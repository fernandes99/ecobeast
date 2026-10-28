# 01. Login no servidor

- **Status:** concluída
- **Depende de:** [backend-api](../backend-api/)

## Contexto

O servidor só tem rotas abertas de leitura do catálogo. Esta fase cria o login com Google pelo navegador, conduzido pelo NestJS com o Supabase Auth ([architecture.md](architecture.md#login-pelo-navegador)), a renovação e a saída da sessão, e a guarda (`AuthGuard`) que as rotas do jogador da [03](03-player-api.md) vão usar. O jogo só passa a usar isso na [04](04-client-login.md).

## Escopo

- Variáveis novas no `.env` e passos de configuração do dono (Google Cloud e Supabase).
- Tabela `auth_login_sessions` e a migration.
- `SupabaseAuthClient`, `LoginSessionsService`, as rotas de login, renovação e saída e as duas páginas do navegador.
- `TokenVerifier` e `AuthGuard`.

## Fora do escopo

- Rotas do jogador ([03](03-player-api.md)).
- Qualquer mudança no Godot.
- Apple, login nativo, link de volta para o app.

## Passos do dono (antes de testar o login de verdade)

1. **Google Cloud** ([console.cloud.google.com](https://console.cloud.google.com)): criar um projeto "Ecobeast". Em **APIs e serviços > Tela de consentimento OAuth**: tipo "Externo", nome "Ecobeast", e-mail de suporte; adicionar o próprio e-mail em "Usuários de teste". Em **Credenciais > Criar credenciais > ID do cliente OAuth**: tipo "Aplicativo da Web"; em "URIs de redirecionamento autorizados", `https://<projeto>.supabase.co/auth/v1/callback` (o endereço do projeto Supabase). Guardar o **ID do cliente** e a **chave secreta do cliente**.
2. **Supabase > Authentication > Sign In / Providers > Google:** ligar, colar o ID e a chave secreta do cliente, salvar.
3. **Supabase > Authentication > URL Configuration > Redirect URLs:** adicionar `http://localhost:3100/auth/google/callback**` (e, para testar no celular, o mesmo com o IP do PC na rede, como `http://192.168.0.10:3100/auth/google/callback**`).
4. **Supabase > Project Settings > JWT Keys:** conferir que a chave em uso é assimétrica (ECC P-256 ou RSA). Se só houver o "Legacy JWT secret", migrar para as chaves de assinatura seguindo o botão do próprio painel.
5. **`.env`:** acrescentar `SUPABASE_URL` (Project Settings > Data API > Project URL), `SUPABASE_PUBLISHABLE_KEY` (Project Settings > API Keys > Publishable key) e `PUBLIC_BASE_URL=http://localhost:3100`.

## Requisitos

**Configuração**

- **RF-01:** `env.ts` valida `SUPABASE_URL` (URL obrigatória), `SUPABASE_PUBLISHABLE_KEY` (texto obrigatório) e `PUBLIC_BASE_URL` (URL, padrão `http://localhost:<PORT>`). O `.env.example` traz as três com valores de exemplo e um comentário de onde achar cada uma. Faltando uma obrigatória, o servidor não sobe e a mensagem diz o nome dela.

**Banco**

- **RF-02:** `auth_login_sessions` no bloco "Jogador" do `schema.prisma` (modelo `AuthLoginSession`), com as colunas de [architecture.md](architecture.md#banco) e o enum `LoginStatus` (`pending`, `complete`, `failed`); migration `auth_login_sessions`. Índice em `expires_at`.

**Supabase Auth** — `src/auth/supabase-auth.client.ts`, `SupabaseAuthClient` (classe injetável; todas as chamadas com os cabeçalhos `apikey: <SUPABASE_PUBLISHABLE_KEY>` e `Content-Type: application/json`):

- **RF-03:** `authorizeUrl(redirectTo: string, codeChallenge: string): string` monta `<SUPABASE_URL>/auth/v1/authorize?provider=google&redirect_to=…&code_challenge=…&code_challenge_method=s256`, com os valores codificados para URL.
- **RF-04:** `exchangeCode(code, codeVerifier): Promise<AuthTokens>` (`POST /auth/v1/token?grant_type=pkce`, corpo `{auth_code, code_verifier}`), `refresh(refreshToken): Promise<AuthTokens>` (`POST /auth/v1/token?grant_type=refresh_token`, corpo `{refresh_token}`) e `logout(accessToken): Promise<void>` (`POST /auth/v1/logout` com `Authorization: Bearer`). `AuthTokens = { access_token, refresh_token, expires_in }`. Resposta diferente de 2xx vira `SupabaseAuthError` com o código HTTP.

**Login** — `src/auth/login-sessions.service.ts`, `LoginSessionsService`:

- **RF-05:** `start(): Promise<{login_id, poll_secret, url}>`: apaga os logins com `expires_at` no passado; cria um login com `poll_secret` e `code_verifier` aleatórios (32 bytes em base64url cada), guarda o SHA-256 do segredo, `status = pending`, `opened = false` e validade de 10 minutos (`LOGIN_TTL_MS = 600_000`). `url = <PUBLIC_BASE_URL>/auth/google/go?login=<id>`.
- **RF-06:** `go(loginId): Promise<string>`: para um login pendente, não vencido e com `opened = false`, marca `opened = true` e devolve a `authorizeUrl` com `redirect_to = <PUBLIC_BASE_URL>/auth/google/callback?login=<id>` e o `code_challenge` (SHA-256 do verifier em base64url). Qualquer outro caso lança `LoginUnavailableError`.
- **RF-07:** `complete(loginId, code)`: para um login pendente, não vencido e já aberto, troca o código (RF-04), grava os tokens e muda para `complete`. Login inválido lança `LoginUnavailableError`; falha da troca marca `failed` e relança.
- **RF-08:** `poll(loginId, pollSecret)`: id inexistente ou segredo que não confere (comparação em tempo constante do hash) → `NotFoundException` "Login não encontrado."; vencido ou `failed` → `GoneException` "Login expirado. Tente de novo." (e apaga a linha); `pending` → `{status: "pending"}`; `complete` → os tokens, e apaga a linha na mesma transação. Um segundo `poll` depois da entrega dá `404`.

**Rotas** — dentro de `/v1`, tag "Login" da Scalar, com descrições em pt-BR:

- **RF-09:** `POST /v1/auth/google/start` → `201` com `{login_id, poll_secret, url}`.
- **RF-10:** `POST /v1/auth/google/poll`, corpo `{login_id: uuid, poll_secret: string}` validado → `202 {"status":"pending"}` ou `200 {access_token, refresh_token, expires_in}` ou os erros do RF-08.
- **RF-11:** `POST /v1/auth/refresh`, corpo `{refresh_token}` → `200` com os tokens novos; refresh token recusado pelo Supabase → `401` "Sessão inválida. Entre de novo.".
- **RF-12:** `POST /v1/auth/logout`, protegida pelo `AuthGuard` → `204`, mesmo se o Supabase responder que a sessão já acabou.

**Páginas do navegador** — fora do `/v1` (`exclude` do prefixo, como o `/health`), não aparecem na Scalar:

- **RF-13:** `GET /auth/google/go?login=<id>` → `302` para a URL do RF-06; login indisponível → página de erro.
- **RF-14:** `GET /auth/google/callback?login=<id>&code=<code>` → completa o login (RF-07) e responde uma página HTML curta, em pt-BR, nas cores do jogo: título "Pronto!", texto "Você entrou no Ecobeast. Pode voltar ao jogo." Sem `code`, com `error` na URL (o jogador recusou) ou com falha: título "Não foi possível entrar", texto "Volte ao Ecobeast e tente de novo.", e o login fica `failed`.

**Sessão nas rotas**

- **RF-15:** `src/auth/token-verifier.ts`, `TokenVerifier` (injetável) com `verify(token): Promise<{userId: string}>`: confere o JWT pelo JWKS de `<SUPABASE_URL>/auth/v1/.well-known/jwks.json` (biblioteca `jose`, `createRemoteJWKSet`), o emissor `<SUPABASE_URL>/auth/v1`, a audiência `authenticated` e a validade; `userId` é o `sub`.
- **RF-16:** `AuthGuard`: lê `Authorization: Bearer <token>`, chama o `TokenVerifier` e põe `userId` na requisição (decorator `@CurrentUser()`); sem cabeçalho ou com token recusado → `401` "Sessão inválida. Entre de novo.". As rotas protegidas aparecem na Scalar com o cadeado (`addBearerAuth` no documento e `@ApiBearerAuth()` nelas).

## Critérios de aceite

- [x] Sem `SUPABASE_URL` no `.env`, o servidor não sobe e a mensagem cita a variável.
- [x] `start` → `go` (302 para o Supabase com `code_challenge`) → `callback` (página "Pronto!") → `poll` (200 com os tokens) → `poll` de novo (404), com o Supabase substituído por um dublê nos testes.
- [x] `poll` antes do retorno dá 202; com o segredo errado, 404; depois de 10 minutos, 410; `go` aberto duas vezes, na segunda, página de erro.
- [x] `refresh` repassa ao Supabase e devolve o par novo; refresh recusado dá 401.
- [x] O `AuthGuard` aceita um token assinado pela chave do JWKS e recusa um vencido, um de outro emissor, um de outra audiência e um assinado por outra chave.
- [ ] Passo do dono: com o `.env` e o Supabase configurados, `curl -X POST http://localhost:3100/v1/auth/google/start`, abrir a `url` no navegador, entrar com o Google e ver "Pronto!"; o `poll` seguinte devolve os tokens, e um `POST /v1/auth/logout` com o access token dá 204.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/auth/`: `auth.module.ts`, `supabase-auth.client.ts`, `login-sessions.service.ts`, `auth.controller.ts`, `google-redirect.controller.ts`, `pages.ts` (as duas páginas HTML), `token-verifier.ts`, `auth.guard.ts`, `current-user.decorator.ts`, com `*.spec.ts` para o serviço, o cliente (com `fetch` substituído) e a guarda (tokens assinados com um par de chaves gerado pelo `jose` e um `createLocalJWKSet`).
- `server/test/auth.e2e-spec.ts`, com `SupabaseAuthClient` substituído por um dublê.
- Migration `auth_login_sessions`.

**Alterar**

- `server/prisma/schema.prisma`, `server/src/config/env.ts` (+ `env.spec.ts`), `server/.env.example`, `server/src/app.module.ts` (`AuthModule`), `server/src/app.setup.ts` (excluir `auth/google/*` do prefixo; `addBearerAuth`), `server/test/support/app.ts` (opção para trocar `SupabaseAuthClient` e `TokenVerifier`), `server/package.json` (`jose`).
- `server/CLAUDE.md` e `server/README.md`: as variáveis novas e os passos do Supabase.

## Verificação

Da pasta `server/`:

```bash
npm run db:migrate
npm test
npm run test:e2e
npm run start:dev   # e o passo do dono com o Google de verdade
```

## Tarefas

- [x] Variáveis no `env.ts` e `.env.example` (RF-01), com teste.
- [x] `schema.prisma` e migration (RF-02).
- [x] `SupabaseAuthClient` com testes (RF-03, RF-04).
- [x] `LoginSessionsService` com testes (RF-05 a RF-08).
- [x] e2e das rotas e páginas; rodar e ver falhar. Controllers (RF-09 a RF-14).
- [x] `TokenVerifier` e `AuthGuard` com testes (RF-15, RF-16).
- [x] Documentos; marcar esta spec e a tabela do README como `concluída`; commit `feat: login com Google no servidor`.

## Decisões da implementação

- **Páginas de erro com `400`:** a página "Não foi possível entrar" (ida indisponível, retorno sem código, jogador recusou, troca falhou) responde `400`; a de sucesso, `200`. As duas vão com `Cache-Control: no-store`.
- **`LoginSessionsService.fail(loginId)`:** método a mais, usado pelo retorno quando vem `error` ou falta o `code`, para o `poll` seguinte dar `410` em vez de esperar os 10 minutos.
- **Ida uma vez só, mesmo em paralelo:** a ida marca `opened` numa atualização condicional (`updateMany` com `opened = false`), e a entrega da sessão só acontece para quem apagar a linha (`deleteMany` com `status = complete`). Dois pedidos ao mesmo tempo não ganham os dois.
- **Ids que não são UUID** (na ida, no retorno e no `poll`) contam como login indisponível ou inexistente, sem chegar ao banco. No `poll`, o corpo já é validado pelo DTO (`400`).
- **Endereços sem barra no fim:** `SUPABASE_URL` e `PUBLIC_BASE_URL` perdem a `/` final na validação do `.env`, e só aceitam `http` ou `https`.
- **`refresh` com o Supabase fora do ar:** só uma recusa (código abaixo de 500) vira `401`; erro do Supabase ou de rede sobe como `500`, para o jogo não apagar a sessão por um problema passageiro.
- **`logout`** ignora só as recusas do Supabase (`SupabaseAuthError`); uma falha de rede sobe como `500`.
- **`TokenVerifier`** aceita só `ES256` e `RS256`, os algoritmos das chaves assimétricas do Supabase, e exige `sub`.
- **DTOs** ficam no próprio `auth.controller.ts`, como no `bundle.controller.ts`.
- **`jose` 6.2.12**, versão fixa. A 6.2.13 tinha 8 dias e ficou de fora.
- **e2e:** o `vitest.config.e2e.ts` põe um `SUPABASE_URL` falso, então os e2e nunca falam com o Supabase Auth de verdade, mesmo com o `.env` preenchido. O `SupabaseAuthClient` real monta a URL de autorização, e as chamadas de rede são dublês. Os tokens vêm de `test/support/tokens.ts`, que a [03](03-player-api.md) também usa. O e2e do banco passou a contar 29 tabelas mais o histórico de migrations.
- **Conferência:** `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 88 testes; `npm run test:e2e` com 178, dos quais 16 do login. O passo do dono com o Google de verdade fica aberto até a configuração do Google Cloud e do Supabase.

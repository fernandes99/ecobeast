# Arquitetura

O desenho técnico que as fases do auth-google compartilham: o fluxo do login pelo navegador, a sessão, as rotas do jogador e o que muda no cliente.

## Login pelo navegador

```
Jogo (Godot)                 NestJS                              Supabase Auth / Google
     │ POST /v1/auth/google/start ─>│ cria login (id, segredo, PKCE)
     │<── { login_id, poll_secret, url }
     │ abre o navegador em url ────>│ GET /auth/google/go?login=<id>
     │                              │── 302 ─────────────────────────> /auth/v1/authorize?provider=google
     │                              │                                   (code_challenge, redirect_to)
     │                              │                                 conta Google, consentimento
     │                              │<── 302 GET /auth/google/callback?code=…&login=<id>
     │                              │ POST /auth/v1/token?grant_type=pkce (code + verifier)
     │                              │ guarda a sessão no login; página "Pronto! Pode voltar ao Ecobeast."
     │ a cada 2 s:                  │
     │ POST /v1/auth/google/poll ──>│ (login_id + poll_secret)
     │<── 202 pendente … 200 { access_token, refresh_token, expires_in } (uma vez)
```

1. **Começar** (`POST /v1/auth/google/start`): o servidor cria uma linha em `auth_login_sessions` com um `id` (UUID), um `poll_secret` aleatório (32 bytes; só o hash SHA-256 vai para o banco) e o `code_verifier` do PKCE. Devolve `login_id`, `poll_secret` e a `url` da página de ida (`<PUBLIC_BASE_URL>/auth/google/go?login=<id>`). O login vale 10 minutos.
2. **Ida** (`GET /auth/google/go?login=<id>`, fora do `/v1`, aberta no navegador): redireciona para `<SUPABASE_URL>/auth/v1/authorize?provider=google&redirect_to=<PUBLIC_BASE_URL>/auth/google/callback?login=<id>&code_challenge=<S256>&code_challenge_method=s256`. Só funciona uma vez por login.
3. **Retorno** (`GET /auth/google/callback?code=…&login=<id>`): troca o `code` pela sessão (`POST <SUPABASE_URL>/auth/v1/token?grant_type=pkce` com `auth_code` e `code_verifier`), guarda os tokens no login e mostra uma página simples em pt-BR: "Pronto! Você entrou no Ecobeast. Pode voltar ao jogo." Erro (login vencido, recusado, falha do Supabase) mostra "Não foi possível entrar. Volte ao jogo e tente de novo." e marca o login como falho.
4. **Perguntar** (`POST /v1/auth/google/poll` com `login_id` e `poll_secret`): `202 {"status": "pending"}` enquanto espera; `200` com a sessão quando terminou, e o login é apagado na mesma hora (a sessão só sai uma vez); `410` para login falho ou vencido; `404` para id ou segredo errados, e para a sessão já entregue (a linha não existe mais).
5. **Limpeza:** cada `start` apaga os logins vencidos.

O jogo pergunta a cada 2 segundos e desiste depois de 5 minutos (mostra "Tentar de novo"). O botão "Cancelar" também para de perguntar.

## Sessão

- É a sessão do Supabase: `access_token` (JWT, vale cerca de 1 hora), `refresh_token` (troca por um novo par) e `expires_in` (segundos).
- **Toda rota do jogador** exige `Authorization: Bearer <access_token>`. A guarda do NestJS (`AuthGuard`) confere a assinatura com as chaves públicas do projeto (`<SUPABASE_URL>/auth/v1/.well-known/jwks.json`, guardadas em memória pela biblioteca `jose`), o emissor (`<SUPABASE_URL>/auth/v1`), a audiência (`authenticated`) e a validade. Sem token, ou token inválido ou vencido: `401` com "Sessão inválida. Entre de novo.". O `sub` do token é o id do usuário.
- **Renovar** (`POST /v1/auth/refresh` com `refresh_token`): repassa para `POST <SUPABASE_URL>/auth/v1/token?grant_type=refresh_token` e devolve o par novo; refresh token inválido: `401`.
- **Sair** (`POST /v1/auth/logout`, com o access token): repassa para `POST <SUPABASE_URL>/auth/v1/logout`, que invalida o refresh token; responde `204` mesmo se o Supabase já tiver encerrado a sessão.
- **No aparelho:** o jogo guarda `access_token`, `refresh_token` e o horário de vencimento em `user://session.json`, cifrado com `FileAccess.open_encrypted_with_pass` e o id do aparelho (`OS.get_unique_id()`). Isso só evita que o arquivo seja lido por engano; a proteção de verdade é o servidor conferir tudo.
- **Renovação no cliente:** antes de uma chamada, se faltar menos de 60 s para vencer, o cliente renova. Se uma chamada voltar `401`, renova uma vez e repete; se a renovação falhar, apaga a sessão e volta à tela de login.

## Configuração do servidor

Novas variáveis no `.env` (nomes e exemplos no `.env.example`, valores reais só no `.env`):

| Variável                   | Para quê                                                                                 |
| -------------------------- | ---------------------------------------------------------------------------------------- |
| `SUPABASE_URL`             | `https://<projeto>.supabase.co`: autorizar, trocar o código, renovar, sair e as chaves públicas |
| `SUPABASE_PUBLISHABLE_KEY` | A chave pública do projeto (antiga "anon"), exigida pelo Supabase Auth em toda chamada    |
| `PUBLIC_BASE_URL`          | O endereço do NestJS visto pelo navegador (`http://localhost:3100`; no celular, o IP do PC na rede) |

A chave secreta do Supabase (`service_role`/secret) **não** é usada.

## Banco

Uma tabela nova no bloco "Jogador" do `schema.prisma`, com migration:

| Tabela                | Colunas                                                                                                                                                         |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `auth_login_sessions` | `id` uuid PK · `poll_secret_hash` text · `code_verifier` text · `status` enum (`pending`, `complete`, `failed`) · `opened` boolean (a ida já foi usada) · `access_token` text? · `refresh_token` text? · `expires_in` int? · `expires_at` timestamptz · `created_at` timestamptz |

Os tokens ficam no máximo até o jogo buscá-los (a linha é apagada na entrega) ou até o login vencer (10 minutos). O banco só é acessível pelo servidor.

`players.id` passa a ser preenchido com o id do usuário do Supabase Auth (o `sub` do token), em vez de um UUID gerado. As outras tabelas do jogador ficam como estão.

## Rotas do jogador

Todas exigem a sessão. O JSON segue o contrato de [onboarding/architecture.md](../onboarding/architecture.md#modelos-resdomainmodels) (`snake_case`), com `stats` calculado pelo servidor em cada criatura.

| Rota                     | Corpo                  | Sucesso                                   | Falhas                                                                                                                                          |
| ------------------------ | ---------------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `GET /v1/me`             | —                      | `200 { "player": Player \| null }`         | `401`                                                                                                                                           |
| `POST /v1/me`            | `{ "name": "…" }`      | `201 { "player": Player }`, sem equipe     | `400` "Use de 2 a 16 letras, números ou espaços." · `409` "Você já tem um Domador."                                                             |
| `POST /v1/me/starter`    | `{ "species_id": 1 }`  | `200 { "player": Player }`, inicial no slot 1 | `409` "Crie seu Domador primeiro." · `409` "Você já escolheu seu Ecobeast." · `400` "Esse Ecobeast não pode ser escolhido."                    |
| `DELETE /v1/me`          | —                      | `204`                                      | —                                                                                                                                               |

- O nome é normalizado como no cliente (pontas sem espaço, espaços repetidos viram um) e conferido com a mesma regra (`^[\p{L}\p{N} ]{2,16}$`).
- O Domador nasce no nível 1 com 1000 moedas. O inicial nasce no nível 5, pelas regras de [onboarding/architecture.md](../onboarding/architecture.md) (Genes 0–31, Temperamento e Traço normal sorteados, as 4 últimas Técnicas por nível com PP cheio, Vínculo 70, nunca Prismático).
- Criar o inicial grava `creature_instances` (local `party`, slot 1), `creature_instance_stats` (Genes e Treino 0 por stat) e `creature_instance_skills` numa transação.
- `DELETE /v1/me` apaga o Domador e, em cascata, as criaturas e o inventário. A conta no Supabase Auth continua.

## Servidor: peças novas

```
server/src/
  auth/
    auth.module.ts
    supabase-auth.client.ts    as chamadas REST ao Supabase Auth (substituível nos testes)
    login-sessions.service.ts  começar, ida, retorno, perguntar, limpeza
    auth.controller.ts         /v1/auth/google/start, /poll, /v1/auth/refresh, /logout
    google-redirect.controller.ts  /auth/google/go e /auth/google/callback (páginas do navegador)
    auth.guard.ts              confere o Bearer pelo JWKS; põe o id do usuário na requisição
    token-verifier.ts          jose + JWKS (substituível nos testes)
  domain/rules/                stat-calculator.ts, xp-curve.ts, creature-factory.ts (fase 02)
  player/
    player.module.ts  player.controller.ts  player.service.ts  player.dto.ts
```

Nos testes, o `SupabaseAuthClient` e o `TokenVerifier` são trocados por dublês: os e2e assinam tokens com um par de chaves gerado na hora, sem Google nem Supabase Auth de verdade.

## Cliente: o que muda

```
res://core/autoload/api.gd          autoload Api: HTTPRequest com JSON, Bearer e renovação
res://core/net/api_response.gd      a resposta, com os erros em pt-BR
res://core/auth/auth_session.gd     a sessão em user://session.json (ler, gravar, apagar)
res://core/auth/auth_service.gd     começar o login, abrir o navegador, perguntar, sair
res://core/services/api_game_service.gd   GameService pelas rotas do jogador
res://screens/login/                tela "Entrar com Google"
```

- **Saem:** `LocalGameService`, `LocalPlayerRepository`, `PlayerRepository`, `res://domain/rules/` (`CreatureFactory`, `StatCalculator`, `XpCurve`), `res://core/util/uuid.gd` e o `user://save.json` (apagado na primeira abertura, se existir).
- **Boot:** catálogo → sessão guardada? Não: tela de login. Sim: `GET /v1/me`; `401` sem conseguir renovar volta ao login; sem Domador: tela do nome; sem inicial: escolha; com equipe: Hub.
- **Tela de login** (`login`): o logo, "Capture, treine e batalhe." e o botão "Entrar com Google". Depois do toque: "Continue no navegador…", "Depois de entrar, volte para cá." e "Cancelar". Falha ou 5 minutos sem resposta: a mensagem e "Tentar de novo".
- **Perfil** (placeholder): "Sair da conta" em todo build; "Apagar progresso" continua só no debug, agora pelo servidor.
- O `Session` continua sendo a porta das telas: os métodos não mudam, só o serviço por trás (`ApiGameService`).

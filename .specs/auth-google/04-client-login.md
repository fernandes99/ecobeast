# 04. Login no jogo

- **Status:** rascunho
- **Depende de:** [01-auth-server](01-auth-server.md)

## Contexto

O servidor já faz o login com Google pelo navegador ([01](01-auth-server.md)). Esta fase põe esse login na frente do jogo: uma tela "Entrar com Google", a sessão guardada no aparelho e renovada sozinha, e "Sair da conta" no Perfil. O progresso ainda é o local nesta fase; ele passa para o servidor na [05](05-client-player.md).

Godot: `OS.shell_open(url)` abre o navegador padrão do aparelho com o endereço. `await get_tree().create_timer(2.0).timeout` espera 2 segundos sem travar o jogo (o `create_timer` cria um temporizador de uso único, e o `await` espera o sinal `timeout` dele). `FileAccess.open_encrypted_with_pass` abre um arquivo cifrado com uma senha.

## Escopo

- Autoload `Api`: as chamadas HTTP com JSON, a sessão e a renovação.
- `AuthSession` (o arquivo da sessão) e `AuthService` (começar o login, perguntar, cancelar, sair).
- Tela `login` e o boot passando por ela.
- "Sair da conta" no Perfil.

## Fora do escopo

- Jogador pelo servidor ([05](05-client-player.md)).
- Login nativo e link de volta para o app.

## Requisitos

**Chamadas** — `res://core/autoload/api.gd`, autoload `Api` (um `Node`, para os `HTTPRequest` entrarem na árvore):

- **RF-01:** `request(method: HTTPClient.Method, path: String, body: Variant = null, authenticated: bool = false) -> ApiResponse`, assíncrono. Cria um `HTTPRequest` filho (timeout de 10 s), manda JSON para `<ecobeast/api/base_url><path>` e devolve `ApiResponse` (`res://core/net/api_response.gd`: `code: int`, `data: Variant` com o JSON lido ou `null`, `ok: bool` para 2xx, `error: String` pronta para a tela). Sem resposta: `code = 0`, "Não foi possível conectar ao servidor."; 5xx: "O servidor teve um problema. Tente de novo."; 4xx: a `message` do corpo.
- **RF-02:** Com `authenticated`, manda `Authorization: Bearer <access_token>`. Se faltar menos de 60 s para a sessão vencer, renova antes (`POST /v1/auth/refresh`); se a resposta for `401`, renova uma vez e repete. Se a renovação falhar com `401`, apaga a sessão e emite o sinal `session_lost`.

**Sessão** — `res://core/auth/auth_session.gd` (`class_name AuthSession`, `RefCounted`):

- **RF-03:** Campos `access_token`, `refresh_token`, `expires_at` (Unix, segundos). `static load_saved() -> AuthSession` (ou `null`), `save() -> bool` e `static clear()`, em `user://session.json`, cifrado com `FileAccess.open_encrypted_with_pass` e `OS.get_unique_id()` como senha. Arquivo ilegível conta como sem sessão (e é apagado). `static from_tokens(data: Dictionary) -> AuthSession` calcula `expires_at = agora + expires_in`.

**Login** — `res://core/auth/auth_service.gd` (`class_name AuthService`, `RefCounted`):

- **RF-04:** `login() -> Result`, assíncrono: `POST /v1/auth/google/start`; abre a `url` com `OS.shell_open`; pergunta `POST /v1/auth/google/poll` a cada 2 s (`POLL_INTERVAL_S = 2.0`) até `200` (grava a sessão e devolve sucesso), `404`/`410` ("Não foi possível entrar. Tente de novo."), falha de rede repetida 3 vezes seguidas ("Não foi possível conectar ao servidor.") ou 5 minutos sem resposta (`LOGIN_TIMEOUT_S = 300`, "O login demorou demais. Tente de novo.").
- **RF-05:** `cancel()`: o `login()` em andamento para de perguntar e devolve uma falha com `error` vazio (a tela volta ao estado inicial, sem mensagem).
- **RF-06:** `logout() -> Result`: `POST /v1/auth/logout` (ignora falha de rede) e apaga a sessão.
- **RF-07:** O `Session` expõe `has_auth_session() -> bool`, `login() -> Result`, `cancel_login()` e `logout() -> Result`; as telas continuam falando só com o `Session`.

**Tela** — `res://screens/login/login_screen.tscn`/`.gd`, registrada como `&"login"`, dentro de um `SafeArea`, no tema escuro:

- **RF-08:** Estado inicial: o logo "Ecobeast" (`LogoLabel`, 72), "Capture, treine e batalhe." (`SecondaryLabel`) e o botão "Entrar com Google".
- **RF-09:** Depois do toque: o botão some; aparecem "Continue no navegador…" e, embaixo, "Depois de entrar, volte para cá." (`SecondaryLabel`) e o botão "Cancelar" (`OutlineButton`).
- **RF-10:** Sucesso: segue para o boot do jogador (RF-12). Falha com mensagem: volta ao estado inicial com a mensagem em `DangerLabel` acima do botão, que passa a dizer "Tentar de novo".

**Boot e saída**

- **RF-11:** `main.gd`: depois do catálogo, sem sessão (`Session.has_auth_session()` falso) abre `login`; com sessão, segue como hoje (carrega o jogador e abre `title`, `starter_select` ou `hub`).
- **RF-12:** A tela de login, ao entrar, chama a mesma etapa do boot que carrega o jogador e abre a primeira tela.
- **RF-13:** `Api.session_lost` leva o jogo para `login` (`Router.go_to`), de qualquer tela.
- **RF-14:** O painel do Perfil (`profile_debug_panel`) ganha o botão "Sair da conta" (`OutlineButton`), em todo build, acima de "Apagar progresso": chama `Session.logout()` e vai para `login`.

## Critérios de aceite

- [ ] Sem sessão, o jogo abre na tela de login; com sessão, abre como antes (nome, escolha ou Hub).
- [ ] Passo do dono: no PC, "Entrar com Google" abre o navegador; depois de entrar, a página diz "Pronto!", e o jogo segue sozinho em até 2 s. Fechar e abrir o jogo de novo não pede login.
- [ ] "Cancelar" durante a espera volta ao estado inicial, e o jogo para de perguntar ao servidor.
- [ ] Com o servidor parado, o toque em "Entrar com Google" mostra "Não foi possível conectar ao servidor." e "Tentar de novo".
- [ ] Com o `access_token` vencido e o `refresh_token` válido, o jogo renova sozinho; com os dois inválidos, volta à tela de login.
- [ ] "Sair da conta" no Perfil volta à tela de login, e a próxima abertura pede login.
- [ ] `user://session.json` não é legível como texto.
- [ ] O jogo roda sem erros de script e o editor não mostra avisos.

## Desenho técnico

**Criar**

- `res://core/autoload/api.gd` (registrado em `project.godot`, antes do `Session`), `res://core/net/api_response.gd`, `res://core/auth/auth_session.gd`, `res://core/auth/auth_service.gd`.
- `res://screens/login/login_screen.tscn`/`.gd`.

**Alterar**

- `res://core/autoload/session.gd` (RF-07), `res://core/autoload/router.gd` (`&"login"`), `res://screens/main/main.gd` (RF-11 a RF-13), `res://screens/hub/profile_debug_panel.tscn`/`.gd` (RF-14), `client/project.godot` (autoload `Api`).
- `client/CLAUDE.md` e `.specs/foundation/architecture.md` (pastas `core/net/` e `core/auth/`, autoload `Api`, boot).

**Reaproveitar**

- `ProjectSettings` `ecobeast/api/base_url` e o padrão de `HTTPRequest` da `HttpDataSource`; `Result`; o tema escuro.

## Verificação

Com o servidor rodando:

```bash
godot --headless --path client --quit-after 30
```

Uma cena temporária confere, contra o servidor real, o `start`, o `poll` pendente, o "Cancelar" e o limite de tempo (com o limite encurtado só nela), sem abrir o navegador. O login de verdade com o Google é passo do dono, no F5.

## Tarefas

- [ ] `Api` e `ApiResponse` (RF-01, RF-02).
- [ ] `AuthSession` (RF-03) e `AuthService` (RF-04 a RF-06); `Session` (RF-07).
- [ ] Tela de login (RF-08 a RF-10).
- [ ] Boot, `session_lost` e "Sair da conta" (RF-11 a RF-14).
- [ ] Cena temporária e conferência; apagar a cena.
- [ ] Documentos; marcar esta spec e a tabela do README como `concluída`; commit `feat: login no jogo`.

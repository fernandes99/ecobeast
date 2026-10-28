# Auth Google

Login com a conta Google e o jogador morando no servidor. O jogo abre o navegador para o login, o servidor recebe a resposta do Google pelo Supabase Auth, e daí em diante toda ação do jogador (criar o Domador, escolher o inicial) é decidida e gravada pelo NestJS no banco. O aparelho não guarda mais o progresso, só a sessão.

## Contexto

Até aqui, o catálogo vem do servidor ([backend-api](../backend-api/)), mas o jogador é criado e salvo no próprio aparelho (`user://save.json`), com as regras de geração do inicial rodando no Godot. Isso deixa qualquer um editar o próprio progresso e impede jogar em mais de um aparelho. As tabelas do jogador já existem no banco desde a [backend-api/02](../backend-api/02-database-schema.md), vazias.

## Quem usa

Todo jogador: o login vira a primeira tela do jogo. Quem implementa as próximas iniciativas, que passam a ter um jogador autenticado no servidor para batalhas, capturas e recompensas.

## Objetivos

1. Entrar com a conta Google pelo navegador, no PC e no celular, e voltar ao jogo já logado.
2. O jogo lembra a sessão: nas próximas aberturas, vai direto ao Hub.
3. Criar o Domador e escolher o inicial passam a ser rotas do servidor, que gera a criatura e grava tudo no banco. O cliente só exibe.
4. A mesma conta, em outro aparelho, encontra o mesmo Domador e a mesma equipe.
5. Sair da conta volta à tela de login.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                                        | Motivo                                                                                     |
| ---------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| Só o Google, por enquanto                                                                      | Primeiro passo; Apple entra quando houver build iOS (a Apple exige junto do Google)        |
| Login pelo navegador, não pelo SDK nativo                                                      | Funciona igual no PC, Android e iOS, sem plugin nativo nem build Android agora; o nativo fica para uma melhoria |
| O jogo pergunta ao servidor a cada 2 s se o login terminou                                     | Simples; custo desprezível (só no primeiro login de cada aparelho)                         |
| O nome do Domador continua sendo digitado                                                      | O nome é do jogo, não da conta Google                                                      |
| O jogador passa a morar no servidor nesta mesma iniciativa                                    | Fecha a porta das trapaças no progresso e grava os dados no banco                          |
| O Godot continua falando só com o NestJS                                                       | Regra do projeto; o Supabase Auth é usado pelo servidor                                     |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                                                   | Motivo                                                                                       |
| --------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| O servidor fala com o Supabase Auth pela API REST dele (`/auth/v1/...`), sem o `supabase-js`               | São quatro chamadas (autorizar, trocar o código, renovar, sair); fácil de substituir nos testes |
| Fluxo OAuth com PKCE, conduzido pelo NestJS                                                                | O código do Google só vale com o segredo que o servidor guardou; nada sensível passa pelo navegador |
| A sessão é a do Supabase (access token + refresh token); o NestJS confere a assinatura pela chave pública do projeto (JWKS) | Sem sessão própria para manter; a conferência não precisa chamar o Supabase a cada requisição |
| O id do Domador é o id do usuário no Supabase Auth                                                         | Um Domador por conta, sem tabela de ligação                                                  |
| As regras de criação do inicial são reescritas em TypeScript, com os mesmos testes de valor                | O servidor é a autoridade; saem do cliente                                                   |
| `user://save.json`, `LocalGameService`, `LocalPlayerRepository` e `res://domain/rules/` saem do cliente     | O progresso não pode mais ser decidido nem guardado no aparelho                              |
| Saves locais antigos são descartados                                                                       | Só existem em máquinas de desenvolvimento                                                    |
| "Apagar progresso" (debug) apaga o Domador no servidor; a conta Google continua                            | Refazer o onboarding durante o desenvolvimento                                               |

## Fora do escopo

- Login nativo (Credential Manager no Android, SDK no iOS) e "Entrar com a Apple".
- Link de volta para o app (`ecobeast://`) depois do login; o jogo descobre sozinho, perguntando ao servidor.
- Apagar a conta (exigência das lojas para publicar): entra com a `release-pipeline`.
- Batalha, captura, recompensas e qualquer outra ação além de criar o Domador, escolher o inicial e apagar o progresso.
- Servidor publicado (Render). Até lá, o celular testa pelo PC na mesma rede Wi-Fi.

## Riscos conhecidos

- **Link de login repassado:** como em todo login por navegador iniciado por outro aparelho, alguém poderia mandar o próprio link de login para uma vítima; se ela entrasse, a sessão iria para quem gerou o link. O link vale uma vez e por 10 minutos, e a página final diz em qual jogo a pessoa entrou. O login nativo, no futuro, elimina o risco.

## Pré-requisitos

- [backend-api](../backend-api/) concluída.
- Passos do dono, detalhados na [01](01-auth-server.md): projeto no Google Cloud com um cliente OAuth, o provedor Google ligado no Supabase, a URL de retorno do servidor liberada no Supabase e as chaves de assinatura (JWT Signing Keys) ativas no projeto.

## Fases

| Fase                                        | Entrega                                                                                        | Status   |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------- | -------- |
| [01-auth-server](01-auth-server.md)         | Login pelo navegador no NestJS (começar, retorno, perguntar, renovar, sair) e a guarda das rotas | concluída |
| [02-player-rules](02-player-rules.md)       | Regras de criação do inicial em TypeScript (stats, XP, Genes, Temperamento, Técnicas)           | rascunho |
| [03-player-api](03-player-api.md)           | Rotas do jogador: ler, criar o Domador, escolher o inicial, apagar o progresso                 | rascunho |
| [04-client-login](04-client-login.md)       | Tela de login no jogo, a sessão guardada e o boot com login                                    | rascunho |
| [05-client-player](05-client-player.md)     | O jogo usando as rotas do jogador; sai o save local e as regras do cliente                     | rascunho |

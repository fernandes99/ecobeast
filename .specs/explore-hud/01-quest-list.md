# 01. A lista das missões aceitas

- **Status:** concluída
- **Depende de:** [auralis/06](../auralis/06-island-quests.md)

## Contexto

O quadro de missões da [03](03-quest-tracker.md) precisa saber quais missões o Domador aceitou e quanto falta em cada uma. Hoje o jogo só recebe os lugares do "Vá até" (`quest_places`). O servidor guarda as aceitas em `player_quests`.

## Escopo

- `server/src/quests/` (a rota e o serviço) e `server/src/domain/quests/quests.ts` (o texto curto do progresso).
- `client/core/services/` (`GameService` e `ApiGameService`), `client/core/autoload/session.gd` e um modelo novo em `client/domain/models/`.

## Requisitos

- **RF-01:** `GET /v1/me/quests` (com login) responde `quests`: as missões aceitas e não entregues do Domador (`player_quests` com `claimed_at` nulo), das ilhas publicadas (`islands.published_at` não nulo), pela ordem do `accepted_at`, a mais antiga primeiro. A missão de uma ilha que saiu do ar fica de fora; a de um NPC que saiu do mapa continua (é o dono que arruma no F2).
- **RF-02:** cada uma traz `id`, `island_id`, `island_name`, `npc_id`, `npc_name` (quem entrega), `title` (o mesmo título das falas da missão), `type` (o `slug` do `quest_types`), `progress`, `target` (na unidade do `questTarget`), `progress_text` e `done` (`progress` chegou ao `target`, falta entregar).
- **RF-03:** `progress_text` é o progresso curto, para caber numa linha: "2/3" nos tipos de contagem; "40%/60%" no "Explore"; "3/5 min" no "Fique" (minutos inteiros, para baixo). Mora em `src/domain/quests/quests.ts`, ao lado do `progressLine`, com teste de unidade.
- **RF-04:** no "Explore", o progresso é o de agora, contado como na conversa (`progressOf`), não só o gravado.
- **RF-05:** sem missões aceitas, `quests` vem vazia (200).
- **RF-06:** no jogo, `Session.load_quests() -> Result` chama a rota e guarda a lista em `Session.quests` (`Array[ActiveQuest]`, o modelo novo em `domain/models/active_quest.gd`), e manda o sinal `quests_changed`. Com erro, a lista fica como estava.
- **RF-07:** o `Session` compara a lista nova com a anterior: cada missão que estava na lista anterior sem `done` e chega com `done` vai no sinal `quest_ready(quest: ActiveQuest)`. A primeira leitura depois de abrir o jogo não manda o sinal (não há lista anterior), e nada disso é guardado no aparelho.

## Fora do escopo

- Missões não aceitas e as entregues.
- Os lugares do "Vá até" (continuam no `quest_places`).

## Critérios de aceite

- O e2e da rota: sem login dá 401; com login responde o formato do RF-02 (sem conferir valores de balanceamento).
- O teste de unidade do `progress_text` cobre um tipo de contagem, o "Explore" e o "Fique".
- O jogo carrega a lista sem erro de script.

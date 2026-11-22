# 04. Os Domadores da ilha

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-unlock-config](01-unlock-config.md), [03-archipelago-screen](03-archipelago-screen.md), [island-npcs](../island-npcs/), [npc-tamers](../npc-tamers/), [tamer-level](../tamer-level/)

## Contexto

O [README](README.md) decidiu que a ilha seguinte abre quando a da vez tem os Domadores vencidos, as Arenas ganhas e as missões cumpridas. Esta fase traz a primeira condição, os Domadores, e com ela a primeira ilha que abre sozinha.

Em 2026-11-22, o dono escolheu: "Tocar no NPC e Volta o Hub". A luta começa quando o jogador toca no NPC do Domador, depois da última fala. Perder volta ao Hub, como a derrota para um Domador do mapa aleatório.

Hoje:

- Os NPCs das ilhas vêm do catálogo `npcs` (nome, sprite ou aparência de pessoa, voz) e são postos pelo F2 (`island_npcs`), com a fala e a ação opcional. No jogo, tocar num NPC por perto mostra as falas e, depois da última, roda a ação (`ExplorationScreen._talk` e `_on_greeting_tapped`).
- A luta contra o Domador do mapa aleatório (`POST /v1/me/board-battle/tamer`) tira o Domador da exploração guardada e luta com `opponent: 'tamer'` e `tamer: {nameId, source: 'map'}`. O nome vem de `npc_tamer_names`. Perder encerra a exploração (`BoardBattleService.finish`), e o jogo volta ao Hub (`_exits_to_hub`).
- O XP do Domador (`tamerXpFromBattle`) paga `tamer_win` em toda vitória contra Domador. As fontes `island_tamer_win` (150), `island_tamer_rematch` (15) e `island_unlocked` (1000) já estão no catálogo, sem nada que as pague.

## Decisões desta fase

| Decisão | Motivo |
| --- | --- |
| O Domador da ilha é um NPC do catálogo `npcs` com uma linha em `tamers` (`npc_id` único) | O F2 já põe, veste e dá voz aos NPCs; a ligação fica no painel do Supabase, sem mudar o rascunho da ilha nem o editor |
| A equipe fica em `tamer_creatures` (espécie e nível, até 6), e as Técnicas são as que a espécie aprende até o nível, como nos Domadores sorteados | O dono só escolhe quem e em que nível |
| A luta começa depois da última fala do NPC, no lugar da ação dele | A escolha do dono; a conversa já existe |
| O servidor confere que a exploração guardada é a ilha do Domador e que o NPC está na versão publicada dela, mas não confere a distância | O passeio do NPC só existe no cliente; a mesma confiança da descoberta da névoa |
| Contam para abrir a ilha seguinte só os Domadores marcados (`counts_for_unlock`) que estão na versão publicada da ilha | Um Domador tirado do mapa não deixa o jogador preso |
| Revencer é possível; só a primeira vitória conta e paga o `island_tamer_win`, as outras pagam o `island_tamer_rematch`, e nenhuma paga o `tamer_win` | A regra da [tamer-level](../tamer-level/README.md) |
| Ao completar uma ilha, abre a ilha logo depois dela na ordem, e o Domador ganha o `island_unlocked` | Completar uma ilha antiga de novo não pula ilhas |
| O aviso da ilha nova é uma linha no fim da luta: "Ilha nova aberta: <nome>!" | O fim da luta já mostra o resultado e os níveis |

## Escopo

- As tabelas `tamers`, `tamer_creatures` e `player_tamer_wins`, e a coluna `islands.required_tamer_wins`.
- As regras puras: a ilha completa pelos Domadores e a ilha seguinte.
- A rota `POST /v1/me/board-battle/island-tamer`, com o `npc_id`.
- No fim da luta: a vitória gravada, o XP, a ilha seguinte aberta e o `island_unlocked` na resposta. A derrota encerra a exploração.
- O `tamer: true` nos NPCs da ilha que são Domadores, na resposta da exploração.
- No jogo: a luta depois da última fala, o nome do Domador na luta, a volta ao Hub na derrota e o aviso.

## Fora do escopo

- As Arenas (fase 5) e as missões (fase 6), que entram na mesma conta da ilha completa.
- A lista do que falta na tela do Arquipélago.
- Escolher a equipe pelo F2: ela se edita no painel.
- Uma fala depois da luta.

## Onde ficou

- As regras: `nextIslandAfter` e `tamersComplete` em `server/src/domain/islands/archipelago.ts`, e o `islandTamer` e o `islandUnlocked` no `tamerXpFromBattle` (`server/src/domain/progression/tamer-level.ts`).
- O `IslandTamersService` (`server/src/islands/island-tamers.service.ts`): acha o Domador do NPC, marca os NPCs Domadores da exploração e monta as escritas da vitória, com a ilha seguinte. O `BattleRecordsService.finish` as põe na transação do fim da luta, e o `BoardBattleService.startIslandTamer` começa a luta.
- A exploração guarda a ilha (`StoredExploration.islandId`).
- A migration `20270212000000_island_tamers` e o e2e `server/test/island-tamers.e2e-spec.ts`, no grupo que grava no catálogo, porque cria NPCs.
- No jogo: o `MapNpc.tamer`, o `_after_talk` do `ExplorationScreen`, o `island_tamer` da tela da luta, o `BoardBattleView.tamer_name`, o `BoardTurn.island_unlocked_name` e o `ISLAND_UNLOCKED_TEXT`.
- Para pôr um Domador: crie o NPC em `npcs` (ou use um que já existe), ponha-o na ilha pelo F2 e publique, e crie a linha em `tamers` (o `npc_id`, a ilha, o formato) e as linhas da equipe em `tamer_creatures`, pelo painel do Supabase.

## Requisitos

- **RF-01:** `tamers` tem `id`, `npc_id` (único, FK `npcs`), `island_id` (FK `islands`, apaga junto), `size` (1 a 3, padrão 1) e `counts_for_unlock` (padrão verdadeiro). `tamer_creatures` tem `tamer_id`, `position` (1 a 6), `species_id` e `level` (1 a 100), com a chave em `tamer_id` e `position`. `player_tamer_wins` tem `player_id`, `tamer_id`, `wins` (1 ou mais) e `first_won_at`. `islands.required_tamer_wins` é opcional e maior que 0.
- **RF-02:** a ilha está completa pelos Domadores quando tem pelo menos um Domador que conta e o jogador venceu `required_tamer_wins` deles, ou todos quando a coluna é nula. Um número maior que o de Domadores que contam pede todos.
- **RF-03:** a ilha seguinte é a de menor ordem acima da ilha completa, entre as publicadas do Arquipélago.
- **RF-04:** `POST /v1/me/board-battle/island-tamer` com `{npc_id}` começa a luta contra a equipe do Domador, no formato dele (`slots = size`), com `opponent: 'tamer'` e `tamer: {name_id: 0, source: 'island', name}`, o nome do NPC. Ela dá 409 "Nenhum Domador aqui." sem exploração ou quando a exploração não é numa ilha, quando o NPC não é um Domador daquela ilha ou não está na versão publicada dela, ou quando a equipe está vazia. Sem equipe, os mesmos erros das outras lutas.
- **RF-05:** na vitória, a primeira contra o Domador cria a linha em `player_tamer_wins` e paga o `island_tamer_win`. As seguintes somam `wins` e pagam o `island_tamer_rematch`. Nenhuma paga o `tamer_win`. O modo deus não grava a vitória nem paga.
- **RF-06:** quando a vitória completa a ilha e a ilha seguinte não está aberta, ela abre (`player_islands`) na mesma transação, o Domador ganha o `island_unlocked`, e a resposta traz `island_unlocked: {id, name}`. Nos outros casos, `island_unlocked` é nulo.
- **RF-07:** a derrota contra o Domador da ilha encerra a exploração, como a do mapa.
- **RF-08:** na resposta de `POST /v1/me/exploration` numa ilha, cada NPC traz `tamer`, verdadeiro quando ele é um Domador daquela ilha.
- **RF-09:** no jogo, depois da última fala de um NPC com `tamer`, a luta começa pela transição de Domador e pela rota nova, no lugar da ação dele. Um NPC Domador sem fala luta logo ao toque.
- **RF-10:** a luta mostra o nome do Domador pelo `name` quando o `name_id` é 0. A derrota com `source: 'island'` volta ao Hub, como a do mapa.
- **RF-11:** com `island_unlocked`, o fim da luta mostra "Ilha nova aberta: <nome>!" embaixo do resultado.

## Critérios de aceite

- [x] Com um Domador de Liora que conta e a ilha seguinte no Arquipélago, a primeira vitória abre a seguinte, e a resposta traz `island_unlocked`. A segunda vitória não abre nada e paga 15 de XP.
- [x] Com dois Domadores que contam e `required_tamer_wins = 1`, vencer um abre a seguinte.
- [x] Um Domador fora da versão publicada da ilha não conta, e a luta com ele dá 409.
- [x] Perder para o Domador da ilha apaga a exploração guardada.
- [x] Na exploração, só os NPCs Domadores vêm com `tamer: true`.
- [ ] No jogo, tocar no NPC Domador mostra as falas e começa a luta, perder volta ao Hub, e vencer a última condição mostra o aviso.

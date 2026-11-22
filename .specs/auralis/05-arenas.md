# 05. As Arenas

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [04-island-tamers](04-island-tamers.md), [interiors](../interiors/)

## Contexto

O [README](README.md) decidiu que a Arena é um prédio com sala, com Domadores de treino e o Mestre de Arena. Vencer o Mestre dá o emblema, e a Arena seguinte da ilha só abre depois. Cada ilha tem quantas Arenas o dono quiser, e todas entram na conta para abrir a ilha seguinte.

Em 2026-11-22, o dono decidiu que perder na Arena volta ao Hub ("Sim, volta ao Hub"), como perder para um Domador da ilha.

Hoje:

- Uma peça da ilha com sala (`island_props.interior_id`) abre a tela `interior` por cima de Explorar, onde o Domador anda e fala com os NPCs parados (`interior_npcs`, com o `npc_id` do catálogo). Depois da última fala, roda a ação do NPC.
- A [04](04-island-tamers.md) fez o Domador da ilha: um NPC do catálogo com uma linha em `tamers`. A luta (`POST /v1/me/board-battle/island-tamer`) confere que o NPC está posto no mapa publicado da ilha. A ilha completa quando os Domadores que contam foram vencidos.

## Decisões desta fase

| Decisão | Motivo |
| --- | --- |
| `arenas` tem a ilha, a ordem nela, o nome, a sala e o Mestre (um `tamers`) | O Mestre e os de treino são Domadores como os da ilha; a Arena só junta a sala e a ordem |
| Os Domadores de treino são os NPCs Domadores postos na sala da Arena; o Mestre também fica na sala | O dono monta a sala no modo Interiores do F2, como as outras |
| Um NPC posto na sala de uma peça publicada da ilha conta como posto na ilha | Sem isso, nenhum Domador de dentro de uma sala lutaria |
| A Arena trancada não abre: a porta mostra "Essa Arena ainda está trancada.", e o servidor recusa a luta contra quem está nela | O servidor é a autoridade, e o jogo não deixa entrar à toa |
| A primeira vitória contra o Mestre dá o emblema (`player_arenas`) e paga o `arena` (500), no lugar do `island_tamer_win` | A regra da [tamer-level](../tamer-level/README.md) |
| O Mestre não entra na conta dos Domadores que contam: ele conta pela Arena | Sem contar duas vezes a mesma vitória |
| A ilha completa quando tem pelo menos uma condição (um Domador que conta ou uma Arena) e cumpre as duas | O README: "Uma ilha só abre a próxima quando tem pelo menos uma condição e cumpre todas" |
| O emblema aparece no fim da luta: "Emblema conquistado: <Arena>!" | O fim da luta já mostra a ilha nova; a tela de emblemas fica para depois |

## Escopo

- As tabelas `arenas` e `player_arenas`.
- As regras puras: o estado de cada Arena e a ilha completa com as Arenas.
- O NPC da sala contando como posto na ilha, a luta recusada na Arena trancada e o emblema na vitória contra o Mestre.
- Na exploração: as salas trancadas (`locked_interior_ids`) e os NPCs Domadores da ilha (`tamer_npc_ids`), dos de fora e dos de dentro das salas.
- No jogo: a porta trancada, a luta depois da última fala dentro da sala, o aviso do emblema e a Arena seguinte abrindo sem sair da ilha.

## Fora do escopo

- Uma tela com os emblemas e a lista do que falta na ilha.
- Mudar a arte dos prédios da Arena.
- A Liga.

## Onde ficou

- As regras: `arenaOpen` e `islandComplete` em `server/src/domain/islands/archipelago.ts`, e o `islandTamer: 'arena'` no `tamerXpFromBattle`.
- O `IslandTamersService` passou a ver os NPCs das salas (`placedNpcs`), a recusar a luta na Arena trancada, a dar as salas trancadas (`lockedInteriorIds`) e a gravar o emblema (`player_arenas`) na vitória contra o Mestre.
- A resposta da luta traz `arena_won`, e a da exploração traz `locked_interior_ids` e `tamer_npc_ids`.
- A migration `20270213000000_arenas` e o e2e `server/test/arenas.e2e-spec.ts`, no grupo que grava no catálogo.
- No jogo: o `ExplorationMap.locked_interior_ids` e o `tamer_npc_ids`, a porta trancada no `_finish_prop`, o `Session.opened_arena_rooms` (a sala seguinte abre sem sair da ilha), o `_after_talk` da tela `interior` e o `ARENA_WON_TEXT` no fim da luta.
- O critério da ilha com Domadores e Arena ficou nos testes de unidade do `islandComplete`; os do jogo ficam para o dono conferir.
- Para montar uma Arena: monte a sala no modo Interiores do F2 com o Mestre e os de treino (NPCs do catálogo), ponha a peça do prédio com essa sala na ilha e publique, crie as linhas em `tamers` dos três (os de treino com `counts_for_unlock` falso, se não devem contar) e a linha em `arenas` (a ilha, a ordem, o nome, a sala e o Mestre).

## Requisitos

- **RF-01:** `arenas` tem `id`, `island_id` (apaga junto), `position` (maior que 0, única na ilha), `name` (1 a 40 caracteres), `interior_id` (FK `interiors`) e `boss_tamer_id` (FK `tamers`, único). `player_arenas` tem `player_id`, `arena_id` e `won_at`.
- **RF-02:** a Arena está aberta quando todas as Arenas da ilha de posição menor foram ganhas, e trancada nos outros casos.
- **RF-03:** os NPCs postos de uma ilha são os do mapa publicado e os das salas que as peças do mapa publicado abrem.
- **RF-04:** a luta contra um Domador cujo NPC está na sala de uma Arena trancada dá 409 "Essa Arena ainda está trancada.".
- **RF-05:** a primeira vitória contra o Mestre de uma Arena grava a Arena em `player_arenas` e paga o `arena` no lugar do `island_tamer_win`. A resposta traz `arena_won: {id, name, next_interior_id}`, com a sala da Arena seguinte da ilha (nula se não houver). Nos outros casos, `arena_won` é nulo. As revanches pagam o `island_tamer_rematch`.
- **RF-06:** a ilha completa quando tem pelo menos um Domador que conta (sem os Mestres) ou uma Arena, os Domadores estão vencidos pela regra da [04](04-island-tamers.md) e todas as Arenas foram ganhas.
- **RF-07:** a resposta de `POST /v1/me/exploration` numa ilha traz `locked_interior_ids`, as salas das Arenas trancadas para o Domador, e `tamer_npc_ids`, os NPCs que são Domadores da ilha. No mapa sorteado, as duas listas vêm vazias.
- **RF-08:** no jogo, tocar numa peça cuja sala está trancada mostra "Essa Arena ainda está trancada." e não abre a sala. Depois de uma vitória com `arena_won`, a sala do `next_interior_id` passa a abrir sem sair da ilha.
- **RF-09:** dentro da sala, o NPC Domador luta depois da última fala, como fora, e o fim da luta com `arena_won` mostra "Emblema conquistado: <Arena>!". Perder volta ao Hub.

## Critérios de aceite

- [x] Com duas Arenas numa ilha, lutar contra o Mestre da 2ª antes de ganhar a 1ª dá 409, e a 2ª aparece em `locked_interior_ids`.
- [x] Vencer o Mestre da 1ª grava o emblema, traz `arena_won` com a sala da 2ª e paga o `arena`.
- [x] Um Domador de treino dentro da sala luta, e a vitória não dá emblema.
- [x] Uma ilha só com uma Arena completa quando ela é ganha, e a ilha seguinte abre.
- [ ] Uma ilha com Domadores que contam e uma Arena só completa com os dois.
- [ ] No jogo, a porta da Arena trancada avisa e não abre, e a luta na sala começa depois da fala.

# 03. Rotas dos Domadores

- **Status:** concluída
- **Depende de:** [02-tamer-rules](02-tamer-rules.md), [architecture.md](architecture.md)

## Contexto

Com as regras prontas, o servidor passa a pôr Domadores em cada exploração e a abrir a luta contra eles. Hoje:

- `ExplorationService.start` (`server/src/exploration/exploration.service.ts`) gera o mapa, sorteia os selvagens e guarda tudo no `ExplorationStore`.
- `BattleRecordsService.takeSpawn` (`server/src/battle/battle-records.service.ts`) confere a posição e tira um selvagem do mapa. `createEnemy` cria o Ecobeast, e `finish` grava o fim.
- `BoardBattleService` (`server/src/board-battle/board-battle.service.ts`) abre a luta (`begin`) e joga as vezes (`act`).

## Escopo

- Os Domadores na exploração e no `map` da resposta.
- `POST /v1/me/board-battle/tamer` e `POST /v1/me/board-battle/challenge`.
- `POST /v1/me/exploration/tamers`, com `ENABLE_TEST_BATTLE`.
- A exploração apagada na derrota contra um Domador do mapa.

## Fora do escopo

- O jogo: vem na [04](04-map-tamers.md) e na [05](05-hub-challenge.md).
- Guardar Domadores entre sessões ou entre reinícios do servidor: a exploração continua só na memória.
- Limitar quantas vezes o Desafiar pode ser usado.

## Requisitos

- **RF-01:** `POST /v1/me/exploration` sorteia os Domadores com `rollMapTamers`, depois dos selvagens, com a mesma média da equipe, e guarda em `StoredExploration.tamers`. O `map` da resposta ganha `tamers: [{id, q, r, name_id, greeting_id}]`, sem tamanho nem equipe.
- **RF-02:** `POST /v1/me/board-battle/tamer` recebe `{q, r, god?}`, valida como o `/board-battle/wild` e confere a posição com a mesma regra (`MIN_STEP_MS`), gravando a nova posição. As duas rotas usam o mesmo código para isso.
- **RF-03:** sem Domador no hexágono, a resposta é `409` "Nenhum Domador por aqui.". Com ele, o Domador sai da exploração antes de a luta começar.
- **RF-04:** a luta contra Domador cria os Ecobeasts da equipe dele com `createEnemies`, na ordem sorteada, e abre o tabuleiro com `opponent: 'tamer'`, `size` vagas do lado inimigo e `min(size, Ecobeasts de pé)` do lado do jogador.
- **RF-05:** `POST /v1/me/board-battle/challenge`, sem corpo, sorteia o desafiante com `rollChallenger` e a média da equipe principal, e abre a mesma luta. Sem desafiante, a resposta é `409` "Nenhum Domador quer lutar agora.". Ela não lê nem muda a exploração.
- **RF-06:** a resposta das duas rotas é a de `/board-battle/wild`, com `tamer_id` (o id do Domador do mapa, ou `null` no Desafiar e nas outras lutas), e o `battle` de todas as respostas da luta no tabuleiro ganha `tamer: {name_id, source} | null`, com `source` `"map"` ou `"challenge"`.
- **RF-07:** o `BattleStore` guarda, junto da luta, de onde o Domador veio (`map`, `challenge` ou nenhum).
- **RF-08:** quando a luta contra um Domador do mapa termina em derrota, o servidor grava o fim como hoje e apaga a exploração do jogador. Depois disso, `/board-battle/wild` e `/board-battle/tamer` respondem `404` "Essa exploração acabou. Saia e entre de novo.".
- **RF-09:** a vitória, e qualquer fim da luta do Desafiar, não mexem na exploração.
- **RF-10:** `POST /v1/me/exploration/tamers` recebe `{q, r, size}`, com `size` de 1 a 3, só existe com `ENABLE_TEST_BATTLE` e põe na exploração um Domador com esse tamanho, sorteado com as taxas de todos os biomas, como o do Desafiar (o servidor não guarda os hexágonos e não sabe o bioma), no hexágono pedido, marcado `debug`. Já havendo Domador ali, ele é substituído. Responde `{tamer: {id, q, r, name_id, greeting_id}}`.
- **RF-10b:** `POST /v1/me/board-battle/wild` num hexágono com Domador responde `409` "Um Domador está esperando você aqui.", antes de tirar o selvagem. Depois da luta contra o Domador, Procurar volta a funcionar ali.
- **RF-11:** a rota de limpar o spawn de depuração (`DELETE /v1/me/exploration/spawns`) também tira os Domadores marcados `debug`, e a resposta ganha `removed_tamer_ids`.
- **RF-12:** todas as rotas novas ficam no OpenAPI, com descrição e erros em pt-BR, como as de hoje.

## Critérios de aceite

- [x] `POST /v1/me/exploration` traz `tamers`, sem `size` nem `team`.
- [x] Um e2e com o Domador posto por `POST /exploration/tamers` de tamanho 3 abre a luta com 3 vagas inimigas, sem fuga (`can_flee: false`) e com `tamer.source` `"map"`.
- [x] Um jogador com só 1 Ecobeast de pé contra um Domador de 3 começa com 1 vaga do seu lado.
- [x] Pedir a mesma luta duas vezes: a segunda responde "Nenhum Domador por aqui.".
- [x] `/board-battle/wild` num hexágono com Domador e selvagem responde "Um Domador está esperando você aqui.", e o selvagem continua na exploração.
- [x] Depois de uma derrota contra Domador do mapa, `/board-battle/wild` responde `404`.
- [x] `/board-battle/challenge` abre uma luta com `tamer.source` `"challenge"` e `tamer_id` `null`, mesmo sem exploração.
- [x] `POST /exploration/tamers` responde `404` com `ENABLE_TEST_BATTLE` desligada.
- [x] `typecheck`, `lint`, `npm test` e `npm run test:e2e` sem erros.

## Desenho técnico

- `server/src/exploration/spawn-data.ts`: `loadSpawnSpecies`, `loadTamerTexts` e `partyAverageLevel`, as leituras do banco que a exploração e o Desafiar fazem. O `loadSpawnSpecies` saiu de dentro do `ExplorationService`.
- `server/src/exploration/exploration.store.ts`: `tamers` no `StoredExploration` e `delete(userId)`.
- `server/src/exploration/exploration.service.ts`: o sorteio dos Domadores no `start`, o `debugTamer` e o `debugClear` com Domadores.
- `server/src/exploration/exploration.dto.ts`: `MapTamerDto`, `tamers` no `ExplorationMapDto`, `DebugTamerBodyDto` (com a mensagem "Domador de depuração inválido."), `DebugTamerResponseDto` e `removed_tamer_ids`.
- `server/src/exploration/exploration.controller.ts`: a rota `POST tamers`.
- `server/src/battle/battle.dto.ts`: as mensagens `NO_TAMER_HERE`, `TAMER_WAITING` e `NO_CHALLENGER`.
- `server/src/battle/battle-records.service.ts`: a conferência de posição saiu do `takeSpawn` para o `confirmPosition`, que o `takeTamer` também usa. O `takeSpawn` recusa o hexágono com Domador, e o `endExploration` apaga a exploração.
- `server/src/battle/battle.store.ts`: `BattleTamer` (`{nameId, source}`) e o `tamer` na entrada da luta.
- `server/src/board-battle/board-battle.service.ts`: `startTamer` e `startChallenge`. O `begin` recebe as opções num objeto (`godMode`, `slots`, `opponent`, `tamer`) e dá ao jogador `min(slots, Ecobeasts de pé)` vagas. O fim passa por um `finish` do próprio serviço, que grava como antes e, na derrota contra Domador do mapa, chama o `endExploration`. O desenho pedia isso dentro do `BattleRecordsService.finish`, mas quem sabe de onde veio o Domador é a luta guardada, e o `finish` continua igual para a luta antiga.
- `server/src/board-battle/board-battle.controller.ts`, `board-battle.dto.ts` e `board-battle.mapper.ts`: as duas rotas, `tamer_id` na resposta, `BattleTamerDto` e o `tamer` no `BoardBattleDto`.
- `server/test/tamers.e2e-spec.ts`: os e2e de cada critério. As jogadas que levam uma luta até o fim (`attackVez`, `waitVez`, `fleeVez`, `playOut`) saíram do e2e do tabuleiro para `server/test/support/board-play.ts`, e os dois arquivos as usam. O `placeWild` de `test/support/wild.ts` também põe Domadores.
- `.specs/biome-encounters/architecture.md`: a seção "Exploração no servidor" cita os Domadores.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Feita em 2026-11-09: `typecheck` e `lint` sem erros, 718 testes unitários e a suíte e2e inteira, com os 13 novos de `tamers.e2e-spec.ts`. O critério da derrota cura a equipe antes de Procurar: sem HP, o servidor responde "Cure sua equipe no Refúgio." antes de conferir a exploração.

- Em `/docs`, chamar as rotas e conferir os exemplos.

## Tarefas

- [x] e2e das rotas, primeiro falhando.
- [x] Store, exploração e DTOs do mapa.
- [x] `takeTamer` e a conferência da posição compartilhada.
- [x] As rotas da luta e o `tamer` no DTO.
- [x] A exploração apagada na derrota.
- [x] `POST /exploration/tamers` e o `DELETE /exploration/spawns`.
- [x] Atualizar a arquitetura da biome-encounters, rodar a verificação e mudar o status aqui e no README.

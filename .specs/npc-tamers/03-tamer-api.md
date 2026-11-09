# 03. Rotas dos Domadores

- **Status:** rascunho
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

- [ ] `POST /v1/me/exploration` traz `tamers`, sem `size` nem `team`.
- [ ] Um e2e com o Domador posto por `POST /exploration/tamers` de tamanho 3 abre a luta com 3 vagas inimigas, sem fuga (`can_flee: false`) e com `tamer.source` `"map"`.
- [ ] Um jogador com só 1 Ecobeast de pé contra um Domador de 3 começa com 1 vaga do seu lado.
- [ ] Pedir a mesma luta duas vezes: a segunda responde "Nenhum Domador por aqui.".
- [ ] `/board-battle/wild` num hexágono com Domador e selvagem responde "Um Domador está esperando você aqui.", e o selvagem continua na exploração.
- [ ] Depois de uma derrota contra Domador do mapa, `/board-battle/wild` responde `404`.
- [ ] `/board-battle/challenge` abre uma luta com `tamer.source` `"challenge"` e `tamer_id` `null`, mesmo sem exploração.
- [ ] `POST /exploration/tamers` responde `404` com `ENABLE_TEST_BATTLE` desligada.
- [ ] `typecheck`, `lint`, `npm test` e `npm run test:e2e` sem erros.

## Desenho técnico

- `server/src/exploration/exploration.store.ts`: `tamers` no `StoredExploration` e `delete(userId)`.
- `server/src/exploration/exploration.service.ts`: o sorteio dos Domadores no `start` (lendo os ids de `npc_tamer_names` e `npc_tamer_greetings`), o `debugTamer` e o `debugClear` com Domadores. O `loadSpawnSpecies` passa a servir as duas coisas.
- `server/src/exploration/exploration.dto.ts`: `MapTamerDto`, `tamers` no `ExplorationMapDto`, `DebugTamerBodyDto` e `DebugTamerResponseDto`.
- `server/src/exploration/exploration.controller.ts`: a rota `POST tamers`.
- `server/src/battle/battle-records.service.ts`: a conferência de posição sai do `takeSpawn` para uma função que o `takeTamer` também usa. `takeTamer(userId, position)` tira o Domador. O `finish` recebe de onde veio o Domador, para apagar a exploração na derrota.
- `server/src/battle/battle.store.ts`: o `tamer` (`{nameId, source}`) na entrada da luta.
- `server/src/board-battle/board-battle.service.ts`: `startTamer` e `startChallenge`, e o `begin` com `opponent`, as vagas dos dois lados e o `tamer`.
- `server/src/board-battle/board-battle.controller.ts` e `board-battle.dto.ts`: as duas rotas, `tamer_id` na resposta e `tamer` no `BoardBattleDto`.
- `server/src/board-battle/board-battle.mapper.ts`: o `tamer` no DTO.
- `server/test/`: os e2e de cada critério. Eles não conferem os valores sorteados.
- `.specs/biome-encounters/architecture.md`: a seção "Exploração no servidor" cita os Domadores.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

- Em `/docs`, chamar as rotas e conferir os exemplos.

## Tarefas

- [ ] e2e das rotas, primeiro falhando.
- [ ] Store, exploração e DTOs do mapa.
- [ ] `takeTamer` e a conferência da posição compartilhada.
- [ ] As rotas da luta e o `tamer` no DTO.
- [ ] A exploração apagada na derrota.
- [ ] `POST /exploration/tamers` e o `DELETE /exploration/spawns`.
- [ ] Atualizar a arquitetura da biome-encounters, rodar a verificação e mudar o status aqui e no README.

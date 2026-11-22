# 01. Os contadores no servidor

- **Status:** concluída
- **Depende de:** o [README](README.md) e o [architecture.md](architecture.md) desta iniciativa

## Contexto

O pedido e as decisões estão no [README](README.md), e as tabelas, os 18 contadores e onde cada um sobe estão no [architecture.md](architecture.md). Esta fase cria o catálogo `counters` e as linhas do jogador, faz a luta, a Loja, o Refúgio e Explorar contarem, e abre a leitura `GET /v1/me/counters`. O sinal de cada minuto é a [fase 2](02-play-ping.md), e a tela, a [fase 3](03-profile-screen.md). O jogo só precisa aceitar a tabela nova do catálogo.

## Escopo

- A migration `counters` (catálogo, `player_counters`, `creature_instances.battles`, `players.last_ping_at` e `players.last_play_day`), o `schema.prisma`, o `seed-data/counters.json`, o `CATALOG_TABLES` e o espelho no `catalog_schema.gd` e no `.specs/game-data/architecture.md`.
- O módulo `server/src/counters/` com a leitura e as escritas.
- Os incrementos da luta, da Loja, do Refúgio e de Explorar.

## Fora do escopo

- Os contadores 9, 10 e 16 a 18 só ganham a linha no catálogo; quem sobe é a [fase 2](02-play-ping.md).
- A tela.

## Requisitos

- **RF-01:** O catálogo `counters` tem os 18 contadores do [architecture.md](architecture.md), com os mesmos ids, slugs, nomes e `subject`, e entra no `GET /v1/catalog`.
- **RF-02:** No fim de uma luta, sobem `wins_wild` (vitória contra selvagem), `wins_tamer` (vitória contra Domador) ou `defeats` (derrota), conforme o `state.result` e o `state.opponent`.
- **RF-03:** Na luta que termina em captura, `captures` sobe pelo número de capturados, cada capturado sobe 1 em `captures_by_element` para cada Elemento da espécie e 1 em `captures_by_day_phase` na parte do dia de agora, e `captures_first_sphere` sobe 1 se a luta gastou uma Esfera só.
- **RF-04:** `spheres_used` sobe pelas Esferas gastas (o `used` dos itens com `captureBonus`), em qualquer resultado.
- **RF-05:** `xp_gained` sobe pela soma do XP ganho pela equipe, e `coins_earned` pelo `coinsChange` quando ele é positivo.
- **RF-06:** Cada Ecobeast que lutou (a união dos `foughtBy` dos inimigos) ganha +1 em `creature_instances.battles`, na vitória, na derrota, na fuga e na captura.
- **RF-07:** Nada da RF-02 à RF-06 acontece na luta `sandbox`, com `noRewards` ou com `godMode`.
- **RF-08:** Os incrementos da luta entram na mesma transação do `saveTeam`, a da Loja na transação do `buy` e os do Refúgio e de Explorar junto da escrita deles.
- **RF-09:** Uma compra na Loja sobe `coins_spent` pelo preço pago.
- **RF-10:** Uma cura no Refúgio que dá certo (`POST /v1/me/heal`) sobe `heals` em 1.
- **RF-11:** Abrir uma exploração (no mapa sorteado ou numa ilha) sobe `maps_explored` em 1.
- **RF-12:** `GET /v1/me/counters` devolve `counters` (as linhas do jogador, com `counter_id`, `subject_id` e `value`), `partner` (o Ecobeast do jogador com mais `battles`, nulo enquanto nenhum lutou, com `creature_uid`, `species_id` e `battles`), `created_at` (do Domador) e `walkable_biomes` (os biomas do catálogo onde o Domador anda, pelo `blocksWalking` do gerador: sem a água e, desde a `volcano`, sem a lava). Sem Domador, responde 404 como as outras rotas de `/v1/me`.
- **RF-13:** Apagar o progresso apaga as linhas do jogador junto (FK em cascata).

## Critérios de aceite

- [x] O jogo abre com o servidor no ar e o `CatalogValidator` aceita a tabela `counters`.
- [x] Vencer um selvagem, depois perder, mostra `wins_wild` 1 e `defeats` 1 no `GET /v1/me/counters`.
- [x] Capturar um Ecobeast de dois Elementos com uma Esfera sobe `captures` 1, `captures_first_sphere` 1, `spheres_used` 1, uma linha de `captures_by_element` em cada Elemento e uma de `captures_by_day_phase`.
- [x] Uma luta de teste da Técnica não muda nenhum contador.
- [x] Comprar um item de 50 moedas sobe `coins_spent` em 50; curar sobe `heals` em 1; abrir Explorar sobe `maps_explored` em 1.
- [x] O `partner` é o Ecobeast que mais lutou.

## Desenho técnico

**Banco** (`server/prisma/migrations/<data>_counters/migration.sql`, escrito à mão e aplicado com `migrate deploy`):

- `counters`: `id SERIAL`, `slug` único com o CHECK `^[a-z0-9_]+$`, `name`, `subject` com o CHECK `IN ('none','element','day_phase','biome')`; os 18 `INSERT` e o `setval`, como na migration `day_phases`.
- `player_counters`: a chave (`player_id`, `counter_id`, `subject_id`), `subject_id INT NOT NULL DEFAULT 0`, `value INT NOT NULL DEFAULT 0` com o CHECK `>= 0`, FK `players` em cascata, FK `counters` restrict e o índice `player_counters_ranking_idx` em (`counter_id`, `subject_id`, `value` DESC).
- `creature_instances.battles INT NOT NULL DEFAULT 0`, CHECK `>= 0`.
- `players.last_ping_at TIMESTAMPTZ(3)` e `players.last_play_day DATE`, nulos.
- `schema.prisma`: os modelos `Counter` (`@@map("counters")`) e `PlayerCounter` (`@@map("player_counters")`), as colunas novas e as relações. `server/prisma/seed-data/counters.json` com as 18 linhas.
- `server/src/catalog/catalog-tables.ts`: `table('counters', 'counter')` depois de `day_phases`, e o comentário e o `catalog-tables.spec.ts` passam de 51 para 52 tabelas.

**Domínio** (`server/src/domain/counters/`, sem Nest nem Prisma):

- `counters.ts`: `COUNTER_IDS`, o mapa de slug para id dos 18, e o tipo `CounterIncrement = { counterId: number; subjectId: number; amount: number }`.
- `battle-counters.ts`: `battleCounters(state: BattleState, input: { dayPhaseId: number; sphereItemIds: Set<number> }): CounterIncrement[]` (o Elemento de cada capturado vem do próprio `Combatant`, `elementIds` e `captured`), que segue a RF-02 à RF-05 e junta os incrementos iguais; e `foughtCreatureIndices(state: BattleState): number[]`, a RF-06.

**Serviço** (`server/src/counters/`):

- `counters.service.ts`: `increments(userId, list: CounterIncrement[], client = this.prisma): Prisma.PrismaPromise<unknown>[]`, um `upsert` com `increment` por item (o `client` aceita o `tx` de uma transação interativa); e `read(userId): Promise<CountersView>`, com a RF-12.
- `counters.controller.ts` em `@Controller('me/counters')`, com `@Get()` e a doc no `/docs` como as outras rotas.
- `counters.module.ts`, exportando o serviço, importado no `app.module.ts`.

**Onde sobe:**

- `BattleRecordsService.saveTeam` (`server/src/battle/battle-records.service.ts`): o `battleCounters` e os `battles` de `foughtCreatureIndices` entram no array do `$transaction`. A luta `sandbox` já não chega ao `finish` (o `BoardBattleService.act` volta antes), e o `saveTeam` pula os contadores com `godMode` ou `noRewards`. A parte do dia vem do `dayPhaseAt(minuteOfDay(Date.now()), phases)`, como o `ProgressionService` já faz.
- `InventoryService.buy`: o incremento de `coins_spent` pelo `tx`.
- `PlayerService.heal` e `ExplorationService.start` e `startIsland`: o incremento depois da escrita que já fazem.

**Jogo:** `res://core/data/catalog_schema.gd` ganha `"counters"` com `id`, `slug`, `name` e `subject` (texto). O `catalog.gd` só guarda as linhas; o modelo `Counter` é da [fase 3](03-profile-screen.md).

## Verificação

- `cd server && npm test` (os testes de `battle-counters.spec.ts`) e `npm run test:e2e` com os e2e tocados: o novo `test/counters.e2e-spec.ts`, mais `catalog`, `bundle`, `database`, `seed`, `shop`, `heal` e `board-battle`. A suíte inteira antes do commit.
- `godot --headless --path client --quit-after 30` com o servidor no ar, sem erro do `CatalogValidator`.

## Tarefas

- [x] **Domínio, primeiro os testes.** `server/src/domain/counters/battle-counters.spec.ts`, com o `BattleState` de `server/src/domain/battle/testing.ts`:
  - vitória contra `wild` → `[{counterId: 1, subjectId: 0, amount: 1}]` mais `xp_gained` e `coins_earned` quando há XP e moedas;
  - vitória contra `tamer` → `wins_tamer`; `defeat` → `defeats`; `fled` → nem vitória nem derrota;
  - `captured` com um capturado Água/Volt e uma Esfera gasta → `captures` 1, `captures_first_sphere` 1, `spheres_used` 1, `captures_by_element` 1 em cada Elemento e `captures_by_day_phase` 1 no `dayPhaseId`;
  - captura com 2 Esferas gastas → sem `captures_first_sphere`;
  - `coinsChange` negativo → sem `coins_earned`;
  - `foughtCreatureIndices` devolve a união sem repetir, com dois inimigos enfrentados pelo mesmo Ecobeast.
  Rode, veja falhar, escreva `counters.ts` e `battle-counters.ts`, rode até passar.
- [x] **Banco.** A migration, o `schema.prisma`, o `counters.json`, o `CATALOG_TABLES` (52) e o `catalog_schema.gd`; `npx prisma migrate deploy` e `npx prisma generate`; o espelho em `.specs/game-data/architecture.md`. Rode o `catalog-tables.spec.ts` e os e2e `catalog`, `bundle`, `database` e `seed`: o `database` ganha os casos `expectRejected` do CHECK do `subject` e do `value` negativo.
- [x] **Leitura.** `test/counters.e2e-spec.ts` com `GET /v1/me/counters` de um Domador novo (lista vazia, `partner` nulo, `walkable_biomes` igual ao número de biomas que não são água) e sem Domador (404). Escreva o serviço, o controller e o módulo até passar.
- [x] **Luta.** No mesmo e2e, pelo `test/support/wild.ts` e `board-play.ts`: vencer, perder e capturar mudam os contadores e o `partner` como nos critérios; a luta `skill-test` não muda nada. Ligue o `saveTeam`.
- [x] **Loja, Refúgio e Explorar.** Casos no mesmo e2e para `coins_spent`, `heals` e `maps_explored`; ligue os três serviços.
- [x] Rode a suíte inteira, abra o jogo sem janela, marque as tarefas e mude o status desta fase e da tabela do [README](README.md) para `concluída`.

## Notas da implementação

- Os 2 casos do `test/seed.e2e-spec.ts` que conferem `species_day_phases` e `species_skills` contra o `seed-data` falham desde antes desta fase: o dono editou essas tabelas no painel. A suíte e2e passou no resto.

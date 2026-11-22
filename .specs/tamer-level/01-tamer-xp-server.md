# 01. O XP do Domador no servidor

- **Status:** concluída
- **Depende de:** [player-stats/01](../player-stats/01-counters-server.md) (o fim da luta conta na mesma transação), [codex](../codex/) (as espécies novas), [skill-test](../skill-test/) (o `noRewards`)

## Contexto

O [README](README.md) decidiu o desenho. Esta fase faz o servidor dar XP ao Domador no fim de cada luta, subir o nível e pagar a recompensa de cada nível. O jogo ainda não mostra nada de novo: isso fica para a [02](02-tamer-level-client.md). A única exceção é o `CatalogValidator`, que precisa aceitar as tabelas novas, senão o jogo não abre.

Hoje:

- `players.level` existe (CHECK de 1 a 100) e fica sempre em 1. Não há coluna de XP.
- O `awardXp` (`server/src/domain/battle/experience.ts`) calcula o `total` de cada inimigo derrubado, mas sai mais cedo quando ninguém pode receber (todos no `MAX_LEVEL` ou caídos), e só soma o `xpEarned` de quem recebe.
- O `BattleRecordsService.finish` (`server/src/battle/battle-records.service.ts`) grava tudo numa transação em lote (`$transaction([...])`). As espécies novas (`registeredSpeciesIds`) saem do resultado da última escrita, pelo `CodexService.newlyCaught`.
- O `BoardBattleService` (`server/src/board-battle/board-battle.service.ts`) monta a resposta do turno com o `progression` e o `registered_species_ids` (`BoardTurnDto`, em `board-battle.dto.ts`).

## Escopo

- As tabelas `tamer_levels` e `tamer_xp_sources` no schema `ecobeasts`, com as linhas iniciais, no seed e no catálogo.
- A coluna `players.xp`.
- As regras puras com testes.
- O XP bruto dos inimigos no estado da luta.
- O XP, a subida de nível e as recompensas no fim da luta.
- O `tamer_progress` na resposta do turno e o `xp`, o `level_xp` e o `next_level_xp` no `PlayerDto`.
- O `CatalogValidator` aceitando e conferindo as duas tabelas.

## Fora do escopo

- Qualquer tela: a barra, o Perfil e o aviso ficam para a [02](02-tamer-level-client.md).
- As fontes da [auralis](../auralis/) (`island_tamer_win`, `island_tamer_rematch`, `quest`, `arena`, `island_unlocked`): as linhas entram no catálogo, mas nada as paga ainda.
- Dar XP retroativo aos jogadores de antes.

## Requisitos

- **RF-01:** `tamer_levels` tem uma linha por nível, de 1 a 99. O `xp_total` é `round(40 × (n − 1) + 0,8 × (n − 1)³)`, ou seja, 0 no 1, 41 no 2, 943 no 10, 20.671 no 30, 96.079 no 50 e 756.874 no 99.
- **RF-02:** cada nível de 2 a 99 paga `reward_coins = 50 + 10 × n`. Os níveis 5, 15, 25… (múltiplos de 5 que não são de 10) pagam 3 Esferas de Vínculo (`bond_sphere`, id 1). Os níveis 10, 20, 30… pagam 3 Esferas Reforçadas (`reinforced_sphere`, id 2). O nível 1 tem 0 moedas e nenhum item. Os valores ficam marcados como _a revisar_.
- **RF-03:** `tamer_xp_sources` tem as 8 linhas do README: `battle_xp_percent` 10, `new_species` 100, `tamer_win` 50, `island_tamer_win` 150, `island_tamer_rematch` 15, `quest` 100, `arena` 500 e `island_unlocked` 1000.
- **RF-04:** na vitória, o Domador ganha `floor(XP bruto × battle_xp_percent / 100)`. O XP bruto é a soma do `total` de cada inimigo derrubado na luta (o `xpYield`, com o `TAMER_XP_MULTIPLIER` contra Domador), contado mesmo quando nenhum Ecobeast recebe XP por estar no nível 100.
- **RF-05:** no fim de uma luta com captura, cada espécie em `registeredSpeciesIds` dá `new_species` XP ao Domador.
- **RF-06:** na vitória contra Domador (`state.opponent === 'tamer'`), o Domador ganha `tamer_win` XP.
- **RF-07:** derrota e fuga não dão XP ao Domador. Uma captura dá só o `new_species`, quando houver espécie nova.
- **RF-08:** com `godMode` ou `noRewards`, o Domador não ganha XP.
- **RF-09:** quando o XP passa de um ou mais `xp_total`, o nível sobe todos eles numa vez, e cada nível subido paga as moedas e o item dele, uma vez só, na mesma transação do fim da luta.
- **RF-10:** no nível máximo (a maior linha de `tamer_levels`), o XP continua somando e o nível não sobe.
- **RF-11:** a resposta do turno ganha `tamer_progress`, nulo quando a luta não terminou ou quando o Domador não ganhou XP. Quando vem, traz `xp_gained`, `level_before`, `level_after`, `current_xp`, `level_xp`, `next_level_xp` (nulo no máximo) e `levels` (`level`, `reward_coins`, `reward_item_id`, `reward_item_quantity` de cada nível subido, em ordem).
- **RF-12:** o `PlayerDto` ganha `xp`, `level_xp` e `next_level_xp` (nulo no máximo).
- **RF-13:** o `CatalogValidator` do jogo recusa um `tamer_levels` que não começa no 1 com `xp_total` 0, que tem buraco ou que não cresce, e uma linha com `reward_item_id` sem `reward_item_quantity` (ou o contrário).

## Critérios de aceite

- [x] `GET /v1/catalog` traz `tamer_levels` com 99 linhas e `tamer_xp_sources` com 8.
- [x] Vencer um selvagem cujo XP bruto é 85 dá 8 XP ao Domador, com a equipe abaixo do nível 100 ou toda nele.
- [x] Capturar uma espécie que não estava no Bestiário dá 100 XP. Capturar uma que já estava dá 0, e `tamer_progress` vem nulo.
- [x] Vencer um Domador NPC dá 50 XP mais a parte da luta.
- [x] Perder ou fugir não muda `players.xp`.
- [x] Com 30 XP, ganhar 60 leva ao nível 3 (90 XP, passando os 41 do 2 e os 86 do 3). As moedas sobem 70 + 80, e `levels` traz os níveis 2 e 3.
- [x] Chegar ao nível 5 põe 3 Esferas de Vínculo na Mochila.
- [x] A luta de teste da Técnica e a luta em modo deus não mudam `players.xp`.
- [x] `GET /v1/me` traz `xp`, `level_xp` e `next_level_xp`.
- [x] O jogo abre com o servidor no ar, sem erro do `CatalogValidator`.

## Desenho técnico

### Banco

- Migration nova `server/prisma/migrations/20270202000003_tamer_level/migration.sql`, com o SQL escrito à mão e aplicado por `migrate deploy` (o `migrate dev` trava neste projeto):
  - `tamer_levels`: `level INTEGER PRIMARY KEY` (CHECK ≥ 1), `xp_total INTEGER NOT NULL` (CHECK ≥ 0), `reward_coins INTEGER NOT NULL DEFAULT 0` (CHECK ≥ 0), `reward_item_id INTEGER NULL` (FK para `items`, `ON DELETE RESTRICT`), `reward_item_quantity INTEGER NULL`, mais o CHECK `(reward_item_id IS NULL) = (reward_item_quantity IS NULL)` e `reward_item_quantity ≥ 1`. As 99 linhas entram por um `INSERT ... SELECT` sobre `generate_series(1, 99)`, com a fórmula do RF-01 e as recompensas do RF-02.
  - `tamer_xp_sources`: `id SERIAL`, `slug TEXT UNIQUE` com o CHECK `^[a-z0-9_]+$`, `name TEXT`, `amount INTEGER` (CHECK ≥ 0), as 8 linhas e o `setval`, como na migration `counters`.
  - `players.xp INTEGER NOT NULL DEFAULT 0` com CHECK ≥ 0.
- `server/prisma/schema.prisma`: os models `TamerLevel` e `TamerXpSource`, a relação com `Item` e o `xp` do `Player`.
- `server/prisma/seed-data/tamer_levels.json` e `tamer_xp_sources.json` com as mesmas linhas da migration. As 99 linhas de `tamer_levels` são geradas pela mesma fórmula, por um script único, e conferidas contra o SQL.
- `server/src/catalog/catalog-tables.ts`: `table('tamer_levels', 'tamerLevel', ['level'])` depois de `items`, e `table('tamer_xp_sources', 'tamerXpSource')`. A contagem do comentário e o `catalog-tables.spec.ts` sobem 2.

### Regras puras: `server/src/domain/progression/tamer-level.ts`

```ts
export interface TamerLevelRow { level: number; xpTotal: number; rewardCoins: number; rewardItemId: number | null; rewardItemQuantity: number | null; }
export type TamerXpSources = ReadonlyMap<string, number>; // slug → amount
export interface TamerBattleInput { rawEnemyXp: number; victory: boolean; opponentIsTamer: boolean; newSpeciesCount: number; }
export function tamerXpFromBattle(input: TamerBattleInput, sources: TamerXpSources): number;
export interface TamerLevelUp { xp: number; level: number; levels: TamerLevelRow[]; }
export function addTamerXp(xp: number, level: number, gained: number, levels: readonly TamerLevelRow[]): TamerLevelUp;
export function levelBounds(level: number, levels: readonly TamerLevelRow[]): { levelXp: number; nextLevelXp: number | null };
```

Uma fonte que falta no mapa vale 0. `levels` chega ordenado por `level`.

### Estado da luta

- `BattleState` (`server/src/domain/battle/types.ts`) ganha `rawEnemyXp: number`, que começa em 0 onde o estado nasce (`board-battle.service.ts` e os dois `testing.ts`).
- `awardXp` soma o `total` em `state.rawEnemyXp` logo depois do `if (state.noRewards) return;` e antes do filtro de quem recebe.

### Fim da luta

- `TamerLevelService` (`server/src/tamer-level/`, no `TamerLevelModule`, separado do `PlayerModule` porque ele já importa o `BattleModule`): `levels()`, `catalog()` (os níveis e as fontes) e `award(userId, gained, levels)`, que devolve as escritas para a transação de quem chama e o `TamerProgressDto`. A auralis usa o mesmo `award`.
- `BattleRecordsService.finish` (pelo `tamerAward`):
  - calcula as espécies novas antes de montar a transação, lendo o Bestiário do jogador;
  - chama `tamerXpFromBattle` e o `award`;
  - quando o ganho é maior que 0, põe na mesma transação o `player.update` (`xp: { increment }`, `level` e `coins: { increment }` com a soma das moedas dos níveis subidos) e um `inventoryItem.upsert` por item, como o `InventoryService.buy`.
  - Fica de fora com `godMode` ou `noRewards`.
  - A moeda da recompensa de nível não entra no contador `coins_earned`, que é das lutas.
- `BattleFinish` ganha `tamerProgress: TamerProgressDto | null`, e o `NOT_FINISHED` do `BoardBattleService` leva `null`.
- `TamerProgressDto` e `TamerLevelRewardDto` em `server/src/tamer-level/tamer-level.dto.ts`, com `@ApiProperty` em pt-BR; o `tamer_progress` da resposta do turno (`board-battle.dto.ts`) usa os dois.

### Jogador

- `PlayerDto` (`server/src/player/player.dto.ts`) e `toPlayerDto(row, tamerLevels)` (`player.mapper.ts`): `xp`, `level_xp` e `next_level_xp`, pelo `levelBounds`; o `PlayerService` passa as linhas do `TamerLevelService.levels()`.

### Jogo

- `res://core/data/catalog_validator.gd`: as regras do RF-13 para `tamer_levels` e a FK de `reward_item_id` para `items`. `tamer_xp_sources` só tem o slug único conferido.

## Verificação

- `cd server && npm test`: o novo `domain/progression/tamer-level.spec.ts`, o `experience.spec.ts` (o `rawEnemyXp` soma mesmo com a equipe no 100 e fica em 0 com `noRewards`) e o `catalog-tables.spec.ts`.
- `npm run test:e2e`: o novo `test/tamer-level.e2e-spec.ts`, com os casos dos critérios (o Domador novo no `/v1/me`, a vitória com a equipe no nível 100, o Domador NPC, a captura nova e a repetida, a derrota, o `godMode` e a luta de teste, e vários níveis com as moedas e os itens), com os valores lidos do catálogo. A suíte inteira antes do commit.
- `godot --headless --path client --quit-after 30` com o servidor no ar, sem erro do `CatalogValidator`.

## Tarefas

- [x] `tamer-level.ts` com os testes primeiro: fontes que faltam, derrota sem XP, captura nova, Domador, vários níveis numa vez, máximo parado com XP somando e `levelBounds` no máximo.
- [x] `rawEnemyXp` no `BattleState` e no `awardXp`, com o teste da equipe no nível 100.
- [x] Migration, `schema.prisma`, `seed-data` e `catalog-tables.ts`; `prisma generate` e `migrate deploy`.
- [x] `CatalogValidator` com as regras do RF-13.
- [x] `BattleRecordsService.finish` com o XP, o nível e as recompensas; `tamer_progress` no DTO e no `BoardBattleService`.
- [x] `PlayerDto` com `xp`, `level_xp` e `next_level_xp`.
- [x] e2e dos critérios de aceite; suíte inteira; status desta fase e da tabela do README.

# 02. Schema do banco

- **Status:** concluída
- **Depende de:** [01-server-setup](01-server-setup.md)

## Contexto

O servidor conecta no Supabase, mas o banco está vazio. Esta fase escreve no `server/prisma/schema.prisma` todas as tabelas do jogo: as 23 do catálogo e as 5 do estado do jogador. Depois gera a primeira migration, com as faixas de valor como `CHECK`, e a aplica no projeto Supabase. As colunas, tipos, nulidade, chaves e faixas são os de [game-data/architecture.md](../game-data/architecture.md) e do espelho em código `client/core/data/catalog_schema.gd`. As convenções (schema `ecobeasts`, nomes, ids, FKs) estão em [architecture.md](architecture.md#banco).

## Escopo

- Os 28 modelos no `schema.prisma`, agrupados em blocos comentados.
- A migration `init`, com os `CHECK` acrescentados à mão.
- Testes que provam que o banco recusa valores fora da faixa.

## Fora do escopo

- Dados (carga inicial em [03](03-catalog-seed.md)).
- Regras de consistência entre linhas (por exemplo, toda espécie tem stat de cada tipo). O `CatalogValidator` do cliente continua conferindo essas regras sobre o catálogo baixado ([07](07-client-remote-catalog.md)).
- Tabelas futuras (itens, zonas, clima, Domadores NPC, Arenas).

## Requisitos

**Modelos**

- **RF-01:** Cada tabela vira um modelo com o nome abaixo, `@@map("<tabela>")` e `@@schema("ecobeasts")`, se a versão do Prisma exigir. Os campos são a coluna em `camelCase`, com `@map("<coluna>")` quando o nome difere. A conversão é sempre mecânica (`growth_rate_id` → `growthRateId`), para o código poder converter linhas nos dois sentidos sem tabela de nomes.

| Bloco      | Tabela → modelo |
| ---------- | --------------- |
| Referência | `elements` → `Element`, `element_efficacy` → `ElementEfficacy`, `stats` → `Stat`, `growth_rates` → `GrowthRate`, `rarities` → `Rarity`, `temperaments` → `Temperament`, `skill_categories` → `SkillCategory`, `skill_targets` → `SkillTarget`, `skill_learn_methods` → `SkillLearnMethod`, `status_conditions` → `StatusCondition`, `status_condition_immunities` → `StatusConditionImmunity`, `effect_types` → `EffectType`, `evolution_triggers` → `EvolutionTrigger` |
| Espécies   | `species` → `Species`, `species_elements` → `SpeciesElement`, `species_stats` → `SpeciesStat`, `traits` → `Trait`, `species_traits` → `SpeciesTrait`, `evolutions` → `Evolution`, `starter_options` → `StarterOption` |
| Técnicas   | `skills` → `Skill`, `skill_effects` → `SkillEffect`, `species_skills` → `SpeciesSkill` |
| Jogador    | `players` → `Player`, `creature_instances` → `CreatureInstance`, `creature_instance_stats` → `CreatureInstanceStat`, `creature_instance_skills` → `CreatureInstanceSkill`, `inventory_items` → `InventoryItem` |

- **RF-02:** As tabelas do catálogo têm exatamente as colunas, a nulidade e as chaves de `catalog_schema.gd`. Isso inclui as chaves compostas: `element_efficacy` (atacante, defensor), `status_condition_immunities` (status, elemento), `species_elements` e `species_traits` (espécie, slot), `species_stats` (espécie, stat), `species_skills` (espécie, Técnica, método) e `starter_options` (espécie). Os tipos são: `int` → `Int`; `float` → `Float` (precisão dupla, nunca `Decimal`); `string` → `String`; `bool` → `Boolean`. As tabelas com `id` usam `Int @id @default(autoincrement())`.
- **RF-03:** Slugs são únicos em cada tabela. `rarities.sort_order` e `starter_options.sort_order` são únicos.
- **RF-04:** Cada FK de `catalog_schema.gd` vira uma relação com `onDelete: Restrict`. Quando a mesma tabela aparece duas vezes, a relação tem nome (`attacker_element_id` e `defender_element_id`; `species_id` e `evolved_species_id`; `increased_stat_id` e `decreased_stat_id`; `evolves_from_species_id`). As colunas `fk_future` (`skill_effects.weather_id`, `evolutions.item_id`, `evolutions.zone_id`) ficam como `Int?` sem relação, com o comentário `/// FK futura: <tabela>`. Toda coluna FK tem índice.
- **RF-05:** Tabelas do jogador:
  - `players`: `id` UUID (`@default(uuid())`), `name`, `level` (padrão 1), `coins` (padrão 0), `created_at` (`DateTime @default(now())`, com fuso).
  - `creature_instances`: `uid` UUID; `player_id` (relação, `onDelete: Cascade`); `species_id`, `temperament_id` e `trait_id` (relações, `Restrict`); `nickname?`, `level`, `current_xp`, `current_hp`, `gender` (enum `Gender`: `male`, `female`, `none`), `is_prismatic`, `bond`; `held_item_id?` (FK futura `items`); `status_condition_id?` (relação, `Restrict`); `location` (enum `CreatureLocation`: `party`, `storage`), `party_slot?`; `original_player_id` (UUID sem relação, porque o Domador original pode não existir mais); `caught_at` (`DateTime`, com fuso); `caught_zone_id?` (FK futura `zones`). Único: (`player_id`, `party_slot`).
  - `creature_instance_stats`: chave (`creature_uid`, `stat_id`); `genes`, `training_points`; relação com a criatura em `Cascade`.
  - `creature_instance_skills`: chave (`creature_uid`, `slot`); `skill_id` (relação, `Restrict`), `current_pp`; relação com a criatura em `Cascade`.
  - `inventory_items`: chave (`player_id`, `item_id`); `item_id` (FK futura `items`), `quantity`; relação com o jogador em `Cascade`.
- **RF-06:** O arquivo é dividido nos blocos Referência, Espécies, Técnicas e Jogador, cada um com um comentário de título. Cada modelo tem um `///` de uma linha dizendo o que guarda.

**Faixas (`CHECK`)**

- **RF-07:** A migration `init` é criada com `prisma migrate dev --create-only --name init`. Os `CHECK` abaixo são acrescentados no fim do SQL dela antes de aplicar, com nome `<tabela>_<coluna>_check`. Cada campo com `CHECK` tem no `schema.prisma` o comentário `/// CHECK <faixa> (migration init)`. Coluna anulável aceita `NULL`.

| Tabela | Faixas |
| ------ | ------ |
| todas as com `slug` | `slug ~ '^[a-z0-9_]+$'` |
| `elements` | `color_hex ~ '^#[0-9A-Fa-f]{6}$'` |
| `element_efficacy` | `multiplier IN (0, 0.5, 2)` |
| `growth_rates` | `xp_multiplier` 0.1–10 |
| `species` | `base_xp_yield ≥ 1`; `capture_rate` 3–255; `gender_ratio` −1–1; `height_m ≥ 0`; `weight_kg ≥ 0` |
| `species_elements` | `slot IN (1, 2)` |
| `species_stats` | `base_value` 1–255; `training_yield` 0–3 |
| `species_traits` | `slot IN (1, 2, 3)` |
| `skills` | `power` 0–250; `accuracy` 0–100; `max_pp` 5–40; `priority` −7–5; `crit_stage` 0–3; `min_hits` 1–10; `max_hits` 1–10 |
| `skill_effects` | `sort_order ≥ 1`; `chance` 1–100; `stages` −6–6; `percent` 1–100; `value ≥ 1`; `min_turns ≥ 1`; `weather_id IS NULL` |
| `species_skills` | `level` 0–100 |
| `evolutions` | `min_level` 1–100; `min_bond` 0–255; `time_of_day IN ('day', 'night')`; `item_id IS NULL`; `zone_id IS NULL` |
| `players` | `level` 1–100; `coins ≥ 0` |
| `creature_instances` | `level` 1–100; `current_xp ≥ 0`; `current_hp ≥ 0`; `bond` 0–255; `party_slot` 1–6; `(location = 'party') = (party_slot IS NOT NULL)`; `held_item_id IS NULL`; `caught_zone_id IS NULL` |
| `creature_instance_stats` | `genes` 0–31; `training_points` 0–252 |
| `creature_instance_skills` | `slot` 1–4; `current_pp ≥ 0` |
| `inventory_items` | `quantity ≥ 1` |

- **RF-08:** A migration aplicada cria o schema `ecobeasts` com as 28 tabelas, e o `public` continua sem tabelas do jogo. Isso inclui o histórico de migrations do Prisma (`_prisma_migrations`), que também fica em `ecobeasts`.

## Critérios de aceite

- [x] `npx prisma validate` passa, e `npx prisma migrate status` diz que o banco está em dia com a migration `init`.
- [x] No painel do Supabase (Table Editor, schema `ecobeasts`), as 28 tabelas aparecem com os nomes do RF-01.
- [x] `npx prisma migrate dev` logo depois não gera migration nova, porque o schema e o banco estão iguais, e não tenta apagar os `CHECK`.
- [x] Pelo painel, mudar a `accuracy` de uma Técnica de teste para 150 é recusado pelo banco. (Feito no teste automático do RF-07; o dono pode repetir à mão depois da [03](03-catalog-seed.md).)
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/prisma/migrations/<data>_init/migration.sql` (gerado + `CHECK` à mão).
- `server/test/database.e2e-spec.ts`: cada caso roda numa transação interativa do Prisma, que cria os pais válidos que precisar, tenta a linha inválida, confere o erro e desfaz tudo lançando uma exceção no fim. O banco fica como estava.

**Alterar**

- `server/prisma/schema.prisma`: os 28 modelos, os 2 enums e os comentários.

## Verificação

Da pasta `server/`:

```bash
npx prisma validate
npx prisma migrate status
npm run test:e2e
```

## Tarefas

- [x] Modelos do bloco Referência (RF-01 a RF-04, RF-06).
- [x] Modelos dos blocos Espécies e Técnicas.
- [x] Modelos do bloco Jogador e enums (RF-05).
- [x] `prisma migrate dev --create-only --name init`; acrescentar os `CHECK` do RF-07 ao SQL; comentários `/// CHECK` no schema; aplicar com `prisma migrate dev`.
- [x] Testes e2e de recusa, um por grupo:
  - `skills.accuracy = 150`;
  - `elements.color_hex = 'red'`;
  - `element_efficacy.multiplier = 1.5`;
  - `species_elements.slot = 3`;
  - `evolutions.time_of_day = 'dusk'`;
  - `creature_instance_stats.genes = 32`;
  - `creature_instances` com `location = 'party'` e `party_slot = NULL`.
  
  Mais um caso válido que é aceito: uma Técnica com `accuracy = 100`.
- [x] Teste e2e: apagar uma `species` usada por `species_elements` falha (`Restrict`); apagar um `player` com criatura apaga a criatura (`Cascade`).
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: schema do banco`.

## Decisões da implementação

- **Histórico de migrations em `ecobeasts`:** a CLI do Prisma criou `_prisma_migrations` no `public`, que é o schema que a API automática do Supabase publica. O `prisma.config.ts` agora acrescenta `schema=ecobeasts` à `DIRECT_URL`, sem mudar o `.env`, e a tabela foi movida (`ALTER TABLE … SET SCHEMA`). Um teste e2e confere que o `public` fica vazio e que o `ecobeasts` tem as 28 tabelas mais o histórico.
- **`@@unique([skillId, sortOrder])` em `skill_effects`:** é a regra "`sort_order` não se repete na mesma Técnica" do validador do cliente. Como o Prisma descreve essa regra direto, ela fica no `schema.prisma`, e não num `CHECK`.
- **`db:migrate` também gera o cliente:** no Prisma 7, `migrate dev` não roda mais o `generate`. O script passou a ser `prisma migrate dev && prisma generate`.
- **61 `CHECK`** na migration `20261024164323_init`: 14 de slug e 47 de faixas e regras de uma linha. Um `migrate dev --create-only` logo depois gera uma migration vazia, sinal de que o Prisma não tenta apagar os `CHECK`.
- **Testes:** `test/support/db.ts` (`attempt`: roda numa transação sempre desfeita e devolve `'accepted'` ou o erro) e `test/support/fixtures.ts` (linhas mínimas válidas). Os testes de recusa conferem o nome da restrição na mensagem do erro.

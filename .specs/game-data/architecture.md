# Arquitetura

O modelo relacional do catálogo, o formato dos arquivos e como o jogo os lê.

## Convenções

- **Arquivo = tabela.** `res://data/<tabela>.json` contém um array JSON; cada elemento é uma linha (objeto) com exatamente as colunas da tabela.
- **Nomes** de tabelas e colunas em inglês, `snake_case`, tabelas no plural.
- **Chave primária:** `id` inteiro, começando em 1, estável (nunca renumerar nem reaproveitar). Tabelas de junção usam chave composta, indicada abaixo.
- **Chave estrangeira:** `<tabela_no_singular>_id` (`element_id`, `species_id`). Quando a mesma tabela aparece duas vezes, o nome diz o papel (`attacker_element_id`, `evolved_species_id`).
- **`slug`:** identificador em inglês, `snake_case`, único na tabela, para o código se referir a uma linha sem decorar ids (`GameData.get_stat_id("spd")`).
- **`name` e `description`:** texto em pt-BR, exibido ao jogador.
- **Nulo:** colunas marcadas com `?` aceitam `null`, e o valor sempre aparece na linha (nada de coluna omitida).
- **Números:** o `JSON` do Godot lê todo número como `float`; o carregador converte as colunas `int` para `int`.
- **Ordem das linhas** no arquivo não tem significado; ordenação é feita por coluna (`slot`, `level`, `sort_order`).

Tipos usados abaixo: `int`, `float`, `string`, `bool`. `FK → tabela` indica a chave estrangeira.

## Diagrama

```
elements ─┬─< element_efficacy (atacante × defensor)
          ├─< species_elements >── species ──< species_stats >── stats
          ├─< skills ──< skill_effects ──> effect_types, status_conditions, stats, skill_targets
          └─< status_condition_immunities >── status_conditions

species ──< species_traits >── traits
species ──< species_skills >── skills          (skill_learn_methods)
species ──< evolutions >── species              (evolution_triggers)
species ──> growth_rates, rarities, species (evolves_from)
species ──< starter_options
temperaments ──> stats (aumentado, diminuído)
```

## Tabelas do MVP

### Referência (preenchidas em [02-core-tables](02-core-tables.md))

**`elements`** — os 14 elementos.

| Coluna    | Tipo   | Observação                                 |
| --------- | ------ | ------------------------------------------ |
| id        | int    | 1 Fogo … 14 Arcano (ordem do GDD)          |
| slug      | string | `fire`, `water`, …                         |
| name      | string | "Fogo"                                     |
| color_hex | string | `#RRGGBB`, cor do elemento na interface    |
| is_rare   | bool   | `true` só para Arcano (elemento dos Ancestrais) |

**`element_efficacy`** — chave (`attacker_element_id`, `defender_element_id`). Só pares com multiplicador ≠ 1.

| Coluna              | Tipo  | Observação           |
| ------------------- | ----- | -------------------- |
| attacker_element_id | int   | FK → elements        |
| defender_element_id | int   | FK → elements        |
| multiplier          | float | `0`, `0.5` ou `2`    |

**`stats`** — atributos.

| Coluna         | Tipo   | Observação                                                       |
| -------------- | ------ | ---------------------------------------------------------------- |
| id             | int    |                                                                  |
| slug           | string | `hp`, `atk`, `def`, `sp_atk`, `sp_def`, `spd`, `accuracy`, `evasion` |
| name           | string | "Ataque Especial"                                                |
| short_name     | string | "Atq.E"                                                          |
| is_battle_only | bool   | `true` para precisão e evasão (só existem como estágio em batalha) |

**`growth_rates`** — curvas de XP. XP total para o nível n = `floor(xp_multiplier · n³)`.

| Coluna        | Tipo   | Observação         |
| ------------- | ------ | ------------------ |
| id            | int    |                    |
| slug          | string | `fast`, `medium`, `slow` |
| name          | string |                    |
| xp_multiplier | float  | 0,8 / 1,0 / 1,25   |

**`rarities`** — `id`, `slug` (`common`, `uncommon`, `rare`, `epic`, `ancestral`), `name`, `sort_order` (int).

**`temperaments`** — 25 combinações; neutro quando os dois stats são iguais.

| Coluna            | Tipo   | Observação                                 |
| ----------------- | ------ | ------------------------------------------ |
| id                | int    |                                            |
| slug              | string |                                            |
| name              | string | "Ousado"                                   |
| increased_stat_id | int    | FK → stats (só `atk`…`spd`, nunca `hp`)    |
| decreased_stat_id | int    | FK → stats (idem)                          |

**`skill_categories`** — `id`, `slug` (`physical`, `special`, `support`), `name`.

**`skill_targets`** — `id`, `slug` (`enemy`, `self`, `all`), `name`.

**`skill_learn_methods`** — `id`, `slug` (`level_up`, `evolution`, `teachable`), `name`.

**`status_conditions`** — `id`, `slug`, `name`, `is_volatile` (bool: some ao trocar de criatura).

**`status_condition_immunities`** — chave (`status_condition_id`, `element_id`): criaturas desse elemento não recebem o status.

**`effect_types`** — `id`, `slug`, `name`. Os tipos e as colunas de `skill_effects` que cada um usa:

| slug           | Colunas usadas em `skill_effects`                           |
| -------------- | ----------------------------------------------------------- |
| `apply_status` | `status_condition_id`, `chance`                             |
| `modify_stat`  | `skill_target_id`, `stat_id`, `stages` (−6 a +6), `chance`  |
| `heal`         | `percent` (do HP máximo de quem usa)                        |
| `drain`        | `percent` (do dano causado)                                 |
| `recoil`       | `percent` (do dano causado)                                 |
| `flinch`       | `chance`                                                    |
| `multi_turn`   | — (carrega no 1º turno, ataca no 2º)                        |
| `fixed_damage` | `value` (`null` = dano igual ao nível de quem usa)          |
| `set_weather`  | `weather_id` (tabela futura), `min_turns`                   |
| `protect`      | —                                                           |
| `switch`       | —                                                           |

**`evolution_triggers`** — `id`, `slug` (`level`, `item`, `bond`, `time_of_day`, `zone`, `trade`, `temperament`), `name`. No MVP só `level` é usado em `evolutions`.

### Conteúdo (preenchidas em [03-starter-content](03-starter-content.md))

**`species`**

| Coluna                  | Tipo    | Observação                                         |
| ----------------------- | ------- | -------------------------------------------------- |
| id                      | int     | Número no Bestiário                                |
| slug                    | string  | `fagulho`                                          |
| name                    | string  | "Fagulho"                                          |
| description             | string  | Texto do Bestiário                                 |
| growth_rate_id          | int     | FK → growth_rates                                  |
| rarity_id               | int     | FK → rarities                                      |
| base_xp_yield           | int     | XP dado ao ser derrotado                           |
| capture_rate            | int     | 3–255 (45 = difícil, 255 = fácil)                  |
| gender_ratio            | float   | Fração de machos, 0–1; `-1` = sem gênero           |
| height_m                | float   |                                                    |
| weight_kg               | float   |                                                    |
| evolves_from_species_id | int?    | FK → species; `null` na forma base                 |

**`species_elements`** — chave (`species_id`, `slot`). `slot` 1 = primário, 2 = secundário. `element_id` FK → elements.

**`species_stats`** — chave (`species_id`, `stat_id`). Uma linha para cada stat não exclusivo de batalha.

| Coluna         | Tipo | Observação                           |
| -------------- | ---- | ------------------------------------ |
| species_id     | int  | FK → species                         |
| stat_id        | int  | FK → stats (`is_battle_only = false`) |
| base_value     | int  | 1–255                                |
| training_yield | int  | 0–3: pontos de Treino dados ao vencedor |

**`traits`** — `id`, `slug`, `name`, `description`. O efeito em batalha é implementado no battle-core pelo `slug`.

**`species_traits`** — chave (`species_id`, `slot`).

| Coluna     | Tipo | Observação                         |
| ---------- | ---- | ---------------------------------- |
| species_id | int  | FK → species                       |
| trait_id   | int  | FK → traits                        |
| slot       | int  | 1 e 2 = normais; 3 = oculto        |
| is_hidden  | bool | `true` se, e só se, `slot = 3`     |

**`skills`**

| Coluna            | Tipo   | Observação                                   |
| ----------------- | ------ | -------------------------------------------- |
| id                | int    |                                              |
| slug              | string |                                              |
| name              | string | Sempre original                              |
| description       | string |                                              |
| element_id        | int    | FK → elements                                |
| skill_category_id | int    | FK → skill_categories                        |
| power             | int    | 0–250; 0 em técnicas de suporte              |
| accuracy          | int    | 0–100; 0 = nunca erra                        |
| max_pp            | int    | 5–40                                         |
| priority          | int    | −7 a +5                                      |
| crit_stage        | int    | 0 normal, 1 crítico alto                     |
| skill_target_id   | int    | FK → skill_targets                           |
| makes_contact     | bool   |                                              |
| min_hits          | int    | 1 normal                                     |
| max_hits          | int    | ≥ `min_hits`                                 |

**`skill_effects`** — chave `id`; cada técnica tem zero ou mais efeitos, aplicados na ordem de `sort_order`.

| Coluna              | Tipo  | Observação                                    |
| ------------------- | ----- | --------------------------------------------- |
| id                  | int   |                                               |
| skill_id            | int   | FK → skills                                   |
| effect_type_id      | int   | FK → effect_types                             |
| sort_order          | int   | 1, 2… dentro da técnica                       |
| chance              | int   | 1–100; 100 = sempre                           |
| skill_target_id     | int?  | FK → skill_targets (quem recebe, em `modify_stat`) |
| status_condition_id | int?  | FK → status_conditions                        |
| stat_id             | int?  | FK → stats                                    |
| stages              | int?  | −6 a +6, sem 0                                |
| percent             | int?  | 1–100                                         |
| value               | int?  |                                               |
| weather_id          | int?  | FK futura (`weathers`); `null` no MVP         |
| min_turns           | int?  |                                               |

Colunas que o tipo do efeito não usa ficam `null`.

**`species_skills`** — learnset e técnicas ensináveis. Chave (`species_id`, `skill_id`, `skill_learn_method_id`).

| Coluna                | Tipo | Observação                                               |
| --------------------- | ---- | -------------------------------------------------------- |
| species_id            | int  | FK → species                                             |
| skill_id              | int  | FK → skills                                              |
| skill_learn_method_id | int  | FK → skill_learn_methods                                 |
| level                 | int? | ≥ 1 em `level_up`; 0 em `evolution`; `null` em `teachable` |

**`evolutions`** — regras de Ascensão. Chave `id`.

| Coluna               | Tipo    | Observação                                  |
| -------------------- | ------- | ------------------------------------------- |
| id                   | int     |                                             |
| species_id           | int     | FK → species (de)                           |
| evolved_species_id   | int     | FK → species (para)                         |
| evolution_trigger_id | int     | FK → evolution_triggers                     |
| min_level            | int?    | Obrigatório com o gatilho `level`           |
| item_id              | int?    | FK futura (`items`); `null` no MVP          |
| min_bond             | int?    | 0–255                                       |
| time_of_day          | string? | `day` ou `night`                            |
| zone_id              | int?    | FK futura (`zones`); `null` no MVP          |

**`starter_options`** — chave `species_id` (FK → species); `sort_order` int. As espécies oferecidas na escolha do inicial.

## Tabelas futuras (só documentadas)

Entram com as iniciativas do [roadmap](../roadmap.md); não têm arquivo no MVP.

- `item_categories` (captura, cura, batalha, evolução, treino) e `items` (`id`, `slug`, `name`, `description`, `item_category_id`, `price`, `capture_bonus?`, `heal_amount?`…).
- `weathers`.
- `zones` (`id`, `slug`, `name`, `recommended_level`, `unlock_average_level`) e `zone_encounters` (`zone_id`, `species_id`, `min_level`, `max_level`, `spawn_weight`).
- `npc_tamers`, `npc_tamer_creatures`, `arenas` (`id`, `slug`, `name`, `element_id`, `npc_tamer_id`, `badge_name`, `sort_order`).

### Estado do jogador (no servidor)

O cliente nunca lê essas tabelas: recebe o jogador pronto, no formato do contrato descrito em [onboarding/architecture.md](../onboarding/architecture.md). Elas ficam registradas aqui para o banco do backend nascer junto com o catálogo.

- `players` (`id` uuid, `name`, `level`, `coins`, `created_at`).
- `creature_instances` (`uid` uuid, `player_id`, `species_id`, `nickname?`, `level`, `current_xp`, `current_hp`, `temperament_id`, `trait_id`, `gender`, `is_prismatic`, `bond`, `held_item_id?`, `status_condition_id?`, `location` `party`/`storage`, `party_slot?`, `original_player_id`, `caught_at`, `caught_zone_id?`).
- `creature_instance_stats` (`creature_uid`, `stat_id`, `genes` 0–31, `training_points` 0–252).
- `creature_instance_skills` (`creature_uid`, `slot` 1–4, `skill_id`, `current_pp`).
- `inventory_items` (`player_id`, `item_id`, `quantity`).

## Como o jogo lê o catálogo

```
res://data/*.json ──> StaticJsonDataSource ──> Catalog ──> GameData (autoload) ──> telas e serviços
                         (DataSource)          ▲
                                      CatalogValidator + CatalogSchema
```

- **`DataSource`** (`@abstract`): `load_tables(names: PackedStringArray) -> Dictionary` (nome da tabela → `Array[Dictionary]`) e `get_errors() -> Array[String]`. `StaticJsonDataSource` lê `res://data/<nome>.json`. No futuro, `HttpDataSource` baixa as mesmas tabelas da API, com uma versão do catálogo para guardar em cache.
- **`CatalogSchema`**: constante com cada tabela, sua chave, colunas, tipos, nulidade, FKs, FKs futuras, valores permitidos e faixas. É o espelho em código das tabelas acima; quando um muda, o outro muda no mesmo commit.
- **`CatalogValidator`**: confere as tabelas carregadas contra o schema e as regras de consistência ([01-data-layer](01-data-layer.md)) e devolve a lista de erros.
- **`Catalog`** (`RefCounted`): converte tipos, monta os índices e os modelos tipados de `res://domain/models/` e responde às consultas.
- **`GameData`** (autoload): cria `StaticJsonDataSource` + `Catalog` no `load_catalog()` e expõe as consultas do `Catalog` para o resto do jogo.

A matriz de efetividade é montada uma vez como `PackedFloat32Array` de 14 × 14 (índice `(atacante − 1) · 14 + (defensor − 1)`), com padrão 1,0, e `get_efficacy(atacante, defensores)` multiplica os valores dos elementos defensores.

## Sprites

Não há coluna de imagem. O sprite de frente de uma espécie fica em `res://assets/creatures/<slug>/front.png`; quando não existe, o `CreaturePortrait` desenha o placeholder ([foundation/02](../foundation/02-ui-shell.md)). Costas, ícone e som seguem a mesma pasta (`back.png`, `icon.png`, `cry.ogg`) quando existirem.

## Export

Arquivos `.json` não são recursos do Godot. A predefinição de export precisa incluir `data/*.json` em "Filtros para exportar arquivos que não são recursos" (iniciativa `release-pipeline`).

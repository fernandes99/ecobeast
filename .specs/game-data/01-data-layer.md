# 01. Camada de dados

- **Status:** rascunho
- **Depende de:** [foundation/01-project-setup](../foundation/01-project-setup.md)

## Contexto

O projeto está configurado, mas não há dados nem forma de lê-los. Esta fase cria tudo que fica entre os arquivos `res://data/*.json` e o resto do jogo: o schema em código, a leitura, a validação, os modelos tipados, o autoload `GameData` e o validador por linha de comando. As tabelas são criadas vazias (`[]`); o conteúdo vem nas fases 02 e 03.

## Escopo

- Os 23 arquivos de tabela do MVP, vazios.
- `CatalogSchema`, `DataSource`, `StaticJsonDataSource`, `CatalogValidator`, `Catalog`.
- Modelos de `res://domain/models/` do catálogo e `StatBlock`.
- Autoload `GameData`.
- `res://tools/validate_data.gd`.

## Fora do escopo

- Conteúdo das tabelas (fases 02 e 03).
- `HttpDataSource` e cache do catálogo.
- Modelos do estado do jogador (`CreatureInstance`, `Player`), que entram em [onboarding/01](../onboarding/01-title-and-tamer-name.md).

## Requisitos

**Arquivos**

- **RF-01:** Existe um arquivo `res://data/<tabela>.json` com o conteúdo `[]` para cada tabela do MVP de [architecture.md](architecture.md#tabelas-do-mvp): `elements`, `element_efficacy`, `stats`, `growth_rates`, `rarities`, `temperaments`, `skill_categories`, `skill_targets`, `skill_learn_methods`, `status_conditions`, `status_condition_immunities`, `effect_types`, `evolution_triggers`, `species`, `species_elements`, `species_stats`, `traits`, `species_traits`, `skills`, `skill_effects`, `species_skills`, `evolutions`, `starter_options`.

**Schema**

- **RF-02:** `res://core/data/catalog_schema.gd` (`class_name CatalogSchema`) tem a constante `TABLES: Dictionary` com uma entrada por tabela: `key` (array de colunas da chave) e `columns`, em que cada coluna tem `type` (`"int"`, `"float"`, `"string"`, `"bool"`) e, quando se aplica, `nullable`, `unique`, `fk` (tabela), `fk_future` (tabela que ainda não existe), `min`, `max` e `values` (valores permitidos). Exemplo:

```gdscript
"species": {
	"key": ["id"],
	"columns": {
		"id": {"type": "int", "min": 1},
		"slug": {"type": "string", "unique": true},
		"growth_rate_id": {"type": "int", "fk": "growth_rates"},
		"capture_rate": {"type": "int", "min": 3, "max": 255},
		"evolves_from_species_id": {"type": "int", "nullable": true, "fk": "species"},
	},
},
```

- **RF-03:** O schema reproduz exatamente as colunas, tipos, nulidade, FKs e faixas das tabelas de [architecture.md](architecture.md).

**Leitura**

- **RF-04:** `DataSource` (`@abstract`, `RefCounted`) declara `load_tables(names: PackedStringArray) -> Dictionary` e `get_errors() -> Array[String]`.
- **RF-05:** `StaticJsonDataSource` lê `res://data/<nome>.json` para cada nome. Arquivo ausente, JSON inválido, raiz que não é array ou linha que não é objeto viram erro (`"<tabela>.json: <motivo>"`) e a tabela fica vazia.

**Validação** — `CatalogValidator.validate(tables: Dictionary) -> Array[String]`. Cada erro é uma linha `"<tabela>.json linha <n>: <motivo>"` (n começa em 1) ou `"<tabela>.json: <motivo>"`.

- **RF-06:** Toda linha tem todas as colunas do schema e nenhuma a mais (coluna desconhecida acusa provável erro de digitação).
- **RF-07:** Cada valor tem o tipo da coluna; `int` exige número inteiro; `null` só em coluna `nullable`.
- **RF-08:** `min`, `max`, `values` e `unique` são respeitados.
- **RF-09:** A chave (simples ou composta) não se repete.
- **RF-10:** Toda FK não nula aponta para uma linha existente. Toda coluna `fk_future` é `null`.
- **RF-11:** Regras de consistência:
  - cada espécie tem 1 ou 2 linhas em `species_elements`, com `slot` 1 e, se houver, 2, de elementos diferentes;
  - cada espécie tem exatamente uma linha em `species_stats` para cada stat com `is_battle_only = false`, e nenhuma para os outros;
  - `element_efficacy.multiplier` é 0, 0.5 ou 2;
  - `temperaments` tem 25 linhas, cada par (aumentado, diminuído) aparece uma vez, e nenhum usa `hp` ou stat exclusivo de batalha;
  - `species_traits`: `is_hidden` é `true` se, e só se, `slot = 3`; toda espécie tem o `slot` 1;
  - `species_skills`: `level_up` exige `level ≥ 1`; `evolution` exige `level = 0`; `teachable` exige `level = null`; toda espécie tem ao menos uma técnica `level_up` no nível 1;
  - `skill_effects`: as colunas obrigatórias do tipo do efeito (tabela de `effect_types` em [architecture.md](architecture.md)) estão preenchidas e as outras são `null`; `sort_order` não se repete na mesma técnica;
  - `evolutions`: gatilho `level` exige `min_level`; para cada regra A → B, a espécie B tem `evolves_from_species_id = A`;
  - `starter_options` tem pelo menos 1 linha e `sort_order` não se repete.
- **RF-12:** Com todas as tabelas vazias, só as regras que exigem conteúdo falham (`temperaments` com 25 linhas e `starter_options` com pelo menos 1 linha); essas duas mensagens são esperadas até a fase 03.

**Catálogo e modelos**

- **RF-13:** `Catalog.load(source: DataSource) -> Array[String]` carrega todas as tabelas do schema, valida e, sem erros, converte os tipos e monta os índices. Com erros, devolve a lista e o catálogo fica vazio.
- **RF-14:** Modelos em `res://domain/models/` (`RefCounted`, campos tipados, `static func from_row(row: Dictionary) -> <Classe>` quando vêm de uma linha):
  - `Element` (`id`, `slug`, `name`, `color: Color`, `is_rare`);
  - `StatBlock` (`hp`, `atk`, `def`, `sp_atk`, `sp_def`, `spd`; `get_value(slug)`, `set_value(slug, value)`, `total()`, `to_dict()`, `static from_dict()`);
  - `CreatureSpecies` (colunas de `species` + `element_ids: Array[int]` por `slot`, `base_stats: StatBlock`, `training_yield: StatBlock`);
  - `Skill` (colunas de `skills` + `effects: Array[SkillEffect]` por `sort_order`); `SkillEffect` (colunas de `skill_effects`, com `null` virando `-1` em ids e `0` em números, mais `has_<coluna>()` quando o tipo do efeito usa a coluna);
  - `CreatureTrait`, `Temperament`, `GrowthRate`;
  - `LearnsetEntry` (`skill_id`, `level`, `method_slug`);
  - `EvolutionRule` (colunas de `evolutions` + `trigger_slug`).
- **RF-15:** Consultas do `Catalog` (e do `GameData`, que as repassa):
  - `get_element(id) -> Element`, `get_elements() -> Array[Element]` (por id);
  - `get_efficacy(attacker_element_id: int, defender_element_ids: Array[int]) -> float`;
  - `get_species(id) -> CreatureSpecies`, `get_all_species() -> Array[CreatureSpecies]` (por id);
  - `get_starters() -> Array[CreatureSpecies]` (por `sort_order`);
  - `get_learnset(species_id) -> Array[LearnsetEntry]` (`level_up` e `evolution`, por nível; `evolution` primeiro);
  - `get_evolutions(species_id) -> Array[EvolutionRule]`;
  - `get_skill(id) -> Skill`, `get_trait(id) -> CreatureTrait`;
  - `get_species_traits(species_id) -> Array[Dictionary]` (linhas de `species_traits`, por `slot`);
  - `get_temperament(id) -> Temperament`, `get_temperaments() -> Array[Temperament]`;
  - `get_growth_rate(id) -> GrowthRate`;
  - `get_stat_id(slug) -> int`;
  - `get_row(table: String, id: int) -> Dictionary` para as tabelas de referência sem modelo próprio (`rarities`, `status_conditions`…).
  - Id inexistente devolve `null` (ou `{}` em `get_row`) e gera `push_error`.
- **RF-16:** `GameData` (autoload `res://core/autoload/game_data.gd`, `extends Node`) tem `load_catalog() -> bool`, `errors: Array[String]` e as consultas do RF-15. Não carrega nada sozinho no `_ready`: quem chama é o boot da cena raiz.

**Validador por linha de comando**

- **RF-17:** `res://tools/validate_data.gd` (`extends SceneTree`) cria `StaticJsonDataSource` + `Catalog` sem depender de autoload, imprime cada erro e, ao fim, `"Catálogo OK: <n> tabelas, <m> linhas"` ou `"<k> erros"`, e sai com código 0 sem erros e 1 com erros.

## Critérios de aceite

- [ ] `godot --headless --path . --script res://tools/validate_data.gd` com as tabelas vazias lista só os dois erros esperados do RF-12 e sai com código 1.
- [ ] Acrescentar em `species.json` uma linha com `"growth_rate_id": 99` mostra o erro de FK com a linha certa; acrescentar uma coluna `"nmae"` mostra coluna desconhecida. Desfazer.
- [ ] Apagar `stats.json` mostra `"stats.json: arquivo não encontrado"`. Restaurar.
- [ ] Nenhum arquivo em `res://domain/` usa `Node`, autoload, `FileAccess` ou `get_tree()`.

## Desenho técnico

**Criar**

- `res://data/*.json` (RF-01).
- `res://core/data/catalog_schema.gd`, `data_source.gd`, `static_json_data_source.gd`, `catalog_validator.gd`, `catalog.gd`.
- `res://domain/models/element.gd`, `stat_block.gd`, `creature_species.gd`, `skill.gd`, `skill_effect.gd`, `creature_trait.gd`, `temperament.gd`, `growth_rate.gd`, `learnset_entry.gd`, `evolution_rule.gd`.
- `res://core/autoload/game_data.gd` e registro do autoload `GameData` (primeiro da lista).
- `res://tools/validate_data.gd`.

**Alterar**

- `project.godot`: autoload `GameData`.
- `CLAUDE.md`: como editar dados (arquivo = tabela, schema em `catalog_schema.gd`, rodar o validador antes de commitar).

**Notas para quem implementa**

- Ler arquivo: `FileAccess.get_file_as_string(path)` + `JSON.new().parse(texto)` (o objeto `JSON` informa a linha do erro de sintaxe).
- Números chegam como `float`: em colunas `int`, conferir `is_equal_approx(v, roundf(v))` antes de converter com `int(v)`.
- `@abstract` exige Godot 4.5+; o projeto usa 4.7.
- O validador roda com `--script`, que não carrega autoloads, por isso usa as classes diretamente. Os `class_name` vêm do cache que o editor gera (`.godot/global_script_class_cache.cfg`): depois de criar uma classe nova, abra o projeto no editor uma vez antes de rodar o validador.
- Em `extends SceneTree`, o trabalho vai em `_initialize()` e o fim é `quit(codigo)`.

## Verificação

```bash
godot --headless --path . --script res://tools/validate_data.gd ; echo "saída: $?"
```

No editor: percorrer os critérios de aceite.

## Tarefas

- [ ] Arquivos vazios das tabelas.
- [ ] `CatalogSchema` espelhando a architecture.
- [ ] `DataSource` e `StaticJsonDataSource`.
- [ ] `CatalogValidator` (RF-06 a RF-12).
- [ ] Modelos e `Catalog`.
- [ ] `GameData` e o autoload.
- [ ] `tools/validate_data.gd`.
- [ ] Atualizar o `CLAUDE.md`.
- [ ] Marcar esta spec e as tabelas como `concluída`; commit `feat: camada de dados do catálogo`.

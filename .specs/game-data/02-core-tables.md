# 02. Tabelas de referência

- **Status:** concluída
- **Depende de:** [01-data-layer](01-data-layer.md)

## Contexto

Depois da fase 01 as tabelas existem vazias e o validador funciona. Esta fase preenche as tabelas de referência — as listas fixas que as espécies e técnicas da fase 03 vão apontar por FK. Os números e regras vêm do `GDD.md` (seções "Tipos (Elementos) e efetividade", "Fórmulas" e "Status, traços, temperamentos e itens"); o que o GDD não define foi proposto no planejamento e está marcado _a revisar_.

## Escopo

Preencher: `elements`, `element_efficacy`, `stats`, `growth_rates`, `rarities`, `temperaments`, `skill_categories`, `skill_targets`, `skill_learn_methods`, `status_conditions`, `status_condition_immunities`, `effect_types`, `evolution_triggers`.

## Fora do escopo

- Espécies, traços, técnicas e tudo da fase 03.
- Curva Erratic (sem fórmula no GDD; ver [roadmap](../roadmap.md#dúvidas-globais-em-aberto)).
- Climas (`weathers`), itens e zonas.

## Requisitos

- **RF-01:** `elements.json` com as 14 linhas abaixo. Cores _a revisar_.

| id  | slug     | name   | color_hex | is_rare |
| --- | -------- | ------ | --------- | ------- |
| 1   | `fire`   | Fogo   | `#F2603C` | false   |
| 2   | `water`  | Água   | `#3A8FE0` | false   |
| 3   | `flora`  | Flora  | `#4CB050` | false   |
| 4   | `volt`   | Volt   | `#F5C518` | false   |
| 5   | `earth`  | Terra  | `#B07A43` | false   |
| 6   | `wind`   | Vento  | `#7CC9B8` | false   |
| 7   | `ice`    | Gelo   | `#6FCDEB` | false   |
| 8   | `metal`  | Metal  | `#8C99A6` | false   |
| 9   | `toxin`  | Toxina | `#9B4FC9` | false   |
| 10  | `mind`   | Mente  | `#E86AA8` | false   |
| 11  | `shadow` | Sombra | `#4A3F6B` | false   |
| 12  | `light`  | Luz    | `#F7E7A6` | false   |
| 13  | `beast`  | Fera   | `#B08B6E` | false   |
| 14  | `arcane` | Arcano | `#6C5CE7` | true    |

- **RF-02:** `element_efficacy.json` transcreve as colunas "Forte contra" (2), "Pouco eficaz contra" (0,5) e "Sem efeito" (0) da tabela de elementos do `GDD.md`, linha a linha, com o elemento da linha como atacante. São 76 linhas, nesta contagem por atacante: Fogo 7, Água 5, Flora 8, Volt 6, Terra 6, Vento 5, Gelo 8, Metal 6, Toxina 6, Mente 5, Sombra 4, Luz 5, Fera 2, Arcano 3. A coluna "Fraco a" do GDD não gera linhas (é a mesma informação lida pelo defensor) e foi conferida: bate com as outras três.

- **RF-03:** `stats.json`:

| id  | slug       | name             | short_name | is_battle_only |
| --- | ---------- | ---------------- | ---------- | -------------- |
| 1   | `hp`       | HP               | HP         | false          |
| 2   | `atk`      | Ataque           | Atq        | false          |
| 3   | `def`      | Defesa           | Def        | false          |
| 4   | `sp_atk`   | Ataque Especial  | Atq.E      | false          |
| 5   | `sp_def`   | Defesa Especial  | Def.E      | false          |
| 6   | `spd`      | Velocidade       | Vel        | false          |
| 7   | `accuracy` | Precisão         | Prec       | true           |
| 8   | `evasion`  | Evasão           | Eva        | true           |

- **RF-04:** `growth_rates.json`: 1 `fast` "Rápido" 0.8; 2 `medium` "Médio" 1.0; 3 `slow` "Lento" 1.25.
- **RF-05:** `rarities.json`: 1 `common` "Comum"; 2 `uncommon` "Incomum"; 3 `rare` "Raro"; 4 `epic` "Épico"; 5 `ancestral` "Ancestral"; `sort_order` igual ao id.
- **RF-06:** `temperaments.json` com os 25 abaixo (linha = stat aumentado, coluna = stat diminuído; diagonal = neutros). Ousado, Calmo e Ágil são do GDD; os outros 22 nomes são _a revisar_. Ids de 1 a 25 na ordem de leitura da tabela (linha por linha).

| + \ −      | Atq          | Def          | Atq.E         | Def.E      | Vel            |
| ---------- | ------------ | ------------ | ------------- | ---------- | -------------- |
| **Atq**    | Sereno       | Impetuoso    | Ousado        | Feroz      | Robusto        |
| **Def**    | Paciente     | Equilibrado  | Teimoso       | Rígido     | Firme          |
| **Atq.E**  | Sábio        | Sonhador     | Tranquilo     | Intenso    | Contemplativo  |
| **Def.E**  | Calmo        | Bondoso      | Reservado     | Sóbrio     | Prudente       |
| **Vel**    | Arisco       | Ágil         | Inquieto      | Afoito     | Constante      |

Slugs: o nome sem acento, em minúsculas (`sereno`, `impetuoso`, `sabio`, `sobrio`…).

- **RF-07:** `skill_categories.json`: 1 `physical` "Física"; 2 `special` "Especial"; 3 `support` "Suporte".
- **RF-08:** `skill_targets.json`: 1 `enemy` "Inimigo"; 2 `self` "Si mesmo"; 3 `all` "Todos".
- **RF-09:** `skill_learn_methods.json`: 1 `level_up` "Por nível"; 2 `evolution` "Ao ascender"; 3 `teachable` "Ensinável".
- **RF-10:** `status_conditions.json`:

| id  | slug        | name        | is_volatile |
| --- | ----------- | ----------- | ----------- |
| 1   | `burn`      | Queimado    | false       |
| 2   | `poison`    | Envenenado  | false       |
| 3   | `paralysis` | Paralisado  | false       |
| 4   | `sleep`     | Adormecido  | false       |
| 5   | `freeze`    | Congelado   | false       |
| 6   | `confusion` | Confuso     | true        |
| 7   | `fear`      | Amedrontado | true        |
| 8   | `trapped`   | Preso       | true        |

- **RF-11:** `status_condition_immunities.json`, da coluna "Imune" do GDD: Queimado–Fogo, Envenenado–Toxina, Envenenado–Metal, Paralisado–Volt, Congelado–Gelo (5 linhas).
- **RF-12:** `effect_types.json`, ids de 1 a 11 na ordem da tabela de [architecture.md](architecture.md): `apply_status` "Aplicar status", `modify_stat` "Alterar atributo", `heal` "Curar", `drain` "Drenar", `recoil` "Recuo", `flinch` "Amedrontar", `multi_turn` "Carregar", `fixed_damage` "Dano fixo", `set_weather` "Mudar clima", `protect` "Proteger", `switch` "Trocar".
- **RF-13:** `evolution_triggers.json`: 1 `level` "Nível"; 2 `item` "Item"; 3 `bond` "Vínculo"; 4 `time_of_day` "Horário"; 5 `zone` "Zona"; 6 `trade` "Troca"; 7 `temperament` "Temperamento".

## Critérios de aceite

- [x] O validador lista só o erro de `starter_options` vazio (esperado até a fase 03).
- [x] Um script temporário imprime `get_efficacy(1, [3])` = 2, `get_efficacy(4, [5])` = 0, `get_efficacy(1, [2, 5])` = 0,25 e `get_efficacy(13, [1])` = 1. (Apagar depois.)
- [x] `get_temperaments()` devolve 25 itens e os 5 neutros têm os dois stats iguais.

Como o `GameData` não carrega o catálogo enquanto o validador acusa `starter_options` vazio, o script temporário monta o `Catalog` direto das tabelas, sem a validação. Ele também conferiu que, lida pelo defensor, a tabela bate com a coluna "Fraco a" do GDD nos 14 elementos.

## Desenho técnico

**Alterar**

- Os 13 arquivos de `res://data/` listados no Escopo.

Nenhum código novo: se faltar algo no `Catalog` para os critérios de aceite, é defeito da fase 01 e se corrige lá (com a spec atualizada).

## Verificação

```bash
godot --headless --path client --script res://tools/validate_data.gd
```

E os critérios de aceite.

## Tarefas

- [x] `elements` e `element_efficacy` (conferir a contagem por atacante).
- [x] `stats`, `growth_rates`, `rarities`, `temperaments`.
- [x] `skill_categories`, `skill_targets`, `skill_learn_methods`.
- [x] `status_conditions`, `status_condition_immunities`, `effect_types`, `evolution_triggers`.
- [x] Marcar esta spec e as tabelas como `concluída`; commit `feat: tabelas de referência do catálogo`.

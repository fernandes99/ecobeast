# skill-editor: arquitetura

O desenho que as 2 fases compartilham. As decisões e o motivo de cada uma estão no [README.md](README.md).

## Quem pode salvar

As rotas ficam sob `/v1/editor/skills`, com `@UseGuards(AuthGuard, EditorGuard)`, como as do editor de ilhas ([map-editor/architecture.md](../map-editor/architecture.md), "Quem edita"):

- Com `MAP_EDITOR_USER_IDS` vazia, `404` "Rota não encontrada.".
- Com um usuário fora da lista, `403` com o `NOT_AN_EDITOR` de hoje.

O nome da variável e a mensagem continuam os de hoje. O dono já está na lista.

## A Técnica inteira

O mesmo corpo serve para criar e para salvar. Os nomes seguem as colunas do catálogo (`snake_case`), como o `GET /v1/catalog` devolve:

```json
{
  "slug": "erupcao_solar",
  "name": "Erupção Solar",
  "description": "…",
  "element_id": 2,
  "skill_category_id": 2,
  "power": 120,
  "accuracy": 85,
  "max_pp": 5,
  "priority": 0,
  "crit_stage": 0,
  "skill_target_id": 1,
  "makes_contact": false,
  "min_hits": 1,
  "max_hits": 1,
  "area_shape_id": 1,
  "range": 1,
  "pierces": false,
  "ground_effect_id": null,
  "ground_turns": null,
  "cooldown": 3,
  "effects": [
    { "effect_type_id": 1, "chance": 30, "skill_target_id": null, "status_condition_id": 3,
      "stat_id": null, "stages": null, "percent": null, "value": null, "min_turns": null }
  ],
  "learners": [
    { "species_id": 1, "skill_learn_method_id": 1, "level": 25 }
  ]
}
```

- **`slug`** só vale ao criar. Ao salvar, ele é ignorado, e o `slug` do banco continua.
- **`effects`** vêm na ordem em que aparecem. O servidor grava `sort_order` de 1 em diante, nessa ordem. `weather_id` não vem: fica sempre nulo, como manda o CHECK.
- **`learners`** é a lista inteira de quem aprende. Um Ecobeast que sai da lista deixa de aprender a Técnica dali para a frente. Quem já a conhece continua com ela (`creature_instance_skills` não depende de `species_skills`).

### As rotas

| Rota | Faz | Responde |
| --- | --- | --- |
| `POST /v1/editor/skills` | Cria a Técnica, os efeitos e os aprendizes | `201` `{ "id": <novo id> }` |
| `PUT /v1/editor/skills/:id` | Troca os campos e os aprendizes. O efeito na posição N reaproveita a linha que já estava na posição N, para o id não mudar; as linhas que sobram são apagadas, e as que faltam, criadas | `200` `{ "id": <id> }` |

- Tudo numa transação do Prisma (`$transaction`). Se uma parte falha, nada muda.
- Antes de inserir, o serviço põe o contador de id de `skills` e de `skill_effects` depois do maior id. Linhas postas pelo painel com o id escrito à mão deixam o contador para trás, e o `INSERT` bateria num id que já existe.
- As conferências moram em `server/src/domain/skills/skill-draft.ts`, como funções puras.
- Um `id` que não existe: `404` "Técnica não encontrada.".
- Depois de gravar, o servidor chama `BundleService.invalidate()` (novo), que joga fora a cópia do catálogo. O próximo `GET /v1/catalog` lê o banco de novo, e a versão muda.
- A luta não guarda nada: a próxima luta lê o banco no `begin`, como hoje.

## As conferências

Antes de gravar, o servidor confere tudo e responde `400` com a primeira mensagem, em pt-BR, que o F1 mostra como chega. Elas juntam duas fontes:

- **Os CHECKs do banco**, para o dono ler o motivo, e não um erro do Postgres.
- **As regras do `CatalogValidator` do jogo** (`res://core/data/catalog_validator.gd` e `catalog_schema.gd`). Todo aparelho confere o catálogo baixado. Uma Técnica que passa no servidor e falha no jogo deixa todos os jogadores, e o próprio F1, em "Sem catálogo". Por isso o servidor nunca grava o que o jogo recusaria. Se uma regra do validador mudar, a do servidor muda junto.

**A Técnica:**

| Campo | Regra |
| --- | --- |
| `slug` (ao criar) | `^[a-z0-9_]+$`, e não pode existir outra com o mesmo |
| `name` | Não vazio, depois de tirar os espaços das pontas |
| `description` | Texto; pode ser vazio |
| `element_id`, `skill_category_id`, `skill_target_id`, `area_shape_id` | Um id que existe na tabela |
| `power` | 0 a 250 |
| `accuracy` | 0 a 100 |
| `max_pp` | 5 a 40 |
| `priority` | −7 a 5 |
| `crit_stage` | 0 a 3 |
| `min_hits`, `max_hits` | 1 a 10, e `min_hits` ≤ `max_hits` |
| `range` | 1 a 6 |
| `ground_effect_id`, `ground_turns` | Os dois nulos, ou um id que existe e 1 a 20 turnos |
| `cooldown` | 0 a 5 |
| `makes_contact`, `pierces` | Verdadeiro ou falso |

**Cada efeito:**

| Campo | Regra |
| --- | --- |
| `effect_type_id` | Um id que existe |
| `chance` | 1 a 100 |
| `skill_target_id`, `status_condition_id`, `stat_id` | Nulo, ou um id que existe |
| `stages` | Nulo, ou −6 a 6, e nunca 0 |
| `percent` | Nulo, ou 1 a 100 |
| `value`, `min_turns` | Nulo, ou 1 ou mais |

Cada tipo de efeito usa só algumas colunas, como no `EFFECT_PARAMS` de `catalog_schema.gd`. As exigidas precisam vir, e as que o tipo não usa precisam vir nulas:

| Tipo | Exige | Pode ter | A luta usa? |
| --- | --- | --- | --- |
| `apply_status` | `status_condition_id` | | sim |
| `modify_stat` | `skill_target_id`, `stat_id`, `stages` | | sim |
| `heal`, `drain`, `recoil` | `percent` | | sim |
| `flinch` | | | sim |
| `fixed_damage` | | `value` | não |
| `multi_turn`, `protect`, `switch` | | | não |
| `set_weather` | | | recusado: "O clima ainda não existe." |

O `set_weather` exige `weather_id` no jogo, e o banco obriga `weather_id` nulo, então nenhum efeito desse tipo seria válido. Um tipo que não está na tabela, criado depois no banco, também é recusado: "Esse tipo de efeito ainda não tem regra no jogo.".

**Cada aprendiz:**

| Campo | Regra |
| --- | --- |
| `species_id`, `skill_learn_method_id` | Um id que existe |
| `level` | Pelo método: `level_up`, 1 a 100; `evolution`, 0; `teachable`, nulo |
| o par espécie e método | Não pode repetir na lista (é a chave de `species_skills`) |

**Toda espécie** precisa continuar com pelo menos uma Técnica `level_up` no nível 1 (é com ela que um Ecobeast nasce). Se a lista nova tirar a última de uma espécie, a resposta é `400` "O <nome da espécie> ficaria sem Técnica no nível 1.".

## Os testes e o banco

Os e2e rodam no banco do Supabase, como os do editor de ilhas. Eles só criam Técnicas próprias, com `slug` começando em `zz_teste_`, e nunca editam uma Técnica do jogo. Os aprendizes de teste usam o método `teachable`, que não mexe no que um Ecobeast aprende por nível. O `afterAll` apaga, pelo Prisma, os aprendizes, os efeitos e as Técnicas `zz_teste_`, nessa ordem. Ele roda num grupo à parte do `vitest.config.e2e.ts`, depois de todos os outros e2e, porque os outros leem o catálogo e contam as linhas.

## No jogo

- **A aba Técnicas** (`res://tools/content_viewer/skills_tab.gd`) ganha o botão **Editar** no topo da ficha e o botão **Nova Técnica** em cima da lista (`ListDetail.add_list_header`).
- **O formulário** é `SkillForm` (`res://tools/content_viewer/skill_form.gd`), montado no código como o resto do F1. Ele entra no lugar da ficha pelo `ListDetail.show_custom`.
- **As chamadas** ficam no `EditorApi` (`res://tools/map_editor/editor_api.gd`), ao lado das do editor de ilhas: `create_skill(body)` e `save_skill(id, body)`.
- **Depois de salvar:** `await GameData.load_catalog()`, `viewer.rebuild()` e `viewer.show_item(ContentViewer.TAB_SKILLS, id)`. O F1 mostra a ficha nova, só leitura. As telas do jogo que já estão abertas continuam com os dados antigos até serem abertas de novo.
- **Se o catálogo novo não carregar** (servidor caiu, `CatalogValidator` achou erro), o F1 mostra o aviso de hoje, "Sem catálogo", com **Tentar de novo**.

# free-props: arquitetura

## As camadas de uma ilha

| Camada | Onde fica | Preso a | Bloqueia |
| --- | --- | --- | --- |
| Terreno (bioma, altura, variante, chão, área) | `island_tiles` | hexágono | não |
| Objetos | `island_objects`, `island_object_tiles` | hexágonos | por hexágono |
| Ações | `island_actions`, `island_action_tiles` | hexágonos | não |
| **Peças soltas** | `island_props` | um ponto dentro de um hexágono | nunca |

O carimbo não é uma camada: ele vive só no editor e, ao ser posto, vira objetos, peças soltas e chão.

## O catálogo: `prop_types`

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `slug` | text | `^[a-z0-9_]+$`, único |
| `name` | text | pt-BR |
| `variants` | int | `>= 1` |

A arte e o vento de cada tipo são do jogo, pelo `slug` ([02](README.md#fases)).

Os primeiros tipos (fase 1):

| id | slug | name | variants |
| --- | --- | --- | --- |
| 1 | `tree` | Árvore | 4 |
| 2 | `pine` | Pinheiro | 4 |
| 3 | `bush` | Arbusto | 4 |
| 4 | `dark_bush` | Arbusto escuro | 4 |
| 5 | `tuft` | Tufo de grama | 4 |
| 6 | `flowers` | Flores | 4 |
| 7 | `fern` | Samambaia | 4 |
| 8 | `dry_shrub` | Arbusto seco | 4 |
| 9 | `dry_tuft` | Tufo seco | 4 |
| 10 | `moss` | Musgo | 4 |
| 11 | `pebbles` | Pedrinhas | 4 |
| 12 | `rock` | Pedra | 4 |
| 13 | `mossy_rock` | Pedra com musgo | 4 |
| 14 | `brown_rock` | Pedra marrom | 4 |
| 15 | `boulder` | Rochedo | 4 |
| 16 | `rock_pile` | Monte de pedras | 4 |
| 17 | `spire` | Agulha de pedra | 4 |
| 18 | `lamp_post` | Poste de luz | 2 |
| 19 | `sign` | Placa | 2 |
| 20 | `flower_bed` | Canteiro de flores | 3 |
| 21 | `bench` | Banco | 2 |

Os 17 primeiros são as plantas e pedras do terreno (`HexDecorations.KIND_ROWS`, na mesma ordem). Os 4 últimos eram os objetos 36 a 39 de `map_object_types`, que saem de lá; os ids 36 a 39 não voltam a ser usados.

## A tabela da ilha: `island_props`

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `island_map_id` | int | FK `island_maps`, apaga junto |
| `prop_type_id` | int | FK `prop_types`, não deixa apagar o tipo em uso |
| `q`, `r` | int | o hexágono do pé, que precisa ser da ilha |
| `dx`, `dy` | int | o pé, em pixels da arte, a partir do centro plano do hexágono (`HexMapView.flat_center`), sem a altura |
| `variant` | int | de 1 a `prop_types.variants` |
| `mirrored` | bool | espelhada |

O ponto do pé é `flat_center(q, r) + (dx, dy)`, e ele precisa cair no próprio hexágono `(q, r)`: o servidor confere com a mesma conta do jogo (`HexMapView.grid_coord`), copiada em `server/src/domain/islands/hex-pixels.ts`. Assim o hexágono do pé nunca é ambíguo, e a altura dele é a da peça.

Uma ilha tem no máximo `MAX_PROPS` (6000) peças.

## O contrato

O rascunho do editor (`IslandDraftDto`) e o mapa de Explorar numa ilha (`ExplorationMapDto`) ganham `props`:

```json
{ "prop_type_id": 6, "q": 3, "r": -1, "dx": -7, "dy": 4, "variant": 2, "mirrored": false }
```

No rascunho que o editor manda, `props` é opcional (vazio se faltar), para o editor de antes da fase 3 continuar salvando. Nas respostas, vem sempre. No mapa sorteado, vem vazio.

O `content_hash` do rascunho inclui as peças, em ordem de `(r, q, dy, dx, prop_type_id, variant, mirrored)`.

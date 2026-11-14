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

## O desenho no jogo

- **Faixas:** cada linha de hexágonos tem um `HexRowView` de chão e `DEPTH_BANDS` (4) de decoração, de trás para a frente. Uma decoração (sorteada, da Vegetação ou peça solta) entra na faixa do pé dela, pela distância `dy` ao centro do hexágono (`HexMapView.band_of`: faixas de 14,5 pixels da arte, de −29 a 29).
- **O Domador** entra na divisa de faixas mais perto do pé dele, na linha dos pés (`HexMapView.set_actor_depth`). Os Ecobeasts e os Domadores NPC entram antes da faixa do meio (`MIDDLE_BAND`, `set_actor_row`), como antes. Os objetos continuam depois de todas as faixas da linha da frente deles.
- **A arte das peças:** os tipos com o `slug` de uma linha da folha `decorations.png` (`HexDecorations.KIND_ROWS`) usam a célula da variante (`variant - 1`), com o pé no `CELL_BASE` e o vento do `KIND_SWAY`. Os outros usam `assets/props/<slug>/<variante>.png`, com o pé no meio da borda de baixo, sem vento. Cada faixa de cada pedaço tem uma malha por textura.
- **Ilhas:** desde a [05](05-natural-decorations.md), as decorações sorteadas do bioma aparecem nas ilhas como no mapa sorteado, com a seed da ilha (o id dela), menos no hexágono com a marca `HexTile.bare`; as da Vegetação continuam.

## No editor

- **A ferramenta Peças** (a 7, que era Objeto) tem os tipos de grade (`map_object_types`) e os soltos (`prop_types`) na mesma paleta (`ObjectPanel`, com `placing_prop`, `selected` e `selected_prop`). O rascunho guarda as peças como o servidor manda (`IslandDraft.props`), e o desfazer guarda cópias de antes e depois (`EditorHistory.Step.props_before` e `props_after`).
- **O ponto do ponteiro:** o `EditorCanvas` passa à ferramenta o ponto no chão plano (`pointer_flat`: o ponto da arte mais a altura do hexágono embaixo dele, `IslandDraft.rise_at`), e a peça nova fica com o pé nele, arredondado. A escolha com o botão direito compara o ponto da arte com o retângulo da arte de cada peça (`PropArt.rect`, em volta do pé levantado), e ganha a da frente (o pé mais embaixo).
- **Arrastar:** começar o clique esquerdo sobre a arte da peça escolhida a arrasta; o canvas manda o ponto a cada movimento (`pointer_dragged`), e o pé segue o ponteiro, guardando a distância do começo, só para hexágonos da ilha.
- **Redesenhar:** o `HexMapView.set_props` só indexa as peças; o canvas compara as peças de cada hexágono antes e depois (`refresh_props`) e refaz só os hexágonos que mudaram, com `update_tiles`.

## Os carimbos

- **O arquivo:** `client/tools/map_editor/stamps/<slug>.json`, com o `name`, o chão de cada hexágono (`tiles`, com `dq`, `dr` e `ground`), os objetos (`objects`, como no rascunho, com `dq` e `dr` no lugar de `q` e `r`) e as peças (`props`, idem, com o `dx` e o `dy` de sempre). Tudo a partir do hexágono de apoio, o da área mais perto do meio dela. Não leva bioma nem altura.
- **Guardar** (`Stamp.capture`): o chão dos hexágonos marcados, os objetos com todos os hexágonos dentro e as peças com o pé dentro.
- **Pôr** (`Stamp.place`): nos hexágonos do carimbo que são da ilha, o chão troca e os objetos que ocupam algum saem; entram os objetos que cabem inteiros e as peças com o pé na ilha. Espelhado, cada deslocamento `(dq, dr)` vira `(-dq - dr, dr)` (`ObjectPanel.mirror`), o `dx` das peças troca de sinal e o espelho de cada objeto e peça se inverte.
- **A ferramenta Carimbo** (a 10, só pelo botão) tem o `StampPanel`, com os modos Pôr e Escolher área. O pôr é um passo de desfazer com o chão, os objetos e as peças de antes e de depois.
- **A Fonte** (`fountain`, id 40) é um objeto de grade de 1 hexágono, com arte do `make_town.gd`.

## A marca sem decorações

- **No banco:** `island_tiles.bare` (`boolean NOT NULL DEFAULT false`), na migration `free_props_bare_tiles`.
- **No contrato:** o hexágono do editor e o de Explorar numa ilha levam `bare: true` só quando marcado; sem o campo, vale falso. O `content_hash` também leva a marca só quando ela é verdadeira.
- **No cliente:** o `HexTile.bare` faz o `HexMapView` pular o sorteio daquele hexágono; as peças soltas aparecem sempre.
- **No editor:**
  - **Hexágonos novos:** os do gerador, da ilha em branco e do Pôr hexágono vêm sem a marca, e o Bioma tira a marca de todo hexágono que pinta.
  - **A Borracha** (a 11, só pelo botão): o botão esquerdo põe a marca e apaga as peças com o pé no pincel, e o direito tira a marca.
  - **O carimbo** guarda e põe a marca; sem o campo, ele põe a marca.
  - **O desfazer:** o `snapshot` leva a marca.

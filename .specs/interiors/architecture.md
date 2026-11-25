# interiors: arquitetura

O desenho que as fases da [interiors](README.md) compartilham.

## Vocabulário

| No jogo | No código |
| --- | --- |
| Interior (a sala) | `Interior`, tabela `interiors` |
| Quadrado | uma célula da grade da sala, de 16×16 px da arte (`Vector2i`, coluna e linha a partir do canto de cima à esquerda) |
| Tile | um quadrado de 16 px de uma folha do pacote: a folha (`sheet`) e a coluna e a linha nela (`col`, `row`) |
| Objeto | um retângulo de tiles de uma folha, posto inteiro na sala (`InteriorObject`) |
| Porta | o quadrado de chão onde o Domador nasce e por onde sai |

## As folhas

As três folhas do pacote Main Characters Home vão, sem mudar os pixels, para `client/assets/interiors/main_home/`, com os créditos em `client/assets/interiors/CREDITOS.md` (a licença da craftpix.net, como em `assets/props/CREDITOS.md`):

| `sheet` | Arquivo | Tamanho | O que tem |
| --- | --- | --- | --- |
| `walls_floor` | `walls_floor.png` | 11×16 tiles | chão de tábuas, paredes de pedra com o arremate creme, arcos, portas e a borda escura |
| `interior` | `interior.png` | 14×27 tiles | móveis, tapetes, plantas, poções, barris |
| `doors_windows` | `doors_windows.png` | 17×12 tiles | portas e janelas (só o primeiro quadro de cada animação é usado) |

A [04](04-refuge-hospital.md) acrescenta a folha `refuge` (`refuge.png`, em `client/assets/interiors/fdr/`, 16×10 tiles), montada pelo `make_refuge_sheet.py` com peças das folhas Interior e Laboratory do Fantasy Dreamland Reborn, realinhadas aos 16 px: o piso, a parede rosa, o teto com a moldura creme e os cantos de dentro, o estrado, o tapete, o capacho, as placas da cruz, as cápsulas, as macas, os armários, as plantas, os sofás e a máquina de cura (colunas 0 a 4, linhas 8 e 9). O caminho de cada folha mora em `InteriorTiles.SHEET_PATHS`.

O jogo monta o `TileSet` do Godot (o recurso que diz ao `TileMapLayer` de onde vem cada tile) por código, uma vez, com uma fonte de atlas por folha, na ordem da tabela: o id da fonte é o índice da folha em `InteriorTiles.SHEETS`. Um tile de uma folha que não existe, ou fora dela, não é desenhado, e o jogo segue.

## As tabelas

Schema `ecobeasts`. Os interiores não entram no catálogo (`GET /v1/catalog`): o jogo baixa um de cada vez, ao entrar.

**`interiors`**

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | serial | |
| `name` | text | 1 a 40 caracteres; aparece no topo da tela |
| `width`, `height` | smallint | 4 a 64 quadrados |
| `door_x`, `door_y` | smallint | dentro da sala (`CHECK door_x < width` e `door_y < height`) |
| `updated_at` | timestamptz | |

**`interior_tiles`**, a chave é (`interior_id`, `layer`, `x`, `y`):

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `interior_id` | int | FK, `on delete cascade` |
| `layer` | text | `floor`, `floor_detail`, `wall` ou `wall_detail` |
| `x`, `y` | smallint | ≥ 0 (a rota confere o limite da sala) |
| `sheet` | text | `^[a-z0-9_]+$` |
| `col`, `row` | smallint | 0 a 63 |

**`interior_objects`**: `id` serial, `interior_id` (FK, cascade), `x`, `y` (o quadrado do canto de cima à esquerda), `sheet`, `col`, `row` (o tile do canto de cima à esquerda na folha), `width`, `height` (1 a 8 tiles), com a mesma regra de `sheet`, `col` e `row` acima, e `action_type_id` (FK `action_types`, `on delete restrict`, nulo sem ação; [04](04-refuge-hospital.md)): o toque no objeto leva o Domador até o lado dele e roda a ação, e a `refuge` faz do objeto a máquina de cura.

**`interior_blocks`**: `interior_id` (FK, cascade), `x`, `y`; a chave é os três. São os quadrados bloqueados: os marcados ao pôr uma parede sólida ou um objeto (pelo script da [01](01-interior-data.md) e pelo editor da [03](03-interior-editor.md)) e os pintados à mão.

**`interior_npcs`**: `id` serial, `interior_id` (FK, cascade), `npc_id` (FK `npcs`, `on delete restrict`), `x`, `y`, `dialogue` (text, até 2.000 caracteres, vazio é sem fala, os parágrafos como nos NPCs da ilha) e `action_type_id` (FK `action_types`, `on delete restrict`, nulo é sem ação).

**`island_props.interior_id`**: int, nulo, FK `interiors` com `on delete restrict`. Vai junto da peça no rascunho e na publicação da ilha, como o `no_smoke`.

## Quando um quadrado bloqueia

Um quadrado da sala bloqueia o andar quando:

- não tem tile na camada `floor`; ou
- está em `interior_blocks`; ou
- tem um NPC.

A camada `wall` não bloqueia sozinha. No pacote, ela também guarda o contorno fino das paredes por cima do chão livre: no `Interior1.tmx`, quase todo quadrado de chão tem um tile de parede. Por isso, só o tile de parede **sólido**, com pelo menos 128 dos 256 pixels com alfa acima de 0, bloqueia, e ele vira um bloqueio em `interior_blocks` quando é posto. O servidor só conhece `interior_blocks` e não lê as folhas.

A porta precisa ser um quadrado com chão e fora de `interior_blocks`. A rota do editor confere isso, e o editor avisa antes de salvar.

## As rotas

Respostas e corpos em `snake_case`, como o resto da API. O corpo da sala é o mesmo na leitura e no salvar:

```json
{
  "id": 1,
  "name": "Refúgio",
  "width": 26,
  "height": 22,
  "door": { "x": 13, "y": 21 },
  "tiles": [{ "layer": "floor", "x": 3, "y": 5, "sheet": "walls_floor", "col": 4, "row": 9 }],
  "objects": [{ "id": 7, "x": 10, "y": 6, "sheet": "interior", "col": 0, "row": 0, "width": 2, "height": 3, "action_type_id": null }],
  "blocks": [{ "x": 10, "y": 8 }],
  "npcs": [{ "id": 2, "npc_id": 12, "x": 14, "y": 4, "dialogue": "Bem-vindo!", "action_type_id": 1 }]
}
```

| Rota | Quem | O que faz |
| --- | --- | --- |
| `GET /v1/interiors/:id` | jogador (`AuthGuard`) | a sala; 404 "Esse lugar não existe." |
| `GET /v1/editor/interiors` | editor | a lista, `[{ "id", "name" }]`, por `id` |
| `GET /v1/editor/interiors/:id` | editor | a sala; 404 "Interior não encontrado." |
| `POST /v1/editor/interiors` | editor | `{ "name", "width", "height" }` cria uma sala vazia, com a porta no meio da linha de baixo, e a devolve |
| `PUT /v1/editor/interiors/:id` | editor | troca a sala inteira pelo corpo, numa transação, e a devolve com os `id` novos dos objetos e dos NPCs |
| `DELETE /v1/editor/interiors/:id` | editor | apaga; 409 "Uma peça de ilha leva a esse interior." se alguma `island_props` aponta para ela |

As rotas `/v1/editor` usam o `EditorGuard` (404 com `MAP_EDITOR_USER_IDS` vazia, 403 a quem não está nela), como as outras.

O `PUT` dá 400 com a mensagem do primeiro erro: um quadrado fora da sala ("Há um tile fora da sala."), dois tiles no mesmo quadrado e camada, um objeto que passa da borda, um bloqueio repetido, um objeto com uma ação que não existe ("O objeto tem uma ação que não existe."), um NPC que não existe ("Esse NPC não existe."), um NPC num quadrado sem chão, bloqueado, na porta ou junto de outro NPC ("O NPC precisa de um quadrado livre."), um tipo de ação que não existe, ou a porta sem chão ou num bloqueio ("A porta precisa estar num quadrado de chão, sem bloqueio."). O limite é de 16.384 tiles, 1.000 objetos e 50 NPCs por sala.

O salvar da ilha no editor aceita o `interior_id` em cada peça (400 "Esse interior não existe." se não existir), e o mapa de Explorar (`ExplorationMap`) traz o `interior_id` de cada peça.

## O jogo

- **Modelos** (`domain/models/`): `Interior` (com `from_dict` e `to_dict`), `InteriorTile`, `InteriorObject` e `InteriorNpc`. O `MapProp` ganha o `interior_id` (0 é sem sala).
- **`InteriorTiles`** (`ui/components/interior_tiles.gd`): `SHEETS`, o `TileSet` montado uma vez (`tile_set()`), a textura de uma folha (`sheet_texture(sheet)`), se um tile é sólido (`is_solid(sheet, col, row) -> bool`, pela regra acima) e o bloqueio (`blocked(interior) -> Dictionary`, os quadrados bloqueados pelas regras acima, sem os NPCs).
- **`InteriorView`** (`ui/components/interior_view.gd`, um `Node2D`): desenha uma sala na escala 1 da arte. O jogo e o editor usam o mesmo.
  - `floor` e `floor_detail` são dois `TileMapLayer` embaixo de tudo.
  - Por cima, um `Node2D` com `y_sort_enabled` (o Godot desenha os filhos pela altura do pé, o de baixo por cima) guarda:
    - o `TileMapLayer` da `wall` e o da `wall_detail`, também com `y_sort_enabled`, com cada tile ordenado pela borda de baixo do quadrado dele;
    - um `Sprite2D` por objeto, com o recorte da folha e o pé na borda de baixo do retângulo. Um objeto que cobre um quadrado de um objeto anterior da lista (uma jarra sobre a mesa) se ordena pelo pé mais baixo dos dois, e por isso fica por cima dele;
    - o nó `actors`, onde a tela põe o Domador e os NPCs, ordenados pelo pé.
  - Assim, uma estante de 3 tiles de altura cobre o Domador que está atrás dela, e o Domador na frente da parede cobre a parede.
- **A ação de um tipo** (`core/action_screens.gd`, `ActionScreens`): o `ACTION_SCREENS` e a regra sem equipe que hoje estão na `ExplorationScreen` saem para cá, com `static func open(type_id: int) -> String`. Ela abre a tela do tipo pelo `Router.push` e devolve o texto para a barra de mensagem quando não abre (sem equipe), ou `""`. A tela de Explorar e a do interior usam a mesma.
- **`Session.load_interior(id: int) -> Result`**, pelo `GameService` e pelo `ApiGameService`.
- **A tela `interior`** (`screens/interior/`), registrada no `Router.SCREENS`, recebe `{"interior_id": id}` no `setup`. A [02](02-interior-screen.md) tem o resto.
- **O editor** fica em `tools/interior_editor/`, aberto pelo F2. A [03](03-interior-editor.md) tem o resto.

## O andar lá dentro

- A busca é um `AStarGrid2D` (a classe do Godot que acha o caminho numa grade de quadrados) com os quadrados bloqueados como sólidos e a diagonal só quando os dois vizinhos dela estão livres.
- O caminho de quadrados vira retas: a partir do ponto dos pés, o Domador vai direto até o ponto mais longe do caminho que a reta alcança sem passar por um quadrado bloqueado (conferido a cada 4 px), e assim até o fim. O último ponto é o ponto tocado.
- Tocar num quadrado bloqueado leva ao quadrado livre mais perto dele, pela distância até o ponto tocado.
- A velocidade é a de fora (`WalkRoute.WALK_SPEED`), em pixels da arte.
- O quadrado do Domador é o do ponto dos pés.

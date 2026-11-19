# interiors: plano de implementação

> **Para quem executa:** use superpowers:subagent-driven-development ou superpowers:executing-plans, tarefa por tarefa. Os passos usam `- [ ]` para marcar.

**Objetivo:** o Domador entra no Refúgio (e em qualquer prédio com sala), anda por uma sala de quadrados de 16 px com o tileset do Main Characters Home, fala com os NPCs e sai pela porta; o dono monta as salas no modo Interiores do F2.

**Arquitetura:** as salas moram no banco (`interiors` e 4 tabelas filhas) e saem por `GET /v1/interiors/:id`; a peça solta ganha `island_props.interior_id`. No jogo, a tela `interior` vai por cima de Explorar (`Router.push`), desenhada pelo `InteriorView` (`TileMapLayer` + objetos e atores em y-sort), com o andar pelo `InteriorRoute` (`AStarGrid2D` + retas). O F2 ganha o `InteriorEditor`, que edita um `InteriorDraft` e salva pelo `PUT`.

**Tecnologia:** NestJS + Prisma (schema `ecobeasts`, migration à mão + `prisma migrate deploy`), vitest; Godot 4.7 com GDScript tipado; Python 3 + Pillow para o script de importação.

**Spec:** [README](README.md), [architecture](architecture.md), [01](01-interior-data.md), [02](02-interior-screen.md), [03](03-interior-editor.md). Leia a spec da fase antes da tarefa: o plano decide o que ela deixa aberto e não repete o que ela já diz.

## Regras de todo o plano

- Textos do jogador em pt-BR; código, nomes de arquivo e de classe em inglês, como o resto do repositório.
- Código sem comentário por padrão; só o porquê que evita bug, em uma linha.
- Sem chave, senha ou token no repositório.
- Os e2e do servidor usam o banco de verdade: todo teste apaga o que cria e nunca muda a sala 1.
- As conferências do jogo são cenas temporárias em `client/zz_tmp_check/` (com os autoloads), rodadas por `C:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path client res://zz_tmp_check/<cena>.tscn`, que imprimem `OK` ou o erro e saem com `get_tree().quit()`. A pasta é apagada no fim de cada tarefa. Depois de criar um `class_name`, rode `... --headless --path client --editor --quit` uma vez.
- Uma conferência do jogo que fala com a API local (`localhost:3100`) usa o login do dono: ela só lê, ou cria e apaga uma sala própria. Nunca grava na sala 1 nem numa ilha.
- Commit por fase (`feat: ... (interiors 01)` etc., com `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), **só quando o dono pedir**, com `git add` só dos arquivos da fase: as mudanças em `client/story/scenes/*` não são desta iniciativa.
- Ao terminar uma fase, marque as tarefas e os critérios na spec dela e mude o status para concluída (o README da iniciativa, `.specs/README.md` e `.specs/roadmap.md` no fim da 03).

## Foco da revisão

Casos que nenhum teste de tarefa cobre e que mais podem morder:

1. **A porta coberta depois de salvar no F2:** um NPC posto no quadrado vizinho da porta e depois um bloqueio pintado na porta. O `InteriorDraft.save_error()` precisa recusar antes do `PUT` (teste na Tarefa 10).
2. **Diminuir a sala com a porta, NPCs e objetos fora dela:** a porta vai para o quadrado de dentro mais perto, e os NPCs e objetos que sobram fora saem (teste na Tarefa 10).
3. **Tocar fora da sala, no fundo escuro:** o ponto fora da grade leva ao quadrado livre mais perto, sem erro de índice no `AStarGrid2D` (teste na Tarefa 7).
4. **Sair e voltar sem ter andado:** o Domador nasce na porta, e só entrar na porta vindo de outro quadrado sai; tocar na própria porta ao nascer não sai (teste na Tarefa 8).
5. **Apagar uma sala ligada a uma peça só do rascunho:** o `DELETE` dá 409 também quando só o rascunho de uma ilha aponta para ela, porque o rascunho mora em `island_props` (teste na Tarefa 3).

---

## Fase 01: as salas no banco

### Task 1: as folhas, o script e a migration

**Arquivos:**
- Criar: `client/assets/interiors/main_home/walls_floor.png`, `interior.png`, `doors_windows.png` (cópias de `C:\Users\ferna\Downloads\main-characters-home-free-top-down-pixel-art-asset\Tiled_files\` `walls_floor.png`, `Interior.png`, `Doors_windows_animation.png`), `client/assets/interiors/CREDITOS.md`, `client/assets/interiors/import_tmx.py`
- Criar: `server/prisma/migrations/20270103000000_interiors/migration.sql`
- Alterar: `server/prisma/schema.prisma`, `server/test/database.e2e-spec.ts`, `.specs/game-data/architecture.md`

**Interfaces:**
- Produz: os modelos Prisma `Interior`, `InteriorTile`, `InteriorObject`, `InteriorBlock`, `InteriorNpc` (`@@map` para `interiors`, `interior_tiles`, `interior_objects`, `interior_blocks`, `interior_npcs`) e `IslandProp.interiorId Int? @map("interior_id")` com `interior Interior? @relation(... onDelete: Restrict)`; `Npc.interiorNpcs` e `ActionType.interiorNpcs` do lado de lá.
- Produz: `python client/assets/interiors/import_tmx.py <arquivo.tmx> <nome>` → SQL na saída.

- [x] **Passo 1:** copie as 3 folhas, com o `.import` igual ao de `client/assets/props/` (sem filtro, sem mipmaps), e escreva o `CREDITOS.md` no molde de `client/assets/props/CREDITOS.md`.
- [x] **Passo 2:** escreva o `import_tmx.py` pela [01 RF-02](01-interior-data.md#requisitos). Decisões que a spec deixa:
  - lê as camadas CSV dos `<chunk>`, tira os 3 bits de espelho do gid (`g & 0x1FFFFFFF`) e acha a folha pelo `firstgid` (a folha `Interior` do Tiled vira `interior`, `Doors_windows_animation` vira `doors_windows`);
  - sólido = pelo menos 128 pixels com alfa > 0 no tile de 16×16 (Pillow, com as folhas ao lado do `.tmx`);
  - o agrupamento é por busca nos 4 vizinhos, juntando `(x+dx, y+dy)` ao grupo quando tem a mesma folha e o tile `(col+dx, row+dy)`;
  - a saída é um bloco `DO $$ DECLARE room integer; BEGIN INSERT INTO "ecobeasts"."interiors" (...) VALUES (...) RETURNING id INTO room; INSERT ... ; END $$;`, com os tiles na ordem (camada, y, x), os objetos na ordem da spec e os bloqueios por (y, x), sem duplicar um quadrado (um bloqueio da parede e de um objeto viram uma linha só);
  - sem argumentos certos, imprime o uso e sai com código 2.
- [x] **Passo 3:** rode o script duas vezes no `Interior1.tmx` e compare (`diff` vazio). Monte uma imagem da sala a partir do SQL (um script no scratchpad, não no repositório) e compare com o `Interior1.tmx` renderizado; confira que a porta cai na linha de baixo do cômodo principal e que os quadrados livres são o chão de verdade.
- [x] **Passo 4:** escreva a migration: as 5 tabelas e a coluna pela [architecture](architecture.md#as-tabelas), com os `CHECK` nomeados `<tabela>_<coluna>_check` (`interiors_name_check`, `interiors_width_check`, `interiors_height_check`, `interiors_door_check`, `interior_tiles_layer_check`, `interior_tiles_sheet_check`, `interior_tiles_col_check`, `interior_tiles_row_check`, `interior_objects_size_check`, `interior_npcs_dialogue_check` e os de x/y ≥ 0), os índices das FKs, o `ALTER TABLE island_props ADD COLUMN interior_id integer REFERENCES ... ON DELETE RESTRICT` com índice, e no fim o SQL da sala 1 colado do script, com o nome "Refúgio".
- [x] **Passo 5:** escreva os modelos no `schema.prisma`, com os `///` de cada CHECK como os outros modelos, e rode `npx prisma generate`.
- [x] **Passo 6:** em `database.e2e-spec.ts`, o total de tabelas de `ecobeasts` passa de 73 para 78 (e o título do teste diz 78), e um teste novo `recusa uma porta fora da sala (interiors)` que insere uma sala com `door_x = width` e espera `interiors_door_check`, no molde do `expectRejected` do arquivo.
- [x] **Passo 7:** aplique com `npx prisma migrate deploy` e rode `npm run test:e2e -- test/database.e2e-spec.ts`. Esperado: passa.
- [x] **Passo 8:** acrescente as 5 tabelas e a coluna em `.specs/game-data/architecture.md`, na seção das tabelas, no estilo das ilhas.

### Task 2: as rotas da sala

**Arquivos:**
- Criar: `server/src/domain/interiors/interior-body.ts` e `interior-body.spec.ts`
- Criar: `server/src/interiors/interiors.module.ts`, `interiors.controller.ts`, `interiors.service.ts`, `interiors.dto.ts`
- Criar: `server/src/editor/interiors-editor.controller.ts`, `interiors-editor.service.ts`, `interiors-editor.dto.ts`
- Criar: `server/test/interiors.e2e-spec.ts`
- Alterar: `server/src/app.module.ts`, `server/src/editor/editor.module.ts`, `server/vitest.config.e2e.ts` (o e2e novo em `CATALOG_WRITERS`)

**Interfaces:**
- Produz, em `interior-body.ts`:
  ```ts
  export const INTERIOR_LAYERS = ['floor', 'floor_detail', 'wall', 'wall_detail'] as const;
  export interface InteriorBody { name: string; width: number; height: number; door: Cell;
    tiles: { layer: string; x: number; y: number; sheet: string; col: number; row: number }[];
    objects: { x: number; y: number; sheet: string; col: number; row: number; width: number; height: number }[];
    blocks: Cell[]; npcs: { npc_id: number; x: number; y: number; dialogue: string; action_type_id: number | null }[] }
  export interface InteriorKnownIds { npcIds: ReadonlySet<number>; actionTypeIds: ReadonlySet<number> }
  export function interiorError(body: InteriorBody, known: InteriorKnownIds): string | null;
  ```
- Produz: `InteriorsService.read(id: number): Promise<InteriorDto | null>` (exportado pelo `InteriorsModule`, usado pelo editor), `INTERIOR_NOT_FOUND = 'Esse lugar não existe.'`; no editor, `EDITOR_INTERIOR_NOT_FOUND = 'Interior não encontrado.'` e `INTERIOR_IN_USE = 'Uma peça de ilha leva a esse interior.'`.
- Produz: `InteriorDto` (o corpo da [architecture](architecture.md#as-rotas), com `id`), `InteriorBodyDto` (o mesmo, com os `id` opcionais e ignorados), `NewInteriorDto` (`name`, `width`, `height`), `InteriorListDto` (`{ interiors: { id, name }[] }`).

As mensagens de `interiorError`, conferidas nesta ordem (a primeira que falha volta):

| Regra | Mensagem |
| --- | --- |
| nome de 1 a 40 | `O nome precisa ter de 1 a 40 caracteres.` |
| largura e altura de 4 a 64 | `A largura e a altura vão de 4 a 64 quadrados.` |
| até 16.384 tiles, 1.000 objetos, 50 NPCs | `A sala pode ter até 16.384 tiles.` / `até 1.000 objetos.` / `até 50 NPCs.` |
| camada fora das 4, `sheet` fora de `^[a-z0-9_]+$`, `col`/`row` fora de 0 a 63 | `Há um tile inválido.` |
| tile fora da sala | `Há um tile fora da sala.` |
| dois tiles no mesmo quadrado e camada | `Há dois tiles no mesmo quadrado e camada.` |
| objeto com folha, tile ou tamanho (1 a 8) inválidos | `Há um objeto inválido.` |
| objeto que passa da borda | `Há um objeto que passa da borda da sala.` |
| bloqueio fora da sala | `Há um bloqueio fora da sala.` |
| bloqueio repetido | `Há um bloqueio repetido.` |
| fala com mais de 2.000 caracteres | `A fala do NPC pode ter até 2.000 caracteres.` |
| `npc_id` que não existe | `Esse NPC não existe.` |
| `action_type_id` que não existe | `O NPC tem uma ação que não existe.` |
| NPC fora da sala, sem chão, bloqueado, na porta ou no quadrado de outro NPC | `O NPC precisa de um quadrado livre.` |
| porta fora da sala, sem chão ou bloqueada | `A porta precisa estar num quadrado de chão, sem bloqueio.` |

- [x] **Passo 1:** escreva `interior-body.spec.ts` com uma sala válida de 6×5 (chão em tudo, porta em (3, 4)) e um `it` por linha da tabela, mudando só o necessário e esperando a mensagem exata; mais um `it('aceita a sala válida')` que espera `null`, e um que aceita a parede (`layer: 'wall'`) na porta, porque a parede não bloqueia sozinha.
- [x] **Passo 2:** rode `npm test -- interior-body`. Esperado: falha, `interiorError` não existe.
- [x] **Passo 3:** implemente `interiorError`. Rode de novo. Esperado: passa.
- [x] **Passo 4:** escreva `interiors.e2e-spec.ts` (molde do `npc-voice.e2e-spec.ts`, com o `MAP_EDITOR_USER_IDS` do teste), que cria as próprias salas e as apaga no `afterAll`:
  - `GET /v1/interiors/1` traz o Refúgio: os 4 `layer` presentes nos tiles, `objects` e `blocks` não vazios, e a porta num quadrado com tile `floor` e fora de `blocks`;
  - `GET /v1/interiors/999999` e `/v1/interiors/abc` dão 404 com `Esse lugar não existe.`; sem sessão, 401;
  - `GET /v1/editor/interiors` traz `{ id: 1, name: 'Refúgio' }`; a quem não é editor, 403;
  - `POST` com `{ name: 'Teste e2e', width: 8, height: 6 }` dá 201 com a sala vazia e a porta em (4, 5);
  - `PUT` dessa sala com chão em tudo, um objeto, um bloqueio e um NPC (o NPC 3, com a ação de id 1) devolve os `id` novos, e um segundo `PUT` igual devolve outros `id`; o `GET` do editor traz o mesmo corpo;
  - `PUT` com a porta num bloqueio dá 400 com a mensagem da porta; com um tile em `x = 8`, 400 `Há um tile fora da sala.`; numa sala que não existe, 404 `Interior não encontrado.`;
  - `DELETE` apaga, e o `GET` depois dá 404.
- [x] **Passo 5:** rode `npm run test:e2e -- test/interiors.e2e-spec.ts`. Esperado: falha (404 nas rotas).
- [x] **Passo 6:** implemente o módulo `interiors` (`@UseGuards(AuthGuard)`, `@Controller('interiors')`, o `ParseIntPipe` com 404 como o do `npcs-editor`) e o controller do editor (`@UseGuards(AuthGuard, EditorGuard)`, `@Controller('editor/interiors')`), com os decorators do Swagger no molde do `NpcsEditorController`. O `PUT` confere com `interiorError` (os ids conhecidos lidos de `npc` e `actionType`) e troca tudo numa `$transaction`: apaga os filhos, atualiza a sala (com `updatedAt: new Date()`) e recria tiles, objetos (`createManyAndReturn`, na ordem do corpo), bloqueios e NPCs. O `POST` cria sem conferir a regra da porta (a sala nasce sem chão). A leitura ordena tiles por camada (na ordem de `INTERIOR_LAYERS`), y e x; objetos e NPCs por `id`; bloqueios por y e x. O `DELETE` conta `islandProp` com o `interiorId` antes e dá 409 com `INTERIOR_IN_USE`.
- [x] **Passo 7:** rode o e2e de novo. Esperado: passa. Rode `npm run lint` e `npm run typecheck`.

### Task 3: a sala na peça

**Arquivos:**
- Alterar: `server/src/domain/islands/island-draft.ts`, `server/src/editor/islands-editor.dto.ts`, `server/src/editor/islands-editor.service.ts`, `server/src/islands/islands.service.ts`, `server/src/exploration/exploration.dto.ts`
- Teste: `server/test/interiors.e2e-spec.ts`

**Interfaces:**
- Produz: `DraftProp.interiorId?: number` (só quando há), `KnownIds.interiorIds: ReadonlySet<number>`, `DraftPropDto.interior_id?: number | null`, `MapPropDto.interior_id?: number`.

- [x] **Passo 1:** no e2e, um `describe('a sala na peça')`: cria uma sala, cria uma ilha de teste pelo `POST /v1/editor/islands` com uma peça com `interior_id`, e confere:
  - o `GET` do rascunho traz o `interior_id` na peça;
  - salvar com `interior_id: 999999` dá 400 `Esse interior não existe.`;
  - o `DELETE` da sala dá 409 com só o rascunho apontando;
  - publicar e o mapa da ilha publicada traz o `interior_id` (pela mesma leitura que o `islands-editor.e2e` usa para conferir a publicação);
  - no `afterAll`, apaga a ilha e depois a sala.
- [x] **Passo 2:** rode e veja falhar.
- [x] **Passo 3:** leve o `interiorId` pelo mesmo caminho do `noSmoke` (`toDraft`, as duas listas do `writeVersion`, a leitura no `islands.service`, o `toPropDto`), com o erro `Esse interior não existe.` no `draftError` depois do erro da ação da peça. Ponha o `interiorId` no `contentHash` só quando há, como o `actionTypeId`, para uma ilha sem sala manter o hash.
- [x] **Passo 4:** rode o e2e, `npm run lint`, `npm run typecheck`, `npm test` e a suíte inteira `npm run test:e2e`. Esperado: tudo passa, menos as 2 falhas que já existiam no `seed.e2e`.

### Task 4: a sala no jogo

**Arquivos:**
- Criar: `client/domain/models/interior.gd`, `interior_tile.gd`, `interior_object.gd`, `interior_npc.gd`
- Alterar: `client/domain/models/map_prop.gd`, `client/tools/map_editor/stamp.gd`, `client/core/services/game_service.gd`, `client/core/services/api_game_service.gd`, `client/core/autoload/session.gd`

**Interfaces:**
- Produz:
  - `InteriorTile`: `layer: String`, `cell: Vector2i`, `sheet: String`, `atlas: Vector2i` (col, row); `from_dict`, `to_dict`.
  - `InteriorObject`: `id: int`, `cell: Vector2i`, `sheet: String`, `atlas: Vector2i`, `size: Vector2i`; `from_dict`, `to_dict`, `rect() -> Rect2i`, `foot_y() -> int` (a linha da borda de baixo, `cell.y + size.y`).
  - `InteriorNpc`: `id`, `npc_id`, `cell`, `dialogue`, `action_type_id` (0 sem); `from_dict`, `to_dict` (`action_type_id` nulo quando 0), `to_map_npc() -> MapNpc` (parado, `coord = cell`).
  - `Interior`: `id`, `name`, `width`, `height`, `door: Vector2i`, `tiles: Array[InteriorTile]`, `objects: Array[InteriorObject]`, `blocks: Array[Vector2i]`, `npcs: Array[InteriorNpc]`; `static from_dict(d) -> Interior` (null sem `width`/`height` válidos), `to_dict() -> Dictionary` (o corpo da architecture, com os `id`), `has_cell(cell) -> bool`, `tile_at(layer, cell) -> InteriorTile`.
  - `MapProp.interior_id: int` (0 sem sala).
  - `Session.load_interior(id: int) -> Result` (com `Interior` em `data`), por `GameService.load_interior` e `ApiGameService.load_interior` (`GET /v1/interiors/%d`, falha `ApiResponse.SERVER_ERROR` quando o corpo não vira `Interior`).

- [x] **Passo 1:** escreva `zz_tmp_check/models.tscn`: um `Interior.from_dict` do corpo da architecture volta igual pelo `to_dict`; `MapProp.from_dict({..., "interior_id": 3}).interior_id == 3` e 0 sem o campo; `InteriorNpc` com fala de dois parágrafos dá `to_map_npc().lines().size() == 2` e `still == true`. Rode: falha (classes não existem).
- [x] **Passo 2:** implemente os modelos, o `MapProp.interior_id`, o `interior_id` no `Stamp._copy_extras` e o `load_interior`. Rode o `--editor --quit` e a cena. Esperado: `OK`.
- [x] **Passo 3:** acrescente à cena um `await Session.load_interior(1)` contra a API local: `ok`, `name == "Refúgio"` e `tiles.size() > 0`. Rode com a API de pé. Esperado: `OK`. Apague `zz_tmp_check/`.
- [x] **Passo 4:** `--headless --path client --quit-after 30` sem erro de script.
- [x] **Passo 5:** marque a fase 01 na spec. Commit da fase, só quando o dono pedir: `feat: as salas dos interiores no banco, as rotas e o Refúgio convertido (interiors 01)`.

---

## Fase 02: a tela do interior

### Task 5: o `ActionScreens` e a peça com sala

**Arquivos:**
- Criar: `client/core/action_screens.gd`
- Alterar: `client/screens/exploration/exploration_screen.gd`

**Interfaces:**
- Produz:
  ```gdscript
  class_name ActionScreens extends RefCounted
  const SCREENS: Dictionary[String, StringName]  # o ACTION_SCREENS de hoje
  const NO_TEAM_TRAVEL_TEXT := "Você precisa de um Ecobeast para viajar."
  const NO_TEAM_HEAL_TEXT := "Você ainda não tem Ecobeasts para cuidar."
  static func screen_for(type_id: int) -> StringName  # &"" sem tela
  static func open(type_id: int) -> String  # abre pelo Router.push e devolve ""; sem equipe, não abre e devolve a frase
  ```

- [x] **Passo 1:** `zz_tmp_check/actions.tscn`: `screen_for` do id da ação `refuge` é `&"heal_station"`, de `travel` é `&"travel"`, de 0 é `&""`; com `Session.player` sem inicial (troque o `player` por um sem inicial na cena e devolva no fim), `open` do `refuge` devolve `NO_TEAM_HEAL_TEXT` sem abrir tela. Rode: falha.
- [x] **Passo 2:** crie o `ActionScreens` (a regra sem equipe é `Session.player == null or not Session.player.has_starter()`) e troque a `ExplorationScreen`: `_run_action_type` hide o `_debug_menu` e mostra a frase devolvida na barra (`&"SecondaryLabel"`); as constantes saem dela; um `_open_prop(index)` abre `Router.push(&"interior", {"interior_id": id})` quando a peça tem sala e senão roda a ação, chamado nos dois lugares que hoje rodam a ação da peça (o já encostado do `_go_to_prop` e o fim da caminhada, no ramo `_prop_target` do fim do `_walk`); e o `_prop_hit` aceita a peça com sala mesmo sem ação.
- [x] **Passo 3:** rode a cena. Esperado: `OK`. O `Router` ainda não tem `interior`: a peça com sala só abre depois da Tarefa 8.

### Task 6: o `InteriorTiles` e o `InteriorView`

**Arquivos:**
- Criar: `client/ui/components/interior_tiles.gd`, `client/ui/components/interior_view.gd`

**Interfaces:**
- Consome: `Interior`, `InteriorTile`, `InteriorObject` (Tarefa 4).
- Produz:
  ```gdscript
  class_name InteriorTiles extends RefCounted
  const SHEETS: Array[String] = ["walls_floor", "interior", "doors_windows"]
  const SHEET_PATH := "res://assets/interiors/main_home/%s.png"
  const CELL := 16
  const SOLID_PIXELS := 128
  static func tile_set() -> TileSet  # montado uma vez (static var)
  static func source_id(sheet: String) -> int  # -1 desconhecida
  static func sheet_texture(sheet: String) -> Texture2D
  static func sheet_cells(sheet: String) -> Vector2i  # o tamanho em tiles
  static func has_tile(sheet: String, atlas: Vector2i) -> bool
  static func is_solid(sheet: String, atlas: Vector2i) -> bool  # cache por folha
  static func blocked(interior: Interior) -> Dictionary[Vector2i, bool]  # sem chão ou em blocks; sem os NPCs
  static func cell_center(cell: Vector2i) -> Vector2
  static func cell_of(point: Vector2) -> Vector2i

  class_name InteriorView extends Node2D
  var actors: Node2D
  func show_interior(interior: Interior) -> void
  func refresh_tiles(cells: Array[Vector2i]) -> void  # as 4 camadas nesses quadrados
  func refresh_objects() -> void
  ```
- Decisões: no `TileSet`, `tile_size` 16 e cada tile com `y_sort_origin = 8`, para a camada em y-sort ordenar o tile da parede pela borda de baixo do quadrado (o `TileMapLayer` ordena pelo meio do quadrado). O `Sprite2D` do objeto tem `centered = false`, `region_enabled`, e a posição no pé de ordenar; um objeto que cobre um quadrado de um objeto anterior da lista usa o pé mais baixo dos dois ([architecture](architecture.md#o-jogo)), com o `offset` corrigido para a arte ficar no lugar. `texture_filter` NEAREST em tudo.

- [x] **Passo 1:** `zz_tmp_check/view.tscn`: com a sala 1 lida da API, `blocked` não tem a porta e tem os quadrados sem chão; `is_solid("walls_floor", Vector2i(1, 1))` é verdade e `is_solid("walls_floor", Vector2i(1, 0))` (o contorno fino) é falso; `show_interior` cria as 4 camadas, um `Sprite2D` por objeto e o `actors`; numa sala de teste em memória com uma mesa 2×2 em (2, 2) e uma jarra 1×1 em (2, 2), o `y` de ordenar da jarra é o da mesa. Rode: falha.
- [x] **Passo 2:** implemente. Rode: `OK`.
- [x] **Passo 3:** tire uma imagem da sala 1 pelo `InteriorView` numa cena com janela (`get_viewport().get_texture().get_image().save_png(...)` no scratchpad) e compare com o renderizado do `.tmx` da Tarefa 1. Apague `zz_tmp_check/`.

### Task 7: o `InteriorRoute`

**Arquivos:**
- Criar: `client/screens/interior/interior_route.gd`

**Interfaces:**
- Consome: `InteriorTiles.blocked`, `cell_center`, `cell_of`.
- Produz:
  ```gdscript
  class_name InteriorRoute extends RefCounted
  const SAMPLE_STEP := 4.0
  func _init(interior: Interior, extra_blocked: Dictionary[Vector2i, bool] = {}) -> void  # extra: os quadrados dos NPCs
  func is_blocked(cell: Vector2i) -> bool  # fora da sala conta como bloqueado
  func nearest_free(point: Vector2) -> Vector2i  # (-1, -1) se não há
  func is_clear(from: Vector2, to: Vector2) -> bool
  func route(from: Vector2, to: Vector2) -> PackedVector2Array  # sem o ponto de partida; vazio sem caminho
  func route_to_cell(from: Vector2, cell: Vector2i) -> PackedVector2Array  # termina no centro do quadrado
  func approach(from: Vector2, target: Vector2i) -> Vector2i  # o vizinho livre (4 direções) de caminho mais curto; (-1, -1) sem
  ```
- Decisões: `AStarGrid2D` com `region` da sala, `cell_size` 16, `diagonal_mode = DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES`, heurística euclidiana; os pontos do caminho são os centros dos quadrados; a reta segue a [architecture](architecture.md#o-andar-lá-dentro). Um destino bloqueado ou fora da sala vira o centro do `nearest_free` do ponto tocado.

- [x] **Passo 1:** `zz_tmp_check/route.tscn` numa sala de teste 8×6 com uma parede vertical em x = 4 de y = 0 a 3:
  - `route` de (1, 1) a (6, 1) passa pela abertura de baixo e nenhum ponto amostrado de 4 em 4 px cai em quadrado bloqueado;
  - numa sala sem obstáculo, `route` de (0, 0) a (5, 3) tem um ponto só (a reta corta as quinas livres);
  - tocar no meio da parede leva ao livre mais perto; tocar em (-40, -40), fora da sala, dá um caminho para (0, 0), sem erro;
  - com o destino cercado por bloqueios, `route` é vazio;
  - `approach` de um NPC encostado na parede escolhe um vizinho livre, e cercado dá (-1, -1).
  Rode: falha.
- [x] **Passo 2:** implemente. Rode: `OK`. Apague `zz_tmp_check/`.

### Task 8: a tela, a câmera, o andar e a porta

**Arquivos:**
- Criar: `client/screens/interior/interior_screen.gd`, `interior_screen.tscn`
- Alterar: `client/core/autoload/router.gd` (`&"interior": "res://screens/interior/interior_screen.tscn"`)

**Interfaces:**
- Consome: `Session.load_interior`, `InteriorView`, `InteriorRoute`, `ViewSettings.explore_zoom()`, `WalkRoute.WALK_SPEED`, `TamerSprite`.
- Produz: `setup(params: Dictionary)` (`interior_id` ou `interior`), `handle_back() -> bool`, e para os testes: `func player_point() -> Vector2`, `func tap_art(point: Vector2) -> void` (o mesmo caminho do toque, em pixels da arte).
- Decisões:
  - a cena tem o `RoomArea` (Control, tela cheia, `clip_contents`) com o `InteriorView`, e por cima o `SafeArea` com o nome no topo e a barra de mensagem embaixo, copiando o `IslandPlate`/`IslandName` e a `Message` do `exploration_screen.tscn` com as mesmas variações de tema; o "Entrando…" e o erro com Voltar ficam no meio;
  - a câmera segue a [02 RF-05](02-interior-screen.md#a-tela): o Domador no centro, em pixels inteiros, presa à borda da sala no eixo em que ela é maior que a tela e centrada no outro;
  - a escala é a do `HexMapView._level_scale` (os pixels da janela por pixel da arte, inteiros) com o degrau do `ViewSettings`; o Domador e os NPCs ficam no `actors` em escala 1;
  - o Domador anda pela rota a `WALK_SPEED` (em pixels da arte, sem o `Y_STRETCH` dos hexágonos), vira para cada reta (`face_toward`) e toca `play_run`/`play_idle`;
  - a porta: o quadrado de agora fica em `_cell`; quando ele muda para a porta vindo de outro, `Router.back()`;
  - o toque é um `InputEventMouseButton` ou `InputEventScreenTouch` solto no `RoomArea`, convertido para a arte por `(posição - view.position) / view.scale`.

- [x] **Passo 1:** `zz_tmp_check/screen.tscn`: abre a tela `placeholder` pelo `Router.go_to` e faz `Router.push(&"interior", {"interior": <sala de teste 8×6, porta em (4, 5)>})`; confere que o Domador nasce no centro da porta; `tap_art` num ponto longe da porta anda (espere o `_process` por frames) e o Domador não sai; `tap_art` de volta à porta faz a tela sair (`Router.can_go_back()` falso de novo); e tocar na porta logo ao nascer não sai. Rode: falha.
- [x] **Passo 2:** implemente a tela e registre no `Router`. Rode: `OK`.
- [x] **Passo 3:** a mesma cena com `{"interior_id": 1}` contra a API: mostra "Entrando…", depois o nome "Refúgio"; com `{"interior_id": 999999}`, mostra `Esse lugar não existe.` e o Voltar. Esperado: `OK`. Apague `zz_tmp_check/`.

### Task 9: os NPCs, a conversa, a ação e a cura

**Arquivos:**
- Alterar: `client/screens/interior/interior_screen.gd`, `interior_screen.tscn` (o `TamerGreetingPanel` embaixo, como em Explorar)

**Interfaces:**
- Consome: `InteriorNpc.to_map_npc()`, `NpcSprite.make`, `InteriorRoute.approach`, `TamerGreetingPanel.say/close` e o sinal `tapped`, `GameData.npc_voice`, `ActionScreens.open`.
- Decisões: o NPC fica em `actors`, no centro do quadrado, `play_idle()` e virado para baixo; os quadrados dos NPCs vão no `extra_blocked` da rota; tocar num NPC (pelo `NpcSprite.hits`) tem prioridade sobre o chão; a conversa trava o toque no mapa até fechar, como em Explorar (`_talking`, `_talk_lines`, `_talk_index`); o voltar do aparelho com a conversa aberta fecha a caixa e não roda a ação.

- [x] **Passo 1:** `zz_tmp_check/talk.tscn`, numa sala em memória com o NPC 3 em (4, 1), fala `"Olá!\n\nVamos cuidar da equipe?"` e a ação `refuge`: `tap_art` no NPC anda até um vizinho livre, vira os dois um para o outro e abre a caixa com a primeira fala; dois `tapped` depois, a caixa fecha e a tela no topo do `Router` é a `heal_station` (com o jogador do dono, que tem inicial); `Router.back()` volta para a sala. Num NPC sem fala nem ação, chegar só vira os dois. Rode: falha.
- [x] **Passo 2:** implemente. Rode: `OK`. Apague `zz_tmp_check/`.
- [x] **Passo 3:** `--headless --path client --quit-after 30` sem erro de script.
- [x] **Passo 4:** marque a fase 02 na spec; os critérios do F5 ficam abertos até o fim da 03. Commit da fase, só quando o dono pedir: `feat: a tela do interior, com o andar, os NPCs e a cura no balcão (interiors 02)`.

---

## Fase 03: o modo Interiores do F2

### Task 10: o `InteriorDraft`

**Arquivos:**
- Criar: `client/tools/interior_editor/interior_draft.gd`

**Interfaces:**
- Consome: `Interior` e os modelos (Tarefa 4), `InteriorTiles.is_solid`, `has_tile`, `blocked`.
- Produz:
  ```gdscript
  class_name InteriorDraft extends RefCounted
  const NPC_NEEDS_FREE := "O NPC precisa de um quadrado livre."
  const DOOR_NEEDS_FLOOR := "A porta precisa estar num quadrado de chão, sem bloqueio."
  var interior: Interior
  func _init(source: Interior) -> void  # copia pelo to_dict
  static func stamp_origin(stroke_start: Vector2i, cell: Vector2i, size: Vector2i) -> Vector2i
  func paint(layer: String, cell: Vector2i, sheet: String, atlas: Vector2i, size: Vector2i) -> Array[Vector2i]  # cortado na borda; na wall, o sólido marca o bloqueio
  func erase(layer: String, cell: Vector2i) -> bool  # na wall, o sólido desmarca o bloqueio
  func place_object(cell: Vector2i, sheet: String, atlas: Vector2i, size: Vector2i) -> int  # -1 se passa da borda; marca a linha de baixo (a inteira com 1 linha)
  func object_at(cell: Vector2i) -> int  # o de pé mais baixo; -1
  func move_object(index: int, cell: Vector2i) -> bool  # preso dentro da sala; os bloqueios não andam junto
  func remove_object(index: int) -> void
  func set_block(cell: Vector2i, on: bool) -> bool
  func place_npc(cell: Vector2i, npc_id: int, dialogue: String, action_type_id: int) -> String  # "" ou NPC_NEEDS_FREE
  func npc_at(cell: Vector2i) -> int
  func move_npc(index: int, cell: Vector2i) -> String
  func update_npc(index: int, npc_id: int, dialogue: String, action_type_id: int) -> void
  func remove_npc(index: int) -> void
  func set_door(cell: Vector2i) -> String  # "" ou DOOR_NEEDS_FLOOR
  func resize(width: int, height: int) -> void  # corta tiles, objetos, bloqueios e NPCs de fora; a porta vai ao quadrado de dentro mais perto
  func save_error() -> String  # a regra da porta e a dos NPCs, antes do PUT
  func snapshot() -> Dictionary
  func restore(data: Dictionary) -> void
  ```

- [x] **Passo 1:** `zz_tmp_check/draft.tscn` com os casos da [03 Verificação](03-interior-editor.md#verificação) e os dois do Foco da revisão (porta coberta por um bloqueio depois de pôr o NPC, e `resize` com a porta, um NPC e um objeto fora), mais: `paint` de um retângulo 3×2 em (6, 5) numa sala 8×6 só escreve os 2×1 de dentro; `stamp_origin(Vector2i(1, 1), Vector2i(4, 2), Vector2i(2, 2)) == Vector2i(3, 1)`; `snapshot`/`restore` voltam a sala; e `interior.to_dict()` tem as chaves do corpo da architecture. Rode: falha.
- [x] **Passo 2:** implemente. Rode: `OK`. Apague `zz_tmp_check/`.

### Task 11: a janela, a lista, o salvar e as mudanças

**Arquivos:**
- Criar: `client/tools/interior_editor/interior_editor.gd`
- Alterar: `client/tools/map_editor/editor_api.gd`, `client/tools/map_editor/map_editor.gd`

**Interfaces:**
- Produz no `EditorApi`: `INTERIORS_PATH := "/v1/editor/interiors"`, `list_interiors()`, `read_interior(id)`, `create_interior(name, width, height)`, `save_interior(id, body)`, `delete_interior(id)`, todos `-> ApiResponse`.
- Produz no `MapEditor`: `func ask_unsaved() -> String` (`"save"`, `"discard"` ou `"cancel"`, pelo `_unsaved_dialog` de hoje; o `_resolve_unsaved` passa a usá-la).
- Produz:
  ```gdscript
  class_name InteriorEditor extends VBoxContainer
  signal islands_requested
  signal interiors_changed(rows: Array)  # a lista [{id, name}] depois de criar, salvar ou apagar
  func open() -> void  # lê a lista e abre a última sala, ou a 1
  func resolve_unsaved(ask: Callable) -> bool  # ask devolve a String do ask_unsaved
  func handle_input(event: InputEvent) -> bool
  func is_dirty() -> bool
  ```
- Decisões: o desfazer é um `UndoRedo` próprio, com um passo por `snapshot` antes e depois (`add_do_method(restore.bind(depois))`, `add_undo_method(restore.bind(antes))`), e o sujo é a versão diferente da salva, como no `MapEditor._update_dirty`. No `MapEditor`, o botão Interiores fica no `header` depois da Linha da história; trocar esconde o `_editor` e mostra o `InteriorEditor` (filho do mesmo `stack`), depois do `_resolve_unsaved` da ilha; o `close()` também passa pelo `resolve_unsaved` do interior; o `_on_window_input` entrega o evento ao `InteriorEditor` quando ele está à mostra.

- [x] **Passo 1:** `zz_tmp_check/editor_api.tscn` contra a API: `create_interior("Teste F2", 6, 5)`, `save_interior` com chão em tudo e a porta em (3, 4), `read_interior` traz o mesmo, `delete_interior` apaga; a sala 1 não é tocada. Rode: falha.
- [x] **Passo 2:** implemente o `EditorApi`. Rode: `OK`. Apague `zz_tmp_check/`.
- [x] **Passo 3:** implemente o `InteriorEditor` com a barra de cima da [03 RF-02](03-interior-editor.md#a-janela) (Salas num `PopupPanel` como o Ilhas do `MapEditor`, Nova sala com nome, largura e altura num `ConfirmationDialog`, Excluir com confirmação, os campos de nome e tamanho, Salvar, Desfazer, Refazer, Ilhas, a chave Bloqueios e a barra de mensagem) e o meio vazio por enquanto. O Salvar confere `save_error()` antes do `PUT` e escreve "Sala salva." ou o erro.
- [x] **Passo 4:** confira no F2 (com o jogo rodando pelo editor do Godot): Interiores abre o Refúgio; mudar o nome põe o asterisco; Ilhas pergunta; Descartar volta sem salvar. `--headless --path client --quit-after 30` sem erro.

### Task 12: o canvas, a paleta, os tiles e os objetos

**Arquivos:**
- Criar: `client/tools/interior_editor/interior_canvas.gd`, `interior_palette.gd`
- Alterar: `client/tools/interior_editor/interior_editor.gd`

**Interfaces:**
- Consome: `InteriorView` (`show_interior`, `refresh_tiles`, `refresh_objects`), `InteriorDraft`.
- Produz:
  ```gdscript
  class_name InteriorCanvas extends Control  # clip_contents, com o InteriorView filho em escala inteira
  signal stroke_started(cell: Vector2i, secondary: bool)
  signal stroke_moved(cell: Vector2i)
  signal stroke_ended
  signal hovered(cell: Vector2i)
  var show_blocks := false
  func set_draft(draft: InteriorDraft) -> void
  func refresh_cells(cells: Array[Vector2i]) -> void
  func refresh_all() -> void
  func set_preview(sheet: String, atlas: Vector2i, size: Vector2i) -> void  # o fantasma da escolha no quadrado do mouse

  class_name InteriorPalette extends VBoxContainer
  signal picked(sheet: String, atlas: Vector2i, size: Vector2i)
  ```
- Decisões: as abas mostram `walls_floor`, `interior` e `doors_windows` (a última só na primeira linha de quadros, a linha 0); a ferramenta e a tecla ficam numa coluna à esquerda com os ícones de `tools/map_editor/icons/` que já servirem (sem ícone, o texto); a grade e a borda são desenhadas no `_draw` do canvas, por cima do `InteriorView`. Uma pincelada inteira é um passo do desfazer.

- [x] **Passo 1:** implemente o canvas (zoom de 1 a 6 em volta do mouse, arrasto pelo botão do meio ou espaço + esquerdo, grade, borda e o quadrado do mouse), a paleta e as ferramentas Chão, Detalhe do chão, Parede, Detalhe da parede e Objeto pela [03 RF-05 a RF-07](03-interior-editor.md#pintar), ligando os sinais ao `InteriorDraft` e o desfazer.
- [x] **Passo 2:** confira no F2: pintar chão em arrasto repete o carimbo e corta na borda; a parede sólida aparece bloqueada com a chave Bloqueios; uma estante posta se move de quadrado em quadrado e Delete a apaga; Ctrl+Z desfaz a pincelada inteira e Ctrl+Y refaz.

### Task 13: Bloqueio, NPC e Porta

**Arquivos:**
- Criar: `client/tools/interior_editor/interior_npc_panel.gd`
- Alterar: `client/tools/interior_editor/interior_editor.gd`, `interior_canvas.gd`

**Interfaces:**
- Produz:
  ```gdscript
  class_name InteriorNpcPanel extends VBoxContainer
  signal changed(npc_id: int, dialogue: String, action_type_id: int)  # o NPC escolhido foi editado
  func show_npc(npc: InteriorNpc) -> void  # null: os campos do próximo NPC
  func values() -> Dictionary  # {npc_id, dialogue, action_type_id}
  ```
- Decisões: a lista de NPCs vem de `GameData.get_rows("npcs")` com o `NpcSprite.icon_frame`; a das ações, de `action_types`, com "Nenhuma"; editar a fala é um passo do desfazer ao sair do campo, não a cada letra. O canvas desenha os NPCs pelo `NpcSprite.icon_frame` no centro do quadrado e a porta com um contorno de 2 px em `UiPalette.WARNING`.

- [x] **Passo 1:** implemente as ferramentas Bloqueio, NPC e Porta pela [03 RF-08 a RF-10](03-interior-editor.md#pintar), com as mensagens da spec na barra.
- [x] **Passo 2:** confira no F2: o NPC não vai para um bloqueio nem para a porta; a porta não vai para um quadrado bloqueado; salvar uma sala de teste com um NPC com fala e a ação Refúgio e abrir a tela `interior` dela por uma cena temporária mostra o NPC; apague a sala de teste.

### Task 14: a Sala na ferramenta Peças

**Arquivos:**
- Alterar: `client/tools/map_editor/object_panel.gd`, `client/tools/map_editor/map_editor.gd`

**Interfaces:**
- Produz: `ObjectPanel.set_interiors(rows: Array) -> void`; o `MapEditor` a chama depois de ler `EditorApi.list_interiors()` no `_refresh_list` e no `interiors_changed` do `InteriorEditor`.
- Decisões: a linha Sala fica logo abaixo da Ação, no molde dela (`_interior_select`, `_interior_ids`, um `_step("Trocar a sala da peça")`); "Nenhuma" apaga a chave `interior_id` do dicionário da peça; uma peça com uma sala que não está mais na lista mostra "Nenhuma" e não muda até o dono escolher.

- [x] **Passo 1:** implemente.
- [x] **Passo 2:** confira no F2: escolher a sala numa peça marca a ilha como mudada, Ctrl+Z desfaz, e salvar e ler de novo mantém o `interior_id`. Não salve em Liora nesta conferência: use uma ilha de teste e apague-a.

### Task 15: as docs e o fim

**Arquivos:**
- Alterar: `client/CLAUDE.md`, `server/CLAUDE.md`, `CLAUDE.md` (o parágrafo do escopo), `.specs/interiors/*.md`, `.specs/README.md`, `.specs/roadmap.md`

- [x] **Passo 1:** `server/CLAUDE.md`: `src/interiors/` na lista de pastas e as rotas de `/v1/editor/interiors` na linha do `src/editor/`. `client/CLAUDE.md`: um item **Interiores** (a tela `interior`, o `InteriorView`, o `InteriorRoute`, o `ActionScreens`, o modo Interiores do F2 em `tools/interior_editor/` e a regra do bloqueio), no estilo dos outros itens. `CLAUDE.md`: uma frase "Depois, a `interiors` (concluída): ..." no fim do escopo.
- [x] **Passo 2:** a suíte inteira do servidor (`npm run lint`, `npm run typecheck`, `npm test`, `npm run test:e2e`) e `--headless --path client --quit-after 30`. Esperado: passa, menos as 2 falhas do `seed.e2e`.
- [x] **Passo 3:** o status das 3 fases, do README e das duas tabelas vira concluída, com "(falta o dono conferir no F5)" enquanto os critérios do F5 da 02 e da 03 estiverem abertos. Commit da fase, só quando o dono pedir: `feat: o modo Interiores do F2 e a sala na peça (interiors 03)`.

# Editor de roupas (F6) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Uma janela de desenvolvimento (F6) que edita pixel a pixel as folhas de adulto do Domador e salva cada peça, sem o `make_wardrobe.gd` apagar a edição.

**Architecture:** A folha aberta é um `WardrobeSheet` (RefCounted: a `Image`, o desfazer por pincelada e o salvar), sem nó, para ser conferido sem janela. Três `Control`s desenham a partir dela (o quadro ampliado, as miniaturas e a prévia animada), e o `WardrobeEditor` (uma `Window` nativa como o `ContentViewer`) liga tudo, lista as peças pelo catálogo e escreve o `hand_drawn.json`, que o `make_wardrobe.gd` passa a ler.

**Tech Stack:** Godot 4.7, GDScript tipado.

**Spec:** [05-wardrobe-editor.md](05-wardrobe-editor.md)

## Global Constraints

- Textos em pt-BR; poucos comentários, só o porquê (memória do dono).
- O editor só existe com `OS.has_feature("editor")`; nenhuma tela do jogo depende de `tools/`.
- Só as folhas de adulto; nunca escrever em `child/`.
- Células de 32×32 (`SheetSprite.CELL_SIZE`), 5 linhas; Parado 4 colunas, Correndo 6.
- Cores-chave (230,230,230), (180,180,180), (130,130,130), (80,80,80) e o contorno `#2f2522`.
- Sem cor fixa em cena ou script de UI: cores de `UiPalette` (as das folhas e da grade de pixels são dados da arte, ficam como constantes do editor).
- Folhas lidas por `Image.load_from_file(ProjectSettings.globalize_path(path))`, nunca `load()`.
- Conferência por cena temporária em `client/zz_tmp_check`, apagada no fim (memória `reference-godot-headless-check`).

## Review Focus

- Salvar uma folha cujo PNG o Godot ainda não reimportou: a prévia e o quadro devem mostrar o que foi salvo (leitura pelo arquivo, não pelo cache de recursos).
- Peça sem uma das folhas (sem `run.png`, ou só `_back`): a lista de folhas mostra só as que existem, sem erro.
- Pincelada que sai do quadro arrastando: os pixels fora da célula de 32×32 não mudam (nem a célula vizinha).
- Trocar de peça com mudança não salva: perguntar antes, e "Cancelar" mantém a peça aberta com as mudanças.
- `hand_drawn.json` ausente ou mal formado: o `make_wardrobe.gd` trata como lista vazia e avisa, sem parar.

---

### Task 1: A lista `hand_drawn.json`

**Files:**
- Create: `client/assets/tamer/hand_drawn.json`
- Modify: `client/assets/tamer/make_wardrobe.gd` (a const `HAND_DRAWN` e o `_init`)

**Interfaces:**
- Produces: o arquivo `{"bodies": [], "parts": ["pants"]}`; `static func hand_drawn() -> Dictionary` em `make_wardrobe.gd` devolvendo `{"bodies": Array[String], "parts": Array[String]}` (lista vazia se o arquivo faltar ou não for JSON, com `push_warning`).

- [x] **Step 1:** Criar o JSON com a Calça.
- [x] **Step 2:** Trocar a const pela leitura: o `_init` pula as peças de `parts` (adulto e criança) e os corpos de `bodies` (o `male`/`female` e, se o adulto estiver na lista, não mexe na criança dele).
- [x] **Step 3:** Conferir: anotar o md5 de `parts/pants/run.png` e de `bodies/male/run.png`, pôr `"male"` em `bodies`, rodar `godot --headless -s res://assets/tamer/make_wardrobe.gd`. Esperado: "guarda-roupa gerado" e os dois md5 iguais; tirar `"male"` de novo.

### Task 2: `WardrobeSheet`

**Files:**
- Create: `client/tools/wardrobe_editor/wardrobe_sheet.gd`
- Test: `client/zz_tmp_check/sheet_check.gd` + `.tscn` (temporários)

**Interfaces:**
- Produces: `class_name WardrobeSheet extends RefCounted`
  - `static func open(path: String) -> WardrobeSheet` (null se o arquivo não existe)
  - `var path: String`, `var image: Image`, `var dirty: bool`
  - `func columns() -> int`, `func cell_rect(column: int, row: int) -> Rect2i`
  - `func pixel(column: int, row: int, at: Vector2i) -> Color`
  - `func begin_stroke() -> void`, `func paint(column: int, row: int, at: Vector2i, color: Color) -> bool` (false fora da célula ou sem mudança), `func end_stroke() -> void`
  - `func undo() -> bool`, `func redo() -> bool` (até `MAX_UNDO := 100` pinceladas)
  - `func colors() -> Array[Color]`: as 4 chaves, o contorno e as outras cores opacas da folha, sem repetir, nessa ordem
  - `func save() -> Error` (grava o PNG e zera `dirty`)
  - `signal changed`

- [x] **Step 1: A conferência.** A cena copia `parts/shorts/idle.png` para `user://check_idle.png`, abre, confere `columns() == 4`, pinta (0,0,(5,5)) de contorno numa pincelada, confere o pixel, `undo()` volta ao valor de antes, `redo()` reaplica, `paint` em (40,5) devolve false, `save()` e reabre: o pixel salvo está lá; `colors()` começa pelas 4 chaves e o contorno. Imprime "OK sheet" ou o primeiro erro.
- [x] **Step 2:** Rodar `godot --headless --path client res://zz_tmp_check/sheet_check.tscn`. Esperado: falha (classe não existe).
- [x] **Step 3:** Implementar. O desfazer guarda, por pincelada, um `Dictionary` de pixel absoluto → `[antes, depois]`.
- [x] **Step 4:** Rodar de novo. Esperado: "OK sheet".

### Task 3: O quadro, as miniaturas e a prévia

**Files:**
- Create: `client/tools/wardrobe_editor/wardrobe_canvas.gd`, `wardrobe_frames.gd`, `wardrobe_preview.gd`

**Interfaces:**
- Consumes: `WardrobeSheet` (Task 2).
- Produces:
  - `class_name WardrobeCanvas extends Control`: `var sheet: WardrobeSheet`, `var guide: WardrobeSheet` (o corpo, ou null), `var cell := Vector2i.ZERO` (coluna, linha), `var tool: int` (`PENCIL`, `ERASER`, `PICKER`), `var color: Color`, `var show_body := true`, `var show_previous := true`; `signal picked(color: Color)`. Desenha em `_draw` com `draw_texture_rect_region` na escala inteira que cabe (8 a 20), a grade de pixels e as guias a 35% e 25%; o mouse pinta por `begin_stroke`/`paint`/`end_stroke`, o botão direito apaga.
  - `class_name WardrobeFrames extends Control`: `var sheet: WardrobeSheet`, `var cell: Vector2i`; `signal cell_chosen(cell: Vector2i)`; as miniaturas a 2× com o nome da linha à esquerda e a escolhida contornada.
  - `class_name WardrobePreview extends Control`: `func show_sheets(body: WardrobeSheet, part: WardrobeSheet, row: int, seconds: float, palette_id: int, body_palette_id: int) -> void`; anima as colunas da linha com `ImageTexture` das imagens (atualizado no `changed`) e o `TamerSprite.palette_material`.

- [x] **Step 1:** Implementar os três, redesenhando no `sheet.changed`.
- [x] **Step 2:** Conferir que compilam: na cena temporária, `load(path).can_instantiate()` para cada um. Esperado: true nos três.

### Task 4: A janela, o F6 e o salvar

**Files:**
- Create: `client/tools/wardrobe_editor/wardrobe_editor.gd`
- Modify: `client/screens/main/main.gd` (o F6, como o `_toggle_content_viewer`)
- Test: `client/zz_tmp_check/editor_check.gd` + `.tscn` (temporários)

**Interfaces:**
- Consumes: Tasks 1 a 3; `GameData.get_rows("body_types" | "appearance_parts" | "appearance_slots" | "palettes")`.
- Produces: `class_name WardrobeEditor extends Window`; `func entries() -> Array[Dictionary]` (`{"label", "folder", "kind": "body"|"part", "slug", "palette_kind"}`, corpos de adulto primeiro e as peças pela ordem do lugar); `func open_entry(index: int) -> void`; `func save() -> void`.

- [x] **Step 1: A conferência.** A cena carrega o catálogo como o `main` (espera `GameData.load_catalog()`), cria o `WardrobeEditor`, confere que `entries()` tem `male`, `female` e `pants` e que nenhum aponta para `child/`. Imprime "OK editor".
- [x] **Step 2:** Rodar. Esperado: falha (classe não existe).
- [x] **Step 3:** Implementar a janela (1280×720, `force_native`, ao lado do jogo como o `ContentViewer`): coluna de peças com Parado/Correndo e Frente/Atrás/Curta (só as folhas que existem), ferramentas e cores, o quadro, a prévia com a escolha de paleta e de corpo guia, as miniaturas, Desfazer/Refazer/Salvar e a mensagem. Atalhos: Ctrl+Z, Ctrl+Y, Ctrl+S, setas, B (Lápis), E (Borracha), I (Conta-gotas). O salvar grava as folhas `dirty` da entrada e o slug no `hand_drawn.json` (sem repetir); trocar ou fechar com mudança abre um `ConfirmationDialog` com Salvar, Descartar e Cancelar.
- [x] **Step 4:** Rodar. Esperado: "OK editor". Rodar também `godot --headless --path client --quit-after 60` sem "SCRIPT ERROR".
- [x] **Step 5:** Apagar `client/zz_tmp_check`.

### Task 5: Documentação

**Files:**
- Modify: `.specs/tamer-looks/05-wardrobe-editor.md` (status e caixas), `.specs/tamer-looks/README.md` (fase 5), `client/CLAUDE.md` (o F6 ao lado do F1 e do F2), `CLAUDE.md` (a frase da `tamer-looks`).

- [x] **Step 1:** Atualizar os 4 arquivos.
- [ ] **Step 2:** Mostrar ao dono e esperar a conferência no F6 antes do commit.

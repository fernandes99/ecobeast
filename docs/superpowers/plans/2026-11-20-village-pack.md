# village-pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** As casas (em tamanhos e 8 cores), os objetos e as cercas do tileset Village do Fantasy Dreamland Reborn viram peças soltas e paredes das ilhas.

**Architecture:** Scripts Python (Pillow) em `client/assets/props` e `client/assets/walls` montam a arte a partir de `FDR_Village.png`, sem pixel novo além da troca de cor. O catálogo ganha os tipos por migrações SQL à mão (`prop_types`, `prop_type_blocks`, `prop_type_lights`, `wall_types`), aplicadas com `prisma migrate deploy`. O cliente só ganha entradas em `HexMapView.PROP_SMOKE` e `HexWalls` (`FLAT_GAP`, `STEEP`); o editor lista os tipos novos sozinho.

**Tech Stack:** Python 3 + Pillow, Godot 4.7 (GDScript), PostgreSQL via Prisma.

**Spec:** `.specs/village-pack/` (README, 01-village-houses, 02-village-objects, 03-village-fences)

## Global Constraints

- Fonte: `C:\Users\ferna\Downloads\textures-png\Assets\ElvGames\Fantasy Dreamland Reborn\Tilesets\Village\Sprites\FDR_Village.png` (512×512, tiles 16×16). Lida só como argumento, scripts rodam com `python -I` de dentro da pasta deles.
- Tipos de peça a partir do 102 (casas primeiro, objetos depois); paredes 5 e 6. Ids nunca renumerados.
- Slugs `village_<nome>`; nomes em pt-BR, sem vocabulário do Pokémon.
- Cores das casas: 1 vermelho, 2 azul, 3 verde, 4 telha de madeira (reboco mais branco), 5 ardósia, 6 roxo, 7 verde-água, 8 laranja; 1, 2 e 5 são os telhados do pacote.
- Peça: PNG em `client/assets/props/<slug>/<variante>.png`, pé no meio da borda de baixo; luzes com `x = coluna − largura // 2`, `y = linha − altura`.
- Migração: SQL à mão em `server/prisma/migrations/<data>_<nome>/migration.sql` com `setval` depois de cada INSERT, aplicada por `npx prisma migrate deploy` (nunca `migrate dev`). `seed-data/` não é editada (como a `portal_altar`).
- Código sem comentários por padrão. O commit não inclui os arquivos da `board-size` que já estão modificados no working tree.

## Review Focus

- Casa espelhada (M no editor): a fumaça e as luzes caem na chaminé e nas janelas do outro lado — conferir na prévia espelhada que o script grava.
- Telhado azul (cor 2) e ardósia (5) não viram janela no `find_lights.py`; comparar o JSON novo com o antigo e só os tipos novos mudam.
- Peça grande com bloqueio: o retângulo fica rente à base, sem bloquear o hexágono da frente (o servidor bloqueia o hexágono cujo centro fica a até 8 px da linha).
- O `make_walls.py` refeito grava as 3 folhas antigas idênticas byte a byte.
- Variantes pequenas (flor, broto) com menos de 8 px ainda aparecem e não somem no recorte.

---

### Task 1: A prévia das casas

**Files:**
- Create: `client/assets/props/make_village_houses.py`
- Output (scratchpad, não versionado): `village_preview.png`

**Interfaces:**
- Produces: `FORMS: dict[str, Form]` (os 7 formatos da tabela do RF-02, na ordem), `build(sheet, form, roof_color) -> Image`, `recolor(image, rule) -> Image`, `COLORS` (8 regras), e o CLI `make_village_houses.py <FDR_Village.png> [--preview <png>]`.

- [ ] **Step 1:** Mapear na folha, por recortes ampliados, as caixas em pixels de: os 3 telhados por cor (casa larga, larga de alas compridas, casinha), os corpos de parede (bl), a frente de frontão com janela, a porta fechada no batente, a janela de vidro, a chaminé. Guardar como constantes `(x, y, w, h)` no script.
- [ ] **Step 2:** Implementar `build` colando, na ordem, corpo → porta/janelas → chaminé → telhado, e as alas esticadas repetindo a faixa de colunas do meio da ala; recortar por `getbbox()`.
- [ ] **Step 3:** `--preview`: os 7 formatos na cor 1 e um espelhado, sobre grama (o tile de grama da própria folha, repetido), o Domador (`client/assets/tamer` corpo idle, primeiro quadro) ao lado de cada um, o nome embaixo; ampliado 3× com NEAREST.
- [ ] **Step 4:** Rodar e olhar a imagem. Esperado: nenhum buraco de alfa entre telhado e corpo, porta no meio do frontão, telhado cobrindo o topo da chaminé.
- [ ] **Step 5:** Mandar a prévia ao dono (SendUserFile) e anotar na spec 01 (tabela de Decisões do README) os formatos escolhidos e os ids.

### Task 2: As casas escolhidas no jogo

**Files:**
- Modify: `client/assets/props/make_village_houses.py` (gravação das pastas)
- Create: `client/assets/props/village_<formato>/1.png`…`8.png`, `smoke.png`
- Create: `server/prisma/migrations/20270111000000_village_houses/migration.sql`
- Modify: `client/ui/components/hex_map_view.gd` (`PROP_SMOKE`), `client/assets/props/find_lights.py` (`TYPES`), `client/assets/props/LUZES.md`, `client/assets/props/CREDITOS.md`

**Interfaces:**
- Consumes: Task 1 (`FORMS` filtrado pelos escolhidos).
- Produces: tipos 102.. com 8 variantes; o script imprime `slug WxH`, o canto da fumaça e a caixa da base `(x0, y0, x1, y1)` relativa ao pé.

- [ ] **Step 1:** Gravar as 8 cores de cada formato escolhido; `recolor` por grupos HSV como no `make_timber_house.py` (telhado vermelho repintado nas cores 3, 4, 6, 7, 8; cores 2 e 5 vêm dos telhados do pacote; reboco só na 4).
- [ ] **Step 2:** Rodar `python -I find_lights.py > /tmp/new.json` com os tipos em `TYPES`; `diff` contra `server/prisma/seed-data/prop_type_lights.json`: só linhas dos tipos novos aparecem, e uma por janela de vidro.
- [ ] **Step 3:** Escrever a migração: `prop_types` (id, slug, name, 8), `prop_type_blocks` (variante 0, fechado, retângulo da base menos 2 px de cada lado, do pé a −14), `prop_type_lights` (as linhas do passo 2, ids depois do 152).
- [ ] **Step 4:** `cd server && npx prisma migrate deploy`. Esperado: "1 migration applied".
- [ ] **Step 5:** `PROP_SMOKE` com os cantos impressos (`size` 48, 6 quadros, 6 fps); `LUZES.md` e `CREDITOS.md` com o pacote.
- [ ] **Step 6:** `C:\Godot\<console> --headless --path client --quit-after 60` sem erro de script; abrir uma cena temporária em `client/zz_tmp_check` que monta um `HexMapView` com uma casa de cada, espelhada e não, e salva um PNG; olhar; apagar a pasta.

### Task 3: Os objetos

**Files:**
- Create: `client/assets/props/make_village_objects.py`, `client/assets/props/village_<objeto>/<n>.png`
- Create: `server/prisma/migrations/20270111000001_village_objects/migration.sql`
- Modify: `find_lights.py` (`TYPES`, `LAMPS`), `LUZES.md`, `CREDITOS.md`

**Interfaces:**
- Consumes: o último id da Task 2.
- Produces: os 17 tipos do RF-02 da spec 02, na ordem da tabela, com as variantes na ordem da coluna; o script imprime a caixa da base dos que bloqueiam.

- [ ] **Step 1:** Tabela `OBJECTS = [(slug, nome, [variante: [(x, y, w, h, dx, dy), ...]])]` com os retângulos da folha (a placa de loja e a estátua da fonte coladas por cima do braço e da fonte grande).
- [ ] **Step 2:** Gravar, recortar por `getbbox()` e gerar uma folha de conferência no scratchpad com todas as variantes numeradas; olhar (nenhum vizinho cortado junto, nenhuma variante vazia).
- [ ] **Step 3:** `LAMPS` das lanternas (raio 18; amarela `ffd890`, roxa com a cor média do vidro) e diff do JSON como na Task 2.
- [ ] **Step 4:** Migração: os 17 tipos, os bloqueios (variante 0 quando todas bloqueiam; senão a variante da tabela) e as luzes; `migrate deploy`.
- [ ] **Step 5:** Godot headless sem erro.

### Task 4: As cercas

**Files:**
- Modify: `client/assets/walls/make_walls.py`, `client/ui/components/hex_walls.gd`, `client/assets/walls/CREDITOS.md`
- Create: `client/assets/walls/village_fence.png`, `village_wall.png`
- Create: `server/prisma/migrations/20270111000002_village_fences/migration.sql`

- [ ] **Step 1:** Copiar as 3 folhas atuais para o scratchpad (para o teste byte a byte).
- [ ] **Step 2:** `make_walls.py` com o terceiro argumento de folha (sheet 2) e as entradas `village_fence` e `village_wall` em `WALLS` (poste, travessa deitada, vista de cima como retângulo da folha).
- [ ] **Step 3:** Rodar e `cmp` das 3 folhas antigas: idênticas.
- [ ] **Step 4:** `HexWalls.FLAT_GAP`/`STEEP` dos dois tipos; migração `wall_types` (5, `village_fence`, "Cerca da vila", true), (6, `village_wall`, "Muro da vila", true); `migrate deploy`.
- [ ] **Step 5:** Cena temporária desenhando as duas paredes em 0°, 30°, 60° e 90°; olhar; apagar.

### Task 5: Fechar

- [ ] **Step 1:** `cd server && npm test` passa; Godot headless sem erro.
- [ ] **Step 2:** Status das fases no README da iniciativa, `.specs/README.md`, `.specs/roadmap.md`, o parágrafo no `CLAUDE.md` e no `client/CLAUDE.md`.
- [ ] **Step 3:** Commit só dos arquivos da village-pack (`git add` por caminho), `feat: ... (village-pack 01 a 03)`.

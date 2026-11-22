# Vulcão, fase 1 (a arte e a lava) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** O chão do Vulcão, a Lava rasa e a funda (que se mexem e brilham à noite), os arremates e as decorações, desenhados por código, aprovados pelo dono numa prévia e virados peças soltas no F2.

**Architecture:** Um `make_volcano.py` no molde do `make_glacier.py` grava as superfícies, as linhas das folhas e a prévia. No cliente, a lava é um terceiro tipo de hexágono, ao lado da terra e da água: ela bloqueia o andar, recebe o arremate da terra como a água recebe a espuma, corre num código novo do `hex_grounds.gdshader` e, à noite, escapa do filtro por uma chave de cor e solta luz pelas bordas, por uma lista como a dos vagalumes.

**Tech Stack:** Python 3 + Pillow + numpy (arte), Godot 4.7 GDScript e shaders, SQL de migration do Prisma.

**Spec:** `.specs/volcano/01-volcano-art.md` (e o `README.md` da iniciativa)

## Global Constraints

- Tudo desenhado por código, sem arte de terceiros. Nada do vocabulário do Pokémon.
- Os arquivos do jogo só são gravados depois que o dono aprova a prévia (RF-02).
- Rodar o `make_volcano.py` duas vezes dá os mesmos arquivos, e ele só regrava as linhas dele.
- Pixel art em pixels inteiros, inclusive no movimento da lava.
- Código sem comentário por padrão; só o porquê que evita bug, em uma linha.
- Cores do minimapa: `volcano` `#3b3433`, `lshallow` `#ff8a1e`, `ldeep` `#c2361a`.
- Os ids das peças começam no 177, e a categoria é a próxima livre, conferidos no banco antes da migration.
- Um commit só no fim da fase (`feat: ... (volcano 01)`), com `git add` e `git commit` juntos, porque a pasta é compartilhada com outras sessões.

## Review Focus

- **Peças e roupas acendendo à noite:** a chave de cor da lava não pode pegar telhado vermelho, roupa laranja do Domador nem flor. A Task 4 tem uma varredura das folhas de arte que falha se um pixel de fora da lava cair na chave.
- **Lava ao lado de água:** a lava e a água não trocam arremate nem viram cachoeira uma sobre a outra. A cena da Task 2 põe um hexágono de lava encostado na Água rasa.
- **Ponte, trilha ou ponta de parede na lava:** o F2 não pode aceitar ponta de ponte na lava (`bridge_end_ok`), e o chão pintado (`_add_grounds`) não cobre a lava. Isso é conferido na Task 2.
- **Lava num degrau:** se a lava ficar acima de um vizinho, a lateral é de rocha (`cliff`), sem cachoeira. A cena da Task 2 tem um hexágono de lava no 6 ao lado de um de terra no 4.
- **Noite com muita lava na tela:** o brilho das bordas se limita a `MAX_LAVA_GLOWS` pontos, os mais perto do Domador. A Task 4 confere que a lista passa desse limite sem erro.

---

### Task 1: O `make_volcano.py` e a prévia

**Files:**
- Create: `client/assets/terrain/make_volcano.py`

**Interfaces:**
- Produces: as linhas novas das folhas. `transitions.png`: linha 10 `volcano` e linha 11 `lava_crust` (a borda de crosta escura que a lava recebe da terra). `drips.png`: linha 7 `volcano`. `decorations.png`: linhas 72 a 78, na ordem `basalt_pebbles`, `lava_crack`, `fumarole`, `burnt_tree`, `ash_patch`, `obsidian`, `lava_crust`. Superfícies `surfaces/volcano.png`, `surfaces/lshallow.png` e `surfaces/ldeep.png`, com 512 px e sem emenda.
- Produces: a chave de cor da lava, `HOT_MIN_RED = 0.9` e `HOT_MAX_BLUE = 0.06` (em 0 a 1). Todo pixel da lava rasa, dos veios da funda, do fundo da `lava_crack` e das frestas da `lava_crust` cai na chave. A rocha, a cinza, a obsidiana e a fumaça ficam fora dela.

- [ ] **Step 1:** Escrever o `make_volcano.py` no molde do `make_glacier.py`: as mesmas importações (`make_desert_snow as art`, `make_nature as nature`) e o `FreeCell` para as cores com alfa. A borda da Vulcão e a crosta saem da linha da Pedra recolorida, como a Geleira fez. As cores e os desenhos seguem a tabela e o RF-01 da spec.
- [ ] **Step 2:** Escrever o `--preview <arquivo>` com os 5 quadros do RF-02, ampliados 3 vezes. A noite é simulada multiplicando pelo ambiente `(0.42, 0.48, 0.72)` da meia-noite (`DayLightLayer.KEYFRAMES`), menos os pixels na chave de cor, mais um halo laranja fraco em volta da lava.
- [ ] **Step 3:** Rodar `python -I client/assets/terrain/make_volcano.py --preview <scratchpad>/volcano_preview.png` duas vezes e conferir que os dois PNGs são iguais byte a byte.
- [ ] **Step 4:** Mandar a prévia ao dono (SendUserFile) e **parar até ele aprovar**. Os ajustes que ele pedir voltam ao Step 1.
- [ ] **Step 5:** Depois da aprovação, rodar sem `--preview` e conferir (por um diff das imagens) que só as linhas e as superfícies novas mudaram nas folhas.

### Task 2: O Vulcão e a lava no mapa

**Files:**
- Modify: `client/domain/models/hex_tile.gd`, `client/ui/components/hex_transitions.gd`, `client/ui/components/hex_map_view.gd`, `client/ui/components/minimap_palette.gd`, `client/ui/components/minimap_image.gd`, `client/ui/components/hex_decorations.gd`, `client/tools/map_editor/island_draft.gd`
- Test: uma cena temporária em `client/zz_tmp_check/`, apagada no fim

**Interfaces:**
- Produces: `HexTile.LAVA_BIOMES: Array[String] = ["lshallow", "ldeep"]`, `HexTile.is_lava() -> bool` e `blocks_walking()`, que passa a ser `is_water() or is_lava()`. O `is_water()` não muda.

- [ ] **Step 1:** Escrever a cena temporária: um mapa com `volcano` (nos níveis 4 e 6), `lshallow` e `ldeep` no 6, ao lado de `temperate`, `boreal`, `mountain` e de um hexágono `wshallow`. Ela confere, sem janela (ver a memória do headless), que:
  - `blocks_walking()` é verdadeiro na lava e `is_water()` falso;
  - `HexTransitions.transitions_of` de um hexágono de lava ao lado de terra dá a linha `lava_crust`, e ao lado da `wshallow` não dá nada;
  - `HexMapView.face_texture("lshallow")` é `"cliff"`;
  - `HexDecorations` sorteia só os tipos da receita `volcano` num hexágono de Vulcão e só `lava_crust` na `lshallow`.

  Rodar e ver falhar.
- [ ] **Step 2:** Implementar:
  - **`HexTile`:** como no Interfaces.
  - **`HexTransitions`:** `volcano` no fim de `SURFACE_ORDER` (ela avança sobre todos os vizinhos de terra), `MATERIAL_ROWS` com `"volcano": 10` e `"lava_crust": 11`, e `DRIP_ROWS` com `"volcano": 7`. No `transitions_of`, o material é `FOAM` na água, `"lava_crust"` na lava e `neighbor.biome` na terra. A lava, como a água, fica fora de `SURFACE_ORDER`. Entre a lava e a água não há arremate: o vizinho que não está em `SURFACE_ORDER` não conta.
  - **`HexMapView`:** `volcano` em `CLIFF_BIOMES`, e o `face_texture` dá `"cliff"` para a lava. O `_tint`, o `_add_grounds` e o `_add_lips` pulam a lava como pulam a água.
  - **O minimapa:** as cores do Global Constraints no `minimap_palette.gd`. No `minimap_image.gd`, a lava não conta como água aberta.
  - **`HexDecorations`:** os tipos em `KIND_ROWS` (72 a 78) e em `KIND_RADIUS` (basalto 7, rachadura 9, fumarola 7, árvore queimada 9, cinza 8, obsidiana 6, crosta 9, a revisar com a prévia), nenhum em `KIND_SWAY`. As receitas `volcano` e `lshallow` usam as densidades aprovadas na prévia.
  - **`island_draft.gd`:** o `bridge_end_ok` usa `not tile.blocks_walking()`.
- [ ] **Step 3:** Procurar os outros usos de `is_water()` e de `WATER_BIOMES` no cliente (`grep -rn`, fora do `android/`). Onde o sentido é "dá para andar ou pôr coisa", trocar por `blocks_walking()`. Onde é "desenha como água", deixar como está.
- [ ] **Step 4:** Rodar a cena e ver passar. Depois rodar `godot --headless --path client --quit-after 60` e conferir que não há erro de script.

### Task 3: A lava se mexendo

**Files:**
- Modify: `client/ui/components/hex_map_view.gd` (`_add_surface`, as constantes de código), `client/ui/components/hex_grounds.gdshader`

**Interfaces:**
- Produces: `HexMapView.LAVA_CODE := 10.0`. O CUSTOM0 da superfície de lava é `[0, 0, deep, LAVA_CODE]`, com `deep` 1 na `ldeep`.

- [ ] **Step 1:** No `_add_surface`, dar à lava o CUSTOM0 do Interfaces.
- [ ] **Step 2:** No shader, o ramo `code == 10`:
  - a mesma deriva em degraus da água (`WATER_STEPS`), com `LAVA_DRIFT = vec2(7.0, 4.0) * 512.0 / 3600.0` e a funda na metade disso;
  - a onda com `WAVE_LENGTH` 24 e metade da velocidade da água;
  - um pulso de brilho de `±6%` no RGB, com o período fechando volta inteira em 3.600 s, para não dar salto quando o `map_time` volta a zero.

  Tudo em pixels inteiros (`floor`/`round`), sem espuma.
- [ ] **Step 3:** Na cena da Task 2, avançar o `map_time` e conferir, por um print da textura do viewport, que os pixels da lava mudam e os da terra não. Rodar o `godot --headless` de novo.

### Task 4: A lava acesa à noite

**Files:**
- Modify: `client/ui/components/day_light.gdshader`, `client/ui/components/day_light_layer.gd`, `client/ui/components/hex_map_view.gd`, `client/screens/exploration/exploration_screen.gd`
- Create: `client/assets/terrain/check_hot_key.py` (a varredura)

**Interfaces:**
- Consumes: a chave de cor da Task 1.
- Produces:
  - `DayLightLayer.MAX_LAVA_GLOWS := 48` e `DayLightLayer.set_lava_glows(points: PackedVector2Array) -> void`, no molde do `set_swarms`;
  - `HexMapView.lava_glows() -> PackedVector2Array` e `HexMapView.lava_glow_tiles() -> Array[Vector2i]`: os centros, já subidos pela altura, dos hexágonos de lava com pelo menos um vizinho que não é lava. São os mesmos pares da `firefly_swarms` e da `firefly_swarm_tiles`.

- [ ] **Step 1:** Escrever o `check_hot_key.py`: ele varre todo PNG em `client/assets/` (fora das superfícies de lava, das linhas 72 a 78 das decorações e das linhas da Task 1) e a paleta do Domador (`server/prisma/seed-data/palettes.json`). Ele falha listando cada arquivo com um pixel opaco onde `r ≥ 0.9` e `b ≤ 0.06`. Rodar e anotar o resultado. Se aparecer um arquivo de fora da lava, apertar a chave (subir o `r` mínimo ou baixar o `b` máximo), ajustar as cores do `make_volcano.py` à chave nova e rodar de novo até passar.
- [ ] **Step 2:** No `day_light.gdshader`:
  - o pixel na chave (`color.r >= HOT_MIN_RED && color.b <= HOT_MAX_BLUE`, conferido antes da troca de saturação) não é escurecido: `light` vale 1 para ele;
  - um laço sobre `lava_glows[MAX_LAVA_GLOWS]` soma uma luz `LAVA_LIGHT = vec3(1.0, 0.55, 0.2)`, de raio 32 px da arte e força 0,6 vezes o `light_strength`, como os enxames.

  De dia (`light_strength` 0), nada muda.
- [ ] **Step 3:** Fazer o `HexMapView.lava_glows`, o `lava_glow_tiles` e o `set_lava_glows`. No `exploration_screen.gd`, guardar as listas ao lado de `_swarms` e, no `_refresh_lights`, passar só as visíveis e descobertas, das mais perto do Domador para as mais longe, cortadas em `MAX_LAVA_GLOWS`.
- [ ] **Step 4:** Na cena temporária, chamar `set_lava_glows` com 100 pontos e conferir que não dá erro e que o shader recebe 48. Rodar o `godot --headless`.

### Task 5: As peças no F2

**Files:**
- Create: `server/prisma/migrations/<data>_volcano_props/migration.sql`
- Modify: `client/tools/map_editor/vegetation_panel.gd`

- [ ] **Step 1:** Conferir no banco o maior id de `prop_categories` e de `prop_types`, por um script temporário em `server/zz_tmp/` com o Prisma, apagado depois. Os tipos começam no 177 se o maior for 176.
- [ ] **Step 2:** Escrever a migration no molde da `20270201000000_glacier_props`: a categoria `volcano` "Vulcão" e os 7 tipos, com os nomes da tabela da spec e 4 variantes, e as duas `setval`. Aplicar com `npx prisma migrate deploy` (ver a memória das migrations).
- [ ] **Step 3:** No `vegetation_panel.gd`, criar `VOLCANO_KINDS` com os 7 slugs e o grupo `{"name": "Vulcão", "kinds": VOLCANO_KINDS, "per_tile": 1.0, "off": ["lava_crust"]}` no fim de `GROUPS`.
- [ ] **Step 4:** Rodar `npm run lint`, `npm run typecheck` e `npm test` em `server/`, e o `godot --headless --path client --quit-after 60`. Conferir que o `GET /v1/catalog` serve a categoria e os 7 tipos.
- [ ] **Step 5:** Apagar `client/zz_tmp_check/`, marcar as tarefas e os critérios na spec da fase (deixando o F2 para o dono conferir) e fazer o commit:

```bash
git add client/assets/terrain client/domain/models/hex_tile.gd client/ui/components client/screens/exploration/exploration_screen.gd client/tools/map_editor server/prisma/migrations .specs/volcano docs/superpowers/plans/2026-11-21-volcano-art.md && git commit -m "feat: o chão do Vulcão e a lava rasa e funda, se mexendo e acesa à noite, com as decorações e as peças no F2 (volcano 01)"
```

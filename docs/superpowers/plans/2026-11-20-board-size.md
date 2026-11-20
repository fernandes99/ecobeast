# board-size Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** O tabuleiro da luta com o tamanho sorteado pelo servidor por formato, os lados começando perto do meio, e no jogo a abertura da câmera pelos dois times e o zoom pelo tamanho do hexágono.

**Architecture:** O servidor sorteia o `BoardSize` no `BoardBattleService.begin` e o passa ao `startBoardBattle`; `board.ts` monta o tabuleiro, as zonas e as casas de começo pelo tamanho. O jogo já desenha qualquer lista de hexágonos; a tela da luta ganha o `_hex_zoom()` e a abertura, tocada no `_show_turn` da primeira resposta.

**Tech Stack:** NestJS + Vitest (servidor), Godot 4.7 GDScript tipado (cliente).

**Spec:** `.specs/board-size/README.md`, `01-board-size-rules.md`, `02-board-size-screen.md`

## Global Constraints

- Textos em pt-BR; nada de nomes do Pokémon.
- O servidor é a autoridade: o tamanho sai do servidor; o jogo só exibe.
- Regras em `server/src/domain/` como funções puras, com testes de unidade.
- GDScript tipado; sem cor fixa; poucos comentários (só o porquê).
- `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` antes do commit; commit só quando o dono pedir.
- Faixas: 1 → 4 a 10, 2 → 6 a 12, 3 → 8 a 16; fora da tabela, a do 1. Padrão `{ columns: 3, rows: 6 }`.
- Abertura: 2 s no time do jogador, 0,8 s de passagem, 2 s no inimigo, 0,8 s até quem faz a primeira vez.

## Review Focus

1. Um 2×2 com o jogador tendo só 1 Ecobeast de pé: o tamanho é o do formato pedido (2), e as casas de começo do jogador são as de 1 vaga.
2. O tabuleiro de 4 linhas: a zona do inimigo só tem a linha 0, e a do jogador as linhas 3 (sem linha de baixo) — nenhuma casa fora do tabuleiro.
3. A troca e a entrada depois de um desmaio num campo grande: `entryCellsFor` devolve casas da zona nova.
4. A abertura numa luta em que o inimigo já termina a luta na primeira resposta (sem `vez_started`): a câmera termina no time do jogador e o fim toca normal.
5. Um toque durante a abertura não chega ao `BoardView` como `cell_tapped`.

---

### Task 1: O tamanho no motor (`board.ts`)

**Files:**
- Modify: `server/src/domain/board/types.ts` (`BoardSize`, `Board.size`)
- Modify: `server/src/domain/board/board.ts`
- Modify: `server/src/domain/board/board-engine.ts` (`BoardOptions.size`)
- Modify: os testes que importam `BOARD_COLUMNS`/`BOARD_ROWS` (`board.spec.ts`) e os que chamam `startCell` com 3 argumentos
- Test: `server/src/domain/board/board.spec.ts`

**Interfaces:**
- Produces: `interface BoardSize { columns: number; rows: number }`; `Board.size: BoardSize`; `DEFAULT_BOARD_SIZE`; `BOARD_SIZE_RANGES: Record<number, { min: number; max: number }>`; `rollBoardSize(slots: number, random: Random): BoardSize`; `makeBoard(size?: BoardSize): Board`; `startCell(side, position, slots, board: Board): HexCoord`; `BoardOptions.size?: BoardSize`.

- [ ] **Step 1: Testes que falham** em `board.spec.ts` (`describe('tamanho sorteado (board-size/01)')`):
  - `rollBoardSize` com um `Random` que devolve sempre 0 dá `{4,4}`, `{6,6}`, `{8,8}`; com sempre 0,999 dá `{10,10}`, `{12,12}`, `{16,16}`; formato 7 usa a faixa do 1; com uma sequência `[0, 0.999]` dá colunas no mínimo e linhas no máximo.
  - `makeBoard({columns: 7, rows: 5})` tem 35 casas; `size` igual; zona do inimigo = linhas 0 (frente) e nenhuma acima → só linha 0 (`floor((5-4)/2) = 0`); zona do jogador = linhas 3 e 4; cada zona com a linha da frente primeiro.
  - `makeBoard()` igual ao de hoje (18 casas, zonas nas linhas 0–1 e 4–5, inimigo começando por `at(0, 1)`).
  - Num 10 × 10: com 1, 2 e 3 vagas, as casas de começo estão nas linhas 3 e 6, nas colunas `[4]`, `[3, 5]` e `[2, 4, 6]`, e `hexDistance` entre as casas de vaga 0 dos dois lados num 1×1 é 3.
  - No padrão 3 × 6, as casas de começo de 1, 2 e 3 vagas são as de hoje (colunas `[1]`, `[0, 2]`, `[0, 1, 2]`).
- [ ] **Step 2:** `npm test -- src/domain/board/board.spec.ts` → FAIL (símbolos inexistentes).
- [ ] **Step 3:** Implementar em `board.ts` conforme os RF-01 a RF-06 da 01: `rollBoardSize` sorteia `min + floor(random() * (max - min + 1))`, colunas antes das linhas; linhas de frente `e = floor((rows - 4) / 2)` e `p = e + 3`; zonas com a linha de trás só se existir; colunas em volta de `c = floor((columns - 1) / 2)`, as de 3 vagas com passo 2 se `c - 2 >= 0` e `c + 2 < columns`, senão passo 1. Tirar `BOARD_COLUMNS`, `BOARD_ROWS`, `ZONE_ROWS` e `START_COLUMNS`. `startCell` lê `board.size`. No `startBoardBattle`, `board: makeBoard(size)` e `startCell(side, spot.position, count, state.board)`.
- [ ] **Step 4:** `npm test` → todos passam; `npm run lint && npm run typecheck` sem erro.

### Task 2: O sorteio na luta, a vista e os documentos

**Files:**
- Modify: `server/src/board-battle/board-battle.service.ts` (`begin`)
- Modify: `server/src/board-battle/board-battle.mapper.ts` e `board-battle.dto.ts` (`BoardDto.columns`, `rows`)
- Modify: `server/test/board-battle.e2e-spec.ts` (linhas 206 e 524)
- Modify: `.specs/board-battle/architecture.md` (seção Tabuleiro), `GDD.md` se fixar 3 × 6, `.specs/board-size/01-board-size-rules.md` (status e resultado)

**Interfaces:**
- Consumes: `rollBoardSize`, `BoardOptions.size`, `Board.size` (Task 1).
- Produces: a vista `battle.board` com `columns` e `rows`.

- [ ] **Step 1:** Mudar o e2e: `cells` com tamanho `columns * rows`, `columns` e `rows` entre 4 e 10 (1×1); rodar `npm run test:e2e -- test/board-battle.e2e-spec.ts` → FAIL (sem `columns`).
- [ ] **Step 2:** No `begin`, `size: rollBoardSize(slots, secureRandom)`; o mapper manda `{ cells, zones, columns: size.columns, rows: size.rows }`; o DTO documenta os dois (`example: 7`). Ajustar o `board-battle.mapper.spec.ts`.
- [ ] **Step 3:** `npm run lint && npm run typecheck && npm test && npm run test:e2e` → só os e2e que já falhavam antes (seed species_skills e species_day_phases, timeout do team) falham.
- [ ] **Step 4:** Documentos: o `architecture.md` descreve as faixas, as linhas de frente e as zonas pelo tamanho; a 01 vira "concluída" com o resultado.

### Task 3: O zoom e a abertura no jogo

**Files:**
- Modify: `client/screens/board_battle/board_battle_screen.gd`
- Modify: `client/domain/models/board_battle_view.gd` só se precisar de `columns`/`rows` (não precisa: o tamanho vem das casas)
- Test: cena temporária `client/zz_tmp_check/check.tscn` + `check.gd`, apagada depois

**Interfaces:**
- Produces: `_hex_zoom() -> float`, `_max_zoom() -> float`, `_play_opening(first_key: String) -> void`, `_team_center(prefix: String) -> Vector2`, constantes `OPENING_HOLD := 2.0`, `OPENING_PAN := 0.8`, flag `_opening_pending: bool`, `_opening_skip: bool`.

- [ ] **Step 1: Cena de teste que falha:** monta a tela com tabuleiros de 4 × 4, 3 × 6 e 16 × 16 (casas por `cellAt` igual ao servidor) numa `BoardArea` de 720 × 900 e confere: no 3 × 6, `_hex_zoom()` = 1 e `_max_zoom()` = 2,5; no 16 × 16, `_board.scale.x` no `_hex_zoom()` igual ao do 3 × 6 no zoom 1 (±0,01) e no máximo igual ao do 3 × 6 no máximo; na abertura do 16 × 16 com `OPENING_HOLD`/`OPENING_PAN` zerados no teste, o `_view_focus` passa pelo centro do time do jogador, pelo do inimigo e termina na casa de `first_key`; com `_opening_skip` ligado, ele vai direto à casa de `first_key`. Rodar `godot --headless --path client res://zz_tmp_check/check.tscn` → falha (funções inexistentes).
- [ ] **Step 2:** Implementar o RF-01 e o RF-02 (o `_zoom_around` prende em `[1, _max_zoom()]`).
- [ ] **Step 3:** Implementar a abertura: `_begin` liga `_opening_pending`; o `_show_turn`, antes de tocar o primeiro `vez_started` com a flag ligada (ou no fim, sem nenhum), desliga a flag e `await _play_opening(key)`. `_play_opening` põe `_zoom = _hex_zoom()`, foca o centro do jogador, espera, faz o `Tween` do `_view_focus` (chamando `_fit_board` no `tween_method`), espera e passa à casa de `first_key` (vazio → centro do jogador). Um toque, a pinça ou a roda durante ela ligam `_opening_skip`, que mata o tween e a espera e vai ao fim; o `taps_blocked` também devolve verdadeiro com a abertura tocando. Os tempos são `var`s de instância lidos das constantes, para o teste zerá-los.
- [ ] **Step 4:** Rodar a cena → 0 falhas; apagar `client/zz_tmp_check`; `godot --headless -d --path client --quit-after 240` sem erro de script.
- [ ] **Step 5:** Documentos: a 02 com os critérios e o resultado; `client/CLAUDE.md` (Zoom de Explorar, a frase da luta) e o `CLAUDE.md` da raiz (a frase da board-size); o roadmap e o README da board-size com o status.

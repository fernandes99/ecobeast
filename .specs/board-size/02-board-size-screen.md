# 02. A abertura da câmera e a pinça num campo de qualquer tamanho

- **Status:** concluída (falta o dono conferir no celular)
- **Depende de:** [01](01-board-size-rules.md) e [camera-zoom/02](../camera-zoom/02-battle-zoom.md) (a pinça e o arrasto na luta)

## Contexto

O `board_battle_screen.gd` escala o tabuleiro pelo `_base_ratio()`: o menor entre caber na `BoardArea` e a largura de referência de 624 px (`REFERENCE_BOARD_WIDTH`). O zoom vai de 1 a 2,5 vezes isso (`MAX_ZOOM`), em volta do ponto do tabuleiro no centro da área (`_view_focus`), preso nas bordas pelo `_fit_board`. No 3 × 6 de hoje, quem manda é a largura de referência, e o hexágono fica perto do tamanho cheio. Num 16 × 16, o campo inteiro cabe só com o hexágono em menos da metade disso.

Ao abrir, o `_begin` monta o tabuleiro, põe o zoom 1, revela a tela (`BattleIntro.reveal()`) e toca a primeira resposta (`_show_turn`).

## Escopo

- A abertura da câmera: o time do jogador, o inimigo e quem faz a primeira vez.
- O zoom da luta, de 1 ao máximo pelo tamanho do hexágono.

## Fora do escopo

- A câmera seguir o Ecobeast da vez depois da abertura.
- Mudar a pinça, a roda ou o arrasto de hoje.

## Requisitos

**O zoom**

- **RF-01:** O zoom 1 continua sendo o campo inteiro (`_base_ratio()`). O zoom do hexágono de hoje, `_hex_zoom()`, é o que deixa o hexágono do tamanho que ele teria num 3 × 6 inteiro na mesma área: a escala do 3 × 6 (`_fit_ratio(BoardView.rect_size(3, 6))`, com as mesmas regras do `_base_ratio()`) dividida pelo `_base_ratio()`, e nunca menos que 1. No 3 × 6, ele é 1. (A primeira versão usava só a largura de referência; a cena de teste mostrou que o 3 × 6 pode ficar limitado pela altura da área.)
- **RF-02:** O zoom máximo é `MAX_ZOOM × _hex_zoom()`. No 3 × 6, isso dá 2,5, como hoje.

**A abertura**

- **RF-03:** Na primeira resposta, os Ecobeasts entram no tabuleiro pelos eventos `creature_entered`. Logo antes do primeiro `vez_started` (ou no fim da resposta, sem nenhum), a câmera faz, no zoom `_hex_zoom()`:
  1. abre centrada no meio dos Ecobeasts do jogador e fica 2 s;
  2. desliza em 0,8 s até o meio dos inimigos e fica 2 s;
  3. desliza em 0,8 s até quem faz a primeira vez.

  O meio de um time é a média dos centros (`BoardView.cell_center`) das casas dos Ecobeasts dele no tabuleiro, e o `_fit_board` prende a vista nas bordas: num campo que cabe inteiro, a câmera não se mexe (_a revisar_ os tempos das passagens).
- **RF-04:** Quem faz a primeira vez é o Ecobeast do primeiro `vez_started` da primeira resposta: um inimigo, quando ele joga antes, ou o Ecobeast da vez do jogador. Sem nenhum `vez_started`, a câmera termina no meio do time do jogador.
- **RF-05:** Um toque ou um clique na tela durante a abertura pula para o fim dela: a câmera vai direto ao passo 3, sem esperar, e o toque não escolhe hexágono nem ação. A pinça e a roda também pulam a abertura antes de mudar o zoom.
- **RF-06:** Depois da abertura, a luta segue como hoje, com a vista onde a abertura parou. A próxima luta começa de novo pela abertura.

**A pinça**

- **RF-07:** A pinça, a roda e o arrasto continuam com as regras da [camera-zoom/02](../camera-zoom/02-battle-zoom.md), entre o zoom 1 e o máximo do RF-02: o ponto entre os dedos fica parado, a vista não sai das bordas e o arrasto só vale com o campo maior que a área.
- **RF-08:** O chão em volta (`cover_screen`) cobre a tela em qualquer zoom, também num 16 × 16. O limite de hoje (`MAX_COVER_CELLS`, 64 hexágonos por eixo) basta.

## Critérios de aceite

- [x] Um teste sem janela abre a luta com tabuleiros de 4 × 4, 3 × 6 e 16 × 16 e confere: o `_hex_zoom()` e o zoom máximo do 3 × 6 iguais aos de hoje (1 e 2,5), e o hexágono do 16 × 16 no zoom da abertura e no máximo do mesmo tamanho que o do 3 × 6.
- [x] O mesmo teste confere a abertura num 16 × 16: a vista começa no time do jogador, passa ao inimigo e termina em quem faz a primeira vez, e um toque no meio a leva direto ao fim.
- [x] O jogo sem janela abre sem erros de script.
- [ ] No celular, o dono abre lutas de 1×1, 2×2 e 3×3, vê campos de tamanhos diferentes e a abertura da câmera, aproxima com a pinça e arrasta a vista.

## Desenho técnico

- `client/screens/board_battle/board_battle_screen.gd`:
  - `_hex_zoom()` e o zoom máximo do RF-02 no `_zoom_around`;
  - a abertura (`_play_opening(first_key)`), chamada pelo `_show_turn` da primeira resposta antes do primeiro `vez_started`, com um `Tween` do `_view_focus` (e do `_zoom`) que chama o `_fit_board` a cada quadro, e um aviso de pular que o `_input` da pinça e do toque usa;
  - o toque da abertura não chega ao `BoardView` (o `taps_blocked` também olha a abertura).

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

Manual (F5): lutas de 1×1, 2×2 e 3×3, com a abertura, a pinça e o arrasto.

## Resultado da verificação

Em 2026-11-20, uma cena temporária sem janela (já apagada) abriu a tela da luta, sem o servidor de luta, com tabuleiros de 3 × 6, 4 × 4, 7 × 5 e 16 × 16, e conferiu:

- o `BoardView.rect_size` igual ao tamanho que o `set_board` mede;
- no 3 × 6, o `_hex_zoom()` 1 e o zoom máximo 2,5; no 16 × 16, a escala no `_hex_zoom()` e no máximo igual à do 3 × 6 no zoom 1 e no máximo;
- a abertura num 16 × 16 com dois Ecobeasts de cada lado: no zoom do hexágono, ela começa no meio do time do jogador, passa ao do inimigo e termina na casa de quem faz a primeira vez, com o toque no tabuleiro bloqueado;
- um clique no meio pula direto para o fim, e sem `vez_started` ela termina no time do jogador.
- os Ecobeasts entram já no zoom do hexágono, com a vista no meio das casas de largada do jogador (`_frame_cells`), sem o campo inteiro antes da abertura; a revisão final achou o salto e o corrigiu.

A primeira versão do `_hex_zoom()` falhou nessa cena (1,36 no 3 × 6), porque media só a largura de referência, e passou com a escala do 3 × 6 na mesma área. O jogo sem janela abriu sem erro de script. Não foram vistos com janela: a abertura, a pinça e o arrasto no celular.

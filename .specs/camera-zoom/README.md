# camera-zoom

O jogador aproxima e afasta a câmera com dois dedos (pinça), ao explorar e na luta, entre um zoom mínimo e um máximo. Hoje o zoom é fixo: o mapa de Explorar mostra cada pixel da arte com 2 pixels da tela lógica, e o tabuleiro da luta se ajusta inteiro à área livre.

A ideia é do dono, em 2026-11-14, para melhorar a usabilidade no celular.

## Contexto

- **Explorar** (`res://screens/exploration/exploration_screen.gd`): o mapa é um `HexMapView` (`res://ui/components/hex_map_view.gd`) na escala de `art_scale()`, que arredonda `ART_SCALE` (2) para pixels inteiros da janela; o Domador fica no centro da tela e a câmera anda com ele (`_move_map`). O toque no mapa (`_on_map_input`) leva o Domador até o ponto, e um movimento de até 24 px (`MAX_TAP_TRAVEL`) ainda conta como toque. Os Ecobeasts existem como nós até 16 hexágonos do Domador (`CREATURE_RADIUS`). O botão de debug "mapa inteiro" (`_toggle_whole_map`) continua como está.
- **A luta** (`res://screens/board_battle/board_battle_screen.gd`): o `BoardView` (`board_view.gd`) fica numa camada atrás da interface (`BoardLayer`), e o `_fit_board` o escala para caber na `BoardArea` (no máximo 624 px de largura de referência) e o centraliza. O `cover_screen` cobre o resto da tela com chão. O toque num hexágono (`_on_gui_input`) emite `cell_tapped`.
- **O toque no celular:** o projeto emula o mouse a partir do toque (o padrão do Godot), então o primeiro dedo chega como `InputEventMouseButton`. Os dois dedos chegam como `InputEventScreenTouch` e `InputEventScreenDrag`, cada um com o seu `index`.

## Objetivos

1. A pinça aproxima e afasta a câmera ao explorar, sem borrar a pixel art.
2. A pinça aproxima e afasta o tabuleiro da luta, com a vista arrastável quando aproximada.
3. Tirar os dedos depois de uma pinça nunca vale como toque.

## Decisões

Do dono, em 2026-11-14:

| Decisão | Motivo |
| --- | --- |
| O zoom é por pinça, ao explorar e na luta, com limite mínimo e máximo | Usabilidade no celular |

Do planejamento, aprovadas pelo dono em 2026-11-14:

| Decisão | Motivo |
| --- | --- |
| Ao explorar, o zoom anda em degraus inteiros: 1, 2, 3 ou 4 pixels da tela lógica por pixel da arte, arredondados para pixels inteiros da janela como hoje. O 2 é o de hoje | Um zoom quebrado deixa os pixels da arte de tamanhos diferentes |
| Ao explorar, a câmera continua presa no Domador; a pinça só muda o tamanho | Um dedo já serve para andar |
| O último zoom de Explorar fica guardado no aparelho | Quem prefere ver mais longe não precisa repetir a pinça |
| Na luta, o mínimo é o tabuleiro inteiro (o ajuste de hoje) e o máximo é 2,5 vezes isso, com o zoom contínuo | Afastar mais não mostraria nada; o tabuleiro já é escalado em tamanhos quebrados |
| Na luta, a pinça aproxima em volta do ponto entre os dedos, e um dedo arrasta a vista quando aproximada, sem sair das bordas do tabuleiro | Ver de perto qualquer parte do tabuleiro |
| Cada luta começa com o tabuleiro inteiro | Ver as posições antes da primeira vez |
| No PC, a roda do mouse faz o mesmo que a pinça | Testar sem celular |

## Fora do escopo

- Botões de + e − na tela.
- Arrastar a vista de Explorar para longe do Domador.
- A câmera da luta seguindo o Ecobeast da vez.
- O editor de ilhas (F2), que já tem o seu zoom.
- O servidor: nada muda nele.

## Pré-requisitos

- [wild-battle](../wild-battle/) e [islands](../islands/): o mapa de Explorar.
- [board-battle](../board-battle/): o tabuleiro da luta.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-explore-zoom](01-explore-zoom.md) | A pinça ao explorar, em degraus, guardada no aparelho | concluída (falta o dono conferir no celular) |
| 2 | [02-battle-zoom](02-battle-zoom.md) | A pinça e o arrasto no tabuleiro da luta | concluída (falta o dono conferir no celular) |
| 3 | [03-smooth-explore-zoom](03-smooth-explore-zoom.md) | O zoom de Explorar suave: a pinça segue os dedos entre 1 e 4 e assenta no degrau inteiro mais perto ao soltar | concluída (falta o dono conferir no celular) |

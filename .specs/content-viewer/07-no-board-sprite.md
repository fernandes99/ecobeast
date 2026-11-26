# 07. Sem o board.png

- **Status:** concluída (falta o dono ver)
- **Depende de:** [board-battle/06](../board-battle/06-board-look.md), que criou o `board.png`, e [board-battle/07](../board-battle/07-battle-sprites.md), que pôs as folhas da luta na frente dele

## Contexto

Em 2026-11-26, o dono pediu: "Eu não vou mais precisar da imagem de board, pode remover em tudo que é usado/chamado direta ou indiretamente, nenhum Ecobeast vai ter a imagem de board mais". O `board.png` era o `front.png` reduzido a pixel art pelo `res://tools/board_sprites.gd`, mostrado 2× maior na luta por quem não tinha as folhas de `battle/`. Só 11 Ecobeasts ainda o tinham (as linhas do Ruvo, da Nilu, do Clod e do Hushling).

## Escopo

- A luta: quem não tem as folhas de `battle/` passa direto para o `front.png` reduzido, que já era o caminho de quem não tinha o `board.png`.
- O visualizador (F1): sai a linha "board" dos arquivos do Ecobeast e o cartão "Com board" do Resumo; a conta passa de "/7" para "/6".
- Saem os 11 `board.png` (com os `.import`) e o gerador `res://tools/board_sprites.gd`.

## Fora do escopo

- As folhas da luta e do mapa, o `front.png` e o `face.png`.
- As specs de fases concluídas, que contam o que foi feito na época.

## Requisitos

- **RF-01:** `BoardView` perde `BOARD_SPRITE_PATH` e `SPRITE_SCALE`; no `_dress`, sem as folhas, só o `front.png` reduzido, com o respirar e o pulinho de antes.
- **RF-02:** `ContentFiles.creature_files` devolve front, as 4 folhas e o call; o Resumo conta as folhas e o call pelas posições novas.
- **RF-03:** Nenhum arquivo do jogo, das ferramentas ou das skills procura um `board.png`.

## Critérios de aceite

- [x] Nenhum `board.png` nem `board_sprites.gd` no repositório, e nenhum código que os chame.
- [x] O jogo abre sem erro de script, e o visualizador monta a aba Ecobeasts e o Resumo.
- [ ] O dono vê no F1 que a linha "board" e o "Com board" sumiram, e numa luta que um Ecobeast sem folhas de `battle/` aparece pelo `front.png`.

## Verificação

Em 2026-11-26, a busca por `board.png`, `BOARD_SPRITE_PATH` e `board_sprites` no `client/` e nas skills não achou nada, e o jogo sem janela abriu sem erro de script; uma cena sem janela carregou o `BoardView`, montou o visualizador e deu os 6 arquivos do Ruvo, todos presentes. Dos 11 que tinham o `board.png`, o Ruvo, o Ruvak e o Ruvaroth têm as folhas de `battle/`; as linhas da Nilu, do Clod e do Hushling (8) não têm e passam a aparecer na luta pelo `front.png` reduzido, até ganharem as folhas.

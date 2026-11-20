# creature-fronts

Os Ecobeasts ganham a arte nova do dono no `front.png`, em pixel art com contorno escuro, num acabamento mais próximo do resto do jogo, e o `board.png` refeito dela.

## Contexto

Em 2026-11-20, o dono pediu uma imagem com os `front.png` de cada linha e, depois, mandou as linhas redesenhadas, com as mesmas formas e cores. A primeira pedida foi "Atualize as artes deles agora, vou te mandar as artes atualziadas", para o Ruvo e a Nilu. Depois, "Atualize deles, porém só use a versão 2 e 3 que foi gerado no hushling, descarte a primeira", para o Clod e o Hushling.

## Decisões

| Decisão | Quem | Motivo |
| --- | --- | --- |
| Os `front.png` vêm das imagens do dono | Dono | Pedido |
| Na imagem do Hushling, a primeira das três formas sai; a segunda é o Hushling e a terceira o Echofrost | Dono | "só use a versão 2 e 3 [...] descarte a primeira" |
| O `board.png` é refeito do `front.png` novo | Claude | Ele sai do `front.png` pelo `board_sprites.gd` ([board-battle/06](../board-battle/06-board-look.md)) |
| As folhas de Explorar (`explore/`) e da luta (`battle/`) não mudam | Claude | São desenhadas à parte, pela skill `creature-sprites`; refazer é outro pedido |
| O alfa do `front.png` sai só 0 ou 255 | Claude | O webp com perda deixava o miolo em 252, um pouco transparente |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-ruvo-nilu-fronts](01-ruvo-nilu-fronts.md) | Os `front.png` e `board.png` novos das linhas do Ruvo e da Nilu | concluída (falta o dono conferir no jogo) |
| 2 | [02-clod-hushling-fronts](02-clod-hushling-fronts.md) | Os `front.png` e `board.png` novos das linhas do Clod e do Hushling | concluída (falta o dono conferir no jogo) |

# 06. A ponte na diagonal

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [05-width-and-cuts](05-width-and-cuts.md)

## Contexto

O dono mandou a imagem de uma ponte de madeira na diagonal: "Tem como melhorar a ponte em diagonal? Ela tá ficando com um aspecto muito puxado".

A ponte inclinada era a vista de cima (ou de lado) assentada no trecho, sem girar:
- as pranchas continuavam na horizontal da tela;
- a largura medida de lado ficava a mesma, então, na diagonal, a ponte ficava mais fina e os corrimãos viravam uma linha.

Na mesma imagem, a grama do bioma nascia por cima da cabeceira.

## Requisitos

- **RF-01:** Entre 20° e 70° da horizontal da tela (`HexBridges.DIAGONAL_MIN` e `DIAGONAL_MAX`), a ponte é a vista de cima girada no ângulo dela. Cada pixel acha a posição ao longo da ponte (a linha da arte) e a distância até o eixo (a coluna, com o miolo repetido pela largura). As pranchas atravessam a ponte, e a largura de verdade é a escolhida.
- **RF-02:** O corrimão do lado de baixo da tela vai numa imagem à parte e entra na ordem 6 px mais abaixo, na frente de quem anda no piso, como na ponte deitada.
- **RF-03:** O piso do andar na diagonal é o da ponte em pé: metade da largura menos o corrimão e 1 px.
- **RF-04:** As decorações naturais do bioma com o ponto a até metade da largura mais 2 px do trecho de uma ponte não aparecem (`HexMapView._under_bridge`). As peças soltas postas pelo dono ficam.

## Critérios de aceite

- [x] Uma prévia desenhada pelo jogo compara, a 30°, 45° e 60°, a ponte de antes e a girada.
- [ ] No jogo (F5), a ponte na diagonal não fica puxada e a grama não nasce por cima dela.

## Desenho técnico

**Alterar:**
- `client/ui/components/hex_bridges.gd`: `_rotated`, `is_diagonal` e o `deck_reach`.
- `client/ui/components/hex_map_view.gd`: `_under_bridge` no sorteio das decorações e os hexágonos das pontas no `set_bridges`.

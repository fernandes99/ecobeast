# water-motion

A água das ilhas e do mapa de Explorar ganha movimento: a superfície da água rasa e da funda ondula devagar, e a lateral de um hexágono de água mais alto que o vizinho da frente vira uma cachoeira, com espuma no pé. Hoje a água é uma textura parada, e a lateral de um hexágono de água alto mostra o mesmo barranco de terra da grama.

A ideia é do dono, em 2026-11-14, vendo uma ilha com água no alto.

## Contexto

- **O desenho do terreno** é o `HexMapView` (`res://ui/components/hex_map_view.gd`), usado no jogo e no editor. Cada linha de hexágonos é um `HexRowView` com malhas; todas usam o mesmo shader, `hex_grounds.gdshader`, que só mexe nas malhas que chegam com um código no `CUSTOM0.w` (hoje o 3, o chão dos caminhos) e deixa as outras passarem direto.
- **A superfície** de cada bioma é uma textura de 512 × 512 (`assets/terrain/surfaces/<bioma>.png`), presa ao ponto do mapa e não ao hexágono, então os vizinhos de mesmo bioma formam uma superfície contínua ([wild-battle/04](../wild-battle/04-biome-surfaces.md)).
- **As laterais** só aparecem nas duas bordas da frente (`LOWER_NEIGHBORS`), com a altura da diferença para o vizinho ou, na borda do mapa, a altura do hexágono mais a base de 26 px (`SIDE_HEIGHT`). A textura é `side.png` (terra) ou `cliff.png` (pedra), por `face_texture(biome)`; a água usa a de terra ([terrain-height/02](../terrain-height/02-eleven-heights.md)).
- **A espuma da praia** já existe: a água ao lado da terra recebe uma faixa de espuma pelas transições (`HexTransitions`, material `foam`) ([wild-battle/09](../wild-battle/09-biome-transitions.md)). Ela continua igual.

## Objetivos

1. A superfície da água rasa e da funda se mexe, em todo mapa que usa o `HexMapView`.
2. Toda lateral de água vira cachoeira, caindo sobre água, sobre terra ou para fora do mapa.
3. O pé da cachoeira tem espuma, sobre água e sobre terra.
4. A espuma da praia fica mais sutil, mexendo, e não sobe mais nos campos mais altos da frente ([03](03-shore-foam.md)).

## Decisões

Do dono, em 2026-11-14:

| Decisão | Motivo |
| --- | --- |
| A lateral de um hexágono de água rasa ou funda, mais alto que o vizinho da frente, é uma cachoeira | Pedido do dono |
| A cachoeira cai também sobre a grama (qualquer bioma), com espuma no pé | Decisão do dono |
| Na borda do mapa, a lateral da água também é cachoeira, caindo para fora | Decisão do dono. Consequência: a água que chega na borda do mapa, inclusive o mar em volta das ilhas e dos mapas sorteados, ganha uma cachoeira de 26 px ou mais nas bordas da frente |

Do planejamento (a revisar pelo dono ao ver no jogo):

| Decisão | Motivo |
| --- | --- |
| O movimento sai do shader do terreno, não de quadros de textura | Não pede arte nova para a superfície, e a textura continua se emendando sozinha |
| O movimento anda em pixels inteiros, em passos de tempo (perto de 6 por segundo na superfície), como animação feita à mão | Uma textura deslizando em frações de pixel borra o pixel art |
| Uma textura de cachoeira só, para a água rasa e a funda | A queda é água agitada; a cor da funda não aparece na espuma |
| Na borda do mapa, a cachoeira não tem espuma: os últimos pixels somem num pontilhado | Não há onde a água bater |
| Os números (velocidade, tamanho da onda, largura da espuma) são de partida e se acertam olhando | A aparência só se julga na tela |

## Fora do escopo

- A água do tabuleiro da luta (`BoardView`, que não desenha água).
- Rios que correm numa direção, e a superfície no alto da cachoeira puxando para a beira.
- Som de água.
- Qualquer mudança no servidor, no rascunho ou no editor além do que ele já desenha pelo `HexMapView`.

## Pré-requisitos

- [terrain-height](../terrain-height/): água em qualquer altura.
- [free-trails/02](../free-trails/02-ground-mask.md): o código no `CUSTOM0.w` do shader do terreno.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-water-surface](01-water-surface.md) | A superfície da água rasa e da funda se mexendo | concluída |
| 2 | [02-waterfalls](02-waterfalls.md) | As cachoeiras, com a espuma no pé e a queda para fora do mapa | concluída |
| 3 | [03-shore-foam](03-shore-foam.md) | A espuma da praia sem subir nos campos mais altos da frente, mais sutil e animada | concluída |

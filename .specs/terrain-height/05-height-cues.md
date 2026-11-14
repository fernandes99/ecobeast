# 05. A leitura da altura

- **Status:** concluída (falta o dono ver no jogo e no editor)
- **Depende de:** [04-rounded-corners](04-rounded-corners.md)

## Contexto

Onde um platô termina sobre um chão do mesmo bioma, só os 2 lados da frente têm paredão. Atrás e nas laterais, a textura continua igual, e não dá para ver onde a altura muda. Nasceu de um teste, em 2026-11-14, e ficou.

## Requisitos

- **RF-01 (beirada):** no hexágono de terra, cada trecho da borda sem paredão à mostra (atrás e nas laterais, seguindo as pontas arredondadas) com o vizinho mais baixo, ou fora do mapa, ganha uma beirada clara de 2 px por dentro. A beirada é a textura do próprio chão clareada: o pixel de fora mais forte e o de dentro mais fraco.
- **RF-02 (sombra no pé):** no chão de baixo, junto ao pé do paredão de um vizinho de terra mais alto, entra uma sombra de 6 px: os 2 primeiros cheios e o resto sumindo em pontilhado. Não há sombra no pé de uma cachoeira.
- **RF-03 (tom por altura):** cada nível de terra abaixo do 5 fica 3% mais escuro, na superfície, no paredão, nos escorridos, nos arremates e no chão das trilhas. A água não muda.
- **RF-04:** é só o desenho. A grade, as regras e o servidor não mudam.
- **RF-05:** o menu Debug do mapa tem as chaves "Beirada", "Sombra no pé" e "Tom por altura" (`HexMapView.height_lips`, `foot_shadows` e `height_tint`, ligadas por padrão).

## Fora do escopo

- As decorações (árvores, tufos, rochas) e as peças soltas não escurecem com o tom.
- Não há chaves para elas no editor; ele usa o valor padrão.

## Resultado

- `HexMapView._add_lips` e `_add_foot_shadows` montam as faixas pelos trechos da borda (`_outline`, que usa o `HexRounding` com as pontas arredondadas), e `_tint` dá o tom. O shader `hex_grounds.gdshader` desenha a beirada no código 8 e a sombra no código 9 do `CUSTOM0.w`, com a distância até a borda no x.
- Os ajustes ficam em constantes: `LIP_WIDTH`, `SHADOW_WIDTH`, `TINT_STEP` e `TINT_TOP` no `HexMapView`, e `LIP_OUTER`, `LIP_INNER`, `SHADOW_ALPHA` e `SHADOW_SOLID` no shader.
- Conferido numa cena temporária com platôs de grama de alturas 3 e 5 sobre grama de altura 1. O tom começou em 3,5% por nível abaixo do 6 e passou a 3% abaixo do 5, para escurecer menos o chão comum.
- **Não conferido:** o jogo e o editor abertos.

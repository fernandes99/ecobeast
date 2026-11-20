# item-icons

Os ícones dos itens ganham um padrão de tamanho: os Tônicos e o Bálsamo Puro com a arte do pacote gratuito **Free Paint Pixel Art Icon Pack** da craftpix.net, e as 3 Esferas com a pixel art de 32×32 do dono, feita a partir do Gemini.

## Contexto

Em 2026-11-20, o dono pediu: "Quero modificar os ícones dos itens, eu quero trazer um padrão para eles de tamanho, qual você me sugere? Atualize o tonico leve e forte pelo icon1 e icon13 desse pacote [...] E o balsemo puro é o icon5".

Os 6 ícones de antes (`client/assets/items/<slug>.png`) eram pinturas de 256×256, cada uma ocupando a tela de um jeito (o Tônico Forte com 136 px de largura, o Bálsamo com 236), reduzidas pelo `ItemIcon` com filtro linear. Os do pacote são pixel art de 32×32.

## O padrão (proposto por Claude)

| Regra | Valor | Motivo |
| --- | --- | --- |
| Tela | 32×32 px, PNG com fundo transparente | O tamanho do pacote; dá detalhe para um frasco ou uma esfera sem virar ilustração |
| Estilo | Pixel art, sem suavização, contorno escuro de 1 px | Combina com o resto do jogo (mapa, Ecobeasts, construções) |
| Ocupação | O objeto entre 24 e 30 px de altura, centrado na largura, com 1 a 2 px livres embaixo | Itens de alturas parecidas pesam igual na lista |
| Na tela | Só em múltiplos inteiros de 32: 32, 64, 96 (o padrão do `ItemIcon`) ou 128, com o filtro mais próximo (`TEXTURE_FILTER_NEAREST`) | Pixel art em escala quebrada fica com pixels de tamanhos diferentes |

## Decisões

| Decisão | Quem | Motivo |
| --- | --- | --- |
| Tônico Leve = `Icon1`, Tônico Forte = `Icon13`, Bálsamo Puro = `Icon5` | Dono | Pedido |
| Os ícones do pacote entram sem edição | Claude | Já estão no padrão: 32×32, de 27 a 30 px de altura |
| O `ItemIcon` usa o filtro mais próximo nos ícones de até 64 px e o linear nos maiores | Claude | Um ícone grande que entrar fora do padrão não fica serrilhado |
| As Esferas são as de 32×32 do dono, só centradas, menores que os frascos | Dono | "esses aqui já tem um tamanho mais ideal" ([02](02-spheres.md)) |
| A tela de captura mostra a Esfera em 128 px (era 150), e a marca de capturado do Bestiário em 32 px (era 26) com o filtro mais próximo | Claude | Múltiplos inteiros de 32 |

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-tonics-balm](01-tonics-balm.md) | O padrão no `ItemIcon` e os ícones novos dos Tônicos e do Bálsamo Puro | concluída (falta o dono conferir) |
| 2 | [02-spheres](02-spheres.md) | As 3 Esferas em pixel art de 32×32 | concluída (falta o dono conferir) |

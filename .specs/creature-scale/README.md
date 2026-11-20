# creature-scale

Os Ecobeasts ficam maiores no mapa de Explorar. A altura das folhas passa a ser a de hoje mais 4 pixels, com um mínimo de 6 e um máximo de 32. A pixel art segue o acabamento dos animais do pacote Fantasy Dreamland Reborn. Esta iniciativa muda a regra da skill `creature-sprites` e redesenha as 16 folhas de Explorar que existem.

## Contexto

Hoje a altura de um Ecobeast no mapa segue a escala do Domador: 1,70 m são 25 pixels, então `pixels = height_m × 25 / 1,70` ([wild-battle/architecture.md](../wild-battle/architecture.md), skill `creature-sprites`). Isso deixa os filhotes minúsculos: a Nilu, o Puffcoo e o Hushling têm 4 pixels, e o Seedlet e o Tidebud têm 6. Nesse tamanho, só cabem uma mancha de cor e dois olhos.

Em 2026-11-20, o dono pediu: "eu quero aumentar o tamanho dos ecobeasts no explorar. [...] quero aumentar um pouco eles e ter um valor minimo e maximo de tamanho". Como referência, ele apontou os animais do pacote Fantasy Dreamland Reborn (`Animals/Chick_01.png` e `Chicken_01.png`, que estão no computador dele, fora do repositório): "quero um tamanho minimo parecido com eles e um pixel art parecido também". Medidos, o pintinho tem de 10 a 12 pixels de altura e a galinha de 12 a 14. Os dois usam de 8 a 13 cores, contorno escuro tingido pela cor do bicho e um sombreado simples.

Claude gerou duas prévias:

1. Uma escala de 12 a 30 pixels, que o dono achou grande demais.
2. A de hoje mais 4 pixels, que ele pediu assim: "de 4 fique 8, 6 fique 10, 7, fique 11 e assim por diante. O minimo seria de 6 para ecobeast que fiquem com 0,1m (futuros). Até no maximo 32". Depois, aprovou a escrita desta spec.

A segunda prévia está em `art-source/creature-scale/preview.png`. A Nilu, o Seedlet e o Ruvo foram desenhados de frente, à mão, em 8, 10 e 11 pixels, e as grades deles estão em `art-source/creature-scale/front_drafts.py`.

## A regra

```
pixels = arredondar(height_m × 25 / 1,70 + 4), no mínimo 6 e no máximo 32
```

| Ecobeast | Altura | Hoje | Novo |
| --- | --- | --- | --- |
| (futuros) | 0,1 m | 1 | 6 |
| Nilu, Puffcoo, Hushling | 0,3 m | 4 | 8 |
| Seedlet, Tidebud, Clod | 0,4 m | 6 | 10 |
| Ruvo | 0,5 m | 7 | 11 |
| Nilgar | 0,9 m | 13 | 17 |
| Ruvak, Grovequill, Crag | 1,0 m | 15 | 19 |
| Kelpcoil | 1,1 m | 16 | 20 |
| Nilgorr, Galecrest | 1,5 m | 22 | 26 |
| Ruvaroth, Ingot | 1,6 m | 24 | 28 |
| Echofrost | 1,7 m | 25 | 29 |
| Arbornix | 1,8 m | 26 | 30 |
| Tempestide | 2,0 m | 29 | 32 |

O Domador continua com 25 pixels. A regra chega ao máximo perto de 1,90 m, e daí para cima tudo tem 32 pixels, a altura da célula.

## Objetivos

1. A regra nova no `spritekit.py` e na conferência das folhas (`check_sheets.py`), com as alturas lidas do catálogo do servidor.
2. As regras de desenho da skill `creature-sprites` com o acabamento do pacote, em qualquer tamanho.
3. As 16 folhas de Explorar redesenhadas no tamanho novo, dos menores para os maiores.

## Anti-objetivos

- Mudar o tamanho do Domador, da célula de 32×32 ou da densidade de pixels do mapa. Nada é ampliado: cada folha é desenhada de novo, pixel a pixel.
- Mexer nas folhas da luta (`battle/`), no `board.png`, no `front.png` ou na altura do catálogo (`height_m`).

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| A altura de hoje mais 4 pixels | "de 4 fique 8, 6 fique 10, 7, fique 11 e assim por diante" |
| O mínimo de 6 pixels, para os Ecobeasts de 0,1 m que vierem | "O minimo seria de 6 para ecobeast que fiquem com 0,1m (futuros)" |
| O máximo de 32 pixels | "Até no maximo 32 de tamanho" |
| O acabamento dos animais do Fantasy Dreamland Reborn | "Olha o tamanho e a qualidade deles, [...] um pixel art parecido também" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os Ecobeasts da altura do Domador ficam mais altos que ele: o Ruvaroth (1,6 m) tem 28 pixels, e o Echofrost (1,7 m) tem 29 | A regra do dono soma 4 a todos. No mapa, a diferença de 3 ou 4 pixels se lê como "um bicho grande", e o Domador não muda |
| A largura também cabe nos 32 pixels: o Ruvaroth e o Nilgorr ficam mais compactos, com a cauda e as pinças mais perto do corpo | Crescendo na proporção, eles teriam 35 e 33 pixels de largura. Trocar a célula mudaria o `CreatureSprite`, o `NpcSprite` e todas as folhas |
| A conferência lê as alturas do catálogo do servidor (`GET /v1/catalog`), e não do `server/prisma/seed-data/species.json` | A carga inicial é uma foto antiga, que não tem o Seedlet, o Grovequill, o Arbornix nem os ids de 10 em diante. Hoje, as folhas deles não têm a altura conferida |
| Contorno tingido em qualquer tamanho, inclusive abaixo de 12 pixels | O pintinho tem contorno com 10 pixels, e a Nilu da prévia ficou legível com contorno em 8. A regra de hoje da skill tira o contorno até 12 pixels |
| Até 16 cores por folha, de preferência; a conferência continua barrando acima de 32 | O pacote usa de 8 a 13 cores. O limite de 32 já pega a folha que veio de uma imagem reduzida |
| Os pequenos são desenhados de novo, com o contorno automático do `spritekit`, e os médios e os grandes crescem pelo `stretched`, repetindo linhas do desenho de hoje, sem ficar mais largos | Os médios e os grandes já tinham o contorno e o sombreado pedidos e o desenho aprovado; o que faltava era a altura. Uma prévia antes e depois está em `art-source/creature-scale/before_after.png` |
| Três fases de redesenho, por tamanho | Os pequenos são os que mais mudam e os que o dono quer ver primeiro. Cada fase deixa o jogo inteiro funcionando, com tamanhos misturados até a última |
| O Clod, o Crag e o Ingot ficam de fora | Eles não têm folhas de Explorar. Quando ganharem, já nascem na regra nova |

## Fora do escopo

- Folhas novas para quem não tem: Clod, Crag e Ingot.
- As folhas da luta (`battle/`), que têm o tamanho próprio do tabuleiro ([board-battle/07](../board-battle/07-battle-sprites.md)).
- O tamanho do Domador e dos NPCs pessoas (`TamerSprite`).

## O que muda junto

- Os NPCs das ilhas com o sprite de um Ecobeast (`npcs.sprite`, [island-npcs](../island-npcs/architecture.md)), como o Puffcoo do campo em Liora, crescem com a folha da espécie. O toque neles usa a célula inteira (`NpcSprite.hits`), então nada muda no código.
- O spawn do menu Debug do mapa e o visualizador do F1 mostram as folhas novas sem mudar código.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-scale-rule](01-scale-rule.md) | A regra nova no `spritekit.py` e no `check_sheets.py`, as alturas lidas do catálogo, as regras de desenho da skill e os documentos | concluída (falta o dono conferir no jogo) |
| 2 | [02-small-sheets](02-small-sheets.md) | As folhas da Nilu, do Puffcoo, do Hushling, do Seedlet, do Tidebud e do Ruvo (de 8 a 11 pixels) | concluída (falta o dono conferir no jogo) |
| 3 | [03-medium-sheets](03-medium-sheets.md) | As folhas do Nilgar, do Ruvak, do Grovequill e do Kelpcoil (de 17 a 20 pixels) | concluída (falta o dono conferir no jogo) |
| 4 | [04-large-sheets](04-large-sheets.md) | As folhas do Nilgorr, do Galecrest, do Ruvaroth, do Echofrost, do Arbornix e do Tempestide (de 26 a 32 pixels) | concluída (falta o dono conferir no jogo) |

# 01. A arte, os tipos e as receitas

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [desert-snow/02](../desert-snow/02-biome-art.md)

## Contexto

`HexDecorations` sorteia as decorações de cada hexágono pela receita do bioma (`RECIPES`) e as desenha pela folha `assets/terrain/decorations/decorations.png`, de células de 48×64 com o pé em (24, 60) e 4 variantes por linha.

## Os tipos

| Linha | Slug | Nome | Raio | Vento (pixels, altura) |
| --- | --- | --- | --- | --- |
| 23 | `birch` | Bétula | 13 | 2, 36 |
| 24 | `oak` | Carvalho | 15 | 2, 36 |
| 25 | `fir` | Abeto | 10 | 2, 46 |
| 26 | `fallen_branch` | Galho caído | 7 | parado |
| 27 | `log` | Tronco caído | 11 | parado |
| 28 | `stump` | Toco | 7 | parado |
| 29 | `mushrooms` | Cogumelos | 4 | parado |
| 30 | `tall_grass` | Mato alto | 5 | 2, 14 |
| 31 | `wildflowers` | Flores do campo | 6 | 2, 10 |
| 32 | `clover` | Trevo | 5 | 1, 5 |
| 33 | `berry_bush` | Arbusto de frutinhas | 10 | 1, 13 |
| 34 | `thistle` | Cardo | 5 | 2, 14 |
| 35 | `dry_branch` | Galho seco | 7 | parado |
| 36 | `yellow_flowers` | Flores amarelas | 5 | 2, 10 |
| 37 | `slab` | Laje rachada | 11 | parado |
| 38 | `lichen_rock` | Pedra com líquen | 9 | parado |
| 39 | `tumbleweed` | Rolo seco | 7 | 1, 10 |
| 40 | `desert_flower` | Flor do deserto | 4 | 1, 8 |
| 41 | `bleached_branch` | Galho branco | 7 | parado |
| 42 | `dune_grass` | Capim de duna | 4 | 2, 10 |
| 43 | `frozen_branch` | Galho congelado | 7 | parado |
| 44 | `ice_shards` | Cristais de gelo | 7 | parado |
| 45 | `winter_berry` | Arbusto de inverno | 10 | 1, 13 |
| 46 | `snow_log` | Tronco com neve | 11 | parado |

## Requisitos

- **RF-01:** `assets/terrain/make_nature.py` (Python com Pillow) desenha as linhas 23 a 46 da folha, com 4 variantes cada, sem imagem de terceiros, com o contorno, a luz de cima à esquerda e a sombra (12, 26, 18, 72) das decorações de hoje. Rodar de novo regrava só essas linhas.
- **RF-02:** `HexDecorations` ganha os 24 tipos em `KIND_ROWS`, `KIND_RADIUS` e `KIND_SWAY`, como na tabela.
- **RF-03:** Cada receita ganha, no fim, as entradas abaixo (tipo, chance, mínimo, máximo):
  - Planície: `oak` 0,05 (1), `birch` 0,06 (1 a 2), `log` 0,05 (1), `stump` 0,05 (1), `fallen_branch` 0,12 (1), `wildflowers` 0,14 (1 a 2), `mushrooms` 0,06 (1 a 2), `tall_grass` 0,2 (1 a 2), `clover` 0,2 (1 a 2);
  - Boreal: `fir` 0,3 (1 a 2), `birch` 0,1 (1), `log` 0,1 (1), `stump` 0,08 (1), `berry_bush` 0,14 (1), `fallen_branch` 0,14 (1), `mushrooms` 0,2 (1 a 3);
  - Colina: `stump` 0,04 (1), `thistle` 0,18 (1 a 2), `dry_branch` 0,12 (1), `yellow_flowers` 0,16 (1 a 2);
  - Pedra: `slab` 0,14 (1), `lichen_rock` 0,16 (1);
  - Montanha: `slab` 0,1 (1), `dry_branch` 0,05 (1);
  - Deserto: `tumbleweed` 0,12 (1), `bleached_branch` 0,1 (1), `desert_flower` 0,12 (1 a 2), `dune_grass` 0,3 (1 a 3);
  - Neve: `snow_log` 0,08 (1), `winter_berry` 0,14 (1), `frozen_branch` 0,12 (1), `ice_shards` 0,1 (1).
- **RF-04:** No mapa, uma decoração sorteada a menos de `max(raio dela, raio da peça)` de uma peça solta do mesmo hexágono não é desenhada. O raio da peça é o de `VegetationPanel.radius_of`, que passa para `PropArt.radius`.
- **RF-05:** Na luta, os tipos baixos novos (`fallen_branch`, `dry_branch`, `bleached_branch`, `frozen_branch`, `mushrooms`, `clover`, `wildflowers`, `yellow_flowers`, `desert_flower`, `dune_grass`) entram em `LOW_DECORATIONS`. Nas trilhas, `clover` e `dune_grass` entram em `TRAIL_DECORATIONS`.

## Critérios de aceite

- [x] Para uma seed, as decorações de hoje de cada hexágono saem iguais às de antes, no mesmo ponto, variante e espelho.
- [x] Uma cena temporária mostra cada bioma com os tipos novos, e a captura é revisada.
- [x] As linhas 0 a 22 da folha ficam iguais, pixel a pixel, e rodar o script duas vezes dá o mesmo arquivo.
- [x] O jogo e o editor compilam sem erros de script e sem avisos novos.

## Tarefas

- [x] O script da arte e a folha.
- [x] `HexDecorations`, o filtro das peças e as listas da luta e das trilhas.

## Resultado da verificação

Em 2026-11-15:

- **A arte:** o script desenha cada tipo com formas de círculos (copas, arbustos), facetas (pedras), fios (capim, flores, cardo) e traços (galhos, rolo seco), com o contorno de 1 px, a luz de cima à esquerda com pontilhado e as marquinhas escuras das folhas, como as decorações de hoje. As 24 linhas foram ampliadas e revisadas, e a bétula, o carvalho, o abeto, o tronco, o toco, o trevo, o arbusto de frutinhas, o cardo e o rolo seco foram redesenhados depois da primeira olhada.
- **A folha:** as linhas 0 a 22 ficaram iguais, pixel a pixel, e rodar o script de novo deu o mesmo arquivo. A folha tem 192×3008.
- **O sorteio:** numa cena temporária, em 1.400 hexágonos dos 7 biomas, as decorações dadas pelo `HexDecorations` de antes (tirado do git) saíram iguais, no mesmo ponto, variante e espelho, e os tipos novos somaram 955 decorações, perto de 0,7 por hexágono.
- **O filtro das peças:** uma Árvore frondosa a 2 px de uma decoração a esconde, e a 40 px não.
- **Uma cena temporária com janela** (apagada) desenhou uma faixa de cada bioma, e a captura foi aberta e revisada.
- **O jogo e o editor** compilam sem erros de script, e o jogo sobe sem avisos novos; o único (`sign` em `hex_bridges.gd`) é da [bridges](../bridges/).
- **Não conferido:** o mapa sorteado, a ilha e a luta com o jogo aberto.

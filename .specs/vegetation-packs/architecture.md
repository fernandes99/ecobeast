# vegetation-packs: desenho compartilhado

## A arte

Cada variante é um PNG em `client/assets/props/<slug>/<variante>.png`, como as outras peças de arte própria ([free-props](../free-props/architecture.md)). O jogo desenha o PNG com o pé no meio da borda de baixo. Por isso, cada desenho do pacote é recortado assim:

- em cima e embaixo, até o primeiro pixel que não é transparente;
- dos lados, simétrico em volta do meio da imagem original, para o tronco continuar no meio.

O pé fica então no pé da sombra. Os créditos e a licença estão em `client/assets/props/CREDITOS.md`.

## Os tipos

Os ids continuam depois do Observatório (27). As variantes vão da maior para a menor, na ordem dos arquivos do pacote.

**Árvores** (`Trees_shadow`):

| id | slug | Nome | Variantes | Arquivos |
| --- | --- | --- | --- | --- |
| 28 | `leafy_tree` | Árvore frondosa | 3 | `Tree1` a `Tree3` |
| 29 | `moss_tree` | Árvore com musgo | 3 | `Moss_tree1` a `3` |
| 30 | `fruit_tree` | Árvore frutífera | 3 | `Fruit_tree1` a `3` |
| 31 | `blossom_tree` | Árvore florida | 3 | `Flower_tree1`, `Flower_tree2`, `Flower_tree2-1` |
| 32 | `autumn_tree` | Árvore de outono | 3 | `Autumn_tree1` a `3` |
| 33 | `dead_tree` | Árvore morta | 3 | `Burned_tree1` a `3` |
| 34 | `round_pine` | Pinheiro redondo | 3 | `Christmas_tree1` a `3` |
| 35 | `snowy_pine` | Pinheiro com neve | 3 | `Snow_christmass_tree1` a `3` |
| 36 | `snowy_tree` | Árvore com neve | 3 | `Snow_tree1` a `3` |
| 37 | `broadleaf_tree` | Árvore de folha larga | 3 | `Palm_tree1_1` a `1_3` |
| 38 | `palm_tree` | Palmeira | 3 | `Palm_tree2_1` a `2_3` |
| 39 | `stump_log` | Tocos e troncos | 7 | `Broken_tree1` a `7` (formatos, não tamanhos) |

**Arbustos** (`Assets_shadow`):

| id | slug | Nome | Variantes | Arquivos |
| --- | --- | --- | --- | --- |
| 40 | `autumn_bush` | Arbusto de outono | 3 | `Autumn_bush1` a `3` |
| 41 | `dry_twigs` | Galhos secos | 4 | `Burned_tree1`, `Burned_tree2`, `Broken_tree1`, `Broken_tree2` |
| 42 | `blue_flower_bush` | Arbusto de flores azuis | 3 | `Bush_blue_flowers1` a `3` |
| 43 | `orange_flower_bush` | Arbusto de flores laranja | 3 | `Bush_orange_flowers1` a `3` |
| 44 | `pink_bud_plant` | Planta de botão rosa | 3 | `Bush_pink_flowers1` a `3` |
| 45 | `red_bromeliad` | Bromélia vermelha | 3 | `Bush_red_flowers1` a `3` |
| 46 | `round_bush` | Arbusto redondo | 3 | `Bush_simple1_1` a `1_3` |
| 47 | `light_bush` | Arbusto claro | 3 | `Bush_simple2_1` a `2_3` |
| 48 | `barrel_cactus` | Cacto redondo | 3 | `Cactus1_1` a `1_3` |
| 49 | `arm_cactus` | Cacto de braços | 3 | `Cactus2_1` a `2_3` |
| 50 | `wild_fern` | Samambaia selvagem | 3 | `Fern1_1` a `1_3` |
| 51 | `star_fern` | Folhagem estrela | 3 | `Fern2_1` a `2_3` |
| 52 | `snowy_bush` | Arbusto com neve | 3 | `Snow_bush1` a `3` |

**Pedras** (`Objects_separately`, só os `RockN_K.png`, com sombra):

| id | slug | Nome | Variantes | Arquivos |
| --- | --- | --- | --- | --- |
| 53 | `sand_stone` | Pedra bege | 5 | `Rock1_1` a `1_5` |
| 54 | `rust_crystal` | Cristal ferrugem | 5 | `Rock2_1` a `2_5` |
| 55 | `ice_crystal` | Cristal de gelo | 5 | `Rock3_1` a `3_5` |
| 56 | `moss_stone` | Pedra de musgo | 5 | `Rock4_1` a `4_5` |
| 57 | `white_stone` | Pedra branca | 5 | `Rock5_1` a `5_5` |
| 58 | `slab_stone` | Pedra em lascas | 5 | `Rock6_1` a `6_5` |
| 59 | `clay_stone` | Pedra de barro | 5 | `Rock7_1` a `7_5` |
| 60 | `lava_stone` | Pedra de lava | 5 | `Rock8_1` a `8_5` |

## Os grupos do pincel

Os 7 grupos de hoje ([vegetation-brush](../vegetation-brush/architecture.md#os-grupos)) não mudam. Depois deles, entram:

| Grupo | Tipos | Variantes | Peças por hexágono na Média | Começam desligados |
| --- | --- | --- | --- | --- |
| Árvores (pacote) | 28 a 38 | todas | 1 | `autumn_tree`, `dead_tree`, `snowy_pine`, `snowy_tree`, `broadleaf_tree`, `palm_tree` |
| Troncos (pacote) | 39 | todas | 0,5 | nenhum |
| Arbustos (pacote) | 40 a 52 | todas | 2 | `autumn_bush`, `dry_twigs`, `barrel_cactus`, `arm_cactus`, `snowy_bush` |
| Pedras grandes (pacote) | 53 a 60 | 1 e 2 | 1 | `rust_crystal`, `ice_crystal`, `lava_stone` |
| Pedras médias (pacote) | 53 a 60 | 3 | 1 | os mesmos |
| Pedras pequenas (pacote) | 53 a 60 | 4 e 5 | 2 | os mesmos |

Cada grupo pode limitar as variantes (`variants`, de uma a outra), e o pincel sorteia a variante dentro do limite. Sem limite, sorteia entre todas, como hoje.

## O espaço no chão

O pincel guarda distância entre as peças pelo raio de cada uma ([vegetation-brush](../vegetation-brush/architecture.md#onde-o-pincel-põe-uma-peça)). As decorações têm o raio fixo de `HexDecorations.KIND_RADIUS`. As peças de arte própria passam a ter o raio da variante: ¼ da largura do PNG, de 4 a 15 px. Antes era 8 px para todas.

| Exemplo | Largura | Raio |
| --- | --- | --- |
| Árvore frondosa, variante 1 | 62 px | 15 |
| Árvore frondosa, variante 3 | 40 px | 10 |
| Arbusto redondo, variante 1 | 30 px | 7,5 |
| Pedra bege, variante 5 | 16 px | 4 |

O raio também é a distância mínima do centro do hexágono, onde o Domador fica.

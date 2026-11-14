# Wild battle

Explorar zona passa a abrir um **mapa hexagonal gerado a cada exploração**, maior que a tela. O jogador anda um hexágono por vez (desde a [14](14-tap-to-walk.md), tocando longe, ele vai sozinho pelo caminho mais curto; desde a [15](15-free-walk.md), em reta até o ponto tocado, com o hexágono só por baixo), com a câmera sempre nele, e procura Ecobeasts a partir dali. Cada bioma é uma superfície contínua, dividida pela grade, e os terrenos formam regiões coerentes, não uma mistura aleatória.

## Contexto

Hoje Explorar zona vai direto para a batalha, contra uma espécie sorteada entre as 9 do catálogo ([battle-screen](../battle-screen/)). O roadmap previa uma lista de zonas com nível recomendado e cadeado (TELAS.md #4). O dono trocou essa ideia por um mapa procedural, e forneceu 108 sprites de terreno para ele.

## Quem usa

- O jogador, ao tocar em Explorar zona.
- As iniciativas seguintes: o bioma do hexágono vai decidir os Ecobeasts que aparecem e quais terrenos cada equipe alcança.

## Objetivos

1. Cada exploração mostra um mapa diferente, e a mesma seed reproduz o mesmo mapa.
2. Os terrenos formam regiões que fazem sentido: florestas agrupadas, cadeias de montanhas e lagos.
3. Os hexágonos ficam alinhados e encostados, e a pixel art fica nítida em qualquer tela.
4. Sair do mapa para lutar e voltar não perde o lugar do jogador.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                                       | Motivo                                                                                  |
| --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| O mapa hexagonal substitui a seleção de zonas (TELAS.md #4) e o desbloqueio por nível         | Pedido do dono                                                                          |
| Um mapa novo a cada exploração, finito e maior que a tela                                     | Pedido do dono                                                                          |
| O jogador vê só o entorno: a câmera o acompanha, sem zoom e sem arrastar                      | Ver mais do mapa exige andar                                                            |
| Sem neblina: todos os hexágonos estão visíveis, mesmo os não visitados, quando entram na tela | Decisão do dono                                                                         |
| Anda um hexágono por vez, por qualquer terreno                                                | O bloqueio por terreno vem depois. Desde a [14](14-tap-to-walk.md), tocar longe anda o caminho mais curto, um hexágono por vez |
| Botão provisório "Procurar Ecobeast" no mapa                                                  | É a entrada para a batalha enquanto o encontro não nasce do terreno                     |
| O bioma do hexágono vai decidir o Campo, mas não nesta iniciativa                             | Nesta, o encontro continua sorteado como hoje                                           |
| `O_flat` é o mesmo terreno que `flat`, com mais detalhe                                       | Confirmado pelo dono                                                                    |
| `boreal` faz o papel de floresta por enquanto                                                 | Não há sprite de árvore. Mais tarde, `boreal` será só um Campo                          |
| Colina e montanha na água viram ilhas raras                                                   | Decisão do dono                                                                         |
| Superfícies contínuas no lugar dos sprites, com texturas provisórias geradas por código       | Pedido do dono, com o Sandwalkers de referência. Ele pode trocar as imagens depois      |
| Colina e montanha têm textura própria em qualquer bioma                                       | O dono vai separar as decorações à parte, e as duas vão ter Ecobeasts próprios          |
| Cinco níveis de altura, múltiplos de 8, da água (0) à montanha (32)                           | Pedido do dono, com o Sandwalkers de referência                                         |
| Plantas e rochas como enfeite em cada hexágono, geradas por código no cliente                 | Pedido do dono. Elas não mudam regra, então não passam pelo servidor                    |
| Contorno branco e sombra interna no hexágono atual                                            | Pedido do dono, para ver onde o jogador está                                            |
| Arremate sutil em cada divisa de biomas, com ondas na água, e o bioma escorrendo nos paredões | Pedido do dono, com o Sandwalkers de referência. É enfeite, então sai do cliente        |
| O Domador aparece no mapa, parado e correndo, com o template de Eris Esra por enquanto         | Pedido do dono. A arte final entra trocando as folhas                                   |
| Planos no mapa: o Domador fica entre as decorações de cima e as de baixo do hexágono           | Pedido do dono, para ele passar atrás do que está na frente                             |
| Vento nas plantas, em uma onda pelo mapa, feito por shader, sem arte nova                      | Pedido do dono. Vale para qualquer arte que entrar depois                               |
| Menu de depuração no mapa, com spawn de Ecobeasts que passeiam no próprio hexágono             | Pedido do dono, para validar as folhas de cada Ecobeast                                 |
| Só cinco regiões: `temperate`, `boreal`, `stone`, `wshallow` e `wdeep`                         | Decisão do dono, para simplificar. `warm`, `swamp`, `desert` e `snow` saíram do gerador, e os sprites ficaram no projeto |
| `stone` é uma região própria, com plano, colinas e montanhas                                  | Decisão do dono. Antes, a pedra era só o miolo das cadeias, e por isso a montanha de base cinza aparecia colada no campo e na floresta |
| Hexágonos encostados, com passos de 32, 21 e 16 px                                            | O dono tirou o vão de 2 px que tinha pedido depois da fase 03, porque ele impede a textura contínua por bioma |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                        | Motivo                                                                                                                  |
| ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| O servidor gera o mapa, e o cliente só desenha                                 | O texto do dono dizia "o jogo", mas o terreno vai decidir encontros e movimento, e o servidor é a autoridade das regras |
| Elevação, umidade e crista vêm de ruído                                        | Regiões coerentes sem escolher cada hexágono sozinho                                                                    |
| A posição do jogador fica só no cliente                                        | Ela ainda não afetava nenhuma regra. Desde a [biome-encounters](../biome-encounters/), o servidor a confere ao Procurar        |
| O mapa não fica guardado no servidor                                           | Nada depende dos hexágonos; a seed basta para reproduzi-los. A [biome-encounters](../biome-encounters/) guarda só os Ecobeasts e a posição     |
| Os parâmetros do gerador são constantes de código, não tabelas do catálogo     | São ajuste do algoritmo, e os valores ainda vão mudar bastante. Viram tabela quando o dono quiser editá-los no painel   |
| Depois da luta, a batalha volta para o mapa, no mesmo hexágono                 | O mapa só se perde ao voltar para o Hub                                                                                 |
| Escala inteira de pixels, recalculada para cada tela                           | A tela do jogo escala em frações, o que borraria a pixel art                                                            |

## Fora do escopo

- Encontros por bioma e tabelas de encontro.
- Terrenos bloqueados. A ideia do dono para depois: regiões mais fundas de montanha só com Ecobeasts que voem, e de água só com os que voem ou nadem.
- Aparecer Ecobeast ao andar. Por enquanto, a batalha só começa pelo botão.
- Guardar o mapa ou retomar a exploração depois de voltar ao Hub.
- Som ao andar.
- Zoom para o jogador, arrastar, minimapa e busca de caminho. Em build de debug, há um botão que mostra o mapa inteiro.
- Rios finos: sem sprites de transição, a água é feita de hexágonos inteiros.

## Pré-requisitos

- [battle-screen](../battle-screen/) concluída.
- Os sprites do dono em `C:\Users\ferna\Downloads\v01-1\v01\nogrid` (108 PNGs).

## Fases

| Fase                                              | Entrega                                                                  | Status   |
| ------------------------------------------------- | ------------------------------------------------------------------------ | -------- |
| [01-hex-grid](01-hex-grid.md)                     | Sprites no jogo, modelos do mapa e o desenho da grade com pixels inteiros | concluída |
| [02-map-generator](02-map-generator.md)           | Gerador puro com seed e a rota que entrega o mapa                        | concluída |
| [03-exploration-screen](03-exploration-screen.md) | A tela do mapa, andar, Procurar Ecobeast e a ligação com o Hub           | concluída |
| [04-biome-surfaces](04-biome-surfaces.md)         | Superfícies contínuas por bioma, com a grade visível                     | concluída |
| [05-terrain-elevation](05-terrain-elevation.md)   | Água, terra e montanha em alturas diferentes, com paredões               | concluída |
| [06-vegetation](06-vegetation.md)                 | Árvores, arbustos, grama e flores em cada hexágono                       | concluída |
| [07-rocks](07-rocks.md)                           | Rochas no mapa e rochas próprias do bioma de pedra                       | concluída |
| [08-current-tile](08-current-tile.md)             | Contorno branco e sombra interna no hexágono atual                       | concluída |
| [09-biome-transitions](09-biome-transitions.md)   | Ondas na costa, bordas sutis entre biomas e o bioma escorrendo no paredão | concluída |
| [10-tamer-sprite](10-tamer-sprite.md)             | O Domador no mapa, parado e correndo para os seis lados                  | concluída |
| [11-depth-planes](11-depth-planes.md)             | O Domador na frente do que está atrás e atrás do que está na frente      | concluída |
| [12-plant-wind](12-plant-wind.md)                 | As plantas balançam com o vento, em uma onda pelo mapa                   | concluída |
| [13-debug-menu](13-debug-menu.md)                 | Menu de depuração no mapa, com spawn de qualquer Ecobeast                | concluída |
| [14-tap-to-walk](14-tap-to-walk.md)               | Tocar num hexágono distante e o Domador ir sozinho pelo caminho mais curto | concluída |
| [15-free-walk](15-free-walk.md)                   | O Domador anda em reta até o ponto tocado, com o hexágono só por baixo   | concluída |

O desenho compartilhado está em [architecture.md](architecture.md).

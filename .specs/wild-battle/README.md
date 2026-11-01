# Wild battle

Explorar zona passa a abrir um **mapa hexagonal gerado a cada exploração**, maior que a tela. O jogador anda um hexágono por vez, com a câmera sempre nele, e procura Ecobeasts a partir dali. Os terrenos usam os sprites do dono e formam regiões coerentes, não uma mistura aleatória.

## Contexto

Hoje Explorar zona vai direto para a batalha, contra uma espécie sorteada entre as 9 do catálogo ([battle-screen](../battle-screen/)). O roadmap previa uma lista de zonas com nível recomendado e cadeado (TELAS.md #4). O dono trocou essa ideia por um mapa procedural, e forneceu 108 sprites de terreno para ele.

## Quem usa

- O jogador, ao tocar em Explorar zona.
- As iniciativas seguintes: o bioma do hexágono vai decidir os Ecobeasts que aparecem e quais terrenos cada equipe alcança.

## Objetivos

1. Cada exploração mostra um mapa diferente, e a mesma seed reproduz o mesmo mapa.
2. Os terrenos formam regiões que fazem sentido: florestas agrupadas, cadeias de montanhas, lagos, e nada de deserto encostado em neve.
3. Os hexágonos se encaixam sem emendas, e a pixel art fica nítida em qualquer tela.
4. Sair do mapa para lutar e voltar não perde o lugar do jogador.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                                       | Motivo                                                                                  |
| --------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| O mapa hexagonal substitui a seleção de zonas (TELAS.md #4) e o desbloqueio por nível         | Pedido do dono                                                                          |
| Um mapa novo a cada exploração, finito e maior que a tela                                     | Pedido do dono                                                                          |
| O jogador vê só o entorno: a câmera o acompanha, sem zoom e sem arrastar                      | Ver mais do mapa exige andar                                                            |
| Sem neblina: todos os hexágonos estão visíveis, mesmo os não visitados, quando entram na tela | Decisão do dono                                                                         |
| Anda um hexágono por vez, por qualquer terreno                                                | O bloqueio por terreno vem depois                                                       |
| Botão provisório "Procurar Ecobeast" no mapa                                                  | É a entrada para a batalha enquanto o encontro não nasce do terreno                     |
| O bioma do hexágono vai decidir o Campo, mas não nesta iniciativa                             | Nesta, o encontro continua sorteado como hoje                                           |
| `O_flat` é o mesmo terreno que `flat`, com mais detalhe                                       | Confirmado pelo dono                                                                    |
| `boreal` faz o papel de floresta por enquanto                                                 | Não há sprite de árvore. Mais tarde, `boreal` será só um Campo                          |
| Colina e montanha na água viram ilhas raras                                                   | Decisão do dono                                                                         |
| Usar só os sprites fornecidos, sem placeholder de terreno                                     | Pedido do dono                                                                          |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                        | Motivo                                                                                                                  |
| ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------- |
| O servidor gera o mapa, e o cliente só desenha                                 | O texto do dono dizia "o jogo", mas o terreno vai decidir encontros e movimento, e o servidor é a autoridade das regras |
| O clima vem de ruído de temperatura e umidade, com pares de biomas proibidos   | Regiões coerentes sem escolher cada hexágono sozinho                                                                    |
| A posição do jogador fica só no cliente                                        | Ela ainda não afeta nenhuma regra. O servidor passa a conferir quando o terreno decidir algo                            |
| O mapa não fica guardado no servidor                                           | Nada depende dele ainda; a seed basta para reproduzi-lo                                                                 |
| Os parâmetros do gerador são constantes de código, não tabelas do catálogo     | São ajuste do algoritmo, e os valores ainda vão mudar bastante. Viram tabela quando o dono quiser editá-los no painel   |
| O marcador do jogador é o retrato do primeiro Ecobeast da equipe               | Não há sprite de Domador                                                                                                |
| Depois da luta, a batalha volta para o mapa, no mesmo hexágono                 | O mapa só se perde ao voltar para o Hub                                                                                 |
| Escala inteira de pixels, recalculada para cada tela                           | A tela do jogo escala em frações, o que borraria a pixel art                                                            |

## Fora do escopo

- Encontros por bioma e tabelas de encontro.
- Terrenos bloqueados. A ideia do dono para depois: regiões mais fundas de montanha só com Ecobeasts que voem, e de água só com os que voem ou nadem.
- Aparecer Ecobeast ao andar. Por enquanto, a batalha só começa pelo botão.
- Guardar o mapa ou retomar a exploração depois de voltar ao Hub.
- Sprite de Domador, animação de andar e som.
- Zoom, arrastar, minimapa e busca de caminho.
- Rios finos: sem sprites de transição, a água é feita de hexágonos inteiros.

## Pré-requisitos

- [battle-screen](../battle-screen/) concluída.
- Os sprites do dono em `C:\Users\ferna\Downloads\v01-1\v01\nogrid` (108 PNGs).

## Fases

| Fase                                              | Entrega                                                                  | Status   |
| ------------------------------------------------- | ------------------------------------------------------------------------ | -------- |
| [01-hex-grid](01-hex-grid.md)                     | Sprites no jogo, modelos do mapa e o desenho da grade com pixels inteiros | concluída |
| [02-map-generator](02-map-generator.md)           | Gerador puro com seed e a rota que entrega o mapa                        | rascunho |
| [03-exploration-screen](03-exploration-screen.md) | A tela do mapa, andar, Procurar Ecobeast e a ligação com o Hub           | rascunho |

O desenho compartilhado está em [architecture.md](architecture.md).

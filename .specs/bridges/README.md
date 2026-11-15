# bridges

As ilhas ganham **pontes**: o dono desenha cada uma no editor como um traço reto, em qualquer ângulo, como a cerca, com a arte de um pacote de pontes da craftpix.net. Ao mesmo tempo, **a água passa a bloquear** o Domador nas ilhas e no mapa sorteado, e a ponte vira o caminho para atravessar.

## Contexto

Em 2026-11-15, o dono mandou a imagem de uma ponte de madeira sobre um rio e pediu: "agora quero criar pontes [...] A ideia é eu conseguir criar para qualquer ângulo, parecido com o que fizemos com a cerca". Mandou também o pacote `craftpix-net-668008-free-bridges-top-down-pixel-art-asset-pack`.

O que existe hoje:

- **A água não bloqueia nada.** O Domador anda por cima dela; só as linhas das peças e as paredes bloqueiam ([wild-battle/14](../wild-battle/14-tap-to-walk.md), [free-fences](../free-fences/)). Na [island-villages](../island-villages/README.md), o dono tinha decidido: "a água continua livre para andar; a ponte é só visual". O objeto Ponte de grade saiu na [island-villages/03](../island-villages/03-map-objects.md).
- **Os Ecobeasts de água** nascem nos hexágonos de água, no mapa sorteado (taxas de `wshallow` e `wdeep`) e nas áreas das ilhas pintadas sobre a água. A luta só começa pelo Procurar, no hexágono do Domador.
- **O mapa sorteado** tem lagos e canais de ruído e ilhotas, sem garantia de terra ligada.
- **O andar** vai de centro em centro de hexágono (`ExplorationMap.path_to_any`), com a reta final até o ponto tocado (`WalkRoute`).
- **A cerca** é desenhada em fatias de 1 px da arte, assentadas sobre a linha, sem girar a arte ([free-fences/architecture](../free-fences/architecture.md#o-desenho-fase-1)).
- **O pacote** tem 9 estilos de ponte em peças de 16 px. A maioria vem em duas vistas: de cima (a ponte em pé na tela, com o piso e os corrimãos dos lados) e de lado (a ponte deitada, com o piso, a frente com os arcos e os corrimãos de trás e da frente separados).

Claude mostrou que, com a água livre, a ponte seria só enfeite, e perguntou se a água devia bloquear. Depois, perguntou se só nas ilhas ou também no mapa sorteado, e mostrou dois jeitos de andar na ponte: o corredor da ponte ou liberar os hexágonos por onde ela passa.

## Objetivos

1. A água bloqueia o Domador e os NPC que andam, nas ilhas e no mapa sorteado.
2. O dono desenha pontes retas em qualquer ângulo no editor, escolhe o estilo, seleciona, troca o estilo e apaga, com desfazer.
3. No jogo, a ponte aparece na altura das margens, com o Domador por cima do piso e atrás do corrimão da frente.
4. O Domador atravessa a água pela ponte, pelo meio do piso, tocando do outro lado ou em cima dela.
5. Os Ecobeasts de água continuam sendo enfrentados, pela margem ou pela ponte.

## Anti-objetivos

- O servidor não passa a conferir o caminho do Domador: continua conferindo só o tempo (`confirmPosition`).
- O mapa sorteado não ganha pontes nem terra ligada à força.
- Nada de girar a arte: a pixel art não borra em ângulo nenhum.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| A ponte se desenha como a cerca: um traço, em qualquer ângulo | "parecido com o que fizemos com a cerca" |
| A arte vem do pacote de pontes da craftpix.net | "utilize esse pacote aqui para criar o visual melhor" |
| A água passa a bloquear o andar | "Água bloqueia". Troca a decisão da island-villages ("a água continua livre para andar") |
| Bloqueia nas ilhas e no mapa sorteado, sem garantir terra ligada | "Nos dois, mas não precisa se preocupar em deixar terra ligada. A ideia no futuro é ter formas de nadar utilizando um ecobeast" |
| Na ponte, o Domador anda num corredor do tamanho do piso | "Corredor da ponte", e não liberar os hexágonos de água por onde ela passa |
| Só ficam a ponte de madeira e a de corda, com a largura controlada, e sem cortes | "Ficou muito ruim, vamos manter apenas a ponte de madeira e a ponte de corda [...] quero controlar a largura dela, e também tá tendo muitos cortes nela" |
| A ponte deitada mostra os corrimãos em pé | "anteriormente tinha como ver as paredes/cerca da ponte em isométrico, agora nem isso direito" |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e no `architecture.md`):

| Decisão | Motivo |
| --- | --- |
| A ponte é um trecho reto de 2 pontos, com as duas pontas em terra | Uma ponte com curva precisaria de juntas na arte; duas pontes seguidas fazem a curva |
| A ponte mais deitada que 45° usa a vista de lado em colunas de 1 px; a mais em pé usa a vista de cima em linhas de 1 px | O mesmo truque da cerca: inclina sem girar |
| O piso fica na altura das margens. Com margens em alturas diferentes, ele sobe em rampa de uma à outra | O Domador não afunda até a água, e a ponte liga dois níveis |
| Os estilos são os do pacote com as duas vistas, num catálogo novo `bridge_types` (a fase 5 deixou só madeira e corda) | Toda ponte precisa servir em qualquer ângulo |
| Os corrimãos não viram parede: sair do piso já é entrar na água, que bloqueia | Um bloqueio só |
| O Procurar passa a enfrentar também um Ecobeast de um hexágono de água vizinho ao Domador | Com a água bloqueando, ninguém chegaria aos Ecobeasts de água |
| Os Ecobeasts e os Domadores NPC continuam nascendo onde nascem hoje. Os de uma ilhota fora de alcance esperam o nado | O dono vai fazer o nado depois |
| A chegada do mapa sorteado sempre fica em terra | Começar na água prenderia o Domador |
| Tocar na água leva o Domador até a margem, rente à água, como tocar numa cerca | O mesmo que a parede faz |

## Fora do escopo

- Nadar com um Ecobeast.
- Pontes no mapa sorteado.
- Ponte com curva, ponte levadiça, ponte quebrada.
- A animação da água do pacote.
- Passar por baixo da ponte.

## Pré-requisitos

- [free-fences](../free-fences/): o desenho em fatias, o bloqueio por linha e a ferramenta Cerca.
- [prop-depth-blocks](../prop-depth-blocks/): a ordem de desenho pelo pé.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-bridge-records](01-bridge-records.md) | A arte dos estilos, o catálogo `bridge_types`, a tabela `island_bridges` e o contrato | concluída (falta o dono conferir) |
| 2 | [02-bridge-drawing](02-bridge-drawing.md) | A ponte desenhada no mapa, na altura das margens, na ordem do pé | concluída (falta o dono conferir) |
| 3 | [03-bridge-tool](03-bridge-tool.md) | A ferramenta Ponte do editor | concluída (falta o dono conferir) |
| 4 | [04-water-walking](04-water-walking.md) | A água bloqueia, o corredor da ponte, o Domador na altura do piso e o Procurar na água vizinha | concluída (falta o dono conferir) |
| 5 | [05-width-and-cuts](05-width-and-cuts.md) | Só a ponte de madeira e a de corda, a largura escolhida e o desenho sem cortes | concluída (falta o dono conferir) |
| 6 | [06-diagonal](06-diagonal.md) | A ponte na diagonal girada, sem ficar puxada, e o bioma sem grama embaixo dela | concluída (falta o dono conferir) |
| 7 | [07-standing-rails](07-standing-rails.md) | Os corrimãos em pé, como a cerca, em qualquer ângulo até 75° | concluída (falta o dono conferir) |

O desenho compartilhado está no [architecture.md](architecture.md).

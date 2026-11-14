# free-fences

A cerca das ilhas sai da grade. O dono desenha a cerca como um traço, clicando os pontos, em qualquer ângulo, e ela é ao mesmo tempo a arte e uma **parede**: o Domador e os NPC não a atravessam. A mesma ferramenta desenha a **parede invisível**, para bloquear onde não há cerca. A Cerca de grade de hoje é convertida em traços e aposentada.

## Contexto

Em 2026-11-14, o dono pediu:

- **Mais liberdade na cerca:** "uma cerca ocupa o espaço de um campo inteiro, assim é muito limitante usar a cerca, queria algo mais refinado e especifico".
- **Bloqueio mais fino:** "só consigo bloquear por campo de hexagono, faria sentido ter um bloqueio melhor?"

O que existe hoje:

- **A Cerca (cidade)** (`town_fence`, id 29 de `map_object_types`, variantes 1 madeira e 2 pedra) é um objeto de 1 hexágono que bloqueia o hexágono inteiro. Ela se liga às vizinhas na mesma altura: um poste no centro e um braço até o meio de cada lado ligado ([island-villages/05](../island-villages/05-connected-fences.md), `HexFences`).
- **O bloqueio é por hexágono** (`island_object_tiles.blocks`). O Domador já anda em reta até o ponto tocado, em pixels ([wild-battle/15](../wild-battle/15-free-walk.md)), mas a busca de caminho (`ExplorationMap.path_to_any`) e a reta (`WalkRoute.is_clear`) só perguntam se o hexágono está bloqueado.
- **O servidor não confere bloqueio quando o Domador anda**, só o tempo (`confirmPosition`). Ele usa os hexágonos bloqueados para não pôr Ecobeast neles e para recusar o início da ilha num deles.
- **O editor já desenha traços livres** com a ferramenta Caminho (`island_trails`, [free-trails](../free-trails/README.md)).

Claude mostrou dois jeitos de bloquear: a cerca é a parede (A), ou a cerca é enfeite e o bloqueio se desenha à parte (B). O dono escolheu a A. Depois, num teste descartável com as duas artes de hoje, comparou a cerca em qualquer ângulo com a cerca presa às 6 direções do hexágono, e escolheu qualquer ângulo. Escolheu também converter as cercas de grade e aposentar o tipo, e o bloqueio por linha exata em vez de uma grade fina.

## Objetivos

1. O dono desenha cercas de madeira e de pedra em qualquer ângulo, ponto a ponto, e depois seleciona, troca o tipo e apaga cada uma, com desfazer.
2. A cerca é uma parede: o Domador anda até ela e não a atravessa, e a busca de caminho contorna. Os NPC que passeiam também.
3. A parede invisível bloqueia do mesmo jeito, aparece só no editor e se desenha com a mesma ferramenta.
4. No jogo, a cerca aparece na altura do chão embaixo dela, na frente ou atrás do Domador conforme a posição.
5. As cercas de grade das ilhas viram traços, e a Cerca (cidade) sai do editor.

## Anti-objetivos

- A parede não muda o servidor como autoridade do andar: ele continua conferindo só o tempo, como hoje.
- Nada muda no mapa sorteado de Explorar zona.
- O bloqueio por hexágono das casas, do Refúgio e da Loja continua como está.

## Decisões

Do dono, em 2026-11-14:

| Decisão | Motivo |
| --- | --- |
| A cerca é a parede (A): o traço é a arte e o bloqueio | Desenhar o cercado uma vez só |
| Qualquer ângulo, e não as 6 direções do hexágono | No teste, as direções fixas viraram dentes e zigue-zague, e o traço não fechava |
| Converter as cercas de grade em traços e aposentar a Cerca (cidade) | Um jeito só de fazer cerca, e um bloqueio só |
| O bloqueio é a linha exata, e não uma grade fina | O andar já é em pixels; o Domador chega rente à cerca |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e no `architecture.md`):

| Decisão | Motivo |
| --- | --- |
| Os tipos: **Cerca de madeira** (`wood_fence`), **Muro de pedra** (`stone_fence`) e **Parede invisível** (`invisible_wall`), num catálogo novo `wall_types` | A madeira e a pedra são as duas variantes de hoje; a invisível é o bloqueio fino que o dono pediu |
| Na ferramenta, um clique põe um ponto e a cerca segue em reta entre os pontos; Enter, clique duplo ou o botão direito terminam | A cerca é feita de trechos retos; arrastar, como o Caminho, faria tremer |
| A arte é montada como no teste: as travessas (ou o muro) são fatias de 1 px da arte de hoje, repetidas ao longo da linha, e os postes ficam a cada cerca de 20 px, sempre num ponto clicado | Foi a versão que o dono aprovou no teste |
| Cada fatia e cada poste entra na faixa de profundidade do pé dele, como as peças soltas | O Domador fica na frente ou atrás da cerca pela posição |
| Um trecho que cruza um degrau é desenhado em pedaços, cada um na altura do hexágono embaixo dele | O mesmo que o caminho faz |
| A parede bloqueia o pé do Domador a menos de 3 px da linha (`WALL_REACH`) | Uma folga, para ele não passar raspando por uma fresta |
| A busca de caminho fecha a passagem entre dois hexágonos vizinhos quando uma parede corta a reta entre os centros deles | O resto da busca fica igual, de hexágono em hexágono |
| A parede não muda os Ecobeasts nem Procurar: eles nascem por hexágono, como hoje | O servidor não sabe de paredes, e um Ecobeast atrás da cerca no mesmo hexágono ainda pode ser enfrentado |
| No cliente, os Ecobeasts e os Domadores NPC que vagam dentro do hexágono escolhem pontos sem cruzar parede | Só desenho: ninguém aparece atravessando a cerca |
| Tocar num hexágono cujo centro a parede cerca leva o Domador até o ponto mais perto, rente à parede | Hoje, tocar numa cerca leva ao lado livre; a conversão põe paredes pelo centro dos hexágonos de cerca |
| Num trecho quase na vertical da tela, os postes ficam mais juntos (cerca de 10 px) | Sem lado vertical no hexágono, a cerca de hoje nunca teve esse caso; a fatia de 1 px vira só um fio |
| A conversão é uma migration em SQL: cada par de cercas ligadas vira uma parede de centro a centro (metade de cada material, se forem diferentes), e uma cerca sozinha vira a peça reta da esquerda para a direita | Fica no banco, como as outras limpezas; juntar trechos em linhas longas não vale o trabalho |
| As paredes não entram nos carimbos | Como os traços de caminho |
| Limites: 2.000 paredes por ilha, de 2 a 128 pontos cada | A conversão faz uma parede por par de cercas ligadas, e uma ilha cheia de cercas passaria de 500 |

## Fora do escopo

- Portão, ou parede que abre.
- Mover um ponto de uma parede já feita ou emendar duas. Para mudar, o dono apaga e desenha de novo.
- Paredes nos carimbos.
- Arte nova de cerca, além da de hoje.
- O servidor conferir paredes no andar ou nos Ecobeasts.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-wall-records](01-wall-records.md) | Servidor e jogo: o catálogo `wall_types`, as paredes no banco, no contrato do editor e de Explorar, e desenhadas no jogo e no editor | concluída (falta o dono ver no editor e no jogo) |
| 2 | [02-wall-blocking](02-wall-blocking.md) | Jogo: o Domador e os NPC não atravessam as paredes | concluída (falta o dono jogar numa ilha com cercas) |
| 3 | [03-fence-tool](03-fence-tool.md) | Editor: a ferramenta Cerca, para desenhar, selecionar, trocar e apagar paredes, com desfazer | concluída (falta o dono usar no F2) |
| 4 | 04-fence-conversion | Servidor e cliente: as cercas de grade viram paredes, e a Cerca (cidade) sai | rascunho |

As specs das fases são escritas antes de cada uma. O desenho compartilhado está no [architecture.md](architecture.md).

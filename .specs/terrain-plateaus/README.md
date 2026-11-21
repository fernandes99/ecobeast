# terrain-plateaus

O mapa sorteado ganha relevo de verdade: patamares de várias alturas separados por paredões, escadarias para subir e montanhas no alto (8 a 10). Em todo mapa, inclusive nas ilhas, um paredão de 3 níveis ou mais bloqueia o Domador. Os lagos e os rios nas alturas, com cachoeiras, ficam para depois: por enquanto, toda água fica no 0.

## Contexto

Em 2026-11-21, o dono mandou duas imagens de terreno em hexágonos, com platôs, paredões de terra, um rio no alto caindo em cachoeira e um lago embaixo, e pediu: "Na geração de mapas eu quero gerar terrenos elevados, não só para os biomas de colina e montanha, a montanha sem duvidas será sempre a que vai ficar na maior atitude, em 8~10. [...] Onde rios e lagos podem ser formados em altitudes elevadas e serem criadas cachoeiras com isso. O mar sempre ficaria no 0".

Claude leu o gerador e o andar:

- O gerador já calcula um relevo contínuo (`shapeRelief` em `server/src/domain/exploration/map-generator.ts`, de 0 a 1), mas o `terrainOf` o corta em 5 alturas fixas pela forma e pelo bioma: água 0, chão plano 1, Colina 2, Pedra 3 e Montanha 4 (`MOUNTAIN_HEIGHT`). Todo lago e todo rio fica no 0.
- O jogo já desenha alturas de 0 a 10, com paredões, e toda lateral de água vira cachoeira ([water-motion](../water-motion/)). Uma cena como a das imagens já se pinta no F2.
- A altura não entra no andar. A busca (`ExplorationMap.path_to_any`), a reta do passo (`is_clear`) e as conferências de alcance do servidor (`walkable` em `map-water.ts`, `reachable` em `map-rocks.ts`) só olham a água, as paredes e as linhas das peças. O Domador sobe qualquer paredão.

Em Liora (mapa publicado 7076), com a regra nova e sem contar as pontes, 773 dos 7.757 hexágonos que se alcançam hoje a partir do início ficariam fora: uma baixada de 552 hexágonos de Boreal e Montanha (q 14 a 52, r −30 a 9) cercada por paredões dos níveis 6 a 10, um platô de 210 hexágonos de Planície no nível 7 (q −30 a −3, r −16 a 7) e 6 pedaços de 1 a 3 hexágonos. Nenhum NPC nem área de Ecobeasts fica neles.

## Objetivos

1. A regra do paredão em todo mapa: entre vizinhos, uma diferença de até 2 níveis passa, e de 3 ou mais bloqueia.
2. No mapa sorteado, toda a terra se alcança a pé (ou por ponte) a partir da chegada.
3. Patamares na terra, separados por paredões, com encostas de degraus de 1 e 2 misturados ao acaso.
4. A Montanha sempre no alto, de 8 a 10.
5. Toda água no 0 por enquanto; os lagos e os rios nas alturas, com cachoeiras, ficam para uma fase futura.

## Anti-objetivos

- O Domador subindo um paredão de 3 níveis ou mais.
- Um pedaço de terra do mapa sorteado sem caminho a partir da chegada.
- Mar acima do 0.
- Mudar as ilhas salvas: a regra vale nelas, mas as alturas continuam as que o dono pintou.

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| O paredão bloqueia o Domador, com encostas para subir | Respondeu "Sim, com encostas" |
| Até 2 níveis passa; a encosta mistura degraus de 1 e de 2 ao acaso | "de graus de 1~2, as vezes pode ser 1 em 1 ou 2 em 2, ou as vezes é 1 em 2, 2 em 1, randomico" |
| A regra vale em todo mapa, nas ilhas também | Respondeu "Sim, em todo mapa", depois de ver o que Liora perderia |
| A Montanha fica de 8 a 10 | "a montanha sem duvidas será sempre a que vai ficar na maior atitude, em 8~10" |
| O mar fica sempre no 0 | "O mar sempre ficaria no 0, nunca poderia ter um mar na altitude acima disso" |
| Lagos e rios podem ficar no alto, com cachoeiras, mas depois | Pediu no começo; depois de ver a prévia: "Vamos deixar as cachoeiras para depois, desfaça o que fez nelas, todas as aguas vão nascer no plano 0" |
| As encostas têm vários degraus juntos | "devem existir mais degrais juntos, podem sim existir apenas um [...] Mas o ideal é ter mais" |
| A encosta é a própria altura, não uma peça de escada | Escolheu a opção A; a escada como peça pode vir depois, por cima da mesma regra |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Duas fases: a regra primeiro, os patamares depois | A regra sozinha já muda o andar em Liora e nos mapas de hoje (a Montanha no 4 encostada no chão no 1 vira paredão), e a garantia de alcance da fase 1 é a mesma que a fase 2 usa |
| A encosta só sobe hexágonos, nunca baixa | Baixar a terra podia deixar a água mais alta que a margem |
| A margem de ponte que sobe leva a outra junto | As duas pontas continuam na mesma altura, e a encosta pode passar por elas |
| Os patamares da terra ficam nas alturas 1, 4 e 7 | 3 níveis entre eles: toda borda de patamar é paredão, e a encosta precisa de 1 ou 2 degraus no meio |
| A Montanha é 8 na borda, 9 a 1 hexágono dela e 10 mais para dentro | Degraus de 1: dá para andar dentro dela, e o patamar 7 encosta nela sem paredão |
| A Praia fica sempre no 1 | A areia desce até o mar; um paredão de praia no alto não parece praia |
| A camada Bloqueios do F2 marca os paredões | O dono vê onde falta encosta para abrir em Liora |

## Fora do escopo

- A escada ou a rampa como peça desenhada (a opção B da conversa).
- Abrir as encostas de Liora: o dono pinta pela ferramenta Altura do F2, guiado pela camada Bloqueios.
- A altura na luta: o tabuleiro continua plano.
- Os Ecobeasts que passeiam dentro do próprio hexágono.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-cliff-rule](01-cliff-rule.md) | A regra do paredão no jogo e no servidor, a garantia de alcance do mapa sorteado e os paredões na camada Bloqueios do F2 | concluída (falta o dono conferir em Liora e no F2) |
| 2 | [02-plateaus-water](02-plateaus-water.md) | Os patamares, as escadarias, a Montanha de 8 a 10 e a água no 0 | concluída (falta o dono conferir no jogo) |

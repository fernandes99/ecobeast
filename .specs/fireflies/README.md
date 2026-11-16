# fireflies

Vagalumes no mapa de exploração: enxames de pontinhos brilhantes que aparecem no fim da tarde, vagam, piscam e iluminam em volta à noite, no mapa sorteado e nas ilhas.

## Contexto

Em 2026-11-15, logo depois da [day-night](../day-night/), o dono pediu: "coloca uma decoração nova, que será vagalumes, vai ser uns pontos brilhantes no mapa, ele vai aparecer nas ilhas generativas também, a ideia é elas emitirem luzes a noite também."

As decorações naturais saem de uma receita por bioma (`HexDecorations.RECIPES`), sorteada pela seed do mapa, no mapa sorteado e nas ilhas. O filtro da noite (`DayLightLayer`, shader `day_light.gdshader`) escurece o mapa e desenha até 32 luzes em degraus do pixel da arte.

## Objetivos

1. Enxames de vagalumes nos hexágonos de Planície e de Boreal, no mapa sorteado e nas ilhas.
2. Cada enxame tem alguns pontinhos de 1 pixel da arte que vagam em volta do centro e piscam.
3. Os vagalumes só aparecem com a força das luzes da noite: surgem a partir das 17h, ficam a noite toda e somem até as 7h.
4. Cada enxame ilumina em volta, fraco, e o pontinho brilha por cima do escuro.

## Anti-objetivos

- Mudar o lugar das decorações que já existem num mapa ou numa ilha.
- Vagalume visível de dia.
- Um nó novo que precise seguir a câmera.
- Mudar o servidor, o banco ou o catálogo.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| Os vagalumes são uma decoração do mapa, no mapa sorteado e nas ilhas, e iluminam à noite | Pedido do dono |
| Só aparecem do fim da tarde até a manhã | Escolheu "Só à noite" entre só à noite e sempre visíveis |
| Os pontinhos são desenhados no shader da noite | Claude mostrou o shader da noite e uma camada própria de pontinhos, e o dono escolheu o shader |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Biomas: Planície (`temperate`) e Boreal (`boreal`), _a revisar_ | São os de mato e floresta; Deserto, Neve, Praia, Pedra, Colina, Montanha e água ficam sem |
| O sorteio dos enxames usa um gerador próprio, e não entra na receita das decorações | Assim o sorteio das decorações de hoje não muda, e o enxame não precisa de arte na folha `decorations.png` |
| Um hexágono com a marca `bare` (a Borracha do editor) não tem enxame | A Borracha tira as decorações naturais |
| Os enxames não viram peça solta no editor | Eles saem do bioma, como as decorações naturais |
| Cada enxame é uma luz fraca dentro do próprio shader, fora do limite das 32 luzes | Um campo cheio de vagalumes passaria do limite e apagaria os postes |
| Nenhum vagalume no tabuleiro da luta | O tabuleiro não tem decorações sorteadas por hexágono |

## Fora do escopo

- Vagalumes no tabuleiro da luta e no editor de ilhas (F2), que fica sempre de dia.
- Outros bichos de enfeite (borboletas, pássaros) e som à noite.
- Vagalumes fugindo do Domador.

## Pré-requisitos

- [day-night](../day-night/): o relógio, o filtro e a força das luzes.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-fireflies](01-fireflies.md) | Os enxames sorteados e desenhados no shader da noite | concluída (falta o dono conferir) |

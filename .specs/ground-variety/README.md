# ground-variety

Vinte tipos novos de chão e de caminho para o editor de ilhas (F2), para o dono montar cenários mais variados: deck de madeira, praça de tijolos, pátio de castelo, templo de mármore, ruína com musgo, vulcão, praia, fazenda, pântano, bosque e neve, e, na [02](02-stone-trails.md), oito trilhas de pedra, três delas com as pedras soltas sobre o bioma.

## Contexto

Em 2026-11-22, o dono pediu "novas opções de caminhos e chão, crie vários e diversos, pelo menos 10", para "ter mais opções para criar cenários no f2".

O que existe hoje ([free-trails](../free-trails/README.md)):

- **8 chãos** no catálogo `ground_types`, com o `kind` (`trail` ou `floor`) e a dureza (`hardness`, de 1 a 3), cada um com a textura de 512×512 gerada pelo `make_grounds.gd`.
- **Todo tipo serve para as duas ferramentas** do F2: a Chão (por hexágono) e a Caminho (o traço livre). As duas leem a lista do catálogo.
- **A máscara de chão** desenha tudo por um shader só, com a borda irregular na grama e, na emenda, as pedras do tipo mais duro soltas sobre o mais mole. Ela aceita até 31 tipos (`HexGrounds.MAX_TYPES`).

Claude propôs os 12 tipos da tabela abaixo, e o dono aprovou a lista ("Pode seguir").

## Objetivos

1. Os 12 tipos novos no catálogo, com nome, `kind` e dureza.
2. A textura de cada um no estilo das de hoje, emendando nas quatro bordas.
3. Os tipos aparecem nas ferramentas Chão e Caminho do F2 e em Explorar numa ilha, sem mudar a tela.

## Anti-objetivos

- O chão continua só desenho: não bloqueia, não muda encontro nem a posição do Domador.
- Nada muda no mapa sorteado de Explorar zona.
- As 8 texturas de hoje não mudam.

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| Os 12 tipos da tabela, com o uso de cada um | A lista proposta por Claude, aprovada sem mudança |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os ids 9 a 20, o `kind` e a dureza da tabela | O piso fecha uma área (deck, praça, pátio, horta); a trilha é o que se anda. A dureza segue a regra da free-trails: a pedra se solta sobre a terra |
| A textura fica parada no mundo, sem girar com o traço | É como o chão é desenhado hoje. As tábuas e os tijolos ficam sempre na horizontal, bons em piso; numa trilha curva, eles não acompanham a curva. O dono foi avisado ao aprovar a lista |
| Nas Folhas secas, o chão entre as folhas é transparente e mostra o bioma, como nos Pisantes | Folhas caídas sobre a grama, não um tapete marrom || A arte é gerada por código, no `make_grounds.gd`, como a de hoje | O pacote Fantasy Dreamland só tem grama, terra e areia lisas |

| id | slug | name | kind | hardness | Uso |
| --- | --- | --- | --- | --- | --- |
| 9 | `wood_planks` | Tábuas de madeira | floor | 2 | deck, cais, piso de vila |
| 10 | `brick_floor` | Tijolos | floor | 3 | praça e rua de cidade |
| 11 | `flagstone_floor` | Lajotas | floor | 3 | pátio de castelo |
| 12 | `marble_floor` | Mármore | floor | 3 | templo e ruínas arcanas |
| 13 | `mossy_trail` | Pedra com musgo | trail | 3 | trilha de ruína na floresta |
| 14 | `basalt_floor` | Basalto rachado | floor | 3 | Vulcão |
| 15 | `shell_trail` | Conchas | trail | 2 | trilha da Praia |
| 16 | `tilled_soil` | Terra arada | floor | 1 | horta e fazenda |
| 17 | `straw_floor` | Palha | floor | 1 | celeiro e fazenda |
| 18 | `mud_trail` | Lama | trail | 1 | pântano, chuva |
| 19 | `leaf_trail` | Folhas secas | trail | 1 | trilha de bosque |
| 20 | `snow_trail` | Neve pisada | trail | 1 | Neve |

## Fora do escopo

- A textura que gira com o traço.
- Chão animado ou aceso à noite (a lava no basalto, a água na lama).
- Os tipos novos no gerador da ilha nova ou no mapa sorteado.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-ground-types](01-ground-types.md) | Catálogo e arte: os 12 tipos e as texturas, nas ferramentas Chão e Caminho | concluída (falta o dono conferir no F2) |
| 2 | [02-stone-trails](02-stone-trails.md) | Catálogo e arte: 8 trilhas de pedra (ids 21 a 28), 5 fechadas e 3 de pedras soltas sobre o bioma | concluída (falta o dono conferir no F2) |
| 3 | [03-dirt-tones](03-dirt-tones.md) | Catálogo e arte: a Trilha de terra clara e a escura, no tom da Lama (ids 29 e 30) | concluída (falta o dono conferir no F2) |

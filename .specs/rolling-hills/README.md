# rolling-hills

No mapa sorteado, a Colina e a Montanha passam a ser sorteadas separadas. A Colina vira um morro de verdade, em manchas que sobem 1 ou 2 níveis acima do chão em volta, longe ou perto de montanha. A Montanha fica mais rara e junta, em 1 a 4 maciços por mapa, e cada maciço sorteia se ganha uma faixa de Colina ao pé.

## Contexto

Em 2026-11-21, o dono pediu para entender a Colina antes de mexer nela. Depois explicou o que incomoda: "a montanha hoje depende da colina para ser gerada, mas nem sempre quero isso, podem existir colinas sem montanahs e podem existir montanhas sem as colinas em voltas. Será que esse algoritmo podemos pensar em algum melhor?"

Claude leu o gerador (`server/src/domain/exploration/map-generator.ts`):

- O `shapeRelief` dá a cada hexágono de terra um relevo só (`elevation`, de 0 a 1 por percentil), que mistura o ruído de altitude (0,45), as cristas (0,35) e a distância até o mar (0,2).
- O `placeShapes` corta esse relevo em faixas: acima de `mountainFrom` (0,96) é Montanha, entre `hillFrom` (0,86) e `mountainFrom` é Colina.
- O relevo muda aos poucos de um vizinho para o outro. Por isso toda Montanha nasce cercada pela faixa da Colina, e a Colina longe de montanha só aparece onde um morro parou antes de 0,96, o que é raro.
- A Colina fica sempre acima de `terraceHigh` (0,75), então toda Colina está no patamar 7, logo abaixo da Montanha (8 a 10).
- A montanha solta, sem outra encostada, vira Colina (`gatherMountains`).

O que mais o dono sabe da Colina hoje: nenhuma ilha usa o bioma (nem Liora), ela tem 19 espécies e nenhuma é só dela, e as zonas Pedregal e Mato seco. Nada disso muda nesta iniciativa.

## Objetivos

1. Colinas sem montanha: manchas de morro em qualquer patamar, longe de qualquer Montanha.
2. Montanhas sem colina: a cadeia pode subir direto do chão em volta.
3. A Colina é um morro de verdade: 1 nível acima do chão na borda e 2 no miolo.
4. A Montanha continua a mais alta do mapa.
5. As montanhas em maciços grandes e juntos, mais raras de encontrar.

## Anti-objetivos

- A Colina presa à Montanha, como hoje.
- Um morro com paredão por dentro: o Domador sobe a pé de um degrau de 1 para o outro.
- Mexer nas ilhas salvas, no editor de altura, nos Ecobeasts, nas zonas ou na arte.

## Caminhos considerados

| Caminho | O que custa | Escolha |
| --- | --- | --- |
| **Dois sorteios independentes:** a Montanha pelo relevo, a Colina por um ruído em manchas, e a faixa ao pé de cada maciço por sorteio | Pouco código, e o relevo de hoje continua para os rios, os patamares e o frio | **Escolhido** |
| Pôr cada cadeia e cada mancha à mão, como formas carimbadas | Controla a quantidade exata, mas tem cara de carimbo e é muito mais código | Descartado |
| Manter o relevo único e apagar o anel de Colina depois | Remendo, e a Colina continua presa ao patamar 7 | Descartado |

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| Colina e Montanha não dependem uma da outra | "podem existir colinas sem montanahs e podem existir montanhas sem as colinas em voltas" |
| A Colina longe de montanha é um morro de verdade, mais alto que a volta | Escolheu "Morro de verdade" no lugar de "só o bioma" |
| O desenho abaixo | "Aprovado, escreve" |
| As montanhas mais raras, juntas e grandes, não em faixas ou pedaços espalhados | Depois da prévia: "elas devem ser um pouco mais incomuns de se encontrar e não podem ficar dispersas assim, elas geralmente ficaram mais juntas e ocuparam mais espaço, não serão uma ou duas faixas de blocos" |
| A prévia dos maciços | "Ficou bom, segue" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase), mostradas ao dono antes do "Aprovado":

| Decisão | Motivo |
| --- | --- |
| A Colina sai de um ruído próprio, em manchas arredondadas de uns 4 a 15 hexágonos | Um morro de 1 hexágono não parece morro, e uma mancha enorme vira um planalto |
| O morro sobe +1 na borda e +2 no miolo, a partir do patamar dele | Degraus de 1: sobe a pé, sem paredão nem escadaria (o paredão começa em 3) |
| No patamar 7 o morro sobe só +1, ficando no 8 | A Montanha (8 a 10) continua a mais alta |
| Cada maciço sorteia uma faixa de Colina de 1 ou 2 hexágonos ao pé, com 50% de chance | Uns maciços com sopé, outros subindo direto do chão |
| A Montanha sai do relevo suavizado (a média a até 3 hexágonos), e os pedaços menores que 0,4% da terra viram chão | Dá os maciços que o dono pediu: o ruído de cristas dava linhas finas, e o relevo puro, manchas espalhadas |
| A Colina fica com 6% a 10% da terra (`hillFraction` 0,10) | É perto do que era (abaixo de 12%) |
| O morro no Deserto e na Neve fica com o bioma do lugar (duna, morro nevado); na Praia não há morro | É a regra de hoje do `terrainOf`, e a Praia fica sempre no 1 |
| A montanha solta continua virando Colina | Um hexágono de montanha sozinho não é cadeia; vira um morro |
| Os sorteios novos usam um gerador com sal próprio | O mar, o clima, os lagos e os rios de uma seed não mudam por causa deles |

## Fora do escopo

- A Colina com Ecobeasts só dela, uma regra de jogo própria ou arte nova: o dono decide depois se ela fica e como.
- A altura nas ilhas e no editor: continua pintada à mão.
- Lagos e rios nas alturas, com cachoeiras (seguem para depois, como na [terrain-plateaus](../terrain-plateaus/README.md)).

## Pré-requisitos

- [terrain-plateaus](../terrain-plateaus/README.md): os patamares 1, 4 e 7, a Montanha de 8 a 10, a regra do paredão e as escadarias.
- [map-realism](../map-realism/README.md): o relevo único e o clima por mapa.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-independent-relief](01-independent-relief.md) | A Montanha em maciços, a Colina em sorteio próprio, o morro de +1 e +2, a faixa ao pé por maciço e os parâmetros novos no gerador do F2 | concluída (falta o dono conferir no jogo) |

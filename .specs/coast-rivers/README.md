# coast-rivers

O mapa sorteado ganha um mar de verdade, com a Praia na beira dele, e um gerador de lagos e rios. Os rios que cortam a terra ganham travessias: pontes automáticas e vaus, uma água rasa e transparente que dá pé.

## Contexto

Em 2026-11-15, o dono pediu: "agora faça um novo bioma, a ideia é ser uma praia, ela deve nascer perto de um mar, o mar deve ter muita agua, vai ter agua rasa e muita agua profunda para se tornar um mar. além disso faça também um algoritmo que vai criar além do mar, rios e lagos, pesquise boas praticas dessas criações. rios vão poder nascer em um pequeno lago/nascente, mas não necessariamente todos os lagos vão ter rios."

Hoje a água do mapa sorteado são os 20% mais baixos de um ruído de altitude: poças espalhadas, sem mar, sem rio e sem diferença entre mar e lago. Desde a [bridges/04](../bridges/04-water-walking.md), a água bloqueia o Domador, e a ponte só existe nas ilhas, posta no editor.

Um rio que corta a terra separaria o mapa. Claude mostrou três saídas: ponte automática, vau e rio que não corta. O dono respondeu: "Vamos implementar as 3, mas a parte do Vau preciso entender como seria isso, eu gostaria que tivesse uma agua com opacidade e uma terra embaixo nesses casos", e "No 3, quero ter um controle disso da geração, por padrão deve ser equilibrado alguns vão cortar outros não, e pode nem surgir rios que cortam". Viu uma prévia do vau, desenhada pelo jogo, com fundo de areia ou cascalho e a água a 45% ou 65%, e escolheu "Cascalho, 45%".

## As boas práticas pesquisadas

- **Mar e lago** se separam pela ligação: a água ligada à borda do mapa é mar, a fechada na terra é lago, e a costa é a terra encostada no mar ([Red Blob Games, polygon map generation](https://www.redblobgames.com/maps/polygon-map-generation/)).
- **O rio** nasce num ponto alto e desce sempre para o vizinho mais baixo, até o mar, um lago ou outro rio ([Red Blob Games, rivers](https://www.redblobgames.com/maps/rivers/); [delvelord, river generation](https://delvelord.blogspot.com/2015/01/river-generation.html)).
- **O buraco sem saída** no caminho é enchido até transbordar (Priority-Flood), e assim todo ponto tem uma descida até uma saída ([Barnes, Priority-Flood](https://arxiv.org/pdf/1511.04463); [mewo2, generating fantasy maps](https://mewo2.com/notes/terrain)).
- **A altitude cai em direção ao mar**, para os rios correrem para ele, como no gerador da Red Blob, que decide a costa primeiro e sobe a terra a partir dela.

## Objetivos

1. Um mar grande num lado do mapa, com uma faixa de água rasa junto da terra e o resto fundo.
2. O bioma Praia (id 10) na terra encostada no mar, com quem nasce nele.
3. Lagos espalhados, alguns com rio e outros sem.
4. Rios que nascem numa nascente ou num lago pequeno e descem até o mar, um lago ou outro rio.
5. Rios que atravessam o mapa, vindos de fora dele, cortando a terra, com pontes e vaus, numa quantidade controlada pela geração.
6. O vau (id 11): água rasa a 45% sobre um fundo de cascalho, onde o Domador anda.
7. Toda terra ligada à chegada por terra, ponte ou vau, menos a que só o mar ou um lago separa.

## Anti-objetivos

- Um pedaço de terra cortado por rio sem travessia.
- Uma ponte que não liga duas margens.
- O mar em poças pelo mapa, ou um mapa sem mar.
- Mudar as ilhas já salvas.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| Praia perto do mar, e o mar com água rasa e muita água funda | "o mar deve ter muita agua, vai ter agua rasa e muita agua profunda" |
| Rios nascem numa nascente ou num lago pequeno, e nem todo lago tem rio | "rios vão poder nascer em um pequeno lago/nascente, mas não necessariamente todos os lagos vão ter rios" |
| As três travessias: ponte automática, vau e rio que não corta | "Vamos implementar as 3" |
| A quantidade de rios que cortam é um controle da geração, equilibrado por padrão, e pode sair nenhum | "por padrão deve ser equilibrado alguns vão cortar outros não, e pode nem surgiu rios que cortam" |
| O vau é água a 45% sobre cascalho | Viu a prévia e escolheu "Cascalho, 45%" |
| Sem ilhotas no mar | "remova a chance de ilhota na ilha no gerador" |
| Onde o rio encontra o mar, não há faixa de areia | "quando o rio se encontrar com o mar, remova a faixa de areia" |
| A Praia tem de 2 a 4 hexágonos | "a faixa de areia está curta, pode ser entre 2 a 4" |
| O lago é redondo, com no mínimo 6 hexágonos de largura, também o da nascente | "Quando for lago, ele precisa ser mais redondo (no minimo um 6x6 caso exista algum)" |
| O rio tem normalmente de 2 a 4 hexágonos de largura, com o controle no gerador | "pode aumentar para que normalmente vemos de 2 a 4 de largura (a grossura do rio podemos ter esse controle no gerador?)" |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O mar fica num lado do mapa, sorteado pela seed, crescendo a partir da borda, com a costa recortada por ruído | Um mar de verdade, grande e de um lado só, como pedido; em volta do mapa todo, ele comeria a terra das bordas |
| Sem ilhotas: o `islandChance` sai do gerador e do editor, e a água fica sempre plana | "remova a chance de ilhota na ilha no gerador", depois de ver os pilares de terra no mar |
| Um rio que nasce dentro da terra nunca a corta; só corta o que vem da borda do mapa (o "rio que atravessa") | O Domador contorna a nascente. Assim o controle é simples: a chance de cada rio vir de fora. Num estreito do recorte do mapa, o lago ou o rio de dentro que partiria a terra é sorteado de novo |
| A ponte automática só sai com as margens frente a frente, na mesma altura e sem montanha; senão, a travessia é vau | Uma ponte entre alturas diferentes ou numa montanha ficaria torta |
| Um ruído miúdo na altura de escoar | Sem ele, o enchimento deixa planos, e os rios saíam retos e paralelos |
| O vau é um bioma (`wford`, id 11), da família da água no desenho, mas sem bloquear | "Siga como é feito hoje": o editor pinta o vau pelo bloco Bioma, como os outros |
| As travessias ficam a cada 14 hexágonos do rio que atravessa, no mínimo 1, metade ponte e metade vau | Um rio longo não obriga uma volta grande, e os dois tipos aparecem |
| A ponte automática é de madeira, de 28 px, reta de margem a margem por cima de um hexágono de rio | É a largura padrão da ferramenta Ponte |
| A Praia fica sobre qualquer bioma, menos a Montanha | A costa fica toda de areia, como numa praia |
| O rio fica fino na nascente e largo na foz (`riverMinWidth` → `riverMaxWidth`); o que vem da borda já começa no meio | Como um rio de verdade, que junta água descendo |
| A Praia não encosta num rio, nem longe do mar | A areia sumir só na foz deixaria um degrau de areia ao lado do rio logo atrás dela |
| Quem nasce na Praia: Nilu 50, Clod 20, Nilgar 15, Elu 10, Nilgorr 5 | Água e Terra combinam com mar e areia |
| No Vau não nasce ninguém | É passagem |
| A água de hoje por ruído de altitude sai; `water_fraction` e `deep_fraction` dão lugar aos parâmetros do mar, dos lagos e dos rios | A água agora vem do mar, dos lagos e dos rios |
| O mapa sorteado de uma seed muda | Os mapas sorteados não são guardados; as ilhas salvas não mudam |
| A Praia ganha arte gerada por script, como a do Deserto, e 4 decorações novas: conchas, estrela-do-mar, tronco à deriva e pedra de praia | A arte de hoje é provisória e de script |

## Fora do escopo

- Nadar com um Ecobeast.
- Deltas e cachoeiras no meio do rio.
- Correnteza ou animação própria do rio.
- Pontes de corda automáticas.

## Pré-requisitos

- [bridges](../bridges/): as pontes, o bloqueio da água e o corredor da ponte.
- [desert-snow](../desert-snow/): o ruído de temperatura e o caminho de um bioma novo.
- [nature-variety](../nature-variety/): as linhas 23 a 46 da folha de decorações.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-sea-and-beach](01-sea-and-beach.md) | O mar num lado do mapa e a Praia, no gerador, no catálogo, no editor e na arte | concluída (falta o dono conferir) |
| 2 | [02-lakes-and-rivers](02-lakes-and-rivers.md) | Os lagos e os rios que nascem dentro da terra | concluída (falta o dono conferir) |
| 3 | [03-crossings](03-crossings.md) | Os rios que atravessam, o vau e as pontes automáticas | concluída (falta o dono conferir) |
| 4 | [04-wide-rivers](04-wide-rivers.md) | Sem ilhotas, a Praia de 2 a 4 sem areia na foz, os rios de 2 a 4 de largura e os lagos redondos | concluída (falta o dono conferir) |

O desenho compartilhado está no [architecture.md](architecture.md).

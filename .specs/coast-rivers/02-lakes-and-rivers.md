# 02. Os lagos e os rios

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-sea-and-beach.md)

## Contexto

Com o mar no lugar, esta fase põe os lagos e os rios que nascem dentro da terra, como nos passos 4 a 7 do [desenho](architecture.md#o-gerador). Um rio que nasce dentro da terra não a corta, porque o Domador contorna a nascente, menos num estreito do recorte do mapa: ali, o lago ou o rio que partiria a terra é sorteado de novo.

## Requisitos

- **RF-01:** A altura de escoar (`drain`), como no passo 4, mais um ruído miúdo de ±0,04 (`MEANDER`), para o rio serpentear em vez de cortar em reta o plano que o enchimento deixa.
- **RF-02:** Os lagos, com `lakeCount`, `lakeMinSize` e `lakeMaxSize`, como no passo 5.
- **RF-03:** O Priority-Flood a partir do mar e dos lagos, como no passo 6.
- **RF-04:** Os rios, com `riverCount` e `springLakeChance`, como no passo 7, todos nascendo dentro da terra nesta fase.
- **RF-05:** Um lago, um lago pequeno ou um rio que partiria a terra em mais pedaços é desfeito e sorteado de novo (`landPieces`). O rio é `wshallow` e plano. Uma colina ou montanha no caminho vira água; a terra em volta continua como está.
- **RF-06:** O editor ganha "Lagos", "Tamanho mínimo do lago", "Tamanho máximo do lago", "Rios" e "Chance de nascer num lago".

## Critérios de aceite

- [x] Em 60 mapas, cada rio é uma linha de hexágonos vizinhos, sem voltar, e termina encostado no mar, num lago ou em outro rio.
- [x] Nenhum rio sobe: num terreno de teste com um buraco, o nível de saída nunca sobe no caminho, e o buraco é enchido até transbordar (`map-water.spec.ts`).
- [x] O número de lagos e de rios bate com os parâmetros, menos quando o mapa não tem lugar (o teste confere o limite, não a igualdade).
- [x] Há lagos sem rio e rios que nascem num lago pequeno.
- [x] Toda terra que um rio toca continua ligada à chegada (na fase 3, pelos vaus e pontes também).
- [x] Uma cena temporária mostra um mapa inteiro, e a captura é revisada.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [x] O `drain`, os lagos, o enchimento e os rios, com os testes.
- [x] Os parâmetros no editor.

## Resultado da verificação

Em 2026-11-15:

- **O código** fica em `server/src/domain/exploration/map-water.ts`: `drainOf`, `flowDown` (o Priority-Flood, com um heap e o empate para quem chegou antes), `placeLakes`, `placeRivers`, `descend` e `landPieces`.
- **O estreito:** a primeira versão deixava um rio passar pelo estreito entre dois lóbulos do mapa, e um teste achou 16 hexágonos de terra fora do alcance da chegada. Agora o lago ou o rio que aumentaria o número de pedaços de terra é desfeito e sorteado de novo.
- **O rio em reta:** o enchimento deixa os buracos planos, e o empate pelo caminho mais curto desenhava rios retos e paralelos. O ruído miúdo na altura de escoar os fez serpentear.
- **No mapa padrão** (10.000 hexágonos, 6 seeds): de 4 a 7 lagos (com os pequenos das nascentes), 5 rios de 5 a 69 hexágonos. O mapa saía em uns 250 ms; com a contagem de pedaços guardada entre uma água e outra e o mar crescendo por um heap, ficou em uns 150 ms (era uns 100 ms antes dos lagos e rios).
- **Testes:** os de `map-generator.spec.ts` (60 mapas de 900 hexágonos) e os de `map-water.spec.ts`. Os testes do mar da fase 1 passaram a separar o mar dos lagos e dos rios.
- **Uma cena temporária** (apagada) desenhou um mapa de 3.500 hexágonos tirado do gerador, e a captura foi revisada.
- **Não conferido:** o mapa sorteado com o jogo aberto.

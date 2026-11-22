# 01. A chegada no maior pedaço de terra

- **Status:** concluída
- **Depende de:** [coast-rivers](../coast-rivers/), [terrain-plateaus](../terrain-plateaus/)

## Contexto

O `startOf` de `server/src/domain/exploration/map-generator.ts` escolhia a chegada pelo hexágono de terra plano mais perto da origem (0,0). Quando o mar deixa um pedaço de terra solto perto da origem, a chegada cai nele, e nenhuma garantia de alcance que vem depois (o `placeCrossings`, que põe ponte sobre rio e lago, e o `openSlopes`, que abre encostas) atravessa o mar. Ver o [README](README.md).

Medição em 200 seeds (`index * 7919 + 1`, o `DEFAULT_MAP_CONFIG`, 10.000 hexágonos), contando a terra que se alcança da chegada a pé e pelas pontes:

| | Antes | Depois |
| --- | --- | --- |
| Chegadas que alcançam menos de 50% da terra | 2 (633.521: 1 hexágono; 1.544.206: 18%) | 0 |
| O pior alcance | 0,02% | 57% |
| Seeds com a chegada mudada | | 2 (só as duas ruins) |

O exemplo que achou o defeito, a seed 23.762 no clima Temperado (`climate: 1`), ia de 1 para 5.674 dos 6.312 hexágonos de terra. Os 25% a 45% que faltam nas seeds de pior alcance são terra que o mar separa de vez, longe da chegada.

## Escopo

- O `startOf` escolhe, entre os hexágonos de antes (terra plana, senão terra, senão a água), os do maior pedaço, e entre eles o mais perto da origem.
- No gerador, só o mar separa os pedaços: o rio e o lago contam como ligados, porque o `placeCrossings` os atravessa depois, a partir da chegada.

## Fora do escopo

- A terra que o mar separa da chegada continua sem caminho: ponte sobre o mar, ou tirar esses pedaços do mapa, fica para outra fase, se o dono quiser.
- A ilha vulcânica, que escolhe a chegada pelo `map-volcanic-island.ts`, sem o `startOf`.
- As ilhas publicadas, que têm a chegada pintada no F2.

## Requisitos

- **RF-01:** a chegada do mapa sorteado fica no maior pedaço de hexágonos fora do mar, ligados por vizinhos.
- **RF-02:** dentro desse pedaço, vale a regra de antes: terra plana, senão terra, e a mais perto da origem.
- **RF-03:** quando a chegada de antes já estava no maior pedaço, ela não muda, e o mapa da seed fica igual.

## Critérios de aceite

- [x] Na seed 23.762 com `climate: 1`, a chegada alcança mais da metade da terra (o teste em `map-generator.spec.ts`).
- [x] Um pedaço de 1 hexágono mais perto da origem perde para um de 3 mais longe (o teste de unidade do `startOf`).
- [x] Nas 200 seeds medidas, toda chegada alcança mais da metade da terra.
- [x] Os 5 mapas presos pelo `map-glacier.spec.ts` não mudaram; dos 5 do `map-volcano.spec.ts`, só o da seed 418.927 mudou.

## Desenho técnico

- `server/src/domain/exploration/map-generator.ts`: o `startOf` ganha o segundo parâmetro `joins`, que diz quais hexágonos formam os pedaços (o padrão é a terra, para quem o chama sem o mapa inteiro), e o `pieceSizes` conta o tamanho do pedaço de cada um. O `generateShapedMap` passa `(cell) => !cell.sea`.
- `server/src/domain/exploration/map-volcano.spec.ts`: o hash da seed 418.927 muda. Nela o mar corta a terra quase ao meio, e a chegada passa da parte de 2.984 hexágonos alcançáveis para a de 3.341, dos 6.364 de terra.

## Verificação

```bash
cd server
npm run lint && npm run typecheck && npm test && npm run test:e2e
```

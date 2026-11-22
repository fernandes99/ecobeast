# start-island

No mapa sorteado, a chegada do Domador nunca cai num pedaço de terra isolado pelo mar.

## Contexto

Em 2026-11-22, durante a [volcano](../volcano/), apareceu um mapa em que o Domador não andava para lugar nenhum: `generateMap(23762, { ...DEFAULT_MAP_CONFIG, climate: 1 })` põe a chegada em (0,0), um hexágono de Praia na beira de baixo do mapa, com Água rasa acima e nada nos outros lados, e dela se alcança 1 hexágono de 6.312 de terra. O defeito vem de antes do vulcão.

A causa é o `startOf` de `server/src/domain/exploration/map-generator.ts`, que escolhia o hexágono de terra plano mais perto da origem sem olhar se ele está ligado ao resto da terra. O mar, crescido da borda com a costa irregular, às vezes deixa um pedacinho de terra solto entre ele e a beira do mapa, e a origem cai ali. As duas garantias de alcance que vêm depois partem da chegada e não resolvem: o `placeCrossings` (`map-water.ts`) só põe ponte sobre rio e lago, e o `openSlopes` (`map-slopes.ts`) só abre encostas, sem atravessar água.

## Fases

| #   | Fase                                         | Status    |
| --- | -------------------------------------------- | --------- |
| 1   | [01-start-piece](01-start-piece.md)          | concluída |

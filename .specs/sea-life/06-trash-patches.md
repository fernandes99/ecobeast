# 06. O lixo numa mancha pequena

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02](02-sea-zones.md), [biome-zones/01](../biome-zones/01-zone-records.md)

## Contexto

Em 2026-11-20, o dono pediu: "as zonas de lixo devem ficar próximas uma da outra e ser uma zona pequena. Bem raramente vai ter zona de lixo nas lagoas e água rasa."

Até aqui, o Lixo da Água rasa e o da Água profunda eram faixas do ruído das zonas, como as outras zonas, com 8% de cada água. Por isso apareciam em vários pedaços espalhados, também nos lagos e nos rios.

Os números e o jeito de achar o mar mudaram na [07](07-lakes-and-trash.md): o mar é o que não é lago nem rio, e a mancha sai em todo mapa com mar.

## Escopo

- O `assignZones` (`server/src/domain/exploration/map-zones.ts`) tira as duas zonas de lixo das faixas e as põe em manchas, com um sorteio próprio (`PATCH_SALT`), sem mudar as outras zonas nem o terreno.
- A migration `trash_patches`, que põe o `share` das zonas 27 e 30 em 0, porque a parte delas não vale mais.

## Requisitos

- **RF-01:** A água do mapa se divide em pedaços ligados. O mar é o maior pedaço que toca a borda do mapa, com pelo menos 40 hexágonos; os outros são os lagos e os rios soltos.
- **RF-02:** No mar, com 75% de chance por mapa, nasce uma mancha de 8 hexágonos, crescida a partir de um hexágono de Água profunda vizinho da Água rasa. Assim, a parte rasa e a funda do lixo ficam juntas. Cada hexágono da mancha fica com o Lixo do seu bioma.
- **RF-03:** Em cada lago ou rio solto, com 4% de chance, nasce uma mancha de 3 hexágonos.
- **RF-04:** Os números ficam em constantes do `map-zones.ts` (_a revisar_): `SEA_MIN_TILES` 40, `SEA_PATCH_CHANCE` 0,75, `SEA_PATCH_TILES` 8, `LAKE_PATCH_CHANCE` 0,04 e `LAKE_PATCH_TILES` 3.
- **RF-05:** Nas ilhas, nada muda: o dono pinta as zonas no F2.

## Critérios de aceite

- [ ] O dono vê, no mapa sorteado, o lixo numa mancha só, perto da costa.
- [x] O `map-zones-patches.spec.ts`, em 24 seeds: toda mancha tem até 8 hexágonos e só água; o mar tem no máximo uma mancha grande, com a parte rasa e a funda juntas em mais de um terço dos mapas; as manchas fora do mar são raras; as outras zonas e o terreno não mudam, e a mesma seed repete.
- [x] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [x] As manchas no `assignZones`.
- [x] Os testes.
- [x] A migration, aplicada no banco.

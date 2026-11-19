# 01. As tabelas, as zonas no gerador e quem nasce por zona

- **Status:** concluída
- **Depende de:** [biome-encounters](../biome-encounters/), [day-phase-spawns](../day-phase-spawns/), [coast-rivers](../coast-rivers/)

## Contexto

Ver o [README](README.md#contexto). Esta fase é só do servidor e do catálogo: depois dela, o mapa sorteado já manda a zona de cada hexágono e sorteia os Ecobeasts por zona. As plantas só mudam na [fase 02](02-zone-plants.md).

## Escopo

- As tabelas `biome_zones` e `species_biome_zones`, na migration e no seed, e as duas no `GET /v1/catalog`.
- As zonas no mapa sorteado de Explorar e no gerador do F2.
- O sorteio dos selvagens do mapa sorteado por zona.

## Fora do escopo

- As ilhas guardarem a zona (fase 03).
- As equipes dos Domadores NPC e o Ecobeast posto pelo debug: continuam pela taxa do bioma.

## Requisitos

- **RF-01:** A migration `biome_zones` cria `biome_zones`:

| Coluna | Tipo | Observação |
| --- | --- | --- |
| id | int | |
| slug | text | CHECK `^[a-z0-9_]+$`, único |
| biome_id | int | FK → biomes |
| name | text | CHECK 1–40 caracteres |
| share | int | CHECK 0–100: a parte do bioma no mapa sorteado, dividida pela soma das zonas do bioma; 0 só aparece pintada numa ilha |
| sort_order | int | a ordem das manchas no mapa sorteado, dentro do bioma |

A zona Comum de um bioma é a linha com o mesmo slug do bioma.

- **RF-02:** A mesma migration insere as 24 zonas (_a revisar_: os nomes, as partes e a ordem):

| id | slug | bioma | name | share | sort_order |
| --- | --- | --- | --- | ---: | ---: |
| 1 | `temperate` | Planície | Comum | 40 | 3 |
| 2 | `boreal` | Boreal | Comum | 40 | 3 |
| 3 | `stone` | Pedra | Comum | 40 | 1 |
| 4 | `hill` | Colina | Comum | 40 | 2 |
| 5 | `mountain` | Montanha | Comum | 100 | 1 |
| 6 | `wshallow` | Água rasa | Comum | 100 | 1 |
| 7 | `wdeep` | Água profunda | Comum | 100 | 1 |
| 8 | `desert` | Deserto | Comum | 40 | 2 |
| 9 | `snow` | Neve | Comum | 40 | 2 |
| 10 | `beach` | Praia | Comum | 100 | 1 |
| 11 | `wford` | Vau | Comum | 100 | 1 |
| 12 | `temperate_clearing` | Planície | Clareira | 15 | 1 |
| 13 | `temperate_meadow` | Planície | Campo florido | 15 | 2 |
| 14 | `temperate_shrubland` | Planície | Arbustal | 15 | 4 |
| 15 | `temperate_woods` | Planície | Bosque | 15 | 5 |
| 16 | `boreal_clearing` | Boreal | Clareira | 30 | 1 |
| 17 | `boreal_ferns` | Boreal | Samambaial | 30 | 2 |
| 18 | `hill_scree` | Colina | Pedregal | 30 | 1 |
| 19 | `hill_dry_brush` | Colina | Mato seco | 30 | 3 |
| 20 | `stone_crags` | Pedra | Rochedo | 60 | 2 |
| 21 | `desert_dunes` | Deserto | Dunas | 30 | 1 |
| 22 | `desert_cacti` | Deserto | Cactal | 30 | 3 |
| 23 | `snow_field` | Neve | Campo de neve | 30 | 1 |
| 24 | `snow_pines` | Neve | Pinheiral nevado | 30 | 3 |

- **RF-03:** A migration cria `species_biome_zones` (chave `species_id`, `biome_zone_id`; `rate_percent` int, CHECK 0–1000) e insere as exceções abaixo, cada uma só se a espécie existir (_a revisar_). O seed (`biome_zones.json`, `species_biome_zones.json`) tem as zonas e as exceções das espécies que estão no seed.

| Espécie | Zona | rate_percent |
| --- | --- | ---: |
| 1 Ruvo | Mato seco, Dunas, Bosque | 200, 150, 50 |
| 2 Ruvak | Pedregal, Rochedo | 200, 150 |
| 7 Seedlet | Bosque, Samambaial, Clareira da Planície | 200, 200, 50 |
| 8 Grovequill | Bosque | 200 |
| 15 Puffcoo | Clareira da Planície, Campo florido, Clareira do Boreal, Bosque | 200, 200, 200, 50 |
| 16 Galecrest | Campo florido | 150 |

- **RF-04:** `biome_zones` e `species_biome_zones` entram em `CATALOG_TABLES`, depois de `biomes`, e no `catalog_schema.gd` do cliente. O `CatalogValidator` confere que todo bioma tem a zona Comum.
- **RF-05:** `assignZones(tiles, seed, zones, config)`, em `server/src/domain/exploration/map-zones.ts`, põe `zone` (o slug) nos hexágonos de um mapa já gerado, sem mudar mais nada do mapa:
  - um ruído próprio, de `seededRandom(seed ^ ZONE_SALT)`, na escala `config.noiseScale × ZONE_SCALE` (`ZONE_SCALE` 2, _a revisar_: manchas menores que as dos biomas);
  - para cada bioma com zonas de `share` acima de 0, os hexágonos do bioma ordenados pelo ruído (no empate, por `q` e depois `r`) e divididos em faixas, na ordem de `sort_order`, com o tamanho de cada faixa proporcional ao `share`;
  - o hexágono que cai na Comum fica sem `zone`.
- **RF-06:** A entrada no mapa sorteado (`POST /v1/me/exploration`) e o gerador do F2 (`map-generator.controller.ts`) chamam `assignZones` com as zonas do banco. `MapTileDto` ganha `zone?: string`, que só aparece fora da Comum.
- **RF-07:** O sorteio do mapa sorteado (`rollSpawns`) junta os hexágonos por zona (`tile.zone ?? tile.biome`), no lugar do bioma. A taxa de uma espécie numa zona é `rate × rate_percent / 100`, com `rate` de `species_biomes` no bioma da zona e `rate_percent` 100 quando não há linha em `species_biome_zones`. O resto do sorteio ([biome-encounters/architecture.md](../biome-encounters/architecture.md#sorteio-do-mapa)) não muda.
- **RF-08:** `loadSpawnSpecies` lê as exceções para o sorteio do mapa; as equipes dos Domadores NPC continuam pela taxa do bioma.

## Critérios de aceite

- [x] Com as zonas do seed, cada zona fica com a parte dela no bioma, a até 1 hexágono da conta exata, e a Montanha, a Praia e as águas ficam sem zona.
- [x] O mapa de uma seed tem o mesmo bioma, a mesma altura, a mesma variante e as mesmas pontes de antes, hexágono por hexágono.
- [x] A mesma seed dá as mesmas zonas.
- [x] Sem nenhuma linha em `species_biome_zones`, o peso de cada espécie em cada bioma é igual ao de antes, somando as zonas.
- [x] Uma espécie com `rate_percent` 0 numa zona não nasce nela; com 200, o peso dela na zona dobra.
- [x] `GET /v1/catalog` leva as duas tabelas, e o jogo abre sem erro do `CatalogValidator`.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Desenho técnico

- `server/prisma/migrations/<data>_biome_zones/migration.sql` à mão, em LF, e `prisma migrate deploy`, como nas migrations de antes.
- `server/prisma/schema.prisma`: `BiomeZone`, `SpeciesBiomeZone`, e as relações em `Biome` e `Species`.
- `server/src/domain/exploration/map-zones.ts` (novo) e `map-zones.spec.ts`.
- `server/src/domain/exploration/spawns.ts`: `SpawnSpecies.zoneRates` (`Partial<Record<string, number>>`, em %), o grupo por zona e os testes em `spawns.spec.ts`.
- `server/src/exploration/spawn-data.ts`, `exploration.service.ts`, `exploration.dto.ts` e `server/src/editor/map-generator.controller.ts`.
- `server/src/catalog/catalog-tables.ts` e o teste; `client/core/data/catalog_schema.gd` e o `CatalogValidator`.
- `.specs/game-data/architecture.md`: as duas tabelas, depois de `species_biomes`.

## Tarefas

- [x] Migration, schema, seed e os CHECKs no `database.e2e-spec.ts`.
- [x] `assignZones`, a entrada no mapa e o gerador do F2.
- [x] O sorteio por zona.
- [x] O catálogo, o `catalog_schema.gd`, o validador e o `game-data/architecture.md`.

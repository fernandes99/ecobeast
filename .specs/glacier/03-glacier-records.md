# 03. A Geleira no catálogo

- **Status:** concluída (falta o dono conferir a amostra no F2)
- **Depende de:** [01](01-glacier-art.md) e de a [rolling-hills](../rolling-hills/) estar commitada

## Contexto

O servidor aceita um bioma pelas listas `BIOMES` e `SHAPED_BIOMES` do `server/src/domain/exploration/map-generator.ts`, usadas pelas rotas do mapa, das ilhas e do editor. O `terrainOf` dá o bioma do catálogo pela forma. Na Colina, o Deserto, a Neve e a Praia ficam no próprio bioma.

Esta fase esperava a `rolling-hills` ser commitada, porque o `map-generator.ts` tinha mudanças dela sem commit. Ela foi commitada (`b018e8a`).

## Requisitos

- **RF-01:** A migration `glacier`:
  - insere o bioma 12 `glacier` "Geleira", com a descrição "Chão de gelo liso e duro, onde até a neve escorrega.";
  - insere a zona Comum 35 `glacier`, com o `share` 100, por ser a única da Geleira;
  - insere as zonas Lago gelado 36 `wshallow_ice_lake` (bioma 6) e 37 `wdeep_ice_lake` (bioma 7), com `share` 0, como as do Lago;
  - insere as taxas `species_biomes` do Hushling (10) 30 e do Echofrost (11) 10, só se a espécie existir;
  - acerta as sequências.
- **RF-02:** `glacier` entra em `BIOMES` e em `SHAPED_BIOMES`. O `terrainOf('glacier', 'hill')` dá `glacier`, como a Neve. Nos testes do gerador, a lista `RARE_BIOMES` tira a Geleira dos que exigem todo bioma de terra em mais de 10% dos mapas: ela ainda não nasce, e depois da [04](04-generated-glacier.md) é rara de propósito.
- **RF-03:** No F2, `glacier` entra em `editor_tools.gd`, em `BIOMES` (logo depois de `snow`) e no nome "Geleira", e a amostra usa a superfície da [01](01-glacier-art.md).
- **RF-04:** Uma ilha salva com hexágonos `glacier`, e com os da água na zona Lago gelado, volta igual em Ilhas.

## Critérios de aceite

- [x] O catálogo (`GET /v1/catalog`) tem o bioma 12, as zonas 35 a 37 e as duas taxas.
- [x] Um teste e2e das rotas do editor salva e lê uma ilha com `glacier` e com a água na zona Lago gelado.
- [x] Um teste de unidade: `terrainOf('glacier', 'hill')` é `glacier`, e `terrainOf('glacier', 'mont')` é `mountain`.
- [x] Um mapa sorteado de uma seed é igual ao de antes, hexágono por hexágono (a Geleira ainda não nasce nele). Conferido em 40 seeds contra o `map-generator.ts` do commit anterior, numa comparação temporária.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam, menos 2 testes do `seed.e2e-spec.ts` (`species_day_phases` e `species_skills`), que falham porque a linha do Seedlet (espécies 7 a 9) mudou no banco fora desta iniciativa e a foto do `seed-data` não acompanha.

## Tarefas

- [x] A migration (`20270201000002_glacier`), aplicada no banco.
- [x] As listas e o `terrainOf`, com os testes.
- [x] A amostra no F2.

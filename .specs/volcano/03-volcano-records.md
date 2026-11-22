# 03. O Vulcão e a lava no catálogo

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [01](01-volcano-art.md)

## Contexto

O servidor aceita um bioma pelas listas `BIOMES` e `SHAPED_BIOMES` do `server/src/domain/exploration/map-generator.ts`, que as rotas do mapa, das ilhas e do editor usam. O `terrainOf` dá o bioma do catálogo pela forma. A água fica só em `BIOMES` e é sempre plana. O `isWater` e o `blocksWalking` dizem o que é água e o que bloqueia o andar. Hoje os dois têm a mesma lista.

## Requisitos

- **RF-01:** A migration `volcano`:
  - insere os biomas 13 `volcano` "Vulcão", 14 `lshallow` "Lava rasa" e 15 `ldeep` "Lava funda", com as descrições:
    - Vulcão: "Rocha escura e quente, que ainda guarda o fogo de baixo da terra.";
    - Lava rasa: "Rocha derretida que escorre devagar e brilha no escuro.";
    - Lava funda: "O coração do vulcão, quente demais para chegar perto.";
  - insere a zona Comum de cada um (38 a 40), com o `share` 100;
  - insere as taxas `species_biomes` no Vulcão: Ruvo (1) 20, Ruvak (2) 30 e Ruvaroth (3) 15, só se a espécie existir;
  - acerta as sequências.

  Os ids são conferidos no banco antes.
- **RF-02:** `volcano`, `lshallow` e `ldeep` entram em `BIOMES`. O `volcano` também entra em `SHAPED_BIOMES`: o `terrainOf('volcano', 'hill')` dá `volcano`, e o `terrainOf('volcano', 'mont')` dá `volcano`. O vulcão tem a altura dele e não vira Montanha.
- **RF-03:** O `blocksWalking` passa a incluir a lava, e o `isWater` não. Onde o servidor usa o `isWater` para decidir o andar, o encontro ou o nascimento, ele passa a usar o `blocksWalking`, ou o que fizer sentido em cada caso: o Procurar não enfrenta nada na lava, e nenhum Ecobeast nem Domador NPC nasce nela. O construtor confere cada uso.
- **RF-04:** Nos testes do gerador, a lista `RARE_BIOMES` passa a ter os três: eles ainda não nascem, e depois das [04](04-land-volcano.md) e [05](05-volcanic-island.md) são raros de propósito.
- **RF-05:** No F2, os três entram em `editor_tools.gd`: em `BIOMES` (o Vulcão depois da Geleira, e a lava depois da água) e nos nomes. As amostras usam as superfícies da [01](01-volcano-art.md).
- **RF-06:** Uma ilha salva com hexágonos de Vulcão e de lava volta igual em Ilhas, e o Domador não anda na lava dela.
- **RF-07:** Uma luta aberta num hexágono de Vulcão usa o chão do Vulcão no tabuleiro.

## Critérios de aceite

- [x] O catálogo (`GET /v1/catalog`) tem os biomas 13 a 15, as zonas 38 a 40 e as três taxas (migration `20270202000001_volcano`, aplicada).
- [x] Um teste e2e das rotas do editor salva e lê uma ilha com `volcano`, `lshallow` e `ldeep`.
- [x] Testes de unidade: o `terrainOf` do Vulcão; o `blocksWalking` é verdadeiro na lava, e o `isWater` falso; a chegada na lava é recusada.
- [x] Um mapa sorteado de uma seed é igual ao de antes, hexágono por hexágono (o vulcão ainda não nasce). Conferido pelo teste de hash de 5 seeds do `map-glacier.spec.ts`, que passa sem mudança; a comparação de 40 seeds não foi feita.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e os e2e do editor e do catálogo passam. A suíte e2e inteira (rodada na fase 1) tem 3 falhas de fora: as 2 do `seed.e2e-spec.ts`, já conhecidas, e a contagem de tabelas da iniciativa dos contadores, em andamento em outra sessão.

## Tarefas

- [x] A migration, aplicada no banco.
- [x] As listas, o `terrainOf`, o `isLava` e o `blocksWalking`, e os usos do `isWater` que são do andar (as pontas de ponte, os NPCs, a chegada, os Domadores NPC e o alcance das pedras), com os testes.
- [x] As amostras no F2.

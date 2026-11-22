# 03. O Vulcão e a lava no catálogo

- **Status:** pendente
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

- [ ] O catálogo (`GET /v1/catalog`) tem os biomas 13 a 15, as zonas 38 a 40 e as três taxas.
- [ ] Um teste e2e das rotas do editor salva e lê uma ilha com `volcano`, `lshallow` e `ldeep`.
- [ ] Testes de unidade: o `terrainOf` do Vulcão; o `blocksWalking` é verdadeiro na lava, e o `isWater` falso.
- [ ] Um mapa sorteado de uma seed é igual ao de antes, hexágono por hexágono (o vulcão ainda não nasce). Conferido em 40 seeds contra o `map-generator.ts` do commit anterior, numa comparação temporária.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [ ] A migration, aplicada no banco.
- [ ] As listas, o `terrainOf`, o `blocksWalking` e os usos do `isWater`, com os testes.
- [ ] As amostras no F2.

# 05. A ilha vulcânica

- **Status:** concluída (falta o dono aprovar a prévia e conferir no jogo)
- **Depende de:** [04](04-land-volcano.md) (o perfil do cone, as escadarias e os picos)

## Contexto

O mapa sorteado de hoje tem o mar num lado só (`placeSea`, crescido a partir da borda), com a Praia na costa, lagos, rios e as montanhas pelo relevo. A ilha vulcânica é um mapa de outro tipo: o oceano em volta de tudo e o vulcão como o centro da terra, com só um pouco de floresta e praia no pé. Ela é a forma mais rara e a mais diferente, a do "nossa, que diferente!" do dono.

## Na implementação

Com o contorno recortado do mapa sorteado (`edgeRoughness` 200), o meio do mapa fica perto da beira, e a ilha cabia com só 9% a 32% de terra. Por isso, em 2026-11-22, o mapa da ilha vulcânica usa o contorno sem recorte (`edgeRoughness` 0, um hexágono), com o mesmo número de hexágonos. Os mapas comuns não mudam, porque o sorteio da ilha é próprio.

## Requisitos

- **RF-01:** O parâmetro `volcanoIslandChance`, padrão 0,02, faixa de 0 a 1, em `MAP_CONFIG_RANGES` e no gerador da ilha nova do F2. Com ele em 0, o mapa de uma seed é igual ao de antes; com ele em 1, todo mapa é uma ilha vulcânica.
- **RF-02:** O sorteio da ilha (`rollsVolcanicIsland`, e `isVolcanicIsland(seed, config)` para medir sem gerar o mapa):
  - vem de um sorteio próprio a partir da seed (`VOLCANIC_ISLAND_SALT`), antes do contorno do mapa;
  - roda sempre, independente do vulcão em terra; quando a ilha sai, o `placeVolcano` não roda;
  - não sai com o `climate` fixado em Frio. Com outro `climate`, a ilha sai do mesmo jeito: o cinto é de Planície e Boreal, como no clima Úmido.
- **RF-03:** A forma (`shapeVolcanicIsland`, em `map-volcanic-island.ts`):
  - o centro é o hexágono mais longe da beira do mapa;
  - a terra é uma ilha só, mais ou menos redonda (a costa entorta até 10% do raio, em 10 pontos), com o raio buscado até a terra dar a parte sorteada, de 45% a 60% do mapa, sem chegar perto da beira (fica pelo menos a água rasa e mais 2 hexágonos de mar);
  - o resto é oceano, com a Água rasa até `shallowWidth` da terra e a funda depois;
  - não há lagos, rios, pontes, ilhotas, Montanha nem Colina.
- **RF-04:** A terra, de fora para dentro:
  - **a Praia** na costa, de `beachMinWidth` a `beachMaxWidth` hexágonos, na altura 1;
  - **o cinto de floresta:** Boreal na parte mais úmida (umidade acima de 0,45) e Planície no resto, na altura 1, com pelo menos 3 hexágonos entre a Praia e o cone;
  - **o vulcão:** o cone da [04](04-land-volcano.md) (`buildCone`), no centro, com 40% a 60% da área da terra, limitado pela costa mais perto.
- **RF-05:** O cone da ilha tem a cratera em 35% do raio (no lugar de 50%), para o lago de lava não tomar a cratera inteira. O pé dele fica no 1, então a encosta tem os patamares 4 e 7, cada um um anel largo e andável.
- **RF-06:** São 3 ou 4 escadarias, com as regras da [04](04-land-volcano.md). Os picos de basalto e as rachaduras de lava também; a chance de pico na encosta caiu para 0,04 nas duas formas, porque a encosta grande da ilha ficava coberta de picos.
- **RF-07:** A chegada fica no meio do cinto de floresta, num ângulo sorteado. Toda a terra de fora do cone se alcança dela, e o piso da cratera também, pelas escadarias.
- **RF-08:** Os Ecobeasts e os Domadores NPC nascem por bioma, como em todo mapa.

## Critérios de aceite

- [x] Testes de unidade (`map-volcanic-island.spec.ts`, em 4 mapas do tamanho do jogo com a ilha forçada):
  - em 4.000 seeds, de 1% a 3,5% saem como ilha vulcânica (pelo `isVolcanicIsland`), e nenhuma com o `climate` em Frio;
  - a terra é um pedaço só, e a água também; a beira do mapa é toda água; sem lago, rio nem ponte;
  - só há água, Praia, Planície, Boreal, Vulcão e lava, tudo plano;
  - toda terra na costa é Praia, e o cone fica a mais de 3 hexágonos da Praia;
  - a terra é de 45% a 62% do mapa, e o cone, de 35% a 62% da terra;
  - o cone tem a borda no 10, o piso no 6 e a lava no 5;
  - a chegada fica no cinto, toda a terra de fora do cone e o piso se alcançam dela, há pelo menos 3 escadarias, e sem elas a borda não se alcança.
- [x] Com o `volcanoIslandChance` em 0 (e o `volcanoChance` em 0), o hash do mapa de 5 seeds é o do commit da [03](03-volcano-records.md) (no `map-volcano.spec.ts`).
- [ ] A prévia das 3 ilhas vistas de cima (seeds 140, 185 e 197, com os parâmetros padrão) e de um vulcão em terra (seed 61) aprovada pelo dono.
- [x] Um e2e gera pelo F2 uma ilha vulcânica.
- [ ] O dono confere no jogo uma ilha vulcânica, pela seed 140 no F2 ou pelo `volcanoIslandChance` em 1.
- [x] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [x] O parâmetro e o sorteio da ilha.
- [x] A forma da ilha: o oceano, a praia e o cinto de floresta.
- [x] O cone grande, com a cratera menor, as escadarias e os picos.
- [x] A prévia para o dono, o parâmetro no F2 e o e2e.

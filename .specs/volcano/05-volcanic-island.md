# 05. A ilha vulcânica

- **Status:** pendente
- **Depende de:** [04](04-land-volcano.md) (o perfil do cone, as escadarias e os picos)

## Contexto

O mapa sorteado de hoje tem o mar num lado só (`placeSea`, crescido a partir da borda), com a Praia na costa, lagos, rios e as montanhas pelo relevo. A ilha vulcânica é um mapa de outro tipo: o oceano em volta de tudo e o vulcão como o centro da terra, com só um pouco de floresta e praia no pé. Ela é a forma mais rara e a mais diferente, a do "nossa, que diferente!" do dono.

## Requisitos

- **RF-01:** Os parâmetros novos em `MAP_CONFIG_RANGES` e no gerador da ilha nova do F2:

  | Parâmetro | Padrão | Faixa |
  | --- | --- | --- |
  | `volcanoIslandChance` | 0,02 | 0 a 1 |

  Com ele em 0, o mapa de uma seed é igual ao de antes, hexágono por hexágono. Com ele em 1, todo mapa é uma ilha vulcânica, para o dono testar no F2.
- **RF-02:** O sorteio da ilha:
  - vem de um sorteio próprio a partir da seed (`VOLCANIC_ISLAND_SALT`), que roda sempre, independente do sorteio do vulcão em terra (`VOLCANO_SALT`), que também roda sempre;
  - quando os dois saem, a ilha vence, e o `placeVolcano` da [04](04-land-volcano.md) não roda. Assim, com o `volcanoIslandChance` em 0, os mapas da [04](04-land-volcano.md) não mudam;
  - a ilha vulcânica sempre tem o clima Úmido, menos com o `climate` fixado em `cold` pelo parâmetro: aí ela não sai, porque o vulcão nunca sai no Frio. Com outro `climate` fixado, ela sai Úmida mesmo assim.
- **RF-03:** A forma do mapa:
  - o contorno do mapa (`growRegion`) é o mesmo;
  - a terra é uma ilha só, mais ou menos redonda, no meio do mapa, com a costa irregular. Ela ocupa de 45% a 60% do mapa;
  - o resto é oceano, com a Água rasa junto da costa e a funda depois, como o mar de hoje (`shallowWidth`);
  - não há lagos, rios nem pontes, e a ilha não tem ilhotas em volta.
- **RF-04:** A terra, de fora para dentro:
  - **a Praia** na costa, de `beachMinWidth` a `beachMaxWidth` hexágonos, na altura 1;
  - **o cinto de floresta**: Planície e Boreal (pelo ruído de umidade do clima), nos patamares 1 e 4, com as decorações e as zonas de sempre. Ele tem pelo menos 3 hexágonos de largura em toda volta;
  - **o vulcão**: o cone da [04](04-land-volcano.md), centrado na ilha, ocupando de 40% a 60% da terra. O raio sai do tamanho da terra, e a cratera e o lago de lava crescem junto.

  A ilha não tem Montanha, Colina, Pedra, Neve, Deserto nem Geleira fora do vulcão.
- **RF-05:** A encosta de um cone grande tem mais patamares (os paredões continuam com 3 ou mais níveis cada), e os patamares ficam mais largos, cada um um anel andável. Como a altura vai só até 10, o construtor decide quantos patamares cabem e a largura de cada um. O cone continua com a borda em 9 e 10 e o piso da cratera no 6.
- **RF-06:** São 3 ou 4 escadarias, espalhadas em volta do cone, com as regras da [04](04-land-volcano.md). Os picos de basalto seguem a mesma regra.
- **RF-07:** A chegada fica no cinto de floresta ou na praia. Toda a terra e o anel do piso da cratera se alcançam da chegada.
- **RF-08:** Os Ecobeasts nascem por bioma como em todo mapa: os da Planície, do Boreal e da Praia no pé, a linha do Ruvo no Vulcão e os da água no oceano. Os Domadores NPC também nascem como sempre, fora da lava e dos picos.

## Critérios de aceite

- [ ] Testes de unidade (`map-volcanic-island.spec.ts`):
  - Em 1.000 seeds, de 1% a 3,5% saem como ilha vulcânica.
  - A terra é uma ilha só, cercada de água, sem lago, rio nem ponte.
  - A ordem de fora para dentro é água, Praia, floresta e Vulcão, e o Vulcão ocupa de 40% a 60% da terra.
  - O cone tem a borda em 9 e 10, o piso no 6 e a lava só dentro da cratera.
  - Tirando os hexágonos das escadarias, a borda não se alcança do pé. Com elas, o anel do piso se alcança da chegada.
- [ ] Com o `volcanoIslandChance` em 0, o hash do mapa de 5 seeds é igual ao de antes, tirado do `map-generator.ts` do commit da [04](04-land-volcano.md).
- [ ] Uma prévia de 3 ilhas vulcânicas, como imagem vista de cima, mostrada ao dono antes de fechar a fase. O jeito de gerar a imagem é escolha do construtor.
- [ ] Um e2e gera pelo F2 uma ilha vulcânica.
- [ ] O dono confere no jogo uma ilha vulcânica, pelo `volcanoIslandChance` em 1 no F2.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [ ] O parâmetro e o sorteio da ilha.
- [ ] A forma da ilha: o oceano, a praia e o cinto de floresta.
- [ ] O cone grande, com os patamares largos, as escadarias e os picos.
- [ ] A prévia para o dono, os parâmetros no F2 e o e2e.

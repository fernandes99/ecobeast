# 04. O vulcão em terra

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02](02-basalt-spires.md), [03](03-volcano-records.md), [glacier/04](../glacier/04-generated-glacier.md) (o caminho do sorteio próprio depois do `openSlopes`) e [terrain-plateaus](../terrain-plateaus/) (os paredões e as escadarias)

## Contexto

O gerador (`map-generator.ts`) faz, nesta ordem:

1. sorteia o clima (`climateOf`);
2. dá o relevo, as formas (`placeShapes`), a água (o mar, os lagos e os rios), o calor e o bioma de cada hexágono;
3. separa as vizinhanças proibidas (`separateBiomes`);
4. põe as alturas, as escadarias (`openRamps`), a garantia de alcance (`openSlopes`), as pontes, a Geleira (`placeGlacier`) e as pedras (`placeGiantRocks`, `placeIceRocks`).

A Geleira entra depois do `openSlopes`, com um sorteio próprio (`GLACIER_SALT`), e mexe só na mancha dela. Assim o resto do mapa da seed não muda. O vulcão segue o mesmo caminho.

A terra fica nos patamares 1, 4 e 7, e a Montanha de 8 a 10. O Domador sobe ou desce no máximo 2 níveis por passo (`MAX_CLIMB`).

## Na implementação

O primeiro desenho (o cone de raio 10 a 14 só em chão plano dos patamares 1 e 4) não cabia em nenhum mapa: os rios e os lagos picotam a terra, e o maior disco sem água, colina nem patamar 7 tinha raio de 7 a 10. Por isso, em 2026-11-22:

- o cone passa por cima de colinas e patamares, e só não cobre água, ponte, a chegada, a Montanha e o terreno de 8 para cima;
- o raio padrão vai de 7 a 12;
- a terra encostada no cone desce até o chão do pé (o 1 ou o 4), para o paredão do pé ter 3 níveis;
- a distância ao centro é em linha reta, e não pela grade, para o cone sair redondo, e não hexagonal;
- a cratera ocupa metade do raio, e a borda tem 2 hexágonos, para a encosta não virar uma mesa larga no 7.

## Requisitos

- **RF-01:** Os parâmetros novos em `MAP_CONFIG_RANGES` e no gerador da ilha nova do F2 (`new_island_panel.gd`):

  | Parâmetro | Padrão | Faixa |
  | --- | --- | --- |
  | `volcanoChance` | 0,07 | 0 a 1 |
  | `volcanoMinRadius` | 7 | 6 a 30 |
  | `volcanoMaxRadius` | 12 | 6 a 30 |

  O `volcanoMinRadius` não passa do `volcanoMaxRadius`. Com o `volcanoChance` em 0, o mapa de uma seed é igual ao de antes, hexágono por hexágono. Com ele em 1, todo mapa que não seja Frio e tenha lugar ganha o vulcão, para o dono testar no F2.
- **RF-02:** `placeVolcano(cells, climate, start, random, config, isBlocked)`, em `map-volcano.ts`:
  - **Quando roda:** depois do `openSlopes` e antes da Geleira, com um sorteio próprio a partir da seed (`VOLCANO_SALT`). Só os climas que não são `cold` entram.
  - **O sorteio:** decide se sai o vulcão, o raio (de `volcanoMinRadius` a `volcanoMaxRadius`) e o lugar.
  - **O lugar:** o centro de um disco de raio `R + 2` sem água, lava, ponte (`isBlocked`, as margens das pontes), Montanha, terreno de 8 para cima nem a chegada. O `clearance` (pela grade) separa os candidatos, e o escolhido é conferido em linha reta, porque o cone e a terra encostada nele vão até `R + 2` em linha reta, o que pela grade pode ser até `(R + 2) / 0,866` passos. Os 25% mais longe da borda do mapa são tentados primeiro, numa ordem sorteada.
  - **Na revisão final** (2026-11-22), o revisor achou que, só pela grade, um cone de raio 12 ou mais cobria água e rebaixava Montanha e terreno de 8; a conferência em linha reta veio daí, com o teste do cone grande.
  - **Sem lugar no raio sorteado:** o sorteio tenta raios menores, até o `volcanoMinRadius`. Se nenhum couber, o mapa fica sem vulcão.
  - **A raridade:** medida em 200 mapas do tamanho do jogo com o padrão 0,07: 7 vulcões, perto de 6% dos mapas que não são frios (3,5% de todos), com 290 hexágonos de cone em média; o vulcão forçado (`volcanoChance` 1) não achou lugar em 4 dos 118 mapas sem Neve. O padrão fica em 0,07.
- **RF-03:** O perfil do cone (`buildCone`), pela distância em linha reta ao centro, menos uma onda do sorteio próprio (8 pontos, até 1 hexágono, a mesma em todas as faixas, e sumindo perto do centro):
  - **A lava** (até a cratera menos 1,5): a Lava funda no meio, sempre com um anel de Lava rasa em volta, as duas na altura 5;
  - **o piso** (até metade do raio): altura 6, o anel de chão em volta da lava;
  - **a borda** (2 hexágonos depois da cratera): altura 10;
  - **a encosta de fora** (até `R`): os patamares de 3 em 3 níveis acima do pé, até o 7 (o 7 e o 4 no pé de 1, só o 7 no pé de 4), em faixas da mesma largura;
  - **o pé:** a terra encostada no cone desce até o chão do pé, o 1 se a metade dela está no 2 ou abaixo, senão o 4.

  Todo hexágono do cone é `volcano`, menos a lava. Os braços de lava e a borda no 9 ficaram de fora.
- **RF-04:** As escadarias (`carveVolcanoStairs`). São 2 ou 3, espalhadas em volta do cone (o ângulo de cada uma sai no `buildCone`). Cada uma segue a reta que sai do centro, do primeiro hexágono do piso até o primeiro de fora do cone: enquanto dois vizinhos da reta passarem de 2 níveis, o do cone muda para 1 ou 2 do outro (o mais alto desce, ou o degrau sobe quando o mais alto é o chão de fora). Ela é cavada depois da garantia de alcance da terra em volta, para o pé estar na altura final.
- **RF-05:** Os picos de basalto e as rachaduras de lava (`placeVolcanoRocks`, em `map-rocks.ts`, pelo `placeRocks` das pedras gigantes e com um sorteio próprio, `VOLCANO_ROCKS_SALT`):
  - os picos na borda (chance 0,33 por hexágono) e na encosta de fora (0,08);
  - as rachaduras nos patamares e no piso (1 a cada 30);
  - nunca numa escadaria nem fechando o caminho de ninguém.
- **RF-06:** Toda terra que se alcançava da chegada continua alcançável: depois do cone, a garantia de alcance (`openSlopes`) roda de novo, com um sorteio próprio (`VOLCANO_SLOPES_SALT`), sem entrar no cone. O piso da cratera se alcança da terra em volta pelas escadarias.
- **RF-07:** Fora do cone e da terra encostada nele, os biomas, a água, as pontes e a chegada são os do mesmo mapa sem o vulcão. A altura também, menos onde a garantia de alcance precisou subir um caminho (1 hexágono em 8 mapas medidos).
- **RF-08:** As zonas: o cone fica na zona Comum do Vulcão, e a lava na Comum dela.

## Critérios de aceite

- [x] Testes de unidade (`map-volcano.spec.ts`, em 6 mapas do tamanho do jogo, com o vulcão forçado):
  - pelo menos 80% ganham o vulcão; com o clima `cold`, nenhum;
  - a borda no 10, o piso no 6, a lava no 5, só encostando em lava ou no piso, e a funda só encostando em lava;
  - o piso se alcança da terra em volta; tirando as escadarias, nenhum hexágono da borda se alcança de fora;
  - toda terra que se alcançava continua alcançável;
  - fora do cone e da terra encostada nele, os biomas, a chegada e as pontes são os do mapa sem o vulcão;
  - os picos e as rachaduras ficam no cone, fora das escadarias, os picos fora do piso e as rachaduras fora da borda;
  - um cone grande (raio de 14 a 20, sem lagos nem rios) não cobre nem rebaixa água, Montanha ou terreno de 8 para cima (a seed 39.600 quebrava antes da conferência em linha reta);
  - com o `volcanoChance` em 0, o hash de 5 seeds é o do commit da [03](03-volcano-records.md) (conferido em 20 seeds contra uma cópia do código daquele commit).
- [x] A frequência medida em 200 mapas do tamanho do jogo (RF-02). Ela fica fora dos testes de unidade, porque 200 mapas levam perto de 2 minutos.
- [x] Nos testes do `map-generator.spec.ts`, o Vulcão e a lava estão em `RARE_BIOMES`, e a configuração deles desliga o vulcão.
- [x] Um e2e gera pelo F2 um mapa com o vulcão, a lava e os picos.
- [ ] O dono confere no jogo um vulcão de mapa sorteado, pelo `volcanoChance` em 1 no F2.
- [x] `npm run lint`, `npm run typecheck` e `npm test` passam.

Os testes de alcance partem da terra em volta do cone, e não da chegada: há mapas (como o da seed 23.762 no clima Temperado) em que a chegada cai numa faixa de Praia presa entre a água e a beira do mapa, com alcance de 1 hexágono, com ou sem vulcão. É um defeito do gerador de antes desta iniciativa.

## Tarefas

- [x] Os parâmetros e os testes da faixa.
- [x] O `placeVolcano`, o `buildCone` e o `carveVolcanoStairs`, com os testes.
- [x] Os picos de basalto e as rachaduras (`placeVolcanoRocks`).
- [x] Os parâmetros no gerador do F2, com o e2e.

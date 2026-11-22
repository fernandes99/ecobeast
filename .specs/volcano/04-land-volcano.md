# 04. O vulcão em terra

- **Status:** pendente
- **Depende de:** [02](02-basalt-spires.md), [03](03-volcano-records.md), [glacier/04](../glacier/04-generated-glacier.md) (o caminho do sorteio próprio depois do `openSlopes`) e [terrain-plateaus](../terrain-plateaus/) (os paredões e as escadarias)

## Contexto

O gerador (`map-generator.ts`) faz, nesta ordem:

1. sorteia o clima (`climateOf`);
2. dá o relevo, as formas (`placeShapes`), a água (o mar, os lagos e os rios), o calor e o bioma de cada hexágono;
3. separa as vizinhanças proibidas (`separateBiomes`);
4. põe as alturas, as escadarias (`openRamps`), a garantia de alcance (`openSlopes`), as pontes, a Geleira (`placeGlacier`) e as pedras (`placeGiantRocks`, `placeIceRocks`).

A Geleira entra depois do `openSlopes`, com um sorteio próprio (`GLACIER_SALT`), e mexe só na mancha dela. Assim o resto do mapa da seed não muda. O vulcão segue o mesmo caminho.

A terra fica nos patamares 1, 4 e 7, e a Montanha de 8 a 10. O Domador sobe ou desce no máximo 2 níveis por passo (`MAX_CLIMB`).

## Requisitos

- **RF-01:** Os parâmetros novos em `MAP_CONFIG_RANGES` e no gerador da ilha nova do F2 (`new_island_panel.gd`):

  | Parâmetro | Padrão | Faixa |
  | --- | --- | --- |
  | `volcanoChance` | 0,07 | 0 a 1 |
  | `volcanoMinRadius` | 10 | 6 a 30 |
  | `volcanoMaxRadius` | 14 | 6 a 30 |

  O `volcanoMinRadius` não passa do `volcanoMaxRadius`. Com o `volcanoChance` em 0, o mapa de uma seed é igual ao de antes, hexágono por hexágono. Com ele em 1, todo mapa que não seja Frio e tenha lugar ganha o vulcão, para o dono testar no F2.
- **RF-02:** `placeVolcano(cells, climate, start, random, config): Volcano | null`, num arquivo próprio (`map-volcano.ts`):
  - **Quando roda:** depois do `openSlopes` e antes da Geleira, com um sorteio próprio a partir da seed (`VOLCANO_SALT`). Só os climas que não são `cold` entram.
  - **O sorteio:** decide se sai o vulcão, o raio (de `volcanoMinRadius` a `volcanoMaxRadius`) e o lugar.
  - **O lugar:** o centro de um disco de raio `R + 2` todo de terra nos patamares 1 e 4, sem água, ponte, Montanha, Colina, terra no patamar 7 nem a chegada. Entre os lugares possíveis, o sorteio prefere os mais longe da borda do mapa. O jeito de achar e sortear os lugares é escolha do construtor.
  - **Sem lugar no raio sorteado:** o sorteio tenta raios menores, até o `volcanoMinRadius`. Se nenhum couber, o mapa fica sem vulcão e retorna `null`. O cone nunca passa por cima de água, ponte ou Montanha.
  - **A raridade:** o que vale é a parte dos mapas com vulcão, perto de 1 em 15 (de 5% a 8% dos mapas sem o clima Frio), e não a chance do sorteio. Se faltar lugar com frequência, o construtor sobe o padrão do `volcanoChance` até a parte medida cair nessa faixa e anota aqui o valor final.
- **RF-03:** O perfil do cone, pela distância `d` ao centro, com a borda de cada faixa ondulada por um ruído do sorteio próprio, para o cone não sair um hexágono perfeito:
  - **A cratera** (`d` até perto de 40% de `R`): piso na altura 6. No meio, a Lava funda; em volta dela, um anel de Lava rasa, as duas na altura 5, um nível abaixo do piso, como a água ([01](01-volcano-art.md)); e entre a lava e o paredão de dentro, um anel de chão de Vulcão de 1 a 2 hexágonos de largura, andável e todo ligado.
  - **A borda** (logo depois da cratera, de 1 a 2 hexágonos de largura): altura 10. Um hexágono da borda só fica no 9 se não encostar na encosta de fora, para a borda não se subir sem escadaria.
  - **A encosta de fora** (até `R`): desce em patamares de 7 e 4 (no chão de 4, só o 7), com paredões de 3 níveis entre eles.
  - **O pé:** o último anel do cone fica 3 níveis acima do chão de fora (o 4 sobre o chão de 1, o 7 sobre o chão de 4) e encosta nele com o paredão, menos nas escadarias. O anel de `R` a `R + 2` fica como estava: ele só garante a folga em volta do cone.

  Todo hexágono do cone é `volcano`, menos a lava. Às vezes saem braços de Lava rasa do lago até o pé do paredão de dentro, como as rachaduras da imagem do dono, sem quebrar o anel do piso em pedaços sem saída.
- **RF-04:** As escadarias. São 2 ou 3 por vulcão, espalhadas em volta do cone, com pelo menos 90° entre elas. Cada uma:
  - começa no chão de fora;
  - sobe a encosta até a borda em degraus de 1 e 2 níveis, com 1 hexágono de largura (2 onde precisar para a reta do passo);
  - desce por dentro até o anel do piso da cratera, também em degraus.

  Fora das escadarias, a encosta de fora e o paredão de dentro não se sobem a pé.
- **RF-05:** Os picos de basalto, `placeBasaltSpires`, ao lado do `placeGiantRocks` e com as mesmas regras (o `placeRocks`):
  - usa os tipos da [02](02-basalt-spires.md) e um sorteio próprio;
  - põe muitos picos na borda (perto de 1 a cada 3 hexágonos, a revisar) e poucos na encosta de fora (perto de 1 a cada 12, a revisar);
  - não põe pico numa escadaria, no anel do piso nem na lava.

  As pedras da Montanha não caem no Vulcão.
- **RF-05b:** As rachaduras de lava (`lava_crack`, a peça que bloqueia, da [01](01-volcano-art.md)), pelo mesmo `placeRocks`, com um sorteio próprio: poucas, nos patamares da encosta de fora e no anel do piso (perto de 1 a cada 15 hexágonos, a revisar), fora das escadarias, sem fechar o caminho de nenhuma terra nem pedaço do anel do piso.
- **RF-06:** Toda terra que se alcançava da chegada continua alcançável, e o anel do piso da cratera se alcança da chegada. A chegada não cai no cone.
- **RF-07:** Fora do disco do vulcão, os biomas, as alturas, a água, as pontes e as pedras são os do mesmo mapa sem o vulcão. A Geleira não sai num mapa com vulcão, porque o vulcão não sai no Frio.
- **RF-08:** As zonas: o cone fica na zona Comum do Vulcão, e a lava nas zonas Comum dela. O `assignZones` não espalha outras zonas por cima.

## Critérios de aceite

- [ ] Testes de unidade (`map-volcano.spec.ts`, em mapas do tamanho do jogo ou menores, como o construtor achar melhor):
  - Em 400 seeds sem o clima Frio e com o `volcanoIslandChance` em 0, de 5% a 8% saem com vulcão.
  - Com o clima `cold` fixado, nenhum mapa tem vulcão.
  - O cone tem o raio sorteado, a borda nas alturas 9 e 10, o piso no 6, a lava no 5 e só dentro da cratera, com a funda no meio e a rasa em volta.
  - Tirando os hexágonos das escadarias, a borda não se alcança do chão de fora, e o piso não se alcança da borda. Com elas, o anel do piso se alcança da chegada.
  - Nenhum pedaço do anel do piso fica sem saída.
  - Os picos só caem na borda e na encosta, fora das escadarias.
  - As rachaduras não fecham o caminho de nenhum pedaço do piso nem da encosta.
- [ ] Toda terra que se alcançava da chegada no mesmo mapa sem o vulcão continua alcançável, fora as pedras e os picos.
- [ ] Com o `volcanoChance` em 0, o hash do mapa de 5 seeds é igual ao de antes, tirado do `map-generator.ts` do commit da [03](03-volcano-records.md).
- [ ] Fora do disco, os biomas, as alturas, as pontes e as pedras são os do mesmo mapa sem o vulcão.
- [ ] Nos testes do `map-generator.spec.ts`, o Vulcão e a lava continuam em `RARE_BIOMES`. Os testes das pedras (`map-rocks.spec.ts`) e da Geleira geram os mapas com o `volcanoChance` em 0.
- [ ] Medido em 200 mapas do tamanho do jogo: quantos têm vulcão, o raio médio e quantos sorteios não acharam lugar. Os números entram nesta fase.
- [ ] Um e2e gera pelo F2 um mapa com o vulcão, a lava e os picos.
- [ ] O dono confere no jogo um vulcão de mapa sorteado, pelo `volcanoChance` em 1 no F2.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [ ] Os parâmetros e os testes da faixa.
- [ ] O `placeVolcano`: o lugar, o perfil, a lava e as escadarias, com os testes.
- [ ] Os picos de basalto (`placeBasaltSpires`).
- [ ] Os parâmetros no gerador do F2, com o e2e.

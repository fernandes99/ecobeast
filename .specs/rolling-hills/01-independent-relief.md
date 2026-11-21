# 01. A Montanha em maciços e a Colina em sorteio próprio

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [terrain-plateaus/02](../terrain-plateaus/02-plateaus-water.md) e [map-realism/01](../map-realism/01-climate-relief.md)

## Contexto

Antes, a Montanha e a Colina saíam do mesmo relevo (`elevation`), cortado em faixas pelo `placeShapes`, e por isso toda Montanha vinha cercada de Colina no patamar 7. O motivo e as decisões estão no [README](README.md). Esta fase tira a Colina do relevo, dá ao morro a altura dele e junta as montanhas em maciços.

## Escopo

- `server/src/domain/exploration/map-generator.ts`: a forma da Montanha e da Colina, a faixa ao pé de cada maciço e a altura do morro.
- `server/src/domain/exploration/map-config.ts`: sai `hillFrom`; entram `hillFraction` e `foothillChance`.
- `server/src/domain/exploration/map-slopes.ts`: a escadaria extra não abre num paredão que outra escadaria já subiu.
- `client/tools/map_editor/new_island_panel.gd`: os nomes dos parâmetros novos no gerador da ilha nova do F2.

## Requisitos

### A Montanha

- **RF-01:** A Montanha sai do alto do relevo suavizado: cada hexágono de terra leva a média do `elevation` da terra a até 3 hexágonos dele (`meanAround`), em percentil, e é Montanha acima de `mountainFrom` (padrão 0,96). Os pedaços de Montanha menores que 0,4% da terra (no mínimo 6 hexágonos) voltam a ser chão. Com os padrões, saem de 1 a 4 maciços por mapa, de uns 40 a 250 hexágonos cada.
- **RF-02:** A altura da Montanha continua a da [terrain-plateaus/02](../terrain-plateaus/02-plateaus-water.md): 8 na borda, 9 a 1 hexágono dela e 10 mais para dentro. Sem a faixa ao pé, ela encosta direto no chão em volta, e o paredão é aberto pelas escadarias e pela garantia de alcance (`openRamps`, `openSlopes`).
- **RF-03:** A montanha solta, sem outra Montanha encostada, continua virando Colina (`gatherMountains`, também depois das pontes), com a altura do morro (RF-08).
- **RF-04:** Os rios continuam sem nascer nem passar na Montanha.

### A Colina

- **RF-05:** A Colina sai de um ruído próprio, na escala `noiseScale × 2,5`. É Colina o hexágono de terra fora da Montanha cujo percentil desse ruído passa de `1 − hillFraction`. Uma mancha de 1 ou 2 hexágonos volta a ser chão plano. Com os padrões, as manchas soltas têm de 9 a 15 hexágonos (a mediana por mapa).
- **RF-06:** Cada maciço (os hexágonos de Montanha ligados entre si) sorteia uma vez, com a chance `foothillChance`, se ganha a faixa ao pé. Se ganhar, sorteia a largura, de 1 ou 2 hexágonos, e a terra fora da Montanha até essa distância dele vira Colina.
- **RF-07:** O bioma do morro segue o `terrainOf`: na Planície, no Boreal e na Pedra, ele é `hill`; no Deserto e na Neve, fica com o bioma do lugar. A Praia não tem morro: fica no 1. A água continua sempre plana: um rio ou um lago que passa por uma mancha a corta.

### A altura do morro

- **RF-08:** O morro sobe a partir do patamar dele (`terraceOf`, 1, 4 ou 7): +1 no hexágono de Colina que encosta em algo que não é morro (chão, água, Praia, Montanha ou borda do mapa) e +2 no miolo. No patamar 7, o miolo também fica no 8, o máximo do morro. O patamar 1 vira 2 e 3, o 4 vira 5 e 6, e o 7 vira 8 (`placeMoundHeights`).
- **RF-09:** Dentro de uma mancha num patamar só, dois vizinhos de Colina nunca têm mais de 1 nível de diferença. Onde a mancha atravessa a borda de um patamar, o paredão continua, e as escadarias e a garantia de alcance o tratam como antes.
- **RF-10:** A escadaria e a margem de ponte podem mudar a altura de um hexágono de Colina, como fazem com qualquer terra. A margem de ponte que era morro no 8 desce para o patamar 7 (`groundFloor`).

### Os parâmetros

- **RF-11:** Sai `hillFrom`. Entram:
  - `hillFraction`: fração, padrão 0,10, a parte da terra que o ruído da Colina pega (RF-05), sem contar a faixa ao pé;
  - `foothillChance`: fração, padrão 0,5, a chance de cada maciço ganhar a faixa ao pé (RF-06).
- **RF-12:** No gerador da ilha nova do F2, "Altura para colina" deu lugar a "Fração de colina" (`hill_fraction`) e "Chance de colina ao pé da montanha" (`foothill_chance`). "Altura para montanha" (`mountain_from`) continua, agora sobre o relevo suavizado.
- **RF-13:** O ruído da Colina e o sorteio de cada maciço usam um gerador com sal próprio, então o mar, o clima, os lagos e os rios de uma seed não mudam com `hillFraction`.

### A escadaria extra

- **RF-14:** O `openRamps` monta a lista de paredões antes de abrir as escadarias. Um paredão cujo pé uma escadaria anterior já subiu acima do alto dele fica de fora. Antes, a escadaria saía sem degraus, e o hexágono ficava sem altura. Com os morros no 8 perto da Praia, isso travava o `openSlopes` (a seed 308842 com a configuração dos patamares).

## Critérios de aceite

- [x] Em pelo menos 15 de 20 seeds, há uma mancha de Colina com todos os hexágonos a 4 ou mais hexágonos de qualquer Montanha.
- [x] Com `foothillChance` 0 e `hillFraction` 0, toda Colina é uma montanha solta (sem Colina vizinha), e há Montanha encostada em chão plano.
- [x] Com `foothillChance` 1, a terra encostada numa Montanha não é plana, fora a Praia, a água e a beira da água.
- [x] A Colina fica de 5% a 15% da terra com os padrões, e as montanhas continuam formando conjuntos.
- [x] A Montanha fica de 8 a 10; o morro de 2 a 8; e nenhuma outra terra passa de 7. Mais de 90% dos morros ficam em 2, 3, 5, 6 ou 8; o resto foi subido por uma escadaria.
- [x] Toda a terra continua alcançável a partir da chegada.
- [x] O mar, o clima e os rios de uma seed são os mesmos com `hillFraction` 0,10 e 0,20.
- [x] As faixas recusam `hillFraction` e `foothillChance` fora de 0 a 1.
- [x] A seed 308842 com a configuração dos patamares fica pronta, com toda altura inteira.
- [x] `npm test`, o typecheck e os e2e do editor e da exploração passam; o projeto do Godot importa sem erro de script.
- [x] A prévia de 8 mapas foi mostrada ao dono, que aprovou ("Ficou bom, segue").
- [ ] No jogo, o dono anda por um morro numa zona sorteada e vê a altura dele.

## Divergências da spec escrita

- **A Montanha em maciços:** a primeira versão tirava a Montanha de um ruído de cristas próprio, e as montanhas saíram em linhas de 1 hexágono de largura. A segunda voltou ao `elevation` e deu manchas pequenas e espalhadas. O dono pediu: "As montanhas estão muitas despersas, elas devem ser um pouco mais incomuns de se encontrar e não podem ficar dispersas assim, elas geralmente ficaram mais juntas e ocuparam mais espaço". Daí veio o relevo suavizado e o corte dos pedaços pequenos (RF-01).
- **`hillFraction` 0,10:** foi testada em 0,06 e 0,08 na prévia. Com os maciços, a faixa ao pé ficou menor, e 0,10 deixa a Colina com 6% a 10% da terra.
- **RF-14:** não estava na spec. O defeito já existia no `openRamps` e só apareceu com os morros.

## Verificação feita

Em 2026-11-21:

- `npx vitest run`: 1126 de 1126.
- Numa rodada intermediária, o teste dos Domadores (`tamers.spec.ts`, 20 mapas inteiros) estourou os 20 s com a suíte inteira rodando e passou sozinho; na rodada final, passou. O gerador ficou mais rápido: 580 ms por mapa padrão, contra 697 ms antes (medido antes dos maciços).
- `npm run typecheck`, `oxlint` e o Prettier nos arquivos tocados.
- Os e2e `islands-editor` e `exploration`: 84 de 84.
- O Godot importou o projeto só com os avisos de recursos presos na saída, que já existiam.
- A prévia foi desenhada por um script em Python, a partir do `generateMap` de 8 seeds, 2 de cada clima, com as cores do bioma e o sombreado da altura. Não foi desenhada pelo `HexMapView`.

## Verificação

```bash
cd server && npx vitest run src/domain/exploration
cd server && npx vitest run --config ./vitest.config.e2e.ts test/islands-editor.e2e-spec.ts test/exploration.e2e-spec.ts
godot --headless --path client --import
```

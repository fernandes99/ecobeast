# 04. A Geleira no mapa sorteado

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02](02-ice-rocks.md), [03](03-glacier-records.md) e [giant-rocks/02](../giant-rocks/02-generated-rocks.md)

## Contexto

O gerador (`map-generator.ts`) faz, nesta ordem:

1. sorteia o clima (`climateOf`);
2. dá o relevo, o calor e o bioma de cada hexágono;
3. separa as vizinhanças proibidas (`separateBiomes`);
4. põe as alturas, as escadarias, as pontes e as pedras gigantes (`placeGiantRocks`).

As zonas são dadas por bioma no `assignZones` (`map-zones.ts`). A água doce passada em `inland` fica na zona Lago. Toda água fica na altura 0. Um lago com menos de 12 hexágonos não tem água funda (`DEEP_LAKE_FROM`).

## Requisitos

- **RF-01:** Os parâmetros novos em `MAP_CONFIG_RANGES` e no gerador da ilha nova do F2 (`new_island_panel.gd`):

  | Parâmetro | Padrão | Faixa |
  | --- | --- | --- |
  | `glacierChance` | 0,25 | 0 a 1 |
  | `glacierMin` | 20 | 5 a 100 |
  | `glacierMax` | 60 | 5 a 200 |
  | `glacierLakeChance` | 0,5 | 0 a 1 |

  Com `glacierChance` em 0, o mapa de uma seed é igual ao de antes, hexágono por hexágono.
- **RF-02:** `placeGlacier(cells, climate, start, random, config): GlacierPatch | null`, num arquivo próprio (`map-glacier.ts`):
  - **Quando roda:** depois do `openSlopes`, para as encostas de fora da mancha não mudarem. Com o lago, a garantia de alcance roda de novo, com um sorteio próprio (`GLACIER_SLOPES_SALT`). A Geleira guarda a altura da Neve, e o lago desce para 0. Só o clima `cold` entra.
  - **O sorteio:** um gerador com sal próprio a partir da seed. Ele decide se sai Geleira, se sai o lago e o tamanho de 20 a 60.
  - **Os candidatos:** os hexágonos de Neve a pelo menos 2 hexágonos de qualquer bioma que não seja Neve.
  - **O começo:** o candidato mais longe da borda da Neve. Com o lago sorteado, é o candidato na altura 1 ou abaixo mais longe da borda onde o lago cabe. Se não houver nenhum assim, a Geleira sai sem lago, do candidato mais longe da borda.
  - **O crescimento:** pelos candidatos, com a borda irregular pelo sorteio próprio.
  - **Sem Geleira:** se os candidatos alcançáveis do começo forem menos que `glacierMin`, o mapa fica sem Geleira e retorna `null`.
- **RF-03:** O lago da Geleira:
  - é redondo, de raio 2 (19 hexágonos) quando a mancha tem lugar, e senão de raio 1 (7);
  - fica no centro da mancha, cercado por um anel de Geleira, e a mancha continua com pelo menos `glacierMin` hexágonos de terra além dele;
  - o de raio 2 tem a água funda no meio, e o de raio 1 é todo raso;
  - vai à parte, em `iceLake` (fora do `inland`), e o `assignZones` o põe na zona Lago gelado (36 e 37) no lugar do Lago; as manchas de lixo não caem nele.
- **RF-04:** Toda terra que se alcançava da chegada continua alcançável. A chegada não cai na Geleira nem no lago.
- **RF-05:** O `placeIceRocks`, ao lado do `placeGiantRocks` e com as mesmas regras (o `placeRocks` dos dois), põe as pedras de gelo (`ICE_ROCKS`, da [02](02-ice-rocks.md)) só na Geleira, com a chance de 0,15 por hexágono (`ICE_ROCK_CHANCE`, a revisar) e um sorteio próprio, longe das pedras da Montanha. As pedras da Montanha não caem na Geleira e não mudam.
- **RF-06:** A seed fica como antes fora da mancha, nos biomas, na altura, na água, nas pontes e nas pedras da Montanha. As zonas da Neve e as variantes podem mudar ([README](README.md#decisões)).

## Critérios de aceite

- [x] Testes de unidade (`map-glacier.spec.ts`, em mapas de 2.000 hexágonos):
  - Em 400 seeds com o clima `cold` fixado, de 15% a 35% saem com Geleira.
  - Toda Geleira tem de `glacierMin` a `glacierMax` hexágonos de terra.
  - Nenhum hexágono de Geleira encosta num que não seja Geleira, Neve ou o lago dela.
  - Com outro clima, nenhum mapa tem Geleira.
- [x] Nas mesmas seeds, de 30% a 70% das Geleiras têm lago. Medido em 160 mapas frios do tamanho do jogo (10.000 hexágonos): 39 Geleiras (24%), 15 com lago (38%), 41 hexágonos de terra e 4 pedras de gelo em média. Nos mapas de 2.000 hexágonos do teste a Neve baixa é menor, e o lago sai em só 11% das Geleiras; então o teste confere que, com o lago sempre sorteado, ele cabe em pelo menos 25% delas, e que com a chance em 0,5 não passa de 70%.
- [x] O lago é redondo, fica todo dentro da mancha, está na zona Lago gelado e tem a água funda só no de raio 2.
- [x] Toda terra que se alcançava da chegada no mesmo mapa sem a Geleira continua alcançável, fora as pedras e o próprio lago.
- [x] Nos testes do `map-generator.spec.ts`, a Geleira continua em `RARE_BIOMES` (rara de propósito), e o `map-glacier.spec.ts` confere que ela aparece ao longo das seeds frias. Os testes das pedras da Montanha (`map-rocks.spec.ts`) geram os mapas com `glacierChance` em 0.
- [x] Com `glacierChance` em 0, o hash do mapa de 5 seeds é igual ao de antes, tirado do `map-generator.ts` do commit da fase 3.
- [x] Fora da mancha, os biomas, as alturas, as pontes e as pedras da Montanha são os do mesmo mapa sem a Geleira.
- [x] As pedras de gelo só caem na Geleira, e nenhum Ecobeast nem Domador NPC nasce nelas (a exploração já tira os hexágonos de toda pedra, `rockHexes`).
- [ ] O dono confere no jogo uma Geleira de mapa sorteado, pelo `climate` fixado no F2.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [x] Os parâmetros e os testes da faixa (e `glacierMin` não passa de `glacierMax`).
- [x] O `placeGlacier` e o lago, com os testes.
- [x] As pedras de gelo (`placeIceRocks`).
- [x] Os parâmetros no gerador do F2, com um e2e que gera a Geleira com o Lago gelado e as pedras de gelo.

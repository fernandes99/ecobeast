# 04. A Geleira no mapa sorteado

- **Status:** proposta
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
- **RF-02:** `placeGlacier(cells, climate, random, config): GlacierPatch | null`, num arquivo próprio (`map-glacier.ts`):
  - **Quando roda:** depois de dar as alturas e antes do `openSlopes`, para a garantia de alcance valer também com o lago. A Geleira guarda a altura da Neve, e o lago desce para 0. Só o clima `cold` entra.
  - **O sorteio:** um gerador com sal próprio a partir da seed. Ele decide se sai Geleira, se sai o lago e o tamanho de 20 a 60.
  - **Os candidatos:** os hexágonos de Neve a pelo menos 2 hexágonos de qualquer bioma que não seja Neve.
  - **O começo:** o candidato mais longe da borda da Neve. Com o lago sorteado, é o mais longe entre os candidatos na altura 1 ou abaixo. Se não houver nenhum assim, a Geleira sai sem lago.
  - **O crescimento:** pelos candidatos, com a borda irregular pelo sorteio próprio.
  - **Sem Geleira:** se os candidatos alcançáveis do começo forem menos que `glacierMin`, o mapa fica sem Geleira e retorna `null`.
- **RF-03:** O lago da Geleira:
  - é redondo, de raio 2 (19 hexágonos) quando a mancha tem lugar, e senão de raio 1 (7);
  - fica no centro da mancha, que continua com pelo menos `glacierMin` hexágonos de terra além dele;
  - o de raio 2 tem a água funda no meio, e o de raio 1 é todo raso;
  - entra no `inland` com a zona Lago gelado (36 e 37) no lugar do Lago.
- **RF-04:** Toda terra que se alcançava da chegada continua alcançável. A chegada não cai na Geleira nem no lago.
- **RF-05:** O `placeGiantRocks` põe as pedras de gelo (`ICE_ROCKS`, da [02](02-ice-rocks.md)) só na Geleira, com as regras das pedras da Montanha. As pedras da Montanha não caem na Geleira.
- **RF-06:** A seed fica como antes fora da mancha, nos biomas, na altura, na água, nas pontes e nas pedras da Montanha. As zonas da Neve e as variantes podem mudar ([README](README.md#decisões)).

## Critérios de aceite

- [ ] Testes de unidade (`map-glacier.spec.ts`):
  - Em 400 seeds com o clima `cold` fixado, de 15% a 35% saem com Geleira.
  - Toda Geleira tem de `glacierMin` a `glacierMax` hexágonos de terra.
  - Nenhum hexágono de Geleira encosta num que não seja Geleira, Neve ou o lago dela.
  - Com outro clima, nenhum mapa tem Geleira.
- [ ] Nas mesmas seeds, de 30% a 70% das Geleiras têm lago. Se der bem menos, a fase avisa o dono e anota o número aqui.
- [ ] O lago é redondo, fica todo dentro da mancha, está na zona Lago gelado e tem a água funda só no de raio 2.
- [ ] Toda terra do mapa se alcança da chegada.
- [ ] Com `glacierChance` em 0, o hash do mapa de 5 seeds é igual ao de antes.
- [ ] As pedras de gelo só caem na Geleira, e nenhum Ecobeast nem Domador NPC nasce nelas.
- [ ] O dono confere no jogo uma Geleira de mapa sorteado, pelo `climate` fixado no F2.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [ ] Os parâmetros e os testes da faixa.
- [ ] O `placeGlacier` e o lago, com os testes.
- [ ] As pedras de gelo no `placeGiantRocks`.
- [ ] Os parâmetros no gerador do F2.

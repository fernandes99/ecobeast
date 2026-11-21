# 07. Os lagos sem algas e o lixo fácil de achar no mar

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [06](06-trash-patches.md), [coast-rivers](../coast-rivers/)

## Contexto

Em 2026-11-20, depois da [06](06-trash-patches.md), o dono pediu: "as algas não podem aparecer nos lagos. não tô encontrando os lixos, ele deve ser encontrado com mais facilidade na água profunda do mar, certo?"

Até aqui, o servidor não sabia o que era lago: a [06](06-trash-patches.md) achava o mar pelo maior pedaço de água na borda, e os lagos e os rios ficavam nas mesmas zonas do mar, com algas. A mancha de lixo do mar saía em 75% dos mapas, com 8 hexágonos e pouco lixo em cada um (de 0,3 a 0,4 peça por hexágono).

## Escopo

- O `generateMap` devolve `inland`, os lagos e os rios do gerador, cada um um pedaço (só para as zonas; a exploração tira o campo da resposta).
- O `assignZones` recebe `inland`: a água doce fica toda na zona Lago, fora das faixas, e o mar é o resto da água.
- A migration `lake_zones`: as zonas Lago da Água rasa (33, `wshallow_lake`) e da Água profunda (34, `wdeep_lake`), com `share` 0.
- O lixo do mar em todo mapa com mar, quase todo na Água profunda e com bem mais peças.

## Requisitos

- **RF-01:** Todo hexágono de água de `inland` fica no Lago do seu bioma, menos o da mancha de lixo da água doce.
- **RF-02:** As receitas do Lago, sem algas: `wshallow_lake` com sea_rock 0.01 1–1; `wdeep_lake` vazia.
- **RF-03:** A mancha do mar nasce em todo mapa com mar, com 10 hexágonos, a partir de uma Água profunda vizinha da Água rasa do mar; cada passo vai para um vizinho de Água profunda com 80% de chance, quando há.
- **RF-04:** A mancha da água doce nasce com 8% de chance por mapa, num lago ou num rio sorteado, com 3 hexágonos.
- **RF-05:** As receitas do Lixo, sem algas (_a revisar_): `wshallow_trash` com tire 0.1, jug 0.12, old_boot 0.15, plastic_bag 0.25, bottle 0.35 e can 0.3 (1–1 cada); `wdeep_trash` com jug 0.2, tire 0.15, old_boot 0.25, plastic_bag 0.35, bottle 0.5 (1–2) e can 0.4.
- **RF-06:** As constantes ficam no `map-zones.ts` (_a revisar_): `SEA_PATCH_TILES` 10, `SEA_PATCH_DEEP` 0,8, `LAKE_PATCH_CHANCE` 0,08 e `LAKE_PATCH_TILES` 3.
- **RF-07:** Nas ilhas, o dono pinta o Lago pela ferramenta Zona do F2; sem pintar, o lago da ilha fica na Comum.

## Critérios de aceite

- [ ] O dono acha o lixo no mar e não vê algas nos lagos.
- [x] O `map-zones-patches.spec.ts`, em 24 seeds: toda a água doce fica no Lago ou no lixo; todo mapa com mar tem uma mancha de até 10 hexágonos, fora da água doce, com mais de 60% de Água profunda; as manchas fora do mar são raras; as outras zonas e o terreno não mudam.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e o `exploration.e2e` passam.

## Tarefas

- [x] O `inland` no gerador e o Lago no `assignZones`.
- [x] As receitas.
- [x] A migration, aplicada no banco.

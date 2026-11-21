# 02. As receitas e as zonas da água

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-sea-art.md), [biome-zones](../biome-zones/)

## Contexto

As zonas são linhas de `biome_zones`. O mapa sorteado as distribui por bioma em faixas de um ruído (`assignZones`), na ordem de `sort_order` e na proporção de `share`. A taxa de um Ecobeast numa zona é a do bioma vezes `species_biome_zones.rate_percent / 100`. O cliente acha a receita das plantas pelo slug da zona (`HexDecorations.recipe_of`), e a ferramenta Zona do F2 lê as zonas do catálogo.

## Escopo

- A migration `sea_zones`: as 6 zonas, a nova parte da Comum e as exceções de quem nasce.
- As receitas em `HexDecorations.RECIPES`.

## Requisitos

- **RF-01:** A migration muda o `share` da Comum da Água rasa (6) e da Água profunda (7) para 50 e o `sort_order` delas para 2, e insere:

| Id | Slug | Bioma | Nome | `share` | `sort_order` |
| --- | --- | --- | --- | --- | --- |
| 25 | `wshallow_rocks` | 6 | Pedras rasas | 21 | 1 |
| 26 | `wshallow_seagrass` | 6 | Algal | 21 | 3 |
| 27 | `wshallow_trash` | 6 | Lixo | 8 | 4 |
| 28 | `wdeep_rocks` | 7 | Rochedo | 21 | 1 |
| 29 | `wdeep_kelp` | 7 | Floresta de algas | 21 | 3 |
| 30 | `wdeep_trash` | 7 | Lixo | 8 | 4 |

O Lixo (27 e 30) deixou de ser faixa na [06](06-trash-patches.md): o `share` dele é 0, e ele vira uma mancha pequena.

- **RF-02:** As exceções em `species_biome_zones` (_a revisar_): as espécies 4, 5, 17 e 18 com 150 no Algal e na Floresta de algas; as 4, 5, 6, 17, 18 e 19 com 50 nos dois Lixos; a 6 com 150 no Rochedo. A migration só insere a linha de uma espécie que existe.
- **RF-03:** As receitas, da maior decoração para a menor (diminuídas na [04](04-trash-and-density.md)):

| Receita | Tipos (chance, mínimo–máximo) |
| --- | --- |
| `wshallow` | sea_rock 0.06 1–1, sunken_rock 0.12 1–1, algae_patch 0.2 1–1, seagrass 0.35 1–3, floating_weed 0.04 1–1, bottle 0.01 1–1, can 0.01 1–1 |
| `wshallow_rocks` | sea_rock 0.6 1–2, sunken_rock 0.5 1–2, algae_patch 0.3 1–1, seagrass 0.2 1–2 |
| `wshallow_seagrass` | kelp 0.2 1–1, algae_patch 0.5 1–2, seagrass 0.9 3–5, floating_weed 0.15 1–1 |
| `wshallow_trash` | tire 0.15 1–1, crate 0.12 1–1, fishing_net 0.25 1–1, plastic_bag 0.4 1–2, bottle 0.5 1–2, can 0.5 1–2, seagrass 0.2 1–2 |
| `wdeep` | sea_stack 0.02 1–1, kelp 0.12 1–2, sunken_rock 0.06 1–1, floating_weed 0.06 1–1, bottle 0.008 1–1 |
| `wdeep_rocks` | sea_stack 0.4 1–1, sea_rock 0.5 1–2, sunken_rock 0.3 1–1 |
| `wdeep_kelp` | kelp 0.9 2–4, sunken_rock 0.1 1–1, floating_weed 0.3 1–2 |
| `wdeep_trash` | crate 0.15 1–1, tire 0.1 1–1, fishing_net 0.3 1–1, plastic_bag 0.3 1–1, bottle 0.5 1–2, can 0.4 1–2, floating_weed 0.2 1–1 |

## Critérios de aceite

- [ ] No mapa sorteado, a água tem manchas de algas, de pedras e, pequena, de lixo, e a terra é a mesma de antes numa seed.
- [ ] A ferramenta Zona do F2 mostra as 3 zonas de cada água e pinta só nela.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e o e2e tocado passam.

## Tarefas

- [x] A migration, aplicada no banco.
- [x] As receitas.
- [x] Os testes de `assignZones` com as zonas da água.

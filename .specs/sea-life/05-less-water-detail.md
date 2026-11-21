# 05. Menos decoração e sem a alga boiando e a pedra submersa

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [04](04-trash-and-density.md)

## Contexto

Em 2026-11-20, depois da [04](04-trash-and-density.md), o dono pediu: "diminua ainda mais as decorações em geral da água rasa e profunda. Também quero remover aquela alga que é amarela." Na sessão da [beach-life](../beach-life/), ele pediu também sobre a Pedra submersa: "Essas pedras aqui também remova elas, ta estranha demais." Aqui ele confirmou: "Sim, apague".

## Escopo

- As chances das receitas da água pela metade de novo.
- A Alga boiando (`floating_weed`, linha 57, peça 145) e a Pedra submersa (`sunken_rock`, linha 55, peça 143) saem do jogo: das receitas, do `KIND_ROWS` e do `KIND_RADIUS`, do grupo Mar do pincel e da folha (as linhas ficam vazias, para as outras não mudarem de lugar).
- As migrations `remove_floating_weed` e `remove_sunken_rock`, que apagam as duas peças e as postas nas ilhas.

## Requisitos

- **RF-01:** As receitas (_a revisar_):

| Receita | Tipos (chance, mínimo–máximo) |
| --- | --- |
| `wshallow` | sea_rock 0.015 1–1, algae_patch 0.035 1–1, seagrass 0.06 1–1, bottle 0.002 1–1, can 0.002 1–1 |
| `wshallow_rocks` | sea_rock 0.12 1–1, algae_patch 0.05 1–1, seagrass 0.04 1–1 |
| `wshallow_seagrass` | kelp 0.03 1–1, algae_patch 0.1 1–1, seagrass 0.22 1–2 |
| `wshallow_trash` | tire 0.03 1–1, jug 0.03 1–1, old_boot 0.04 1–1, plastic_bag 0.07 1–1, bottle 0.1 1–1, can 0.09 1–1, seagrass 0.04 1–1 |
| `wdeep` | sea_stack 0.005 1–1, kelp 0.02 1–1, bottle 0.0015 1–1 |
| `wdeep_rocks` | sea_stack 0.09 1–1, sea_rock 0.1 1–1 |
| `wdeep_kelp` | kelp 0.2 1–1 |
| `wdeep_trash` | jug 0.03 1–1, tire 0.025 1–1, old_boot 0.05 1–1, plastic_bag 0.06 1–1, bottle 0.1 1–1, can 0.075 1–1 |

## Critérios de aceite

- [ ] O dono acha a água com o volume certo.
- [x] Numa cena temporária com o catálogo do servidor, as duas peças não existem mais, toda peça do Mar tem arte, e 1.000 hexágonos dão de 0,03 (Água profunda comum) a 0,42 (Algal e Lixo da Água rasa) decorações por hexágono.

## Tarefas

- [x] As receitas, o pincel e a folha.
- [x] As migrations, aplicadas no banco.

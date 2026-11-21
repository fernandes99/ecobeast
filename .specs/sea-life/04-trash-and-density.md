# 04. O lixo reconhecível e a água mais limpa

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-sea-art.md), [02](02-sea-zones.md), [03](03-sea-props.md)

## Contexto

Em 2026-11-20, depois das fases 01 a 03, o dono pediu: "ficou com muito detalhes agora, diminua bem mais o volume desses detalhes na agua. os lixos também estão feios, coloque lixos que sejam mais caracteristicos."

## Escopo

- O lixo redesenhado no `make_sea.py`, a partir de desenhos pixel a pixel (`stamp`), com o contorno escuro e um tamanho que se lê no mapa:

| Linha | Peça | Slug | Nome | Como é |
| --- | --- | --- | --- | --- |
| 58 | 146 | `bottle` | Garrafa PET | Garrafa deitada, transparente, com o rótulo e a tampa coloridos |
| 59 | 147 | `can` | Lata de refrigerante | Lata deitada, com a faixa do rótulo e a tampa prateada |
| 60 | 148 | `plastic_bag` | Sacola plástica | Sacola de mercado com as duas alças e a marca |
| 61 | 149 | `old_boot` | Bota velha | Bota de couro ou galocha, meio afundada (era a Rede de pesca) |
| 62 | 150 | `tire` | Pneu | Pneu boiando deitado, com os sulcos e a água no furo |
| 63 | 151 | `jug` | Galão | Galão de plástico com a alça e a tampa (era o Caixote boiando) |

- As receitas da água com bem menos decoração: perto de um terço das chances e dos máximos da [02](02-sea-zones.md).
- O capim-marinho com menos folhas por tufo (5 a 8).
- A migration `sea_trash`, que troca o slug e o nome das peças 149 e 151 e o nome das 146 a 148 (os ids não mudam).

## Requisitos

- **RF-01:** As receitas (diminuídas de novo na [05](05-less-water-detail.md)):

| Receita | Tipos (chance, mínimo–máximo) |
| --- | --- |
| `wshallow` | sea_rock 0.03 1–1, sunken_rock 0.05 1–1, algae_patch 0.07 1–1, seagrass 0.12 1–2, floating_weed 0.015 1–1, bottle 0.004 1–1, can 0.004 1–1 |
| `wshallow_rocks` | sea_rock 0.25 1–1, sunken_rock 0.2 1–1, algae_patch 0.1 1–1, seagrass 0.08 1–1 |
| `wshallow_seagrass` | kelp 0.06 1–1, algae_patch 0.2 1–1, seagrass 0.45 1–3, floating_weed 0.05 1–1 |
| `wshallow_trash` | tire 0.06 1–1, jug 0.06 1–1, old_boot 0.08 1–1, plastic_bag 0.15 1–1, bottle 0.2 1–1, can 0.18 1–1, seagrass 0.08 1–1 |
| `wdeep` | sea_stack 0.01 1–1, kelp 0.04 1–1, sunken_rock 0.02 1–1, floating_weed 0.02 1–1, bottle 0.003 1–1 |
| `wdeep_rocks` | sea_stack 0.18 1–1, sea_rock 0.2 1–1, sunken_rock 0.12 1–1 |
| `wdeep_kelp` | kelp 0.4 1–2, sunken_rock 0.04 1–1, floating_weed 0.1 1–1 |
| `wdeep_trash` | jug 0.06 1–1, tire 0.05 1–1, old_boot 0.1 1–1, plastic_bag 0.12 1–1, bottle 0.2 1–1, can 0.15 1–1, floating_weed 0.06 1–1 |

- **RF-02:** O grupo Mar do pincel troca `fishing_net` e `crate` por `old_boot` e `jug`, ainda desligados.

## Critérios de aceite

- [ ] O dono acha a água com o volume certo e reconhece o lixo.
- [x] Numa cena temporária, as receitas usam só tipos da folha, e o `HexMapView` desenha o lixo novo.
- [x] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [x] O lixo novo e a prévia.
- [x] As receitas e o pincel.
- [x] A migration, aplicada no banco.

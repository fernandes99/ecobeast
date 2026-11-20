# 02. Linha do Prayling

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-time-evolution](01-time-evolution.md), [day-phase-spawns](../day-phase-spawns/) (`species_day_phases`) e [creature-scale](../creature-scale/) (a altura das folhas)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270116000000_prayling_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes` e `species_day_phases`.
- A arte: `client/assets/creatures/prayling`, `mantorn`, `solantis` e `umbrantis`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`).

## Requisitos

**Espécies**

- **RF-01:** Quatro espécies novas, todas com crescimento Médio (2), raridade Incomum (2), captura 45 e `gender_ratio` 0.5. O Mantorn evolui do Prayling, e o Solantis e o Umbrantis do Mantorn.

  | id | slug | name | Elementos | XP | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- |
  | 25 | `prayling` | Prayling | Inseto | 60 | 0.4 | 0.5 |
  | 26 | `mantorn` | Mantorn | Inseto | 140 | 1.0 | 3.8 |
  | 27 | `solantis` | Solantis | Inseto / Luz | 230 | 1.5 | 9.5 |
  | 28 | `umbrantis` | Umbrantis | Inseto / Sombra | 230 | 1.5 | 8.0 |

  Descrições (Bestiário):
  - **Prayling:** "Fica imóvel por horas com as patas dobradas, como se rezasse. Quem chega perto achando que é um galho leva um susto, porque ele nunca erra a primeira mordida."
  - **Mantorn:** "Os braços viraram foices de espinho. Frio e paciente, observa a presa sem piscar e só se move quando já é tarde demais para ela fugir."
  - **Solantis:** "Quando evolui sob o sol, as asas viram pétalas de luz. Pousa entre as flores brilhando tanto que os insetos voam até ele sozinhos, e não voltam."
  - **Umbrantis:** "Quando evolui no escuro, fica seco como uma folha morta. Não caça, espera. Dizem que quem dorme no mato sente as foices dele roçarem antes do amanhecer."

- **RF-02:** Os atributos puxam para Ataque e Velocidade. Entre parênteses fica o Treino que a espécie dá ao ser derrotada, e o resto é 0:

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Prayling | 45 | 65 (1) | 40 | 30 | 40 | 90 | 310 |
  | Mantorn | 60 | 90 (2) | 55 | 40 | 55 | 120 | 420 |
  | Solantis | 75 | 110 (3) | 70 | 80 | 80 | 110 | 525 |
  | Umbrantis | 70 | 135 (3) | 60 | 50 | 70 | 140 | 525 |

- **RF-03:** As quatro têm Instinto (2) no slot 1 e Casca Dura (4) no slot 3, oculto.
- **RF-04:** As evoluções:

  | id | De | Para | Gatilho | Nível | Hora |
  | --- | --- | --- | --- | --- | --- |
  | 57 | Prayling | Mantorn | `level` (1) | 18 | — |
  | 58 | Mantorn | Solantis | `time_of_day` (4) | 36 | `day` |
  | 59 | Mantorn | Umbrantis | `time_of_day` (4) | 36 | `night` |

**Learnsets**

- **RF-05:** Por nível (`level_up`) e, no nível 0, ao evoluir (`evolution`), com Técnicas que já existem. As de Inseto e de Luz entram na [fase 3](03-insect-light-skills.md):

  | Nível | Prayling | Mantorn | Solantis | Umbrantis |
  | --- | --- | --- | --- | --- |
  | 0 | — | Lâmina Sombria | Rasante | Garra do Eclipse |
  | 1 | Arranhão, Olhar Manhoso | Arranhão, Olhar Manhoso | Arranhão, Olhar Manhoso | Arranhão, Olhar Manhoso |
  | 6 | Investida Veloz | Investida Veloz | Investida Veloz | Investida Veloz |
  | 11 | Beliscão | Beliscão | Beliscão | Beliscão |
  | 16 | Garra de Espinho | Garra de Espinho | Garra de Espinho | Garra de Espinho |
  | 24 | Lâmina Sombria | — | Lâmina Sombria | Lâmina Sombria |
  | 42 | — | Rasante | — | — |

**Onde e quando nascem**

- **RF-06:** Taxas em `species_biomes`. Sem linha, a taxa é 0, e nenhuma linha em `species_biome_zones` (vale 100% em toda zona):

  | Espécie | Planície | Boreal | Colina |
  | --- | --- | --- | --- |
  | Prayling | 25 | 30 | 15 |
  | Mantorn | 8 | 10 | 5 |
  | Solantis | 2 | — | 2 |
  | Umbrantis | — | 3 | — |

- **RF-07:** Em `species_day_phases`, o Prayling e o Mantorn têm as 4 partes do dia; o Solantis, a Manhã (1) e a Tarde (2); o Umbrantis, o Final de tarde (3) e a Noite (4).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py`: o Prayling, o Mantorn e o Solantis de `art-source/prayling/line-day.webp`, e o Umbrantis de `line-night.webp`.
- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra: 10, 19, 26 e 26 pixels. Os quatro andam nas 4 patas de trás, com as 2 foices dobradas na frente do peito:
  - o **Prayling** é marrom de galho, com a cabeça triangular grande e os olhos verdes;
  - o **Mantorn** é mais alto e esguio, com as foices de espinho claras e as asas fechadas manchadas nas costas;
  - o **Solantis** é branco e dourado, com as asas de luz abertas atrás e a auréola;
  - o **Umbrantis** é marrom e cinza, com as asas de folha rasgada, os olhos roxos e fiapos de névoa roxa.

  No idle, as antenas, as asas ou a névoa mudam a cada quadro; no walk, as patas de trás vão em diagonais, com 3 quadros de diferença.

## Critérios de aceite

- [x] `GET /v1/species/prayling`, `/mantorn`, `/solantis` e `/umbrantis` respondem 200, e `/v1/species/prayling/evolutions` mostra as 3 regras.
- [x] `check_sheets.py` passa nas quatro pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [ ] No F1 e no Bestiário, as quatro espécies aparecem com o `front.png`.
- [ ] No spawn de depuração de Explorar, as quatro formas ficam paradas e andam.
- [ ] De dia, o Solantis pode aparecer na Planície ou na Colina, e à noite o Umbrantis no Boreal.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/prayling/line-day.webp prayling mantorn solantis
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/prayling/line-night.webp - - umbrantis
cd server && npx prisma migrate deploy
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/prayling/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

## Tarefas

- [x] Recortar os quatro `front.png`.
- [x] A migração das espécies.
- [x] As folhas `idle` e `walk` das quatro formas.
- [x] `CLAUDE.md`, README, índice das specs, roadmap e a skill `creature-sprites`.

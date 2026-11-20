# 01. Linha do Lume

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [day-phase-spawns](../day-phase-spawns/) (`species_day_phases`) e [creature-scale](../creature-scale/) (a altura das folhas)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270114000000_lume_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes` e `species_day_phases`.
- A arte: `client/assets/creatures/lume`, `owlume` e `noclume`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`).

## Requisitos

**Espécies**

- **RF-01:** Três espécies novas, todas com crescimento Médio (2), raridade Incomum (2), captura 45 e `gender_ratio` 0.5. O Owlume evolui do Lume, e o Noclume do Owlume.

  | id | slug | name | Elementos | XP | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- |
  | 20 | `lume` | Lume | Sombra | 60 | 0.3 | 1.1 |
  | 21 | `owlume` | Owlume | Sombra | 140 | 0.9 | 6.0 |
  | 22 | `noclume` | Noclume | Sombra / Psíquico | 230 | 1.5 | 18.0 |

  Descrições (Bestiário):
  - **Lume:** "Passa o dia dormindo no oco de uma árvore. À noite, os olhos enormes refletem a lua, e ele enxerga até o que se esconde no escuro."
  - **Owlume:** "Voa sem fazer nenhum som. As pintas claras das asas imitam as estrelas, e quem olha para o céu não o vê chegar."
  - **Noclume:** "Dizem que guarda a noite enquanto o mundo dorme. O rosto brilha como a lua cheia, e quem cruza o seu olhar esquece o caminho de volta."

- **RF-02:** Os atributos puxam para Ataque Especial e Velocidade, com pouca Defesa. Entre parênteses fica o Treino que a espécie dá ao ser derrotada, e o resto é 0:

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Lume | 45 | 35 | 35 | 60 (1) | 55 | 80 | 310 |
  | Owlume | 60 | 45 | 45 | 85 (2) | 70 | 115 | 420 |
  | Noclume | 80 | 55 | 55 | 115 (3) | 95 | 125 | 525 |

- **RF-03:** As três têm Brisa Ligeira (6) no slot 1 e Instinto (2) no slot 3, oculto.
- **RF-04:** As evoluções são pelo gatilho `level`: a 54, do Lume para o Owlume no nível 20, e a 55, do Owlume para o Noclume no nível 38.

**Learnsets**

- **RF-05:** Por nível (`level_up`) e, no nível 0, ao evoluir (`evolution`), com Técnicas que já existem. As de Sombra especiais entram na [fase 2](02-shadow-skills.md):

  | Nível | Lume | Owlume | Noclume |
  | --- | --- | --- | --- |
  | 0 | — | Rasante | Garra do Eclipse |
  | 1 | Investida Veloz, Olhar Manhoso | Investida Veloz, Olhar Manhoso | Investida Veloz, Olhar Manhoso, Rasante |
  | 5 | Pena Afiada | Pena Afiada | Pena Afiada |
  | 10 | Vento a Favor | Vento a Favor | Vento a Favor |
  | 14 | Lâmina Sombria | Lâmina Sombria | Lâmina Sombria |
  | 18 | Eco Mental | Eco Mental | Eco Mental |
  | 24 | Nuvem de Penas | Nuvem de Penas | Nuvem de Penas |
  | 30 | Lufada Cortante | Lufada Cortante | Lufada Cortante |
  | 36 | Palavra Guardada | Palavra Guardada | Palavra Guardada |
  | 44 | — | Garra do Eclipse | — |

**Onde e quando nascem**

- **RF-06:** Taxas em `species_biomes`. Sem linha, a taxa é 0, e nenhuma linha em `species_biome_zones` (vale 100% em toda zona):

  | Espécie | Planície | Boreal |
  | --- | --- | --- |
  | Lume | 20 | 35 |
  | Owlume | 6 | 12 |
  | Noclume | — | 3 |

- **RF-07:** Em `species_day_phases`, as três só têm a Noite (4).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py` de `art-source/lume/line.webp`.
- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra: 8, 17 e 26 pixels. As três andam no chão em duas patas, como o Puffcoo e o Galecrest:
  - o **Lume** é uma bolinha roxo-escura de peito claro, com os olhos dourados grandes, as orelhas de pena e a lua clara na testa, com o contorno do `spritekit` (`outline`);
  - o **Owlume** é mais esguio, com as asas meio abertas, as pintas claras, a lua na testa e as garras douradas;
  - o **Noclume** é alto, com a crista de penas em volta da lua dourada, o peito creme, as asas fechadas nas costas com uma lua clara e a cauda longa de penas.

  No idle, as asas e as penas da crista mudam a cada quadro; no walk, as duas patas vão com 3 quadros de diferença.

## Critérios de aceite

- [x] `GET /v1/species/lume`, `/owlume` e `/noclume` respondem 200, e `/v1/species/lume/evolutions` mostra a linha com os níveis 20 e 38.
- [x] `check_sheets.py` passa nas três pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [ ] No F1 e no Bestiário, as três espécies aparecem com o `front.png`.
- [ ] No spawn de depuração de Explorar, as três formas ficam paradas e andam.
- [ ] À noite, o Lume aparece na Planície ou no Boreal do mapa sorteado, e de dia não.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/lume/line.webp lume owlume noclume
cd server && npx prisma migrate deploy
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/lume/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

## Tarefas

- [x] Recortar os três `front.png`.
- [x] A migração das espécies.
- [x] As folhas `idle` e `walk` das três formas.
- [x] `CLAUDE.md`, README, índice das specs, roadmap e a skill `creature-sprites`.

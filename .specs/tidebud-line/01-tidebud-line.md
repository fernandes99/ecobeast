# 01. Linha do Tidebud

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [day-phase-spawns](../day-phase-spawns/) (`species_day_phases`) e [coast-rivers](../coast-rivers/) (a Praia e o Vau)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270105000000_tidebud_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes` e `species_day_phases`.
- A arte: `client/assets/creatures/tidebud`, `kelpcoil` e `tempestide`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`).
- O `crop_line.py` da skill `creature-sprites`, que corta a imagem de uma linha nos `front.png`.

## Requisitos

**Espécies**

- **RF-01:** Três espécies novas, todas com crescimento Médio (2), raridade Rara (3), captura 45 e `gender_ratio` 0.5. O Kelpcoil evolui do Tidebud, e o Tempestide do Kelpcoil.

  | id | slug | name | Elementos | XP | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- |
  | 17 | `tidebud` | Tidebud | Água | 62 | 0.4 | 1.8 |
  | 18 | `kelpcoil` | Kelpcoil | Água / Volt | 142 | 1.1 | 12.0 |
  | 19 | `tempestide` | Tempestide | Água / Volt | 236 | 2.0 | 48.0 |

  Descrições (Bestiário):
  - **Tidebud:** "Se esconde entre as algas com a cauda enrolada num talo. Quando se assusta, a crista solta uma faísca azul."
  - **Kelpcoil:** "As veias douradas guardam a eletricidade da água. Nas noites de tempestade, os cristais das costas acendem um a um."
  - **Tempestide:** "Onde ele sobe à superfície, o mar fica revolto e os raios correm pelas folhas. Os marinheiros contam que ele chama a chuva."

- **RF-02:** Os atributos puxam para Ataque Especial e Velocidade. Entre parênteses fica o Treino que a espécie dá ao ser derrotada, e o resto é 0:

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Tidebud | 44 | 36 | 40 | 65 (1) | 55 | 75 | 315 |
  | Kelpcoil | 58 | 48 | 52 | 88 (2) | 72 | 102 | 420 |
  | Tempestide | 76 | 60 | 66 | 115 (3) | 90 | 123 | 530 |

- **RF-03:** As três têm Maré Furiosa (3) no slot 1 e Instinto (2) no slot 3, oculto.
- **RF-04:** As evoluções são pelo gatilho `level`: a 52, do Tidebud para o Kelpcoil no nível 18, e a 53, do Kelpcoil para o Tempestide no nível 38.

**Learnsets**

- **RF-05:** Tudo por nível (`level_up`), com Técnicas que já existiam. As de Volt entram na [fase 2](02-volt-skills.md#requisitos):

  | Nível | Tidebud | Kelpcoil | Tempestide |
  | --- | --- | --- | --- |
  | 1 | Investida Veloz, Olhar Manhoso | Investida Veloz, Olhar Manhoso | Investida Veloz, Olhar Manhoso |
  | 5 | Jato de Maré | Jato de Maré | Jato de Maré |
  | 9 | Espuma Densa | Espuma Densa | Espuma Densa |
  | 13 | Folha Navalha | Folha Navalha | Folha Navalha |
  | 17 | Seiva Vital | Seiva Vital | Seiva Vital |
  | 22 | Maré Restauradora | Maré Restauradora | Maré Restauradora |
  | 28 | Torrente | Torrente | Torrente |
  | 34 | Tempestade de Pétalas | Tempestade de Pétalas | Tempestade de Pétalas |
  | 44 | — | — | Maremoto |
  | 50 | — | Maremoto | — |

**Onde e quando nascem**

- **RF-06:** Taxas em `species_biomes`. Sem linha, a taxa é 0:

  | Espécie | Água rasa | Água profunda | Vau | Praia |
  | --- | --- | --- | --- | --- |
  | Tidebud | 15 | — | 20 | 10 |
  | Kelpcoil | 6 | 4 | 8 | 3 |
  | Tempestide | 1 | 3 | — | — |

- **RF-07:** Em `species_day_phases`, o Tidebud e o Kelpcoil têm Final de tarde (3) e Noite (4), e o Tempestide as 4 partes.

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py` como na [seedlet-line](../seedlet-line/01-seedlet-line.md#requisitos) (RF-02): os raios e os cristais soltos vão para a forma de centro mais perto.
- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas do catálogo: 6, 16 e 29 pixels. Sem patas, ele flutua em pé: a ponta da cauda enrolada encosta no chão em todo quadro, o corpo sobe e desce de leve, e as folhas e os raios mudam a cada quadro. No walk, ele se inclina para a frente e a cauda empurra.

## Critérios de aceite

- [x] `GET /v1/species/tidebud`, `/kelpcoil` e `/tempestide` respondem 200, e `/v1/species/tidebud/evolutions` mostra a linha com os níveis 18 e 38.
- [x] `check_sheets.py` passa nas três pastas.
- [x] Lint, typecheck e testes de unidade do servidor passam.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [ ] No F1 e no Bestiário, as três espécies aparecem com o `front.png`.
- [ ] No spawn de depuração de Explorar, as três formas flutuam e andam.
- [ ] À noite, o Tidebud aparece na água rasa, no Vau ou na Praia do mapa sorteado.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/tidebud/line.webp tidebud kelpcoil tempestide
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/tidebud/explore
cd server && npm run lint && npm run typecheck && npm test
godot --headless -d --path client --quit-after 240
```

## Tarefas

- [x] Recortar os três `front.png`.
- [x] A migração das espécies.
- [x] As folhas `idle` e `walk` das três formas.
- [x] `CLAUDE.md`, README, índice das specs, roadmap e a skill `creature-sprites`.

# 01. Linha do Fuzzap

- **Status:** concluída
- **Depende de:** [snelt-line/01](../snelt-line/01-snelt-line.md) (o mesmo caminho), [creature-scale](../creature-scale/), [creature-faces](../creature-faces/), [day-phase-spawns](../day-phase-spawns/), [biome-zones](../biome-zones/) e [glacier](../glacier/)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [snelt-line/01](../snelt-line/01-snelt-line.md). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270205000000_fuzzap_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`.
- A arte: `client/assets/creatures/fuzzap` e `blizzvolt`, cada uma com `front.png`, `face.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`), e os quadrados novos no `client/assets/creatures/faces.json`.

## Requisitos

**Espécies**

- **RF-01:** Duas espécies novas, com crescimento Rápido (1), raridade Comum (1) e `gender_ratio` 0.5. O Blizzvolt evolui do Fuzzap.

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 41 | `fuzzap` | Fuzzap | Volt (4) | 52 | 75 | 0.25 | 1.5 |
  | 42 | `blizzvolt` | Blizzvolt | Volt (4), Gelo (7) | 165 | 35 | 0.9 | 45.0 |

  Descrições do Bestiário:
  - **Fuzzap:** "Rola na neve até o pelo ficar cheio de estática. Assusta-se com qualquer barulho e solta um choque sem querer, e aí fica mais assustado ainda com o próprio choque."
  - **Blizzvolt:** "O medo virou vigília: não tira os olhos de quem chega perto. A cauda de cristal guarda a tempestade, e o pelo solta raios quando alguém dá um passo a mais."

- **RF-02:** Equilibrados, sem um atributo muito acima dos outros. Entre parênteses fica o Treino.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Fuzzap | 50 | 50 | 45 | 45 | 50 | 60 (1) | 300 |
  | Blizzvolt | 85 | 80 | 75 | 70 | 85 | 85 (2) | 480 |

- **RF-03:** As duas têm Brisa Ligeira (6) no slot 1, não oculto, e Instinto (2) no slot 3, oculto.
- **RF-04:** A evolução é a linha 67 de `evolutions`, pelo gatilho `level` (1): 41 → 42 no nível 24.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions`, `skills` e `skill_effects`. Em 2026-11-22 eram 40, 66, 117 e 79.

**Learnsets**

- **RF-05:** Por nível (método 1), com as Técnicas que já existem. As novas entram na [fase 2](02-volt-skills.md).

  | Nível | Fuzzap | Blizzvolt |
  | --- | --- | --- |
  | 1 | Floco Cortante (39) | Floco Cortante (39) |
  | 6 | Geada Silenciosa (40) | Geada Silenciosa (40) |
  | 14 | Faísca Rastejante (91) | Faísca Rastejante (91) |
  | 30 | — | Maré Elétrica (64) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Montanha (5) | Neve (9) | Geleira (12) |
  | --- | --- | --- | --- |
  | Fuzzap | 10 | 40 | 20 |
  | Blizzvolt | 3 | 10 | 6 |

  | Espécie | Campo de neve (23) | Pinheiral nevado (24) |
  | --- | --- | --- |
  | as duas | 200% | 50% |

- **RF-07:** Em `species_day_phases`, as duas têm a Manhã (1), o Final de tarde (3) e a Noite (4).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py`, que tira o fundo branco pela cor dos cantos, com o Blizzvolt espelhado depois, para olhar para a direita. Os raios, os cristais e os flocos soltos em volta ficam com cada forma, como as gotas de veneno do Sandlurk. Depois, o `make_faces.py` grava o `face.png` pelo quadrado do `faces.json`; o calculado pegava o raio e a orelha, então os dois foram postos à mão: `[128, 196, 204]` e `[272, 112, 186]`.

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/fuzzap/line.webp fuzzap blizzvolt
  python -I .claude/skills/creature-sprites/scripts/make_faces.py
  ```

- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra: **8 pixels** para o Fuzzap (0,25 m) e **17** para o Blizzvolt (0,9 m). Os dois andam de quatro, com as diagonais juntas:
  - o **Fuzzap** é uma bola de pelo branco com as pontas azul-lavanda, os olhos azuis grandes, as patinhas curtas embaixo e um raio amarelo que pisca no pelo;
  - o **Blizzvolt** é esguio, de pernas longas, com a juba branca, as mechas azuis e verde-água, a orelha de cristal, o olho azul sério e a cauda grossa enrolada para cima, com um raio amarelo e a ponta de cristal.

  No idle, o raio do pelo pisca e muda de lugar a cada quadro, e a cauda do Blizzvolt balança (`swayed`). No walk, as patas andam em diagonais. As folhas usam o `rig` e o contorno do `spritekit`: o Fuzzap parte do [Hushling](../creature-scale/02-small-sheets.md), com o corpo parado e só as patas, o raio e a cauda mexendo, e o Blizzvolt do Ruvo, com as patas de 5 linhas, a juba espetada e as costas com as pontas das mechas.

## Critérios de aceite

- [x] `GET /v1/species/fuzzap` e `/blizzvolt` respondem 200, e `/v1/species/fuzzap/evolutions` mostra a regra do nível 24.
- [x] `check_sheets.py` passa nas duas pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas. Em 2026-11-22: 1225 de unidade.
- [x] No F1 e no Bestiário, as duas espécies aparecem com o `front.png`, e o rosto aparece nas bolinhas da Home.
- [x] No spawn de depuração de Explorar, as duas formas ficam paradas e andam.
- [x] O Fuzzap aparece na Neve do mapa sorteado, e de Tarde não.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/fuzzap/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/blizzvolt/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

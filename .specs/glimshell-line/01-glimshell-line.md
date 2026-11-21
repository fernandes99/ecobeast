# 01. Linha do Glimshell

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [hopling-line/01](../hopling-line/01-hopling-line.md) (o mesmo caminho), [creature-scale](../creature-scale/), [day-phase-spawns](../day-phase-spawns/) e [biome-zones](../biome-zones/)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [hopling-line/01](../hopling-line/01-hopling-line.md). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270129000000_glimshell_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`.
- A arte: `client/assets/creatures/glimshell`, `lumoshell` e `prismback`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`).

## Requisitos

**Espécies**

- **RF-01:** Três espécies novas, com crescimento Lento (3), raridade Incomum (2) e `gender_ratio` 0.5. O Lumoshell evolui do Glimshell, e o Prismback do Lumoshell.

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 33 | `glimshell` | Glimshell | Luz (12) | 62 | 45 | 0.35 | 8.0 |
  | 34 | `lumoshell` | Lumoshell | Luz (12) | 145 | 45 | 0.8 | 85.0 |
  | 35 | `prismback` | Prismback | Luz (12) | 240 | 45 | 1.3 | 300.0 |

  Descrições do Bestiário:
  - **Glimshell:** "Dorme quase o dia todo com o casco virado para o sol. A pedrinha das costas guarda a luz da manhã e brilha fraquinha até de noite."
  - **Lumoshell:** "Anda tão devagar que os outros desistem de esperar. A luz que escapa pelas frestas do casco desvia os golpes que vêm de longe."
  - **Prismback:** "Dizem que dorme há mais tempo do que qualquer um lembra. O casco-prisma espalha arco-íris e desvia até os golpes de energia mais fortes, sem que ele abra os olhos."

- **RF-02:** HP e Defesa Especial muito altos, Defesa e Velocidade baixas. Entre parênteses fica o Treino.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Glimshell | 70 | 35 | 45 | 50 | 75 (1) | 30 | 305 |
  | Lumoshell | 95 | 45 | 55 | 65 | 105 (2) | 35 | 400 |
  | Prismback | 125 | 55 | 70 | 90 | 140 (3) | 45 | 525 |

- **RF-03:** As três têm Casca Dura (4) no slot 1, não oculto, e nenhum Traço oculto.
- **RF-04:** As evoluções são as linhas 62 e 63 de `evolutions`, pelo gatilho `level` (1): 33 → 34 no nível 18 e 34 → 35 no nível 36.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions`, `skills` e `skill_effects`. Em 2026-11-21 eram 32, 61, 105 e 70.

**Learnsets**

- **RF-05:** Por nível (método 1) e ao evoluir (método 2, nível 0), com as Técnicas que já existem. As de Luz entram na [fase 2](02-light-skills.md).

  | Nível | Glimshell | Lumoshell | Prismback |
  | --- | --- | --- | --- |
  | 1 | Beliscão (14) | Beliscão (14) | Beliscão (14) |
  | 12 | Cochilo (104) | Cochilo (104) | Cochilo (104) |
  | 16 | Raio de Sol (87) | Raio de Sol (87) | Raio de Sol (87) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Pedra (3) | Praia (10) |
  | --- | --- | --- |
  | Glimshell | 20 | 15 |
  | Lumoshell | 6 | 4 |
  | Prismback | 2 | 1 |

  | Espécie | Rochedo (20) | Coqueiral (31) |
  | --- | --- | --- |
  | as três | 200% | 50% |

- **RF-07:** Em `species_day_phases`, as três só têm a Manhã (1) e a Tarde (2).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py`, que tira o fundo branco; os três já olham para a direita:

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/glimshell/line.webp glimshell lumoshell prismback
  ```

- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra: **9 pixels** para o Glimshell (0,35 m), **16** para o Lumoshell (0,8 m) e **23** para o Prismback (1,3 m), com o cristal do topo. Os três andam de quatro, devagar, com as patas curtas e grossas em diagonais e o casco quase parado:
  - o **Glimshell** tem o casco âmbar com a pedrinha clara no topo e a cabeça grande, de olhos meio fechados;
  - o **Lumoshell** tem o casco de placas âmbar com as frestas claras, a ponta de cristal e o pescoço comprido;
  - o **Prismback** tem o casco de prismas furta-cor (âmbar, lilás e azul-claro) com a ponta alta, a barbicha creme e a cauda pontuda.

  No idle, a cabeça desce devagar, como quem cochila, e um pixel do cristal pisca a cada quadro. No walk, as patas andam em diagonais, com os pés sempre no chão, porque a verificação pede algo na última linha em todo quadro.

  As folhas são desenhadas por ângulo, sem o `rig`, como as do [Hopling](../hopling-line/01-hopling-line.md): a vista de lado serve às diagonais (a de subida sem os olhos), e a de costas mostra o casco inteiro e a cauda. O Glimshell é desenhado pixel a pixel. No Lumoshell e no Prismback, o contorno do casco é desenhado à mão, e as placas e os prismas saem de um padrão de arestas diagonais no `sprites.py` (`plate` e `prism`); no Prismback, cada prisma tem uma metade clara e outra escura. A cabeça, a barbicha e as patas são carimbos à mão.

## Critérios de aceite

- [x] `GET /v1/species/glimshell`, `/lumoshell` e `/prismback` respondem 200, e `/v1/species/glimshell/evolutions` mostra as regras dos níveis 18 e 36.
- [x] `check_sheets.py` passa nas três pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas. Em 2026-11-21: 1103 de unidade e 696 de 698 e2e; as 2 falhas (`species_day_phases` e `species_skills`, das espécies 7 a 9) já existiam.
- [ ] No F1 e no Bestiário, as três espécies aparecem com o `front.png`.
- [ ] No spawn de depuração de Explorar, as três formas ficam paradas e andam.
- [ ] De Manhã, o Glimshell aparece na Pedra do mapa sorteado, e à Noite não.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/glimshell/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/lumoshell/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/prismback/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

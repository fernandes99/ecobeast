# 01. Linha do Snelt

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [glimshell-line/01](../glimshell-line/01-glimshell-line.md) (o mesmo caminho), [creature-scale](../creature-scale/), [creature-faces](../creature-faces/), [day-phase-spawns](../day-phase-spawns/), [biome-zones](../biome-zones/) e [volcano](../volcano/)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [glimshell-line/01](../glimshell-line/01-glimshell-line.md). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270203000000_snelt_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`.
- A arte: `client/assets/creatures/snelt`, `smeltrudge` e `magmollusk`, cada uma com `front.png`, `face.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`), e os quadrados novos no `client/assets/creatures/faces.json`.

## Requisitos

**Espécies**

- **RF-01:** Três espécies novas, com crescimento Médio (2), raridade Comum (1) e `gender_ratio` 0.5. O Smeltrudge evolui do Snelt, e o Magmollusk do Smeltrudge.

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 38 | `snelt` | Snelt | Metal (8) | 55 | 70 | 0.3 | 6.0 |
  | 39 | `smeltrudge` | Smeltrudge | Metal (8) | 140 | 40 | 0.9 | 120.0 |
  | 40 | `magmollusk` | Magmollusk | Metal (8), Fogo (1) | 225 | 25 | 1.6 | 450.0 |

  Descrições do Bestiário:
  - **Snelt:** "Lustra a concha de ferro até ver o próprio reflexo nela. Se alguém a arranha, esquenta de raiva e solta fumaça pelo topo."
  - **Smeltrudge:** "Leva horas para atravessar uma trilha, porque para em cada pedra com minério para avaliar. Só derrete na fornalha o que acha digno dela."
  - **Magmollusk:** "Dizem que nenhuma peça saiu torta da fornalha dele. Despeja metal derretido sem pressa nenhuma e olha de cima quem não aguenta o calor."

- **RF-02:** Ataque Especial alto, HP e Defesa bons, Velocidade baixa. Entre parênteses fica o Treino.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Snelt | 55 | 35 | 60 | 65 (1) | 50 | 25 | 290 |
  | Smeltrudge | 75 | 45 | 80 | 95 (2) | 70 | 35 | 400 |
  | Magmollusk | 100 | 55 | 100 | 130 (3) | 90 | 40 | 515 |

- **RF-03:** As três têm Casca Dura (4) no slot 1, não oculto, e Fúria Ardente (1) no slot 3, oculto.
- **RF-04:** As evoluções são as linhas 65 e 66 de `evolutions`, pelo gatilho `level` (1): 38 → 39 no nível 16 e 39 → 40 no nível 32.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions`, `skills` e `skill_effects`. Em 2026-11-22 eram 37, 64, 113 e 76.

**Learnsets**

- **RF-05:** Por nível (método 1), com as Técnicas que já existem. As de Metal entram na [fase 2](02-metal-skills.md).

  | Nível | Snelt | Smeltrudge | Magmollusk |
  | --- | --- | --- | --- |
  | 1 | Faísca Rápida (5) | Faísca Rápida (5) | Faísca Rápida (5) |
  | 8 | Couraça (15) | Couraça (15) | Couraça (15) |
  | 24 | Cometa de Brasa (89) | Cometa de Brasa (89) | Cometa de Brasa (89) |
  | 38 | — | Chama Espiral (9) | Chama Espiral (9) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Pedra (3) | Montanha (5) | Vulcão (13) |
  | --- | --- | --- | --- |
  | Snelt | 30 | 40 | 30 |
  | Smeltrudge | 8 | 12 | 10 |
  | Magmollusk | 2 | 3 | 4 |

  | Espécie | Rochedo (20) |
  | --- | --- |
  | as três | 200% |

- **RF-07:** Em `species_day_phases`, as três têm as 4 partes do dia (1 a 4).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py` da imagem de fundo transparente, com o Smeltrudge e o Magmollusk espelhados depois, para olhar para a direita, como o Dunestrike. Depois, o `make_faces.py` calcula o quadrado do rosto de cada um no `faces.json` e grava o `face.png`; confira na `art-source/creature-faces/faces_sheet.png` que o rosto pega os olhos e as antenas, sem a concha. O quadrado calculado pegava a chaminé, então os três foram postos à mão: `[300, 180, 210]`, `[290, 200, 210]` e `[296, 208, 214]`.

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/snelt/line.webp snelt smeltrudge magmollusk
  python -I .claude/skills/creature-sprites/scripts/make_faces.py
  ```

- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra: **8 pixels** para o Snelt (0,3 m), **17** para o Smeltrudge (0,9 m) e **28** para o Magmollusk (1,6 m), com a fumaça. Os três são caracóis sem patas, com o pé encostado no chão em todo quadro, a concha atrás da cabeça e as duas antenas de ponta acesa:
  - o **Snelt** tem o corpo bege, a concha de ferro em espiral com a brasa laranja e a brasa acesa no topo; com 6 pixels de desenho, não cabe a fumaça. É desenhado pixel a pixel, com o contorno por fora (`outline`), como os outros pequenos;
  - o **Smeltrudge** tem a concha cinza de fornalha, com a chaminé e a fumaça, a portinha acesa, os rebites e um espinho, e a cara emburrada;
  - o **Magmollusk** tem o corpo de pedra escura com frestas de lava, a barbicha creme, a concha de fornalha com espinhos e a emenda acesa das placas, a chaminé com o fogo e a fumaça escura e o metal derretido escorrendo da boca da fornalha (atrás, na vista de lado; no meio, na de costas) até a poça no chão.

  No idle, as pontas das antenas balançam, a brasa pisca e a fumaça balança a cada quadro, e no Magmollusk o metal derretido corre para baixo. No walk, o pé estica e encolhe, com a cabeça indo à frente e a concha vindo um quadro depois, sem nunca sair do chão.

  As folhas são desenhadas por ângulo: a vista de lado serve às diagonais (a de subida sem os olhos), e a de costas mostra a concha inteira com a chaminé. O lado esquerdo sai espelhado no jogo. O Snelt é desenhado pixel a pixel; no Smeltrudge e no Magmollusk, a concha é uma elipse sombreada no `sprites.py` (`Grid.ellipse`), com a chaminé, a porta, os espinhos, a cabeça e as antenas carimbados à mão, e todos usam o contorno do `spritekit`. No walk, o desenho de lado é partido na emenda da concha com a cabeça (`stretched_side`).

## Critérios de aceite

- [x] `GET /v1/species/snelt`, `/smeltrudge` e `/magmollusk` respondem 200, e `/v1/species/snelt/evolutions` mostra as regras dos níveis 16 e 32.
- [x] `check_sheets.py` passa nas três pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas. Em 2026-11-22: 1223 de unidade e 733 de 736 e2e; 2 falhas já existiam (`species_day_phases` e `species_skills`, das espécies 7 a 9), e a 3ª (`skills-editor`, "recusa um apply_status sem Estado") passou rodando o arquivo sozinho.
- [ ] No F1 e no Bestiário, as três espécies aparecem com o `front.png`, e o rosto aparece nas bolinhas da Home.
- [ ] No spawn de depuração de Explorar, as três formas ficam paradas e andam.
- [ ] O Snelt aparece na Montanha do mapa sorteado.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/snelt/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/smeltrudge/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/magmollusk/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

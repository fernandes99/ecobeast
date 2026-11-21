# 01. Linha do Hopling

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [sandlurk-line/01](../sandlurk-line/01-sandlurk-line.md) (o mesmo caminho), [creature-scale](../creature-scale/), [day-phase-spawns](../day-phase-spawns/) e [biome-zones](../biome-zones/)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [sandlurk-line/01](../sandlurk-line/01-sandlurk-line.md). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270128000000_hopling_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`.
- A arte: `client/assets/creatures/hopling` e `pouchmend`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`).

## Requisitos

**Espécies**

- **RF-01:** Duas espécies novas, com crescimento Médio (2), raridade Incomum (2) e `gender_ratio` 0.5. A Pouchmend evolui do Hopling (`evolves_from_species_id` 31).

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 31 | `hopling` | Hopling | Instinto (13) | 62 | 45 | 0.6 | 9.0 |
  | 32 | `pouchmend` | Pouchmend | Instinto (13) | 172 | 30 | 1.6 | 52.0 |

  Descrições do Bestiário:
  - **Hopling:** "Anda com um pano na testa e um maço de ervas na mão, sempre de cara amarrada. Reclama de quem se machuca, mas não deixa ninguém sem curativo."
  - **Pouchmend:** "Tem olheiras de quem nunca dorme e resmunga a cada ferida que trata. O filhote na bolsa, sempre animado, entrega as ervas antes de ela terminar a bronca."

- **RF-02:** Os atributos são equilibrados, com o HP e a Defesa Especial em destaque. Entre parênteses fica o Treino.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Hopling | 65 (1) | 40 | 45 | 45 | 65 | 45 | 305 |
  | Pouchmend | 100 (2) | 60 | 70 | 70 | 100 | 80 | 480 |

- **RF-03:** As duas têm Instinto (2) no slot 1, não oculto, e nenhum Traço oculto.
- **RF-04:** A evolução é a linha 61 de `evolutions`: `species_id` 31, `evolved_species_id` 32, `evolution_trigger_id` 1 (`level`) e `min_level` 28.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions`, `skills` e `skill_effects`. Em 2026-11-21 eram 30, 60, 101 e 66.

**Learnsets**

- **RF-05:** Por nível (método 1) e ao evoluir (método 2, nível 0), com as Técnicas que já existem. As de suporte entram na [fase 2](02-support-skills.md).

  | Nível | Hopling | Pouchmend |
  | --- | --- | --- |
  | 0 (ao evoluir) | — | Brotar (69) |
  | 1 | Patada (27), Olhar Manhoso (28) | Patada (27), Olhar Manhoso (28) |
  | 9 | Investida Veloz (3) | Investida Veloz (3) |
  | 13 | Rugido Feroz (2) | Rugido Feroz (2) |
  | 34 | — | Brotar (69) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Planície (1) | Colina (4) |
  | --- | --- | --- |
  | Hopling | 25 | 20 |
  | Pouchmend | 6 | 5 |

  | Espécie | Campo florido (13) | Mato seco (19) |
  | --- | --- | --- |
  | Hopling | 150% | 200% |
  | Pouchmend | 150% | 200% |

- **RF-07:** Em `species_day_phases`, as duas só têm a Manhã (1) e o Final de tarde (3).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py`, que tira o fundo branco; os dois já olham para a direita:

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/hopling/line.webp hopling pouchmend
  ```

- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra: **13 pixels** para o Hopling (0,6 m) e **28** para a Pouchmend (1,6 m), com as orelhas. Os dois ficam em pé nas patas traseiras e andam aos pulinhos, as duas patas juntas, com a cauda de apoio:
  - o **Hopling** tem a atadura creme na testa, os olhos amarelos meio fechados, a barriga creme e o maço de ervas verde na pata da frente;
  - a **Pouchmend** tem a mesma atadura, a bolsa de pano a tiracolo e o filhote espiando dela, com a cauda comprida.

  No idle, a orelha do Hopling mexe e a ponta da atadura balança, e na Pouchmend a atadura balança e o filhote abaixa as orelhas. No walk, os dois se abaixam e esticam nos pulinhos, com os pés sempre no chão, porque a verificação pede algo na última linha em todo quadro.

  As folhas são desenhadas inteiras por ângulo, sem o `rig`, como as do [Sandlurk](../sandlurk-line/01-sandlurk-line.md): a vista de lado serve às diagonais (a de subida sem os olhos), e a de costas mostra a cauda no meio das patas.

## Critérios de aceite

- [x] `GET /v1/species/hopling` e `/pouchmend` respondem 200, e `/v1/species/hopling/evolutions` mostra a regra do nível 28.
- [x] `check_sheets.py` passa nas duas pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas. Em 2026-11-21: 1102 de unidade e 696 de 698 e2e; as 2 falhas (`species_day_phases` e `species_skills`, das espécies 7 a 9) já existiam.
- [ ] No F1 e no Bestiário, as duas espécies aparecem com o `front.png`.
- [ ] No spawn de depuração de Explorar, as duas formas ficam paradas e pulam.
- [ ] De Manhã, o Hopling aparece na Planície do mapa sorteado, e de Tarde não.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/hopling/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/pouchmend/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

# 01. Linha do Nectoad

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [fuzzap-line/01](../fuzzap-line/01-fuzzap-line.md) (o mesmo caminho), [creature-roles](../creature-roles/), [creature-scale](../creature-scale/), [creature-faces](../creature-faces/), [day-phase-spawns](../day-phase-spawns/) e [biome-zones](../biome-zones/)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [fuzzap-line/01](../fuzzap-line/01-fuzzap-line.md). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270208000000_nectoad_line` (a `20270207000000` ficou com a `ground-variety`, de outra sessão), com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`.
- A arte: `client/assets/creatures/nectoad` e `toxbloom`, cada uma com `front.png`, `face.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`), e os quadrados novos no `client/assets/creatures/faces.json`.
- O Toxbloom na tabela "Os papéis de hoje" da [creature-roles](../creature-roles/README.md#os-papéis-de-hoje).

## Requisitos

**Espécies**

- **RF-01:** Duas espécies novas, com crescimento Médio (2), raridade Comum (1) e `gender_ratio` 0.5. O Toxbloom evolui do Nectoad.

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 43 | `nectoad` | Nectoad | Toxina (9) | 56 | 75 | 0.35 | 2.0 |
  | 44 | `toxbloom` | Toxbloom | Toxina (9), Flora (3) | 170 | 35 | 1.0 | 70.0 |

  Descrições do Bestiário:
  - **Nectoad:** "Senta no meio das flores e jura que é uma delas. A pele solta um néctar doce que atrai os insetos e os deixa tontos de veneno. Fica ofendido se ninguém elogia a cor dele."
  - **Toxbloom:** "Um dia nasceu uma flor de verdade nas costas, e ele nunca mais abaixou o queixo. Aguenta qualquer golpe sem desfazer a pose, e o néctar que pinga das pétalas envenena o chão em volta."

- **RF-02:** Muralha física: a Defesa é o maior atributo, e a Velocidade, o menor. Entre parênteses fica o Treino.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Nectoad | 60 | 45 | 65 (1) | 40 | 50 | 30 | 290 |
  | Toxbloom | 100 | 75 | 110 (2) | 65 | 85 | 45 | 480 |

- **RF-03:** As duas têm Casca Dura (4) no slot 1, não oculto, e Raiz Furiosa (5) no slot 3, oculto.
- **RF-04:** A evolução é a linha 68 de `evolutions`, pelo gatilho `level` (1): 43 → 44 no nível 22.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions`, `skills` e `skill_effects`. Em 2026-11-22 eram 42, 67, 121 e 82.

**Learnsets**

- **RF-05:** Por nível (método 1), com as Técnicas que já existem. As novas entram na [fase 2](02-toxin-guard-skills.md).

  | Nível | Nectoad | Toxbloom |
  | --- | --- | --- |
  | 1 | Espinho Venenoso (74) | Espinho Venenoso (74) |
  | 8 | Couraça (15) | Couraça (15) |
  | 26 | Poça Tóxica (75) | Poça Tóxica (75) |
  | 30 | — | Laço de Raízes (68) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Planície (1) | Boreal (2) |
  | --- | --- | --- |
  | Nectoad | 30 | 10 |
  | Toxbloom | 8 | 3 |

  | Espécie | Campo florido (13) | Bosque (15) |
  | --- | --- | --- |
  | as duas | 200% | 50% |

- **RF-07:** Em `species_day_phases`, as duas têm a Manhã (1), o Final de tarde (3) e a Noite (4).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py` da imagem do dono, que tira o fundo branco pela cor dos cantos, com o Toxbloom espelhado depois, para olhar para a direita. As gotas de néctar soltas ficam com cada forma. Uma gota do Toxbloom, à esquerda dele, ia para o Nectoad, porque o `crop_line.py` dava cada peça solta à forma de centro mais perto; ele passou a dar à forma cuja caixa fica mais perto. Depois, o `make_faces.py` grava o `face.png` pelo quadrado do `faces.json`, posto à mão para pegar os dois olhos e a boca: `[165, 62, 235]` e `[222, 168, 200]`.

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/nectoad/line.webp nectoad toxbloom
python -I -c "from PIL import Image; p='client/assets/creatures/toxbloom/front.png'; Image.open(p).transpose(Image.FLIP_LEFT_RIGHT).save(p)"
  python -I .claude/skills/creature-sprites/scripts/make_faces.py
  ```

- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra: **9 pixels** para o Nectoad (0,35 m) e **19** para o Toxbloom (1,0 m). Os dois ficam agachados, de quatro, com as patas de trás dobradas:
  - o **Nectoad** é verde de pintas rosa, com a barriga creme, os olhos laranja de pálpebra caída, a gola de pétalas rosa mais larga que o corpo e os dedos rosa;
  - o **Toxbloom** é largo e baixo, verde de pintas rosa, com a barriga creme, os olhos laranja meio fechados, o sorriso convencido e a flor carmim e violeta aberta nas costas, de miolo dourado, entre folhas.

  No idle, a garganta do Nectoad infla e uma gota de néctar brilha nas costas dele, e a flor do Toxbloom balança (`swayed`) enquanto o néctar pinga das pétalas. No walk, os dois andam em pulinhos: o corpo e a cabeça sobem 1 pixel em dois quadros de cada três, e as patas, de 2 linhas (Nectoad) e 4 (Toxbloom), esticam embaixo do corpo, com os dedos sempre no chão. As folhas usam o `rig` e o contorno do `spritekit`; o Nectoad parte do Fuzzap, e o Toxbloom tem a anca dobrada de lado (`HAUNCH`) e a flor atrás da cabeça nas vistas de frente e de lado, e na frente nas costas.

## Critérios de aceite

- [x] `GET /v1/species/nectoad` e `/toxbloom` respondem 200, e `/v1/species/nectoad/evolutions` mostra a regra do nível 22.
- [x] `check_sheets.py` passa nas duas pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas. Em 2026-11-22: 1225 de unidade e 735 de 737 e2e (as 2 falhas antigas do seed).
- [ ] No F1 e no Bestiário, as duas espécies aparecem com o `front.png`, e o rosto aparece nas bolinhas da Home.
- [ ] No spawn de depuração de Explorar, as duas formas ficam paradas e andam.
- [ ] O Nectoad aparece na Planície do mapa sorteado, mais no Campo florido, e de Tarde não.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/nectoad/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/toxbloom/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

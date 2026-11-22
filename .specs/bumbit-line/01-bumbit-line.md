# 01. Linha do Bumbit

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [budflit-line/01](../budflit-line/01-budflit-line.md) (o mesmo caminho), [creature-roles](../creature-roles/), [creature-scale](../creature-scale/), [creature-faces](../creature-faces/), [day-phase-spawns](../day-phase-spawns/) e [biome-zones](../biome-zones/)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [budflit-line/01](../budflit-line/01-budflit-line.md). Os números são _a revisar_ depois de jogar. A arte vem da imagem do dono, em `art-source/bumbit/line.webp`.

## Escopo

- A migração `20270212000000_bumbit_line` (a data depois da última migração da pasta), com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`.
- A arte: `client/assets/creatures/bumbit`, `buzzwork` e `bloomarch`, cada uma com `front.png`, `face.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`), e os quadrados novos no `client/assets/creatures/faces.json`.
- O Bloomarch na tabela "Os papéis de hoje" da [creature-roles](../creature-roles/README.md#os-papéis-de-hoje).

## Requisitos

**Espécies**

- **RF-01:** Três espécies novas, com crescimento Médio (2), raridade Comum (1) e `gender_ratio` 0.5. O Buzzwork evolui do Bumbit, e o Bloomarch do Buzzwork.

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 48 | `bumbit` | Bumbit | Inseto (15) | 54 | 75 | 0.3 | 0.6 |
  | 49 | `buzzwork` | Buzzwork | Inseto (15) | 140 | 45 | 0.8 | 7.0 |
  | 50 | `bloomarch` | Bloomarch | Inseto (15), Flora (3) | 222 | 25 | 1.5 | 28.0 |

  Descrições do Bestiário:
  - **Bumbit:** "Vive preocupado com a ordem das flores e fica nervoso quando uma pétala cai fora do lugar. As asinhas mal o levantam, então ele vai de flor em flor a pé, zumbindo baixinho."
  - **Buzzwork:** "Conta cada flor do campo e anota tudo de cabeça. Manda nos outros sem parar e espalha um mel grudento no caminho de quem atrapalha o trabalho."
  - **Bloomarch:** "O manto de pétalas cresce do próprio pelo. Já não se apressa: com um zumbido grave, decide onde cada um pisa, e o mel que pinga das mandíbulas segura quem tenta passar."

- **RF-02:** Controlador equilibrado: nenhum atributo muito acima dos outros, a Def. Especial e o Ataque Especial um pouco à frente e a Velocidade média. Entre parênteses fica o Treino.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Bumbit | 50 | 35 | 50 | 45 | 55 (1) | 65 | 300 |
  | Buzzwork | 70 | 50 | 70 | 65 | 75 (2) | 75 | 405 |
  | Bloomarch | 90 | 70 | 90 | 85 (1) | 95 (2) | 90 | 520 |

- **RF-03:** As três têm Brisa Ligeira (6) no slot 1, não oculto, e Casca Dura (4) no slot 3, oculto.
- **RF-04:** As evoluções são as linhas 71 e 72 de `evolutions`, pelo gatilho `level` (1): 48 → 49 no nível 15 e 49 → 50 no nível 32.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions`, `skills`, `skill_effects` e `ground_effects`, porque outras sessões mexem no catálogo. Em 2026-11-22 eram 47, 70, 127, 91 e 11.

**Learnsets**

- **RF-05:** Por nível (método 1), com as Técnicas que já existem. As novas entram na [fase 2](02-hive-skills.md).

  | Nível | Bumbit | Buzzwork | Bloomarch |
  | --- | --- | --- | --- |
  | 1 | Investida Veloz (3) | Investida Veloz (3) | Investida Veloz (3) |
  | 26 | — | Esporos Sonolentos (30) | Esporos Sonolentos (30) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Planície (1) | Colina (4) |
  | --- | --- | --- |
  | Bumbit | 30 | 10 |
  | Buzzwork | 10 | 3 |
  | Bloomarch | 3 | 1 |

  | Espécie | Campo florido (13) | Mato seco (19) |
  | --- | --- | --- |
  | as três | 200% | 50% |

- **RF-07:** Em `species_day_phases`, as três têm a Manhã (1) e o Final de tarde (3).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py` da imagem do dono, que já tem o fundo transparente. As três olham para a direita, e as gotas de mel soltas ficam com o Bloomarch. Depois, o `make_faces.py` grava o `face.png` pelo quadrado do `faces.json`, posto à mão nos olhos e nas antenas.

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/bumbit/line.webp bumbit buzzwork bloomarch
  python -I .claude/skills/creature-sprites/scripts/make_faces.py
  ```

- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas que o `height_in_pixels` do `spritekit.py` dá para 0,3 m, 0,8 m e 1,5 m (8, 16 e 26 pixels). Alguma coisa encosta no chão em todo quadro:
  - o **Bumbit** anda a pé, em passinhos de bolinha, com as asinhas tremendo atrás do corpo no idle e no walk;
  - o **Buzzwork** fica de pé nas duas pernas, com os cestos de pólen, e anda marchando; as asas vibram em duas poses;
  - o **Bloomarch** fica de pé, pesado, com as manoplas de mel nas mãos e as quatro asas abertas batendo em poses, como a Gatemoth.

## Critérios de aceite

- [x] `GET /v1/species/bumbit`, `/buzzwork` e `/bloomarch` respondem 200, e `/v1/species/bumbit/evolutions` mostra as regras dos níveis 15 e 32.
- [x] `check_sheets.py` passa nas três pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e os e2e do catálogo, das espécies e das Técnicas passam; a única falha é a contagem dos tipos de chão, que espera a migração `dirt_tones` da ground-variety/03, de outra sessão.
- [ ] No F1 e no Bestiário, as três espécies aparecem com o `front.png`, e o rosto aparece nas bolinhas da Home.
- [ ] No spawn de depuração de Explorar, as três formas ficam paradas e andam.
- [ ] O Bumbit aparece na Planície do mapa sorteado, mais no Campo florido, de Manhã e no Final de tarde, e de Tarde e à Noite não.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/bumbit/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/buzzwork/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/bloomarch/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

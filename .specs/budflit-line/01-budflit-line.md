# 01. Linha do Budflit

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [nectoad-line/01](../nectoad-line/01-nectoad-line.md) (o mesmo caminho), [creature-roles](../creature-roles/), [creature-scale](../creature-scale/), [creature-faces](../creature-faces/), [day-phase-spawns](../day-phase-spawns/) e [biome-zones](../biome-zones/)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [nectoad-line/01](../nectoad-line/01-nectoad-line.md). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270209000000_budflit_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`.
- A arte: `client/assets/creatures/budflit`, `cheerwing` e `galafly`, cada uma com `front.png`, `face.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`), e os quadrados novos no `client/assets/creatures/faces.json`.
- A Galafly na tabela "Os papéis de hoje" da [creature-roles](../creature-roles/README.md#os-papéis-de-hoje).

## Requisitos

**Espécies**

- **RF-01:** Três espécies novas, com crescimento Médio (2), raridade Comum (1) e `gender_ratio` 0.5. A Cheerwing evolui do Budflit, e a Galafly da Cheerwing.

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 45 | `budflit` | Budflit | Inseto (15) | 52 | 75 | 0.2 | 0.3 |
  | 46 | `cheerwing` | Cheerwing | Inseto (15), Psíquico (10) | 138 | 45 | 0.6 | 2.5 |
  | 47 | `galafly` | Galafly | Inseto (15), Psíquico (10) | 220 | 25 | 1.3 | 12.0 |

  Descrições do Bestiário:
  - **Budflit:** "Vive escondida entre as pétalas, de asas sempre fechadas como um botão de flor. Só abre um pouquinho quando alguém do time vai bem, e aí solta umas faíscas de brilho."
  - **Cheerwing:** "Abriu as asas e virou a torcedora mais barulhenta do campo. Comemora qualquer golpe, até os que erram, e o pó das asas deixa os aliados mais confiantes."
  - **Galafly:** "As quatro asas abertas parecem a cortina de um palco, e o brilho cai como confete. Rege o time como um maestro e faz cada aliado se sentir a estrela da festa."

- **RF-02:** Suporte rápido: o HP e a Def. Especial em destaque, os ataques baixos e a Velocidade alta. Entre parênteses fica o Treino.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Budflit | 50 | 30 | 40 | 45 | 60 | 75 (1) | 300 |
  | Cheerwing | 70 | 35 | 55 | 60 | 85 | 100 (2) | 405 |
  | Galafly | 95 | 45 | 70 | 75 | 110 (1) | 125 (2) | 520 |

- **RF-03:** As três têm Brisa Ligeira (6) no slot 1, não oculto, e Instinto (2) no slot 3, oculto.
- **RF-04:** As evoluções são as linhas 69 e 70 de `evolutions`, pelo gatilho `level` (1): 45 → 46 no nível 14 e 46 → 47 no nível 30.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions`, `skills` e `skill_effects`. Em 2026-11-22 eram 44, 68, 124 e 86.

**Learnsets**

- **RF-05:** Por nível (método 1), com as Técnicas que já existem. As novas entram na [fase 2](02-cheer-skills.md).

  | Nível | Budflit | Cheerwing | Galafly |
  | --- | --- | --- | --- |
  | 1 | Investida Veloz (3) | Investida Veloz (3) | Investida Veloz (3) |
  | 10 | Vento a Favor (54) | Vento a Favor (54) | Vento a Favor (54) |
  | 22 | — | Eco Mental (44) | Eco Mental (44) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Planície (1) | Colina (4) |
  | --- | --- | --- |
  | Budflit | 35 | 10 |
  | Cheerwing | 10 | 3 |
  | Galafly | 3 | 1 |

  | Espécie | Campo florido (13) | Clareira (12) |
  | --- | --- | --- |
  | as três | 200% | 150% |

- **RF-07:** Em `species_day_phases`, as três têm a Manhã (1) e a Tarde (2).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py` da imagem do dono, que tira o fundo branco pela cor dos cantos. As três já olham para a direita, e os brilhos e os traços de comemoração soltos ficam com a forma mais perto. Depois, o `make_faces.py` grava o `face.png` pelo quadrado do `faces.json`, posto à mão no olho e nas antenas: `[250, 215, 180]`, `[258, 140, 140]` e `[225, 125, 140]`.

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/budflit/line.webp budflit cheerwing galafly
  python -I .claude/skills/creature-sprites/scripts/make_faces.py
  ```

- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra: **7 pixels** para o Budflit (0,2 m), **13** para a Cheerwing (0,6 m) e **23** para a Galafly (1,3 m). As asas batem no idle e no walk, e alguma coisa encosta no chão em todo quadro:
  - o **Budflit** fica sentado, de asas fechadas, com as perninhas no chão, e as asas abrem um pouco e fecham;
  - a **Cheerwing** e a **Galafly** ficam de pé nas pernas finas, com o corpo em pé, as asas abertas batendo e as antenas de bolinha; a Galafly tem as caudas longas das asas de trás, que encostam no chão.

  As três trocam poses inteiras, como a Gatemoth: o Budflit tem duas (as asas fechadas e um pouco abertas), e a Cheerwing e a Galafly três (as asas abertas, no meio e erguidas), com as asas atrás do corpo parado e as pintas douradas piscando nos quadros ímpares.

## Critérios de aceite

- [x] `GET /v1/species/budflit`, `/cheerwing` e `/galafly` respondem 200, e `/v1/species/budflit/evolutions` mostra as regras dos níveis 14 e 30.
- [x] `check_sheets.py` passa nas três pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas.
- [ ] No F1 e no Bestiário, as três espécies aparecem com o `front.png`, e o rosto aparece nas bolinhas da Home.
- [ ] No spawn de depuração de Explorar, as três formas ficam paradas e andam.
- [ ] O Budflit aparece na Planície do mapa sorteado, mais no Campo florido, e à Noite não.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/budflit/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/cheerwing/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/galafly/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

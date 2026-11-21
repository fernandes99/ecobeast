# 01. Linha do Sandlurk

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [snekit-line/01](../snekit-line/01-snekit-line.md) (o mesmo caminho), [creature-scale](../creature-scale/) (a altura das folhas), [day-phase-spawns](../day-phase-spawns/) (`species_day_phases`) e [biome-zones](../biome-zones/) (`species_biome_zones`)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [snekit-line/01](../snekit-line/01-snekit-line.md), que fez o mesmo para duas espécies. Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270127000000_sandlurk_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`. O SQL é escrito à mão e aplicado com `npx prisma migrate deploy`.
- A arte: `client/assets/creatures/sandlurk` e `dunestrike`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`).

## Requisitos

**Espécies**

- **RF-01:** Duas espécies novas, com crescimento Médio (2), raridade Incomum (2) e `gender_ratio` 0.5. O Dunestrike evolui do Sandlurk (`evolves_from_species_id` 29).

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 29 | `sandlurk` | Sandlurk | Inseto (15) / Toxina (9) | 60 | 45 | 0.4 | 6.0 |
  | 30 | `dunestrike` | Dunestrike | Inseto (15) / Toxina (9) | 175 | 25 | 1.1 | 85.0 |

  Descrições do Bestiário:
  - **Sandlurk:** "Passa dias enterrado na duna, só com os olhos de fora, sempre com cara de tédio. Não se dá ao trabalho de fugir: espera quem pisa perto demais e belisca sem nem levantar."
  - **Dunestrike:** "Fica imóvel sob a areia quente por horas, até a presa entrar no alcance do ferrão. O bote é um só, lento de esperar e rápido demais para ver, e o veneno amarelo deixa a vítima dura no lugar."

- **RF-02:** Os atributos puxam para a Defesa e o Ataque, com a Velocidade baixa. Entre parênteses fica o Treino que a espécie dá ao ser derrotada, e o resto é 0.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Sandlurk | 50 | 60 | 75 (1) | 25 | 50 | 40 | 300 |
  | Dunestrike | 85 | 105 | 125 (2) | 35 | 80 | 55 | 485 |

- **RF-03:** As duas têm Casca Dura (4) no slot 1, não oculto, e nenhum Traço oculto.
- **RF-04:** A evolução é a linha 60 de `evolutions`: `species_id` 29, `evolved_species_id` 30, `evolution_trigger_id` 1 (`level`) e `min_level` 30. Os outros campos ficam nulos.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions`, `skills` e `skill_effects`. Em 2026-11-21 eram 28, 59, 97 e 62.

**Learnsets**

- **RF-05:** Por nível (`level_up`, método 1), com as Técnicas que já existem. As de escorpião entram na [fase 2](02-dune-skills.md).

  | Nível | Sandlurk | Dunestrike |
  | --- | --- | --- |
  | 1 | Beliscão (14), Olhar Manhoso (28) | Beliscão (14), Olhar Manhoso (28) |
  | 5 | Nuvem de Poeira (47) | Nuvem de Poeira (47) |
  | 13 | Espinho Venenoso (74) | Espinho Venenoso (74) |
  | 21 | Dardo Gotejante (96) | Dardo Gotejante (96) |
  | 34 | — | Areia Movediça (72) |
  | 42 | — | Poça Tóxica (75) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Deserto (8) | Praia (10) |
  | --- | --- | --- |
  | Sandlurk | 30 | 12 |
  | Dunestrike | 8 | 3 |

  | Espécie | Dunas (21) | Cactal (22) |
  | --- | --- | --- |
  | Sandlurk | 200% | 50% |
  | Dunestrike | 200% | 50% |

- **RF-07:** Em `species_day_phases`, as duas só têm a Manhã (1) e a Tarde (2).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py`, que tira o fundo branco pela cor dos cantos, com o Dunestrike espelhado depois, para olhar para a direita:

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/sandlurk/line.webp sandlurk dunestrike
  ```

  O vão entre os dentes das pinças sai transparente, e as gotas de veneno ficam com cada forma.
- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra (`height_in_pixels` do `spritekit.py`): **10 pixels** para o Sandlurk (0,4 m) e **20** para o Dunestrike (1,1 m). Os dois andam rente ao chão, com oito patas curtas, em lados alternados, como os caranguejos da Nilu:
  - o **Sandlurk** é largo e achatado, com as pinças grossas na frente, a cauda curta enrolada para cima com a gota amarela e os olhos amarelos; usa o contorno do `spritekit` (`outline`), como os pequenos da [creature-scale](../creature-scale/02-small-sheets.md);
  - o **Dunestrike** é comprido e blindado, com as pinças serrilhadas, as placas pontudas e a cauda alta em arco, com o ferrão amarelo.

  No idle do Sandlurk, o ferrão balança e a gota pisca; no do Dunestrike, o corpo respira e a gota cresce e cai. No walk, as patas andam em dois grupos alternados, o ferrão do Sandlurk balança, e o corpo do Dunestrike sobe e desce.

  As folhas são desenhadas inteiras por ângulo, sem o `rig`: a vista de lado serve também às diagonais (a de descida com os dois olhos, a de subida sem eles), e a de costas é a de frente sem os olhos, com as faixas nas costas.

## Critérios de aceite

- [x] `GET /v1/species/sandlurk` e `/dunestrike` respondem 200, e `/v1/species/sandlurk/evolutions` mostra a regra do nível 30.
- [x] `check_sheets.py` passa nas duas pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas. Em 2026-11-21: 1083 de unidade e 695 de 698 e2e; das 3 falhas, as 2 do seed (`species_day_phases` e `species_skills`, das espécies 7 a 9) já existiam, e a do `bundle.e2e-spec.ts` esperava a Chama Espiral com área de um alvo, antes da [board-battle/33](../board-battle/33-triangle-area.md): o teste passou a esperar o Triângulo.
- [ ] No F1 e no Bestiário, as duas espécies aparecem com o `front.png`.
- [ ] No spawn de depuração de Explorar, as duas formas ficam paradas e andam.
- [ ] De Manhã, o Sandlurk aparece no Deserto do mapa sorteado, e à Noite não.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/sandlurk/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/dunestrike/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

O executável do Godot é `C:\Godot\Godot_v4.7.2-stable_win64_console.exe`.

# 01. Linha do Snekit

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [lume-line](../lume-line/01-lume-line.md) (o mesmo caminho), [creature-scale](../creature-scale/) (a altura das folhas) e [day-phase-spawns](../day-phase-spawns/) (`species_day_phases`)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [lume-line/01](../lume-line/01-lume-line.md): ela fez o mesmo para três espécies e serve de modelo para a migração, a arte e a verificação. Os números são _a revisar_ depois de jogar.

A evolução segue o caminho 1 do [ponto aberto](README.md#ponto-aberto-a-evolução-por-vínculo): a regra fica gravada, e a evolução espera a [bond](../bond/README.md).

## Escopo

- A migração `20270115000000_snekit_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes` e `species_day_phases`. Escreva o SQL à mão e aplique com `npx prisma migrate deploy` (o `migrate dev` trava).
- A arte: `client/assets/creatures/snekit` e `venomaw`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`).

## Requisitos

**Espécies**

- **RF-01:** Duas espécies novas, com crescimento Médio (2), raridade Comum (1) e `gender_ratio` 0.5. O Venomaw evolui do Snekit (`evolves_from_species_id` 23).

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 23 | `snekit` | Snekit | Instinto (13) | 58 | 80 | 0.4 | 2.4 |
  | 24 | `venomaw` | Venomaw | Instinto (13) / Toxina (9) | 170 | 30 | 1.2 | 38.0 |

  Descrições do Bestiário:
  - **Snekit:** "Fica enrolada nas pedras quentes, olhando de lado para quem passa. Mostra a língua como quem zomba, e morde antes de qualquer aviso."
  - **Venomaw:** "Ergue a cabeça e abre a bocarra ao menor ruído. O veneno verde que escorre das presas queima o chão onde cai, e nenhuma criatura chega perto do ninho dela."

- **RF-02:** Os atributos puxam para Ataque e Velocidade. Entre parênteses fica o Treino que a espécie dá ao ser derrotada, e o resto é 0. A ordem dos `stat_id` é 1 HP, 2 Ataque, 3 Defesa, 4 Ataque Especial, 5 Defesa Especial e 6 Velocidade.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Snekit | 45 | 62 (1) | 40 | 35 | 45 | 68 | 295 |
  | Venomaw | 75 | 105 (2) | 70 | 55 | 70 | 95 | 470 |

- **RF-03:** As duas têm Instinto (2) no slot 1, não oculto, e nenhum Traço oculto.
- **RF-04:** A evolução é a linha 56 de `evolutions`: `species_id` 23, `evolved_species_id` 24, `evolution_trigger_id` 3 (`bond`), `min_level` 32 e `min_bond` 220. Os outros campos ficam nulos.
  - Até a [bond](../bond/README.md) existir, o servidor não oferece essa evolução. Não mude o `evolutionOffer` nesta fase.
  - O nível natural dos selvagens usa o `min_level` da regra (`naturalLevel` em `server/src/domain/exploration/spawns.ts`), então o Venomaw selvagem nasce perto do nível 32.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species`, `evolutions` e `skills`: outra sessão pode ter usado os ids 23, 24, 56 ou 80 desde 2026-11-20. Se tiverem sido usados, pegue os próximos livres e atualize as specs.

**Learnsets**

- **RF-05:** Por nível (`level_up`, método 1) e, no nível 0, ao evoluir (`evolution`, método 2), só com Técnicas que já existem. As de serpente entram na [fase 2](02-serpent-skills.md).

  | Nível | Snekit | Venomaw |
  | --- | --- | --- |
  | 0 | — | Espinho Venenoso (74) |
  | 1 | Investida Veloz (3), Olhar Manhoso (28) | Investida Veloz (3), Olhar Manhoso (28), Espinho Venenoso (74) |
  | 6 | Beliscão (14) | Beliscão (14) |
  | 12 | Rugido Feroz (2), o chiado | Rugido Feroz (2) |
  | 36 | — | Poça Tóxica (75) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes`. Sem linha, a taxa é 0, e não há linha em `species_biome_zones`, então vale 100% em toda zona.

  | Espécie | Planície (1) | Colina (4) | Deserto (8) |
  | --- | --- | --- | --- |
  | Snekit | 35 | 30 | 40 |
  | Venomaw | — | 6 | 10 |

- **RF-07:** Em `species_day_phases`, as duas só têm a Tarde (2) e o Final de tarde (3).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py`:

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/snekit/line.webp snekit venomaw
  ```

  A imagem já é transparente, e o script deixa o alfa só em 0 ou 255 ([creature-fronts](../creature-fronts/)). Confira que as gotas de veneno do Venomaw ficaram com ele.
- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra (`height_in_pixels` do `spritekit.py`): **10 pixels** para o Snekit (0,4 m) e **22** para o Venomaw (1,2 m). As duas se arrastam no chão, sem patas:
  - o **Snekit** fica enrolado, com a cabeça erguida de lado, os espinhos da cabeça, as marcas verde-limão no roxo-ameixa, a barriga creme e a língua vermelha. Use o contorno do `spritekit` (`outline`), como nos pequenos da [creature-scale](../creature-scale/02-small-sheets.md);
  - o **Venomaw** é grosso e de várias voltas, com a cabeça alta, a juba de espinhos, a boca aberta com as presas e as gotas verdes.

  No idle, a língua entra e sai, e o corpo sobe e desce de leve. No walk, o corpo ondula de um lado para o outro, sem patas: veja como o `sprites.py` de outro Ecobeast monta os quadros e adapte o movimento.

## Critérios de aceite

- [x] `GET /v1/species/snekit` e `/venomaw` respondem 200, e `/v1/species/snekit/evolutions` mostra a regra com nível 32 e Vínculo 220.
- [x] `check_sheets.py` passa nas duas pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo (ele pode reclamar da regra de Vínculo com nível: se reclamar, ajuste o validador e explique na spec).
- [x] Os testes e2e de `species_*` e `evolutions` passam, menos as 2 falhas antigas (eles conferem que toda linha do seed-data está no banco; o seed-data não é editado). Em 2026-11-20: 1046 de unidade e 690 de 692 e2e; as 2 falhas (`species_day_phases` e `species_skills`, das espécies 7 a 9) já existiam antes desta linha, porque essas linhas foram apagadas direto no banco.
- [ ] No F1 e no Bestiário, as duas espécies aparecem com o `front.png`.
- [ ] No spawn de depuração de Explorar, as duas formas ficam paradas e se arrastam.
- [ ] De Tarde, o Snekit aparece na Planície, na Colina ou no Deserto do mapa sorteado, e à Noite não.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/snekit/line.webp snekit venomaw
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/snekit/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/venomaw/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

O executável do Godot é `C:\Godot\Godot_v4.7.2-stable_win64_console.exe`, porque `godot` não está no PATH.

## Tarefas

- [x] Seguir o caminho 1 da evolução ([README](README.md#ponto-aberto-a-evolução-por-vínculo)), com o "pode seguir" do dono.
- [x] Recortar os dois `front.png`.
- [x] A migração das espécies.
- [x] As folhas `idle` e `walk` das duas formas.
- [x] `CLAUDE.md` (uma frase no fim do "Escopo atual"), README e índice das specs, e a linha no roadmap marcada como concluída.

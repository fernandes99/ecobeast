# 01. Linha do Veilmoth

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [glimshell-line/01](../glimshell-line/01-glimshell-line.md) (o mesmo caminho), [creature-scale](../creature-scale/), [day-phase-spawns](../day-phase-spawns/) e [biome-zones](../biome-zones/)

## Contexto

A linha nova do dono ([README](README.md#contexto)). Siga a [glimshell-line/01](../glimshell-line/01-glimshell-line.md). Os números são _a revisar_ depois de jogar.

## Escopo

- A migração `20270130000000_veilmoth_line`, com linhas novas em `species`, `species_elements`, `species_stats`, `species_traits`, `species_skills`, `evolutions`, `species_biomes`, `species_biome_zones` e `species_day_phases`.
- A arte: `client/assets/creatures/veilmoth` e `gatemoth`, cada uma com `front.png` e `explore/` (`sprites.py`, `idle.png` e `walk.png`).

## Fora do escopo

- As Técnicas de Arcano ([fase 2](02-arcane-skills.md)) e o Teleporte ([fase 3](03-teleport.md)).
- O que o [README](README.md#fora-do-escopo) deixa de fora.

## Requisitos

**Espécies**

- **RF-01:** Duas espécies novas, com crescimento Lento (3), raridade Épica (4) e `gender_ratio` 0.5. O Gatemoth evolui do Veilmoth.

  | id | slug | name | Elementos | XP | Captura | Altura (m) | Peso (kg) |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | 36 | `veilmoth` | Veilmoth | Arcano (14) | 70 | 25 | 0.5 | 0.4 |
  | 37 | `gatemoth` | Gatemoth | Arcano (14) / Inseto (15) | 230 | 15 | 1.4 | 6.0 |

  Descrições do Bestiário:
  - **Veilmoth:** "Só sai à noite e nunca se afasta do bando. Quando fecha as asas, se desfaz em pó violeta e aparece junto de uma irmã, onde quer que ela esteja."
  - **Gatemoth:** "Os olhos das asas são portais abertos para outros lugares. Diz-se que os antigos guardavam um em cada altar, para que as ilhas nunca ficassem longe umas das outras."

- **RF-02:** Rápida e frágil, com bom Ataque Especial. Entre parênteses fica o Treino.

  | Espécie | HP | Atq | Def | Atq.E | Def.E | Vel | Total |
  | --- | --- | --- | --- | --- | --- | --- | --- |
  | Veilmoth | 50 | 30 | 40 | 70 | 60 | 80 (1) | 330 |
  | Gatemoth | 80 | 45 | 60 | 115 (2) | 100 | 120 (1) | 520 |

- **RF-03:** As duas têm Brisa Ligeira (6, +1 de Velocidade ao entrar em batalha) no slot 1, não oculto, e nenhum Traço oculto.
- **RF-04:** A evolução é a linha 64 de `evolutions`, pelo gatilho `level` (1): 36 → 37 no nível 32.
- **RF-04b:** Antes de gravar, confira no banco os maiores ids de `species` e `evolutions`. Em 2026-11-21 eram 35 e 63. Se outra linha entrou antes, use os seguintes e corrija esta spec.

**Learnsets**

- **RF-05:** Por nível (método 1), com as Técnicas que já existem. As de Arcano entram na [fase 2](02-arcane-skills.md), e o Teleporte na [fase 3](03-teleport.md).

  | Nível | Veilmoth | Gatemoth |
  | --- | --- | --- |
  | 1 | Investida Veloz (3) | Investida Veloz (3) |
  | 14 | Voo Silencioso (78) | Voo Silencioso (78) |

**Onde e quando nascem**

- **RF-06:** As taxas em `species_biomes` e, por zona, em `species_biome_zones` (sem linha, a zona vale 100%).

  | Espécie | Boreal (2) | Colina (4) |
  | --- | --- | --- |
  | Veilmoth | 10 | 5 |
  | Gatemoth | 2 | 1 |

  | Espécie | Clareira do Boreal (16) |
  | --- | --- |
  | as duas | 200% |

- **RF-07:** Em `species_day_phases`, as duas só têm a Noite (4).

**Arte**

- **RF-08:** Os `front.png` são de 512×512, recortados pelo `crop_line.py`, que tira o fundo branco; as duas já olham para a direita:

  ```bash
  python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/veilmoth/line.webp veilmoth gatemoth
  ```

- **RF-09:** As folhas `idle.png` e `walk.png` seguem a skill `creature-sprites`, nas alturas da regra do mapa (a escala do Domador mais 4 pixels, com o contorno): **11 pixels** para o Veilmoth (0,5 m) e **25** para o Gatemoth (1,4 m), com as antenas e as caudas.
  - As duas voam baixo, como o [Tidebud](../tidebud-line/) flutua: a ponta das caudas de véu encosta na última linha em todo quadro, porque a verificação pede algo nela.
  - O **Veilmoth** tem as asas violeta com o olho-portal (o centro escuro e o anel rosado), a cabeça escura de olhos claros, a gola creme, as antenas lilás e duas caudas.
  - O **Gatemoth** tem as asas largas com os olhos-portal e a faixa creme, as antenas douradas, a máscara escura de olhos claros, a juba creme com o broche de cristal em moldura dourada e as caudas longas com o cristal na ponta. As asas, o corpo e as caudas são partes separadas no `sprites.py`.
  - Só as asas se mexem, em três poses (abertas, no meio e erguidas): no idle, abertas, no meio, erguidas e no meio; no walk, duas batidas inteiras. O anel do olho-portal acende nos quadros ímpares.
  - A largura do Gatemoth cabe na célula de 32 px: as asas abertas vão da coluna 1 à 31, com o contorno.

## Critérios de aceite

- [x] `GET /v1/species/veilmoth` e `/gatemoth` respondem 200, e `/v1/species/veilmoth/evolutions` mostra a regra do nível 32.
- [x] `check_sheets.py` passa nas duas pastas, com o servidor no ar.
- [x] O `godot --headless -d --path client --quit-after 240` roda sem erro de script, com o `CatalogValidator` aceitando o catálogo.
- [x] Os testes de unidade e e2e do servidor passam, menos as falhas antigas. Em 2026-11-21: 1116 de unidade e 696 de 698 e2e; as 2 falhas (`species_day_phases` e `species_skills`, das espécies 7 a 9) já existiam.
- [ ] No F1 e no Bestiário, as duas espécies aparecem com o `front.png`, com a raridade Épico.
- [ ] No spawn de depuração de Explorar, as duas formas ficam paradas e andam.
- [ ] À Noite, o Veilmoth aparece no Boreal do mapa sorteado, e de Manhã não.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm test && npm run test:e2e
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/veilmoth/explore
python -I .claude/skills/creature-sprites/scripts/check_sheets.py client/assets/creatures/gatemoth/explore
godot --headless --path client --import
godot --headless -d --path client --quit-after 240
```

## Tarefas

- [x] Conferir os maiores ids no banco (35 e 63, como previsto).
- [x] A migração, aplicada com `migrate deploy`.
- [x] Os `front.png`.
- [x] As folhas do Veilmoth e do Gatemoth, com o `check_sheets.py`.
- [x] A verificação.

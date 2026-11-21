# 01. A arte da água

- **Status:** concluída (falta o dono aprovar a prévia)
- **Depende de:** [nature-variety/01](../nature-variety/01-nature-art.md)

## Contexto

As decorações moram na folha `client/assets/terrain/decorations/decorations.png`, uma linha de 48×64 por tipo, 4 variantes, com o pé em (24, 60). As linhas 0 a 50 já existem.

## Escopo

- O `client/assets/terrain/make_sea.py`, que desenha as linhas 51 a 63.
- Os tipos em `HexDecorations.KIND_ROWS`, `KIND_RADIUS` e `KIND_SWAY`.

## Os tipos

| Linha | Slug | Nome | Como é |
| --- | --- | --- | --- |
| 51 | `seagrass` | Capim-marinho | Folhas finas verdes, submersas, com as pontas mais claras |
| 52 | `kelp` | Alga longa | Fitas compridas de alga parda subindo do fundo, com boias na superfície |
| 53 | `algae_patch` | Tapete de algas | Uma mancha baixa de alga no fundo, só submersa |
| 54 | `sea_rock` | Pedra no mar | Pedra molhada que fura a superfície, com o anel de espuma no pé |
| 55 | `sunken_rock` | Pedra submersa | Pedra escura e transparente, embaixo d'água |
| 56 | `sea_stack` | Rochedo no mar | Pedra alta, com cracas e espuma no pé |
| 57 | `floating_weed` | Alga boiando | Um bolo de alga dourada boiando |
| 58 | `bottle` | Garrafa | Garrafa de vidro deitada, boiando |
| 59 | `can` | Lata | Lata amassada boiando |
| 60 | `plastic_bag` | Saco plástico | Saco claro e meio transparente |
| 61 | `fishing_net` | Rede de pesca | Pedaço de rede embolada, com uma boia |
| 62 | `tire` | Pneu | Pneu meio afundado |
| 63 | `crate` | Caixote boiando | Caixote de madeira meio afundado |

## Requisitos

- **RF-01:** O `make_sea.py` usa as funções do `make_nature.py` (o contorno escuro de 1 px, a luz de cima à esquerda e o pontilhado) e regrava só as linhas 51 a 63. Rodar duas vezes dá a mesma folha.
- **RF-02:** O que fica embaixo d'água tem alfa de 45% a 70%; o que fica acima é opaco, com espuma clara onde corta a superfície. Os tipos da água não têm a sombra no pé.
- **RF-03:** `KIND_RADIUS` de cada tipo pelo tamanho da arte, e `KIND_SWAY` para `seagrass`, `kelp`, `algae_patch`, `floating_weed`, `plastic_bag` e `fishing_net`.

## Critérios de aceite

- [ ] A prévia dos 13 tipos sobre a Água rasa e a Água profunda, aprovada pelo dono.
- [x] `godot --headless --path client --quit-after 30` sem erro de script.

## Tarefas

- [x] O `make_sea.py` e a prévia.
- [x] Os tipos em `HexDecorations`.

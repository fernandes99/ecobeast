# 02. O chão, os arremates, as decorações e o editor

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-biome-records.md)

## Contexto

O `HexMapView` desenha cada bioma pela textura `assets/terrain/surfaces/<slug>.png`, os arremates entre biomas e o escorrido nos paredões pelas folhas de `assets/terrain/transitions/`, e as plantas e pedras pela folha `assets/terrain/decorations/decorations.png`, escolhidas por `HexDecorations.RECIPES`. A arte de hoje é provisória, feita por script com ruído e carimbos ([wild-battle/04](../wild-battle/04-biome-surfaces.md)).

## Requisitos

- **RF-01:** `assets/terrain/make_desert_snow.py` (Python com Pillow) gera, sem imagem de terceiros:
  - `surfaces/desert.png` e `surfaces/snow.png`, de 512×512, emendando nas quatro bordas, no estilo das texturas de hoje;
  - as linhas 6 (Deserto) e 7 (Neve) de `transitions.png`, cada uma com as 3 variantes e as 6 bordas, no formato das outras;
  - as linhas 3 (Deserto) e 4 (Neve) de `drips.png`, curta e longa;
  - as linhas 17 a 22 de `decorations.png`, com 4 variantes cada: `cactus`, `sand_rock`, `snow_pine`, `snow_rock`, `snow_bush` e `snow_tuft`.

  Rodar o script de novo regrava as mesmas linhas, sem mexer nas outras.
- **RF-02:** `HexTransitions.SURFACE_ORDER` fica `desert`, `temperate`, `boreal`, `hill`, `snow`, `stone`, `mountain`, e o Deserto e a Neve ganham linha em `MATERIAL_ROWS` e `DRIP_ROWS`.
- **RF-03:** `HexDecorations` ganha os 6 tipos, com raio e vento (o cacto e as pedras parados), e as receitas:
  - Deserto: `cactus` 0,22 (1 a 2), `sand_rock` 0,14 (1), `dry_shrub` 0,18 (1), `pebbles` 0,12 (1 a 2), `dry_tuft` 0,3 (1 a 3);
  - Neve: `snow_pine` 0,4 (1 a 3), `snow_rock` 0,14 (1), `snow_bush` 0,24 (1 a 2), `snow_tuft` 0,4 (1 a 3).
- **RF-04:** No editor, o bloco Bioma mostra Deserto e Neve depois da Montanha, e o gerador da ilha nova tem "Parte de deserto" e "Parte de neve".
- **RF-05:** A luta aberta num hexágono de Deserto ou de Neve usa o chão dele no tabuleiro, sem mudança de código.

## Critérios de aceite

- [x] O jogo e o editor compilam sem erros de script e sem avisos.
- [x] Uma cena temporária monta um mapa com os dois biomas ao lado dos outros e confere a textura, os arremates, o escorrido e as decorações de cada um.
- [x] As texturas emendam nas bordas, e as folhas mantêm as linhas de antes iguais, pixel a pixel.
- [ ] No jogo, um mapa sorteado mostra Deserto e Neve, e a luta neles usa o chão certo (falta o dono conferir).

## Tarefas

- [x] O script da arte e as imagens.
- [x] `HexTransitions`, `HexDecorations` e o editor.
- [x] A documentação.

## Resultado da verificação

Em 2026-11-15:

- **A arte:** o script recolore pela luminância a textura da Colina (o chão dos dois), as linhas da Colina e da Planície nos arremates, as da Colina no escorrido e, nas decorações, o pinheiro, a pedra, o arbusto escuro, a pedra marrom e o capim seco. No pinheiro e no arbusto nevados, os tons mais claros de cada camada viram neve, e o alto da forma ganha uma borda de neve. O cacto é desenhado pelo script, em 4 formas.
- **As folhas:** as linhas de antes de `transitions.png`, `drips.png` e `decorations.png` ficaram iguais, pixel a pixel. Rodar o script duas vezes dá os mesmos arquivos.
- **As texturas** emendam nas bordas como a da Colina, de onde saem.
- **Uma cena temporária com janela** (apagada) montou à mão um mapa com Neve nas alturas 1 e 2, Boreal, Planície com uma ilha de neve, Colina, Deserto nas alturas 1 e 2, Pedra e Água rasa, e a captura foi aberta e revisada: o chão, os arremates da neve sobre a grama e a colina, o escorrido, a espuma na praia do deserto e as decorações de cada um.
- **O jogo e o editor** compilam sem erros de script, e o jogo sobe sem avisos novos. O único aviso (`sign` em `hex_bridges.gd`) é da [bridges](../bridges/).
- **Não conferido:** o mapa sorteado e a luta com o jogo aberto, e o bloco Bioma e o gerador da ilha nova no editor aberto.
- **Limite:** o chão do Deserto e o da Neve guardam as marquinhas do capim da Colina, como ondulações na areia e na neve. É arte provisória, como a dos outros biomas.

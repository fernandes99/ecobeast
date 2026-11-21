# 01. A arte da Geleira

- **Status:** concluída (falta o dono conferir a categoria e o grupo no F2)
- **Depende de:** [desert-snow/02](../desert-snow/02-biome-art.md) (o caminho do chão), [sea-life/01](../sea-life/01-sea-art.md) e [sea-life/03](../sea-life/03-sea-props.md) (as decorações que viram peças)

## Contexto

Um bioma no jogo é:

- a textura `client/assets/terrain/surfaces/<slug>.png`;
- uma linha em `transitions.png` (`HexTransitions.MATERIAL_ROWS`) e outra em `drips.png` (`DRIP_ROWS`);
- o lugar em `SURFACE_ORDER`;
- a receita em `HexDecorations.RECIPES`, pelo slug da zona (a Comum tem o slug do bioma).

As decorações moram em `client/assets/terrain/decorations/decorations.png`, uma linha de 48×64 por tipo, 4 variantes, com o pé em (24, 60). As linhas 0 a 65 já existem. Um tipo de peça cujo slug está em `HexDecorations.KIND_ROWS` é desenhado pela folha (`PropArt`), sem arte própria.

Esta fase não mexe no gerador do servidor (`map-generator.ts`), que a [rolling-hills](../rolling-hills/) está mudando. Por isso o bioma só entra no catálogo na [03](03-glacier-records.md), e o chão é conferido aqui pela prévia e por uma cena temporária.

## Escopo

- O `client/assets/terrain/make_glacier.py`: o chão, os arremates, o escorrido e as decorações.
- A prévia para o dono, e só depois da aprovação os arquivos do jogo.
- O slug `glacier` no cliente: as tabelas de arremate, o paredão de rocha, a cor do minimapa e as receitas.
- As decorações novas como tipos de peça solta, no grupo Geleira do pincel.

## Fora do escopo

- As pedras grandes de gelo ([02](02-ice-rocks.md)).
- O bioma no catálogo e a amostra no bloco Bioma do F2 ([03](03-glacier-records.md)).

## Os tipos

Linhas da folha a partir da 66, na ordem da tabela. Esta é a proposta, e a prévia pode tirar ou trocar tipos.

| Slug | Nome | Como é | Onde |
| --- | --- | --- | --- |
| `ice_crack` | Rachadura no gelo | Linhas finas e claras, rente ao chão | Comum |
| `ice_bubbles` | Bolhas no gelo | Pontos claros meio transparentes, sob a superfície | Comum |
| `ice_chips` | Lascas de gelo | Três ou quatro lascas pequenas e afiadas | Comum |
| `snow_drift` | Neve soprada | Um montinho baixo de neve, com a sombra azul | Comum |
| `frozen_fish` | Peixe no gelo | Um peixe parado sob o gelo, visto de cima, meio apagado | Comum, raríssimo |
| `ice_floe` | Placa de gelo | Uma placa branca boiando, com a espuma em volta | Lago gelado |

## Requisitos

- **RF-01:** O `make_glacier.py` usa as funções do `make_nature.py` (o contorno escuro de 1 px, a luz de cima à esquerda e o pontilhado) e grava:
  - `surfaces/glacier.png`, no tamanho das outras superfícies: gelo azul-claro liso, com veios e pontos de brilho, distinto da Neve (branca e fofa) e da água;
  - a linha da Geleira no `transitions.png` e no `drips.png`;
  - as linhas das decorações da tabela.

  Ele regrava só essas linhas. Rodar duas vezes dá os mesmos arquivos. `--preview <arquivo>` grava a prévia sem mexer nos arquivos do jogo.
- **RF-02:** A prévia mostra, ampliada 3 vezes:
  - um trecho de Geleira com as decorações da Comum;
  - a divisa com a Neve e com a Pedra;
  - um paredão;
  - um lago com as placas de gelo.

  Os arquivos do jogo só são gravados depois que o dono aprova. Ele aprovou a prévia em 2026-11-21, sem ajustes.
- **RF-03:** No `HexTransitions`:
  - `glacier` entra em `SURFACE_ORDER` logo antes de `snow`;
  - `MATERIAL_ROWS["glacier"]` é a linha nova do `transitions.png`;
  - `DRIP_ROWS["glacier"]` é a linha nova do `drips.png`.
- **RF-04:** `glacier` entra em `HexMapView.CLIFF_BIOMES`, e a cor dele entra no `minimap_palette.gd`, um azul-claro diferente do `#eef3f6` da Neve: `#9fd4ee`.
- **RF-05:** O `HexDecorations` ganha os tipos (`KIND_ROWS`, `KIND_RADIUS`; nenhum balança) e três receitas:
  - `glacier`: rachaduras (0,45, de 1 a 2), bolhas (0,3), lascas (0,28, de 1 a 2), neve soprada (0,3), `ice_shards` (0,12) e o peixe raríssimo (0,03), as densidades da prévia;
  - `wshallow_ice_lake`: placas de gelo (0,35, de 1 a 2);
  - `wdeep_ice_lake`: placas de gelo, mais raras (0,15).

  Os raios no chão (`KIND_RADIUS`): rachadura 9, bolhas 6, lascas 6, neve soprada 8, peixe 7 e placa 9.
- **RF-06:** O `frozen_fish` e o `ice_bubbles` ficam por baixo da superfície: alfa de 45% a 70% e sem a sombra no pé, como o que fica embaixo d'água na `sea-life`.
- **RF-07:** A migration `glacier_props`:
  - insere a categoria `glacier` "Geleira" em `prop_categories`;
  - insere nela os tipos de peça a partir do 165, na ordem da tabela, com o nome dela e 4 variantes.

  Os ids são conferidos no banco antes: a categoria é a 15, e os tipos vão do 165 ao 170.
- **RF-08:** O pincel Vegetação (`vegetation_panel.gd`) ganha o grupo "Geleira", no fim, com os tipos desta fase (1 por hexágono). O peixe e a placa começam desligados: o peixe é raríssimo, e a placa é da água. As pedras de gelo ficam no grupo seguinte, Pedras de gelo ([02](02-ice-rocks.md)).

## Critérios de aceite

- [x] A prévia aprovada pelo dono.
- [x] Uma cena temporária em `client/zz_tmp_check`, apagada depois, desenha um mapa com hexágonos `glacier` ao lado de `snow` e de `stone`, com o chão, o arremate, o paredão de rocha e a receita, sem erro.
- [ ] A ferramenta Peças mostra a categoria Geleira, e o pincel tem o grupo Geleira. O catálogo já serve a categoria 15 e os tipos 165 a 170; falta o dono abrir o F2.
- [x] `godot --headless --path client --quit-after 60` sem erro de script.
- [x] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [x] O `make_glacier.py` e a prévia para o dono.
- [x] Depois da aprovação: os arquivos do jogo, o `HexTransitions`, o `CLIFF_BIOMES`, o minimapa e o `HexDecorations`.
- [x] A migration (`20270201000000_glacier_props`), aplicada no banco, e o grupo do pincel.

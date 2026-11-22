# 01. A arte do Vulcão e da lava

- **Status:** pendente
- **Depende de:** [glacier/01](../glacier/01-glacier-art.md) (o caminho do chão e das decorações que viram peças) e [water-motion](../water-motion/) (a superfície que se mexe)

## Contexto

Um bioma no jogo é:

- a textura `client/assets/terrain/surfaces/<slug>.png`;
- uma linha em `transitions.png` (`HexTransitions.MATERIAL_ROWS`) e outra em `drips.png` (`DRIP_ROWS`);
- o lugar em `SURFACE_ORDER`;
- a receita em `HexDecorations.RECIPES`, pelo slug da zona (a Comum tem o slug do bioma).

As decorações moram em `client/assets/terrain/decorations/decorations.png`: uma linha de 48×64 por tipo, com 4 variantes e o pé em (24, 60). As linhas 0 a 71 já existem.

A água rasa e a funda se mexem no `hex_grounds.gdshader` (o código 4 é a superfície, com a funda no z). O `day_light.gdshader` escurece o mapa à noite e desenha as luzes e os vagalumes.

Esta fase só mexe no cliente e numa migration de peças. Os biomas entram no catálogo na [03](03-volcano-records.md), então o chão é conferido aqui pela prévia e por uma cena temporária.

## Escopo

- O `client/assets/terrain/make_volcano.py`: o chão, a lava, os arremates, o escorrido e as decorações.
- A prévia para o dono. Os arquivos do jogo só são gravados depois da aprovação.
- Os slugs `volcano`, `lshallow` e `ldeep` no cliente: as tabelas de arremate, o paredão, o minimapa, as receitas e o andar bloqueado na lava.
- A lava se mexendo e brilhando à noite.
- As decorações novas como tipos de peça solta, na categoria Vulcão e no grupo Vulcão do pincel.

## Fora do escopo

- Os picos de basalto ([02](02-basalt-spires.md)).
- Os biomas no catálogo e as amostras no F2 ([03](03-volcano-records.md)).

## Os tipos

Linhas da folha a partir da 72, na ordem da tabela. Esta é a proposta, e a prévia pode tirar ou trocar tipos.

| Slug | Nome | Como é | Onde |
| --- | --- | --- | --- |
| `basalt_pebbles` | Pedrinhas de basalto | Três a cinco pedrinhas escuras e angulosas | Comum do Vulcão |
| `lava_crack` | Rachadura de lava | Uma rachadura rente ao chão, com o fundo laranja aceso | Comum do Vulcão |
| `fumarole` | Fumarola | Uma boca de pedra no chão soltando um fio de fumaça clara, parada | Comum do Vulcão |
| `burnt_tree` | Árvore queimada | Um tronco preto e seco, sem folhas, com galhos quebrados | Comum do Vulcão, rara |
| `ash_patch` | Cinza | Uma mancha de cinza cinza-clara no chão | Comum do Vulcão |
| `obsidian` | Obsidiana | Uma lasca preta e brilhante, com o reflexo roxo | Comum do Vulcão, rara |
| `lava_crust` | Crosta de lava | Uma placa escura e rachada boiando, com as frestas acesas | Lava rasa |

## Requisitos

- **RF-01:** O `make_volcano.py` usa as funções do `make_nature.py` (o contorno escuro de 1 px, a luz de cima à esquerda e o pontilhado) e grava:
  - `surfaces/volcano.png`: rocha vulcânica escura, entre o cinza-chumbo e o marrom, áspera, com grãos e poucos pontos avermelhados. Ela tem que ficar diferente da Pedra e da Montanha;
  - `surfaces/lshallow.png`: lava laranja e amarela, clara, com veios mais claros;
  - `surfaces/ldeep.png`: lava vermelha-escura, quase marrom nas bordas dos veios, com pontos laranja;
  - as linhas dos três slugs no `transitions.png` e no `drips.png`;
  - as linhas das decorações da tabela.

  Ele regrava só essas linhas, e rodar duas vezes dá os mesmos arquivos. `--preview <arquivo>` grava a prévia sem mexer nos arquivos do jogo.
- **RF-02:** A prévia mostra, ampliada 3 vezes:
  - um trecho de Vulcão com as decorações da Comum;
  - a divisa com a Planície, com o Boreal e com a Montanha;
  - um paredão de Vulcão;
  - um lago de lava funda cercado de lava rasa, com as crostas, e o chão de Vulcão em volta;
  - o mesmo lago com o filtro da noite (uma simulação no Python basta).

  Os arquivos do jogo só são gravados depois que o dono aprova.
- **RF-03:** No `HexTransitions`:
  - `volcano` entra em `SURFACE_ORDER`. O lugar é escolha do construtor, a cinza do Vulcão avançando sobre a borda dos vizinhos de terra;
  - a lava entra como a água entra hoje, com a rasa e a funda no mesmo esquema da `wshallow` e da `wdeep`;
  - `MATERIAL_ROWS` e `DRIP_ROWS` ganham as linhas novas.
- **RF-04:** `volcano` entra em `HexMapView.CLIFF_BIOMES`, com o paredão de rocha (`cliff.png`). A lateral de um hexágono de lava também é de rocha: a lava não vira cachoeira.
- **RF-05:** As cores do minimapa (`minimap_palette.gd`):
  - `volcano` `#3b3433`;
  - `lshallow` `#ff8a1e`;
  - `ldeep` `#c2361a`.
- **RF-06:** No `HexTile`, a lava bloqueia o andar (`blocks_walking`), como a água, mas não é água (`is_water` continua só com a `wshallow` e a `wdeep`). Ninguém pesca, nada boia nem há ponte sobre a lava.
- **RF-07:** A lava se mexe no `hex_grounds.gdshader`, pelo caminho da água:
  - a superfície corre mais devagar que a água, sem espuma;
  - o brilho pulsa devagar, com a rasa mais clara que a funda;
  - tudo em pixels inteiros, como a água.

  O código do material da lava é escolha do construtor.
- **RF-08:** À noite, no `day_light.gdshader`:
  - a lava não escurece com o filtro;
  - ela solta uma luz fraca e alaranjada em volta, de até 1 hexágono, sem contar no limite de `MAX_LIGHTS` das peças.

  Como o shader sabe onde está a lava (uma máscara, um canal, uma lista de pontos) é escolha do construtor. De dia, nada muda.
- **RF-09:** O `HexDecorations` ganha os tipos (`KIND_ROWS`, `KIND_RADIUS`; nenhum balança) e duas receitas:
  - `volcano`: pedrinhas, rachadura, fumarola, cinza, e a árvore queimada e a obsidiana mais raras. As densidades saem da prévia;
  - `lshallow`: crostas de lava.

  A lava funda fica sem decoração. A `lava_crack` e a `lava_crust` também acendem à noite (o RF-08).
- **RF-10:** A migration `volcano_props`:
  - insere a categoria `volcano` "Vulcão" em `prop_categories`;
  - insere nela os tipos de peça a partir do 177, na ordem da tabela, com o nome dela e 4 variantes.

  Os ids são conferidos no banco antes.
- **RF-11:** O pincel Vegetação (`vegetation_panel.gd`) ganha o grupo "Vulcão", no fim, com os tipos desta fase. A crosta começa desligada, porque é da lava.

## Critérios de aceite

- [ ] A prévia aprovada pelo dono.
- [ ] Uma cena temporária em `client/zz_tmp_check`, apagada depois, desenha um mapa com `volcano`, `lshallow` e `ldeep` ao lado de `temperate`, `boreal` e `mountain`, com o chão, o arremate, o paredão, a lava se mexendo, a receita e a noite, sem erro.
- [ ] No F2, a ferramenta Peças mostra a categoria Vulcão, e o pincel tem o grupo Vulcão. Fica para o dono conferir.
- [ ] `godot --headless --path client --quit-after 60` sem erro de script.
- [ ] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [ ] O `make_volcano.py` e a prévia para o dono.
- [ ] Depois da aprovação: os arquivos do jogo, o `HexTransitions`, o `CLIFF_BIOMES`, o minimapa, o `HexTile` e o `HexDecorations`.
- [ ] A lava no `hex_grounds.gdshader` e a luz dela no `day_light.gdshader`.
- [ ] A migration, aplicada no banco, e o grupo do pincel.

# 01. A arte do Vulcão e da lava

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [glacier/01](../glacier/01-glacier-art.md) (o caminho do chão e das decorações que viram peças) e [water-motion](../water-motion/) (a superfície que se mexe)

## Contexto

Um bioma no jogo é:

- a textura `client/assets/terrain/surfaces/<slug>.png`;
- uma linha em `transitions.png` (`HexTransitions.MATERIAL_ROWS`) e outra em `drips.png` (`DRIP_ROWS`);
- o lugar em `SURFACE_ORDER`;
- a receita em `HexDecorations.RECIPES`, pelo slug da zona (a Comum tem o slug do bioma).

As decorações moram em `client/assets/terrain/decorations/decorations.png`: uma linha de 48×64 por tipo, com 4 variantes e o pé em (24, 60). As linhas 0 a 71 já existiam.

A água rasa e a funda se mexem no `hex_grounds.gdshader` (o código 4 é a superfície, com a funda no z). O `day_light.gdshader` escurece o mapa à noite e desenha as luzes e os vagalumes.

Esta fase só mexe no cliente e numa migration de peças. Os biomas entram no catálogo na [03](03-volcano-records.md), então o chão é conferido aqui pela prévia e por cenas temporárias.

## Escopo

- O `client/assets/terrain/make_volcano.py`: o chão, a lava, o paredão, os arremates, o escorrido e as decorações.
- A prévia para o dono. Os arquivos do jogo só são gravados depois da aprovação.
- Os slugs `volcano`, `lshallow` e `ldeep` no cliente: as tabelas de arremate, o paredão, o minimapa, as receitas e o andar bloqueado na lava.
- A lava se mexendo e brilhando à noite.
- As decorações novas como tipos de peça solta, na categoria Vulcão e no grupo Vulcão do pincel.

## Fora do escopo

- Os picos de basalto ([02](02-basalt-spires.md)).
- Os biomas no catálogo e as amostras no F2 ([03](03-volcano-records.md)).

## Na revisão da prévia

O dono aprovou a prévia em 2026-11-22, depois de quatro pedidos:

- "A textura do vulcção ficou ruim": o chão virou placas de basalto resfriado, com rachaduras, borda clara em cima e sombra embaixo, no traço da Pedra e da Montanha.
- "A lava deve seguir o mesmo principio, vai ficar com uma altura a menos": a lava fica um nível abaixo do chão em volta, como a água. A [04](04-land-volcano.md) põe o piso da cratera no 6 e a lava no 5.
- "A decoração de racachura de lava ta muito estranha, talvez ela deve ser mais grossa e com bloqueio": a rachadura virou uma fenda grossa, com o miolo de lava, a parede de dentro e a crosta em volta. Como bloqueia, ela é só peça, fora do sorteio do chão.
- "a parede dessee bioma ta estranha": o Vulcão ganhou o paredão próprio de colunas de basalto. Parte do estranho era um buraco da prévia (o arredondamento pulava linhas nas paredes inclinadas), que só existia nela.

## Os tipos

Linhas da folha de 72 a 78, na ordem da tabela, e tipos de peça de 177 a 183.

| Slug | Nome | Como é | Onde |
| --- | --- | --- | --- |
| `basalt_pebbles` | Pedrinhas de basalto | Três a cinco pedrinhas escuras e angulosas | Comum do Vulcão |
| `lava_crack` | Rachadura de lava | Uma fenda grossa, com a lava do vermelho ao amarelo, a parede de dentro e a crosta em volta. Bloqueia | Só peça (F2 e a [04](04-land-volcano.md)) |
| `fumarole` | Fumarola | Uma boca de pedra no chão soltando um fio de fumaça clara, parada | Comum do Vulcão |
| `burnt_tree` | Árvore queimada | Um tronco preto e seco, sem folhas, com galhos quebrados | Comum do Vulcão, rara |
| `ash_patch` | Cinza | Uma mancha de cinza cinza-clara no chão | Comum do Vulcão |
| `obsidian` | Obsidiana | Uma lasca preta e brilhante, com o reflexo roxo | Comum do Vulcão, rara |
| `lava_crust` | Crosta de lava | Uma placa escura e rachada boiando, com as frestas acesas | Lava rasa |

## Requisitos

- **RF-01:** O `make_volcano.py` usa as funções do `make_nature.py` e do `make_glacier.py` e grava:
  - `surfaces/volcano.png`: placas de basalto escuro (um Voronoi que se repete, com a borda torta), rachaduras, a borda de cima clara e a de baixo com sombra, manchas suaves, poros, cinza, rachaduras finas e poucas brasas apagadas;
  - `surfaces/volcano_cliff.png`: o paredão de colunas de basalto, no formato do `cliff.png` (512×64, com a metade de baixo se repetindo nos paredões altos);
  - `surfaces/lshallow.png`: lava laranja e amarela, clara, com veios mais claros;
  - `surfaces/ldeep.png`: lava vermelha, com veios e pontos laranja;
  - as linhas 10 (a borda do Vulcão), 11 (a crosta que a lava recebe da terra) e 12 (a lava rasa avançando sobre a funda) do `transitions.png`, e a 7 do `drips.png`;
  - as linhas das decorações da tabela.

  Ele regrava só essas linhas, e rodar duas vezes dá os mesmos arquivos. `--preview <arquivo>` grava a prévia sem mexer nos arquivos do jogo. O `make_glacier.py` e o `make_beach_life.py` deixaram de cortar a folha de decorações, que apagava as linhas dos scripts seguintes.
- **RF-02:** A prévia mostra, ampliada 3 vezes, o Vulcão com a Planície, o Boreal e a Montanha, um paredão, um lago de lava um nível abaixo, as decorações, a mesma cena à meia-noite e a linha de bloqueio da rachadura.
- **RF-03:** No `HexTransitions`:
  - `volcano` fica no fim de `SURFACE_ORDER` e avança sobre todos os vizinhos de terra;
  - a lava, como a água, fica fora de `SURFACE_ORDER`: ela recebe a crosta (`lava_crust`) da terra e nada da água, e só a funda recebe a borda da rasa;
  - `MATERIAL_ROWS` ganha `volcano` 10, `lava_crust` 11 e `lshallow` 12, e `DRIP_ROWS` ganha `volcano` 7.
- **RF-04:** O `HexMapView.face_texture` dá `volcano_cliff` ao Vulcão e à lava (`VOLCANO_CLIFF`): a lava não vira cachoeira. O `_tint`, o `_add_grounds` e o `_add_lips` pulam a lava como pulam a água.
- **RF-05:** As cores do minimapa (`minimap_palette.gd`): `volcano` `#3b3433`, `lshallow` `#ff8a1e` e `ldeep` `#c2361a`.
- **RF-06:** No `HexTile`, a lava (`LAVA_BIOMES`, `is_lava`) bloqueia o andar (`blocks_walking`), mas não é água (`is_water` continua só com a `wshallow` e a `wdeep`). A ponta de uma ponte não fica na lava (`IslandDraft.bridge_end_ok`).
- **RF-07:** A lava corre no `hex_grounds.gdshader` pelo código 10 (`HexMapView.LAVA_CODE`), com a funda no z: a deriva e a onda da água, mais devagar, sem espuma, e um pulso que só clareia (até 8%), em pixels inteiros e com as voltas fechando em 3.600 s.
- **RF-08:** À noite, no `day_light.gdshader`:
  - a lava não escurece: o pixel na chave de cor (R ≥ 0,33 e B ≤ 0,06) **dentro de um hexágono de lava**. O `DayLightLayer.set_lava_map` manda uma imagem com um pixel por hexágono (a lava e a altura), e o shader acha o hexágono como o `fog.gdshader`. Só a cor não serve: a arte da vila (telhados com o azul em 0), o trigo e o Ruvo caem na chave;
  - as bordas do lago (os hexágonos de lava com um vizinho que não é lava, `HexMapView.lava_glows`) soltam uma luz laranja de 40 px, até 48 por vez (`DayLightLayer.set_lava_glows`), fora do limite das luzes das peças. A exploração entrega as visíveis, das mais perto do Domador para as mais longe.

  De dia, nada muda.
- **RF-09:** O `HexDecorations` ganha os tipos (`KIND_ROWS` 72 a 78 e `KIND_RADIUS`; nenhum balança) e duas receitas: `volcano` (pedrinhas, fumarola, cinza, e a árvore queimada e a obsidiana mais raras) e `lshallow` (crostas). A lava funda fica sem decoração, e a rachadura fica fora das receitas.
- **RF-10:** A migration `20270202000000_volcano_props`:
  - insere a categoria 16 `volcano` "Vulcão";
  - insere nela os tipos 177 a 183, na ordem da tabela, com 4 variantes;
  - dá à rachadura (178) uma linha fechada de bloqueio por variante, pela borda da crosta, saída do `fissure_blocks()` do script;
  - dá à rachadura uma luz laranja por variante (`prop_type_lights`, raio 26) no meio da fenda.
- **RF-11:** O pincel Vegetação (`vegetation_panel.gd`) ganha o grupo "Vulcão", no fim, com os 7 tipos. A crosta começa desligada, porque é da lava.

## Critérios de aceite

- [x] A prévia aprovada pelo dono.
- [x] Uma cena temporária sem janela confere o andar bloqueado, os arremates (a crosta, a borda da rasa e nada entre a lava e a água), o paredão, as receitas e as cores do minimapa, e monta o mapa sem erro.
- [x] Uma cena temporária com janela fotografa a lava em dois tempos: 14.523 pixels mudam, todos na lava, e nenhum fora dela. À meia-noite, a lava fica acesa e o chão escurece, e a lista das bordas aceita no máximo 48.
- [ ] No F2, a ferramenta Peças mostra a categoria Vulcão, a rachadura bloqueia o Domador, e o pincel tem o grupo Vulcão. Fica para o dono conferir.
- [x] `godot --headless --path client --quit-after 60` sem erro de script.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [x] O `make_volcano.py` e a prévia para o dono.
- [x] Depois da aprovação: os arquivos do jogo, o `HexTransitions`, o paredão, o minimapa, o `HexTile` e o `HexDecorations`.
- [x] A lava no `hex_grounds.gdshader` e a luz dela no `day_light.gdshader`.
- [x] A migration (`20270202000000_volcano_props`), aplicada no banco, e o grupo do pincel.

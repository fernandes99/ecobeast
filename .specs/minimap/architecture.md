# minimap: arquitetura

O desenho que as duas fases compartilham: a imagem do mapa descoberto, as cores, os marcadores e a arte.

## A imagem do mapa (`MinimapImage`)

Uma imagem só, montada ao entrar no mapa e atualizada a cada descoberta, serve ao minimapa e ao mapa grande.

- **Classe:** `res://ui/components/minimap_image.gd`, `class_name MinimapImage`, `RefCounted`. Ela usa `Image` e `ImageTexture` e, por isso, mora em `ui/components/` e não em `domain/`.
- **Escala:** cada pixel da imagem vale `ART_PER_PIXEL` (16) pixels da arte no chão plano, _a revisar_. Um hexágono (64×42 de passo) vira uns 4×3 pixels. Uma ilha de raio 80 dá uma imagem de uns 650×430 pixels.
- **Origem e tamanho:** o retângulo que cobre o topo plano de todos os hexágonos do mapa, do menor `HexMapView._tile_origin` até o maior mais `(64, 58)` (a caixa do `HEX_CORNERS`), com o canto de cima à esquerda arredondado para baixo num múltiplo de `ART_PER_PIXEL`.
- **Dono de cada pixel:** o hexágono da grade plana no centro do pixel (`HexMapView.grid_coord(origem + (pixel + 0,5) × ART_PER_PIXEL)`). A altura é ignorada: o minimapa é uma planta vista de cima. Um pixel sem hexágono no mapa tem a cor da névoa, como o não descoberto, para a beira do mapa não entregar o contorno.
- **O molde:** a grade se repete. Andar 64 px da arte leva ao hexágono do lado, e 336 px para baixo leva ao hexágono `(-4, 8)`; com 16 px por pixel, isso é 4 pixels de lado e 21 para baixo. Por isso, os pixels de um hexágono (`pixels_of`) são os do molde da linha dele (`r` módulo 8), calculados uma vez, deslocados. A imagem não pergunta o dono pixel a pixel. Mudou na implementação: perguntar pixel a pixel levava 441 ms numa ilha de raio 80; com o molde, 70 ms.
- **Cor de um pixel descoberto**, nesta ordem:
  1. a cor do bioma do dono (`MinimapPalette.BIOMES`);
  2. o chão do dono (`HexTile.ground`), quando há: `TRAIL` para os tipos de trilha e `FLOOR` para os de piso, pelo `HexGrounds.kind_of`;
  3. os traços de caminho (`ExplorationMap.trails`), pelo ponto mais perto do traço (`HexGrounds.trail_distance` até metade da largura): `TRAIL` ou `FLOOR`, pelo tipo do traço;
  4. as pontes (`ExplorationMap.bridges`), na largura delas: `BRIDGE`;
  5. a sombra da costa: um pixel de terra com o pixel de baixo em água (`HexTile.WATER_BIOMES`, menos o Vau) fica `SHORE_SHADE` mais escuro.
- **Névoa:** um pixel cujo dono não foi descoberto (`MapDiscovery.is_discovered`) é `MinimapPalette.FOG`, opaco. Um pixel de um hexágono escondido vizinho de um descoberto mistura a cor dele com a névoa pela metade (`GLIMPSE`, 0,5, o mesmo valor da `FogLayer`). Não há degradê nem ruído: a borda segue o desenho dos hexágonos, em pixels inteiros.
- **Guardado:** a cor de cada hexágono, os pixels com cor própria (a sombra da costa, os caminhos e as pontes) e quanto aparece cada hexágono que não está na névoa. A imagem começa toda na névoa (`Image.fill`), e só os hexágonos que aparecem são pintados.
- **API:**
  - `build(map: ExplorationMap, discovery: MapDiscovery, show_all: bool)`: monta tudo. Com `show_all`, ignora a névoa (o "Debug: ver mapa inteiro").
  - `reveal(coords: Array[Vector2i])`: repinta só os pixels dos hexágonos novos e do anel de 1 em volta deles (o retângulo de cada um, conferindo o dono), e marca a textura para atualizar uma vez no quadro.
  - `texture: ImageTexture`, `image_size: Vector2i`.
  - `art_to_image(flat: Vector2) -> Vector2`: de um ponto do chão plano para o ponto da imagem, em pixels da imagem (com fração).
  - `pixels_of(coord)`, `owner_at(pixel)` e `snapshot()` (uma cópia da imagem, para os testes: sem janela, a textura não devolve a atualizada).
- **Custo:** medido sem janela num computador, uma ilha de raio 80 (19.441 hexágonos, imagem de 644×424) monta em 70 ms, e um passo do Domador repinta em menos de 1 ms. No celular, deve ficar entre 2 e 4 vezes isso, uma vez, na entrada.

## As cores (`MinimapPalette`)

`res://ui/components/minimap_palette.gd`, `class_name MinimapPalette`, só constantes. Todas são _a revisar_ e puxam a cor de cada bioma no jogo.

| Chave | Cor |
| --- | --- |
| `temperate` (Planície) | `#6fa84a` |
| `boreal` | `#3f7a4a` |
| `stone` (Pedra) | `#8b8b80` |
| `hill` (Colina) | `#9aa65a` |
| `mountain` (Montanha) | `#8a7766` |
| `wshallow` (Água rasa) | `#4f8fc0` |
| `wdeep` (Água profunda) | `#2c5a8c` |
| `desert` (Deserto) | `#d9b35e` |
| `snow` (Neve) | `#eef3f6` |
| `beach` (Praia) | `#e3cf8f` |
| `wford` (Vau) | `#6f9fb8` |
| `TRAIL` | `#a8814f` |
| `FLOOR` | `#b9a58a` |
| `BRIDGE` | `#7a5430` |
| `FOG` | `UiPalette.BACKGROUND_DEEP` (`#0A1A2B`) |
| `SHORE_SHADE` | multiplica a cor por 0,72 |

Um bioma que não está na tabela usa a cor da Planície e avisa uma vez no console (`push_warning`), para um bioma novo não quebrar o minimapa.

## Os marcadores (`MapMarker`)

Cada ícone por cima do mapa é um marcador: `res://ui/components/map_marker.gd`, `class_name MapMarker`, `RefCounted`, com:

- `kind: StringName`: `&"refuge"`, `&"shop"` ou `&"npc"` (e, no futuro, os de missão);
- `flat: Vector2`: o ponto no chão plano;
- `coord: Vector2i`: o hexágono que precisa estar descoberto para ele aparecer;
- `npc: NpcSprite`: o NPC que ele segue, ou `null`.

`MapMarker.shown(markers, discovery, show_all)` devolve os que aparecem.

A tela de Explorar monta a lista uma vez, ao entrar no mapa:

- **O Refúgio e a Loja de uma ação** (`MapAction` com o tipo de `slug` `refuge` ou `shop`): o centro (`HexMapView.flat_center`) do hexágono do meio, `BuildingNamesLayer.middle_of(action.tiles)`.
- **O Refúgio e a Loja de uma peça** (`MapProp.action_type_id` com esse tipo): o pé dela, `flat_center(prop.coord) + prop.offset`, e o hexágono `prop.coord`.
- **Os NPCs:** um por `NpcSprite`, com `coord` e `flat` lidos do sprite a cada quadro em que o minimapa ou o mapa grande se desenha (`flat_center(sprite.coord)`), para o que passeia aparecer onde está.

O desenho de cada `kind` está em `MinimapArt.icon(kind)`. Um `kind` novo, como o de missão, só precisa do desenho e de quem o põe na lista.

## A arte (`MinimapArt` e `make_minimap_art.py`)

- **Gerador:** `res://assets/ui/minimap/make_minimap_art.py` (Python com Pillow, como o `make_day_phase_icons.py`) desenha em pixel art, com a paleta Ouro do [guia de estilo](../town-art/style-guide.md#paletas) (`#fff090`, `#f8c838`, `#c8901c`, `#7a5410`), a luz de cima à esquerda e o contorno de 1 px na cor mais escura:
  - `ring.png`: a moldura redonda do minimapa, 64×64, com o furo do mapa de 48 px de diâmetro transparente, quatro enfeites nas diagonais e uma pedra vermelha em cima;
  - `frame.png`: a moldura retangular do mapa grande, em 9 partes (cantoneiras de 9×9 e a borda de 5 px), para um `NinePatchRect`;
  - `mask.png`: o furo do anel, 48×48, para recortar o mapa (`clip_children`);
  - `pin.png` (5×6), `refuge.png`, `shop.png` e `npc.png` (7×7): o pino do Domador e os ícones. O Refúgio é um coração vermelho num fundo creme, a Loja uma bolsa dourada e o NPC um balão de fala branco, como nos modelos aprovados.
- **Leitura:** `res://ui/components/minimap_art.gd`, `class_name MinimapArt`, com `static func icon(kind: StringName) -> Texture2D` e as constantes dos caminhos.
- **Escala:** a arte é desenhada em pixels de 1 e mostrada em `ART_SCALE` (3) pixels da tela lógica por pixel, com o filtro `TEXTURE_FILTER_NEAREST`, _a revisar_. A imagem do mapa usa a mesma escala no minimapa; no mapa grande, a do zoom.

## A noite

O minimapa e o mapa grande são interface: ficam no `SafeArea`, fora do `MapArea`, e a luz da hora (`DayLightLayer`) não os escurece, como o selo da parte do dia.

## O pixel nítido

Tudo o que o minimapa e o mapa grande desenham usa `TEXTURE_FILTER_NEAREST` e posições arredondadas para pixels inteiros da escala em uso. Como o `HexMapView`, a escala é inteira na tela lógica. Uma diferença de 1 px real entre colunas por causa do esticamento da janela (`canvas_items`) é aceita: é a mesma do resto da UI.

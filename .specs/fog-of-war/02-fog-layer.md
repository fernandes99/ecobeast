# 02. A névoa no mapa de Explorar

- **Status:** concluída
- **Depende de:** [camera-zoom/01](../camera-zoom/01-explore-zoom.md), [fireflies/01](../fireflies/01-fireflies.md)

## Contexto

Hoje o mapa de Explorar aparece inteiro, e no zoom 1 dá para ver quase a ilha toda. Esta fase cobre com a névoa o que o Domador ainda não descobriu, no mapa sorteado e nas ilhas ([README](README.md#decisões)). A descoberta ainda fica só na memória da tela: nas ilhas, ela recomeça a cada entrada até a [03](03-island-memory.md).

## Escopo

- O modelo `MapDiscovery`, com os hexágonos descobertos e a descoberta em volta do Domador.
- A camada `FogLayer`, com a máscara no espaço da arte e o shader da borda irregular.
- Na tela `exploration`: descobrir ao entrar e a cada hexágono novo, esconder as luzes, os vagalumes e os nomes das construções que estão na névoa, e o "ver mapa inteiro" apagando a névoa.

## Fora do escopo

- Guardar a descoberta no servidor (fase 03).
- A névoa na luta, no editor (F2) e no Desafiar.
- Linha de visão, paredes ou altura mudando o raio.

## Requisitos

- **RF-01:** `MapDiscovery` (`res://domain/models/map_discovery.gd`, `class_name MapDiscovery`, `RefCounted`) guarda os hexágonos descobertos (`Dictionary[Vector2i, bool]`) e tem `is_discovered(coord) -> bool`, `add(coords: Array[Vector2i])` e `reveal_around(map: ExplorationMap, center: Vector2i) -> Array[Vector2i]`. Este último descobre os hexágonos do mapa a até `REVEAL_RADIUS` de `center` por `ExplorationMap.distance` e devolve só os que eram novos. `REVEAL_RADIUS = 4`, _a revisar_.
- **RF-02:** Ao carregar o mapa, a tela `exploration` cria a descoberta e chama `reveal_around` no ponto de partida (`_map.start`). A cada vez que o Domador entra num hexágono novo (onde `_player_coord` muda), chama de novo, e os hexágonos novos vão para a névoa.
- **RF-03:** `FogLayer` (`res://ui/components/fog_layer.gd`, `class_name FogLayer`, um `ColorRect` com `mouse_filter` ignorado) fica em `MapArea`, entre o `MapView` e o `DayLight`, cobrindo a mesma área que o `DayLight`. Ela recebe a vista como o `DayLight` (`set_view(art_origin, art_scale)`, chamada em `_sync_view_layers`), o mapa (`set_map(map: ExplorationMap)`) e os hexágonos novos (`reveal(coords: Array[Vector2i])`).
- **RF-04:** A máscara é uma imagem com um pixel por hexágono (`FORMAT_RG8`, do menor ao maior `q` e `r` do mapa): o vermelho diz se o hexágono foi descoberto, e o verde é a altura + 1 (0 sem hexágono). Descobrir só troca os pixels dos hexágonos novos. O shader descobre de quem é o hexágono visível em cada pixel da arte pela mesma regra do `HexMapView.coord_at`: das alturas mais altas para as mais baixas, o hexágono da grade no ponto erguido por aquela altura, se ele tiver essa altura; sem nenhum, o ponto está num paredão, e o dono é o hexágono da grade plana no ponto (ou, na borda do mapa, onde o paredão desce além do hexágono, o de `SIDE_HEIGHT` acima). Assim, o topo e as laterais de um hexágono alto contam como dele, e uma montanha escondida mais para baixo na tela, que sobe por cima de hexágonos descobertos, fica na névoa por inteiro (o que ela cobre já não aparecia sem a névoa). A imagem de uma ilha de raio 80 tem uns 26 mil pixels. Mudou do desenho por formas da spec aprovada: a mesma regra do toque, no shader, dispensa pintar polígonos na ordem do desenho e custa uma imagem minúscula.
- **RF-05:** O shader pinta por cima do mapa o mesmo degradê do fundo da tela (`UiPalette.BACKGROUND` em cima e `BACKGROUND_DEEP` embaixo, pela altura na tela), com a transparência vinda da borda. O vermelho da imagem diz quanto cada hexágono aparece: 1 no descoberto, `GLIMPSE` (0,5) no anel de `GLIMPSE_RADIUS` (1) hexágono em volta do descoberto e 0 no resto. Para cada pixel da arte, o shader acha o chão plano do hexágono visível (o ponto erguido pela altura do dono, como no RF-04) e mistura esse valor dos 3 centros de hexágono em volta, no triângulo dos vizinhos da grade axial. A névoa é `1 − mistura / 0,9`, cortada em 6 degraus (`BANDS`), com cara de pixel art. Assim, ela clareia aos poucos ao longo de uns dois hexágonos, o anel em volta aparece pela metade, e um paredão alto segue o hexágono dele. O ponto que o shader pergunta é deslocado até 6 px da arte por um ruído suave preso ao espaço da arte (células de 7 px, que não correm quando a câmera anda), arredondado para pixels inteiros, o que deixa a borda irregular. Os valores são _a revisar_. Pedidos do dono em 2026-11-15: a borda em degraus ("Em degraus", entre o liso e o pontilhado, porque o corte seco da primeira versão ficou "muito abrupto"), e depois "mais espaçoso as faixas de transparencia", "mais um campo na frente com uma trasparencia maior" e os campos aparecendo "aos poucos junto com o movimento".
- **RF-05b:** Ao descobrir, cada hexágono novo e o anel em volta dele não aparecem de uma vez: o valor sobe até o novo em `FADE_TIME` (0,8 s, _a revisar_), enquanto o Domador anda. Ao entrar no mapa, o que já foi descoberto aparece direto.
- **RF-06:** A névoa segue o chão: o que passa para cima da forma de um hexágono descoberto (a copa de uma árvore, um telhado) fica coberto quando cai sobre um escondido, e a copa de uma árvore de um hexágono escondido mais para baixo na tela aparece quando sobe por cima de um descoberto. _A revisar_ quando o dono vir.
- **RF-07:** As luzes das peças e os enxames de vagalumes que a tela entrega ao `DayLight` (`_refresh_lights`) são só os de hexágonos descobertos. O hexágono de uma luz é o do pé da peça; o de um enxame, o do hexágono em que ele foi sorteado. Ao descobrir, as luzes são escolhidas de novo.
- **RF-08:** O nome de uma construção (`BuildingNamesLayer`) só aparece quando o hexágono do meio dela (`BuildingNamesLayer.middle_of`) está descoberto.
- **RF-09:** Tocar na névoa leva o Domador até o ponto, pelo caminho do mapa de verdade. Um NPC, uma peça com ação ou uma construção num hexágono escondido não respondem ao toque (`_npc_hit` e `_prop_hit` olham `MapDiscovery.is_discovered`): o toque vale como um toque no chão. Assim, o toque às cegas não abre a conversa, a Loja ou o Refúgio de algo que não aparece.
- **RF-10:** Com o "Debug: ver mapa inteiro" ligado, a névoa some e as luzes, os vagalumes e os nomes voltam todos. Ao desligar, voltam a névoa e os filtros.
- **RF-11:** O tabuleiro da luta, o editor (F2) e o Desafiar não ganham névoa.

## Critérios de aceite

- [x] Ao entrar no mapa sorteado ou numa ilha, no zoom 1, só aparecem os hexágonos a até 4 do Domador; o resto tem a cor do fundo.
- [x] Ao andar, os hexágonos novos aparecem, e os de trás continuam acesos, com os Ecobeasts que estiverem neles.
- [x] A borda da névoa é irregular, em pixels inteiros da arte, e não muda de forma quando a câmera anda.
- [ ] Um hexágono de Montanha descoberto aparece inteiro, com o topo e as laterais, sem corte.
- [ ] À noite, nenhum poste, janela ou vagalume brilha dentro da névoa, e a névoa escurece junto com o resto.
- [ ] O nome de uma construção só aparece depois que o meio dela foi descoberto.
- [ ] Tocar na névoa leva o Domador até lá.
- [x] "Debug: ver mapa inteiro" mostra a ilha toda, e desligá-lo volta à névoa.
- [ ] Ao voltar de uma luta, a névoa do mapa sorteado continua igual.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Criar:**
  - `client/domain/models/map_discovery.gd`
  - `client/ui/components/fog_layer.gd`
  - `client/ui/components/fog.gdshader`
- **Alterar:**
  - `client/screens/exploration/exploration_screen.tscn` (o nó `Fog` entre `MapView` e `DayLight`)
  - `client/screens/exploration/exploration_screen.gd` (a descoberta em `_begin` e onde `_player_coord` muda, o filtro em `_refresh_lights`, os nomes em `_show_island`, a vista em `_sync_view_layers` e o `_toggle_whole_map`)
  - `client/ui/components/hex_map_view.gd` (`firefly_swarm_tiles` e o hexágono de cada luz em `prop_lights`)
  - `client/ui/components/map_light.gd` (`coord`)
- **Reutilizar:** o `set_view` e o `art_pixel` do `DayLightLayer` e do `day_light.gdshader` e a regra de `HexMapView.coord_at` e `grid_coord`.

## Verificação

- F5 no Godot: o mapa sorteado e uma ilha com montanha e construções, nos zooms 1 a 4, de dia e às 22h pela barra de hora do menu Debug; andar, tocar na névoa, entrar numa luta e voltar, e ligar e desligar o "ver mapa inteiro".
- No celular Android: a fluidez ao andar numa ilha grande, no zoom 1.

## Tarefas

- [x] `MapDiscovery`.
- [x] `FogLayer`, a máscara e o shader.
- [x] A descoberta, as luzes, os nomes e o debug na tela `exploration`.
- [x] Atualizar `client/CLAUDE.md`, o README e as tabelas das specs.

Conferido por Claude, em capturas da janela do jogo (numa janela pequena, com 1 pixel da tela por pixel da arte): uma ilha e o mapa sorteado à noite, ao entrar e depois de andar 5 hexágonos, e o "ver mapa inteiro". Fica para o dono: os zooms 2 a 4 no celular, a montanha descoberta inteira, as luzes e os nomes na beira da névoa, o toque na névoa e num NPC escondido, a volta de uma luta, o gosto da borda e do raio, e a fluidez no celular.

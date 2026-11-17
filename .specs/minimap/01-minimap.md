# 01. O minimapa

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [fog-of-war/02](../fog-of-war/02-fog-layer.md) e [fog-of-war/03](../fog-of-war/03-island-memory.md)

## Contexto

Explorar não tem como ver, sem afastar o zoom, onde o Domador está e o que já foi descoberto em volta. Esta fase põe o minimapa redondo no canto de cima à direita ([README](README.md#decisões)), com a imagem, as cores, os marcadores e a arte do [architecture.md](architecture.md). Tocar nele ainda não abre nada: o mapa grande é a [02](02-island-map.md).

## Escopo

- `MinimapImage`, `MinimapPalette`, `MapMarker` e `MinimapArt`.
- O `make_minimap_art.py` e os PNGs.
- O componente `Minimap` e a tela de Explorar: o minimapa no canto, a `TopRow` à esquerda, a descoberta e o "ver mapa inteiro".

## Fora do escopo

- O mapa grande (fase 02). O minimapa já emite o toque, mas ninguém o escuta nesta fase.
- Os ícones de missão.

## Requisitos

- **RF-01:** `MinimapImage` monta a imagem do mapa descoberto pela regra do [architecture.md](architecture.md#a-imagem-do-mapa-minimapimage): o bioma, o chão, os traços de caminho, as pontes, a sombra da costa, a névoa e o anel pela metade.
- **RF-02:** O componente `Minimap` (`res://ui/components/minimap.gd`, `class_name Minimap`, um `Control`) tem `MinimapArt.ART_SCALE × 64` (192) pontos de lado e desenha, de baixo para cima:
  - o pedaço da imagem em volta do Domador, recortado num círculo de 48 px da arte (144 pontos), com a imagem na mesma escala de 3 pontos por pixel;
  - os ícones dos marcadores descobertos que caem dentro do círculo inteiro (um ícone na beira pode ser cortado pelo anel);
  - o pino do Domador, no centro, com a ponta no ponto do Domador;
  - o anel (`ring.png`).
- **RF-03:** O Domador fica sempre no centro: o pedaço da imagem é o do ponto dos pés dele no chão plano (`_player_point`), arredondado para o pixel da imagem, e segue o andar a cada quadro. A beira escura do mapa aparece como névoa quando o Domador está perto dela.
- **RF-04:** O `Minimap` tem `set_source(image: MinimapImage, markers: Array[MapMarker], discovery: MapDiscovery)`, `set_center(flat: Vector2)`, `set_show_all(on: bool)` e o sinal `tapped`, emitido num toque dentro do círculo (até `MAX_TAP_TRAVEL` de movimento, como no mapa). O toque no minimapa não chega ao mapa por baixo e não anda o Domador.
- **RF-05:** Na cena `exploration_screen.tscn`, o `Minimap` fica dentro do `SafeArea`, num `Control` que o cobre (`TopCorner`, antes da `Column`, para o menu Debug ficar por cima), ancorado no canto de cima à direita, fora da `Column` (não empurra o resto). Ele só aparece depois de o mapa carregar.
- **RF-06:** A `TopRow` passa a alinhar à esquerda e termina num espaço vazio (`MinimapSpace`, 204 pontos: o minimapa e 12 de folga). O nome da ilha que não couber corta com reticências (`text_overrun_behavior`), com a largura calculada pela tela (`_fit_island_name`).
- **RF-07:** Ao entrar no mapa, a tela monta a `MinimapImage` (depois da descoberta inicial) e os marcadores. A cada `_discover` com hexágonos novos, chama `MinimapImage.reveal`.
- **RF-08:** O "Debug: ver mapa inteiro" monta a imagem de novo com `show_all` ligado, e o minimapa mostra os ícones de todos os marcadores; ao desligar, volta à névoa. O "Esquecer ilha" monta a imagem de novo.
- **RF-09:** No mapa sorteado, o minimapa aparece igual, sem marcadores (não há ações nem NPCs).
- **RF-10:** Andar com o minimapa não pode custar mais de 2 ms por quadro numa ilha de raio 80, medido sem janela: o recorte é desenhado pela textura (`draw_texture_rect_region` com o círculo por um shader de máscara ou um `clip_children`), nunca pintando pixels a cada quadro.

## Critérios de aceite

- [ ] Ao entrar numa ilha ou no mapa sorteado, o minimapa aparece no canto de cima à direita, redondo e dourado, com o pino no centro e só o descoberto colorido. (Visto por Claude numa ilha de teste; falta numa ilha de verdade.)
- [ ] Ao andar, o terreno rola por baixo do pino, e os hexágonos descobertos aparecem no minimapa no mesmo passo da névoa.
- [x] Os biomas, as trilhas, os pisos e as pontes têm as cores da tabela, e a beira da terra com a água tem a sombra.
- [x] O Refúgio, a Loja e um NPC descobertos perto do Domador aparecem com o ícone; escondidos, não aparecem.
- [ ] Os pixels do minimapa têm todos o mesmo tamanho, sem borrar, nos zooms 1 a 4 do mapa.
- [ ] O nome da ilha e o selo da parte do dia ficam à esquerda e não encostam no minimapa.
- [ ] Tocar no minimapa não anda o Domador.
- [ ] "Debug: ver mapa inteiro" mostra o minimapa sem névoa; desligar volta.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Criar:**
  - `client/ui/components/minimap_image.gd`
  - `client/ui/components/minimap_palette.gd`
  - `client/ui/components/map_marker.gd`
  - `client/ui/components/minimap_art.gd`
  - `client/ui/components/minimap.gd`
  - `client/assets/ui/minimap/make_minimap_art.py` e os PNGs (`ring.png`, `frame.png`, `pin.png`, `refuge.png`, `shop.png`, `npc.png`)
- **Alterar:**
  - `client/screens/exploration/exploration_screen.tscn`: o nó `Minimap` e o `alignment` da `TopRow`.
  - `client/screens/exploration/exploration_screen.gd`: a imagem e os marcadores em `_begin`, o `reveal` em `_discover`, o centro a cada passo (onde `_move_map` é chamado), o `_toggle_whole_map` e o `_forget_island`.
- **Reutilizar:** `HexMapView.grid_coord`, `flat_center` e `_tile_origin` (ou uma função pública nova com o mesmo cálculo, se `_tile_origin` for privada), `HexGrounds.kind_of` e `trail_distance`, `BuildingNamesLayer.middle_of`, `MapDiscovery.is_discovered` e `HexTile.WATER_BIOMES`.

## Verificação

- **Teste sem janela** numa cena temporária (`client/zz_tmp_check`, apagada depois), que falha antes e passa depois:
  - num mapa pequeno feito no teste, a cor do pixel de um hexágono descoberto de Planície é a da tabela, a de um escondido é a `FOG`, e a de um vizinho escondido é a mistura pela metade;
  - um hexágono com trilha e uma ponte saem nas cores delas, e a terra acima da água sai com a sombra;
  - `reveal` muda só os pixels dos hexágonos novos e do anel;
  - um marcador num hexágono escondido não é desenhado, e no descoberto é;
  - o tempo de montar uma ilha de raio 80 e o de um quadro de andar com o minimapa.
- **Prints** numa janela de 720×1280: uma ilha ao entrar e depois de andar, e o mapa sorteado.
- **Fica para o dono:** o tamanho e as cores no celular.

## Tarefas

- [x] Spec aprovada pelo dono.
- [x] `MinimapPalette`, `MinimapImage` e `MapMarker`, com o teste.
- [x] O `make_minimap_art.py`, os PNGs e o `MinimapArt`.
- [x] O `Minimap` e a tela de Explorar.
- [x] Prints, `client/CLAUDE.md` e as tabelas das specs.

## Resultado da verificação

Em 2026-11-16:

- **Teste sem janela** (uma cena temporária, já apagada): falhou antes (sem as classes) e passou depois. Conferiu:
  - as cores do descoberto, do escondido e do anel pela metade;
  - a trilha, a ponte, a água e a sombra da costa;
  - o molde: os mesmos pixels que perguntar o dono de cada um, nos 1.110 pixels do mapa do teste;
  - o `reveal`, que só muda o hexágono novo e o anel;
  - o "ver mapa inteiro" e a beira do mapa na cor da névoa;
  - os marcadores escondidos, que não aparecem, e os ícones, que carregam.
- **Tempo:** a primeira versão, que perguntava o dono pixel a pixel, montava uma ilha de raio 80 em 441 ms. Com o molde do [architecture.md](architecture.md#a-imagem-do-mapa-minimapimage), monta em 70 ms, e um passo repinta em menos de 1 ms.
- **Print** (na conversa): numa ilha de teste montada por ruído, numa janela de 720 pontos de largura, o minimapa no canto, com a trilha, o NPC, o pino e a névoa na beira.
- **Projeto:** a tela de Explorar e a cena compilam, e o jogo sem janela abre sem aviso novo (o único é o de antes, do `sign` no `hex_bridges.gd`).
- **Falta o dono:** uma ilha de verdade e o mapa sorteado com a sessão do jogo (a tela precisa do login), o tamanho e as cores no celular, o toque e um nome comprido de ilha.

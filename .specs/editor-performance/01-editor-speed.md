# 01. O editor sem travar

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [map-editor](../map-editor/), [vegetation-brush](../vegetation-brush/) (o `refresh_props_at`), [prop-depth-blocks](../prop-depth-blocks/) (os bloqueios no editor), [bridges](../bridges/) e [water-motion](../water-motion/) (a água no shader)

## Contexto

O editor trava ao decorar e apagar numa ilha cheia, e piora com o tempo ([README](README.md#contexto)).

## Escopo

- `HexMapView`: o índice das pontes, o `map_time` e o `animated`.
- `plant_wind.gdshader` e `hex_grounds.gdshader`: o `map_time` no lugar do `TIME`.
- `EditorCanvas`: as peças e os bloqueios refeitos por hexágono, e a camada dos bloqueios.
- `EditorTools`: a Borracha numa passada e a cópia das peças para o desfazer.
- `MapEditor`: o botão Animações e as ferramentas chamando o `refresh_props_at`.
- `ViewSettings`: a chave `editor_motion`.

## Requisitos

- **RF-01:** O `HexMapView.update_tiles` apaga o índice das pontes antes de refazê-lo. A lista de pedaços tem sempre o tamanho das pontes da ilha.
- **RF-02:** Cada passo da Borracha, do Remover e da ferramenta Peças (pôr, arrastar, editar o bloqueio) e do Bloqueios refaz as peças só dos hexágonos que ele devolve (`refresh_props_at`). O `refresh_props` (desfazer, painéis, Carimbo) acha esses hexágonos pela chave de cada peça do rascunho, sem converter as outras.
- **RF-03:** O `EditorCanvas` guarda, por hexágono com peças que bloqueiam, as linhas delas e os hexágonos que elas bloqueiam, e conta quantos hexágonos de peça bloqueiam cada um. O `refresh_props_at` refaz os bloqueios só dos hexágonos dele, o pincel Vegetação incluído. As paredes ficam numa conta à parte, refeita quando elas mudam. A conta inteira só roda ao abrir a ilha.
- **RF-04:** Os X dos hexágonos bloqueados, as linhas tracejadas e os pontos da ferramenta Bloqueios ficam numa camada própria. Ela só desenha o que cai na tela, e só é redesenhada quando os bloqueios, o zoom, o arrasto, o terreno ou a camada Bloqueios mudam. Os pontos do bloqueio em edição seguem na camada de cima, com o pincel.
- **RF-05:** Num passo da Borracha (botão esquerdo), as peças dos hexágonos do pincel saem numa passada só pela lista.
- **RF-06:** A pincelada só copia as peças para o desfazer nas ferramentas que mexem nelas: Peças, Bloqueios, Carimbo, Vegetação, Borracha e Remover.
- **RF-07:** Cada `HexMapView` passa o `map_time` (os segundos desde que o jogo abriu, voltando a 0 a cada 3.600 s) aos materiais do chão e das decorações a cada quadro, enquanto `HexMapView.animated` (de todos os mapas) estiver ligado. Os shaders usam o `map_time` em vez do `TIME`. Explorar e a luta seguem como antes.
- **RF-08:** O botão Animações, nas Camadas do F2, começa ligado e fica guardado em `user://view.json` (`editor_motion`). Desligado, com o editor aberto, todo mapa para o vento, a água, as cachoeiras, a espuma e a fumaça onde estão, o da janela do jogo incluído. O Godot também fica no modo de pouco processamento (`OS.low_processor_usage_mode`) e só redesenha quando algo muda. Ao fechar o editor ou usar o Testar daqui, as animações e o modo voltam ao de antes. A janela do jogo atrás ainda pode pedir redesenho pelo que anima fora do mapa (o Domador, o filtro da noite), e aí o ganho é menor.

## Critérios de aceite

- [x] Na mesma ilha de teste, 25 pinceladas levam o mesmo tempo na primeira e na quarta rodada (200 ms nas duas; antes, de 271 para 1.112 ms).
- [x] Um passo da Borracha, do Remover ou do arrasto de uma peça leva menos de 50 ms (a Borracha de raio 2: 31 ms; antes, mais de 1 s). O desfazer leva 41 ms.
- [x] Desenhar o pincel a cada quadro custa o mesmo com a camada Bloqueios ligada ou desligada.
- [ ] No F2, apagar, pôr, arrastar e desfazer peças mostra as mesmas peças e os mesmos X de bloqueio de antes.
- [ ] Com Animações desligado, a água, o vento e a fumaça param no F2; religado, voltam. Em Explorar, eles seguem andando.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script.

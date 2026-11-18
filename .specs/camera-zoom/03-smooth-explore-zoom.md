# 03. O zoom suave ao explorar

- **Status:** concluída (falta o dono conferir no celular)
- **Depende de:** [01](01-explore-zoom.md), [story/07](../story/07-camera-zoom.md)

## Contexto

Em 2026-11-17, o dono pediu: "eu queria que ele pudesse ser suave no mobile, onde ele tem uma liberdade de usar o zoom, mas vai ter o limite maximo e minimo", no mapa de Explorar, "que aparece meu personagem".

Hoje, a pinça da [01](01-explore-zoom.md) troca o `HexMapView.zoom_level` em degraus inteiros, de 1 a 4: o nível novo é `round(nível do começo × razão dos dedos)`. O mapa só muda quando a conta passa de meio degrau, e aí pula de uma vez, por exemplo de 2 para 3 (50% maior). A roda do mouse pula um degrau por clique. Por isso parece abrupto.

A [story/07](../story/07-camera-zoom.md) já deixou o `HexMapView` mostrar um zoom fracionário: o `story_zoom`, que a câmera das cenas usa só durante o tween e que termina num degrau inteiro. O `art_scale()` mistura a escala dos dois degraus em volta.

## Escopo

- A pinça segue os dedos de forma contínua, entre o mínimo e o máximo de hoje.
- Ao soltar os dedos, o zoom desliza até o degrau inteiro mais perto.
- A roda do mouse desliza até o degrau seguinte, em vez de pular.

## Fora do escopo

- Mudar o mínimo e o máximo (1 e 4) ou o zoom das cenas.
- O zoom da luta, que já é contínuo ([02](02-battle-zoom.md)).
- O mapa grande do minimapa.

## Requisitos

- **RF-01:** Durante a pinça, o zoom mostrado é `nível do começo × razão dos dedos`, sem arredondar, preso entre `HexMapView.MIN_ZOOM` (1) e `MAX_ZOOM` (4), pelo `story_zoom` do `HexMapView`. A câmera continua presa no Domador, como hoje.
- **RF-02:** Quando os dedos saem (o fim da pinça), o zoom desliza em `ZOOM_SETTLE_SECONDS` (0,15 s, a revisar no celular) até o degrau inteiro mais perto do zoom de agora. No fim, o `zoom_level` é esse degrau, o `story_zoom` volta a 0, e o nível vai para o `ViewSettings`, como hoje. Em repouso, a arte fica sempre num degrau inteiro, com todo pixel do mesmo tamanho ([README](README.md#decisões)).
- **RF-03:** Cada clique da roda do mouse leva o alvo um degrau para cima ou para baixo, preso entre 1 e 4, e o zoom desliza até ele em `ZOOM_SETTLE_SECONDS`. Um clique no meio do deslize parte do zoom de agora para o alvo novo, sem salto.
- **RF-04:** Uma pinça que começa no meio do deslize para o deslize e parte do zoom de agora.
- **RF-05:** O raio dos Ecobeasts e dos Domadores NPC perto do Domador (`_creature_radius`) é refeito a cada degrau novo e no fim do deslize, não a cada quadro.
- **RF-06:** Uma cena que começa no meio do deslize termina o deslize na hora, no degrau alvo (o zoom do jogador já não muda durante uma cena). Mudou na implementação: esperar o deslize de 0,15 s complicaria o começo da cena por um caso raro.

## Critérios de aceite

- [ ] No celular, a pinça aproxima e afasta acompanhando os dedos, sem pulos.
- [ ] Ao soltar, o mapa assenta num degrau inteiro em pouco tempo, sem salto.
- [x] A pinça não passa de 1 nem de 4.
- [x] A roda do mouse aproxima e afasta deslizando, um degrau por clique.
- [ ] Fechar e abrir o jogo volta no último degrau.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Alterar:**
  - `client/ui/components/pinch_zoom.gd`: `signal pinch_ended`, emitido quando a pinça acaba.
  - `client/screens/exploration/exploration_screen.gd`: a pinça põe o `story_zoom` fracionário; `_settle_zoom(target)` desliza num tween próprio (`_zoom_tween`), separado do `_camera_tween` das cenas, e termina como o `_camera_arrived` termina hoje (o degrau, o `ViewSettings`, o `_refresh_wild_sprites` e o `_fit_view`).
- **Reutilizar:** o `HexMapView.story_zoom` e o `art_scale()` da [story/07](../story/07-camera-zoom.md).

## Notas da implementação

- O `PinchZoom.pinch_ended` também sai no `cancel()` no meio de uma pinça, para o zoom não ficar fracionário quando a tela some.
- O degrau vai para o `ViewSettings` no começo do deslize, não no fim, para o `camera_back` das cenas achar o zoom certo mesmo com o deslize cortado.
- O deslize é `TRANS_SINE` com `EASE_OUT`.
- Conferido sem janela, com o jogo inteiro contra a API local e eventos de dois dedos: a pinça sobe de 2,04 a 2,80 em passos pequenos, assenta no 3 ao soltar, não passa de 4 nem de 1, e a roda desliza (1,14 no meio) e, com dois cliques seguidos, chega ao 3.

## Verificação

- `godot --headless --path client --quit-after 30`.
- Uma cena temporária, fora de `client/zz_tmp_check`, que manda eventos de dois dedos e da roda para a tela de Explorar e confere o zoom a cada quadro: contínuo durante a pinça, preso entre 1 e 4, e inteiro no fim do deslize.
- No celular: os critérios acima.

## Tarefas

- [x] O `pinch_ended` e a pinça contínua.
- [x] O deslize ao soltar e na roda.
- [x] O `client/CLAUDE.md`, o README e as tabelas das specs.

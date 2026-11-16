# 01. Os vagalumes

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [day-night/03](../day-night/03-night-lights.md)

## Contexto

O dono quer vagalumes que só aparecem à noite, desenhados pelo shader da noite ([README](README.md#decisões)).

## Escopo

- O sorteio dos enxames por hexágono, em `HexDecorations`.
- A lista de enxames do mapa no `HexMapView` e a escolha dos que vão ao filtro na tela `exploration`.
- Os pontinhos e a luz de cada enxame no `day_light.gdshader`.

## Requisitos

- **RF-01:** `HexDecorations.swarm_of(tile: HexTile, map_seed: int) -> Variant` devolve o ponto do enxame (`Vector2i`, a partir do centro do hexágono, pela regra de `random_spot` e `is_free_spot`) ou `null`. O gerador é próprio (`hash([map_seed, tile.coord, "fireflies"])`), e a chance é a de `SWARM_CHANCE` por bioma, _a revisar_: `temperate` 0,12 e `boreal` 0,18. Sem chance para o bioma, ou com `tile.bare`, não há enxame.
- **RF-02:** `HexMapView.firefly_swarms() -> PackedVector2Array` devolve os centros de todos os enxames do mapa, em pixels da arte: o centro do hexágono erguido pela altura dele, mais o ponto do enxame, mais `SWARM_LIFT` (8 px acima do chão).
- **RF-03:** A tela `exploration` guarda a lista ao carregar o mapa e, a cada mudança de vista, entrega ao `DayLightLayer.set_swarms(points: PackedVector2Array)` os enxames que tocam a área visível, dos mais perto do Domador para os mais longe, até `MAX_SWARMS = 32`.
- **RF-04:** O shader, para cada enxame a até `SWARM_REACH` (o raio da luz do enxame) do pixel da arte:
  - soma uma luz fraca de raio 16 e cor `d8ff8a`, em degraus, como as outras luzes;
  - desenha 6 pontinhos de 1 pixel da arte, cada um num ponto próprio a até 8 px do centro, vagando até 4 px por senos lentos e piscando por um seno com fase própria;
  - pinta o pixel do pontinho com a cor `f4ff9c`, por cima do escuro, na força do pisca vezes a força das luzes.
  Os valores são _a revisar_.
- **RF-05:** Os vagalumes seguem a força das luzes da [day-night/02](../day-night/02-day-light.md): nenhum das 7h às 17h, aparecendo até as 19h e sumindo das 5h às 7h. Com a força 0, o shader não passa pelos enxames.

## Critérios de aceite

- [ ] No mapa sorteado e numa ilha, às 22h, há enxames nos campos de Planície e de Boreal, com pontinhos que vagam, piscam e iluminam o chão em volta.
- [ ] Às 12h não há nenhum pontinho, e o mapa fica igual ao de antes.
- [ ] As decorações de um mapa ficam no mesmo lugar de antes.
- [ ] Os pontinhos ficam no pixel da arte em qualquer zoom.
- [ ] Um hexágono apagado pela Borracha não tem enxame.
- [ ] `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Alterar:**
  - `client/ui/components/hex_decorations.gd` (`SWARM_CHANCE`, `swarm_of`)
  - `client/ui/components/hex_map_view.gd` (`firefly_swarms`)
  - `client/ui/components/day_light_layer.gd` (`MAX_SWARMS`, `set_swarms`)
  - `client/ui/components/day_light.gdshader` (os enxames)
  - `client/screens/exploration/exploration_screen.gd` (a escolha junto com a das luzes, em `_refresh_lights`)
- **Reutilizar:** `random_spot` e `is_free_spot` de `HexDecorations`, `_rise` do `HexMapView` e o pixel da arte que o shader já calcula.

## Verificação

- F5 no Godot: no mapa sorteado e numa ilha, escolher 22h e 12h na barra de hora do menu Debug, dar zoom e andar.
- No celular Android: conferir a fluidez com muitos enxames na tela.

## Tarefas

- [x] Sorteio dos enxames.
- [x] Lista no `HexMapView` e escolha na exploração.
- [x] Pontinhos e luz no shader.
- [x] Atualizar `CLAUDE.md`, `client/CLAUDE.md`, o README e as tabelas das specs.

Conferido por Claude, em capturas da janela do jogo: uma ilha e o mapa sorteado (numa floresta Boreal) às 12h, sem nenhum pontinho, e às 22h, com os enxames brilhando, nos zooms 2 e 4, e os pontinhos em outro lugar 0,7 s depois. Fica para o dono: o gosto (quantidade, cor e tamanho), a Borracha numa ilha e a fluidez no celular.

# 02. A luz da hora e o indicador

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [01](01-world-clock.md), [camera-zoom](../camera-zoom/)

## Contexto

Com o relógio pronto ([01](01-world-clock.md)), o mapa de exploração e o tabuleiro da luta passam a mudar de cor com a hora, pelo filtro escolhido pelo dono, e a UI mostra a parte do dia ([README](README.md#decisões)). Os pontos de luz ficam para a [03](03-night-lights.md); nesta fase, a força das luzes já existe no shader, mas a lista de luzes chega vazia.

## Escopo

- O componente `DayLightLayer` e o shader `day_light.gdshader`, do [architecture.md](architecture.md#o-filtro-da-luz).
- O filtro na tela `exploration` (mapa sorteado e ilhas) e na tela `board_battle`.
- O componente `DayPhaseBadge`, os 4 ícones provisórios e o indicador no Hub e na exploração.

## Fora do escopo

- Os pontos de luz ([03](03-night-lights.md)).
- O filtro no editor de ilhas (F2), no Hub e nos menus.
- O indicador na luta.

## Requisitos

- **RF-01:** `DayLightLayer` é um `ColorRect` com `mouse_filter = IGNORE` e o material `day_light.gdshader`, que faz a conta do [architecture.md](architecture.md#o-filtro-da-luz): saturação, ambiente, luzes em 4 degraus no pixel da arte e o brilho somado.
- **RF-02:** A cada quadro, o `DayLightLayer` lê `WorldClock.hour()` e mistura em linha reta os dois pontos de `KEYFRAMES` em volta da hora, para o ambiente, a saturação e a força das luzes, com os valores iniciais do [architecture.md](architecture.md#a-cor-da-hora). Uma volta inteira de 24 horas não tem nenhum salto de cor.
- **RF-03:** Com o ambiente (1, 1, 1), a saturação 1 e a força das luzes 0, ou com o `WorldClock` sem sincronizar, o `DayLightLayer` fica `visible = false`.
- **RF-04:** O `DayLightLayer` tem `set_view(art_origin: Vector2, art_scale: float)` (na exploração, `art_scale` é o `pixel_scale().x` do `HexMapView`), chamado pela tela sempre que o mapa anda ou muda de zoom, e `set_lights(lights: Array[MapLight])`, com no máximo `MAX_LIGHTS = 32` itens. Sem `set_lights`, a lista fica vazia.
- **RF-05:** Na tela `exploration`, o `DayLightLayer` fica em `MapArea`, entre o `MapView` e o `BuildingNames`, e acompanha a vista pelo mesmo ponto em que hoje a tela chama `_building_names.set_view(...)`.
- **RF-06:** Na tela `board_battle`, o `DayLightLayer` cobre o tabuleiro, sem luzes. Ele escurece os hexágonos, as marcas no chão e os Ecobeasts, mas não a barra de HP, os chips de estágio, os números de dano e as placas, que o `BoardView` desenha dentro do `Board` (`board_view.gd`). Esses elementos ficam num `hud` por Ecobeast, depois do filtro, como no [architecture.md](architecture.md#o-filtro-da-luz), e o filtro passa 4096 px de cada borda do `Board`, porque o chão vai até a borda da tela.
- **RF-07:** O `DayPhaseBadge` mostra o ícone 16×16 (desenhado no tamanho inteiro mais próximo do texto, sem filtro) e o nome da parte do dia (`DayPhase.name`). Ele troca quando o `WorldClock` emite `phase_changed` e fica escondido enquanto o relógio não sincronizou.
- **RF-08:** O Hub mostra o `DayPhaseBadge` na `TopBar`, à esquerda do `CoinChip`. A exploração mostra o `DayPhaseBadge` no alto da tela, na mesma linha da placa com o nome da ilha, e sozinho no mapa sorteado, que não tem placa.
- **RF-09:** `client/assets/ui/day_phases/make_day_phase_icons.py` desenha `morning.png` (sol nascendo), `afternoon.png` (sol alto), `dusk.png` (sol se pondo) e `night.png` (lua), em 16×16, com a paleta do tema. O ícone de cada parte é escolhido pelo `slug`. A arte é provisória, _a revisar_.

## Critérios de aceite

- [ ] Com "Debug: +1 hora", o mapa passa pelo nascer do sol, pelo dia sem filtro, pelo dourado do final de tarde, pelo crepúsculo e pela noite azulada.
- [ ] À noite, os caminhos, a água e os Ecobeasts do mapa continuam fáceis de ver no celular.
- [ ] Os botões, os painéis, o log e os nomes dos prédios não mudam de cor com a hora, nem a barra de HP, os chips e os números de dano do tabuleiro.
- [ ] Ao entrar numa luta à noite, o tabuleiro também está escuro, e ao voltar o mapa continua na mesma cor.
- [ ] O filtro acompanha o mapa em todos os zooms da pinça e da roda do mouse, sem faixa clara na borda.
- [ ] O indicador mostra a parte certa no Hub e na exploração e troca sozinho quando a parte do dia muda.
- [ ] De dia, o `DayLightLayer` fica escondido (conferir no Remote do editor do Godot).
- [ ] `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Criar:**
  - `client/ui/components/day_light_layer.gd`
  - `client/ui/components/day_light.gdshader`
  - `client/ui/components/day_phase_badge.gd` e `.tscn`
  - `client/assets/ui/day_phases/make_day_phase_icons.py` e os 4 PNG
- **Alterar:**
  - `client/screens/exploration/exploration_screen.tscn` e `.gd`
  - `client/screens/board_battle/board_battle_screen.tscn` e `.gd`, e `board_view.gd` (a ordem da UI do tabuleiro)
  - `client/screens/hub/hub_screen.tscn` e `.gd`
- **Reutilizar:**
  - `HexMapView.pixel_scale()` e `MapView.position` para o `art_scale` e o `art_origin`.
  - O `_board.position` e o `_board.scale` da luta.
- **Atenção:** com `window/stretch/mode = "canvas_items"`, o `FRAGCOORD` está em pixels da janela, não do canvas. O shader deve achar o ponto do fragmento por `UV × tamanho do retângulo`, e não por `FRAGCOORD`.

## Verificação

- F5 no Godot: no mapa sorteado e numa ilha, dar a volta no dia com "Debug: +1 hora", dar zoom e andar. Entrar numa luta à noite.
- No celular Android: conferir se a noite está legível e se a exploração anda lisa com o filtro ligado.

## Tarefas

- [x] Shader e `DayLightLayer`, com as cores da hora.
- [x] O filtro na exploração e na luta.
- [x] Os ícones e o `DayPhaseBadge`.
- [x] O indicador no Hub e na exploração.
- [ ] Ajustar as cores no aparelho e marcar os valores finais no [architecture.md](architecture.md#a-cor-da-hora). Fica para o dono: os valores continuam _a revisar_.
- [x] Atualizar `CLAUDE.md`, `client/CLAUDE.md`, o README da iniciativa e as tabelas das specs.

Conferido por Claude, em capturas da janela do jogo: o mapa sorteado e uma ilha às 12h, 17h30, 18h, 19h, 22h e 6h30, e a luta de teste às 12h e às 22h. A UI, os nomes, as barras de HP e o indicador não mudam de cor, e a noite fica legível. Fica para o dono: o celular (legibilidade e fluidez) e o gosto das cores.

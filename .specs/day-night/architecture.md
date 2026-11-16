# Arquitetura do dia e da noite

O desenho que as fases da [day-night](README.md) compartilham.

## O relógio do mundo

Um dia do jogo tem 1440 minutos, e 1 segundo real é 1 minuto do jogo, então o dia inteiro dura 24 minutos reais. Todos os jogadores veem a mesma hora.

```
EPOCH_MS  = 2026-01-01T00:00:00Z em milissegundos   (0h do jogo)
CYCLE_MS  = 1 440 000                                (24 minutos reais)
minuto_do_dia(agora_ms) = ((agora_ms − EPOCH_MS) mod CYCLE_MS) / 1000   → 0 ≤ m < 1440
hora = minuto_do_dia / 60
```

- **Servidor:** a conta mora no domínio, em `server/src/domain/world-clock/world-clock.ts` (`minuteOfDay(nowMs)` e `dayPhaseAt(minute, phases)`), sem banco e sem estado. A rota `GET /v1/world-clock`, sem login, devolve `{ "minute_of_day": 754.317 }`. A regra futura dos nascimentos chama as mesmas funções.
- **Jogo:** o autoload `WorldClock` (`res://core/autoload/world_clock.gd`) chama a rota e guarda o minuto recebido junto com o `Time.get_ticks_msec()` daquele momento, somando metade do tempo de ida e volta do pedido. Daí em diante, ele conta sozinho: `minuto = recebido + (ticks_agora − ticks_recebido) / 1000`, voltando a 0 em 1440. Ele **nunca** usa o relógio do celular (`Time.get_unix_time_from_system`), que o jogador pode mudar.
- O `WorldClock` sincroniza de novo ao entrar na exploração e quando o app volta do segundo plano (`NOTIFICATION_APPLICATION_RESUMED`). Até a primeira resposta, ele não sabe a hora (`is_synced() == false`). Nesse estado, o filtro fica de dia e o indicador fica escondido.
- O `WorldClock` emite `phase_changed(phase: DayPhase)` quando a parte do dia muda, conferindo a cada quadro.

> **Autoload** é um nó que o Godot cria uma vez, ao abrir o jogo, e que todas as telas acessam pelo nome (como o `Session` e o `Api`). O relógio é um autoload porque precisa continuar contando quando as telas trocam.

## As partes do dia

Tabela `day_phases` no schema `ecobeasts`, servida no `GET /v1/catalog` como as outras:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | id estável |
| `slug` | text, único | `^[a-z0-9_]+$` |
| `name` | text | o nome do indicador, em pt-BR |
| `start_minute` | int, único | 0 a 1439: o minuto do dia em que a parte começa |

A parte do dia num minuto `m` é a de maior `start_minute` ≤ `m`. Se nenhuma começa antes de `m`, vale a de maior `start_minute` (a noite atravessa a 0h).

Conteúdo inicial, _a revisar_:

| id | slug | name | start_minute | Horário |
| --- | --- | --- | --- | --- |
| 1 | `morning` | Manhã | 360 | 6h às 12h |
| 2 | `afternoon` | Tarde | 720 | 12h às 17h |
| 3 | `dusk` | Final de tarde | 1020 | 17h às 19h |
| 4 | `night` | Noite | 1140 | 19h às 6h |

## O filtro da luz

> **Shader** é um programa pequeno que roda na placa de vídeo para cada pixel da tela. Este lê a imagem que o mapa acabou de desenhar e devolve a mesma imagem com a cor da hora e as luzes.

O componente `DayLightLayer` (`res://ui/components/day_light_layer.gd`, `class_name DayLightLayer`) é um `ColorRect` que cobre a área do mapa, com `mouse_filter = IGNORE` e o material `res://ui/components/day_light.gdshader`. Ele fica **depois do mapa e antes de qualquer UI** na árvore:

- **Exploração:** em `MapArea`, entre o `MapView` e o `BuildingNames` (os nomes dos prédios não escurecem).
- **Luta:** dentro do `Board`, logo depois do chão, das marcas e das chamas, com os Ecobeasts postos antes dele (`move_child`). A barra de HP, os chips de estágio e os ícones de estado de cada Ecobeast moram num `hud` à parte, filho do `Board` depois do filtro, que segue o Ecobeast por um `RemoteTransform2D`; os números de dano, as placas, os efeitos e as moedas já nascem depois do filtro. Esses elementos são UI e não escurecem. O chão do tabuleiro passa do retângulo do `Board`, então o filtro passa 4096 px de cada borda (`DayLightLayer.margin`). Um `z_index` não serviria: ele ordena a camada inteira, e a UI da tela (z 0) cairia embaixo do filtro.

O shader lê a tela por baixo (`uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;`) e faz, em cada pixel:

```
c       = cor da tela
c       = mix(cinza(c), c, saturação da hora)
luz     = ambiente da hora                                 (rgb)
brilho  = 0
para cada luz i (até light_count):
    d     = distância, em pixels da arte, do pixel da arte deste fragmento até a luz i
    f     = degraus(1 − d / raio_i)                        (4 degraus, 0 fora do raio)
    luz  += cor_i × f × força_das_luzes
    brilho += cor_i × f × força_das_luzes × EMISSAO       (EMISSAO ≈ 0,15, a revisar)
COR     = c × min(luz, 1) + brilho
```

- **Pixel da arte:** o fragmento é levado ao pixel da arte com `art_origin` (a posição do `MapView` no retângulo) e `art_scale` (pixels de tela por pixel da arte, o `pixel_scale().x` do `HexMapView`, que devolve um `Vector2`), e arredondado para baixo. Assim, a luz anda em degraus do tamanho do pixel da arte em qualquer zoom. Na vista "mapa inteiro" do debug, a escala não é inteira, e os degraus podem sair tortos; isso fica aceito.
- **Multiplicar e não somar:** a luz devolve à arte a cor de dia (no máximo), sem estourar para branco. O `brilho` pequeno somado faz uma janela escura ficar amarelada de verdade.
- **De dia, o filtro some:** com o ambiente branco, a saturação 1 e a força das luzes 0, o `DayLightLayer` fica `visible = false`, e a placa de vídeo não gasta nada.

### A cor da hora

Uma tabela do jogo, `DayLightLayer.KEYFRAMES`, liga horas a (ambiente rgb, saturação). O filtro mistura em linha reta os dois pontos em volta da hora atual, voltando ao primeiro depois das 24h. Valores iniciais, _a revisar_ no aparelho:

| Hora | Ambiente (r, g, b) | Saturação | Clima |
| --- | --- | --- | --- |
| 0h | (0,42, 0,48, 0,72) | 0,65 | noite |
| 5h | (0,42, 0,48, 0,72) | 0,65 | noite |
| 6h30 | (0,95, 0,84, 0,82) | 0,95 | nascer do sol |
| 8h | (1, 1, 1) | 1 | dia |
| 16h | (1, 1, 1) | 1 | dia |
| 17h30 | (1, 0,84, 0,64) | 1,05 | sol dourado |
| 19h | (0,72, 0,56, 0,70) | 0,85 | crepúsculo |
| 20h | (0,42, 0,48, 0,72) | 0,65 | noite |

A **força das luzes** é outra curva da mesma tabela: 0 das 7h às 17h, sobe em linha reta até 1 às 19h, fica em 1 até as 5h e desce até 0 às 7h.

Os valores da noite deixam o mapa legível: nenhum canal do ambiente abaixo de 0,4.

## Os pontos de luz

Tabela `prop_type_lights` no schema `ecobeasts`, servida no catálogo, como a `prop_type_blocks`:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | |
| `prop_type_id` | int, FK `prop_types`, cascade | |
| `variant` | int | 0 a 99; 0 vale para as variantes sem luzes próprias, como em `prop_type_blocks` |
| `position` | int | a ordem no tipo e variante; único com os dois |
| `x`, `y` | int | o centro da luz em pixels da arte, a partir do pé da peça, como os pontos do bloqueio |
| `radius` | int | 2 a 96, em pixels da arte |
| `color` | text | `^[0-9a-f]{6}$` |

- O `x` e o `y` são o pixel do centro da luz a partir do pé (`x = coluna − largura // 2`, `y = linha − altura`), e o jogo soma 0,5 para cair no meio do pixel. O ponto parte do mesmo ponto em que a peça é desenhada: o pé erguido pela altura do hexágono. Na peça espelhada, a coluna vira `−x − 1 + largura % 2`, o pixel exato do espelho (as linhas de bloqueio usam só `−x`).
- `HexMapView.prop_lights(props)` monta a lista ao carregar o mapa, e a tela de exploração escolhe as 32 a cada mudança de vista (`_refresh_lights`). Cada luz é um `MapLight` (`res://ui/components/map_light.gd`: posição, raio e cor).
- Os pontos iniciais saem da arte pelo `client/assets/props/find_lights.py`, explicado em `client/assets/props/LUZES.md`.
- O `HexMapView` monta a lista das luzes das peças da ilha ao carregar o mapa, em pixels da arte, e a cada mudança de vista entrega ao filtro só as que tocam a área visível. A luz do Domador vai sempre primeiro. O resto vai pela distância até o Domador, até o limite de 32 luzes (`DayLightLayer.MAX_LIGHTS`).
- A luz do Domador é uma constante do jogo, _a revisar_: centro 10 px acima do pé, raio 36 px, cor `ffe8c0`.
- O mapa sorteado não tem peças, então lá só a luz do Domador acende.

## O indicador

O componente `DayPhaseBadge` (`res://ui/components/day_phase_badge.tscn`) mostra o ícone e o nome da parte do dia. Ele escuta o `WorldClock.phase_changed` e fica escondido enquanto o relógio não sincronizou. Os 4 ícones (sol nascendo, sol alto, sol se pondo e lua) são pixel art provisória, gerada por `client/assets/ui/day_phases/make_day_phase_icons.py`, _a revisar_.

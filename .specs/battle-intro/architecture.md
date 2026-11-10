# Arquitetura

O desenho que as fases da [battle-intro](README.md) compartilham.

Godot, para quem está começando: um **autoload** é um nó que o Godot cria uma vez, no começo do jogo, e deixa acessível de qualquer script pelo nome (como o `Router` e o `Session`). Ele continua vivo enquanto as telas trocam. Um **`CanvasLayer`** desenha os filhos numa camada própria, acima ou abaixo das outras. Um **shader** é um programa pequeno que a placa de vídeo roda para cada pixel. Com `hint_screen_texture`, ele lê o que já está desenhado na tela.

## Fluxo

```text
Procurar / tocar no log  →  await BattleIntro.cover(foco, opponent)
do Domador / Desafiar /     a música da luta começa (Music.play_battle(opponent))
teste do Debug              2 clarões, zoom pixelado no foco, tela preta

                         →  Router.push(&"board_battle", ...)
                            a tela da luta abre por baixo da tela preta

A tela da luta montou    →  BattleIntro.reveal()
o tabuleiro (ou deu         o pixelado se desfaz sobre a luta, e a camada some
erro)                       com erro, também Music.fade_out()

Fim da luta              →  vitória ou captura: Music.play_victory()
                            derrota ou fuga: Music.fade_out()
Sair da luta             →  Music.fade_out(), se algo ainda tocar
```

## BattleIntro

Autoload de cena (`res://core/autoload/battle_intro.tscn`): um `CanvasLayer` com `layer` acima de tudo e um `ColorRect` do tamanho da tela com o shader `res://ui/components/pixel_zoom.gdshader`. Escondido, ele não pega toques. Durante a transição, ele cobre a tela e engole os toques.

| Método | O que faz |
| --- | --- |
| `cover(focus: Vector2, opponent: StringName) -> bool` | Chamado com `await`. Começa a música da luta e anima os clarões, o zoom e o escurecer. Termina com a tela preta e devolve `true`. Com uma transição já correndo, não faz nada e devolve `false`, e quem chamou não abre a luta |
| `reveal() -> void` | Anima o pixelado se desfazendo sobre a tela de agora e esconde a camada. Sem `cover` antes, não faz nada. Não precisa de `await`: a abertura da luta já começa por baixo do pixelado |
| `is_covering() -> bool` | Se a tela está coberta, esperando o `reveal` |

`opponent` é `&"wild"` ou `&"tamer"`. `focus` é um ponto da tela de 720 × 1280 do projeto (o `get_global_transform_with_canvas().origin` do Domador, que já vem nessa medida com o `stretch` `canvas_items`). O shader recebe `focus / get_viewport().get_visible_rect().size`, em UV.

**Esperando o servidor:** se a tela ficar preta por mais de 0,4 s, a camada mostra "Procurando..." no meio, em `SecondaryLabel`, até o `reveal`.

**Nunca presa:** o voltar do aparelho não faz nada enquanto a tela está coberta (o `Router.back` confere `BattleIntro.is_covering()`). O `Router` ganha o sinal `screen_changed(id)`, e o `BattleIntro`, coberto, revela sozinho e chama `Music.fade_out()` quando a tela nova não é a `board_battle`. Assim, uma volta ao login por sessão perdida não deixa a tela preta.

### O shader

`pixel_zoom.gdshader`, `canvas_item`, lê a tela com `hint_screen_texture` e `filter_nearest`:

| Parâmetro | O que faz |
| --- | --- |
| `focus` | O centro do zoom, em UV da tela |
| `zoom` | 1 sem zoom. Acima de 1, aproxima do foco |
| `block` | O tamanho do pixel, em pixels da tela. 1 é a tela como ela é |
| `flash` | De 0 a 1, quanto a tela fica branca |
| `darken` | De 0 a 1, quanto a tela fica preta |

Cada pixel lê a cor do centro do seu bloco, com a UV aproximada do foco: `uv = focus + (uv - focus) / zoom`. O `block` vem em pixels da tela de 720 × 1280, e o shader converte para pixels de verdade com `SCREEN_PIXEL_SIZE` e o tamanho visível. A textura da tela é lida sem mipmaps (`filter_nearest`).

O `hint_screen_texture` num `CanvasLayer` acima de tudo funciona no renderizador Mobile do projeto. Conferir num Android antigo, que pode cair no Compatibility, fica para a `release-pipeline`.

### Tempos e valores

Em `BattleIntro`, _a revisar_, iguais aos da prévia aprovada:

| Etapa | Tempo | O que muda |
| --- | ---: | --- |
| Clarões | 0,45 s | `flash` sobe e desce duas vezes, até 0,9 |
| Zoom | 0,8 s | `zoom` de 1 a 3,5 e `block` de 1 a 120 pixels (um sexto da largura), acelerando. `darken` de 0 a 1 nos últimos 40% |
| Revelar | 0,65 s | `zoom` 1, `darken` 0 e `block` de 96 a 1 pixel, desacelerando |

Os pixels são medidos na tela de 720 × 1280 do projeto e acompanham a escala da janela.

## Music

Autoload de script (`res://core/autoload/music.gd`) com um `AudioStreamPlayer` no canal `Music`. O projeto ainda não tem `default_bus_layout.tres`: ele nasce com o canal `Music`, ligado ao Master, a −6 dB, _a revisar_. Os sons de hoje continuam no Master.

| Método | O que faz |
| --- | --- |
| `play_battle(opponent: StringName)` | Toca em loop a música de `wild` ou de `tamer`. Se a mesma já toca, não recomeça |
| `play_victory()` | Para a música e toca o toque de vitória uma vez |
| `fade_out(seconds := 1.0)` | Baixa o volume até sumir e para |
| `stop()` | Para na hora |

Os arquivos ficam em `res://assets/music/`:

| Arquivo | O que é | Duração |
| --- | --- | --- |
| `battle_wild.ogg` | A luta contra selvagem: animada, em tom maior | loop de 30 a 45 s |
| `battle_tamer.ogg` | A luta contra Domador: mais rápida e mais tensa, em tom menor | loop de 30 a 45 s |
| `victory.ogg` | O toque de vitória | 3 a 5 s, sem loop |

O loop vem do import do Godot (`loop = true` no `.import` das duas lutas), e cada música termina exatamente onde começa.

## O compositor

`res://assets/music/compose.py`, Python 3 sem biblioteca de fora. Ele escreve as três músicas em WAV e chama o `ffmpeg` para gerar os `.ogg`:

- **Quatro canais**, como os videogames de bolso: duas ondas quadradas (melodia e harmonia, com largura de pulso de 12,5%, 25% ou 50%), uma triangular (baixo) e ruído (percussão).
- **Partitura em texto** no próprio script: cada canal é uma lista de notas com duração em semicolcheias, e o andamento fica numa constante.
- **Envelope simples** por nota (ataque curto, queda até um nível, soltura), para as notas não estalarem.
- **Saída:** 44.100 Hz, mono, normalizada sem distorcer. O `ffmpeg` roda com `-fflags +bitexact -flags:a +bitexact`, para o `.ogg` sair igual a cada vez. Os `.import` com `loop` são gerados pelo editor uma vez e entram no git.

A composição é original: escalas, progressões de acordes e ritmos comuns do gênero, sem melodia de jogo nenhum. Rodar de novo gera os mesmos arquivos.

## Na tela da luta

- **Entradas:** a tela de exploração (`_search`, `_fight_challenger` e os botões de teste) e o Hub (Desafiar) fazem `await BattleIntro.cover(...)` antes do `Router.push`. O Hub ganha um caso no `_open` para o destino `board_battle`.
- **Revelar:** `_begin` chama `BattleIntro.reveal()` depois de `_fit_board()` e antes da abertura, ou logo antes de `_show_exit` quando o servidor recusa a luta.
- **Fim:** assim que os eventos da resposta terminam e a fase é `ended`, antes do aviso de registro do Bestiário e da comemoração de XP, o resultado `victory` ou `captured` chama `Music.play_victory()`, e `defeat` ou `fled` chama `Music.fade_out()`. Sair da luta (`_leave`) chama `Music.fade_out()`.

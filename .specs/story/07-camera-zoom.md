# 07. O zoom da câmera e os passos sem esperar

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [03](03-map-steps.md), [06](06-scene-timeline.md)

## Contexto

O dono quer abrir a `liora_abertura` com a câmera aproximando enquanto desliza pelo campo, e liberar uma fala no meio do movimento. Hoje cada passo espera o anterior acabar. Só o `move` tem `wait: false` ([03](03-map-steps.md), RF-05), e as cenas não mexem no zoom. Explorar tem o zoom em degraus inteiros de 1 a 4 ([camera-zoom](../camera-zoom/)), que o jogador escolhe pela pinça ou pela roda, e a cena não muda.

## Abordagens consideradas

| Abordagem | Troca | Escolha |
| --- | --- | --- |
| **"Sem esperar" nos passos**: `camera`, `camera_back` e `fade` ganham o `wait` do `move`, e o `camera` ganha o `zoom` | No F2 é a mesma lista de cartões com uma caixinha a mais, e quase todo "ao mesmo tempo" cabe nela | **escolhida pelo dono** |
| Um passo "Ao mesmo tempo", com trilhas de passos que rodam juntas | Mais poderoso, mas no F2 vira uma lista dentro da lista, mais difícil de ler e de editar | descartada pelo dono |

Para o zoom, o dono escolheu o **suave**: durante o passo o mapa passa por tamanhos fracionários, e termina sempre num degrau inteiro. A outra opção era pular de degrau em degrau (2 → 3 → 4), sempre nítido, mas com trancos. Depois, o dono pediu o zoom das cenas de 1 a 10, mais perto que a pinça do jogador (que continua de 1 a 4).

## Escopo

- O campo `zoom` no passo `camera`, e o `camera_back` devolvendo o zoom do jogador.
- O campo `wait` nos passos `camera`, `camera_back` e `fade`.
- A conferência dos campos novos pelo `StoryValidator`.
- Os campos novos no F2, nos campos do passo e no resumo do cartão.

## Fora do escopo

- O passo "Ao mesmo tempo", com trilhas paralelas.
- Zoom abaixo de 1, e a pinça e a roda do jogador além do 4.
- Um passo que espera a câmera acabar. Para isso, a cena usa um `wait` com os segundos que faltam.
- Tremor de câmera, curvas de movimento diferentes da `TRANS_SINE`/`EASE_IN_OUT` e zoom fora das cenas.
- Mudar as cenas do roteiro. O dono ajusta a `liora_abertura` no F2.

## Requisitos

### O zoom

- **RF-01:** O passo `camera` aceita `zoom`, opcional, um inteiro de 1 a 10 (`HexMapView.MIN_ZOOM` a `STORY_MAX_ZOOM`). Os degraus de 5 a 10 só existem nas cenas: a pinça e a roda do jogador continuam de 1 a 4 (`MAX_ZOOM`), e o zoom guardado no aparelho também. Com `zoom`, a câmera desliza até o hexágono e muda o zoom ao mesmo tempo, pelo mesmo tween (os mesmos `seconds`, `TRANS_SINE`, `EASE_IN_OUT`). Sem `zoom`, o zoom fica como está, como hoje.
- **RF-02:** O zoom do passo é suave. Durante o tween, a escala do mapa vai, por valores fracionários, da escala do zoom de agora até a do zoom pedido, e no fim fica exatamente no degrau inteiro (`HexMapView.art_scale()` do degrau). O ponto em foco fica no centro da tela durante todo o passo. A posição do mapa continua presa a pixels inteiros da janela (`_move_map`).
- **RF-03:** Tudo o que acompanha o mapa cresce junto durante o zoom: o Domador, os Ecobeasts, os Domadores NPC, os NPCs, os atores da cena, a névoa, o filtro do dia e da noite e os nomes das construções. Nada pula de tamanho no fim do tween.
- **RF-04:** O zoom de uma cena não é guardado no aparelho (`ViewSettings`). O `camera_back` volta ao Domador e ao zoom do jogador (`ViewSettings.explore_zoom()`) juntos, no mesmo tween. A volta automática do fim da cena ([03](03-map-steps.md), RF-07) faz o mesmo: ela acontece se a câmera não está no Domador **ou** se o zoom não é o do jogador.
- **RF-05:** O passo `create_tamer` continua pondo o zoom no `MAX_ZOOM` e, ao terminar, volta ao zoom em que a cena estava antes dele, não ao do jogador.

### Sem esperar

- **RF-06:** Os passos `camera`, `camera_back` e `fade` aceitam `wait`, um booleano, com padrão `true`. Com `wait: false`, a cena vai para o próximo passo logo que o movimento começa. Por exemplo, uma `say` logo depois mostra a fala enquanto a câmera ainda anda.
- **RF-07:** Um `camera` ou `camera_back` que começa com outro movimento de câmera em andamento para o anterior e parte do ponto e do zoom em que a câmera está naquele momento. O mesmo vale para um `fade` sobre outro `fade`. A câmera nunca salta. Um `camera` sem `zoom` que interrompe outro mantém o zoom para onde o anterior ia, não o do meio do caminho, para terminar num degrau inteiro (RF-02).
- **RF-08:** Antes dos passos que tomam a tela (`create_tamer`, `choose_starter` e `open_screen`), a cena espera acabar a câmera e o escurecer que estão sem esperar. Ao fim da cena, ela espera os dois antes da volta automática (RF-04) e da gravação dos Marcos, como já faz com o `move` sem esperar.

### A conferência

- **RF-09:** O `StoryValidator` confere o `zoom`, quando existe, como um inteiro de 1 a 10 ("o zoom vai de 1 a 10."), e o `wait` em `camera`, `camera_back` e `fade` como booleano (a mesma mensagem do `move`). Uma cena sem os campos novos continua válida e toca como hoje.

### O F2

- **RF-10:** Nos campos do passo `camera`, embaixo dos Segundos, entra o campo **Zoom**, com as opções "Manter" e de 1 a 10. "Manter" tira o `zoom` do passo. Os passos `camera`, `camera_back` e `fade` ganham a caixinha **"Esperar terminar"**, marcada por padrão, como o "Esperar chegar" do `move`. Um passo novo nasce sem `zoom` e com `wait: true`.
- **RF-11:** O resumo no cartão da linha do tempo ([06](06-scene-timeline.md)) mostra o zoom (`→ (q, r) em 4 s · zoom 3`) e, quando o `wait` é `false`, uma segunda linha "sem esperar", como o `move`.

## Critérios de aceite

- [ ] Um `camera` com `zoom` 4 a partir do zoom 2, em 4 s, aproxima e desliza juntos, sem tranco, e termina nítido.
- [ ] Com `wait: false` no `camera`, uma fala logo depois aparece com a câmera andando, e tocar na fala antes do fim não faz a câmera saltar.
- [ ] O Domador, os atores e a névoa crescem junto com o mapa durante o zoom.
- [ ] Ao fim da cena, a câmera volta ao Domador e ao zoom do jogador, e a pinça muda o zoom a partir do zoom dele.
- [ ] Um `create_tamer` logo depois de um `camera` sem esperar espera a câmera chegar.
- [ ] No F2, o campo Zoom e a caixinha "Esperar terminar" mudam o passo, o cartão mostra os dois, e Testar daqui toca do jeito mostrado.
- [ ] Uma cena com `zoom` 11 abre a tela "Erro nos dados do jogo" com a mensagem do zoom.
- [ ] As 9 cenas de Liora continuam válidas e tocam como antes.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Alterar:**
  - `client/ui/components/hex_map_view.gd`: a escala de um zoom fracionário. `var story_zoom := 0.0` segura o zoom do tween, e com ele o `art_scale()` interpola entre os dois degraus em volta. `const STORY_MAX_ZOOM := 10` é o limite das cenas.
  - `client/screens/exploration/exploration_screen.gd`:
    - `story_camera_to(coord, seconds, zoom: int)` e `story_camera_back(seconds)` animam o foco e o zoom num tween só, guardado em `_camera_tween` e parado por outro (RF-07).
    - `story_camera_idle() -> void` (com `await`) espera o tween que está andando.
    - A escala dos filhos do mapa (`_marker.scale` e os outros no `_fit_view`) passa a seguir a escala do zoom (RF-03).
  - `client/screens/exploration/story_player.gd`:
    - O `wait` dos 3 passos.
    - O `_fade_tween` guardado, parado por outro `fade`.
    - A espera antes dos passos que tomam a tela e no fim da cena (RF-08).
    - O zoom de antes do `create_tamer` (RF-05).
  - `client/core/story/story_validator.gd` (RF-09).
  - `client/tools/map_editor/scene_steps.gd`: os campos e o resumo (RF-10 e RF-11).
  - `.specs/story/architecture.md`: a tabela dos passos ganha o `zoom` e o `wait`.
- **Reutilizar:** o `_slide_camera`, o `_set_camera_focus`, o `_move_map`, o `_sync_view_layers` e a caixinha do `move` no F2.

O tween anima um valor de 0 a 1 e calcula o foco e o zoom a partir dele. Assim, o ponto em foco e a escala andam juntos, e o mapa não escorrega para o lado enquanto aproxima.

## Verificação

- `godot --headless --path client --quit-after 30`.
- Uma cena temporária em `client/zz_tmp_check` toca o `StoryPlayer` com um `camera` com `zoom` e sem esperar, seguido de uma `say`, e confere o zoom e o foco no fim. A cena é apagada depois.
- F5: a `liora_abertura` ajustada pelo dono, nos zooms 1 e 3 do jogador, de dia e de noite.

## Tarefas

- [x] O zoom fracionário do `HexMapView` e os filhos do mapa crescendo junto.
- [x] O `zoom` no `camera` e a volta ao zoom do jogador.
- [x] O `wait` em `camera`, `camera_back` e `fade`, com a espera antes dos passos que tomam a tela e no fim.
- [x] A conferência.
- [x] Os campos e o resumo no F2.
- [x] A `architecture.md`, o `client/CLAUDE.md`, o README e as tabelas das specs.

Notas da implementação:

- O `HexMapView.story_zoom` é o zoom fracionário; com ele maior que 0, o `art_scale()` interpola entre os dois degraus em volta, e por isso o `_fit_view` deixa os sprites do tamanho do mapa sem mudança.
- A câmera da tela tem um tween só (`_camera_tween`), que avisa pelo sinal `camera_settled`; o `story_camera_idle()` espera por ele. O escurecer do `StoryPlayer` faz o mesmo (`_fade_tween`, `fade_settled`).
- O zoom de quando a câmera para é guardado em `_camera_target_zoom`, para o `camera` sem `zoom` que interrompe outro (RF-07).

Conferido por Claude, sem janela, com a API local e uma cena de teste na ilha 1199: um `camera` com `zoom` 4 sem esperar, uma fala, outro `camera` sem `zoom`, um `fade` e um `camera_back` sem esperar. A fala ficou aberta com o zoom subindo (2,1 ao tocar), a segunda câmera partiu de onde a primeira estava e levou o zoom até o 4, o zoom nunca mudou mais que 0,1 entre dois quadros, e no fim a câmera voltou ao Domador e ao zoom do jogador, a tela clareou e os controles voltaram. A conferência recusou o zoom 5 (o limite ainda era 4), o 2,5 e o `wait` de texto; com o limite em 10, ela aceita o 10 e recusa o 11. Os scripts do F2 compilam, e as 9 cenas de Liora carregam. Fica para o dono: ver o zoom suave na tela, a fala no meio do movimento e os campos no F2.

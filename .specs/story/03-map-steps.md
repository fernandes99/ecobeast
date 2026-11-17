# 03. Os passos no mapa

- **Status:** concluída
- **Depende de:** [02](02-scene-player.md)

## Contexto

A [02](02-scene-player.md) toca conversas: falas, escolhas e Marcos. As cenas do roteiro do dono também mexem no mapa: o avô entra pela trilha, a câmera percorre o campo, o avô vai junto até a vila. Esta fase traz os passos que fazem isso ([architecture](architecture.md#os-passos)), com os atores da cena como sprites de NPC no mapa.

## Escopo

- Os atores: o NPC novo da cena e o NPC da ilha (`island_npc`).
- Os passos `show`, `hide`, `move`, `face`, `camera`, `camera_back`, `follow`, `unfollow` e `open_screen`.
- O NPC que segue o Domador, também depois da cena.
- Uma segunda cena de exemplo.

## Fora do escopo

- Animações além de andar e parado (agachar, pular, emoção).
- Seguir na luta ou fora da ilha.
- A ferramenta Cenas (fase 04).

## Requisitos

### Os atores

- **RF-01:** Ao começar a cena, o `StoryPlayer` monta os atores. Um ator com `q` e `r` vira um `NpcSprite` novo, feito de um `MapNpc` com o `npc_id`, o hexágono e `still = true`, posto no mapa como os da ilha (`place_on`, a escala do Domador) e escondido se `visible` é `false`. Um ator `island_npc` é o `NpcSprite` da ilha com esse `npc_id`: o tocado, no gatilho `npc`, senão o primeiro de `_map.npcs`; sem nenhum, o ator falta, e os passos dele são pulados com um aviso no console.
- **RF-02:** O `StoryValidator` passa a conferir, nos atores: `q` e `r` inteiros ou `island_npc: true`, nunca os dois nem nenhum; e, nos passos, os campos da tabela da [architecture](architecture.md#os-passos) (`actor` que é `tamer` ou uma `key`, onde o passo aceita `tamer`; `toward` com `q` e `r` ou uma `key`; `seconds` de 0,1 a 10; `screen` da lista).
- **RF-03:** Ao fim da cena, os atores novos saem do mapa, menos os que estão seguindo o Domador (RF-08). Os atores da ilha voltam a passear (`hold(false)`).

### Os passos

- **RF-04:** `NpcSprite` ganha `signal arrived`, `func walk_to(target: Vector2i) -> void` e `var scripted: bool`. Com `scripted`, o NPC não sorteia passeio. `walk_to` acha o caminho por `ExplorationMap.path_to_any` (sem pontes, como o passeio) e anda por ele, emitindo `arrived` ao chegar; sem caminho, ele aparece no destino, emite `arrived` e o console avisa "Cena <slug>: <key> não acha caminho até (q, r).". Durante a cena, todo ator é `scripted`.
- **RF-05:** `move`: o ator anda até o hexágono; com `wait` (padrão `true`), o próximo passo espera o `arrived`. Para `tamer`, a tela anda o Domador pelo mesmo `_walk` do toque, até o centro do hexágono, e espera a caminhada acabar. Durante a cena, o andar do Domador não procura gatilho de área, não abre a ação da construção onde ele entra e não para no hexágono de um Domador NPC para o desafio. Um `move` sem `wait` que ainda não acabou quando a cena termina é esperado antes da gravação.
- **RF-06:** `face`: vira o ator (ou o Domador, `_marker.face_toward`) para o centro do hexágono `toward` ou para a posição do ator `toward`.
- **RF-07:** `camera` e `camera_back`: a tela ganha `var _camera_focus := Vector2.INF` (o ponto da arte no centro da tela; `INF` é o Domador) e o `_player_centered_position` passa a centrar nele quando não é `INF`. `camera` anda o foco do ponto de agora até `HexMapView.flat_center` do hexágono, com o rise dele, em `seconds`, por um `Tween` com `TRANS_SINE` e `EASE_IN_OUT`, sempre em pixels inteiros (`_move_map`); `camera_back` volta até o Domador e põe `INF` de novo. Ao terminar a cena, se a câmera não está no Domador, ela volta em 0,5 s.
- **RF-08:** `follow` e `unfollow`: o ator passa a seguir o Domador ou para. Quem segue anda (por `walk_to`) até o último hexágono por onde o Domador passou antes do de agora, a cada vez que `_player_coord` muda; até lá fica onde está. Seguir sobrevive ao fim da cena e dura até o `unfollow` ou o Domador sair da ilha. Um ator da ilha que segue não volta ao passeio ao fim da cena, só no `unfollow`, e aí passeia a partir de onde está. Dois seguidores vão em fila: o segundo segue o hexágono que o primeiro deixou.
- **RF-09:** `open_screen`: `Router.push` da tela (`appearance`, `heal_station`, `shop`, `team`, `bag` ou `codex`) e espera a tela de Explorar voltar a aparecer (`visibility_changed` com ela visível). A cena continua de onde estava.
- **RF-10:** `show` e `hide` mostram e escondem o ator; um ator escondido não responde ao toque nem segue.

### O exemplo

- **RF-11:** `res://story/scenes/exemplo_chegada.json`, uma cena `area` em 3 hexágonos de uma ilha publicada, não repetível, que exige `exemplo_conversa`: a câmera vai até um ponto a uns 6 hexágonos, um NPC novo aparece lá e anda até perto do Domador, a câmera volta, os dois se viram um para o outro, uma fala, o NPC passa a seguir, e o Domador anda 2 hexágonos. O id da ilha fica escrito aqui ao concluir a fase.

## Critérios de aceite

- [ ] No exemplo, a câmera desliza sem tremer, em pixels inteiros, e volta ao Domador.
- [ ] O NPC novo aparece, anda pelo caminho (contornando a água) e fala virado para o Domador.
- [ ] Depois da cena, o NPC segue o Domador pela ilha, um hexágono atrás, e some ao sair da ilha.
- [ ] Um ator mandado para um hexágono sem caminho aparece lá, e o console avisa.
- [ ] Uma cena com `open_screen` `appearance` abre a Aparência, e ao voltar a cena continua.
- [ ] Durante um `move` do Domador, passar por uma área com cena ou entrar no Refúgio não dispara nada.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Alterar:**
  - `client/ui/components/npc_sprite.gd` (`scripted`, `walk_to`, `arrived`)
  - `client/screens/exploration/story_player.gd` (os atores e os 9 passos)
  - `client/screens/exploration/exploration_screen.gd` (o `_camera_focus`, os seguidores a cada `_player_coord` novo, o andar do Domador pela cena e a limpeza ao sair)
  - `client/core/story/story_validator.gd` (o RF-02)
- **Criar:** `client/story/scenes/exemplo_chegada.json`
- **Reutilizar:** o `_walk` e o `WalkRoute` do Domador, o `path_to_any` e o `_move_map`.

O `StoryPlayer` fala com a tela por métodos dela com o prefixo `story_` (`story_walk_tamer(coord: Vector2i) -> void`, com `await`; `story_face_tamer(point: Vector2)`; `story_camera_to(point: Vector2, seconds: float) -> void`, com `await`; `story_camera_back(seconds: float) -> void`, com `await`; `story_npc_sprite(npc_id: int, touched: NpcSprite) -> NpcSprite`; `story_add_actor(sprite: NpcSprite)`; `story_set_follow(sprite: NpcSprite, on: bool)`), para a tela de 1.100 linhas não crescer com a lógica dos passos.

## Verificação

- `godot --headless --path client --quit-after 30`.
- F5: o exemplo, nos zooms 1 e 3, de dia e de noite; um destino sem caminho (mudando o arquivo à mão); uma cena com `open_screen`; e o "Cenas" do Debug para repetir.

## Tarefas

- [x] `NpcSprite.walk_to` e os atores.
- [x] `show`, `hide`, `move` e `face`.
- [x] `camera` e `camera_back`.
- [x] `follow` e `unfollow`, também depois da cena.
- [x] `open_screen`.
- [x] O exemplo, `client/CLAUDE.md`, o README e as tabelas das specs.

Notas da implementação:

- Os métodos da tela são `story_island_npc(npc_id, tocado)`, `story_add_actor(npc_id, hexágono)`, `story_release(sprite, criado)`, `story_walk_tamer`, `story_face_tamer`, `story_tamer_point`, `story_hex_point`, `story_camera_to`, `story_camera_back`, `story_set_follow` e `story_open_screen`.
- `NpcSprite.walk_to` devolve `ARRIVED`, `WALKING` ou `JUMPED`, e só quem está andando emite `arrived`, para a cena não esperar um sinal que já passou. Na cena, o ator anda a `STORY_SPEED` (60 px/s, a revisar); quem segue anda na velocidade do Domador (`WalkRoute.WALK_SPEED`), para não ficar para trás.
- `face` também aceita `"tamer"` em `toward` (o NPC vira para o Domador).
- Um ator da ilha que a cena usa, ou o NPC tocado, volta a passear ao fim (`NpcSprite.resume`), menos quem segue. Quem segue é procurado antes pelos atores `island_npc` de outra cena, para uma cena depois poder dar o `unfollow`.

Conferido por Claude, sem janela e em modo de teste: o `exemplo_chegada` tocou inteiro (a câmera, o ator aparecendo e andando, as viradas, a fala, o seguir e o Domador andando 2 hexágonos), e no fim havia 1 seguidor, a câmera voltou ao Domador e os controles voltaram. Fica para o dono: ver a câmera deslizando, o caminho do ator, o seguidor pela ilha, um destino sem caminho, o `open_screen` e o `move` do Domador passando por uma área e pelo Refúgio.

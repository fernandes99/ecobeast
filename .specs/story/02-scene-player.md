# 02. O tocador de cenas e os passos de conversa

- **Status:** concluída
- **Depende de:** [01](01-story-marks.md), [island-npcs/03](../island-npcs/03-npc-talk.md)

## Contexto

Com os Marcos no servidor ([01](01-story-marks.md)), falta o jogo ler as cenas e tocá-las. Esta fase cria o formato no disco, a conferência dos arquivos, a escolha da cena por gatilho e o tocador com os passos de conversa ([architecture](architecture.md#os-passos)). Os passos que mexem no mapa (andar, câmera, atores aparecendo) ficam para a [03](03-map-steps.md); aqui um ator só dá o nome a quem fala. Como a ferramenta Cenas só chega na [04](04-scenes-tool.md), as cenas desta fase são escritas à mão.

## Escopo

- O modelo `StoryScene`, a `StoryLibrary` e o `StoryValidator`.
- O autoload `Story`: os Marcos, a escolha por gatilho e a gravação.
- O `StoryPlayer`, com `say`, `choice`, `if_mark`, `set_mark`, `wait` e `fade`.
- Na tela `exploration`: os três gatilhos, a UI escondida durante a cena e a entrada "Cenas" no menu Debug.
- Uma cena de exemplo e o filtro de exportação.

## Fora do escopo

- Os passos do mapa (fase 03) e a ferramenta Cenas (fase 04).
- Pular cena, retratos e som.

## Requisitos

### O arquivo e a conferência

- **RF-01:** `StoryScene` (`res://domain/models/story_scene.gd`, `class_name StoryScene`, `RefCounted`) tem `slug`, `name`, `island_id`, `repeatable`, `priority`, `requires: Array[String]`, `forbids: Array[String]`, `trigger: Dictionary`, `actors: Array[Dictionary]` e `steps: Array` (os passos ficam como `Dictionary`, como vieram do arquivo), com `static func from_dict(d: Dictionary) -> StoryScene` e `func to_dict() -> Dictionary` (a ordem das chaves da [architecture](architecture.md#o-cliente-o-arquivo-da-cena), para o arquivo salvo pela fase 04 ficar fácil de comparar no git). Também tem `func actor(key: String) -> Dictionary` (vazio quando não existe).
- **RF-02:** `StoryLibrary` (`res://core/story/story_library.gd`, `class_name StoryLibrary`, `RefCounted`) tem `const SCENES_DIR := "res://story/scenes/"`, `func load_all() -> Array[String]` (os erros; lê todo `.json` da pasta em ordem de nome, monta as cenas e chama o validador), `var scenes: Array[StoryScene]` e `func for_island(island_id: int) -> Array[StoryScene]`. Um arquivo que não é JSON válido dá "Cena <arquivo>: o arquivo não é um JSON válido.".
- **RF-03:** `StoryValidator` (`res://core/story/story_validator.gd`, `class_name StoryValidator`) tem `static func validate(scenes: Array[StoryScene], file_names: Array[String]) -> Array[String]`. Cada erro começa com "Cena <slug>:" e, quando é de um passo, diz o caminho dele, numerado de 1 com os blocos separados por ponto ("passo 5.2.1" é o 1º passo da 2ª opção do 5º passo; no `if_mark`, `then` é o bloco 1 e `else` o 2). Confere:
  - `slug` fora de `^[a-z0-9_]{1,48}$`, repetido, ou diferente do nome do arquivo sem `.json`;
  - `name` vazio; `island_id` que não é inteiro positivo;
  - Marco fora de `^[a-z0-9_]{1,48}$` em `requires`, `forbids` e `set_mark`; o mesmo Marco em `requires` e `forbids`;
  - `trigger.type` fora de `auto`, `npc` e `area`; `npc` sem `npc_id` do catálogo (`GameData.get_npc`); `area` sem hexágonos ou com hexágono repetido;
  - em `actors`: `key` fora de `^[a-z0-9_]{1,24}$`, repetida, igual a `tamer`, ou `npc_id` que não existe no catálogo;
  - passo de `type` desconhecido (a lista desta fase e a da [03](03-map-steps.md)), campo obrigatório faltando, `speaker` que não é `null`, `tamer` nem a `key` de um ator; `text` vazio ou com mais de 300 caracteres; `choice` com menos de 2 ou mais de 4 opções, ou opção sem `text`; `wait.seconds` e `fade.seconds` fora de 0,1 a 10; `fade.to` fora de `black` e `clear`; blocos com mais de 8 níveis.
- **RF-04:** O `main.gd` carrega as cenas logo depois do catálogo (o validador precisa dos NPCs): `Story.load_scenes()` devolve os erros, que vão para a mesma tela "Erro nos dados do jogo" (`_show_data_errors`) que os do catálogo.
- **RF-05:** O `export_presets.cfg` inclui `story/scenes/*.json` no `include_filter` de todos os presets, porque o Godot não exporta `.json` sozinho. Sem isso, o jogo exportado não teria cena nenhuma.

### O autoload `Story`

- **RF-06:** `Story` (`res://core/autoload/story.gd`, registrado em `project.godot` depois de `Session`) guarda a `StoryLibrary` e tem:
  - `func marks() -> Array[String]`: `Session.player.story_marks`, ou os Marcos de teste quando há um teste (RF-15);
  - `func can_run(scene: StoryScene, island_id: int) -> bool`: a regra da [architecture](architecture.md#o-cliente-o-arquivo-da-cena) (a ilha, os `requires`, os `forbids` e, se não repetível, o Marco `slug`);
  - `func scene_for_auto(island_id: int) -> StoryScene`, `func scene_for_npc(island_id: int, npc_id: int) -> StoryScene` e `func scene_for_tile(island_id: int, coord: Vector2i) -> StoryScene`: entre as cenas do gatilho que podem rodar, a de maior `priority` e, no empate, a de menor `slug`; `null` quando nenhuma;
  - `func finish(scene: StoryScene, set_marks: Array[String]) -> Result`: monta os Marcos a gravar (o `slug`, se não repetível, e os `set_marks`, sem repetidos e sem os que o jogador já tem). Vazio, devolve sucesso sem chamar o servidor; com algum, chama `Session.add_story_marks`. Em teste, só junta os Marcos aos de teste.
- **RF-07:** A cena que roda é uma cópia: o `StoryPlayer` não muda a `StoryScene` da biblioteca.

### O `StoryPlayer`

- **RF-08:** `StoryPlayer` (`res://screens/exploration/story_player.gd`, `class_name StoryPlayer`, um `Control` que cobre a tela e para os toques enquanto toca) tem `signal finished`, `func play(scene: StoryScene) -> void` (com `await`, volta quando a cena e a gravação terminam) e `var playing: bool`. Ele cria os filhos dele: um `TamerGreetingPanel` (na mesma posição do da tela), o `StoryChoicePanel` e o `ColorRect` do escurecer, que cobre o mapa e fica abaixo da caixa de fala e das opções.
- **RF-09:** Os passos desta fase, como na [architecture](architecture.md#os-passos):
  - `say`: a caixa mostra "<nome>: <texto>" (o nome do NPC do ator pelo `GameData.get_npc`, ou o do Domador para `tamer`) ou só o texto na narração (`speaker` nulo), e espera o `tapped`. `{nome}` vira `Session.player.name`. Depois do toque, a caixa fecha, menos quando o próximo passo é uma `choice` (mudança pedida pelo dono depois da fase: a caixa ficava aberta com a última fala durante a câmera, as esperas e os movimentos);
  - `choice`: o `StoryChoicePanel` (`res://screens/exploration/story_choice_panel.gd`, uma coluna de botões com o tema da caixa de fala, logo acima dela) mostra as opções; a caixa de fala continua com a última fala; tocar numa fecha a caixa e roda os passos dela;
  - `if_mark`: o Marco vale se está em `Story.marks()` ou foi ligado nesta cena;
  - `set_mark`: junta o Marco à lista da cena;
  - `wait`: espera `seconds`;
  - `fade`: anima a opacidade do `ColorRect` até 1 (`black`) ou 0 (`clear`) em `seconds`. Ao terminar a cena, a tela clareia em 0,3 s se ficou escura.
- **RF-10:** Ao fim dos passos, o `StoryPlayer` chama `Story.finish`. Se falhar, a caixa mostra "Não deu para salvar a história. <erro>" e o painel de opções, só com "Tentar de novo", que chama de novo. A cena só termina (`finished`) com a gravação feita.

### Na tela de Explorar

- **RF-11:** A tela `exploration` tem um `StoryPlayer` (o nó `Story`, acima de tudo menos o menu Debug). Enquanto ele toca: os toques no mapa não andam, o painel de controles e o minimapa ficam escondidos, e o passeio dos NPCs continua.
- **RF-12:** O gatilho `auto` é procurado no fim do `_begin` (depois do mapa, dos NPCs e da descoberta) e depois de cada cena terminar, só numa ilha (`_map.island_id > 0`).
- **RF-13:** No `_talk`, antes do diálogo do NPC, `Story.scene_for_npc(island_id, npc.npc.npc_id)`: com uma cena, o NPC para virado para o Domador (`hold`), a cena toca no lugar do diálogo e da ação dele, e o NPC volta a passear ao fim. Um NPC sem diálogo nem ação, mas com uma cena, também responde ao toque: o `_npc_hit` aceita o NPC com `has_talk()` ou com cena.
- **RF-14:** No `_walk`, quando `_player_coord` muda, `Story.scene_for_tile`: com uma cena, o Domador para no fim desse passo (`_stop_walk`), e a cena toca quando a caminhada acaba. Ao entrar na ilha, o fim do `_begin` procura primeiro uma cena de área no hexágono de chegada e, sem nenhuma, a `auto`.
- **RF-14b:** Durante a cena, o voltar (o botão do Android e o Esc) não sai da tela: o `handle_back` da tela devolve `true` enquanto o `StoryPlayer` toca, como já faz na conversa com um NPC.
- **RF-15:** O menu Debug da tela, numa ilha, ganha "Cenas": a lista das cenas da ilha, e tocar numa a toca em teste. No teste, `Story.marks()` são os `requires` da cena mais o que ela liga, nada vai ao servidor, e os gatilhos não procuram outras cenas até ele acabar. `Story.begin_test(scene: StoryScene, marks: Array[String])` e `Story.end_test()` ligam e desligam isso (a fase 04 usa os mesmos).

### O exemplo

- **RF-16:** `res://story/scenes/exemplo_conversa.json`, uma cena `npc` com o NPC 1 (Ruvo da vila) numa ilha publicada que o tenha, não repetível, com uma fala, uma escolha de 2 opções (uma delas com `set_mark` `exemplo_escolheu_sim`) e um `if_mark` que responde conforme a opção. Depois de tocada uma vez, o Ruvo volta ao diálogo da ilha. O id da ilha usado fica escrito aqui ao concluir a fase.

## Critérios de aceite

- [ ] Uma cena com passo de tipo errado, Marco com maiúscula ou NPC que não existe abre a tela "Erro nos dados do jogo" com a mensagem do RF-03, com o caminho do passo.
- [ ] Tocar no Ruvo da ilha do exemplo toca a cena: a fala, a escolha e a resposta certa para cada opção.
- [ ] Depois da cena, `GET /v1/me` traz `exemplo_conversa` e, se a opção foi a com Marco, `exemplo_escolheu_sim`; tocar no Ruvo de novo mostra o diálogo da ilha.
- [ ] Fechar o jogo no meio da cena e voltar: a cena toca de novo, e nada foi gravado.
- [ ] Com o servidor parado no fim da cena, aparece "Tentar de novo"; com ele de volta, a cena termina.
- [ ] Durante a cena, tocar no mapa não anda, e o painel de controles e o minimapa somem.
- [ ] "Cenas", no menu Debug, toca o exemplo de novo sem gravar nada.
- [ ] O jogo exportado (Android) também toca o exemplo.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Criar:**
  - `client/domain/models/story_scene.gd`
  - `client/core/story/story_library.gd`, `client/core/story/story_validator.gd`
  - `client/core/autoload/story.gd`
  - `client/screens/exploration/story_player.gd`, `client/screens/exploration/story_choice_panel.gd`
  - `client/story/scenes/exemplo_conversa.json`
- **Alterar:**
  - `client/project.godot` (o autoload `Story`)
  - `client/export_presets.cfg` (o `include_filter`)
  - `client/screens/main/main.gd` (carregar as cenas no `_boot`)
  - `client/screens/exploration/exploration_screen.gd` e `.tscn` (o nó, os gatilhos em `_begin`, `_talk`, `_npc_hit` e `_walk`, o bloqueio do toque e a entrada do Debug)
- **Reutilizar:** o `TamerGreetingPanel` (a caixa de fala, sem mudar), o `BattleTheme` nos botões das opções e o `DictFields` para ler o arquivo.

O cliente não tem testes automáticos ([README das specs](../README.md#regras)). Para conferir o validador sem janela, use uma cena temporária em `client/zz_tmp_check/` que chama `StoryValidator.validate` com cenas erradas e imprime os erros, e apague a pasta depois.

## Verificação

- `godot --headless --path client --quit-after 30` e a cena temporária do validador.
- F5: o exemplo na ilha, as duas opções (apagando o progresso pelo Perfil entre uma e outra), o servidor parado no fim, fechar no meio e o "Cenas" do Debug.
- No Android: o exemplo no jogo exportado.

## Tarefas

- [x] `StoryScene`, `StoryLibrary` e `StoryValidator`, conferidos pela cena temporária.
- [x] O autoload `Story`, o carregamento no `main.gd` e o filtro de exportação.
- [x] O `StoryPlayer` e o `StoryChoicePanel` com os 6 passos.
- [x] Os gatilhos, a UI escondida e o "Cenas" do Debug na tela `exploration`.
- [x] A cena de exemplo.
- [x] `client/CLAUDE.md` (a pasta `core/story/` e o autoload), o README e as tabelas das specs.

Notas da implementação:

- O `StoryPlayer` é um `Node`, e não um `Control` com a caixa de fala dele: ele usa a `TamerGreeting` da tela, e a tela põe o `StoryChoicePanel` logo acima dela, na mesma coluna, e o escurecer (um `ColorRect` na cor `UiPalette.BACKGROUND_DEEP`) dentro do `MapArea`, por cima do mapa e embaixo da interface. Assim a caixa fica no mesmo lugar da conversa com um NPC.
- A tela de Explorar ganhou `class_name ExplorationScreen`, para o `StoryPlayer` chamar os métodos `story_*` dela com tipo.
- O botão do menu Debug é "Debug: cenas da ilha".
- O `StoryValidator` confere o NPC pela lista do catálogo (`has_npc`), sem o `GameData.get_npc`, que escreve um erro no console para um id que não existe.
- A ilha das cenas de exemplo é a 1199 ("Ilha nova"), com o Ruvo da vila em (-5, 2).

Conferido por Claude, sem janela: o validador acusa as mensagens do RF-03 com o caminho do passo (numa cena temporária com 20 erros), as duas cenas de exemplo carregam sem erro, e a tela de Explorar, aberta numa cena temporária com a conta deste aparelho e em modo de teste (sem gravar Marcos), tocou o `exemplo_conversa` inteiro (a fala com o nome do Domador, a escolha e a resposta da opção escolhida) e voltou com os controles à mostra. Fica para o dono: tocar no Ruvo de verdade (o Marco gravado no servidor), fechar no meio, o "Tentar de novo" com o servidor parado, o "Debug: cenas da ilha" e o jogo exportado no Android.

# 04. A ferramenta Cenas do editor

- **Status:** concluída
- **Depende de:** [03](03-map-steps.md), [island-npcs/02](../island-npcs/02-npc-tool.md)

## Contexto

Com a [02](02-scene-player.md) e a [03](03-map-steps.md), o jogo toca cenas escritas à mão em `.json`. Esta fase entrega o objetivo principal da iniciativa: o dono escreve, muda e testa uma cena sozinho, dentro do F2, sem abrir arquivo ([README](README.md#objetivos)). A ferramenta segue o jeito da ferramenta NPC: um painel do lado e cliques no mapa da ilha aberta ([architecture](architecture.md#o-editor-a-ferramenta-cenas)).

## Escopo

- A ferramenta Cenas, no grupo Jogo do F2.
- O painel: a cena escolhida, os campos, o gatilho, os atores, a árvore de passos e os campos do passo.
- Escolher hexágonos no mapa e as marcas da cena desenhadas nele.
- Salvar, Apagar e Testar daqui.

## Fora do escopo

- Desfazer e refazer nas cenas (o histórico do editor é do mapa). "Descartar" volta ao arquivo salvo.
- Renomear o `slug` de uma cena; para isso, crie outra e apague a velha.
- Testar o rascunho da ilha (só a versão publicada, [README](README.md#decisões)).
- A Linha da história (fase 05).

## Requisitos

### A ferramenta e a lista

- **RF-01:** `EditorTools.Tool` ganha `SCENES`, com o nome "Cenas", o ícone `scene` (um SVG novo em `client/tools/map_editor/icons/`, no estilo dos outros) e a dica "Escolha uma cena no painel. Os botões \"Escolher no mapa\" pegam hexágonos da ilha.", no grupo Jogo, depois de NPC.
- **RF-02:** `ScenePanel` (`client/tools/map_editor/scene_panel.gd`, `class_name ScenePanel`) é o painel da ferramenta. No topo: a lista das cenas da ilha aberta (`Story.library.for_island`, pelo `name`, em ordem de `slug`), "Nova cena" e "Apagar". Uma ilha nunca salva no servidor (sem `id`) mostra só "Salve a ilha para criar cenas.".
- **RF-03:** "Nova cena" pede o `slug` (com a regra `^[a-z0-9_]{1,48}$`, recusando um que já existe em qualquer ilha) e o `name`, e cria a cena com `repeatable` falso, `priority` 0, o gatilho `auto` e nenhum passo, ainda não salva.
- **RF-04:** "Apagar" pergunta "Apagar a cena <name>? O arquivo sai da pasta." e apaga `res://story/scenes/<slug>.json` e a cena da biblioteca.

### Os campos da cena

- **RF-05:** Os campos: `name`, Repetível (`repeatable`), Prioridade (`priority`, de -99 a 99), Precisa de (`requires`) e Não pode ter (`forbids`). As listas de Marcos são um campo de texto com os Marcos separados por vírgula e um menu com os Marcos já usados em alguma cena (os `slug` das não repetíveis e os `set_mark`), para não errar a grafia.
- **RF-06:** O gatilho: um seletor Ao entrar (`auto`), Ao tocar no NPC (`npc`) e Ao pisar na área (`area`). Com `npc`, um menu com os NPCs postos na ilha (pelo nome do catálogo, cada `npc_id` uma vez). Com `area`, "Escolher no mapa", que liga e desliga hexágonos a cada clique até "Pronto", e o número de hexágonos escolhidos.
- **RF-07:** Os atores: uma lista com `key`, o NPC do catálogo, "Da ilha" (`island_npc`) ou o hexágono (com "Escolher no mapa") e Começa escondido (`visible` falso). Adicionar, apagar.

### Os passos

- **RF-08:** Os passos ficam num `Tree` do Godot: um item por passo, com o texto curto do passo ("Fala · Avô: Ei! Já estava...", "Andar · avo → (12, -3)", "Escolha", "Se tiver o Marco sabe_da_mira"), e os blocos como filhos: cada opção da escolha ("Opção: Estava vendo...") e o "Então" e o "Senão" do `if_mark`, com os passos deles dentro.
- **RF-09:** Os botões: "+ Passo" (um menu com os 15 tipos pelo nome em pt-BR, que põe o passo depois do escolhido ou, com um bloco escolhido, no fim dele), Apagar, Subir e Descer (dentro do mesmo bloco). Numa escolha, "+ Opção" (até 4); ao criar, a escolha já tem 2 opções.
- **RF-10:** Abaixo da árvore, os campos do passo escolhido, conforme o tipo ([architecture](architecture.md#os-passos)): quem fala ou o ator (um menu com Domador, Narração quando cabe, e as `key` dos atores), o texto (com a contagem até 300), o hexágono (com "Escolher no mapa"), os segundos, a tela, o Marco. Mudar um campo atualiza a árvore na hora.

### O mapa

- **RF-11:** Com a ferramenta Cenas, o mapa da ilha desenha, por cima: os hexágonos da área do gatilho (contorno na cor de destaque do editor), os atores com hexágono (o primeiro quadro do sprite, meio transparente se começam escondidos) e, no passo escolhido, o destino de `move`, `camera` e `face` (um contorno com uma seta a partir de onde o ator está nesse ponto da cena, quando dá para saber pelos passos de antes).
- **RF-12:** "Escolher no mapa" põe o canvas no modo de pegar: o próximo clique num hexágono da ilha preenche o campo; Esc ou o botão direito desistem. Um clique fora da ilha mostra "Esse hexágono não é da ilha.".

### Salvar e testar

- **RF-13:** "Salvar" confere a cena pelo `StoryValidator` (junto com as outras, para pegar `slug` repetido) e, sem erro, grava `res://story/scenes/<slug>.json` com `JSON.stringify(scene.to_dict(), "  ", false)` e troca a cena na biblioteca do `Story`, sem precisar reabrir o jogo. Com erro, mostra o primeiro e não grava. A cena com mudanças não salvas tem um "•" no nome, e trocar de cena ou de ilha pergunta "Descartar as mudanças da cena?".
- **RF-14:** Gravar em `res://` só funciona com o jogo aberto pelo editor do Godot (`OS.has_feature("editor")`); fora dele, Salvar e Apagar ficam desligados com "Abra o jogo pelo Godot para salvar cenas.".
- **RF-15:** "Testar daqui", com os Marcos do teste (um campo que começa com os `requires` da cena): fecha o F2, chama `Story.begin_test` ([02](02-scene-player.md#na-tela-de-explorar)) com uma cópia da cena como está no painel (salva ou não), e abre Explorar na ilha (`Router.push(&"exploration", {"island_id": id, "story_test": true})`). A tela toca a cena de teste assim que o mapa carrega, no lugar do `auto`, e chama `Story.end_test` quando ela termina ou quando a tela fecha. Desligado, com o motivo: "Publique a ilha para testar a cena." (ilha nunca publicada) ou "Entre com um Domador para testar." (sem jogador).
- **RF-16:** Ao salvar a ilha, o editor avisa (sem impedir) de cada cena dela que usa um hexágono que não é mais da ilha: "A cena <name> usa (q, r), que não é mais da ilha.".

## Critérios de aceite

- [ ] O dono cria pelo F2, sem abrir arquivo, uma cena com fala, escolha com 2 opções, `if_mark`, um ator novo que anda e a câmera, e o arquivo aparece em `client/story/scenes/`.
- [ ] Subir, descer e apagar passos dentro de uma opção mexem só naquele bloco.
- [ ] "Escolher no mapa" preenche o hexágono do passo, e o mapa mostra o destino do passo escolhido.
- [ ] Salvar uma cena com Marco "Sabe Da Mira" mostra o erro e não grava.
- [ ] "Testar daqui" toca a cena na ilha publicada, com as mudanças ainda não salvas, sem gravar Marco no servidor.
- [ ] Uma cena salva roda no jogo sem reabrir o jogo.
- [ ] Tirar da ilha um hexágono que uma cena usa e salvar mostra o aviso.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Criar:**
  - `client/tools/map_editor/scene_panel.gd` (a lista, os campos e os atores)
  - `client/tools/map_editor/scene_steps.gd` (`class_name SceneSteps`: a árvore, os botões e os campos do passo, para o painel não passar de algumas centenas de linhas)
  - `client/tools/map_editor/icons/scene.svg`
- **Alterar:**
  - `client/tools/map_editor/editor_tools.gd` (a ferramenta e o grupo)
  - `client/tools/map_editor/map_editor.gd` (o painel, o modo de pegar, o aviso ao salvar)
  - `client/tools/map_editor/editor_canvas.gd` (as marcas da cena)
  - `client/core/autoload/story.gd` (`replace_scene(scene: StoryScene)`, `remove_scene(slug: String)`, `used_marks() -> Array[String]`)
  - `client/screens/exploration/exploration_screen.gd` (o `story_test` no `setup` e no `_begin`)
- **Reutilizar:** o `NpcPanel` como modelo de painel, o modo de escolher hexágonos do passeio do NPC e o `ConfirmationDialog` do editor.

## Verificação

- `godot --headless --path client --quit-after 30`.
- F5 com o servidor: criar pelo F2 a cena do primeiro critério, salvar, testar, conferir o arquivo no `git diff` e tocá-la de verdade na ilha.

## Tarefas

- [x] A ferramenta, o ícone e o `ScenePanel` com a lista, Nova cena e Apagar.
- [x] Os campos da cena, o gatilho e os atores.
- [x] O `SceneSteps`: a árvore, os botões e os campos de cada tipo.
- [x] "Escolher no mapa" e as marcas no canvas.
- [x] Salvar, o aviso de hexágono e o Testar daqui.
- [x] `client/CLAUDE.md`, o README e as tabelas das specs.

Notas da implementação:

- Trocar de ilha com mudanças na cena não pergunta: as mudanças se perdem, e a mensagem do topo avisa ("As mudanças da cena X foram descartadas."). Trocar de cena na lista pergunta.
- Os Marcos do teste começam com os `requires` da cena e se editam num campo de texto, separados por vírgula.
- As marcas no mapa: a área e os atores com o contorno, o ator com o primeiro quadro do sprite (meio transparente se começa escondido) e o destino do passo escolhido em verde (`UiPalette.HP_HIGH`), com a seta de onde o ator está até lá, contando os "Andar" de antes.
- Ao salvar, os números inteiros voltam a ser inteiros (`ScenePanel.clean`), porque o JSON do Godot lê todo número como float.

Conferido por Claude, sem janela: os scripts compilam, o `SceneSteps` monta a árvore de uma cena de exemplo, e o `clean` devolve os inteiros. Fica para o dono: todo o uso no F2 (criar, editar, escolher no mapa, salvar, apagar e o Testar daqui).

# 06. A linha do tempo das cenas

- **Status:** concluída
- **Depende de:** [04](04-scenes-tool.md)

## Contexto

A ferramenta Cenas da [04](04-scenes-tool.md) empilha tudo no painel lateral do F2, que tem 430 px de largura: a lista de cenas, os campos da cena, o gatilho, os atores, a árvore de passos, os campos do passo e os botões de salvar e testar. O dono achou o painel apertado, com rolagem demais e as informações mal organizadas. Entre três desenhos (painel com abas, linha do tempo embaixo do mapa e janela grande), ele escolheu a **linha do tempo embaixo do mapa** e, para os ramos, as **faixas juntas**.

## Abordagens consideradas

| Abordagem | Troca | Escolha |
| --- | --- | --- |
| Painel com abas (Cena, Atores, Passos, Testar) | A menor mudança, mas as falas longas continuam num espaço estreito | descartada pelo dono |
| **Linha do tempo embaixo do mapa** | Os passos ganham uma faixa larga e o mapa fica sempre à vista para escolher hexágonos; os ramos precisam de um jeito próprio | **escolhida pelo dono** |
| Janela grande só de cenas | O maior espaço e o jeito de roteiro, mas esconde o mapa | descartada pelo dono |

Para os ramos, as **faixas juntas** (abrir a escolha mostra todas as opções, uma faixa por opção) ganharam de **uma opção por vez** (botões para trocar), porque deixam comparar as respostas lado a lado.

## Escopo

- A faixa de passos embaixo do mapa do F2, com os cartões.
- A vista dos ramos: abrir uma escolha ou um "se tiver o Marco" mostra uma faixa por ramo, com o caminho no topo e o Voltar.
- O painel lateral reorganizado: o topo fixo, os campos do passo escolhido e as seções dobráveis da cena.
- Os ícones e as cores de cada tipo de passo.
- O teclado na faixa.

## Fora do escopo

- Arrastar cartões para mudar a ordem (fica com os botões e o teclado).
- Desfazer e refazer nas cenas.
- Tocar a cena dentro do editor (o Testar daqui continua abrindo Explorar).
- Mudar o formato do arquivo da cena, a Linha da história ou o jogo.

## Requisitos

### A faixa

- **RF-01:** Com a ferramenta Cenas e uma cena aberta, aparece a `SceneTimeline` (`client/tools/map_editor/scene_timeline.gd`, `class_name SceneTimeline`) embaixo do mapa, na largura dele. O mapa encolhe para dar lugar a ela. Com outra ferramenta, ou sem cena, ela some.
- **RF-02:** Na vista principal, a faixa tem uma linha com os passos da cena em cartões, da esquerda para a direita, e no fim o cartão "+". A faixa tem 150 px de altura e rola para os lados quando os cartões passam da largura (a roda do mouse rola para os lados).
- **RF-03:** Cada cartão tem 150 px de largura e mostra o número do passo, o ícone do tipo num quadrado da cor do tipo, o nome do tipo e um resumo de até 3 linhas: a fala com quem fala ("Avô: Ei! Já estava imaginando..."), o destino ("Avô → (12, −3)"), o Marco, os segundos, a tela. O cartão escolhido tem o contorno de destaque (`UiPalette.ACCENT`). Tocar num cartão o escolhe.
- **RF-04:** O cartão "+" abre o menu dos 15 tipos, agrupados por cor, e põe o passo novo no fim da faixa dele, já escolhido. Com um cartão escolhido, o painel lateral tem "+ depois deste", que põe o passo logo depois dele.
- **RF-05:** O cartão de uma escolha diz quantas opções tem, e o de um "se tiver o Marco" diz o Marco. Os dois têm o botão "Abrir ramos".

### Os ramos

- **RF-06:** "Abrir ramos" troca a faixa pela vista dos ramos: no topo, o caminho ("Cena › Escolha (passo 4)") e o "← Voltar"; embaixo, uma faixa por opção (ou duas, Então e Senão), cada uma começando por uma etiqueta com o nome do ramo (o texto da opção) e seguida dos cartões dos passos dele e do "+".
- **RF-07:** Na vista dos ramos, a faixa cresce até caber os ramos (uns 74 px por ramo, até 4 ramos e o topo, perto de 340 px). Numa escolha com menos de 4 opções, há o botão "+ Opção" ao lado do Voltar.
- **RF-08:** Tocar na etiqueta de uma opção a escolhe, e o painel lateral mostra o texto dela para editar e o "Apagar opção" (mínimo de 2).
- **RF-09:** Uma escolha dentro de um ramo também tem "Abrir ramos", e o caminho cresce ("Cena › Escolha (passo 4) › Opção 2 › Escolha (passo 1)"). Tocar num pedaço do caminho volta àquele nível.

### O painel lateral

- **RF-10:** O topo do painel fica sempre à vista, sem rolar: a lista das cenas da ilha, Nova cena e Apagar; e Salvar, Descartar e Testar daqui, com a frase do motivo quando o Testar está desligado.
- **RF-11:** Logo abaixo, a seção do passo escolhido ("Passo 3 · Fala"), com os mesmos campos da [04](04-scenes-tool.md) e os botões "+ depois deste", "← Mover", "Mover →" e Apagar. A fala tem uma caixa de texto de 120 px de altura, com a contagem até 300.
- **RF-12:** Embaixo, três seções dobráveis (`FoldableContainer`): Cena (nome, Repetível, Prioridade, os Marcos que precisa e que não pode ter, e o gatilho), Atores e Teste (os Marcos do teste). Ao abrir uma cena sem passo escolhido, a seção Cena vem aberta e as outras fechadas; depois, cada uma fica como o dono deixou.

### Ícones, cores e teclado

- **RF-13:** Os tipos de passo se dividem em 6 grupos, cada um com uma cor em `UiPalette.STORY_STEP_COLORS` e os ícones brancos em `client/tools/map_editor/icons/story/<ícone>.svg`, tingidos como os outros do editor:

| Grupo | Tipos | Cor | Ícones |
| --- | --- | --- | --- |
| Conversa | `say` | roxo | `say` |
| Escolhas | `choice`, `if_mark` | vermelho | `choice`, `if_mark` |
| Marcos | `set_mark` | azul | `mark` |
| Atores | `show`, `hide`, `move`, `face`, `follow`, `unfollow` | verde | `show`, `hide`, `move`, `face`, `follow`, `unfollow` |
| Câmera e tela | `camera`, `camera_back`, `fade`, `wait` | laranja | `camera`, `camera_back`, `fade`, `wait` |
| Telas | `open_screen` | cinza-azulado | `screen` |

  As cores e os desenhos dos ícones são _a revisar_.
- **RF-14:** Com o foco na faixa (depois de tocar num cartão) e fora de um campo de texto: ← e → escolhem o cartão do lado, Delete apaga o escolhido, Ctrl+← e Ctrl+→ o movem, Enter abre os ramos de uma escolha e Esc volta um nível dos ramos (ou desiste do "Escolher no mapa", como hoje).
- **RF-15:** As marcas no mapa ([04](04-scenes-tool.md#o-mapa)) continuam iguais, pelo passo escolhido na faixa.

## Critérios de aceite

- [ ] Com a cena "Exemplo: o guardião chega" aberta, os 10 passos aparecem em cartões embaixo do mapa, e o painel lateral não precisa rolar para mostrar o topo e o passo escolhido.
- [x] Abrir os ramos da escolha do "Exemplo: conversa com o Ruvo" mostra as 2 opções em faixas, com os passos de cada uma, e o Voltar retorna.
- [x] Pôr um passo pelo "+" de uma opção o põe só naquela opção.
- [ ] ← → e Delete funcionam na faixa e não mexem em nada enquanto um campo de texto tem o foco.
- [x] Salvar grava o mesmo arquivo de antes: o `git diff` das cenas de exemplo, abertas e salvas sem mudança, fica vazio.
- [x] `godot --headless -d --path client --quit-after 60` roda sem erro nem aviso nos arquivos tocados.

## Desenho técnico

- **Criar:**
  - `client/tools/map_editor/scene_timeline.gd` (a faixa, os cartões, a vista dos ramos e o teclado)
  - `client/tools/map_editor/icons/story/*.svg` (os 15 ícones)
- **Alterar:**
  - `client/tools/map_editor/scene_panel.gd` (o topo fixo, a seção do passo e as dobráveis; o painel deixa de ter a árvore)
  - `client/tools/map_editor/scene_steps.gd` (perde a árvore e os botões, que vão para a faixa; fica com os campos do passo escolhido e as regras de pôr, apagar e mover, que a faixa chama)
  - `client/tools/map_editor/map_editor.gd` (a faixa embaixo do `_canvas`, mostrada pela ferramenta e pela cena aberta)
  - `client/ui/theme/palette.gd` (`STORY_STEP_COLORS`)
- **Reutilizar:** o `StoryValidator.each_step`, o `ScenePanel.map_marks`, o `header_button` do editor para os ícones e o `EditorTools.section_title`.

## Verificação

- `godot --headless -d --path client --quit-after 60`.
- F5 pelo Godot, com o F2: abrir as duas cenas de exemplo, abrir os ramos, pôr, mover e apagar passos, salvar sem mudança e conferir o `git diff`, e o Testar daqui.

## Tarefas

- [x] `STORY_STEP_COLORS` e os ícones.
- [x] O `SceneSteps` sem a árvore, com as regras de pôr, apagar e mover por lista.
- [x] A `SceneTimeline`: a faixa principal, os cartões e o "+".
- [x] A vista dos ramos, com o caminho, as etiquetas e o "+ Opção".
- [x] O painel lateral: o topo fixo, a seção do passo e as dobráveis.
- [x] A faixa no `MapEditor` e o teclado.
- [x] `client/CLAUDE.md`, o README e as tabelas das specs.

Notas da implementação:

- O topo do painel (a lista, Nova cena, Apagar, Salvar, Descartar e Testar daqui) fica no começo da ferramenta, mas o painel inteiro do editor ainda rola junto: com as seções dobradas, cabe sem rolar.
- O `SceneSteps` ficou com o passo escolhido (`chosen`), os campos e as regras (`add_step`, `add_after`, `delete_chosen`, `move_chosen`, `add_option`, `delete_option`) e com os nomes, os grupos, os ícones e os resumos (`type_group`, `type_color`, `type_icon`, `summary`, `fill_type_menu`), que a `SceneTimeline` usa. Ele avisa a faixa por `structure_changed` (monta de novo), `selection_changed` (troca o contorno) e `changed` (troca o texto dos cartões).
- Nos ramos, o resumo do cartão tem 1 linha, para caber a altura da faixa; na faixa principal, 3. Um duplo clique num cartão de escolha também abre os ramos.
- O "Então" mostra o Marco ("Então (tem sabe_da_mira)"). As etiquetas do Então e do Senão não têm o que editar e ficam desligadas.
- Um ramo aberto que deixa de existir (a escolha apagada ou movida para outro ramo) fecha até o nível que ainda existe.

Conferido por Claude, numa cena temporária sem janela: as duas cenas de exemplo, salvas sem mudança, dão o mesmo texto do arquivo; o painel abre a cena e a faixa mostra os cartões (4 na conversa, 10 na chegada); abrir os ramos da escolha mostra as opções, pôr um passo pelo "+" da opção 2 o põe só nela, o "+ Opção" chega a 3 opções, e →, Ctrl+→, Esc e Delete fazem o que o RF-14 diz. O jogo abre sem aviso de script nos arquivos tocados. Fica para o dono: ver a faixa e o painel com janela no F2, o tamanho dos cartões, as cores e os ícones, e a rolagem da faixa.

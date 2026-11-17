# 05. A Linha da história

- **Status:** concluída
- **Depende de:** [04](04-scenes-tool.md)

## Contexto

Com muitas cenas, missões paralelas e escolhas, fica difícil saber pela lista de cada ilha o que vem depois do quê. Esta fase cria a vista que mostra todas as cenas ligadas pelos Marcos e avisa dos buracos ([architecture](architecture.md#o-editor-a-linha-da-história)).

## Escopo

- A janela Linha da história, aberta pela barra de cima do F2.
- O cálculo das ligações, das colunas e dos avisos, num arquivo sem tela.
- Abrir a cena no editor a partir da caixa.

## Fora do escopo

- Editar pela vista (arrastar caixas, ligar setas).
- Guardar a posição das caixas.

## Requisitos

- **RF-01:** `StoryGraph` (`client/core/story/story_graph.gd`, `class_name StoryGraph`, `RefCounted`, sem nó) recebe as cenas (`static func build(scenes: Array[StoryScene]) -> StoryGraph`) e tem:
  - `func setters(mark: String) -> Array[String]`: as cenas que ligam o Marco (a própria cena não repetível pelo `slug`, e toda cena com um `set_mark` dele em qualquer bloco);
  - `var edges: Array[Vector2i]`: de cada cena que liga um Marco para cada cena que o exige (índices em `scenes`);
  - `var columns: Array[int]`: a coluna de cada cena, 0 para as que não exigem nada, e 1 a mais que a maior coluna das cenas que ligam os Marcos que ela exige; numa cena dentro de um ciclo, a coluna fica 0;
  - `var warnings: Array[String]`: "Ninguém liga o Marco <m>, que a cena <name> exige."; "A cena <name> exige e proíbe o Marco <m>."; "As cenas <a>, <b> e <c> esperam uma pela outra em ciclo." (um aviso por ciclo, com os nomes na ordem do ciclo, separados por vírgula e o último por " e "); e "A cena <name> proíbe o próprio Marco." quando um não repetível tem o próprio `slug` em `forbids`.
- **RF-02:** A barra de cima do F2 ganha "Linha da história", que abre a `StoryLineView` (`client/tools/map_editor/story_line_view.gd`) por cima do editor, com "Fechar".
- **RF-03:** A vista desenha uma caixa por cena (o `name`, o nome da ilha embaixo, em letra menor, e a cor de fundo por ilha, entre as cores de destaque do editor), em colunas da esquerda para a direita pelo `columns`, e dentro da coluna em ordem de ilha e `slug`. As setas vão da borda direita da caixa que liga o Marco à borda esquerda da que o exige; passar o mouse numa seta mostra os Marcos dela. As cenas repetíveis têm a borda tracejada.
- **RF-04:** A vista se arrasta com o botão do meio ou o esquerdo no fundo, e a roda faz zoom de 0,5 a 2 vezes.
- **RF-05:** Os avisos ficam numa coluna à direita, com "Tudo certo." quando não há nenhum; tocar num aviso destaca as caixas dele.
- **RF-06:** Tocar numa caixa fecha a vista, abre no editor a ilha da cena (perguntando antes, se a ilha aberta tem mudanças não salvas, como a lista de ilhas já faz) e escolhe a cena na ferramenta Cenas.

## Critérios de aceite

- [x] Com as cenas de exemplo, `exemplo_chegada` aparece à direita de `exemplo_conversa`, com uma seta entre elas.
- [x] Uma cena que exige um Marco que ninguém liga aparece na coluna certa e gera o aviso.
- [x] Duas cenas que exigem uma a outra geram o aviso de ciclo.
- [ ] Tocar numa caixa abre a cena na ferramenta Cenas, na ilha dela.
- [x] Os avisos e as colunas do `StoryGraph` foram conferidos pela cena temporária em `client/zz_tmp_check/`, apagada depois.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Criar:** `client/core/story/story_graph.gd`, `client/tools/map_editor/story_line_view.gd`
- **Alterar:** `client/tools/map_editor/map_editor.gd` (o botão e abrir a cena pela caixa), `client/tools/map_editor/scene_panel.gd` (`select_scene(slug: String)`)
- **Reutilizar:** o `StoryValidator` para achar os `set_mark` dentro dos blocos (a mesma descida pelos passos) e o tema do editor.

## Verificação

- `godot --headless --path client --quit-after 30` e a cena temporária do `StoryGraph`, com uma lista de cenas montada no código que tem um Marco sem quem ligue, um ciclo de 2 e um de 3.
- F5: abrir a Linha da história com os exemplos e com 2 cenas erradas criadas pelo F2 (e apagadas depois).

## Tarefas

- [x] `StoryGraph`, conferido pela cena temporária.
- [x] A `StoryLineView`: caixas, setas, arrasto e zoom.
- [x] Os avisos e abrir a cena pela caixa.
- [x] `client/CLAUDE.md`, o README, as tabelas das specs e o status da iniciativa.

Conferido por Claude, numa cena temporária: o `StoryGraph` de uma lista com um Marco sem dono, um ciclo de 2 e um de 3 deu as colunas `[0, 1, 2, 0, 0, 0, 0, 0]` e os 3 avisos, e o das cenas de exemplo pôs o `exemplo_chegada` na coluna 1, com a seta a partir do `exemplo_conversa`. A vista abre sem erro. Fica para o dono: ver a vista no F2, o arrasto, o zoom, os avisos destacando as caixas e abrir uma cena pela caixa.

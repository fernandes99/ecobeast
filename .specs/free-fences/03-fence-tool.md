# 03. A ferramenta Cerca

- **Status:** concluída (falta o dono usar no F2)
- **Depende de:** [01](01-wall-records.md) e [02](02-wall-blocking.md)

## Contexto

As paredes já estão no banco, desenhadas ([01](01-wall-records.md)), e bloqueiam ([02](02-wall-blocking.md)). Falta o dono desenhá-las no editor, como no [architecture.md](architecture.md#a-ferramenta-cerca-fase-3).

## Escopo

- A ferramenta Cerca, no grupo Peças, com o painel dos 3 tipos de parede.
- Desenhar ponto a ponto, escolher, trocar o tipo e apagar, com desfazer.
- O redesenho só das paredes que mudaram (o pendente da revisão da [01](01-wall-records.md#resultado-da-verificação)).

## Fora do escopo

- Mover um ponto de uma parede feita ou emendar duas.
- Paredes nos carimbos.

## Requisitos

- **RF-01:** `EditorTools.Tool.FENCE` ("Cerca", ícone `fence.svg`) entra no fim do grupo Peças. O painel `FencePanel` mostra os tipos de `wall_types`, na ordem do catálogo.
- **RF-02:** com a ferramenta Cerca e nada sendo desenhado:
  - um clique a até `FENCE_PICK` (6 px da arte) de uma parede a escolhe;
  - com uma escolhida, um clique longe de todas solta a escolha;
  - sem escolha, um clique num hexágono editável começa uma parede, com o tipo do painel.
- **RF-03:** desenhando:
  - cada clique num hexágono editável põe um ponto, até 128;
  - um ponto fora dos hexágonos editáveis não entra;
  - a prévia liga o último ponto ao mouse.
  - **Terminar:** clicar a até `FENCE_PICK` do último ponto, o botão direito ou Enter. A parede entra no rascunho se tiver 2 pontos ou mais, e cada parede terminada é um passo do desfazer.
  - **Desistir:** Esc tira a parede em desenho.
- **RF-04:** com uma parede escolhida:
  - um tipo no painel troca o tipo dela;
  - Delete apaga;
  - Esc solta.
  - Cada mudança é um passo do desfazer. A escolhida aparece realçada.
- **RF-05:** o desfazer e o refazer guardam as paredes como lista inteira (`walls_before` e `walls_after` no `EditorHistory.Step`), como os traços.
- **RF-06:**
  - **Redesenho:** o `HexMapView.set_walls` monta de novo só os pedaços das paredes de `changed` e reaproveita os guardados das outras (revisto: tirar só os pedaços das paredes mudadas falhava, porque o editor manda cópias delas).
  - **Comparação:** o `EditorCanvas.refresh_walls` compara as listas por um dicionário, e não com `Array.has`.

## Critérios de aceite

- [x] Desenhar uma cerca de 4 pontos, terminar com Enter, desfazer e refazer.
- [x] Escolher a cerca com um clique, trocar para pedra e apagar com Delete, cada um com desfazer.
- [x] Clique fora da ilha não põe ponto; Esc desiste da cerca em desenho.
- [ ] Salvar e abrir de novo traz as cercas iguais.

## Desenho técnico

- `tools/map_editor/editor_tools.gd`:
  - `Tool.FENCE`, o painel e a seção;
  - `fence_click(draft, flat, secondary)`, `finish_fence(draft)`, `cancel_fence()` e `drawing_fence()`.
- `tools/map_editor/fence_panel.gd` (novo): os tipos, a escolha, trocar o tipo, apagar e o sinal `edited(step)`.
- `tools/map_editor/editor_history.gd`: `walls_before` e `walls_after`.
- `tools/map_editor/map_editor.gd`: o clique da ferramenta, Enter, Esc e Delete, o desfazer e o refresh.
- `tools/map_editor/editor_canvas.gd`:
  - a prévia e a parede escolhida;
  - o `refresh_walls` com dicionário.
- `ui/components/hex_map_view.gd`: o `set_walls` incremental.
- `tools/map_editor/icons/fence.svg` (novo).

## Verificação

- Uma cena temporária sem janela, que falha antes e passa depois. Ela confere:
  - desenhar com cliques (o ponto fora da ilha não entra, terminar no último ponto, o botão direito, Enter);
  - escolher, trocar o tipo e apagar;
  - desfazer e refazer pelo `EditorHistory`;
  - o `set_walls` incremental, que dá os mesmos pedaços de montar do zero.
- O jogo sem janela abre sem erros de script e sem avisos.
- **Com o dono:** a ferramenta no editor aberto (F2).

## Tarefas

- [x] O `EditorHistory` e o `FencePanel`.
- [x] A ferramenta no `EditorTools` e no `MapEditor`.
- [x] A prévia e a escolha no `EditorCanvas`.
- [x] O redesenho só do que mudou.
- [x] Testes e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela** (`zz_tmp_check/fence_tool_check`, apagado): 18 de 18. Ele falhou antes, sem a `Tool.FENCE`. Confere:
  - desenhar (o ponto fora da ilha não entra, terminar no último ponto, o botão direito, Enter com um ponto só, Esc);
  - escolher, trocar o tipo, soltar e apagar;
  - desfazer e refazer;
  - os pedaços do `set_walls` iguais aos de montar do zero;
  - os casos da revisão (abaixo).
- **Revisão final.** Corrigido:
  - **A última parede apagada,** ou desfeita, continuava desenhada. O teste "apagar a última parede tira os pedaços" falhou antes e passou depois.
  - **A parede escolhida** continuava realçada em outra ferramenta. Agora a troca de ferramenta solta a escolha.
  - **Arrastar com a Cerca** começava uma pincelada que copiava as peças do rascunho a cada arraste.
  - **A prévia** ligava o primeiro ponto a uma posição velha do mouse até ele se mexer.
- **Ficou anotado, sem mudar:**
  - não dá para começar uma cerca a menos de 6 px de outra (o clique escolhe a outra);
  - o `FENCE_PICK` é em pixels da arte, qualquer que seja o zoom;
  - trocar o tipo no meio do desenho só vale para a próxima.
- **O servidor da porta 3100** continua com erro 500 no catálogo até ser reiniciado. Os testes rodaram num servidor separado, na porta 3101, desligado no fim.
- **Não conferido:** a ferramenta com o editor aberto (F2), por exemplo se o Enter chega antes de um botão com foco.

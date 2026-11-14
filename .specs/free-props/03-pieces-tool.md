# 03. A ferramenta Peças no editor

- **Status:** concluída (falta o dono usar no editor)
- **Depende de:** [01](01-prop-records.md) e [02](02-props-in-game.md)

## Contexto

Desde a [02](02-props-in-game.md), o jogo desenha as peças soltas, mas o editor ainda não as põe. A ferramenta Objeto ([island-villages/03](../island-villages/03-map-objects.md), [map-editor/05](../map-editor/05-editor-ux.md)) põe objetos de grade: escolhe o tipo, a variante e o espelho num painel, põe com o clique esquerdo, escolhe um posto com o direito, e a barra embaixo do escolhido troca a variante, espelha, edita o bloqueio e apaga. O [README](README.md) decidiu uma ferramenta só para os dois, com uma paleta única.

## Escopo

- A ferramenta Objeto vira **Peças**, com os tipos de objeto e os de peça solta na mesma paleta.
- Pôr, escolher, mover, trocar a variante, espelhar e apagar uma peça solta, com desfazer.
- As peças no rascunho, salvas e lidas do servidor.

## Fora do escopo

- Os carimbos (fase 4) e o pincel.
- Escolher várias peças de uma vez.

## Requisitos

- **RF-01:** A ferramenta 7 se chama "Peças". O painel tem os tipos em duas listas: "Na grade (bloqueiam)", os objetos de hoje, e "Soltas (só enfeite)", os de `prop_types`, cada um com o ícone da variante 1.
- **RF-02:** Com um tipo solto escolhido, o clique esquerdo põe a peça com o pé no ponto do clique, na variante e no espelho do painel, e a deixa escolhida. Ela pode ficar em cima de outra peça ou de um objeto. Com um tipo de grade, o clique faz o que fazia.
- **RF-03:** O clique direito escolhe a peça solta cuja arte está sob o ponteiro (a da frente, se houver mais de uma) ou, sem nenhuma, o objeto do hexágono, como antes.
- **RF-04:** Com uma peça solta escolhida, arrastar com o botão esquerdo a partir da arte dela a move: o pé segue o ponteiro, em pixels inteiros da arte, sem sair de um hexágono da ilha. O movimento inteiro é um passo de desfazer.
- **RF-05:** A variante (← → e os números), o espelho (M), apagar (Delete) e voltar à peça nova (Esc), no painel, na barra embaixo da escolhida e no teclado, valem para a peça solta como para o objeto. A peça solta não tem o botão de bloqueio.
- **RF-06:** A peça escolhida tem um contorno no mapa, em volta da arte.
- **RF-07:** O rascunho guarda as peças (`props`), manda ao salvar e lê ao abrir. Tirar um hexágono tira as peças com o pé nele. Mudar a altura de um hexágono leva as peças dele junto.
- **RF-08:** Todo passo com peças desfaz e refaz.

## Critérios de aceite

- [x] Pôr uma flor, um banco e uma árvore em pontos diferentes do mesmo hexágono; salvar, fechar e abrir de novo: estão lá.
- [x] Escolher a do meio com o botão direito, arrastá-la, trocar a variante e espelhá-la; Ctrl+Z desfaz cada passo.
- [x] Apagar uma peça e tirar o hexágono de outra.
- [ ] O dono monta um pedaço de vila no editor e vê a ilha com F5.

## Desenho técnico

**Criar:** `client/ui/components/prop_art.gd` (`class_name PropArt`): o ícone de um tipo e variante e o retângulo da arte em volta do pé, para o editor (o ícone e a escolha) e o contorno.

**Alterar:**

- `tools/map_editor/island_draft.gd`: `props`, a leitura, o `to_dict`, o `remove_tile`, `map_props()` e `prop_at(point)`.
- `tools/map_editor/editor_history.gd`: `props_before` e `props_after`.
- `tools/map_editor/object_panel.gd`: as duas listas de tipos, a peça solta nova e a escolhida, e os passos com as peças.
- `tools/map_editor/editor_tools.gd`: o nome "Peças", pôr e escolher pelo ponto do ponteiro, e o arrastar.
- `tools/map_editor/editor_canvas.gd`: o ponto do ponteiro no chão plano, o sinal do arrastar, `refresh_props` e o contorno.
- `tools/map_editor/map_editor.gd` e `object_bar.gd`: os sinais, o refazer das peças e a barra embaixo da peça.
- `ui/components/hex_map_view.gd`: o `set_props` só indexa as peças; quem muda depois refaz os hexágonos com `update_tiles`.

## Verificação

- Um teste sem janela do rascunho e das ferramentas: pôr, escolher, mover, variante, espelho, apagar, desfazer e refazer; o `to_dict` com as peças; e tirar um hexágono.
- Um print com janela do mapa do editor com peças e a escolhida contornada.
- Salvar e ler de volta pelo servidor local.
- O jogo sem janela abre sem erros de script.

## Tarefas

- [x] Spec.
- [x] O rascunho e o desfazer.
- [x] O painel e a ferramenta.
- [x] O mapa do editor.
- [x] Testes, print e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Teste sem janela** (uma cena temporária, já apagada, contra o servidor novo numa porta à parte): falhou antes (sem as peças no rascunho nem na ferramenta) e passou depois, com 17 de 17. A ferramenta se chama Peças; pôs flores com o pé em (5, −3) do centro e um banco, que ficou escolhido; o botão direito escolheu as flores, e não o banco; arrastar levou as flores para outro hexágono, mantendo a distância do ponteiro ao pé, e não as levou para fora da ilha; a variante, o espelho e o apagar mudaram a peça, e o Ctrl+Z desfez cada passo, até o arrastar, e o Ctrl+Y o refez; o `to_dict` e o `from_dict` levaram as peças; e tirar um hexágono tirou a peça dele.
- **Print com janela e servidor:** o mapa do editor, numa cena temporária com o painel e o mapa, com 9 peças (árvore, arbusto, flores, pinheiro e pedra num degrau de altura 3, banco, poste e canteiro) e o banco escolhido, com o contorno. A mesma ilha foi criada no servidor local, lida de volta com as 9 peças iguais e apagada. No primeiro print, o contorno do banco era bem mais largo que ele, porque as imagens das decorações de rua tinham 64 pixels de largura com bordas vazias: o `make_town.gd` passou a cortar as bordas dos lados também, com o pé no meio.
- **Projeto:** o jogo sem janela, com o depurador, abre sem erros de script e com os mesmos 9 avisos de antes. Na primeira tentativa, um `step` repetido na mesma função do painel dava 1 aviso novo, corrigido.
- **Falta o dono:** montar um pedaço de vila no editor (F2) e ver a ilha com F5.

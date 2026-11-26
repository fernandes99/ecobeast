# 05. O editor de roupas (F6)

- **Status:** concluída (falta o dono conferir no F6)
- **Depende de:** [04](04-pants-run.md)

## Contexto

Em 2026-11-24, o dono pediu "uma tela que eu editaria pixel a pixel no spritesheet das animações e salvaria cada item", dentro do Godot. Hoje as folhas do Domador (`assets/tamer/bodies/<slug>/` e `assets/tamer/parts/<slug>/`) saem do `make_wardrobe.gd`, e a edição à mão só sobrevive pela lista `HAND_DRAWN` do script. O dono aprovou o desenho abaixo.

## Escopo

- Uma ferramenta de desenvolvimento, o `WardrobeEditor`, aberta pelo F6 com o jogo rodando pelo editor do Godot, como o F1 e o F2.
- Editar pixel a pixel as folhas de adulto dos corpos e das peças, com o desfazer, a guia do corpo, a prévia animada com a cor de uma paleta e o salvar.
- A lista das peças editadas à mão num arquivo, que o editor escreve e o `make_wardrobe.gd` lê.

## Fora do escopo

- As folhas da criança (`child/`): o dono pediu as peças novas só no adulto.
- Balde de tinta e criar peça nova (a peça nasce no catálogo e no `make_wardrobe.gd`).
- O jogo aberto mostrar a mudança sem o Godot reimportar o PNG.

## Requisitos

- **RF-01:** O F6, só com a tag `editor` (`OS.has_feature("editor")`), abre e fecha o `WardrobeEditor`, uma janela do sistema de 1280×720 (como o `ContentViewer`).
- **RF-02:** A coluna da esquerda lista os corpos de adulto (`body_types` sem `adult_body_type_id`) e as peças de `appearance_parts`, pelo nome, agrupadas pelo lugar. Embaixo, a animação (Parado, `idle`; Correndo, `run`) e a folha (Frente; Atrás, `_back`; Curta, `_short`), só as que existem na pasta.
- **RF-03:** No meio, o quadro escolhido ampliado (8 a 20 vezes, em pixels inteiros, cabendo no espaço), com a grade de pixels. Por baixo, apagadas, as guias que se ligam: o corpo escolhido (o mesmo quadro da folha do corpo, a 35%) e o quadro anterior da mesma linha (a 25%). Numa folha de corpo, a guia é o quadro anterior.
- **RF-04:** As ferramentas: Lápis (botão esquerdo pinta, arrastando), Borracha (apaga; o botão direito também apaga com qualquer ferramenta) e Conta-gotas (pega a cor do pixel e volta ao Lápis). As cores: os 4 cinzas-chave, o contorno `#2f2522` e as outras cores que a folha já tem (a pele e a cueca do corpo, a bochecha do rosto). Ctrl+Z desfaz e Ctrl+Y refaz, por pincelada, até 100 passos por folha.
- **RF-05:** Embaixo, as miniaturas da folha: 5 linhas (Frente, Diagonal de baixo, Lado, Diagonal de cima e Costas) e as colunas dos quadros (4 no Parado e 6 no Correndo). Tocar numa escolhe o quadro; as setas ← → e ↑ ↓ andam entre quadros e linhas.
- **RF-06:** À direita, a prévia: o corpo e a peça montados, na linha escolhida, animando no ritmo do jogo (`TamerSprite.IDLE_SECONDS` e `RUN_SECONDS`), ampliados 4 vezes, com a cor de uma paleta do tipo do lugar (`appearance_slots.palette_kind`; o corpo usa `skin`) trocada pelo `palette_swap.gdshader`.
- **RF-07:** Salvar (e Ctrl+S) grava os PNGs mexidos por cima dos de `res://assets/tamer/`, põe a peça ou o corpo em `assets/tamer/hand_drawn.json` (`{"bodies": [...], "parts": [...]}`, por slug) e mostra "Salvo. Volte à janela do Godot para ele reimportar." Trocar de peça, de folha ou fechar com mudança não salva pergunta antes ("Salvar", "Descartar", "Cancelar").
- **RF-08:** O `make_wardrobe.gd` lê o `hand_drawn.json` no lugar da lista `HAND_DRAWN` e não grava os corpos e as peças dele (adulto e criança). O arquivo nasce com a Calça (`"parts": ["pants"]`).
- **RF-09:** Zoom: a roda do mouse aproxima e afasta o quadro em degraus inteiros (de 4 a 48 vezes), mantendo o pixel debaixo do mouse no lugar; o botão do meio arrasta a vista, e Ajustar (ou 0) volta ao maior zoom que cabe. Pedido do dono em 2026-11-24, depois da primeira versão.
- **RF-10:** O tamanho do pincel, de 1 a 8 pixels (um quadrado com o mouse no meio), muda segurando Ctrl e girando a roda (ou com [ e ]) e vale para o Lápis, a Borracha e o botão direito; o contorno do pincel aparece debaixo do mouse, e o rodapé mostra o zoom e o pincel.
- **RF-11:** A ferramenta Seleção (S) marca um retângulo do quadro arrastando. Ctrl+C copia, Ctrl+X recorta, Ctrl+V cola no mesmo lugar de onde copiou, em qualquer quadro, folha ou peça, e Ctrl+A seleciona o quadro inteiro. Arrastar por dentro da seleção, ou as setas, movem os pixels soltos; Enter, Esc, um clique sem arrastar ou trocar de ferramenta os assentam. Delete apaga o que está dentro. Colar e mover só põem os pixels opacos, e cada colar ou mover é um passo só do desfazer.

## Critérios de aceite

- [ ] O F6 abre o editor com o jogo rodando pelo Godot, e o jogo exportado não tem o editor.
- [ ] Pintar, apagar, desfazer e refazer mexem no quadro e nas miniaturas.
- [ ] Salvar a Calça grava `parts/pants/run.png`, e o `make_wardrobe.gd` depois não a muda.
- [ ] Salvar uma peça que não estava na lista a põe no `hand_drawn.json`.
- [ ] A prévia anima a peça com a cor escolhida.
- [ ] A roda aproxima e afasta, o Ctrl+roda muda o pincel, e copiar e colar uma seleção leva os pixels a outro quadro.

## Desenho técnico

- `client/tools/wardrobe_editor/`: `wardrobe_editor.gd` (`WardrobeEditor`, a janela e a ligação das partes), `wardrobe_sheet.gd` (`WardrobeSheet`, a folha aberta: a imagem, os pixels, o desfazer e o salvar, sem nó), `wardrobe_canvas.gd` (`WardrobeCanvas`, o quadro ampliado e o pincel), `wardrobe_frames.gd` (`WardrobeFrames`, as miniaturas) e `wardrobe_preview.gd` (`WardrobePreview`, a prévia animada).
- `client/assets/tamer/hand_drawn.json` e `client/assets/tamer/make_wardrobe.gd`.
- `client/screens/main/main.gd`: o F6.
- As folhas se leem com `Image.load_from_file` pelo caminho global, e não pelo `load()`, para mostrar o que acabou de ser salvo.

## Notas da implementação

- Os rótulos do Lápis, da Borracha e do Conta-gotas são curtos, com o atalho na dica, e as chaves das guias (Corpo e Quadro anterior) ficam na coluna da direita, embaixo do Corpo guia, para a janela caber em 1280×720 com os botões do tema.
- A prévia ganhou a escolha da Pele (as paletas `skin`), além da Cor da peça e do Corpo guia: sem ela, o corpo apareceria nos cinzas-chave.
- O quadro ampliado tem o fundo xadrez azulado, para os cinzas-chave não sumirem nele.
- Além das cores da folha, a Cor do lápis abre um seletor de cor livre.
- Trocar de folha pergunta antes, como trocar de peça, e só a folha aberta fica com mudança; o Salvar grava ela.
- O F6 com a janela do editor em foco também a fecha (perguntando antes, com mudança).

## Verificação

Uma cena temporária em `client/zz_tmp_check` (apagada no fim) abre uma cópia de uma folha no `WardrobeSheet`, pinta, desfaz, refaz e salva, e confere os pixels; outra abre o `WardrobeEditor` e confere que a lista tem os corpos e as peças. E o `make_wardrobe.gd` rodado com uma peça no `hand_drawn.json` não muda os arquivos dela.

Manual (F5 e F6): os critérios de aceite.

## Tarefas

- [x] O `hand_drawn.json` no `make_wardrobe.gd`.
- [x] O `WardrobeSheet`.
- [x] O quadro, as miniaturas e a prévia.
- [x] A janela, o F6 e o salvar.
- [x] As specs e o `CLAUDE.md`.

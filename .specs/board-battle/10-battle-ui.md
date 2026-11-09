# 10. O visual da tela da luta, desenhado pelo Godot

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [08](08-board-ground.md) e [09](09-hit-feedback.md)

## Contexto

Na [08](08-board-ground.md), o dono tirou o visual da folha de assets da [06](06-board-look.md), e a tela da luta ficou com o tema padrão do jogo. Em 2026-11-06, ele testou o kit de pixel art "Ornate Retro UI" na tela e não gostou ("Ficou ruim. Desfaz tudo"); a tentativa foi desfeita sem deixar arquivos. Em seguida, mandou um print de referência (cartões e log azul-escuros com borda azul, botões azuis com relevo e ícone, o "?" num quadrado, o balão de conversa no log) e uma imagem com ícones, e pediu os painéis e botões feitos só no código, "sem imagens, talvez dos ícones", "de uma maneira organizada".

A imagem de ícones tem 9 ícones com fundo transparente. A bola de captura repete o desenho de outra franquia, o que as regras do projeto proíbem, e fica de fora: a Mochila usa a bolsa. Passar, que no print era um saquinho, usa o ícone de avançar. A engrenagem não tem uso na luta.

## Escopo

- Um tema da luta, num arquivo só, com as cores, as medidas e os estilos de cada peça.
- Os cartões, o log, os botões de ação, as Técnicas, o "?", o Voltar e o botão de sair com esse tema.
- Os ícones de Atacar, Passar, Mochila, Fugir, do "?" e do log, recortados da imagem do dono.

## Fora do escopo

- As outras telas e os painéis que vêm da luta antiga (Mochila, troca, subir de nível, Técnica nova, Evolução, captura e histórico).
- O nome de quem age em outra cor no log, como no print: pede texto com cores no meio da frase.
- O ícone do Elemento dentro da pílula do Elemento.

## Requisitos

- **RF-01:** Os dois cartões são painéis azul-escuros, com cantos arredondados, borda azul e uma sombra suave. O nível fica numa pílula escura com borda.
- **RF-02:** Atacar, Passar, Mochila e Fugir são botões azuis com cantos arredondados, borda azul-clara e relevo (uma borda mais escura embaixo), com o ícone em cima e o nome embaixo, em branco com contorno escuro. Apertado, o botão fica mais escuro e mais baixo. Desativado, apaga. O último botão tocado ganha um anel laranja com brilho. As Técnicas, a Técnica de emergência, Voltar e o botão de sair usam o mesmo botão, sem ícone.
- **RF-03:** O "?" é um botão quadrado com o ícone de interrogação. Na [13](13-log-opens-history.md), o dono tirou o "?": tocar no log abre o histórico.
- **RF-04:** O log é um painel de uma linha com o balão de conversa à esquerda. Quando uma frase termina de aparecer letra por letra, um triângulo à direita avisa que a luta continua; os avisos da vez do jogador aparecem sem ele.
- **RF-05:** Nada disso usa imagem de moldura: só os ícones são imagens. O tabuleiro continua parado ([08](08-board-ground.md)).

## Critérios de aceite

- [ ] Com F5, a luta tem os cartões, o log e os botões como no print do dono, com os ícones nos 4 botões e no "?".
- [ ] A frase do log termina com o triângulo; um aviso aparece sem ele.
- [ ] Atacar abre as Técnicas no mesmo estilo, e o tabuleiro não muda de lugar.
- [ ] As telas fora da luta não mudam.

## Desenho técnico

- **`BattleTheme`** (`res://ui/theme/battle_theme.gd`) cria, uma vez, um `Theme` só com *variações*: `BattlePanel` e `BattleLog` (de `PanelContainer`), `BattlePill` (de `PanelContainer`), `BattleButton` e `BattleIconButton` (de `Button`). Cores e medidas são constantes no topo do arquivo. Os estilos são `StyleBoxFlat`: o relevo do botão é a sombra deslocada para baixo, e o anel laranja é o estilo de foco. `icon(nome)` carrega um ícone, e `action_button(botão, ícone)` monta um botão de ação.
- **A tela** põe o tema na raiz e diz a variação de cada controle. Como o tema só cria variações, quem não pede uma continua com o tema do jogo: os painéis da luta antiga não mudam. O `BattleSkillButton` e o `HpBar`, que duplicam o estilo como `StyleBoxFlat`, continuam funcionando.
- **O log** virou uma linha com `ChatIcon`, `Message` e `MoreIcon` na cena. Todo aviso passa por `_show_message`, que mostra o texto inteiro e esconde o triângulo; a frase letra por letra o mostra no fim.
- **Ícones:** `art-source/ui/battle_icons.png` é a imagem do dono, e `art-source/ui/battle_icons.py` recorta `attack`, `pass`, `bag`, `flee`, `help`, `chat` e `more` em `client/assets/ui/battle/icons/`. Eles não são pixel art: o Godot os reduz com filtro suave.

## Verificação

- O projeto importa sem erros; a checagem de carga, o teste do tabuleiro, o do tabuleiro parado e o do golpe seguem passando.
- Prints com janela da luta com os botões e com as Técnicas abertas.

## Tarefas

- [x] Spec.
- [x] Os ícones recortados.
- [x] O `BattleTheme`.
- [x] A tela, o cartão e o log com o tema.
- [ ] O dono ver com F5.

## Resultado da verificação

Em 2026-11-06, sem janela, o projeto importou sem erros, e a checagem de carga, o teste do tabuleiro, o do tabuleiro parado e o do golpe deram 0 falhas.

Com janela, prints da luta de teste mostraram os cartões e o log azul-escuros com borda azul, a pílula do nível, o "?" com ícone e os botões com relevo, ícone e nome. Com os ícones em 52 e o texto em 26, os botões ficavam vazios perto do print; ficaram em 60 e 28. Com as Técnicas abertas, os botões delas seguem o mesmo estilo. Falta o dono ver no editor.

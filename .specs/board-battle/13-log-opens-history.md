# 13. O log abre o histórico, sem o "?"

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [10-battle-ui](10-battle-ui.md) (o log com o balão e o "?" com ícone)

## Contexto

Desde a [04](04-board-screen.md), um botão de informação no canto de cima, à direita, abre o histórico da luta. Na [08](08-board-ground.md) ele ficou sozinho no canto, como "?", e na [10](10-battle-ui.md) ganhou o ícone de interrogação. Na [09](09-hit-feedback.md), a luta ganhou o log de uma linha acima do cartão do jogador, com a última frase. Em 2026-11-07, o dono pediu: "pode remover o simbolo de '?' no topo direito. Ele faz abrir os logs, em vez disso vamos abrir quando o usuário clicar na barra de logs".

## Escopo

- Tirar o "?" do topo.
- Tocar no log abre o histórico.

## Fora do escopo

- Mudar o painel do histórico.
- Um sinal no log de que ele abre o histórico: o balão de conversa já fica nele.

## Requisitos

- **RF-01:** O topo da luta não tem mais o "?". O cartão do selvagem ocupa a largura toda, como o cartão do jogador embaixo.
- **RF-02:** Tocar (ou clicar) no log abre o histórico, a qualquer momento da luta, como o "?" fazia. O histórico abre quando o dedo sai do log, como um botão.
- **RF-03:** Em cima do log, o cursor do mouse vira a mãozinha de clicar.
- **RF-04:** O Voltar do Android e o Esc continuam fechando o histórico.

## Critérios de aceite

- [ ] Com F5, a luta não tem o "?" no topo, e tocar no log abre o histórico.

## Desenho técnico

**Alterar:**

- `res://screens/board_battle/board_battle_screen.tscn`: sai o `TopRight` com o `InfoButton`. O `LogBox` passa a receber o toque (`mouse_filter` em `STOP`) e ganha o cursor de mão; o balão, a frase e o triângulo continuam deixando o toque passar para ele.
- `res://screens/board_battle/board_battle_screen.gd`: o sinal `gui_input` do `LogBox` abre o histórico quando o botão esquerdo é solto. Sai o estilo do `InfoButton`.
- `res://ui/theme/battle_theme.gd`: sai a variação `BattleIconButton`, que só o "?" usava.

O ícone `help.png` fica em `res://assets/ui/battle/icons/`, porque o `art-source/ui/battle_icons.py` continua recortando todos os ícones da imagem do dono.

## Verificação

- Um teste sem janela, com uma luta montada, confere que o `InfoButton` não existe, que o histórico começa fechado e que um clique no log (apertar e soltar) o abre.
- Os testes da 09, 11 e 12 seguem dando 0 falhas.
- O jogo sem janela abre sem erros nem avisos de script.
- Manual, com F5: o dono toca no log.

## Tarefas

- [x] Teste do log, vendo falhar.
- [x] Tirar o "?" e ligar o toque no log.
- [x] Os testes da 09, 11 e 12.
- [ ] O dono ver com F5.

## Resultado da verificação

Em 2026-11-07, o teste sem janela, com uma luta montada, falhou antes do código (o `InfoButton` existia, e o log não recebia o toque nem tinha o cursor de mão) e passou depois: sem o `InfoButton`, o histórico começa fechado, não abre ao apertar o log e abre ao soltar. Os testes da 09 (Arranhão e som de dano), da 11 (Rugido Feroz) e da 12 (sinais) seguiram com 0 falhas. O jogo sem janela abriu sem erros nem avisos de script.

A tela não foi vista com janela: falta o dono ver com F5.

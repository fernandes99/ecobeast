# 01. Transição de zoom pixelado

- **Status:** rascunho
- **Depende de:** [architecture.md](architecture.md)

## Contexto

Hoje a luta abre de uma vez, sem transição:

- A tela de exploração (`res://screens/exploration/exploration_screen.gd`) chama `Router.push(&"board_battle", ...)` em `_search` (Procurar), em `_fight_challenger` (o toque no log do Domador) e nos botões de luta de teste do menu Debug.
- O Hub (`res://screens/hub/hub_screen.gd`) abre o Desafiar pelo `_open`, com o destino de `DESTINATIONS`.
- A tela da luta (`res://screens/board_battle/board_battle_screen.gd`) pede a luta em `_begin`, monta o tabuleiro (`_board.set_board`, `_fit_board`) e mostra a abertura (`_show_turn`). Com erro do servidor, ela mostra `_show_exit`.

## Escopo

- O autoload `BattleIntro` e o shader `pixel_zoom.gdshader`.
- A transição nas quatro entradas: Procurar, Domador do mapa, Desafiar e luta de teste.
- O revelar na tela da luta, com e sem erro.

## Fora do escopo

- A música: vem na [02](02-battle-music.md). Aqui, `cover` já recebe `opponent`, mas ainda não toca nada.
- A volta da luta e as outras telas.

## Requisitos

- **RF-01:** `BattleIntro` é um autoload de cena, registrado no `project.godot`, com o `CanvasLayer`, o `ColorRect` e o shader da [arquitetura](architecture.md#battleintro). Escondido, não pega toque nenhum.
- **RF-02:** `await BattleIntro.cover(focus, opponent)` mostra a camada e anima os clarões, o zoom pixelado no `focus` e o escurecer, com os tempos da arquitetura, e devolve `true`. No fim, a tela está preta e continua coberta. Durante e depois, os toques não passam para a tela de baixo. Com mais de 0,4 s de tela preta, aparece "Procurando..." no meio.
- **RF-03:** `BattleIntro.reveal()` anima o pixelado se desfazendo sobre a tela de agora, sem zoom e sem escuro, e esconde a camada no fim. Sem `cover` antes, não faz nada. Chamar `cover` com a transição já correndo não começa outra e devolve `false`, e quem chamou não abre a luta.
- **RF-04:** Procurar, o toque no log do Domador e os botões de teste do Debug fazem `await BattleIntro.cover(...)` antes de abrir a luta, com o foco no Domador do jogador. Procurar sem Ecobeast no hexágono não mostra transição.
- **RF-05:** o Desafiar do Hub faz `await BattleIntro.cover(...)` com o foco no centro da tela, antes de abrir a luta.
- **RF-06:** a tela da luta chama `BattleIntro.reveal()` depois de montar o tabuleiro e antes da abertura. Quando o servidor recusa a luta, ela chama o `reveal` antes de mostrar o erro.
- **RF-07:** o voltar do aparelho durante a transição e com a tela coberta não faz nada: o `Router.back` confere `BattleIntro.is_covering()`.
- **RF-08:** o `Router` emite `screen_changed(id)` a cada troca de tela. Coberto, o `BattleIntro` revela sozinho quando a tela nova não é a `board_battle`.

## Critérios de aceite

- [ ] Procurar um selvagem mostra os dois clarões, o zoom pixelado no Domador e a tela preta, e a luta aparece desfazendo o pixelado.
- [ ] Tocar no log de um Domador do mapa e no Desafiar do Hub mostra a mesma transição.
- [ ] Os botões de teste do Debug mostram a transição.
- [ ] Com a equipe toda sem HP, a transição termina e a luta mostra "Cure sua equipe no Refúgio.".
- [ ] Tocar na tela ou no voltar durante a transição não faz nada.
- [ ] Com o servidor lento, a tela preta mostra "Procurando...".
- [ ] A volta da luta para o mapa e para o Hub continua como antes.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos:

- `res://core/autoload/battle_intro.gd` e `.tscn`: `BattleIntro`, com os tempos em constantes e as animações num `Tween` sobre os parâmetros do shader.
- `res://ui/components/pixel_zoom.gdshader`.

Arquivos alterados:

- `project.godot`: o autoload `BattleIntro`.
- `res://core/autoload/router.gd`: o sinal `screen_changed` e o voltar travado com a tela coberta.
- `res://screens/exploration/exploration_screen.gd`: o `cover` antes das três aberturas, com o foco na posição do Domador do jogador na janela.
- `res://screens/hub/hub_screen.gd`: o `cover` antes do Desafiar.
- `res://screens/board_battle/board_battle_screen.gd`: o `reveal`.
- `client/CLAUDE.md`: uma linha sobre o `BattleIntro`.

## Verificação

```bash
cd server && npm run start:dev
godot --headless -d --path client --quit-after 60
```

No editor (F5), em 360×640, com `ENABLE_TEST_BATTLE` ligada no servidor:

- Procurar um selvagem, tocar no log de um Domador do mapa, usar o Desafiar e um botão de teste do Debug, e conferir a transição nos quatro.
- Com a equipe sem HP, conferir que a tela não fica preta.

## Tarefas

- [ ] O shader e o autoload.
- [ ] A transição nas entradas do mapa e do Hub.
- [ ] O revelar na tela da luta.
- [ ] Atualizar o `client/CLAUDE.md`, rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.

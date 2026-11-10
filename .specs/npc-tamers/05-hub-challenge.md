# 05. Desafiar no Hub

- **Status:** concluída
- **Depende de:** [04-map-tamers](04-map-tamers.md), [architecture.md](architecture.md)

## Contexto

O Hub (`res://screens/hub/hub_screen.gd`) já tem o card "Desafiar" ("Enfrente outros Domadores."), que hoje abre a tela placeholder pelo `DESTINATIONS`. O servidor já tem `POST /v1/me/board-battle/challenge` ([03](03-tamer-api.md)), e a tela da luta já sabe lutar contra Domador ([04](04-map-tamers.md)).

## Escopo

- O card Desafiar abre a luta contra um Domador sorteado.

## Fora do escopo

- Escolher o Domador, ver a equipe dele antes ou uma tela de lista de desafiantes.
- Desafiar outro jogador.
- Limitar quantas vezes se desafia por dia.

## Requisitos

- **RF-01:** tocar em Desafiar abre a tela `board_battle` com `challenge: true`, sem tela no meio.
- **RF-02:** com `challenge`, a tela chama `Session.start_board_challenge()` (`POST /v1/me/board-battle/challenge`) e usa o chão padrão do tabuleiro (`BoardView.DEFAULT_BIOME` e `DEFAULT_SHAPE`, a planície).
- **RF-03:** do lado do jogador, entram os primeiros Ecobeasts de pé da equipe, na ordem dela, até o tamanho da luta. Quando um cai e há reserva de pé, o jogador escolhe quem entra e em qual hexágono, no painel de hoje (`choose_next`). É o que o tabuleiro já faz.
- **RF-04:** a luta é como a do Domador do mapa: sem Fugir, sem Esferas, com o nome dele no log.
- **RF-05:** vencendo ou perdendo, a saída volta ao Hub com o `Router.back()` de hoje, que relê o jogador. O botão diz "Voltar".
- **RF-06:** uma recusa do servidor (equipe sem HP, nenhum desafiante) aparece na tela da luta, como as recusas de hoje, e a saída volta ao Hub.

## Critérios de aceite

- [x] Tocar em Desafiar abre uma luta de 1×1, 2×2 ou 3×3 contra um Domador com nome, no chão da planície.
- [x] Numa luta 3×3, entram os 3 primeiros Ecobeasts de pé da equipe, e quando um deles cai o jogador escolhe quem da reserva entra.
- [x] Vencer e perder voltam ao Hub com as moedas atualizadas no topo.
- [x] Com a equipe toda sem HP, aparece "Cure sua equipe no Refúgio." e a saída volta ao Hub.
- [x] Desafiar não mexe numa exploração aberta: o Hub não tem mapa, e a próxima entrada em Explorar zona gera outro, como hoje.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

- `res://screens/hub/hub_screen.gd`: `DESTINATIONS["Desafiar"]` passa a ser `{"id": &"board_battle", "params": {"challenge": true}}`.
- `res://core/services/game_service.gd` e `api_game_service.gd`: `start_board_challenge`.
- `res://core/autoload/session.gd`: `start_board_challenge`.
- `res://screens/board_battle/board_battle_screen.gd`: `challenge` no `setup` e no `_begin`.
- `TELAS.md`: a linha do Hub cita que Desafiar enfrenta um Domador sorteado.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

No editor (F5), em 360×640:

- Desafiar algumas vezes até ver os três tamanhos.
- Vencer e perder, conferindo as moedas no Hub.
- Com a equipe sem HP, conferir a mensagem e a volta.

Conferido em 2026-11-09: o projeto abre sem erro de script, e os avisos com `-d` são todos de arquivos que esta fase não tocou. Uma cena temporária, que já foi apagada, compilou o Hub, a tela da luta, o `Session` e o `ApiGameService`, conferiu que o card Desafiar abre a `board_battle` com `challenge` e que o `setup` usa o chão padrão. A rota do servidor tem os e2e da [03](03-tamer-api.md). O dono jogou as lutas no editor e aprovou em 2026-11-09.

## Tarefas

- [x] Serviço e `Session`.
- [x] `challenge` na tela da luta.
- [x] O card do Hub.
- [x] Atualizar o `TELAS.md`, rodar a verificação, dizer o que ficou para o dono e mudar o status aqui, no README da iniciativa e no roadmap.

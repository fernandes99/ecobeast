# 03. O rosto nas outras telas

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02-face-component](02-face-component.md)

## Contexto

As decisões estão no [README](README.md). Esta fase troca o corpo inteiro encolhido pelo `CreatureFace` nos outros lugares pequenos.

## Escopo

- `client/screens/board_battle/turn_queue_bar.gd` e `next_creature_row.*`.
- `client/screens/team/team_row.*`.
- `client/screens/heal_station/heal_creature_row.*`.
- `client/screens/bag/bag_target_row.*`.
- `client/screens/storage/storage_cell.*`.
- `client/screens/codex/codex_cell.*`.

## Requisitos

- **RF-01:** Com o anel de HP (`set_creature`): a troca na luta (`NextCreatureRow`), as linhas da tela Ecobeasts (`TeamRow`), do Refúgio (`HealCreatureRow`) e da Mochila (`BagTargetRow`) e a grade do Santuário (`StorageCell`).
- **RF-02:** Sem o anel (`set_species`):
  - a fila de vez da luta (`TurnQueueBar`), que recebe só a espécie e o lado de cada um; a borda da cor do lado (o do jogador, o inimigo e o da vez) continua em volta do rosto;
  - a grade do Bestiário (`CodexCell`), com a sombra para a espécie só vista e o "???" de hoje para a nunca vista.
- **RF-03:** Cada lugar mantém o tamanho que o retrato tem hoje, e a barra de HP que já houver ao lado continua.
- **RF-04:** Onde o corpo inteiro tem espaço, ele continua: o detalhe do Ecobeast, a escolha do inicial, o painel de ações do Santuário (`CreatureActionsPanel`), o registro no Bestiário, o detalhe do Bestiário, a captura, a Evolução e a subida de nível.

## Fora do escopo

- O Ecobeast no tabuleiro da luta e no mapa, que usam as folhas animadas.

## Critérios de aceite

- [x] Cada tela do RF-01 mostra o rosto com o anel de HP certo (o Santuário não foi visto: a conta de teste não tinha Ecobeast guardado).
- [x] O Bestiário mostra o rosto, a sombra e o "???" como antes.
- [x] As telas do RF-04 continuam com o corpo inteiro.
- [x] O jogo sem janela abre sem erro de script.

## Verificação

```bash
godot --headless -d --path client --quit-after 240
```

Depois, no jogo, cada tela do RF-01 e do RF-02.

## Tarefas

- [x] A luta: a fila de vez e a troca.
- [x] As listas: Ecobeasts, Refúgio e Mochila.
- [x] As grades: Santuário e Bestiário.
- [x] Atualizar o `CLAUDE.md` do cliente e o `TELAS.md`.
- [x] A verificação.

# 02. O nível do Domador no jogo

- **Status:** aprovada
- **Depende de:** [01](01-tamer-xp-server.md)

## Contexto

Depois da [01](01-tamer-xp-server.md), o servidor dá XP ao Domador e manda dois dados:

- o `tamer_progress` na resposta do turno que termina a luta;
- o `xp`, o `level_xp` e o `next_level_xp` no `/v1/me`.

Esta fase mostra isso no jogo.

Hoje:

- A Home (`res://screens/hub/hub_screen.gd`) tem o selo do nível (`%LevelLabel`) e a barra `%XpBar`, que fica sempre em 0 por causa da linha `_xp_bar.value = 0.0`.
- O Perfil (`res://screens/profile/profile_screen.gd`) mostra "Nível N" em `_refresh_player`.
- No fim da luta (`res://screens/board_battle/board_battle_screen.gd`, ramo `"ended"`), o `_celebrate(turn.progression)` enche a barra de cada Ecobeast e toca o `level_up_overlay` quando ele sobe de nível.
- O modelo `res://domain/models/player.gd` lê o `level`. O turno é lido em `res://domain/models/board_turn.gd`.

## Escopo

- Ler o XP do Domador no `Player` e o `tamer_progress` no `BoardTurn`.
- A barra da Home cheia na proporção certa.
- O XP no Perfil.
- No fim da luta, a linha "+N XP de Domador" no histórico e, quando o Domador sobe, o aviso de nível novo com as recompensas.

## Fora do escopo

- Animar a barra da Home enchendo: ela só mostra o valor atual ao abrir e quando o jogador muda.
- A árvore de melhorias.
- Mudar o servidor.

## Requisitos

- **RF-01:** `Player` ganha `xp`, `level_xp` e `next_level_xp`. Quando o servidor não manda o `next_level_xp`, ele fica em −1, que quer dizer "nível máximo".
- **RF-02:** um modelo novo, `TamerProgress` (`res://domain/models/tamer_progress.gd`), lê o `tamer_progress` com os níveis subidos e as recompensas. O `BoardTurn.tamer_progress` fica nulo quando a resposta não traz o dado.
- **RF-03:** a barra da Home mostra `(xp − level_xp) / (next_level_xp − level_xp)`, e fica cheia no nível máximo. O comentário "O Domador ainda não sobe de nível" sai.
- **RF-04:** o Perfil mostra, embaixo do nível, "1.240 / 2.000 XP" (o XP dentro do nível e o tamanho do nível, com o ponto de milhar) ou "Nível máximo".
- **RF-05:** no fim da luta, depois do `_celebrate` dos Ecobeasts, quando o `tamer_progress` vem, o histórico ganha a linha "+N XP de Domador".
- **RF-06:** quando `levels` não está vazio, toca o aviso de nível novo, um só mesmo que o Domador tenha subido vários níveis.
  - O aviso mostra "Domador nível N!" com o nível final.
  - Embaixo, a soma das moedas de todos os níveis subidos.
  - E cada item com o ícone (`ItemIcon`) e a quantidade, somando as quantidades do mesmo item.
  - Ele fecha com um toque, como o `level_up_overlay`.
- **RF-07:** depois do aviso, o `Session` atualiza o jogador (as moedas e a Mochila vêm do servidor), e a Home mostra o nível e a barra novos ao voltar.

## Critérios de aceite

- [ ] Um jogador novo vê a barra da Home vazia e "0 / 41 XP" no Perfil.
- [ ] Vencer um selvagem acrescenta "+N XP de Domador" ao histórico, e a barra da Home está maior ao voltar.
- [ ] Subir do nível 4 ao 6 numa luta mostra um aviso só, "Domador nível 6!", com 100 + 110 = 210 moedas e 3 Esferas de Vínculo.
- [ ] Capturar uma espécie que já estava no Bestiário não mostra nem a linha nem o aviso.
- [ ] No nível máximo, a barra fica cheia e o Perfil diz "Nível máximo".
- [ ] O projeto abre no editor sem erros nem avisos de script.

## Desenho técnico

- `res://domain/models/player.gd`: `xp`, `level_xp` e `next_level_xp` pelo `DictFields`, mais `func level_ratio() -> float`.
- `res://domain/models/tamer_progress.gd` (`class_name TamerProgress`, `extends RefCounted`):
  - campos `xp_gained`, `level_before`, `level_after` e `levels: Array[Dictionary]`;
  - `static func from_dict(d: Dictionary) -> TamerProgress`;
  - `func reward_coins() -> int`;
  - `func reward_items() -> Dictionary` (o id do item e a quantidade somada).
- `res://domain/models/board_turn.gd`: `var tamer_progress: TamerProgress`, nulo sem o dado.
- `res://screens/hub/hub_screen.gd`: o `_refresh` põe `_xp_bar.value = player.level_ratio()`, na escala de 0 a 1 da barra (conferir o `max_value` dela no `.tscn`).
- `res://screens/profile/profile_screen.gd`: um rótulo novo embaixo de `%LevelLabel` na `.tscn`.
- `res://screens/board_battle/tamer_level_overlay.gd` e `.tscn`, no molde do `level_up_overlay`: `func play(progress: TamerProgress) -> void`, que espera o toque. Ele entra na `board_battle_screen.tscn` ao lado dos outros avisos.
- `board_battle_screen.gd`, no ramo `"ended"`, depois do `await _celebrate(turn.progression)`:
  - a linha "+N XP de Domador" no `_history`;
  - o `await _tamer_level_overlay.play(...)` quando há níveis subidos;
  - a atualização do jogador pelo mesmo caminho que a tela já usa para as moedas no fim da luta.

Os textos novos ("+%d XP de Domador", "Domador nível %d!", "Nível máximo") ficam em pt-BR, direto no script, como o resto do jogo.

## Verificação

- `godot --headless --path client --quit-after 30` com o servidor no ar, sem erro de script.
- No editor (F5), com o servidor da [01](01-tamer-xp-server.md):
  - um jogador novo vê a barra vazia e o Perfil com "0 / 41 XP";
  - vencer um selvagem mostra a linha no histórico;
  - capturar uma espécie nova sobe o Domador do 1 ao 3 (100 XP), com um aviso só de 70 + 80 moedas;
  - a Home mostra o nível 3 ao voltar.
- O nível máximo e a subida de 4 para 6 com o item: quem implementa monta pelo banco local (o `players.xp` à mão) e diz que fez. O dono confere no celular.

## Tarefas

- [ ] `Player` e `TamerProgress`; `BoardTurn.tamer_progress`.
- [ ] A barra da Home e o rótulo do Perfil.
- [ ] O `tamer_level_overlay` e a ligação no fim da luta, com a linha do histórico e a atualização do jogador.
- [ ] Os passos manuais da verificação; status desta fase, do README, do `.specs/README.md` e do roadmap.

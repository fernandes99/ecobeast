# 02. Vagas no cliente

- **Status:** cancelada (a iniciativa foi substituída pela luta no tabuleiro, ver o [README](README.md))
- **Depende de:** [01-engine-slots](01-engine-slots.md), [battle-screen/02](../battle-screen/02-battle-client.md)

## Contexto

Depois da [01](01-engine-slots.md), o servidor fala o contrato novo, mas o jogo ainda lê o antigo: `active_index`, `enemy.active`, uma ação por chamada e eventos sem `position`. Esta fase troca o jogo para o contrato novo e tira o antigo do servidor. A tela continua a da [battle-screen/03](../battle-screen/03-battle-screen.md), só com a vaga 0: o visual novo e as vagas na tela vêm na [03](03-battle-scene.md).

## Escopo

- Modelos da batalha com vagas.
- `Session` e `GameService` mandando a lista de ações.
- `BattleNarrator` e `BattleDisplay` por lado e posição.
- A tela de hoje lendo os modelos novos, ainda 1 contra 1.
- Tirar o contrato antigo do servidor.

## Fora do escopo

- O visual novo, a escolha do alvo e a ação por vaga na tela (vêm na [03](03-battle-scene.md)).

## Requisitos

- **RF-01:** `BattleView` troca `active_index` e `enemy` por:
  - `active_indices: Array[int]`, com -1 numa vaga vazia;
  - `pending_positions: Array[int]`;
  - `enemies: Array[BattleCreature]`, com null numa vaga vazia.

  Ele ganha `active(position: int) -> BattleCreature` e `enemy_at(position: int) -> BattleCreature`.
- **RF-02:** `Session.battle_action(actions: Array[Dictionary])` e `GameService.battle_action` mandam `{"actions": actions}`.
- **RF-03:** `BattleDisplay` guarda, por lado, uma criatura por posição, e aplica cada evento no lado e na `position` dele. `creature_entered` usa o `team_index` do evento para achar quem entra no `BattleView` final. `creature_left` esvazia a vaga.
- **RF-04:** `BattleNarrator.set_side_name(side, position, name)` guarda um nome por lado e posição. Cada linha usa o nome de quem está na `position` do evento.
- **RF-05:** O `coins_gained` usa o nome da espécie do `species_id`. O `coins_lost` junta os nomes de `species_ids` com vírgula e "e": "Você perdeu 🪙 4 para Ruvo e Nilu.".
- **RF-06:** A captura mostra o destino pelo `captured_to` do `capture_attempted`, logo depois da linha dele, e não pelo `captured_to` da raiz.
- **RF-07:** A tela de hoje manda cada ação com `"position": 0`, e cada troca do `choose_next` com a primeira posição de `pending_positions`. Ela mostra a vaga 0 dos dois lados. Nada muda para o jogador.
- **RF-08:** O servidor tira `player.active_index`, `enemy.active` e o `captured_to` da raiz da resposta, e para de aceitar o corpo antigo, com "Mande a lista de ações.".

## Critérios de aceite

- [ ] Uma luta 1 contra 1 pelo mapa é igual à de antes, do começo ao fim: Técnicas, troca, item, Esfera, fuga, vitória com XP e moedas, e derrota.
- [ ] A captura mostra "entrou na equipe" ou "foi para o Santuário", como antes.
- [ ] Os testes do servidor passam, sem os campos antigos.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Alterar**, em `client/`:

- `domain/models/battle_view.gd` e `battle_turn.gd`: os campos novos, sem o `captured_to` da raiz.
- `core/services/game_service.gd`, `api_game_service.gd` e `core/autoload/session.gd`: `battle_action` com a lista.
- `screens/battle/battle_display.gd`: as criaturas por posição.
- `screens/battle/battle_narrator.gd`: os nomes por posição, as moedas e o destino da captura.
- `screens/battle/battle_screen.gd`: a vaga 0 e as ações com `position`.

**Alterar**, em `server/`: `src/battle/battle.mapper.ts`, `battle.dto.ts` e `battle.controller.ts`, sem o contrato antigo, com os e2e ajustados.

**Atualizar:** em `.specs/battle-screen/architecture.md`, a tabela de efeitos do `BattleDisplay` e a de textos, com `position` e o `creature_left` (sem linha).

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

Uma cena temporária, nos moldes da [battle-screen/03](../battle-screen/03-battle-screen.md), joga uma luta contra o servidor de teste e confere os critérios. Passo do dono: jogar uma luta pelo mapa no editor (F5).

## Tarefas

- [ ] Modelos e `Session` (RF-01 e RF-02).
- [ ] `BattleDisplay` e `BattleNarrator` (RF-03 a RF-06).
- [ ] A tela de hoje na vaga 0 (RF-07).
- [ ] Tirar o contrato antigo do servidor (RF-08).
- [ ] Rodar a verificação. Marcar a spec e o README como `concluída` e fazer o commit `feat: vagas no cliente da batalha`.

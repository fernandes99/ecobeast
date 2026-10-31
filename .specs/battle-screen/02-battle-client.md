# 02. Batalha no cliente

- **Status:** concluída
- **Depende de:** [01-wild-encounter](01-wild-encounter.md)

## Contexto

O servidor já responde com o estado e os eventos da batalha, mas o Godot não sabe chamá-lo nem ler a resposta. Esta fase cria essa parte, sem tela: as classes da batalha, as chamadas pelo `Session`, os textos de cada evento e o que eles mudam no que aparece na tela. A [03](03-battle-screen.md) só monta a interface em cima disso.

## Escopo

- Modelos `BattleView`, `BattleCreature` e `BattleTurn`.
- `start_wild_battle` e `battle_action` no `GameService`, no `ApiGameService` e no `Session`.
- `BattleNarrator` e `BattleDisplay`.
- Nomes de status e stats no `GameData`.

## Fora do escopo

- A tela e a ligação com o Hub.
- Regras: o cliente não calcula dano, ordem nem resultado.

## Requisitos

**Modelos**

- **RF-01:** `BattleView.from_dict` lê `phase`, `result`, `turn`, `can_flee`, `player.active_index`, `player.team`, `enemy.active`, `enemy.team_size` e `enemy.fainted`.
- **RF-02:** `BattleCreature.from_dict` lê `species_id`, `level`, `hp`, `max_hp`, `status`, `confused` e `stages`, e, se vierem, `uid` e `skills` (`Array[SkillSlot]`). `status` nulo vira texto vazio, e `result` nulo também.
- **RF-03:** `BattleTurn` guarda `view: BattleView` e `events: Array[Dictionary]`.

**Chamadas**

- **RF-04:** `start_wild_battle()` chama `POST /v1/me/battle/wild`, e `battle_action(action: Dictionary)`, `POST /v1/me/battle/action`. Com sucesso, `data` é um `BattleTurn`.
- **RF-05:** Em `battle_action`, o código `404` é sucesso com `data` nulo: a batalha expirou ou o servidor reiniciou, e a tela oferece a saída.
- **RF-06:** Uma resposta sem `battle` ou sem `events` é falha, com `ApiResponse.SERVER_ERROR`.
- **RF-07:** O `Session` só repassa as chamadas e não guarda a batalha. Quem a mostra é a tela, e o jogador é relido com `load_player` no fim dela.

**`BattleNarrator`**

- **RF-08:** `describe(event: Dictionary) -> String` devolve a linha da tabela de [architecture.md](architecture.md#o-texto-de-cada-evento), ou texto vazio quando o evento não tem linha.
- **RF-09:** O narrador recebe os nomes dos dois lados em `set_side_name(side: String, name: String)`. A tela os atualiza depois de `BattleDisplay.apply` e antes de `describe`, para a criatura que acabou de entrar já sair com o nome certo. Técnicas, status e stats vêm do `GameData`.
- **RF-10:** A linha de abertura vale até `begin_turns()`, que a tela chama depois de mostrar os eventos do começo da luta. Daí em diante, `creature_entered` usa `<nome> entrou na luta.`
- **RF-11:** Um evento de tipo desconhecido devolve texto vazio, sem erro. Um servidor mais novo não quebra o jogo.

**`BattleDisplay`**

- **RF-12:** `reset(view: BattleView)` copia o estado do servidor.
- **RF-13:** `apply(event: Dictionary, final_view: BattleView)` segue a tabela de [architecture.md](architecture.md#mostrar-um-turno). Em `creature_entered`, a criatura vem de `final_view`, porque o evento não traz o `uid` nem o HP.
- **RF-14:** Expõe `player` e `enemy` (`BattleCreature`), cópias próprias: `apply` não altera `final_view`.
- **RF-15:** Um evento sem efeito na tabela não muda nada.

**`GameData`**

- **RF-16:** `get_status_name(slug: String) -> String` e `get_stat_name(slug: String) -> String` devolvem o nome do catálogo, ou o próprio slug se ele não existir.

## Critérios de aceite

- [x] O JSON do exemplo em [battle-core/architecture.md](../battle-core/architecture.md#api) vira um `BattleView` com todos os campos.
- [x] `status` e `result` nulos viram texto vazio, e o inimigo fica sem `uid` e sem `skills`.
- [x] Contra o servidor real, `start_wild_battle` e `battle_action` devolvem um `BattleTurn`, e uma ação inválida devolve a mensagem do motor.
- [x] Sem batalha em andamento, `battle_action` devolve sucesso com `data` nulo.
- [x] Cada linha da tabela de textos é conferida, inclusive os prefixos de crítico e efetividade.
- [x] Um evento de tipo desconhecido devolve texto vazio.
- [x] `apply` muda o HP, o status, `confused` e os estágios de cada evento da tabela.
- [x] Depois de um `switch`, `apply` põe o `uid` certo no cartão do jogador.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/domain/models/battle_creature.gd`, `battle_view.gd` e `battle_turn.gd`.
- `client/screens/battle/battle_narrator.gd` (`class_name BattleNarrator`) e `battle_display.gd` (`class_name BattleDisplay`), ambos `RefCounted`. Ficam fora de `domain/` porque leem o `GameData`.

**Alterar**

- `client/core/services/game_service.gd` e `api_game_service.gd`: as duas chamadas.
- `client/core/autoload/session.gd`: os métodos que as repassam, com `@warning_ignore("redundant_await")`.
- `client/core/autoload/game_data.gd` e o catálogo por trás dele: os nomes.

**Reaproveitar**

`SkillSlot.from_dict`, `DictFields` e o `_player_result` como modelo de `_turn_result`.

## Verificação

Sem framework de testes no cliente, a conferência é uma cena temporária em `client/tmp_check/`, com os dados de `override.cfg` e um servidor de teste na porta 3198, removidos no fim. Ela confere cada critério e imprime o placar.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Cena de conferência dos modelos; ver falhar; implementar (RF-01 a RF-03).
- [x] Conferência contra o servidor; ver falhar; chamadas e `Session` (RF-04 a RF-07).
- [x] Conferência dos textos; ver falhar; `GameData` e `BattleNarrator` (RF-08 a RF-11, RF-16).
- [x] Conferência dos eventos; ver falhar; `BattleDisplay` (RF-12 a RF-15).
- [x] Remover os arquivos temporários; marcar esta spec e a tabela do README como `concluída`; commit `feat: batalha no cliente`.

## Decisões da implementação

- **`BattleCreature.copy()` e `BattleView.active()`:** a spec pedia cópias próprias no `BattleDisplay` e a criatura de `active_index`; os dois métodos evitam repetir isso na tela.
- **`creature_entered` lê os dois lados de `final_view`:** a criatura só entra depois de tudo o que aconteceu no turno, então a resposta já a traz como está.
- **Nomes por slug no `Catalog`:** `get_status_name` e `get_stat_name` percorrem a tabela, que tem poucas linhas, e devolvem o slug sem erro quando ele não existe.
- **Conferência:** uma cena temporária contra um servidor de teste na porta 3198 passou com 105 de 105 verificações, depois de falhar pela falta das classes. O jogo abriu sem erros nem avisos de script. Os arquivos temporários foram removidos.

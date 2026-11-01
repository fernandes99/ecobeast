# Arquitetura

O desenho comum às fases: o caminho de uma ação, a forma como a tela mostra um turno e o texto de cada evento. O estado, os eventos e a API da batalha estão em [battle-core/architecture.md](../battle-core/architecture.md).

## Peças

```
Hub ── Router.push(&"battle") ──> BattleScreen ──> Session ──> ApiGameService ──> NestJS
                                       │
                                       ├── BattleNarrator (evento → texto)
                                       └── BattleDisplay (evento → HP, status e estágios na tela)
```

- **`BattleTurn`**: o que uma chamada devolve, com o `BattleView` final e os eventos.
- **`BattleView`**: o JSON `battle` em classes tipadas. É sempre o estado do servidor.
- **`BattleNarrator`**: transforma um evento em uma linha em pt-BR. Não muda nada.
- **`BattleDisplay`**: aplica cada evento ao que a tela mostra. Só copia campos do evento; não calcula regra nenhuma.

## Mostrar um turno

A resposta do servidor já traz o turno inteiro. A tela o revela aos poucos:

1. O jogador age, e os botões ficam desativados.
2. Para cada evento, na ordem: o `BattleDisplay` o aplica, os cartões se redesenham, e o `BattleNarrator` escreve a linha, se houver.
3. Depois de cada linha, a tela espera `LINE_DELAY` (0,9 s, _a revisar_). Um evento sem linha não espera.
4. No fim da lista, o `BattleView` da resposta substitui tudo, e a tela segue `phase`.

| `phase`         | O que a tela faz                             |
| --------------- | -------------------------------------------- |
| `choose_action` | Reativa os botões                            |
| `choose_next`   | Abre o painel do próximo Ecobeast            |
| `ended`         | Troca os botões pelo resultado               |

Os eventos que mudam a tela:

| Evento                                                 | Efeito no `BattleDisplay`                                   |
| ------------------------------------------------------ | ----------------------------------------------------------- |
| `creature_entered`                                     | Põe a criatura ativa daquele lado no `BattleView` da resposta |
| `damage`, `recoil`, `healed`, `confused_hit`, `status_damage` | `hp` do lado                                         |
| `status_applied`                                       | `confusion` liga `confused`; `fear` e `trapped` não mudam nada; os outros viram o status do lado |
| `status_ended`                                         | `confusion` desliga `confused`                              |
| `woke_up`, `thawed`                                    | Limpa o status do lado                                      |
| `fainted`                                              | Limpa o status e `confused` do lado                         |
| `stat_changed`                                         | `stages[stat]` do lado recebe `value`                       |

Uma criatura só entra depois de tudo o que aconteceu no turno ([ordem de um turno](../battle-core/architecture.md#ordem-de-um-turno)), então o `BattleView` da resposta já a traz como está naquele momento. `creature_entered` a lê de lá porque o evento não tem o `uid` nem o HP.

## O texto de cada evento

`<nome>` é o nome de exibição de quem está daquele lado: o apelido ou a espécie, no jogador; a espécie, no inimigo. Todos os textos são _a revisar_.

| Evento             | Linha                                                                       |
| ------------------ | --------------------------------------------------------------------------- |
| `battle_started`   | nenhuma                                                                     |
| `creature_entered` | Inimigo, na abertura: `Um <espécie> selvagem apareceu!`. Jogador, na abertura: nenhuma. Depois: `<nome> entrou na luta.` |
| `skill_used`       | `<nome> usou <Técnica>.`; com `skill_id` nulo, `<nome> usou Golpe de Esforço.` |
| `cannot_act`       | `fear`: `<nome> ficou com medo e não agiu.` · `freeze`: `<nome> está congelado.` · `sleep`: `<nome> está dormindo.` · `paralysis`: `<nome> está paralisado e não agiu.` |
| `woke_up`          | `<nome> acordou.`                                                           |
| `thawed`           | `<nome> descongelou.`                                                       |
| `confused_hit`     | `<nome> está confuso e se atingiu: perdeu <n> de HP.`                       |
| `missed`           | `<nome> errou.`                                                             |
| `blocked`          | `<nome> se protegeu.`                                                       |
| `no_effect`        | `Não afetou <nome>.`                                                        |
| `effect_failed`    | `Não funcionou.`                                                            |
| `damage`           | Prefixos, nesta ordem: `Crítico!` e `Muito eficaz!` (multiplicador acima de 1) ou `Pouco eficaz.` (abaixo de 1). Depois, `<nome> perdeu <n> de HP.` |
| `recoil`           | `<nome> sofreu <n> de recuo.`                                               |
| `healed`           | `<nome> recuperou <n> de HP.`                                               |
| `status_applied`   | `<nome> ficou <status>.`                                                    |
| `status_damage`    | `<nome> perdeu <n> de HP: <status>.`                                        |
| `status_ended`     | `<nome> não está mais <status>.`                                            |
| `stat_changed`     | `<stat> de <nome> subiu.` ou `caiu.`; com 2 estágios ou mais, `subiu muito.` ou `caiu muito.` |
| `fainted`          | `<nome> desmaiou.`                                                          |
| `item_used`        | Com cura: `Você usou <item> em <nome>: +<n> de HP.` Só com status: `Você usou <item> em <nome>: não está mais <status>.` |
| `flee_failed`      | `Não conseguiu fugir!`                                                      |
| `battle_ended`     | nenhuma                                                                     |

`<status>` é o nome da tabela `status_conditions`, em minúsculas. `<stat>` é o nome da tabela `stats`. O slug que não estiver no catálogo aparece como veio.

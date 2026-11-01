# Arquitetura

O desenho comum às fases: as peças, o estado, a ordem de um turno, os eventos e a API.

## Peças

```
Godot ── POST /v1/me/battle/action ──> BattleController ──> BattleService
                                                              │        │
                                               BattleStore (memória)   │ no fim: grava HP, PP e status
                                                              │        ▼
                                                              ▼     PrismaService
                                       src/domain/battle/ (regras puras, sem Nest nem Prisma)
                                        rules · engine · ai
```

- **`src/domain/battle/`**: funções puras. Recebem o estado, o `BattleCatalog` e `random: () => number` (em `[0, 1)`), e não fazem I/O.
- **`src/battle/`**: o módulo Nest. Monta os combatentes a partir do banco, guarda a batalha e grava o fim.

## Estado

```ts
type BattlePhase = 'choose_action' | 'choose_next' | 'ended';
type BattleResult = 'victory' | 'defeat' | 'fled';

interface Combatant {
  creatureUid: string | null; // null no inimigo selvagem
  speciesId: number;
  elementIds: number[];
  level: number;
  traitSlug: string;
  stats: StatBlock; // calculados ao começar a luta
  currentHp: number;
  statusSlug: string | null; // burn, poison, paralysis, sleep, freeze
  sleepTurns: number;
  confusionTurns: number; // 0 = não está confuso
  isFeared: boolean;
  isTrapped: boolean;
  isProtected: boolean;
  stages: Record<'atk' | 'def' | 'sp_atk' | 'sp_def' | 'spd' | 'accuracy' | 'evasion', number>;
  skills: { skillId: number; currentPp: number }[];
}

interface BattleSide {
  team: Combatant[];
  activeIndex: number;
}

interface BattleState {
  phase: BattlePhase;
  result: BattleResult | null;
  turn: number;
  canFlee: boolean; // falso contra Domadores
  player: BattleSide;
  enemy: BattleSide;
  bag: { itemId: number; quantity: number; used: number }[]; // a Mochila, copiada ao começar
}
```

`BattleCatalog` traz o que as regras precisam: Técnicas com efeitos, `element_efficacy`, `status_condition_immunities` e o efeito dos itens.

## Ações do jogador

| `type`      | Campo         | Quando vale                                   |
| ----------- | ------------- | --------------------------------------------- |
| `skill`     | `slot` (1–4)  | `choose_action`, e a Técnica tem PP           |
| `emergency` | —             | `choose_action`, e nenhuma Técnica tem PP     |
| `flee`      | —             | `choose_action`, `canFlee`, e não está Preso  |
| `switch`    | `team_index`  | `choose_next`, e a criatura escolhida tem HP  |
| `item`      | `item_id`, `team_index` | `choose_action`, com o item na `bag` e efeito no alvo, que pode ser um reserva |
| `capture`   | `item_id`     | `choose_action`, com uma Esfera na `bag` e um inimigo com `capture_rate` acima de 0 ([capture](../capture/architecture.md#ação-e-eventos)) |

## Ordem de um turno

1. **Conferir** a ação; se não valer, nada muda.
2. **Fugir:** com sucesso (80%), a batalha termina com `fled`. Com falha, o inimigo age sozinho, e o turno segue para o passo 6.
3. **Escolher** a ação do inimigo (IA).
4. **Ordenar:** maior `priority`; depois, maior Velocidade efetiva; depois, sorteio. O golpe de emergência tem prioridade 0.
5. **Executar** cada ação, na ordem, se o autor seguir de pé e, numa Técnica mirada no adversário, se ele também seguir:
   1. Verificar se pode agir: Amedrontado, depois Congelado, Adormecido, Paralisado e Confuso.
   2. Gastar 1 PP. Quem não pôde agir não gasta.
   3. Técnica de autoproteção marca `isProtected`, e a ação termina.
   4. Alvo Protegido bloqueia a Técnica.
   5. Conferir a Precisão.
   6. Técnica com Poder: calcular e aplicar o dano; efetividade 0 não causa dano, e a ação termina.
   7. Aplicar efeitos na ordem de `sort_order`, sorteando a `chance` de cada um. Efeitos no alvo não valem se ele desmaiou.
   8. Quem chegar a 0 HP desmaia. Um desmaio limpa todo o status.
6. **Fim do turno:** Queimado e Envenenado perdem HP, na ordem em que as criaturas agiram; somem `isFeared` e `isProtected`.
7. **Conferir o fim:**
   - sem criaturas de pé no inimigo: `victory`, mesmo que o jogador também tenha caído;
   - sem criaturas de pé no jogador: `defeat`;
   - a batalha segue: `turn + 1`;
   - ativa do inimigo caída: entra a próxima de pé, e o Traço de entrada vale;
   - ativa do jogador caída: fase `choose_next`;
   - senão, `choose_action`.

A ação `item` gasta a rodada: o item faz efeito antes de qualquer ação do inimigo, seja qual for a Velocidade. Depois, o inimigo age sozinho, e o turno segue para o passo 6, como numa fuga que falhou. Os itens gastos só saem do banco no fim da luta ([inventory-shop](../inventory-shop/architecture.md#o-item-na-batalha)).

A ação `capture` gasta a Esfera e sorteia antes de qualquer ação do inimigo. Com sucesso, a luta termina em `captured`, sem fim de turno. Com falha, o inimigo age sozinho, como depois de um item.

Na fase `choose_next`, a ação `switch` põe a criatura em campo, e o Traço de entrada vale, sem gastar turno nem dar ação ao inimigo. No começo da luta, o Traço de entrada dos dois vale antes do turno 1, primeiro o do jogador.

## Eventos

A resposta traz a lista, na ordem em que aconteceu. Cada evento tem `type` e `side` (`player` ou `enemy`), quando se aplica: é quem sofre o evento e, em `missed`, quem errou.

| `type`            | Campos                                    |
| ----------------- | ----------------------------------------- |
| `battle_started`  | —                                         |
| `creature_entered` | `side`, `species_id`, `level`, `max_hp`   |
| `skill_used`      | `side`, `skill_id` (nulo no golpe de emergência) |
| `cannot_act`      | `side`, `reason` (`fear`, `freeze`, `sleep`, `paralysis`) |
| `woke_up`         | `side`                                    |
| `thawed`          | `side`                                    |
| `confused_hit`    | `side`, `damage`, `hp`                    |
| `missed`          | `side`                                    |
| `blocked`         | `side`                                    |
| `no_effect`       | `side`                                    |
| `effect_failed`   | `side`                                    |
| `damage`          | `side`, `damage`, `hp`, `multiplier`, `is_critical` |
| `recoil`          | `side`, `damage`, `hp`                    |
| `healed`          | `side`, `amount`, `hp`                    |
| `status_applied`  | `side`, `status`                          |
| `status_damage`   | `side`, `status`, `damage`, `hp`          |
| `status_ended`    | `side`, `status`                          |
| `stat_changed`    | `side`, `stat`, `stages`, `value`         |
| `fainted`         | `side`                                    |
| `item_used`       | `side`, `item_id`, `team_index`, `healed`, `hp`, `cured_status` |
| `capture_attempted` | `item_id`, `success`                    |
| `flee_failed`     | —                                         |
| `battle_ended`    | `result`                                  |

## API

Todas exigem a sessão. Erros em pt-BR.

| Rota                              | Corpo                                  | Sucesso                     | Falhas                                                                                                                                  |
| --------------------------------- | -------------------------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `POST /v1/me/battle`              | `{ "species_id": 1, "level": 5 }`      | `201 { "battle", "events" }` | `404` com `ENABLE_TEST_BATTLE` desligado · `400` "Esse inimigo não existe." · `409` "Crie seu Domador primeiro." · `409` "Cure sua equipe no Refúgio." |
| `POST /v1/me/battle/wild`         | —                                      | `201 { "battle", "events" }` | `409` "Crie seu Domador primeiro." · `409` "Cure sua equipe no Refúgio." ([battle-screen/01](../battle-screen/01-wild-encounter.md)) |
| `POST /v1/me/battle/action`       | uma ação da tabela acima               | `200 { "battle", "events", "captured_to" }` | `404` "Nenhuma batalha em andamento." · `400` com o motivo                                                                                |

`battle` é o que o jogador vê:

```json
{
  "phase": "choose_action",
  "result": null,
  "turn": 3,
  "can_flee": true,
  "player": {
    "active_index": 0,
    "team": [
      {
        "uid": "…", "species_id": 1, "level": 5, "hp": 14, "max_hp": 20, "status": "burn",
        "confused": false, "stages": { "atk": 1, "def": 0, "sp_atk": 0, "sp_def": 0, "spd": 0, "accuracy": 0, "evasion": 0 },
        "skills": [ { "skill_id": 1, "current_pp": 33 } ]
      }
    ]
  },
  "enemy": {
    "active": {
      "species_id": 7, "level": 4, "hp": 9, "max_hp": 18, "status": null,
      "confused": false, "stages": { "atk": 0, "def": -1, "sp_atk": 0, "sp_def": 0, "spd": 0, "accuracy": 0, "evasion": 0 }
    },
    "team_size": 1,
    "fainted": 0
  }
}
```

O jogador não vê as Técnicas nem o Traço do inimigo, nem o resto da equipe dele.

## Valores a revisar

Propostas do planejamento, todas _a revisar_:

| Regra                                  | Valor                                                                 |
| -------------------------------------- | --------------------------------------------------------------------- |
| Chance de crítico por estágio          | 0: 1/24; 1: 1/8; 2: 1/2; 3 ou mais: sempre                             |
| Golpe de emergência                    | "Golpe de Esforço": físico, Poder 30, sem Elemento, nunca erra         |
| Dano do golpe de emergência em si      | 1/8 do HP máximo                                                       |
| Golpe em si mesmo, se Confuso          | Físico, Poder 40, sem Elemento, sem crítico                            |
| Peso de uma Técnica de suporte na IA   | 20                                                                     |
| Preso                                  | Impede fugir                                                           |
| Proteger em turnos seguidos            | Sempre funciona; o limite é o PP                                       |

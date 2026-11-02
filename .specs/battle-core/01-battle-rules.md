# 01. Regras puras da batalha

- **Status:** concluída
- **Depende de:** [auth-google/02-player-rules](../auth-google/02-player-rules.md)

## Contexto

O motor do turno ([02](02-battle-engine.md)) precisa das contas do `GDD.md`: estágios, Precisão, crítico, dano e ordem. Esta fase as escreve como funções puras, em `server/src/domain/battle/`, com testes de valor. Nada aqui usa Nest, Prisma ou sorteio próprio: a fonte vem por parâmetro, como em `createCreature`.

## Escopo

- Tipos da batalha ([architecture.md](architecture.md#estado)).
- Multiplicador de estágio, chance de acerto, chance de crítico, dano e ordem das ações.

## Fora do escopo

- O turno, os status, os efeitos, a IA e a API.

## Requisitos

- **RF-01:** `stageMultiplier(stage)`: `(2 + n) / 2` para `n >= 0`; `2 / (2 - n)` para `n < 0`. Estágios ficam entre -6 e +6.
- **RF-02:** `effectiveStat(combatant, slug)`: o stat vezes o multiplicador do estágio; Velocidade vezes 0,5 se Paralisado.
- **RF-03:** `hitChance(accuracy, accuracyStage, evasionStage)`: `accuracy / 100 × stageMultiplier(clamp(accuracyStage - evasionStage, -6, 6))`, limitada a 1. `accuracy` 0 nunca erra.
- **RF-04:** `critChance(critStage, targetTraitSlug)`: os valores de [architecture.md](architecture.md#valores-a-revisar). Alvo com o Traço `hard_shell` não sofre crítico.
- **RF-05:** `typeMultiplier(skillElementId, defenderElementIds, catalog)`: o produto dos multiplicadores; par sem linha em `element_efficacy` vale 1. Sem Elemento, vale 1.
- **RF-06:** `calculateDamage(input)` segue a fórmula do `GDD.md`: `((2 · nível / 5 + 2) · Poder · Atk / Def / 50 + 2) · STAB · Tipo · Crítico · Aleatório · Outros`.
- **RF-07:** Técnica física usa Atq e Def; especial, Atq.E e Def.E, todos com estágio. Em crítico, estágios negativos do atacante e positivos do defensor são ignorados.
- **RF-08:** STAB é 1,5 se o Elemento da Técnica for um dos Elementos do atacante. Crítico é 1,5. Aleatório fica entre 0,85 e 1,0.
- **RF-09:** "Outros" multiplica 0,5 se o atacante estiver Queimado e a Técnica for física, e 1,5 se o Traço valer (`blazing_fury` em Fogo, `tidal_fury` em Água, `rooted_fury` em Flora, com HP em 1/3 ou menos).
- **RF-10:** O dano final é arredondado para baixo, com mínimo de 1 se `Tipo` for maior que 0. Com `Tipo` 0, o dano é 0.
- **RF-11:** `orderActions(first, second, random)`: maior `priority`, depois maior Velocidade efetiva, depois sorteio.
- **RF-12:** Toda função é pura: não altera o que recebe.

## Critérios de aceite

- [x] Ruvo nível 5, Atq 10, contra Def 9, com Arranhão (Poder 40, físico, Fera, sem STAB nem crítico, Tipo 1, Aleatório 1) causa 5.
- [x] A mesma conta com STAB causa 8, e com Tipo 2, 11.
- [x] Aleatório 0,85 causa 4.
- [x] `stageMultiplier` dá 1 em 0; 1,5 em +1; 4 em +6; 2/3 em -1; e 1/4 em -6.
- [x] Atacante Queimado causa metade com Técnica física e o normal com especial.
- [x] Fúria Ardente com HP exatamente em 1/3 vale; com um HP acima, não.
- [x] Um golpe de Tipo 0 causa 0; um de dano mínimo causa 1.
- [x] `hitChance` com Precisão 0 é 1, e nunca passa de 1.
- [x] `orderActions` respeita prioridade antes de Velocidade, e um Paralisado com Velocidade 20 perde para Velocidade 11.
- [x] Um empate total obedece à fonte de sorteio.
- [x] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Desenho técnico

**Criar**

- `server/src/domain/battle/types.ts`: os tipos de [architecture.md](architecture.md#estado), `BattleCatalog` e `Random`.
- `server/src/domain/battle/stages.ts`, `accuracy.ts`, `damage.ts` e `turn-order.ts`, cada um com o seu `.spec.ts`.

**Reaproveitar**

`StatBlock` e `StatSlug` de `src/domain/rules/types.ts`. O tipo `Random` deve ser compatível com o que `createCreature` já recebe.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test
```

## Tarefas

- [x] Tipos e testes de estágios e Precisão; ver falhar; implementar (RF-01 a RF-03).
- [x] Testes de crítico, Tipo e dano; ver falhar; implementar (RF-04 a RF-10).
- [x] Testes da ordem; ver falhar; implementar (RF-11).
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: regras puras da batalha`.

## Decisões da implementação

- **`critChance` recebe o Traço do alvo:** a Casca Dura é uma regra do crítico, então fica junto dele, e não no motor.
- **`testing.ts` nasceu nesta fase:** a [02](02-battle-engine.md) o citava, mas os testes daqui já precisam montar combatentes, Técnicas e sorteios.
- **`elementSlug` em `BattleSkill`:** as Fúrias comparam o slug do Elemento (`fire`, `water`, `flora`), que é estável, em vez de um id.
- **Conferência:** `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 186 testes; `npm run test:e2e` com 213.

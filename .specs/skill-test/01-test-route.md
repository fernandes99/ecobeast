# 01. A rota da luta de teste da Técnica

- **Status:** concluída
- **Depende de:** nada da iniciativa

## Contexto

A luta de teste de hoje (`POST /v1/me/board-battle`) usa a equipe do jogador e grava o fim. Esta fase cria uma rota ao lado dela, com um Ecobeast emprestado, três opções novas no motor e uma luta que não grava nada.

## Requisitos

- **RF-01:** `POST /v1/me/board-battle/skill-test`, com o `AuthGuard`, só com `ENABLE_TEST_BATTLE` ligada (sem ela, 404, como a luta de teste). O corpo:

  | Campo | Tipo | Padrão | O quê |
  | --- | --- | --- | --- |
  | `skill_id` | inteiro | obrigatório | A Técnica testada |
  | `species_id` | inteiro | obrigatório | Quem usa |
  | `enemy_species_id` | inteiro | obrigatório | O oponente |
  | `level` | inteiro de 1 a 100 | 50 | O nível dos dois |
  | `enemy_idle` | booleano | `false` | O oponente parado |

  Uma Técnica ou uma espécie que não existe, ou um nível fora da faixa, responde 400 com "Técnica, espécie ou nível inválidos.". A resposta é a mesma `BoardBattleResponseDto` das outras lutas. O jogador não precisa ter equipe nem Ecobeast saudável. Uma luta em andamento, de qualquer tipo, é descartada, como nas outras rotas.

- **RF-02:** Quem usa é criado como um selvagem de `species_id` no `level` (`createEnemy`) e entra do lado do jogador. As Técnicas dele são a testada no 1º espaço e, depois, até duas das que ele sorteou, sem repetir a testada, todas com o PP cheio. Ele tem um `creatureUid` que não é de nenhum Ecobeast do banco. O oponente é criado do mesmo jeito, com `enemy_species_id`, e luta com as Técnicas dele.

- **RF-03:** O motor ganha a opção `freeSkills` (`BoardOptions` e o estado da luta): do lado do jogador, usar uma Técnica não gasta PP e não começa o countdown. O lado inimigo continua normal. Sem a opção, nada muda.

- **RF-04:** O motor ganha a opção `idleEnemies`: na vez de um inimigo, ele não anda e passa a vez (a ação `wait`), com os mesmos eventos de quando a IA passa. Os estados, as marcas e o fim da vez dele valem como sempre. Sem a opção, a IA joga como hoje.

- **RF-04b:** O motor ganha a opção `noRewards` (no estado de toda luta, `BattleState`): vencer não dá XP nem moedas, e perder não tira moedas, sem os eventos `xp_gained`, `coins_gained` e `coins_lost`. Ela entrou na implementação: sem ela, o fim da luta de teste não gravava o XP, mas o jogo mostraria no histórico o XP e as moedas ganhos.

- **RF-05:** A luta é 1×1, com o tabuleiro sorteado como o de uma luta de 1 vaga (`rollBoard(1, …)`). Não há itens nem moedas, e a fuga fica liberada. O `opponent` é `wild`.

- **RF-06:** A luta fica guardada com a marca de teste (`StoredBattle.sandbox`). Uma luta de teste nunca grava nada: nem na abertura, nem no `act`, nem na fuga. Isso inclui XP, HP, PP, estados, itens, moedas, evolução, captura e o Bestiário (`recordSeen`). No fim, a resposta vem com `progression` vazio, `captured_to` nulo e `registered_species_ids` vazio.

## Escopo

- A rota, o DTO do corpo e o método no `BoardBattleService`.
- As opções `freeSkills` e `idleEnemies` no `board-engine.ts`, e a `noRewards` no `experience.ts`.
- O Ecobeast emprestado em `src/domain/board/skill-test.ts` (`borrowedCombatant`).
- A marca `sandbox` no `BattleStore` e o fim sem gravar.

## Fora do escopo

- Mudar a luta de teste de hoje, a selvagem, a de Domador ou o Desafiar.
- Uma migration: nada muda no banco.

## Critérios de aceite

- [x] Testes de unidade do motor: com `freeSkills`, a mesma Técnica do jogador é usada em duas vezes seguidas, sem perder PP; sem a opção, ela espera o countdown.
- [x] Testes de unidade do motor: com `idleEnemies`, o inimigo passa a vez no lugar de atacar, e um estado nele (como o Envenenado) ainda conta no fim da vez.
- [x] Testes de unidade do motor: com `noRewards`, vencer não dá XP nem moedas, e perder não tira moedas.
- [x] Testes de unidade do Ecobeast emprestado: a Técnica no 1º espaço com o PP cheio, sem repetir, e as duas últimas sorteadas.
- [x] e2e em `board-battle.e2e-spec.ts`: a rota começa a luta com a Técnica no 1º espaço, e lutar até o fim, com a Técnica sem perder PP, não muda a equipe, as moedas nem o Bestiário do jogador. Com o oponente parado, ele só passa a vez.
- [x] e2e: um `skill_id` ou uma espécie que não existe responde 400, e o `/docs` mostra a rota.
- [x] Testes de unidade, lint e typecheck do servidor passam.

## Verificação

```bash
cd server && npm test && npm run lint && npm run typecheck
cd server && npm run test:e2e -- board-battle
```

## Tarefas

- [x] As opções do motor, com os testes.
- [x] A rota, o Ecobeast emprestado e o fim sem gravar, com os e2e.
- [x] A rota nos docs (`/docs`), com a descrição em pt-BR.

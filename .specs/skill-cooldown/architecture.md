# skill-cooldown — desenho técnico

## A regra

- `skills.cooldown` (inteiro, 0 a 5): as rodadas em que a Técnica fica bloqueada depois de usada.
- Ao usar uma Técnica com countdown N na rodada R, o motor guarda `readyRound = R + N + 1` naquela vaga. A vaga só pode ser escolhida quando `state.round >= readyRound`.
- Com N = 0, `readyRound` fica R + 1, então a Técnica está livre na rodada seguinte, como hoje. Não há como usar a mesma Técnica duas vezes na mesma rodada, porque cada Ecobeast age uma vez por rodada.
- O contador é por vaga do Ecobeast, não por espécie nem por lado. Ele vive só no estado da luta (`BattleStore`, em memória), nunca no banco, e some quando a luta acaba.
- Uma vaga sem `readyRound` (a luta começou antes do deploy) vale como livre.
- A Técnica de emergência (`EMERGENCY_SKILL`) não tem vaga e não tem countdown.

## Exemplo

Countdown 1, usada na rodada 1: bloqueada na rodada 2 (`cooldown_left` 1) e livre na 3.
Countdown 2, usada na rodada 1: bloqueada nas rodadas 2 (`cooldown_left` 2) e 3 (`cooldown_left` 1) e livre na 4.

## Contrato

**Catálogo** (`GET /v1/catalog` e `GET /v1/skills`): cada Técnica ganha `cooldown` (int, 0 a 5).

**Estado da luta** (o mesmo `battle.mapper.ts` das respostas do tabuleiro): cada Técnica de `player.team[].skills[]` ganha `cooldown_left`, as rodadas que ainda faltam, `max(0, readyRound - state.round)`. 0 quer dizer livre.

```json
{ "skill_id": 12, "current_pp": 8, "cooldown_left": 1 }
```

**Recusa:** escolher uma Técnica com `cooldown_left > 0` é recusado como as outras ações inválidas (400), com a frase "Essa Técnica ainda não voltou."

## As 3 vagas

- `MAX_SKILLS = 3` em `creature-factory.ts` e em `learnset.ts`.
- O banco passa a conferir `slot BETWEEN 1 AND 3` (`creature_instance_skills_slot_check`).
- A migration apaga as linhas `slot = 4` de `creature_instance_skills` antes de trocar o CHECK.
- No cliente, as constantes `SKILL_SLOTS` vão de 4 para 3.

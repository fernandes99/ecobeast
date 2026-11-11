# Legacy battle removal

Apaga a luta antiga, a de turnos em que os dois lados escolhiam juntos. Desde a [board-battle/05](../board-battle/05-board-actions.md), Explorar zona e o Desafiar abrem a luta no tabuleiro, e nenhuma tela abria a antiga.

## Contexto

A luta antiga ficou no repositório como legado: a tela `battle` do jogo, as rotas `/v1/me/battle` e o laço de turno em `server/src/domain/battle/engine.ts`. Ninguém a usa, mas ela custa leitura e manutenção, e cerca de 190 testes de unidade passavam por esse laço para conferir regras que a luta no tabuleiro também usa (status, efeitos, Traços, XP, moedas).

## Decisões

Tomadas com o dono do projeto, em 2026-11-11:

| Decisão | Motivo |
| --- | --- |
| Apagar as rotas, o serviço, a tela e o laço de turno antigos | A luta no tabuleiro é a única do jogo |
| Portar os testes das regras compartilhadas, e não apagá-los | Status, efeitos, Traços, XP e moedas continuam protegidos |
| Os testes portados chamam a regra direto (`resolveSkill`, `canAct`, `applyStatusDamage`, `settleCoins`...) ou jogam uma vez no motor do tabuleiro | O laço antigo some, e o teste não depende da ordem do turno nem da IA |
| As pastas `server/src/battle/` e `server/src/domain/battle/` continuam com esse nome | Elas guardam o que a luta no tabuleiro usa: o `BattleStore`, a gravação do fim, o catálogo e as regras de combate |
| No jogo, as peças compartilhadas saem de `screens/battle/` e vão para `screens/board_battle/` | A pasta antiga só teria peças da luta nova |

## Fora do escopo

- Juntar `server/src/battle/` com `server/src/board-battle/`.
- Mudar o contrato das rotas `/v1/me/board-battle`.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-remove-legacy-battle](01-remove-legacy-battle.md) | Servidor e jogo sem a luta antiga, com os testes das regras portados | concluída |

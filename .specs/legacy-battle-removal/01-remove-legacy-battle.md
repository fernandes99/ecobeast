# 01. Apagar a luta antiga

- **Status:** concluída
- **Depende de:** [board-battle](../board-battle/) concluída

## Contexto

A luta antiga não tinha tela que a abrisse desde a [board-battle/05](../board-battle/05-board-actions.md). Esta fase apaga o que era só dela e move para a luta no tabuleiro os testes das regras que as duas dividiam.

## Escopo

- Servidor: as rotas `/v1/me/battle`, o serviço e os DTOs delas, e o laço de turno antigo no domínio.
- Jogo: a tela `battle`, os modelos e as chamadas dela.
- Os testes das regras compartilhadas, portados.

## Fora do escopo

- Juntar `server/src/battle/` com `server/src/board-battle/`.
- Mudar a luta no tabuleiro.

## Requisitos

### Servidor

- **RF-01:** `POST /v1/me/battle`, `/v1/me/battle/wild` e `/v1/me/battle/action` deixam de existir, e somem do `/docs`.
- **RF-02:** saem o `BattleController`, o `BattleService`, os DTOs e o mapper só deles (`StartBattleBodyDto`, `BattleActionBodyDto`, `BattleResponseDto`, `toBattleActions`).
- **RF-03:** o `BattleStore` guarda uma luta por jogador, sem o campo `kind`: só existe a do tabuleiro.
- **RF-04:** do domínio, saem `startBattle`, `applyAction` e tudo que só eles chamavam, a IA antiga (`chooseEnemyAction`), o `executeAction` e o `applyEndOfTurn`. Ficam as regras que a luta no tabuleiro usa: `resolveSkill`, `newSide`, `itemEffect`, `ownedItem`, `spendItem`, `skillRefusal`, `switchRefusal`, `inFieldRefusal`, `resultWithoutEnemies`, `skillWeight`, `pickSlot`, `orderTurn`, e os arquivos de dano, precisão, efeitos, status, Traços, XP e captura.
- **RF-05:** a mensagem "Nenhuma batalha em andamento." (`NO_BATTLE`) passa a morar em `battle.dto.ts`.
- **RF-06:** os e2e de cura, de itens e de equipe, que abriam uma luta antiga para conferir que ela é descartada, abrem a do tabuleiro.

### Testes das regras

- **RF-07:** as regras compartilhadas ficam conferidas sem o laço antigo, de dois jeitos:
  - chamando a regra direto, numa cópia do estado: `cast` (o `resolveSkill`), `canAct`, `applyStatusDamage`, `faintIfDown`, `applyEntryTrait`, `applyDefeatTrait`, `recordEntry`, `awardXp`, `settleCoins`, `skillWeight`, `pickSlot` e as funções de `engine.ts`;
  - jogando uma vez no motor do tabuleiro (`board/board-rules.spec.ts`), para o que depende da vez: as recusas, o PP, o medo, a proteção, o veneno no fim da vez, o Instinto, a Brisa Ligeira, a troca, os itens, a fuga e o fim.
- **RF-08:** saem os testes do que só existia no laço antigo: os dois lados escolhendo juntos, a ordem por prioridade da Técnica, as vagas com uma ação cada, e a IA antiga.

### Jogo

- **RF-09:** saem a tela `battle` (`battle_screen`, `battle_display`, `battle_side_card`), o id `&"battle"` do `Router`, os modelos `BattleTurn` e `BattleView`, e `start_wild_battle` e `battle_action` do `Session` e do `GameService`.
- **RF-10:** as peças que a luta no tabuleiro usa (`BattleItemsPanel`, `BattleNarrator`, `BattleSkillButton`, `CaptureOverlay`, `EvolutionOverlay`, `LevelUpOverlay`, `NextCreaturePanel`, `NextCreatureRow`, `SkillLearnOverlay`) vão de `res://screens/battle/` para `res://screens/board_battle/`.

## Critérios de aceite

- [x] O `/docs` não tem mais as rotas `/v1/me/battle`.
- [x] Nenhum arquivo do servidor importa `startBattle`, `applyAction` ou `chooseEnemyAction`.
- [x] O projeto do jogo abre sem erro de script, e todas as telas do `Router` carregam.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.
- [ ] No jogo (F5), com o dono: Explorar zona, Procurar, lutar, capturar e o Desafiar do Hub continuam como antes.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

Feita em 2026-11-11:
- **Servidor:** lint e tipos limpos; 739 testes de unidade e E2E_COUNT e2e passando.
- **Testes de unidade:** eram 802. Os cerca de 198 que passavam pelo laço antigo viraram 131 em `domain/battle/` e 40 em `domain/board/board-rules.spec.ts`. Os que saíram sem substituto são os do RF-08.
- **Jogo:** o projeto abre sem erro de script; com `-d`, os avisos são os de antes. Uma cena temporária, já apagada, carregou todas as telas do `Router` e todos os arquivos de `screens/board_battle/`.
- **Para o dono:** no F5, uma luta de Explorar zona com item, troca e Esfera, e um Desafiar.

## Tarefas

- [x] Apagar as rotas, o serviço, os DTOs e adaptar os e2e.
- [x] Apagar a tela e as chamadas no jogo, e mover as peças compartilhadas.
- [x] Portar os testes das regras e apagar o laço antigo.
- [x] Rodar a verificação e atualizar o roadmap e os `CLAUDE.md`.

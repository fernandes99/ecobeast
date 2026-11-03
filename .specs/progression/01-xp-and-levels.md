# 01. XP e nível

- **Status:** rascunho
- **Depende de:** [battle-core](../battle-core/), [team-and-storage](../team-and-storage/), [architecture.md](architecture.md)

## Contexto

Hoje a vitória grava só o HP, o status, o PP e os itens gastos (`BattleService.saveTeam`). O `current_xp` e o `level` de um Ecobeast nunca mudam depois de ele nascer. Esta fase faz o servidor dar XP a quem lutou, subir o nível e recalcular os stats. As Técnicas e a evolução ficam para a [02](02-skills-and-evolution.md), e a tela para a [03](03-level-up-screen.md).

O termo "Ascensão" também sai do jogo nesta fase, por decisão do dono.

## Escopo

- Guardar, em cada inimigo da luta, quem esteve em campo contra ele.
- Calcular e dividir o XP quando um inimigo desmaia, e emitir `xp_gained`.
- Gravar o XP, o nível, os stats e o HP no fim da vitória, e devolver `progression`.
- Trocar "Ascensão" por "Evolução" no catálogo, no glossário e nos documentos vivos.

## Fora do escopo

- Técnicas novas e evolução: na `progression` desta fase, `evolution` é sempre `null`, e `learned_skill_ids` e `pending_skill_ids` são sempre `[]`.
- Qualquer mudança no jogo. O cliente ignora o evento e o campo novos até a [03](03-level-up-screen.md).
- As specs já concluídas que citam "Ascensão": elas registram o que foi feito na época e ficam como estão.

## Requisitos

- **RF-01:** cada inimigo guarda os índices da equipe do jogador que estiveram em campo contra ele, sem repetição, com as regras de entrada do [architecture.md](architecture.md#quem-recebe-xp).
- **RF-02:** quando um inimigo desmaia, o XP total é `floor(base_xp_yield × nível do inimigo ÷ 7)`.
- **RF-03:** o total é dividido entre os índices de `foughtBy` com HP acima de 0 e nível abaixo de 100, e cada um recebe `max(1, floor(total ÷ quantidade))`.
- **RF-04:** sem ninguém para receber, não há XP nem evento.
- **RF-05:** cada parte gera um evento `{ type: 'xp_gained', team_index, amount }`, logo depois do `fainted` do inimigo, na ordem do índice.
- **RF-06:** captura, fuga e derrota não geram `xp_gained`.
- **RF-07:** na vitória, o `current_xp` de cada um que recebeu soma a parte dele, sem passar do XP total do nível 100. O `level` passa a ser o maior nível cujo XP total cabe no `current_xp`.
- **RF-08:** o HP atual de quem subiu de nível aumenta o mesmo tanto que o HP máximo.
- **RF-09:** o XP, o nível e o HP são gravados na mesma transação que já guarda o HP, o PP e os itens da luta.
- **RF-10:** a resposta da ação que encerra a luta traz `progression`. Na vitória, é a lista de quem recebeu XP, na ordem do `team_index`, com os campos do [contrato](architecture.md#contrato). Nos outros casos, é `[]`.
- **RF-11:** a resposta de qualquer ação que não encerra a luta traz `progression: []`.
- **RF-12:** o `name` da linha `evolution` de `skill_learn_methods` passa de "Ao ascender" para "Ao evoluir", no seed e no banco.

## Critérios de aceite

- [ ] Ruvo de nível 5, sozinho, vence um selvagem de nível 5 com `base_xp_yield` 62: recebe 44 de XP, e o evento e a `progression` mostram isso.
- [ ] Dois Ecobeasts que entraram em campo e não desmaiaram recebem 22 cada um pelo mesmo inimigo.
- [ ] Um Ecobeast que entrou em campo, desmaiou e foi trocado não recebe XP, e quem sobrou recebe o total.
- [ ] Um Ecobeast que nunca entrou em campo não recebe XP.
- [ ] Um Ecobeast no nível 100 que lutou não recebe XP nem conta na divisão.
- [ ] Capturar, fugir e perder não mudam o `current_xp` de ninguém.
- [ ] Passar de 1.708 para 1.750 de XP, na curva Média, muda o nível de 11 para 12, e o HP atual sobe o mesmo tanto que o máximo.
- [ ] Um ganho grande que pula vários níveis devolve um item só, com o primeiro e o último nível.
- [ ] Depois da vitória, `GET /v1/me` mostra o nível, o XP e o HP novos.
- [ ] `GET /v1/catalog` mostra "Ao evoluir" em `skill_learn_methods`.
- [ ] O glossário e os documentos vivos (`CLAUDE.md`, `GDD.md`, `README.md` da raiz, `.specs/roadmap.md` e `.specs/glossary.md`) não usam mais "Ascensão" para a evolução.

## Desenho técnico

- **Criar** `server/src/domain/progression/xp.ts`:
  - `xpYield(baseXpYield: number, enemyLevel: number): number`.
  - `splitXp(total: number, receivers: number): number`.
- **Criar** `server/src/domain/progression/levels.ts`:
  - `levelForXp(xpMultiplier: number, totalXp: number): number`.
  - `gainXp(xpMultiplier: number, level: number, currentXp: number, amount: number): { level: number; currentXp: number }`, com o teto do nível 100.
  - Os testes ficam em `xp.spec.ts` e `levels.spec.ts`, ao lado de cada arquivo.
- **Alterar** `server/src/domain/battle/types.ts`:
  - `Combatant` ganha `foughtBy: number[]`, usado no inimigo e vazio no jogador, e `xpEarned: number`, usado no jogador.
  - `BattleCatalog` ganha `xpYields: Map<number, number>`, com o `base_xp_yield` por espécie.
  - `BattleEvent` ganha `xp_gained`.
- **Alterar** `server/src/domain/battle/engine.ts`: anota a entrada em campo (começo, troca e substituição depois de desmaio) e reparte o XP no desmaio do inimigo. Procure onde o `fainted` do lado `enemy` é emitido.
- **Alterar** `server/src/battle/battle-catalog.ts`: carrega o `base_xp_yield`. Atualize `server/src/domain/battle/testing.ts`, que monta catálogos e combatentes para os testes.
- **Alterar** `server/src/battle/battle.service.ts`: no fim da vitória, com o `xp_multiplier` da curva de cada espécie, calcula o nível novo e os stats (`calculateStats`, com os Genes, o Treino e o Temperamento gravados, como em `player.mapper.ts`), monta a `progression` e grava `current_xp`, `level` e `current_hp` no `saveTeam`.
- **Alterar** `server/src/battle/battle.dto.ts`: `CreatureProgressDto` com os campos do contrato e `progression` na resposta, com exemplo na doc do Scalar.
- **Criar** a migração `server/prisma/migrations/<data>_evolution_name/migration.sql` com o `UPDATE` do nome. **Alterar** `server/prisma/seed-data/skill_learn_methods.json`.
- **Alterar** os documentos vivos e os comentários do código que dizem "Ascensão" ou "ascender", e os testes que esperam "Ao ascender".
- **Alterar** `.specs/battle-core/architecture.md`: o evento `xp_gained` e o campo `progression`.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test
cd server && npx prisma migrate deploy && npm run test:e2e
```

E2e novos em `server/test/progression.e2e-spec.ts`, usando o `placeWild` de `server/test/support/wild.ts` para escolher o selvagem: XP de quem venceu sozinho, divisão entre dois com troca, desmaiado sem XP, captura e fuga sem XP, e o nível e o HP em `GET /v1/me`.

## Tarefas

- [ ] `xp.ts` e `levels.ts`, com testes
- [ ] `foughtBy`, `xpEarned` e `xp_gained` no motor da batalha, com testes
- [ ] `xpYields` no catálogo da batalha
- [ ] Gravação e `progression` no `BattleService`, e o DTO
- [ ] Migração e seed de "Ao evoluir"
- [ ] "Ascensão" fora dos documentos vivos e do código
- [ ] E2e, e status e tabelas atualizados

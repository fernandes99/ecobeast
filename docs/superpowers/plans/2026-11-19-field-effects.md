# field-effects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preso no tabuleiro, os estados Encharcado e Brotando, a marca que cura, seis marcas novas e dez Técnicas que os usam.

**Architecture:** As regras ficam no motor do servidor (`server/src/domain/battle` e `board`), contadas por vez como o Atordoado; o catálogo ganha linhas por migração SQL à mão; o Godot só mostra os eventos e os campos novos da vista.

**Tech Stack:** NestJS + Prisma (TypeScript, Jest), Godot 4.7 (GDScript tipado).

**Spec:** `.specs/field-effects/` (README, 01, 02 e 03).

## Global Constraints

- Textos do jogador em pt-BR; nada de Pokémon.
- Migração em SQL à mão + `npx prisma migrate deploy`; `server/prisma/seed-data/` não muda.
- Tabela ou coluna nova muda `schema.prisma`, `catalog_schema.gd` e `.specs/game-data/architecture.md` juntos.
- GDScript tipado; código sem comentário, salvo o porquê em uma linha.
- Commit só quando o dono pedir (um por fase).

## Review Focus

- Luta salva antes da migração, sem `trappedTurns`/`soakedTurns`/`sproutingTurns`: conta 0, nunca `NaN` (teste no Task 2).
- Encharcado no Ecobeast que troca e volta: sai na troca (`clearVolatile`) (teste no Task 2).
- Brotando e Jardim com o HP cheio: nenhum evento de cura (teste nos Tasks 2 e 3).
- Quem desmaia na marca de dano não é curado pelo Jardim no mesmo fim de vez (teste no Task 3).
- Preso que perde a vez por sono ainda conta a vez (teste no Task 2).

---

### Task 1: O catálogo (migração e leitura)

**Files:**
- Create: `server/prisma/migrations/20270109000000_field_effects/migration.sql`
- Modify: `server/prisma/schema.prisma` (`GroundEffect.healPercent Int? @map("heal_percent")`), `server/src/battle/battle-catalog.ts`, `server/src/domain/battle/types.ts` (`BattleGroundEffect.healPercent: number | null`), `server/src/domain/board/testing.ts` e os specs que montam `groundEffects` (pôr `healPercent: null`), `client/core/data/catalog_schema.gd`, `.specs/game-data/architecture.md`
- Test: `server/src/battle/battle-catalog.spec.ts`

**Interfaces:**
- Produces: `BattleGroundEffect.healPercent`; status slugs `soaked` (10) e `sprouting` (11); marcas 6 a 11 do RF-12 da 01; imunidade `trapped` → Vento (6).

- [ ] Step 1: teste no `battle-catalog.spec.ts`: a marca com `heal_percent` 6 chega como `healPercent: 6`, e as outras como `null`.
- [ ] Step 2: rodar `npx jest battle-catalog` e ver falhar.
- [ ] Step 3: migração com o `ALTER TABLE ground_effects ADD COLUMN heal_percent integer`, os INSERTs dos status 10 e 11, da imunidade (8, 6), das marcas 6 a 11 e de `ground_effect_stats` (6: spd −1; 7: evasion −1); `prisma generate`; `healPercent` no `battle-catalog.ts`.
- [ ] Step 4: `npx prisma migrate deploy`, `npm run typecheck`, `npx jest battle-catalog` passam; `GET /v1/catalog` traz `heal_percent`.
- [ ] Step 5: `catalog_schema.gd` com a coluna `heal_percent` (int anulável) e o jogo sem janela abre.

### Task 2: Preso, Encharcado e Brotando no motor

**Files:**
- Modify: `server/src/domain/battle/types.ts`, `status.ts`, `damage.ts`, `testing.ts`; `server/src/domain/board/board-engine.ts`; `server/src/battle/battle.mapper.ts`, `battle.dto.ts`; a lista de eventos em `.specs/board-battle/architecture.md`; `GDD.md` (estados voláteis)
- Test: `server/src/domain/board/board-engine.spec.ts` (describe novo "field-effects/01"), `server/src/domain/battle/damage.spec.ts`

**Interfaces:**
- Produces: `Combatant.trappedTurns`, `soakedTurns`, `sproutingTurns: number` (no lugar de `isTrapped`); `TRAPPED_NO_MOVE = 'Preso: não dá para andar nesta vez.'` exportado do `board-engine.ts`; evento `{ type: 'status_heal', side, position, status: 'sprouting', amount, hp }`; vista com `trapped`, `soaked`, `sprouting: boolean`.

- [ ] Step 1: testes:
  - preso (`trappedTurns: 2`) recebe `{ error: TRAPPED_NO_MOVE }` com `move`, sem mudar o estado; depois de 2 `wait`, `status_ended` `trapped` e `trappedTurns` 0;
  - `applyStatus` de `trapped` num Vento dá `effect_failed`;
  - preso adormecido (perde a vez) ainda conta 1;
  - Volt num encharcado: dano = 1,5× do mesmo golpe sem encharcar (no `damage.spec.ts`), Fogo 0,5×;
  - `soaked` duas vezes: segundo `status_applied` e `soakedTurns` 3;
  - brotando com 100/200 de HP: `status_heal` de 12 (floor(200/16)) no fim da vez, por 5 vezes, e `status_ended`; com HP cheio, sem `status_heal`;
  - Combatant sem os campos novos (apagados com `delete`) joga uma vez sem `NaN`;
  - trocar quem está encharcado zera `soakedTurns`.
- [ ] Step 2: `npx jest board-engine damage` e ver falhar.
- [ ] Step 3: implementar:
  - `setStatus`: `trapped` (falha se > 0, senão 2), `soaked` (sempre 3, retorna true), `sprouting` (falha se > 0, senão 5); `hasStatus` e `clearVolatile` com os três;
  - `damage.ts`: `soakedMultiplier(defender, skill)` = 1,5 para `elementSlug === 'volt'`, 0,5 para `'fire'`, só com `soakedTurns > 0`, nos `others`;
  - `board-engine.ts`: recusa com `trappedTurns > 0` ao lado do `isDazed`; `canWalk` também; troca e fuga usam `trappedTurns > 0`; no `endVez`, depois do `applyStatusDamage`, `sproutHeal` e a contagem dos três (função `countVolatiles(context, actor)`), antes do `applyMarks`; ler cada contador com `?? 0`;
  - mapper e DTO com os três booleanos (Swagger `@ApiProperty`).
- [ ] Step 4: `npm run lint && npm run typecheck && npm test` passam.

### Task 3: A marca que cura

**Files:**
- Modify: `server/src/domain/board/marks.ts`
- Test: `server/src/domain/board/board-engine.spec.ts`

**Interfaces:**
- Consumes: `BattleGroundEffect.healPercent` (Task 1).
- Produces: evento `{ type: 'ground_heal', side, position, amount, hp, ground_effect_id }`.

- [ ] Step 1: testes: dois Ecobeasts (um de cada lado) no Jardim (`healPercent: 6`), com 100/200, recebem `ground_heal` de 12 depois de uma vez; com HP cheio, nada; quem desmaiou no fim da vez não é curado; quem para na Areia Movediça fica preso de novo enquanto ela dura.
- [ ] Step 2: ver falhar.
- [ ] Step 3: no `applyMark`, depois do dano e só com `currentHp > 0`, curar `max(1, floor(hp * healPercent / 100))` sem passar do máximo.
- [ ] Step 4: `npm test` passa.

### Task 4: A IA

**Files:**
- Modify: `server/src/domain/board/board-ai.ts`
- Test: `server/src/domain/board/board-ai.spec.ts`

- [ ] Step 1: testes: a IA presa não manda `move`; a IA com menos da metade do HP, com o Jardim a 1 hexágono, anda para ele; com HP cheio, evita como as outras marcas.
- [ ] Step 2: ver falhar.
- [ ] Step 3: tratar `trappedTurns > 0` como o `isDazed`; na nota do hexágono, o Jardim (`healPercent !== null`) vale como bom com HP < 50%.
- [ ] Step 4: `npm run lint && npm run typecheck && npm test && npm run test:e2e` passam; spec 01 marcada concluída.

### Task 5: O jogo mostra (fase 02)

**Files:**
- Modify: `client/domain/models/battle_creature.gd`, `client/screens/board_battle/battle_statuses.gd`, `status_icons.gd`, `creature_aura.gd`, `battle_narrator.gd`, `board_battle_screen.gd` (eventos `status_heal` e `ground_heal`), o painel F3, `client/ui/theme/palette.gd`
- Test: cena temporária em `client/zz_tmp_check/` (apagar no fim)

- [ ] Step 1: cena temporária que aplica `status_applied` `soaked`/`sprouting`/`trapped` e confere `BattleStatuses.of(key)`, e que `status_heal`/`ground_heal` sobem a vida da ficha.
- [ ] Step 2: ver falhar.
- [ ] Step 3: implementar o RF-01 a RF-06 da 02 (cores `soaked` `#4A90D9`, `sprouting` `#7FCB6B`; falas exatas da spec).
- [ ] Step 4: `godot --headless -d --path client --quit-after 240` sem erro; apagar a cena; spec 02 concluída (falta o dono ver).

### Task 6: As dez Técnicas (fase 03)

**Files:**
- Create: `server/prisma/migrations/20270110000000_field_skills/migration.sql`
- Modify: specs de contagem do catálogo, se houver; `.specs/field-effects/03-field-skills.md`, README, roadmap, `.specs/README.md`, `CLAUDE.md`

- [ ] Step 1: migração com as Técnicas 66 a 75 (RF-01 e RF-02 da 03), `skill_effects` 46 a 49 (RF-03) e `species_skills` (RF-04; ids das espécies: Nilu 4, Nilgar 5, Nilgorr 6, Seedlet 7, Grovequill 8, Arbornix 9, Hushling 10, Echofrost 11, Clod 12, Crag 13, Ingot 14, Tidebud 17, Kelpcoil 18, Tempestide 19; Água 2, Flora 3, Gelo 7, Terra 5, Toxina 9 — conferir os ids dos Elementos no banco).
- [ ] Step 2: `migrate deploy`; teste temporário com o catálogo do banco (Esguicho + Corrente Viva = 1,5×; Laço de Raízes prende; Poça Tóxica não envenena o Nilgorr), depois apagado.
- [ ] Step 3: `npm test`, jogo sem janela com o `CatalogValidator`; `GET /v1/species/tidebud` com o Esguicho no 7.
- [ ] Step 4: documentos (CLAUDE.md, roadmap, índice, README da iniciativa) e o resumo ao dono.

# Os moradores da vila — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** 10 NPCs moradores no catálogo, com a fala padrão que o F2 copia ao pôr o NPC.

**Architecture:** Uma coluna nova em `npcs`, levada pelo catálogo genérico (`BundleService` lê todas as colunas). O cliente só aceita a coluna no esquema e a usa nos dois lugares que põem NPC.

**Tech Stack:** Prisma 7 (SQL à mão + `migrate deploy`), Vitest e2e, Godot 4.7 GDScript.

**Spec:** `.specs/village-crowd/01-villagers.md`

## Global Constraints

- Textos em pt-BR; descrição "Morador da Vila Raiz.".
- CHECK `npcs_default_dialogue_check`: `char_length("default_dialogue") <= 2000`.
- Nunca gravar em Liora nem na sala 1 nas conferências.
- Poucos comentários.

## Review Focus

- O seed numa base vazia: os NPCs de antes precisam de `"default_dialogue": ""` no JSON (createMany aceita sem, mas o JSON fica igual ao banco).
- A saia (peça 15) só no corpo feminino: a conferência de aparência do jogo recusa no masculino.
- Um NPC de Ecobeast (sem corpo) com fala padrão vazia continua igual no F2.
- No interior, a fala digitada antes de pôr tem a vez sobre a padrão.
- O `catalogVersion` muda e o jogo baixa o catálogo novo sem erro de coluna desconhecida.

---

### Task 1: O banco e o seed

**Files:**
- Create: `server/prisma/migrations/20270104000000_village_crowd/migration.sql`
- Modify: `server/prisma/schema.prisma` (modelo `Npc`), `server/prisma/seed-data/npcs.json`, `server/prisma/seed-data/npc_appearance_parts.json`, `server/test/database.e2e-spec.ts`

- [x] Teste e2e `recusa fala padrão de NPC com mais de 2.000 caracteres (village-crowd/01)`, no padrão do teste de `island_npcs_dialogue_check`, esperando `npcs_default_dialogue_check`.
- [x] Migration: `ADD COLUMN`, o CHECK, o `INSERT` dos 10 NPCs e das 50 a 60 peças (RF-02 e RF-03), e o `setval`.
- [x] `npx prisma migrate deploy` e `npx prisma generate`; o e2e do CHECK, o `database.e2e` e o `seed.e2e` passam.

### Task 2: O jogo e o F2

**Files:**
- Modify: `client/core/data/catalog_schema.gd`, `client/tools/map_editor/npc_panel.gd:225`, `client/tools/interior_editor/interior_editor.gd:376`

- [x] `"default_dialogue": TEXT` em `npcs`.
- [x] `place`: `"dialogue": str(GameData.get_npc(npc_id).get("default_dialogue", ""))`.
- [x] Interior: se `values["dialogue"]` está vazio, usa o `default_dialogue` do NPC.
- [x] Cena temporária: catálogo baixado sem erro, `TamerAppearance.for_npc(7..16) != null`, `place` num `IslandDraft` de memória dá a fala da Lúcia (12) e a vazia do Avô (3).

### Task 3: As specs e a suíte

- [x] `game-data/architecture.md`, `.specs/README.md`, `roadmap.md` e o `CLAUDE.md` da raiz.
- [x] `npm run lint && npm run typecheck && npm test && npm run test:e2e`, e o Godot headless sem erro de script.

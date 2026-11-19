# As zonas dos biomas — plano de implementação

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 24 zonas (13 novas e a Comum de cada bioma) com plantas próprias, geradas no mapa sorteado, onde mudam quem nasce, e pintadas nas ilhas pela ferramenta Zona do F2.

**Architecture:** O catálogo ganha `biome_zones` e `species_biome_zones`. Depois de `generateMap`, uma função pura (`assignZones`) põe `zone` nos hexágonos pelas faixas de um ruído próprio, e o `rollSpawns` agrupa por zona. O cliente escolhe a receita de `HexDecorations` pelo slug da zona, caindo no bioma na Comum. As ilhas guardam `island_tiles.biome_zone_id`, nulo na Comum.

**Tech Stack:** Prisma 7 (SQL à mão + `migrate deploy`), NestJS, Vitest (unidade e e2e), Godot 4.7 GDScript.

**Spec:** `.specs/biome-zones/README.md`, `01-zone-records.md`, `02-zone-plants.md`, `03-island-zones.md`

## Global Constraints

- O slug da Comum é o slug do bioma, e o id dela é o id do bioma (1 a 11).
- `share` CHECK 0–100; `rate_percent` CHECK 0–1000; `name` CHECK 1–40; slug CHECK `^[a-z0-9_]+$`.
- `ZONE_SCALE` = 2; `ZONE_SALT` diferente de `TEMPERATURE_SALT` e de `WATER_SALT`.
- `MapTile.zone` e o `zone` do JSON só existem fora da Comum.
- Migrations em LF, à mão, com `prisma migrate deploy`.
- Nunca gravar na ilha 1 (Liora) nas conferências; textos em pt-BR; poucos comentários.

## Review Focus

- Um bioma sem nenhuma zona no banco (o dono apagou as linhas): `assignZones` deixa os hexágonos na Comum, sem erro.
- Uma zona com `share` 0 nunca aparece no mapa sorteado, mas pode ser pintada numa ilha.
- Um bioma com poucos hexágonos (1 ou 2) não quebra a divisão em faixas.
- Uma zona do banco sem receita no cliente cai na receita do bioma, sem travar o mapa.
- Trocar o bioma de um hexágono pintado no F2 e desfazer volta o bioma e a zona juntos.

---

### Task 1: O banco e o seed (fase 01, RF-01 a RF-03)

**Files:**
- Create: `server/prisma/migrations/20270109000000_biome_zones/migration.sql`, `server/prisma/seed-data/biome_zones.json`, `server/prisma/seed-data/species_biome_zones.json`
- Modify: `server/prisma/schema.prisma`, `server/test/database.e2e-spec.ts`

- [x] e2e `recusa zona com share fora de 0 a 100 (biome-zones/01)` e `recusa rate_percent fora de 0 a 1000 (biome-zones/01)`, no padrão dos CHECKs de hoje.
- [x] Migration: as duas tabelas, os CHECKs, os índices de FK, as 24 zonas (RF-02), as exceções (RF-03) por `INSERT ... SELECT ... WHERE EXISTS` na espécie, e o `setval`.
- [x] `npx prisma migrate deploy` e `npx prisma generate`; o `database.e2e` e o `seed.e2e` passam (menos as 2 falhas de antes, de espécies que só estão no banco).

### Task 2: `assignZones` (fase 01, RF-05 e RF-06)

**Files:**
- Create: `server/src/domain/exploration/map-zones.ts`, `map-zones.spec.ts`
- Modify: `map-generator.ts` (`MapTile.zone?: string`), `server/src/exploration/exploration.service.ts`, `exploration.dto.ts`, `server/src/editor/map-generator.controller.ts`, `server/src/exploration/spawn-data.ts` (`loadZones`)

**Interfaces:**
- Produces: `interface MapZone { slug: string; biome: Biome; share: number; sortOrder: number }`; `assignZones(tiles: MapTile[], seed: number, zones: readonly MapZone[], config?: MapConfig): MapTile[]` (devolve hexágonos novos, com `zone` só fora da Comum); `loadZones(prisma): Promise<MapZone[]>`.

- [x] Testes: as faixas a até 1 hexágono da conta exata com as zonas do seed em 20 seeds; Montanha, Praia e águas sem `zone`; a mesma seed dá as mesmas zonas; o bioma, a altura e a variante iguais aos de `generateMap`; um bioma sem zonas fica na Comum; `share` 0 não aparece; um bioma de 1 hexágono não quebra.
- [x] Implementação: o tamanho da faixa é `round(acumulado × n / soma)`, para a soma das faixas dar `n` exato.
- [x] `startRandom` (a entrada no mapa) e `generate` do F2 chamam `assignZones` com `loadZones`; `MapTileDto.zone` opcional.

### Task 3: O sorteio por zona (fase 01, RF-07 e RF-08)

**Files:**
- Modify: `server/src/domain/exploration/spawns.ts`, `spawns.spec.ts`, `server/src/exploration/spawn-data.ts`

**Interfaces:**
- Consumes: `MapTile.zone`, `MapZone`.
- Produces: `SpawnSpecies.zoneRates?: Partial<Record<string, number>>` (em %); `rollSpawns` com a mesma assinatura.

- [x] Testes: sem exceções, a soma dos pesos das zonas de um bioma é a do bioma; `rate_percent` 0 tira a espécie da zona; 200 dobra o peso dela na zona.
- [x] `biomeRolls` agrupa por `tile.zone ?? tile.biome`, com `rate = rates[tile.biome] × (zoneRates[zona] ?? 100) / 100`.
- [x] `loadSpawnSpecies` lê `species_biome_zones` com o slug da zona.

### Task 4: O catálogo do jogo (fase 01, RF-04)

**Files:**
- Modify: `server/src/catalog/catalog-tables.ts`, `catalog-tables.spec.ts`, `client/core/data/catalog_schema.gd`, o `CatalogValidator`, `.specs/game-data/architecture.md`

- [x] `biome_zones` depois de `biomes`, e `species_biome_zones` (chave `species_id`, `biome_zone_id`) depois de `species_biomes`.
- [x] O validador confere que cada bioma tem a zona com o slug dele.
- [x] `npm run lint`, `typecheck`, `test`; o jogo abre sem erro de catálogo.

### Task 5: As plantas por zona (fase 02)

**Files:**
- Modify: `client/domain/models/hex_tile.gd`, `client/ui/components/hex_decorations.gd`, `client/screens/board_battle/board_battle_screen.gd`, `board_view.gd`, quem abre a luta em `client/screens/exploration/`, `client/tools/content_viewer/biomes_tab.gd`

- [x] `HexTile.zone` e o `from_dict`; `decorations_of` com `RECIPES.get(zone)` quando não vazio, e o aviso único de zona sem receita.
- [x] As 13 receitas do RF-03 da fase 02 no fim de `RECIPES`, sem mexer nas de hoje.
- [x] O tabuleiro recebe `zone` junto com `biome`.
- [x] A aba Biomas do F1 com as zonas.
- [x] Cena temporária `client/zz_tmp_check`: a Comum igual à de antes (o hash das decorações de 200 hexágonos antes e depois) e uma foto de um mapa sorteado com zonas; apagar a cena.

### Task 6: As zonas nas ilhas (fase 03)

**Files:**
- Create: `server/prisma/migrations/20270110000000_island_zones/migration.sql`, `client/tools/map_editor/zone_panel.gd`, `client/tools/map_editor/icons/zone.svg`
- Modify: `server/prisma/schema.prisma`, `server/src/islands/` (DTO, service), os e2e das ilhas, `editor_tools.gd`, `island_draft.gd`, `editor_canvas.gd`, `map_editor.gd`

- [x] e2e: salvar e ler uma ilha de teste com `zone`; 400 para uma zona de outro bioma e para uma zona que não existe; o slug da Comum volta sem `zone`.
- [x] Migration, schema e o service (ler e gravar `biome_zone_id`).
- [x] `Tool.ZONE` no grupo Terreno, depois de Altura; o painel, a pintura só no bioma da zona, o botão de trás volta à Comum, a cor por cima e o desfazer (a zona no estado de `island_draft.gd`).
- [x] A ferramenta Bioma limpa a zona; a ilha nova pelo gerador guarda as zonas.
- [x] Conferência numa ilha de teste, nunca em Liora.

### Task 7: Verificação e documentos

- [x] `cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e`.
- [x] `godot --headless --path client --quit-after 30`.
- [x] Status das fases, `roadmap.md`, `README.md` das specs e o `CLAUDE.md` da raiz.

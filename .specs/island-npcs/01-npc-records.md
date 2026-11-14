# 01. Os NPCs no banco e no contrato

- **Status:** concluída
- **Depende de:** [free-props/01](../free-props/01-prop-records.md), [architecture.md](architecture.md)

## Contexto

Primeira fase da [island-npcs](README.md): o servidor passa a ter o catálogo de NPCs e a guardar, conferir, publicar e entregar os NPCs postos numa ilha. O editor e o jogo ainda não os usam (fases 2 e 3). É o mesmo caminho das peças soltas na [free-props/01](../free-props/01-prop-records.md).

## Escopo

- O catálogo `npcs`, com os 2 primeiros NPCs ([architecture](architecture.md#o-catálogo-npcs)).
- As tabelas `island_npcs` e `island_npc_tiles`, e os NPCs no rascunho, na publicação e no mapa de Explorar numa ilha.
- O espelho do catálogo no jogo (`catalog_schema.gd`).

## Fora do escopo

- A ferramenta do editor e o NPC no jogo.

## Requisitos

- **RF-01:** `npcs` (`id`, `slug`, `name`, `description`, `sprite`) entra no catálogo e vem no `GET /v1/catalog`, com `CHECK` no formato do `slug` e do `sprite`.
- **RF-02:** O rascunho aceita `npcs` (opcional, vazio se faltar) e sempre o devolve, com `tiles` e `dialogue` (vazios quando faltam) e `action_type_id` (`null` quando falta).
- **RF-03:** Salvar recusa (`400`) cada erro da lista do [architecture](architecture.md#o-rascunho), com a mensagem dele.
- **RF-04:** O `content_hash` inclui os NPCs só quando há algum, na ordem do architecture.
- **RF-05:** Publicar copia os NPCs, e o `POST /v1/me/exploration` numa ilha publicada os devolve em `map.npcs`, com o `id`; no mapa sorteado, `npcs` é `[]`.

## Critérios de aceite

- [x] O catálogo traz os 2 NPCs.
- [x] Um rascunho com NPCs é salvo, lido de volta igual e publicado, e Explorar na ilha devolve os NPCs.
- [x] Cada erro do RF-03 é recusado com a mensagem certa.
- [x] Uma ilha sem NPC continua com o mesmo `content_hash`.

## Desenho técnico

- `prisma/schema.prisma`: `Npc` (`npcs`), `IslandNpc` (`island_npcs`) e `IslandNpcTile` (`island_npc_tiles`), com `IslandMap.npcs`.
- A migration `island_npcs`, com os `CHECK` à mão, os 2 NPCs e a sequência; `seed-data/npcs.json`.
- `src/catalog/catalog-tables.ts`: `npcs`.
- `src/domain/islands/island-draft.ts`: `DraftNpc`, `IslandDraft.npcs`, `KnownIds.npcIds`, os limites, a conferência e a ordem no `canonicalDraft`.
- `src/editor/islands-editor.dto.ts` e `islands-editor.service.ts`: a leitura, a conferência e a gravação.
- `src/islands/islands.service.ts`: `readVersion` lê os NPCs.
- `src/exploration/exploration.dto.ts` e `exploration.service.ts`: `MapNpcDto` e `npcs` no mapa.
- Jogo: `core/data/catalog_schema.gd`, com `npcs`.
- Specs: `.specs/game-data/architecture.md`, a tabela nova.

## Verificação

- Testes de unidade do `draftError` (cada erro) e do `canonicalDraft` (com e sem NPC).
- E2e: o catálogo com `npcs`, o editor salvando, lendo e publicando, e Explorar devolvendo os NPCs.
- `npm run lint`, `typecheck`, `npm test` e `npm run test:e2e`.

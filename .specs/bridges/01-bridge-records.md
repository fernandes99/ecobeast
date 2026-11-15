# 01. Os estilos, o catálogo e o contrato

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-fences/01](../free-fences/01-wall-records.md)

## Contexto

Antes de desenhar ou andar, a ponte precisa existir: a arte de cada estilo, o tipo no catálogo e a ponte guardada na ilha ([README](README.md#contexto)).

## Escopo

- O recorte da arte do pacote em `client/assets/bridges/`.
- O catálogo `bridge_types` e a tabela `island_bridges`, por migration, com o `seed-data`.
- O contrato `bridges` no editor e em Explorar numa ilha, com as regras do servidor.
- `MapBridge` e `ExplorationMap.bridges` no cliente, e as pontes no `IslandDraft`.

## Requisitos

- **RF-01:** `make_bridges.py` recorta da `Bridges.png` os estilos com as duas vistas, no formato da [arte](architecture.md#a-arte-fase-1). A escolha dos estilos e dos recortes é conferida numa imagem com todos lado a lado, antes de seguir.
- **RF-02:** Uma migration cria `bridge_types` (com os estilos do RF-01) e `island_bridges`, com o `CHECK` de 4 pontos. O `seed-data` ganha `bridge_types.json`.
- **RF-03:** `GET /v1/catalog` manda `bridge_types`, espelhada no `catalog_schema.gd` do jogo.
- **RF-04:** O rascunho do editor e a ilha de Explorar levam `bridges` no contrato da [arquitetura](architecture.md#as-pontes-no-banco-island_bridges-fase-1). O servidor recusa, com uma mensagem em pt-BR:
  - um tipo que não existe;
  - uma ponta fora da ilha ou na água ("A ponta da ponte precisa ficar em terra.");
  - pontas a menos de 16 px uma da outra;
  - mais de 500 pontes.
- **RF-05:** O `content_hash` leva as pontes; uma ilha sem pontes tem o hash de antes.
- **RF-06:** O cliente lê as pontes em `MapBridge`, e o `IslandDraft` as guarda e as manda ao salvar.

## Critérios de aceite

- [x] A imagem com todos os estilos recortados mostra, em cada um, as duas vistas inteiras e o meio repetindo sem emenda.
- [x] Testes do servidor cobrem cada recusa do RF-04 e o hash sem pontes.
- [x] Salvar e abrir de novo uma ilha com pontes devolve as mesmas pontes.

## Desenho técnico

**Criar:**
- `client/assets/bridges/make_bridges.py`, as pastas de cada estilo e `CREDITOS.md`.
- `client/domain/models/map_bridge.gd`.
- A migration e `server/prisma/seed-data/bridge_types.json`.

**Alterar:**
- `server/prisma/schema.prisma`, o catálogo, `server/src/domain/islands/island-draft.ts`, `server/src/islands/islands.service.ts`, `server/src/editor/islands-editor.service.ts` e os testes deles.
- `client/domain/models/exploration_map.gd`, `client/core/data/catalog_schema.gd` e `client/tools/map_editor/island_draft.gd`.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

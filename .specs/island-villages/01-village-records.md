# 01. Registros da vila

- **Status:** concluída
- **Depende de:** [README](README.md), [architecture.md](architecture.md)

## Contexto

Hoje a ilha guarda o terreno, as construções e as áreas. Esta fase prepara os dados de tudo o que a iniciativa traz: os tipos de chão, de objeto e de ação no catálogo, o chão e os objetos em cada ilha e as construções convertidas em ações. Ela também põe as regras do bloqueio no servidor. O jogo e o editor passam a falar de ações no lugar de construções e a guardar o chão e os objetos que receberem, mas ainda não desenham nem pintam trilhas e objetos, o que vem na [02](02-grounds.md) e na [03](03-map-objects.md).

## Escopo

- Migration: `ground_types`, `map_object_types` e `map_object_type_tiles` com as linhas iniciais, `building_types` renomeada para `action_types` com `kind`, `island_tiles.ground_type_id`, `island_objects` e `island_object_tiles`, e `island_buildings` e `island_building_tiles` renomeadas para `island_actions` e `island_action_tiles`.
- O catálogo (`GET /v1/catalog`) com as tabelas novas, e o `catalog_schema.gd` e o `CatalogValidator` acompanhando.
- O rascunho, as conferências de salvar e de publicar, as rotas do editor e o mapa de uma ilha no formato do [contrato](architecture.md#o-contrato).
- O bloqueio nas áreas de Ecobeasts e na chegada.
- No jogo: `actions` no lugar de `buildings`, e o chão e os objetos lidos e guardados no `ExplorationMap`.
- No editor: a ferramenta Construção vira **Ação**, e o rascunho guarda e devolve o chão e os objetos sem perder nada.

## Fora do escopo

- Desenhar trilhas, pisos e objetos, e as ferramentas de pintar ([02](02-grounds.md) e [03](03-map-objects.md)).
- O Domador respeitando o bloqueio no jogo ([03](03-map-objects.md)).

## Requisitos

### Catálogo

- **RF-01:** `ground_types` tem as 4 linhas e `map_object_types` as 17 do [architecture.md](architecture.md#o-catálogo), com os formatos em `map_object_type_tiles`. As linhas entram pela migration, porque o banco já está carregado e o seed só enche tabela vazia, e também nos JSON de `server/prisma/seed-data/`, para um banco novo.
- **RF-02:** `building_types` passa a se chamar `action_types`, com os mesmos ids, slugs, nomes e cores, e a coluna `kind`, com `CHECK` em `open_screen`, preenchida com `open_screen` nas 4 linhas.
- **RF-03:** `GET /v1/catalog` manda `ground_types`, `map_object_types`, `map_object_type_tiles` e `action_types`, e não manda mais `building_types`. O `CatalogValidator` confere as FKs e os `CHECK` delas, como confere as outras.

### A ilha

- **RF-04:** `island_buildings` e `island_building_tiles` passam a se chamar `island_actions` e `island_action_tiles`, com `action_type_id` e `action_id`. Os dados das ilhas que existem ficam como estão, e o `content_hash` de cada versão é recalculado depois, como na [terrain-height/01](../terrain-height/01-terrain-height.md) (`server/prisma/recompute-island-hashes.ts`).
- **RF-05:** `island_tiles` ganha `ground_type_id`, nulo. `island_objects` e `island_object_tiles` seguem o [architecture.md](architecture.md#as-tabelas-da-ilha).
- **RF-06:** a rota de salvar aceita e devolve `ground`, `objects` e `actions` como no [contrato](architecture.md#o-contrato), e recusa com `400` o que as [conferências](architecture.md#conferências-ao-salvar-400) recusam, com a mensagem em pt-BR. Um corpo com `buildings` é recusado por não ter `actions`.
- **RF-07:** publicar recusa com `409` "A chegada não pode ficar num hexágono bloqueado." quando a chegada é de um objeto com `blocks`.
- **RF-08:** o `canonicalDraft` inclui o `ground` de cada hexágono, os objetos em ordem de `(r, q)` do apoio, cada um com os hexágonos em ordem de `(r, q)`, e as ações no lugar das construções.

### Regras

- **RF-09:** nas ilhas, nenhum Ecobeast nasce num hexágono bloqueado nem num de ação.
- **RF-10:** o mapa sorteado manda `objects: []`, `actions: []` e nenhum `ground`.

### Jogo e editor

- **RF-11:** `MapBuilding` vira `MapAction` (`action_type_id`, `tiles`), e o `ExplorationMap` ganha `ground` em cada `HexTile` (o slug, ou vazio), `objects` (`MapObject`: `object_type_id`, `coord`, `variant`, `mirrored`, os hexágonos e o bloqueio de cada um), `action_at(coord)`, `object_at(coord)` e `is_blocked(coord)`.
- **RF-12:** a tela de exploração faz com as ações tudo o que faz hoje com as construções: a cor e o nome por cima, e abrir a tela de `ACTION_SCREENS` ao entrar de fora.
- **RF-13:** no editor, a ferramenta Construção passa a se chamar **Ação**, e o painel e a camada "Construções" passam a "Ações", com o mesmo funcionamento. O `IslandDraft` lê e manda de volta o `ground` de cada hexágono e os `objects` sem mudar nada neles.

## Critérios de aceite

- [x] As ilhas que existem abrem iguais no editor e em Ilhas, com o Refúgio e a Loja abrindo as telas.
- [x] A lista do editor mostra as ilhas publicadas e sem mudança como "Publicada".
- [x] `GET /v1/catalog` traz as 4 tabelas, e o jogo abre sem "Erro nos dados do jogo".
- [x] Salvar um rascunho com chão, um objeto espelhado com bloqueio trocado e uma ação, e ler de volta, devolve o mesmo conteúdo.
- [x] As rotas recusam:
  - um `ground` desconhecido;
  - um objeto sem hexágonos ou sem o hexágono de apoio;
  - dois objetos no mesmo hexágono;
  - um objeto fora da ilha;
  - uma variante abaixo de 1;
  - um corpo sem `actions`.
- [x] Publicar recusa a chegada num hexágono bloqueado.
- [x] O teste das áreas confere que ninguém nasce em hexágono bloqueado nem de ação.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.
- [x] O projeto abre sem erros nem avisos de script novos.

## Desenho técnico

**Servidor**

- `server/prisma/schema.prisma` e a migration `<data>_island_villages`, escrita à mão com `ALTER TABLE ... RENAME` para as tabelas renomeadas, os `CHECK` comentados no schema e os `INSERT` das linhas iniciais. Ela é aplicada com `prisma migrate deploy`, como na terrain-height.
- `server/prisma/seed-data/`: `building_types.json` vira `action_types.json`, com `kind`; mais `ground_types.json`, `map_object_types.json` e `map_object_type_tiles.json`.
- `server/src/catalog/catalog-tables.ts`: as tabelas novas e a renomeada.
- `server/src/domain/islands/island-draft.ts`:
  - `DraftTile.ground`, `DraftObject` e `DraftAction`;
  - as conferências e o `canonicalDraft`;
  - `KnownIds` com os tipos de chão, de objeto (com o formato) e de ação.
- `server/src/domain/islands/area-spawns.ts`: tira os hexágonos de ação e os bloqueados.
- `server/src/editor/islands-editor.dto.ts`, `islands-editor.service.ts`, `server/src/islands/islands.service.ts`, `server/src/exploration/exploration.dto.ts` e `exploration.service.ts`: o formato novo.
- Os testes unitários e os e2e que falam de construções, e os novos dos requisitos.

**Jogo**

- `res://core/data/catalog_schema.gd`: as tabelas novas e a renomeada.
- `res://domain/models/`:
  - `map_building.gd` vira `map_action.gd`;
  - novo `map_object.gd`;
  - `hex_tile.gd` com `ground`;
  - `exploration_map.gd` com o que a RF-11 pede.
- `res://screens/exploration/exploration_screen.gd`: `ACTION_SCREENS` e as ações.
- `res://tools/map_editor/`: `building_panel.gd` vira `action_panel.gd`; mais `editor_tools.gd`, `editor_canvas.gd`, `editor_history.gd`, `island_draft.gd` e `map_editor.gd`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

Antes da migration, copie as tabelas das ilhas e de `building_types` para um JSON fora do repositório. Depois, compare as ações com as construções de antes.

Uma cena temporária em `res://zz_tmp_check/` confere a leitura de um mapa com chão, objetos e ações no `ExplorationMap` e no `IslandDraft`, ida e volta. Depois, a pasta é apagada.

Passos no editor (F2) e em Ilhas: abrir as ilhas que existem, pintar uma ação, salvar, publicar e entrar no Refúgio e na Loja.

## Tarefas

- [x] Cópia de antes; migration, `schema.prisma`, seed-data e catálogo.
- [x] Rascunho, conferências e áreas, com os testes unitários.
- [x] DTOs, serviços e e2e; recalcular o `content_hash`.
- [x] Jogo: catálogo, modelos e tela de exploração.
- [x] Editor: Ação e o rascunho com chão e objetos.
- [x] Verificação; atualizar `map-editor/architecture.md`, `islands/architecture.md`, `game-data/architecture.md` e `client/CLAUDE.md`; marcar esta spec e as tabelas como `concluída`.

## Decisões da implementação

- **O formato fica no editor, e não no servidor:** depois da revisão do planejamento, o servidor guarda os hexágonos que o objeto ocupa e só confere o apoio, a ilha e a sobreposição. Por isso não há `objectTiles` no servidor. O formato do tipo é aplicado pelo editor ao pôr o objeto (`ObjectPanel.footprint`).
- **Migration à mão:** `20261112000000_island_villages`, aplicada com `prisma migrate deploy`. As tabelas antigas foram renomeadas, e não recriadas, com chaves, índices, FKs e sequências renomeados também. As linhas iniciais entram por `INSERT`, com os ids da ordem do [architecture.md](architecture.md#os-tipos-de-objeto). Depois, o `prisma migrate diff` não mostrou diferença entre o banco e o `schema.prisma`.
- **Cópia e conferência:**
  - antes da migration, as tabelas das ilhas e de `building_types` foram copiadas para um JSON fora do repositório;
  - as 26 construções das 3 versões viraram ações com os mesmos ids e hexágonos;
  - o `content_hash` das 3 versões foi recalculado com `npx tsx prisma/recompute-island-hashes.ts`;
  - a ilha publicada continuou com o rascunho igual à publicada.
- **Contagem de tabelas:** o catálogo passa de 32 para 35 tabelas, e o schema `ecobeasts` de 46 para 51. Os testes que contam foram atualizados.
- **Verificação:** `npm run lint`, `npm run typecheck`, os 776 testes unitários e a suíte e2e inteira passaram. Uma cena temporária, já apagada, conferiu:
  - o catálogo baixado pelo jogo contra o servidor local, sem erro do `CatalogValidator`;
  - a ida e volta de chão, objetos e ações no `ExplorationMap` e no `IslandDraft`;
  - o desfazer com o chão.
- **Objetos gravados em lote (correção, 2026-11-11):** a primeira versão gravava cada objeto com o `create` dele e os hexágonos dele, duas idas ao Supabase por objeto. A Vila de Ventoverde, com 296 objetos, passou dos 60 s da transação ao salvar. Agora os objetos entram num `createManyAndReturn`, e cada id é achado pelo hexágono de apoio, que é só daquele objeto; os hexágonos dos objetos entram num `createMany`. Salvar a mesma ilha pelo serviço do editor levou 6,7 s, e a leitura depois do salvamento deu os mesmos objetos e hexágonos.

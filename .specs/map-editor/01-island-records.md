# 01. Ilhas no servidor

- **Status:** concluída
- **Depende de:** [architecture.md](architecture.md)

## Contexto

O servidor não guarda mapas: cada exploração gera um com `generateMap(seed, config)` (`server/src/domain/exploration/map-generator.ts`) e guarda na memória só os Ecobeasts, os Domadores e a posição (`ExplorationStore`). Esta fase cria o lugar das ilhas no banco e as rotas que o editor das fases 02 a 04 usa. O jogador não vê nada disto ainda.

O que esta fase reaproveita:

- O catálogo (`server/src/catalog/catalog-tables.ts`, `GET /v1/catalog`) e, no jogo, o `CatalogSchema` e o `CatalogValidator` (`res://core/data/`), que já recebem tabelas simples de texto como `npc_tamer_names`.
- O `AuthGuard` e o `@CurrentUser()` (`server/src/auth/`).
- As rotas de depuração que respondem 404 "Rota não encontrada." quando uma variável do `.env` está desligada (`ExplorationService.requireTestRoutes`).
- O `generateMap` e o `DEFAULT_MAP_CONFIG`.

## Escopo

- As tabelas `building_types` (catálogo), `islands`, `island_maps`, `island_tiles`, `island_buildings`, `island_building_tiles`, `island_areas` e `island_area_species`, com os `CHECK`.
- `building_types` no catálogo e no jogo (só o schema e o validador; nenhuma tela o usa nesta fase).
- `MAP_EDITOR_USER_IDS` e o `EditorGuard`.
- As conferências do rascunho, puras, com testes.
- As 8 rotas de `/v1/editor`.

## Fora do escopo

- O editor no jogo (fases 02 a 04).
- A rota do jogador que lê as ilhas publicadas (a `islands`).

## Requisitos

### Banco

- **RF-01:** o `schema.prisma` ganha os modelos das 8 tabelas, com as colunas, as chaves, os únicos e as FKs da [arquitetura](architecture.md#tabelas), cada um com `@@schema("ecobeasts")`.
- **RF-02:** a migração cria as tabelas e escreve à mão os `CHECK` da arquitetura: `slug` e `color_hex` de `building_types`; `kind`, o tamanho de `name` de `island_maps`; `shape` e `variant` de `island_tiles`; o `name` e o `color_hex` de `island_areas`; o `weight` e os níveis de `island_area_species`. Cada um fica comentado no campo com `/// CHECK <faixa> (migration <nome>)`.
- **RF-03:** `server/prisma/seed-data/building_types.json` traz os 4 tipos de construção (Refúgio, Loja, Arena, Casa, com as cores _a revisar_), e o `npm run db:seed` os carrega na tabela vazia. É o caminho que `biomes` e `npc_tamer_names` fizeram; a spec dizia que a migração os inseria, mas o seed só carrega tabelas vazias e o teste do catálogo exige o arquivo, então o seed basta.

### Catálogo

- **RF-04:** `building_types` entra no `GET /v1/catalog` (`catalog-tables.ts`) e no `CatalogSchema` e no `CatalogValidator` do jogo, que conferem `slug`, `name` e `color_hex`. O jogo continua abrindo sem erro nos dados.

### Quem edita

- **RF-05:** o `.env` aceita `MAP_EDITOR_USER_IDS`, opcional, uma lista de uuids separados por vírgula (espaços em volta ignorados). O `.env.example` traz o nome vazio, com um comentário.
- **RF-06:** o `EditorGuard` responde 404 "Rota não encontrada." quando a lista está vazia e 403 "Só quem edita o mapa pode usar esta rota." quando o usuário do token não está nela. Ele roda depois do `AuthGuard`, então sem token a resposta continua sendo 401.

### Rotas

- **RF-07:** as conferências de salvar e de publicar da [arquitetura](architecture.md#conferências-ao-salvar-400-mensagem-em-pt-br) ficam em `server/src/domain/islands/island-draft.ts`, como funções puras que devolvem a primeira mensagem de erro ou nada.
- **RF-08:** as 8 rotas da [arquitetura](architecture.md#rotas), com a tag "Editor de ilhas" no `/docs`, todas com `@UseGuards(AuthGuard, EditorGuard)`.
- **RF-09:** criar, salvar e publicar gravam numa transação só. Salvar troca todas as linhas do rascunho; publicar troca todas as da versão publicada por uma cópia do rascunho e grava `published_at`.
- **RF-10:** o `status` vem de comparar o `content_hash` do rascunho com o da publicada. O hash é o sha-256 do rascunho em JSON canônico: chaves em ordem, hexágonos em ordem de `(r, q)`, construções na ordem do corpo, cada uma com os hexágonos em `(r, q)`, áreas na ordem da `key`. Salvar o mesmo rascunho de novo dá o mesmo hash.
- **RF-11:** as rotas do editor aceitam corpo JSON de até 5 MB. As outras continuam com o limite de hoje.
- **RF-12:** `POST /v1/editor/map-generator` valida as faixas de `config` da arquitetura (400 fora delas), completa com o `DEFAULT_MAP_CONFIG` e devolve `{start, tiles}` do `generateMap`, sem gravar nada. `GET /v1/editor/map-generator` devolve o `DEFAULT_MAP_CONFIG` e as faixas, que moram numa constante só, usada pela validação e pela resposta.

## Critérios de aceite

- [x] A migração roda no banco do `.env`, e o `GET /v1/catalog` traz os 4 tipos de construção.
- [x] Com `MAP_EDITOR_USER_IDS` vazia, toda rota do editor responde 404. Com outro usuário, 403.
- [x] Criar uma ilha e ler de volta devolve o mesmo rascunho, com `status` `draft`.
- [x] Publicar uma ilha válida muda o `status` para `published`. Salvar uma mudança muda para `changed`, e salvar o rascunho igual ao publicado volta para `published`.
- [x] Salvar com hexágono repetido, chegada fora da ilha, construção sobre outra ou área inexistente responde 400 com a mensagem certa.
- [x] Publicar com a chegada na água responde 409.
- [x] Uma ilha publicada não pode ser apagada; uma que nunca foi, pode.
- [x] O gerador com a mesma seed e os mesmos parâmetros devolve os mesmos hexágonos, e mudar `water_fraction` muda a quantidade de água.
- [x] Um rascunho de 20.000 hexágonos é salvo e lido.
- [x] O jogo abre sem erro nos dados.
- [x] Testes, lint e typecheck passam.

## Desenho técnico

Arquivos novos:

- `server/prisma/migrations/<data>_islands/migration.sql`: as tabelas e os `CHECK`.
- `server/prisma/seed-data/building_types.json`.
- `server/src/domain/islands/island-draft.ts` e `.spec.ts`: as conferências de salvar e de publicar, e o JSON canônico do hash.
- `server/src/domain/exploration/map-config.spec.ts`: as faixas dos parâmetros (`MAP_CONFIG_RANGES`, `mapConfigError` e `withDefaults`, em `map-config.ts`).
- `server/src/editor/editor.guard.spec.ts`.
- `server/src/editor/`: `editor.module.ts`, `editor.guard.ts`, `islands-editor.controller.ts`, `islands-editor.service.ts`, `islands-editor.dto.ts` e `map-generator.controller.ts`.
- `server/test/islands-editor.e2e-spec.ts`: os e2e apagam as ilhas que criam, e o que publicam (pelo banco, no fim do teste).

Arquivos alterados:

- `server/prisma/schema.prisma`: os 8 modelos e as relações em `Biome` e `Species`.
- `server/src/config/env.ts` e `server/.env.example`: `MAP_EDITOR_USER_IDS`.
- `server/src/catalog/catalog-tables.ts` e os testes do catálogo: `building_types`.
- `server/src/app.module.ts` e `server/src/app.setup.ts` (o limite do corpo das rotas do editor; o `app.setup` também vale nos testes). O leitor do editor precisa de um nome próprio (`editorBodyParser`): o Nest não põe o leitor de JSON dele quando já existe um middleware chamado `jsonParser`, e as outras rotas ficariam sem corpo.
- `server/package.json`: `express` vira dependência direta (já vinha com o `@nestjs/platform-express`), para o `json()` do limite.
- `server/test/database.e2e-spec.ts`: as tabelas a mais e os `CHECK`.
- `res://core/data/catalog_schema.gd`: `building_types`, com o formato do `slug` e da cor. O `CatalogValidator` confere pelo schema; não precisou de regra própria.
- `server/CLAUDE.md`: a linha de `src/editor/`.

## Verificação

```bash
cd server && npx prisma migrate dev
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

No `.env` local, `MAP_EDITOR_USER_IDS` com o id do dono, e o `/docs` mostra a tag "Editor de ilhas".

Feita em 2026-11-10:
- **Banco:** a migração `islands` foi aplicada no banco do `.env`, e o `db:seed` carregou os 4 tipos de construção (1 tabela, 4 linhas). O `GET /v1/catalog` do servidor local traz 32 tabelas, com `building_types`.
- **Servidor:** `lint` e `typecheck` sem erros. Passaram 786 testes unitários (92 nos arquivos desta fase) e a suíte e2e inteira (447 testes). Entre os e2e estão os 18 de `islands-editor.e2e-spec.ts`, com uma ilha de 19.927 hexágonos, e os 4 novos de `database.e2e-spec.ts` (os `CHECK` e o hexágono de duas construções). A suíte da luta antiga (`test:e2e:legacy`, 128 testes) também passou, porque o `app.setup` vale para todas as rotas.
- **Jogo:** uma cena temporária, já apagada, baixou o catálogo sem erros e leu os 4 tipos.
- **Falta, com o dono:** pôr o próprio id em `MAP_EDITOR_USER_IDS` no `.env` local, antes da [02](02-editor-window.md).

## Tarefas

- [x] Modelos, migração com os `CHECK` e os tipos de construção.
- [x] `building_types` no catálogo e no jogo.
- [x] `MAP_EDITOR_USER_IDS` e o `EditorGuard`.
- [x] As conferências puras, com testes.
- [x] As rotas, com os e2e.
- [x] Rodar a verificação, atualizar o `server/CLAUDE.md` e mudar o status aqui e no README.

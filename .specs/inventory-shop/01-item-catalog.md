# 01. Catálogo de itens

- **Status:** rascunho
- **Depende de:** [battle-screen](../battle-screen/), [heal-station](../heal-station/)

## Contexto

Sem a tabela `items`, `inventory_items` não aponta para nada. Esta fase cria as tabelas, coloca os 6 itens no banco e faz a Mochila aparecer na resposta do jogador. Nenhuma tela muda: a Loja vem na [02](02-shop.md).

## Escopo

- `item_categories`, `items` e a FK de `inventory_items`.
- A carga inicial preenchendo tabelas vazias.
- Os itens em `GET /v1/catalog` e no catálogo do cliente.
- `inventory` no JSON do jogador e no `Player` do cliente.

## Fora do escopo

- Comprar e usar itens.
- Telas.
- Rotas próprias de item no catálogo: o jogo lê tudo de `GET /v1/catalog`.

## Requisitos

- **RF-01:** As tabelas seguem [architecture.md](architecture.md#tabelas), com as restrições `CHECK` escritas à mão na migration e o `slug` no mesmo formato das outras tabelas.
- **RF-02:** `inventory_items.item_id` é uma FK para `items`, com `onDelete: Restrict`.
- **RF-03:** `CATALOG_TABLES` tem 25 tabelas, com `item_categories` e `items` em ordem de dependência.
- **RF-04:** Com tabelas vazias, `npm run db:seed` carrega só essas e informa quantas linhas entraram.
- **RF-05:** Com tudo preenchido, a carga não faz nada e informa isso.
- **RF-06:** A carga nunca altera nem apaga uma linha existente.
- **RF-07:** `GET /v1/catalog` traz as duas tabelas, sem mudar as outras.
- **RF-08:** O JSON do jogador traz `inventory`, em ordem de `item_id`, vazio para quem não tem itens.
- **RF-09:** O `CatalogValidator` confere as duas tabelas e recusa uma FK de categoria inválida.
- **RF-10:** `Player.quantity_of(item_id)` devolve a quantidade, ou 0.

## Critérios de aceite

- [ ] O banco recusa preço 0, `heal_amount` 0 e `capture_bonus` 0.
- [ ] O banco recusa um `inventory_items` com `item_id` que não existe.
- [ ] O banco recusa apagar um item que está na Mochila de alguém.
- [ ] `seedPlan` devolve a lista das tabelas vazias e `skip` com tudo preenchido.
- [ ] `npm run db:seed` no banco atual cria 2 categorias e 6 itens, sem mudar as outras tabelas.
- [ ] Rodar `npm run db:seed` de novo não muda nada.
- [ ] `GET /v1/catalog` devolve 25 tabelas.
- [ ] `GET /v1/me` traz `inventory`, e o item criado no teste aparece nele.
- [ ] O jogo abre com o catálogo novo, sem erros nem avisos de script.
- [ ] `GameData.get_items()` devolve os 6 itens, com o preço do banco.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/prisma/migrations/<data>_items/migration.sql`: tabelas, FK e `CHECK`.
- `server/prisma/seed-data/item_categories.json` e `items.json`.
- `client/domain/models/item.gd`, `item_category.gd` e `inventory_slot.gd`.

**Alterar**

- `server/prisma/schema.prisma`: `ItemCategory`, `Item` e a relação em `InventoryItem`.
- `server/src/catalog/catalog-tables.ts` e `.spec.ts`: 25 tabelas.
- `server/prisma/seed-plan.ts`, `.spec.ts` e `seed.ts`: a lista de tabelas vazias.
- `server/src/player/player.mapper.ts`: `inventory` em `PLAYER_INCLUDE` e em `toPlayerDto`.
- `server/src/player/player.dto.ts`: `InventorySlotDto` e `inventory`.
- `server/test/bundle.e2e-spec.ts`, `seed.e2e-spec.ts` e `database.e2e-spec.ts`: as contagens de tabelas e as restrições novas.
- `client/core/data/catalog_schema.gd`, `catalog.gd` e `client/core/autoload/game_data.gd`.
- `client/domain/models/player.gd`.
- `.specs/game-data/architecture.md`: as tabelas saem de "futuro".
- `.specs/backend-api/03-catalog-seed.md`: o RF-04, com o motivo da mudança.
- `.specs/auth-google/03-player-api.md`: `inventory` no JSON do jogador.
- `.specs/onboarding/architecture.md`: `inventory` no modelo do jogador.

**Reaproveitar**

`createMany` e o acerto de sequências de `prisma/seed.ts`, agora só para as tabelas carregadas. `toStatBlock` não se aplica aqui: `inventory` é uma lista simples.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
cd server && npx prisma migrate deploy && npm run db:seed
godot --headless -d --path client --quit-after 60
```

Os testes não conferem preços nem efeitos, que o dono muda no painel: criam um item próprio dentro da transação.

## Tarefas

- [ ] Testes das restrições e do `seedPlan`; ver falhar.
- [ ] Schema, migration e `CATALOG_TABLES` (RF-01 a RF-03, RF-07).
- [ ] Carga inicial e os JSON (RF-04 a RF-06).
- [ ] `inventory` no jogador (RF-08).
- [ ] Cliente: espelho do catálogo, modelos e `quantity_of` (RF-09, RF-10).
- [ ] Atualizar as specs citadas; marcar esta spec e a tabela do README como `concluída`; commit `feat: catálogo de itens`.

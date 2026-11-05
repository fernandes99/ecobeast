# 01. Técnicas no tabuleiro

- **Status:** concluída
- **Depende de:** [game-data/architecture.md](../game-data/architecture.md), [architecture.md](architecture.md#técnicas-no-tabuleiro)

## Contexto

Hoje uma Técnica não sabe nada de distância: ela mira o adversário ou o próprio Ecobeast (`skill_targets`). No tabuleiro, cada Técnica precisa de alcance, forma, se atravessa os inimigos e uma marca no chão opcional. Esta fase põe isso no catálogo, no banco e no jogo, sem mudar nenhuma luta.

## Escopo

- A tabela `area_shapes`, a tabela `ground_effects` e as colunas novas de `skills`.
- Os valores das 38 Técnicas de hoje, com as 3 primeiras formas.
- O catálogo da API e o do jogo com os campos novos.

## Fora do escopo

- Usar os campos numa luta (vem na [02](02-board-engine.md)).
- Formas além de `single` e `line`, como áreas grandes, empurrar e puxar.
- Mostrar o alcance na tela de detalhes da criatura.

## Requisitos

- **RF-01:** A tabela `area_shapes` (`id`, `slug`, `name`) tem `single` ("Um alvo") e `line` ("Linha reta").
- **RF-02:** A tabela `ground_effects` tem `id`, `slug`, `name`, `damage_percent` (1–100, anulável), `status_condition_id` (FK anulável) e `color_hex`, com pelo menos um efeito preenchido. Ela começa com `fire`, "Chão em chamas", `damage_percent` 6 e cor `#E8622C` (_a revisar_).
- **RF-03:** `skills` ganha `area_shape_id` (FK, padrão `single`), `range` (1–6, padrão 1), `pierces` (padrão falso), `ground_effect_id` (FK anulável) e `ground_turns` (1–20, anulável). `ground_effect_id` e `ground_turns` são nulos juntos ou preenchidos juntos.
- **RF-04:** Todas as Técnicas ficam `single`, alcance 1, sem atravessar e sem marca, menos:
  - **Faísca Rápida** (`faisca_rapida`): `line`, alcance 3, sem atravessar;
  - **Chama Espiral** (`chama_espiral`): `single`, alcance 3, marca `fire` por 6 vezes.
  - **Arranhão** (`arranhao`) fica no padrão, como exemplo de corpo a corpo. Os valores das duas primeiras são _a revisar_.
- **RF-05:** `GET /v1/catalog` traz `area_shapes`, `ground_effects` e os campos novos de cada Técnica.
- **RF-06:** O jogo lê os campos novos na `Skill` e o `GroundEffect`, e o `CatalogValidator` confere as chaves estrangeiras e os valores.

## Critérios de aceite

- [x] A migração aplica sobre o banco de hoje, sem apagar nada, e deixa as tabelas novas preenchidas e as colunas das 38 Técnicas com os valores do RF-04.
- [x] Uma Técnica com `ground_effect_id` e sem `ground_turns` é recusada pelo banco.
- [x] `GET /v1/catalog` traz Faísca Rápida com `area_shape_id` de `line` e `range` 3, e Chama Espiral com `ground_effect_id` de `fire` e `ground_turns` 6.
- [x] O jogo abre com o servidor no ar, sem erro do `CatalogValidator`.
- [x] Nenhuma luta muda: os testes de hoje passam sem ajuste.

## Desenho técnico

**Banco:** uma migração nova em `server/prisma/migrations/`, com os `CHECK` no padrão das outras (comentário `/// CHECK` no `schema.prisma`). As tabelas ficam no schema `ecobeasts`. A carga inicial (`npm run db:seed`) só preenche tabelas vazias, então a própria migração insere as linhas de `area_shapes` e `ground_effects`, cria as colunas com os padrões e faz o `UPDATE` de Faísca Rápida e Chama Espiral pelo `slug`. Assim o banco de hoje fica certo sem perder o que o dono editou pelo painel.

**Seed:** `server/prisma/seed-data/area_shapes.json`, `ground_effects.json` e os campos novos em `skills.json`, iguais ao que a migração grava, para um banco novo.

**API:** `server/src/catalog/catalog-tables.ts` com as duas tabelas. O catálogo inteiro (`GET /v1/catalog`) lê as colunas do banco, então as colunas novas de `skills` chegam sem mais código. O recurso `/v1/skills` e o `server/src/battle/battle-catalog.ts` não mudam nesta fase: o jogo lê o catálogo inteiro, e a luta só usa os campos na [02](02-board-engine.md).

**Jogo:**

- `res://core/data/catalog_schema.gd`: `area_shapes`, `ground_effects` e os campos novos de `skills`.
- `res://domain/models/skill.gd`: `area_shape`, `area_range` (a coluna `range`: o nome `range` esconderia a função `range()` do GDScript), `pierces`, `ground_effect_id` e `ground_turns`.
- `res://domain/models/ground_effect.gd` (novo), e o `GameData` com `get_ground_effect(id)`.

**Specs:** `.specs/game-data/architecture.md` com as tabelas novas.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run typecheck && npm run lint && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

O jogo abre (F5) e chega ao Hub sem a tela "Erro nos dados do jogo".

## Tarefas

- [x] Migração, `schema.prisma` e seed (RF-01 a RF-04).
- [x] Catálogo da API, com um e2e dos campos novos (RF-05).
- [x] Catálogo do jogo e `CatalogValidator` (RF-06).
- [x] Atualizar `.specs/game-data/architecture.md`.
- [x] Rodar a verificação, marcar a spec e o README como `concluída` e fazer o commit `feat: alcance e forma das Técnicas`.

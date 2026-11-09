# 01. Nomes e falas dos Domadores

- **Status:** rascunho
- **Depende de:** [biome-encounters/01](../biome-encounters/01-biome-tables.md) (o mesmo caminho de tabela nova no catálogo), [architecture.md](architecture.md)

## Contexto

Um Domador sorteado precisa de um nome e de uma fala para o desafio. Os dois são dados de design: moram no banco, o dono os edita pelo painel do Supabase, e o mapa e a luta mandam só os ids. É o mesmo caminho que `biomes` fez: o `schema.prisma`, a migration com os `CHECK`, o `seed-data/`, o `CATALOG_TABLES` e o espelho no jogo.

## Escopo

- As tabelas `npc_tamer_names` e `npc_tamer_greetings`, com a carga inicial.
- As duas no `GET /v1/catalog` e no `GameData` do jogo.

## Fora do escopo

- Sortear, mostrar ou usar os textos: vem nas fases 02 a 04.
- A tabela `npc_tamers`, da equipe fixa.
- Os textos no visualizador de conteúdo (F1).

## Requisitos

- **RF-01:** `npc_tamer_names` tem `id` (serial) e `name` (texto, de 1 a 20 caracteres, com `CHECK`).
- **RF-02:** `npc_tamer_greetings` tem `id` (serial) e `text` (texto, de 1 a 120 caracteres, com `CHECK`). A fala é escrita sem o nome na frente.
- **RF-03:** as duas ficam no schema `ecobeasts`, entram em `CATALOG_TABLES` (depois de `evolution_triggers`, já que não têm FK) e chegam ao jogo pelo `GET /v1/catalog`.
- **RF-04:** o jogo lê as duas pelo `GameData`: `get_npc_tamer_name(id) -> String` e `get_npc_tamer_greeting(id) -> String`, com texto vazio para um id que não existe.
- **RF-05:** o `CatalogValidator` aceita as duas tabelas e recusa um catálogo em que alguma delas está vazia, porque um Domador sem nome ou sem fala não pode nascer.

## Critérios de aceite

- [ ] As duas tabelas existem no banco, com os `CHECK`, e o seed as preenche com a carga abaixo.
- [ ] `GET /v1/catalog` traz as duas, com `id` e `name` ou `text`.
- [ ] O jogo abre sem erro, e o `GameData` devolve "Lia" para o id 1 e a fala 1 para o id 1.
- [ ] Apagar todas as falas pelo painel faz o jogo abrir na tela "Erro nos dados do jogo".

## Desenho técnico

### Carga inicial

Todos os textos são _a revisar_. Os nomes são curtos e fáceis de ler em qualquer idioma.

`npc_tamer_names`:

| id | name |
| ---: | --- |
| 1 | Lia |
| 2 | Caio |
| 3 | Bruna |
| 4 | Tomás |
| 5 | Iara |
| 6 | Davi |
| 7 | Nina |
| 8 | Rafael |
| 9 | Luna |
| 10 | Otávio |
| 11 | Maya |
| 12 | Enzo |

`npc_tamer_greetings`:

| id | text |
| ---: | --- |
| 1 | O que está fazendo aqui? Vamos nos enfrentar! |
| 2 | Ei, você! Seus Ecobeasts parecem fortes. Mostre do que eles são capazes! |
| 3 | Ninguém passa por este caminho sem lutar comigo! |

### Arquivos

- `server/prisma/schema.prisma`: modelos `NpcTamerName` e `NpcTamerGreeting`, com `@@map` e `@@schema("ecobeasts")`, e os comentários `/// CHECK`.
- `server/prisma/migrations/<data>_npc_tamer_texts/migration.sql`: criada com `--create-only`, com os `CHECK` escritos à mão (`char_length` entre os limites dos RF).
- `server/prisma/seed-data/npc_tamer_names.json` e `npc_tamer_greetings.json`.
- `server/src/catalog/catalog-tables.ts`: as duas entradas, e o comentário passa de 29 para 31 tabelas.
- `client/core/data/catalog_schema.gd`: as colunas das duas.
- `client/domain/models/`: `NpcTamerName` e `NpcTamerGreeting`, seguindo os modelos de catálogo que já existem, como o `Biome`.
- `client/core/autoload/game_data.gd`: guarda as duas tabelas e os dois `get_*`.
- `client/core/data/catalog_validator.gd`: as tabelas não podem chegar vazias.
- `.specs/game-data/architecture.md`: documenta as duas tabelas.
- `.specs/glossary.md`: a linha do Domador NPC cita as duas tabelas, e `npc_tamers` fica para a equipe fixa.

## Verificação

```bash
cd server && npm run db:migrate && npm run db:seed
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

- Conferir as duas tabelas no Table Editor do Supabase.
- `GET /v1/catalog` em `/docs`: as duas tabelas aparecem.

## Tarefas

- [ ] Modelos, migration com `CHECK` e seed-data.
- [ ] `CATALOG_TABLES` e o teste dele.
- [ ] `catalog_schema.gd`, modelos, `GameData` e `CatalogValidator`.
- [ ] Atualizar `game-data/architecture.md` e o glossário.
- [ ] Rodar a verificação e mudar o status aqui e no README da iniciativa.

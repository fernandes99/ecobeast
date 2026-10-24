# 03. Carga inicial do catálogo

- **Status:** concluída
- **Depende de:** [02-database-schema](02-database-schema.md)

## Contexto

As 28 tabelas existem no Supabase, mas estão vazias. O catálogo de hoje (23 tabelas, 436 linhas) mora em `client/data/*.json`, no formato descrito em [game-data/architecture.md](../game-data/architecture.md#convenções). Esta fase escreve o seed do Prisma, que copia esses arquivos para o banco uma única vez. Depois dele, **o banco é o dono do catálogo** ([README](README.md#decisões)): mudança de valor é feita no banco, e ninguém edita `client/data/` até a [07](07-client-remote-catalog.md), quando os arquivos saem do cliente.

## Escopo

- A lista das tabelas do catálogo em ordem de dependência, compartilhada pelo seed e pelas fases seguintes.
- A conversão de nomes de coluna (`snake_case` ↔ `camelCase`).
- O seed (`npm run db:seed`).

## Fora do escopo

- Dados do jogador (as tabelas do jogador ficam vazias).
- Copiar o catálogo para outro projeto Supabase (produção): é feito copiando o banco de desenvolvimento quando houver deploy.

## Requisitos

- **RF-01:** `server/src/catalog/catalog-tables.ts` exporta `CATALOG_TABLES: readonly CatalogTable[]`, com `CatalogTable = { name: string; model: string; key: readonly string[] }`. `name` é a tabela, `model` é o nome do delegate do Prisma (`elementEfficacy`) e `key` são as colunas da chave, em `snake_case`. As 23 tabelas ficam nesta ordem de dependência: `elements`, `stats`, `growth_rates`, `rarities`, `skill_categories`, `skill_targets`, `skill_learn_methods`, `status_conditions`, `effect_types`, `evolution_triggers`, `element_efficacy`, `temperaments`, `status_condition_immunities`, `traits`, `species`, `species_elements`, `species_stats`, `species_traits`, `skills`, `skill_effects`, `species_skills`, `evolutions`, `starter_options`. O arquivo também exporta `SEED_DATA_DIR`, o caminho absoluto de `client/data/`, calculado a partir do próprio arquivo.
- **RF-02:** `server/src/common/case.ts` exporta `snakeToCamelKeys(row: Record<string, unknown>): Record<string, unknown>` e `camelToSnakeKeys(row: Record<string, unknown>): Record<string, unknown>`. Elas trocam só os nomes das chaves e mantêm os valores e a ordem.
- **RF-03:** `server/prisma/seed.ts` roda pelo `prisma db seed` (configurado no `package.json` ou no `prisma.config.ts`), chamado por `npm run db:seed`.
- **RF-04:** Antes de inserir, o seed conta as linhas de cada tabela do catálogo:
  - todas vazias: carrega;
  - todas com linhas: imprime `Banco já tem catálogo; nada foi feito.` e sai com código 0;
  - umas vazias e outras não: imprime `Catálogo incompleto no banco (<tabelas com linhas>); nada foi feito.` e sai com código 1.
  
  Ele nunca apaga nem sobrescreve linhas.
- **RF-05:** A carga lê `<SEED_DATA_DIR>/<tabela>.json` na ordem do RF-01 e insere numa única transação. Cada linha passa por `snakeToCamelKeys`. `species` entra em duas etapas: primeiro todas as linhas com `evolves_from_species_id = null`, depois um update com o valor de cada uma. Assim a ordem dos arquivos não importa para a autorreferência.
- **RF-06:** Ainda na transação, as sequências das 16 tabelas com `id` são ajustadas para o maior id (`setval(pg_get_serial_sequence('ecobeasts.<tabela>', 'id'), max(id))`). Uma linha criada depois no painel ganha o id seguinte.
- **RF-07:** Sucesso imprime `Catálogo carregado: 23 tabelas, 436 linhas` (os números contados do que foi inserido) e sai com código 0. Qualquer erro (arquivo ausente, JSON inválido, `CHECK` ou FK recusado) desfaz a transação, imprime `Falha na carga do catálogo: <tabela>: <motivo>` e sai com código 1.

## Critérios de aceite

- [x] Com o banco vazio, `npm run db:seed` imprime `Catálogo carregado: 23 tabelas, 436 linhas`.
- [x] Rodar `npm run db:seed` de novo imprime `Banco já tem catálogo; nada foi feito.`, e nada muda no banco.
- [x] No painel do Supabase, `species` tem as 9 espécies com os mesmos ids e nomes dos JSON. Brasalobo (`id` 2) tem `evolves_from_species_id` 1.
- [x] Criar uma `growth_rates` nova pelo painel, sem informar o `id`, gera o id seguinte ao maior existente. (Conferido por um teste e2e numa transação desfeita; o dono pode repetir pelo painel.)
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/catalog/catalog-tables.ts` (RF-01).
- `server/src/common/case.ts` e `case.spec.ts` (RF-02).
- `server/prisma/seed.ts` (RF-03 a RF-07). A lógica de decisão do RF-04 fica numa função pura, `seedPlan(counts: Record<string, number>): 'load' | 'skip' | { incomplete: string[] }`, testada sem banco.
- `server/test/seed.e2e-spec.ts`: depois do seed, toda linha de cada JSON existe no banco com a mesma chave. O teste confere só a presença das chaves, não a igualdade de tabela inteira, para continuar valendo quando o dono acrescentar linhas ou mudar valores.

**Alterar**

- `server/package.json` (ou `prisma.config.ts`): o comando do seed.

**Reaproveitar**

- O formato dos JSON e a contagem de 436 linhas do validador do cliente ([game-data/03](../game-data/03-starter-content.md)).

## Verificação

Da pasta `server/`:

```bash
npm run db:seed      # 1ª vez: carregado; 2ª vez: nada foi feito
npm test
npm run test:e2e
```

## Tarefas

- [x] `case.ts` com testes: `{ growth_rate_id: 2, slug: 'a' }` ↔ `{ growthRateId: 2, slug: 'a' }`; a ordem das chaves é mantida.
- [x] `catalog-tables.ts` (RF-01); teste de unidade: 23 nomes, sem repetição, iguais aos nomes dos arquivos `.json` de `SEED_DATA_DIR`. A ordem de dependência é provada pelo próprio seed, que falharia numa FK.
- [x] `seedPlan` com testes: tudo 0 → `load`; tudo > 0 → `skip`; misto → `incomplete` com os nomes das tabelas não vazias.
- [x] `seed.ts` (RF-04 a RF-07); rodar no banco de desenvolvimento.
- [x] `seed.e2e-spec.ts`.
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: carga inicial do catálogo`.

## Decisões da implementação

- **`model` explícito em `CATALOG_TABLES`:** o delegate do Prisma é o nome do modelo, no singular (`elements` → `element`), e não o da tabela. Um teste confere que cada `model` existe no cliente gerado.
- **`seedPlan` em `prisma/seed-plan.ts`:** fica num arquivo separado do `seed.ts`, que executa ao ser importado, para o teste de unidade importar a função sem rodar o seed.
- **O seed conecta pela `DIRECT_URL`,** como a CLI, e roda pelo `tsx` (comando `seed` do `prisma.config.ts`). A transação tem um limite de 120 s, porque o padrão de 5 s do Prisma é curto para 436 linhas pela rede.
- **Sequências:** um teste e2e cria uma curva de XP sem id numa transação desfeita e confere que ela recebe um id maior que o maior existente.
- **Testes de unidade** passam a incluir `prisma/**/*.spec.ts` (`vitest.config.ts`).

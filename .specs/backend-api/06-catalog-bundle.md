# 06. Catálogo inteiro

- **Status:** concluída
- **Depende de:** [05-catalog-api](05-catalog-api.md)

## Contexto

As rotas por recurso servem para explorar o catálogo, mas o jogo precisa de tudo ao abrir. Cem chamadas seriam lentas e gastariam o limite por IP. Esta fase cria `GET /v1/catalog`: as 23 tabelas numa resposta só, no **mesmo formato dos arquivos `client/data/*.json`** que o Godot já sabe ler, com uma versão para o jogo só baixar de novo quando algo mudar ([architecture.md](architecture.md#catálogo-inteiro-get-v1catalog)). A [07](07-client-remote-catalog.md) usa esta rota.

## Escopo

- `GET /v1/catalog` com versão, `ETag`, `304` e cache em memória de 60 segundos.

## Fora do escopo

- Compressão além da que o Nest ou o proxy já fazem.
- Avisar o jogo em tempo real quando o catálogo muda.

## Requisitos

- **RF-01:** `GET /v1/catalog` devolve `{ "version": "<sha256 em hex>", "tables": { "<tabela>": [linhas] } }` com as 23 tabelas de `CATALOG_TABLES` ([03](03-catalog-seed.md)).
- **RF-02:** Cada linha tem exatamente as colunas da tabela, em `snake_case` e na ordem dos campos do modelo (a mesma dos JSON). Os valores vêm do banco sem transformação: `int` como inteiro, `float` como número, `null` como `null`. As linhas vêm em ordem crescente da chave (`key` de `CATALOG_TABLES`). Cada linha passa por `camelToSnakeKeys` ([03](03-catalog-seed.md)).
- **RF-03:** `catalogVersion(tables: Record<string, Record<string, unknown>[]>): string` devolve o SHA-256, em hex, do `JSON.stringify` das tabelas com os nomes em ordem alfabética e as linhas como no RF-02. A mesma entrada dá sempre a mesma versão, e qualquer valor diferente dá outra.
- **RF-04:** A resposta tem o cabeçalho `ETag: "<version>"`, com aspas. Uma requisição com `If-None-Match` igual a esse valor recebe `304`, sem corpo.
- **RF-05:** O servidor guarda as tabelas e a versão em memória por 60 segundos (`CATALOG_CACHE_TTL_MS = 60_000`). Depois disso, a chamada seguinte lê o banco de novo. Uma mudança feita no painel aparece em até 1 minuto.
- **RF-06:** A rota fica na tag "Catálogo" da Scalar, com a descrição em pt-BR: o que devolve, para que serve (o jogo baixa ao abrir) e como usar o `If-None-Match`.

## Critérios de aceite

- [x] `GET /v1/catalog` devolve `200` com 23 tabelas, e a contagem total de linhas é igual à soma do `count()` das 23 tabelas.
- [x] Para cada tabela, toda linha tem exatamente o mesmo conjunto de colunas que as linhas do arquivo correspondente em `client/data/`.
- [x] O cabeçalho `ETag` é igual a `"` + `version` + `"`.
- [x] Repetir a chamada com `If-None-Match` igual ao `ETag` devolve `304`, sem corpo.
- [ ] Mudar o `name` de uma espécie no painel, esperar 1 minuto e chamar de novo devolve outra `version`, com o nome novo. (Passo do dono; desfazer depois. O teste de unidade do cache cobre a releitura depois de 60 s.)
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/catalog/bundle/bundle.module.ts`, `bundle.controller.ts`, `bundle.service.ts` e `catalog-version.ts` (`catalogVersion`), com `catalog-version.spec.ts`.
- `server/test/bundle.e2e-spec.ts`. Para comparar com os JSON, ele lê os arquivos de `SEED_DATA_DIR` ([03](03-catalog-seed.md)).

**Alterar**

- `server/src/app.module.ts`: `BundleModule`.

**Reaproveitar**

- `CATALOG_TABLES` e `SEED_DATA_DIR` (`server/src/catalog/catalog-tables.ts`), `camelToSnakeKeys` (`server/src/common/case.ts`).

## Verificação

Da pasta `server/`:

```bash
npm test
npm run test:e2e
curl -i http://localhost:3100/v1/catalog | head -20
```

## Tarefas

- [x] `catalogVersion` com testes:
  - a mesma entrada dá a mesma versão;
  - trocar um valor muda a versão;
  - as mesmas tabelas em outra ordem de chaves no objeto dão a mesma versão;
  - o resultado é uma string hex de 64 caracteres.
- [x] e2e dos critérios (formato, contagem, colunas iguais às dos JSON, `ETag`, `304`); rodar e ver falhar.
- [x] `BundleService` (RF-01, RF-02, RF-05) e `BundleController` (RF-04); os e2e passam.
- [x] Teste de unidade do cache: duas chamadas em menos de 60 s leem o banco uma vez só (com o Prisma substituído por um dublê que conta as leituras e um relógio controlado).
- [x] Documentação (RF-06).
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: catálogo inteiro na API`.

## Decisões da implementação

- **O cache guarda a leitura em andamento**, não só o resultado. Chamadas que chegam ao mesmo tempo, com o cache vazio, esperam a mesma leitura do banco em vez de fazer uma cada. Se a leitura falhar, ela sai do cache e a chamada seguinte tenta de novo. Os dois casos têm teste de unidade. O relógio do teste é o `Date` falso do Vitest (`vi.useFakeTimers`), sem relógio injetado no serviço.
- **`304` pelo `req.fresh` do Express**, que compara o `If-None-Match` com o `ETag` da resposta. Além do valor exato (RF-04), ele aceita uma lista de valores e o prefixo `W/`, que um proxy pode acrescentar. O controller usa `@Res()` para escrever o cabeçalho e o `304` diretamente.
- **As 23 tabelas são lidas em paralelo**, sem uma transação em volta. Uma edição feita no painel bem no meio da leitura pode sair pela metade numa versão; a leitura seguinte, em até 60 s, corrige.
- **Ordem das colunas:** o e2e confere, além do conjunto, a mesma ordem dos JSON, que é a ordem dos campos no `schema.prisma`.
- **Tamanho:** com o catálogo atual (436 linhas), a resposta tem cerca de 44 KB.

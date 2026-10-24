# 04. Rotas de espécies

- **Status:** rascunho
- **Depende de:** [03-catalog-seed](03-catalog-seed.md)

## Contexto

O banco tem o catálogo. Esta fase cria as peças que todo recurso da API usa (paginação, referência, busca por id ou slug, erros e limite de chamadas) e as rotas de espécies, que estreiam o padrão da PokeAPI descrito em [architecture.md](architecture.md#api). A [05](05-catalog-api.md) repete o padrão para os demais recursos.

## Escopo

- `common/`: paginação, referência, id ou slug, limite de chamadas.
- `GET /v1/species`, `GET /v1/species/{idOrSlug}`, `GET /v1/species/{idOrSlug}/skills`, `GET /v1/species/{idOrSlug}/evolutions`.
- A documentação dessas rotas na Scalar.

## Fora do escopo

- Os outros recursos ([05](05-catalog-api.md)) e o catálogo inteiro ([06](06-catalog-bundle.md)).
- Busca por nome, filtros e ordenação diferente de `id`.

## Requisitos

**Peças comuns** (`server/src/common/`)

- **RF-01:** `PaginationQueryDto` tem `limit` (inteiro de 1 a 100, padrão 20) e `offset` (inteiro ≥ 0, padrão 0). Um valor inválido (`abc`, `0`, `101`, `-1`) responde `400`, com `message` em pt-BR: "limit deve ser um inteiro de 1 a 100" ou "offset deve ser um inteiro maior ou igual a 0".
- **RF-02:** `page(path: string, total: number, query: PaginationQueryDto, results: T[]): Page<T>` monta `{ count, next, previous, results }`:
  - `next` é `<path>?limit=<limit>&offset=<offset+limit>` quando `offset + limit < total`, e `null` nos outros casos;
  - `previous` é `<path>?limit=<limit>&offset=<max(offset−limit, 0)>` quando `offset > 0`, e `null` nos outros casos;
  - um `offset` além do total devolve `results: []`, com `count` igual ao total.
- **RF-03:** `ref(resource: string, row: { id: number; slug: string; name: string }): ResourceRef` devolve `{ id, slug, name, url: "/v1/<resource>/<id>" }`.
- **RF-04:** `parseIdOrSlug(param: string): { id: number } | { slug: string }` trata só dígitos como id e o resto como slug, em minúsculas (`FAGULHO` → `fagulho`). Um recurso que não existe responde `404` com `message` "<Recurso> não encontrado: <param>" (ex.: "Espécie não encontrada: xyz").
- **RF-05:** O `@nestjs/throttler` vale para todas as rotas, com limite de `THROTTLE_LIMIT` chamadas (do config, padrão 100) por 60 segundos por IP. Acima disso, responde `429`. Os testes e2e sobem a aplicação com `THROTTLE_LIMIT=10000`, para não esbarrar no limite, menos o teste do próprio limite.

**Espécies** (`server/src/catalog/species/`)

- **RF-06:** `GET /v1/species` lista as espécies em ordem de `id`, paginadas (RF-01, RF-02), com uma referência (RF-03) por espécie.
- **RF-07:** `GET /v1/species/{idOrSlug}` devolve `id`, `slug`, `name`, `description`, `height_m`, `weight_kg`, `gender_ratio`, `capture_rate`, `base_xp_yield` e mais:
  - `growth_rate`, `rarity` e `evolves_from`: referências; `evolves_from` é `null` quando não há;
  - `elements`: `[{ slot, element }]`, por `slot`;
  - `stats`: `[{ stat, base_value, training_yield }]`, por `id` do stat;
  - `traits`: `[{ slot, is_hidden, trait }]`, por `slot`.
- **RF-08:** `GET /v1/species/{idOrSlug}/skills` devolve `{ species, skills: [{ skill, learn_method, level }] }`, ordenado por método (`id`), nível (com `null` no fim) e Técnica (`id`).
- **RF-09:** `GET /v1/species/{idOrSlug}/evolutions` devolve a linha de Ascensão inteira da espécie pedida, a partir da espécie que não ascende de nenhuma outra. O formato é `{ chain: Node }`, com `Node = { species, evolves_to: [{ trigger, min_level, min_bond, time_of_day, item_id, zone_id, node: Node }] }`. Pedir Fagulho, Brasalobo ou Infernolobo devolve a mesma linha.
- **RF-10:** Cada rota tem no OpenAPI um resumo e uma descrição em pt-BR, os parâmetros e o formato de resposta (DTOs com `@ApiProperty`), com Fagulho como exemplo. As respostas `400`, `404` e `429` também são documentadas. A tag é "Espécies".

## Critérios de aceite

- [ ] `GET /v1/species` devolve `count` igual ao número de linhas de `species`, `results` com os ids em ordem crescente e `previous` igual a `null`.
- [ ] `GET /v1/species?limit=2&offset=2` devolve 2 resultados, `next` igual a `/v1/species?limit=2&offset=4` e `previous` igual a `/v1/species?limit=2&offset=0`.
- [ ] `limit=0`, `limit=101`, `limit=abc` e `offset=-1` devolvem `400` com a mensagem em pt-BR.
- [ ] `GET /v1/species/1`, `/v1/species/fagulho` e `/v1/species/FAGULHO` devolvem o mesmo corpo.
- [ ] `GET /v1/species/9999` e `/v1/species/xyz` devolvem `404`, com "Espécie não encontrada: …".
- [ ] `GET /v1/species/3` tem `elements` com `fire` no `slot` 1 e `shadow` no `slot` 2, e `evolves_from.id` igual a 2.
- [ ] `GET /v1/species/1/skills` tem pelo menos uma entrada com `learn_method.slug` igual a `level_up` e `level` igual a 1.
- [ ] `GET /v1/species/2/evolutions` tem `chain.species.id` igual a 1, `chain.evolves_to[0].node.species.id` igual a 2 e o nó seguinte com id 3, e `trigger.slug` igual a `level`.
- [ ] As quatro rotas aparecem na Scalar em `/docs`, na tag "Espécies", e dá para testar `GET /v1/species/1` por lá.
- [ ] `npm run lint`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/common/pagination.ts` (DTO e `page`), `resource-ref.ts` (`ref`, `ResourceRef`), `id-or-slug.ts` (`parseIdOrSlug`), com testes `.spec.ts`.
- `server/src/catalog/species/species.module.ts`, `species.controller.ts`, `species.service.ts` e `dto/` (os formatos dos RF-07 a RF-09).
- `server/test/species.e2e-spec.ts`.

**Alterar**

- `server/src/app.module.ts`: `ThrottlerModule` (com `ThrottlerGuard` global) e `SpeciesModule`.
- `server/src/main.ts`: `ValidationPipe` global com `transform: true`.

## Verificação

Da pasta `server/`:

```bash
npm test
npm run test:e2e
npm run start:dev   # e testar as rotas pela Scalar em http://localhost:3000/docs
```

## Tarefas

- [ ] `page` com testes: total 9, limit 2, offset 2 → next `offset=4`, previous `offset=0`; offset 8 → next `null`; offset 20 → `results: []`, previous `offset=18`.
- [ ] `parseIdOrSlug` com testes: `"1"` → `{ id: 1 }`; `"fagulho"` → slug; `"FAGULHO"` → slug `fagulho`; `"1a"` → slug.
- [ ] `ref` e `PaginationQueryDto` (com as mensagens do RF-01).
- [ ] e2e das rotas de espécies (critérios acima); rodar e ver falhar.
- [ ] `SpeciesService` e `SpeciesController` (RF-06 a RF-09); os e2e passam.
- [ ] Throttler (RF-05) com e2e: num app de teste com `THROTTLE_LIMIT=3`, a 4ª chamada seguida devolve `429`.
- [ ] Documentação das rotas (RF-10).
- [ ] Marcar esta spec e a tabela do README como `concluída`; commit `feat: rotas de espécies`.

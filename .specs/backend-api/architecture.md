# Arquitetura

O desenho técnico que as fases do backend-api compartilham. As iniciativas seguintes do servidor (login, batalha, jogador) acrescentam peças nesta estrutura.

## Pastas

```
server/
  package.json  tsconfig.json  nest-cli.json
  .env.example                  nomes das variáveis, sem valores reais (versionado)
  .env                          valores reais (fora do git)
  .gitignore                    node_modules/, dist/, .env
  CLAUDE.md                     regras do servidor
  README.md                     como instalar, rodar, migrar, semear e testar
  prisma/
    schema.prisma               o único arquivo que descreve o banco
    migrations/                 geradas pelo Prisma a partir do schema.prisma
    seed.ts                     carga inicial do catálogo a partir de ../client/data/*.json
  src/
    main.ts                     inicia o Nest, prefixo /v1, documentação em /docs
    app.module.ts
    config/                     lê e valida o .env na partida
    prisma/                     PrismaService (módulo global)
    health/                     GET /health
    common/                     paginação, referência, erros, limite de chamadas
    catalog/
      species/                  um módulo por recurso: controller, service, DTOs
      skills/  elements/  traits/  temperaments/  …
      bundle/                   GET /v1/catalog
    domain/                     regras puras de jogo (nasce em battle-core; vazio aqui)
  test/                         testes e2e (supertest)
```

## Banco

- **Onde:** o projeto Supabase que o dono já tem. Todas as tabelas ficam no schema Postgres **`ecobeasts`**. O `public` fica vazio. A API automática do Supabase publica só o `public`, então nada do jogo é exposto por ela, e o Godot nunca fala com o Supabase.
- **Conexões** (no `.env`): `DATABASE_URL`, pelo pooler do Supabase, usada pelo servidor; e `DIRECT_URL`, conexão direta, usada pelas migrations. O `.env.example` traz as duas, com o formato e valores de exemplo. Usa a versão estável atual do Prisma. Se ela pedir as URLs em outro lugar (como o `prisma.config.ts`), segue a versão, mas as tabelas continuam só no `schema.prisma`.
- **Conferir no painel** (fase 01): em Settings > API > Exposed schemas, o `ecobeasts` **não** pode aparecer.
- **Um arquivo só:** `server/prisma/schema.prisma` descreve todas as tabelas, chaves, índices e relações, agrupadas em blocos comentados: Referência, Espécies, Técnicas e Jogador. Toda mudança no banco começa nele e vira uma migration (`prisma migrate dev`). Ninguém cria nem altera tabela pelo painel do Supabase. **Mudar valores** (linhas) pelo painel é permitido e esperado.
- **Nomes:** no banco, os nomes de [game-data/architecture.md](../game-data/architecture.md): tabelas no plural e colunas em `snake_case` (`species`, `skill_effects`, `growth_rate_id`). No código, os modelos do Prisma ficam em `PascalCase` no singular, e os campos em `camelCase` (`Species`, `SkillEffect`, `growthRateId`), ligados aos nomes do banco por `@@map` e `@map`.
- **Tabelas do catálogo:** as 23 de [game-data/architecture.md](../game-data/architecture.md#tabelas-do-mvp), com as mesmas colunas, tipos, nulidade, chaves (inclusive as compostas das tabelas de junção), slugs únicos e FKs. Os tipos de efeito, as categorias e os demais "enums" continuam sendo tabelas de referência, como no JSON.
- **Tabelas do jogador:** as de [game-data/architecture.md](../game-data/architecture.md#estado-do-jogador-no-servidor): `players`, `creature_instances`, `creature_instance_stats` (com `genes` 0–31 e `training_points` 0–252 por stat), `creature_instance_skills` e `inventory_items`. `gender` (`male`, `female`, `none`) e `location` (`party`, `storage`) viram enums do Prisma. As FKs para tabelas que ainda não existem (`held_item_id`, `caught_zone_id`, `item_id` de `inventory_items`) ficam como coluna sem relação, com um comentário, até a tabela nascer. `inventory_items` é criada, mas fica vazia até existir a tabela `items`.
- **Ids:** os do catálogo são os mesmos dos JSON e nunca mudam. As chaves inteiras usam autoincremento. Depois da carga inicial, as sequências são ajustadas para continuar do maior id, para que uma linha nova criada no painel ganhe o id seguinte. Os ids do jogador são UUID.
- **FKs:** `ON DELETE RESTRICT` no catálogo, para não apagar uma espécie usada em outra tabela. No jogador, apagar o `player` apaga as criaturas e o inventário dele (`CASCADE`).
- **Índices:** em toda FK e nos slugs (únicos).

### Restrições de valor

As faixas que o validador do cliente confere (precisão de 1 a 100, `stages` de −6 a +6, Genes de 0 a 31, Treino de 0 a 252…) viram restrições `CHECK` no banco. Assim um valor fora da faixa é recusado mesmo quando editado à mão no painel.

O Prisma não descreve `CHECK` no `schema.prisma`, então essa é a única exceção à regra do arquivo único:

- a migration é criada com `prisma migrate dev --create-only`, os `CHECK` são acrescentados à mão no SQL dela, e só então ela é aplicada;
- no `schema.prisma`, cada campo com faixa ganha um comentário de documentação dizendo a faixa e a migration que a criou (`/// CHECK 1–100 (migration 20261101_catalog_checks)`);
- tabelas, colunas, chaves, índices e relações continuam só no `schema.prisma`. Só as faixas moram no SQL;
- as faixas são as mesmas de `client/core/data/catalog_schema.gd` e das tabelas em [game-data/architecture.md](../game-data/architecture.md).

## Carga inicial (seed)

- `prisma/seed.ts` lê `../client/data/<tabela>.json` e insere as linhas em ordem de dependência (referências antes de espécies, espécies antes de Técnicas aprendidas…), numa transação.
- Só roda se o banco estiver vazio: se `species` tiver qualquer linha, avisa e não faz nada. Nunca sobrescreve uma mudança feita à mão.
- No fim, ajusta as sequências dos ids e confere a contagem: 23 tabelas, 436 linhas, os mesmos números do validador do cliente.
- Até a fase 07, ninguém edita `client/data/`. Depois da carga, mudança de valor é feita no banco.
- Na fase 07, os arquivos saem do cliente e vão para `server/prisma/seed-data/` (com `git mv`), e o seed passa a ler de lá. Eles ficam como a foto inicial do catálogo, para montar um banco do zero. Um banco novo com os valores atuais (o de produção, por exemplo) é copiado do banco de desenvolvimento, e não desses arquivos.

## API

- **Prefixo:** `/v1`. Uma mudança que quebre o jogo publicado ganha um `/v2`, e o `/v1` continua respondendo.
- **Aberta:** as rotas do catálogo não pedem login. Há um limite de chamadas por IP (`@nestjs/throttler`, 100 por minuto), que responde `429` acima disso.
- **JSON em `snake_case`**, como a PokeAPI e o contrato do jogador em [onboarding/architecture.md](../onboarding/architecture.md). Textos (`name`, `description`) em pt-BR.
- **Lista:** `GET /v1/<recurso>?limit=20&offset=0`. O `limit` vai de 1 a 100, com padrão 20. A resposta tem `count` (total), `next` e `previous` (o caminho da página seguinte e da anterior, ou `null`) e `results`, com uma referência por linha, em ordem de `id`.
- **Detalhe:** `GET /v1/<recurso>/{id ou slug}`. Um número é tratado como id, e o resto como slug.
- **Referência** (quando um recurso cita outro): `{ "id": 1, "slug": "fire", "name": "Fogo", "url": "/v1/elements/1" }`. A `url` é o caminho a partir da raiz da API.
- **Erros:** o formato padrão do Nest (`statusCode`, `error`, `message`), com `message` em pt-BR. `404` para id ou slug que não existe e `400` para `limit` ou `offset` inválidos.
- **Recursos:**
  - `species` e os sub-recursos `species/{id}/skills` (o learnset: Técnica, método e nível) e `species/{id}/evolutions` (a linha de Ascensão inteira, de onde vem e para onde vai).
  - `skills`, com Elemento, categoria, alvo e efeitos.
  - `elements`, com a efetividade como atacante e como defensor.
  - `traits`, `temperaments`, `stats`, `growth-rates`, `rarities`, `status-conditions`, `skill-categories`, `skill-targets`, `skill-learn-methods`, `effect-types` e `evolution-triggers`.
  - `starters`, só a lista de iniciais em `sort_order`.
- **Detalhe de espécie** (`GET /v1/species/{id}`): `id`, `slug`, `name`, `description`, `height_m`, `weight_kg`, `gender_ratio`, `capture_rate`, `base_xp_yield`, `growth_rate` (referência), `rarity` (referência), `evolves_from` (referência ou `null`), `elements` (`[{ slot, element }]`), `stats` (`[{ stat, base_value, training_yield }]`) e `traits` (`[{ slot, is_hidden, trait }]`). As Técnicas e as Ascensões ficam nos sub-recursos.

### Catálogo inteiro (`GET /v1/catalog`)

- Devolve `{ "version": "<texto>", "tables": { "<tabela>": [ linhas ] } }`. As linhas têm exatamente as colunas e os nomes de `client/data/<tabela>.json`. Assim o Godot recebe o mesmo formato que já sabe ler.
- `version` é um resumo (hash SHA-256) do conteúdo, montado sempre na mesma ordem (tabelas por nome, linhas pela chave). Muda sempre que qualquer valor muda e só nesse caso. Vai também no cabeçalho `ETag`. Com `If-None-Match` igual à versão atual, a resposta é `304`, sem corpo.
- Para não montar o catálogo a cada chamada, o servidor guarda a resposta em memória por até 60 segundos. Uma mudança feita no banco aparece em no máximo 1 minuto.

## Documentação

- O `@nestjs/swagger` gera o documento OpenAPI a partir dos controllers e dos DTOs, com descrições em pt-BR e exemplos (o Fagulho como espécie de exemplo).
- A **Scalar** (`@scalar/nestjs-api-reference`) mostra esse documento em `/docs`, e o JSON fica em `/docs/openapi.json`. A Swagger UI não é montada.

## Testes

- Jest + supertest. Os testes e2e sobem a aplicação e chamam as rotas contra o banco de desenvolvimento já semeado, só lendo dados. Eles conferem formato, paginação, 404 e a existência dos iniciais (ids 1, 4 e 7). Não conferem valores de balanceamento (poder, stats), que o dono pode mudar no banco a qualquer hora.
- Os testes de unidade cobrem o que tiver lógica (paginação, cálculo da versão do catálogo).
- `npm test` e `npm run test:e2e` precisam passar antes de cada commit de fase.

## Cliente (fase 07)

- A `HttpDataSource` (prevista em [game-data/architecture.md](../game-data/architecture.md#como-o-jogo-lê-o-catálogo)) faz `GET /v1/catalog` e devolve as tabelas no mesmo formato da `StaticJsonDataSource`. O `Catalog` e o `CatalogValidator` continuam iguais.
- O endereço da API fica numa configuração do projeto Godot, com `http://localhost:3000` como padrão de desenvolvimento.
- O último catálogo baixado fica em cache no aparelho, junto com a versão. Na abertura, o jogo pede o catálogo com `If-None-Match`. Se a API não responder e houver cache, usa o cache. Sem cache, mostra o erro com "Tentar de novo".
- `client/data/` e `client/tools/validate_data.gd` saem do cliente. O validador continua rodando sobre as tabelas baixadas.

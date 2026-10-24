# Servidor

A API do Ecobeast: **NestJS 12 + Prisma 7** sobre o Postgres do Supabase, em TypeScript (ESM). As regras gerais (specs, vocabulário, servidor como autoridade) estão no `CLAUDE.md` da raiz. O desenho está em `.specs/backend-api/` (`README.md` e `architecture.md`).

## Estrutura

```
server/
  prisma/schema.prisma   o único arquivo que descreve o banco
  prisma/migrations/     geradas a partir do schema.prisma
  prisma.config.ts       caminho do schema e URL das migrations (DIRECT_URL)
  src/main.ts            inicia o Nest; src/app.setup.ts monta prefixo e docs (usado também nos testes)
  src/config/            leitura e validação do .env
  src/prisma/            PrismaService (global)
  src/health/            GET /health
  src/common/            peças compartilhadas pelas rotas
  src/catalog/           um módulo por recurso do catálogo
  src/domain/            regras puras de jogo (sem Nest nem Prisma)
  src/generated/         cliente do Prisma (gerado, fora do git)
  test/                  testes e2e (*.e2e-spec.ts)
```

## Regras

- **Banco:** `prisma/schema.prisma` é o único lugar onde tabelas, colunas, chaves, índices e relações nascem e mudam (`npm run db:migrate`). A única exceção são as restrições `CHECK`, escritas à mão no SQL da migration (criada com `--create-only`) e comentadas no campo com `/// CHECK <faixa> (migration <nome>)`. Nunca altere tabela pelo painel do Supabase.
- **Schema `ecobeasts`:** todo modelo tem `@@schema("ecobeasts")`. Nada no `public`, nem o histórico de migrations (o `prisma.config.ts` força `schema=ecobeasts` na URL da CLI). A API automática do Supabase não pode enxergar as tabelas.
- **Nomes:** no banco, tabelas no plural e colunas em `snake_case` (iguais às de `.specs/game-data/architecture.md`). No Prisma, modelo em `PascalCase` singular e campo em `camelCase`, com `@@map` e `@map`. A conversão de nome é sempre mecânica.
- **Respostas** em `snake_case`, com `name` e `description` em pt-BR. Mensagens de erro em pt-BR.
- **Rotas** sob `/v1` (menos `/health` e `/docs`). Toda rota documentada no OpenAPI, com descrição em pt-BR.
- **Regras de jogo** ficam em `src/domain/`, como funções puras sem Nest, Prisma nem I/O, porque são a autoridade do jogo e precisam de testes de unidade.
- **Testes:** Vitest + supertest. Os e2e rodam contra o banco do `.env` e só leem dados, ou desfazem o que escrevem. Eles não conferem valores de balanceamento, que o dono muda no painel. `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam antes de cada commit.
- **Segredos** só no `.env` (fora do git). O `.env.example` tem só nomes e valores de exemplo.
- Imports relativos com extensão `.js` (ESM com `nodenext`).

## Comandos

Da pasta `server/`:

```bash
npm run start:dev      # API em http://localhost:3000, docs em /docs
npm run db:migrate     # nova migration a partir do schema.prisma (e regenera src/generated/)
npm run db:generate    # regenera src/generated/
npm run db:seed        # carga inicial do catálogo
npm run lint && npm run typecheck && npm test && npm run test:e2e
```

# 01. Projeto do servidor

- **Status:** concluída
- **Depende de:** MVP de estrutura concluído; projeto Supabase do dono; Node 24 e npm

## Contexto

`server/` só tem um README de marcador. Esta fase cria o projeto NestJS, liga o Prisma ao Postgres do Supabase, sobe a documentação (Scalar) e deixa os testes rodando. Ainda não há tabelas: elas vêm em [02-database-schema](02-database-schema.md). O desenho compartilhado está em [architecture.md](architecture.md).

## Escopo

- Projeto NestJS em `server/` com TypeScript (ESM), oxlint, Prettier e Vitest (o que o Nest 12 gera).
- Configuração pelo `.env`, validada na partida.
- Prisma instalado, com `schema.prisma` só com a fonte de dados e o gerador, e o `PrismaService`.
- `GET /health` conferindo o banco.
- Documentação em `/docs` (Scalar) e `/docs/openapi.json`.
- `server/CLAUDE.md`, `server/README.md`, `.env.example`, `.gitignore`.

## Fora do escopo

- Tabelas e migrations ([02](02-database-schema.md)).
- Rotas do catálogo ([04](04-species-api.md) em diante).
- Deploy.

## Requisitos

- **RF-01:** `server/` é um projeto NestJS (versão estável atual) criado com npm e sem repositório git próprio (o git é o do monorepo). Scripts do `package.json`: `start:dev`, `build`, `start:prod`, `lint`, `typecheck` (`tsc --noEmit`), `test`, `test:e2e`, `postinstall` e `db:generate` (`prisma generate`, porque o cliente gerado fica fora do git), `db:migrate` (`prisma migrate dev`) e `db:seed` (a carga inicial, que nasce em [03](03-catalog-seed.md)). O `package.json` declara `"engines": { "node": ">=24" }`.
- **RF-02:** A configuração vem do `.env` pelo `@nestjs/config`, validada na partida. As variáveis são `DATABASE_URL` (obrigatória), `DIRECT_URL` (obrigatória), `PORT` (padrão `3000`) e `THROTTLE_LIMIT` (padrão `100`, usada em [04](04-species-api.md)). Faltando uma obrigatória, o servidor não sobe e a mensagem diz o nome da variável.
- **RF-03:** `server/.env.example` (versionado) tem as quatro variáveis com valores de exemplo, sem nada real, e um comentário dizendo onde achar cada URL no painel do Supabase (Connect > ORMs > Prisma). `server/.gitignore` ignora `node_modules/`, `dist/`, `.env` e o cliente gerado do Prisma.
- **RF-04:** `server/prisma/schema.prisma` tem a fonte de dados (`postgresql`, schema `ecobeasts`) e o gerador do cliente, sem modelos. Se a versão do Prisma pedir as URLs no `prisma.config.ts`, elas ficam lá: `DATABASE_URL` para o servidor e `DIRECT_URL` para as migrations.
- **RF-05:** `PrismaService` (`src/prisma/prisma.service.ts`) estende o cliente do Prisma, conecta na partida e desconecta no encerramento. Ele vem de um `PrismaModule` global (`src/prisma/prisma.module.ts`).
- **RF-06:** Toda rota fica sob o prefixo `/v1`, menos `/health` e `/docs`.
- **RF-07:** `GET /health` executa `SELECT 1` no banco. Respondendo, devolve `200` com `{ "status": "ok", "database": "ok" }`. Falhando, devolve `503` com `{ "status": "error", "database": "error" }`.
- **RF-08:** O `@nestjs/swagger` gera o OpenAPI com título `Ecobeast API`, versão `1` e a descrição "API do catálogo do Ecobeast. Usada pelo jogo; leitura aberta, sem login.". A Scalar (`@scalar/nestjs-api-reference`) mostra esse documento em `GET /docs`, e o JSON fica em `GET /docs/openapi.json`. A Swagger UI não é montada.
- **RF-09:** `server/CLAUDE.md` traz as regras do servidor:
  - o `schema.prisma` é o único arquivo do banco, e os `CHECK` à mão na migration são a única exceção;
  - nada de alterar tabela pelo painel;
  - regras de jogo ficam em `src/domain/`, sem Nest nem Prisma;
  - respostas em `snake_case` e textos em pt-BR;
  - os testes rodam antes de cada commit;
  - os comandos.
- **RF-10:** `server/README.md` explica como instalar (`npm install`), preencher o `.env`, gerar o cliente, migrar, semear, rodar (`npm run start:dev`) e testar.
- **RF-11:** O `CLAUDE.md` da raiz deixa de dizer que o servidor "ainda não existe" e aponta para `server/CLAUDE.md`.

## Critérios de aceite

- [x] Com o `.env` preenchido, `npm run start:dev` sobe na porta 3000, e `GET http://localhost:3000/health` devolve `200 {"status":"ok","database":"ok"}`.
- [x] Com uma senha errada na `DATABASE_URL`, `GET /health` devolve `503 {"status":"error","database":"error"}`, e o servidor continua no ar.
- [x] Sem `DATABASE_URL` no `.env`, `npm run start:dev` falha com uma mensagem que cita `DATABASE_URL`.
- [x] `http://localhost:3000/docs` abre a Scalar com o título "Ecobeast API", e `/docs/openapi.json` devolve o documento.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.
- [x] `git status` não mostra `.env`, `node_modules/` nem `dist/`.
- [ ] No painel do Supabase, em Settings > API > Exposed schemas, não aparece `ecobeasts`. (Passo do dono, ainda não confirmado.)

## Desenho técnico

**Criar**

- `server/` pelo `npx @nestjs/cli new server --package-manager npm --skip-git` (rodado na raiz), com o exemplo `AppController`/`AppService` removido.
- `server/src/main.ts`: prefixo `/v1` com exceção de `health` e `docs`, Swagger e Scalar, e a porta do config.
- `server/src/config/env.ts`: o schema das variáveis e a função de validação passada ao `ConfigModule.forRoot({ validate })`.
- `server/src/prisma/prisma.module.ts` e `prisma.service.ts`.
- `server/src/health/health.module.ts` e `health.controller.ts`.
- `server/prisma/schema.prisma` (e `server/prisma.config.ts`, se a versão do Prisma usar).
- `server/test/health.e2e-spec.ts`.
- `server/.env.example`, `server/.gitignore`, `server/CLAUDE.md`, `server/README.md` (substitui o marcador).

**Alterar**

- `CLAUDE.md` (raiz): RF-11.

## Verificação

Da pasta `server/`:

```bash
npm install
npm run db:generate
npm run lint
npm test
npm run test:e2e
npm run start:dev   # e abrir http://localhost:3000/docs e /health
```

## Tarefas

- [x] Apagar o `server/README.md` de marcador (o Nest CLI quer a pasta vazia); criar o projeto Nest e limpar o exemplo; scripts e `engines` do RF-01.
- [x] Teste e2e de `/health` (`200` com banco ok) e de `/docs/openapi.json` (`info.title` igual a `Ecobeast API`); rodar e ver falhar.
- [x] Config validado (RF-02), `.env.example` e `.gitignore` (RF-03).
- [x] Prisma: `schema.prisma` (RF-04), `PrismaModule` e `PrismaService` (RF-05).
- [x] `HealthController` (RF-07), prefixo (RF-06), Swagger e Scalar (RF-08); os testes passam.
- [x] Teste de unidade da validação do config: sem `DATABASE_URL`, lança erro que cita a variável.
- [x] `server/CLAUDE.md`, `server/README.md` e `CLAUDE.md` da raiz (RF-09 a RF-11).
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: projeto do servidor`.

## Decisões da implementação

- **Vitest e oxlint em vez de Jest e ESLint:** o Nest 12 gera o projeto em ESM com Vitest, supertest, oxlint e Prettier. A spec previa Jest e ESLint, mas trocar o padrão do gerador não traria ganho. Os comandos `npm test` e `npm run test:e2e` são os mesmos.
- **Prisma 7.10.1, fixo:** a tag `latest` do npm aponta para uma versão candidata da 8.0. A 7.10.1 é a última estável. No Prisma 7, as URLs saem do `schema.prisma` e vão para o `prisma.config.ts` (`DIRECT_URL`, para a CLI e as migrations), e o servidor conecta com o adaptador `@prisma/adapter-pg` (`DATABASE_URL`). O cliente é gerado em `src/generated/prisma` (ESM) e fica fora do git; o `postinstall` gera de novo.
- **`configureApp`** (`src/app.setup.ts`): o prefixo e a documentação são montados numa função usada pelo `main.ts` e pelos testes e2e, para os testes verem as mesmas rotas.
- **Banco fora do ar na partida:** o `PrismaService` só avisa no log e o servidor sobe. O `/health` mostra o problema (`503`).

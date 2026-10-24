# Servidor do Ecobeast

A API do Ecobeast: NestJS + Prisma sobre o Postgres do Supabase. O jogo (`../client/`) fala só com esta API. O desenho está em `../.specs/backend-api/`.

## Preparar

Precisa de Node 24 e npm.

```bash
cd server
npm install            # também gera o cliente do Prisma (postinstall)
cp .env.example .env   # e preencha com os dados do seu projeto Supabase
```

No `.env`:

- `DATABASE_URL`: URL do pooler, usada pelo servidor.
- `DIRECT_URL`: conexão direta, usada pelas migrations.

As duas ficam no painel do Supabase, em **Connect > ORMs > Prisma**. O `.env` nunca vai para o git.

## Rodar

```bash
npm run start:dev      # http://localhost:3000
```

- `GET /health`: confere o servidor e o banco.
- `GET /docs`: documentação da API (Scalar), onde dá para testar as rotas.
- `GET /docs/openapi.json`: o documento OpenAPI.

## Banco

Todas as tabelas ficam em `prisma/schema.prisma`, no schema Postgres `ecobeasts`. Toda mudança de tabela começa nesse arquivo:

```bash
npm run db:migrate     # cria e aplica uma migration a partir do schema.prisma
npm run db:generate    # regenera o cliente do Prisma (src/generated/)
npm run db:seed        # carga inicial do catálogo (só em banco vazio)
```

Valores do catálogo (o poder de uma Técnica, por exemplo) podem ser mudados direto pelo painel do Supabase. Tabelas e colunas, nunca.

## Testar

```bash
npm run lint
npm run typecheck
npm test               # testes de unidade
npm run test:e2e       # sobem a API e chamam as rotas contra o banco do .env
```

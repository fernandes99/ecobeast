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
- `SUPABASE_URL`: endereço do projeto (**Project Settings > Data API > Project URL**).
- `SUPABASE_PUBLISHABLE_KEY`: chave pública do projeto (**Project Settings > API Keys > Publishable key**). A chave secreta (`service_role`) não é usada.
- `PUBLIC_BASE_URL`: endereço deste servidor visto pelo navegador; padrão `http://localhost:<PORT>`.

As duas primeiras ficam no painel do Supabase, em **Connect > ORMs > Prisma**. Sem qualquer uma das obrigatórias, o servidor não sobe e diz qual falta. O `.env` nunca vai para o git.

### Login com Google

O login usa o Supabase Auth com o provedor Google. Antes do primeiro login de verdade, siga os passos do dono em [`.specs/auth-google/01-auth-server.md`](../.specs/auth-google/01-auth-server.md#passos-do-dono-antes-de-testar-o-login-de-verdade): o cliente OAuth no Google Cloud, o provedor Google no Supabase, a URL de retorno `http://localhost:3100/auth/google/callback**` liberada e as chaves de assinatura JWT assimétricas.

## Rodar

```bash
npm run start:dev      # http://localhost:3100
```

- `GET /health`: confere o servidor e o banco.
- `GET /docs`: documentação da API (Scalar), onde dá para testar as rotas.
- `GET /docs/openapi.json`: o documento OpenAPI.
- `GET /v1/me`, `POST /v1/me`, `POST /v1/me/starter` e `DELETE /v1/me`: o Domador do usuário logado (exigem `Authorization: Bearer`).
- `POST /v1/auth/google/start`: começa um login com Google; abra a `url` da resposta no navegador e pergunte em `POST /v1/auth/google/poll`.

## Banco

Todas as tabelas ficam em `prisma/schema.prisma`, no schema Postgres `ecobeasts`. Toda mudança de tabela começa nesse arquivo:

```bash
npm run db:migrate     # cria e aplica uma migration a partir do schema.prisma e regenera o cliente
npm run db:generate    # regenera o cliente do Prisma (src/generated/)
npm run db:seed        # carga inicial do catálogo (só em banco vazio)
```

Valores do catálogo (o poder de uma Técnica, por exemplo) podem ser mudados direto pelo painel do Supabase. Tabelas e colunas, nunca.

## Testar

```bash
npm run lint
npm run typecheck
npm test               # testes de unidade
npm run test:e2e       # sobem a API e chamam as rotas contra o banco do .env (o Supabase Auth é um dublê)
```

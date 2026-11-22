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
  src/auth/              login com Google (Supabase Auth), AuthGuard e @CurrentUser()
  src/player/            o Domador do usuário logado (/v1/me), que pode nascer sem nome e ganhá-lo uma vez (PUT /v1/me/name), e a conferência da aparência (appearance-check.ts), que os NPCs pessoas também usam
  src/battle/            o que toda luta usa: o BattleStore (a luta na memória), a leitura da equipe e a gravação do fim
  src/board-battle/      a luta no tabuleiro do usuário logado (/v1/me/board-battle)
  src/exploration/       o mapa de exploração do usuário logado (/v1/me/exploration), sorteado ou de uma ilha publicada, com os Ecobeasts e os Domadores NPC guardados na memória, e o teleporte de depuração (PUT /v1/me/exploration/position, só para quem está em MAP_EDITOR_USER_IDS)
  src/inventory/         a Loja e a Mochila do usuário logado (/v1/me/shop e /v1/me/items)
  src/team/              a equipe e o Santuário do usuário logado (/v1/me/team e /v1/me/storage)
  src/codex/             o Bestiário do usuário logado (/v1/me/codex) e o CodexService, que as lutas, a Evolução e o inicial usam para registrar visto e capturado
  src/editor/            os editores (/v1/editor): ilhas em rascunho e publicadas (e a ilha casa, PUT /v1/editor/islands/:id/home), o gerador de mapas, as Técnicas do F1 (/v1/editor/skills), a aparência dos NPCs pessoas (/v1/editor/npcs/:id/appearance), a voz dos NPCs (/v1/editor/npcs/:id/voice) e as salas dos interiores (/v1/editor/interiors), só para quem está em MAP_EDITOR_USER_IDS
  src/interiors/         a sala de um interior para o jogo (GET /v1/interiors/:id) e o InteriorsService, que o editor também usa; as regras da sala moram em src/domain/interiors/
  src/islands/           as ilhas publicadas para o jogador (/v1/me/islands) e o IslandsService, que lê uma versão de ilha para o editor e para a exploração numa ilha, e os hexágonos que cada Domador já descobriu nelas (/v1/me/islands/:id/discoveries, o DiscoveriesService), e o Arquipélago Auralis (/v1/me/archipelago, o ArchipelagoService): a ordem das ilhas, as que o Domador abriu e a entrada recusada numa trancada; e os Domadores fixos das ilhas e as Arenas (o IslandTamersService, com a luta em POST /v1/me/board-battle/island-tamer, a Arena trancada, o emblema e a ilha seguinte aberta na vitória); as regras moram em src/domain/islands/archipelago.ts
  src/tamer-level/       o nível do Domador (TamerLevelService): o catálogo da curva e das fontes e o award, que devolve as escritas do XP, do nível e das recompensas para a transação de quem chama; as regras moram em src/domain/progression/tamer-level.ts
  src/story/             os Marcos da história do usuário logado (/v1/me/story/marks), guardados sem significado: o roteiro mora no jogo
  src/world-clock/       a hora do mundo (GET /v1/world-clock, sem login); a conta mora em src/domain/world-clock/
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
- **Rotas** sob `/v1` (menos `/health`, `/docs` e as páginas do navegador `/auth/google/go` e `/auth/google/callback`). Toda rota documentada no OpenAPI, com descrição em pt-BR.
- **Regras de jogo** ficam em `src/domain/`, como funções puras sem Nest, Prisma nem I/O, porque são a autoridade do jogo e precisam de testes de unidade.
- **Sessão:** rotas do jogador usam `@UseGuards(AuthGuard)`, `@ApiBearerAuth()` e `@CurrentUser()` (o `sub` do token do Supabase). O servidor fala com o Supabase Auth só pela API REST (`SupabaseAuthClient`); a chave secreta do Supabase não é usada.
- **Testes:** Vitest + supertest. Os e2e rodam contra o banco do `.env` e só leem dados, ou desfazem o que escrevem. O Supabase Auth dos e2e é sempre um dublê (`SUPABASE_URL` falso no `vitest.config.e2e.ts`), e os tokens são assinados por `test/support/tokens.ts`. Eles não conferem valores de balanceamento, que o dono muda no painel. Um e2e que grava no catálogo entra no grupo `e2e-catalog-writers` do `vitest.config.e2e.ts`, que roda depois dos outros. `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam antes de cada commit.
- **Segredos** só no `.env` (fora do git). O `.env.example` tem só nomes e valores de exemplo.
- Imports relativos com extensão `.js` (ESM com `nodenext`).

## Comandos

Da pasta `server/`:

```bash
npm run start:dev      # API em http://localhost:3100, docs em /docs
npm run db:migrate     # nova migration a partir do schema.prisma (e regenera src/generated/)
npm run db:generate    # regenera src/generated/
npm run db:seed        # carga inicial do catálogo
npm run lint && npm run typecheck && npm test && npm run test:e2e
```

# 03. Rotas do jogador

- **Status:** concluída
- **Depende de:** [01-auth-server](01-auth-server.md), [02-player-rules](02-player-rules.md)

## Contexto

Com a sessão conferida pelo `AuthGuard` ([01](01-auth-server.md)) e as regras do inicial em TypeScript ([02](02-player-rules.md)), esta fase cria as rotas do jogador em `/v1/me` ([architecture.md](architecture.md#rotas-do-jogador)): ler, criar o Domador, escolher o inicial e apagar o progresso, gravando nas tabelas do jogador que existem desde a [backend-api/02](../backend-api/02-database-schema.md). O formato do JSON é o contrato que o cliente já lê ([onboarding/architecture.md](../onboarding/architecture.md#modelos-resdomainmodels)).

## Escopo

- `PlayerModule`: controller, service e DTOs de `/v1/me`.
- A conversão das linhas do banco para o JSON do jogador, com `stats` calculado.

## Fora do escopo

- Qualquer ação além das quatro rotas (apelido, reorganizar equipe, batalha…).
- Mudanças no Godot ([05](05-client-player.md)).

## Requisitos

- **RF-01:** Todas as rotas usam o `AuthGuard`; o Domador é o de `players.id = userId`. Tag "Jogador" na Scalar, com cadeado.
- **RF-02:** `GET /v1/me` → `200 {"player": <Player> | null}`.
- **RF-03:** `POST /v1/me`, corpo `{"name": string}`: normaliza (pontas sem espaço, sequências de espaço viram uma) e confere `^[\p{L}\p{N} ]{2,16}$` (flag `u`); inválido → `400` "Use de 2 a 16 letras, números ou espaços."; Domador já existe (inclusive numa corrida, pela chave primária) → `409` "Você já tem um Domador."; sucesso → `201 {"player"}` com `level = 1`, `coins = 1000` e equipe vazia.
- **RF-04:** `POST /v1/me/starter`, corpo `{"species_id": int}`: sem Domador → `409` "Crie seu Domador primeiro."; já tem criatura → `409` "Você já escolheu seu Ecobeast." (inclusive numa corrida, pela chave única `player_id + party_slot`); espécie fora de `starter_options` → `400` "Esse Ecobeast não pode ser escolhido."; sucesso → `200 {"player"}` com a criatura nível 5 no slot 1.
- **RF-05:** A criatura do RF-04 vem de `createCreature` ([02](02-player-rules.md)) com os dados do catálogo lidos do banco (espécie, stats base, learnset em ordem de nível, PP das Técnicas, Traços normais, Temperamentos, multiplicador da curva) e `random` de `crypto.randomInt`. Grava, numa transação, `creature_instances` (`location = party`, `party_slot = 1`, `original_player_id = userId`, `caught_at = agora`, `caught_zone_id` nulo), 6 linhas de `creature_instance_stats` e as linhas de `creature_instance_skills`.
- **RF-06:** `DELETE /v1/me` → `204`; apaga o Domador (cascata nas criaturas, stats, Técnicas e inventário); sem Domador, também `204`.
- **RF-07:** JSON do `Player`: `id`, `name`, `level`, `coins`, `created_at` (ISO 8601 em UTC, com `Z`) e `party` (criaturas com `location = party`, em ordem de `party_slot`). Cada criatura: `uid`, `species_id`, `nickname` (`""` se nulo), `level`, `current_xp`, `current_hp`, `stats`, `genes`, `training_points` (objetos com os 6 slugs), `temperament_id`, `trait_id`, `gender`, `is_prismatic`, `bond`, `skills` (`[{skill_id, current_pp}]` em ordem de slot), `status_condition_id`, `held_item_id`, `original_player_id`, `caught_at`, `caught_zone_id` (os três ids opcionais como `null`). `stats` é recalculado a cada resposta pelo `calculateStats`, com o Temperamento e os stats base atuais do banco.
- **RF-08:** As mensagens de erro estão em pt-BR e iguais às do contrato do `GameService` ([onboarding/architecture.md](../onboarding/architecture.md#contrato-do-gameservice)).

## Critérios de aceite

- [x] Sem token, cada rota dá `401`.
- [x] Um usuário novo: `GET /v1/me` dá `player: null`; `POST /v1/me` com `"  Ana   Maria "` cria "Ana Maria" com 1000 moedas; um segundo `POST` dá `409`.
- [x] `POST /v1/me/starter` antes do Domador dá `409`; com `species_id` 2 (não inicial), `400`; com 1, `200` com Fagulho no nível 5, 4 ou menos Técnicas, HP cheio e `stats` coerentes com Genes e Temperamento; um segundo, `409`.
- [x] O `GET /v1/me` seguinte devolve o mesmo jogador, e o banco tem 1 criatura, 6 linhas de stats e as Técnicas.
- [x] Dois `POST /v1/me/starter` ao mesmo tempo terminam com uma criatura só (um `200` e um `409`).
- [x] `DELETE /v1/me` dá `204`, e o `GET /v1/me` seguinte, `player: null`.
- [x] Os e2e apagam os Domadores que criaram.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/player/`: `player.module.ts`, `player.controller.ts`, `player.service.ts`, `player.dto.ts` (DTOs da resposta e do corpo, com exemplos reais), `player.mapper.ts` (linhas → JSON), com `player.mapper.spec.ts`.
- `server/test/player.e2e-spec.ts`: tokens assinados por um par de chaves gerado na hora, com o `TokenVerifier` substituído por um que confere essa chave; cada teste usa um `sub` (UUID) novo.

**Alterar**

- `server/src/app.module.ts` (`PlayerModule`); `server/test/support/` (ajudante para assinar tokens).

**Reaproveitar**

- `AuthGuard` e `@CurrentUser()` ([01](01-auth-server.md)); `createCreature` e `calculateStats` ([02](02-player-rules.md)); `PrismaService`.

## Verificação

```bash
cd server && npm test && npm run test:e2e
```

## Tarefas

- [x] e2e dos critérios; rodar e ver falhar.
- [x] `player.mapper` com teste (RF-07).
- [x] `PlayerService` e `PlayerController` (RF-01 a RF-06, RF-08); os e2e passam.
- [x] Documentação na Scalar.
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: rotas do jogador`.

## Decisões da implementação

- **Transação:** a criatura, os stats e as Técnicas são gravados por uma escrita aninhada do Prisma, que já é uma transação só.
- **Corridas:** as conferências de "já existe" dão a mensagem no caso comum; quem decide em dois pedidos simultâneos é o banco (chave primária de `players`; chave única `player_id + party_slot`). O erro `P2002` vira o mesmo `409`.
- **Ordem das conferências do inicial:** sem Domador, já tem criatura, espécie fora dos iniciais. Um segundo inicial com uma espécie inválida dá `409`, não `400`.
- **Ordem do learnset:** por nível e, no empate, por `skill_id`, a mesma ordem do catálogo que o cliente lê (`GET /v1/catalog`). `species_skills` não tem coluna de ordem.
- **Normalização do nome:** qualquer sequência de espaço em branco (`\s+`) vira um espaço, como no cliente. Corpo sem `name`, ou com `name` que não é texto, dá a mesma mensagem de nome inválido.
- **`created_at` e `caught_at`** saem de `toISOString()`, com milissegundos (`2026-10-30T12:00:00.000Z`). O cliente só guarda o texto.
- **Sorteio:** `crypto.randomInt` aceita no máximo 2⁴⁸ − 1, e esse é o intervalo usado em `secureRandom`.
- **Falta de um dos 6 stats** (na criatura ou na espécie) lança erro em vez de responder um número errado.
- **`players.id`** recebe o `sub` do token. O `@default(uuid())` do schema continua lá; não precisou de migration.
- **Conferência:** `npm run lint`, `npm run typecheck` e Prettier sem avisos; `npm test` com 118 testes; `npm run test:e2e` com 201, dos quais 23 desta fase. Depois dos e2e, `players`, `creature_instances`, `creature_instance_stats` e `creature_instance_skills` ficaram com 0 linhas.

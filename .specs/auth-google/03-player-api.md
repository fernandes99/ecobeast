# 03. Rotas do jogador

- **Status:** rascunho
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

- [ ] Sem token, cada rota dá `401`.
- [ ] Um usuário novo: `GET /v1/me` dá `player: null`; `POST /v1/me` com `"  Ana   Maria "` cria "Ana Maria" com 1000 moedas; um segundo `POST` dá `409`.
- [ ] `POST /v1/me/starter` antes do Domador dá `409`; com `species_id` 2 (não inicial), `400`; com 1, `200` com Fagulho no nível 5, 4 ou menos Técnicas, HP cheio e `stats` coerentes com Genes e Temperamento; um segundo, `409`.
- [ ] O `GET /v1/me` seguinte devolve o mesmo jogador, e o banco tem 1 criatura, 6 linhas de stats e as Técnicas.
- [ ] Dois `POST /v1/me/starter` ao mesmo tempo terminam com uma criatura só (um `200` e um `409`).
- [ ] `DELETE /v1/me` dá `204`, e o `GET /v1/me` seguinte, `player: null`.
- [ ] Os e2e apagam os Domadores que criaram.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

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

- [ ] e2e dos critérios; rodar e ver falhar.
- [ ] `player.mapper` com teste (RF-07).
- [ ] `PlayerService` e `PlayerController` (RF-01 a RF-06, RF-08); os e2e passam.
- [ ] Documentação na Scalar.
- [ ] Marcar esta spec e a tabela do README como `concluída`; commit `feat: rotas do jogador`.

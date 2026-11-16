# 01. Os selvagens pela parte do dia

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [day-night/01](../day-night/01-world-clock.md)

## Contexto

O dono quer que cada Ecobeast tenha as partes do dia em que pode nascer ([README](README.md#decisões)). Esta fase cria o registro, com todos em todas as partes, e passa a filtrar o sorteio dos selvagens pela parte do dia de quando o Domador entra no mapa.

## Escopo

- A tabela `species_day_phases` no banco, na carga inicial e no catálogo.
- O filtro em `rollSpawns` e em `rollAreaSpawns`, com a parte do dia vinda do relógio do servidor.
- O `debug_minute` da entrada, para testar com a hora de debug do jogo.

## Fora do escopo

- Ver ou editar as partes do dia no jogo ou nos editores.
- As equipes dos Domadores NPC e o Ecobeast posto pelo debug.

## Requisitos

- **RF-01:** A migração `<data>_species_day_phases` (SQL escrito à mão, aplicado com `prisma migrate deploy`) cria `ecobeasts.species_day_phases` com `species_id` (FK para `species`) e `day_phase_id` (FK para `day_phases`), as duas `ON DELETE RESTRICT`, chave primária nas duas e índice em `day_phase_id`. No mesmo SQL, ela grava uma linha para cada Ecobeast que existe e cada parte do dia (`INSERT ... SELECT` do produto das duas tabelas). O `schema.prisma` ganha o modelo `SpeciesDayPhase`, com as relações em `Species` e `DayPhase`.
- **RF-02:** `server/prisma/seed-data/species_day_phases.json` tem as 4 partes do dia para cada Ecobeast de `species.json`, e a carga inicial as grava.
- **RF-03:** `GET /v1/catalog` traz a tabela `species_day_phases`, logo depois de `species_biomes` em `server/src/catalog/catalog-tables.ts`, com a chave `['species_id', 'day_phase_id']`. O jogo baixa o catálogo sem erro do `CatalogValidator`, mesmo sem ler a tabela.
- **RF-04:** `bornIn(items, born)` (`server/src/domain/exploration/spawns.ts`) deixa só os Ecobeasts cujo `speciesId` está no conjunto `born`, e o mapa sorteado chama `rollSpawns` com `bornIn(<espécies>, born)`. Um bioma sem nenhum candidato fica sem selvagem, como hoje. `rollSpawns` e `SpawnSpecies` não mudam, então as equipes dos Domadores NPC, que usam o mesmo `SpawnSpecies`, ficam de fora sem esforço.
- **RF-05:** `areasBornIn(areas, born)` (`server/src/domain/islands/area-spawns.ts`) deixa em cada área só os da lista dela que estão em `born`, e a ilha chama `rollAreaSpawns` com o resultado. Uma área sem nenhum fica sem selvagem.
- **RF-06:** `speciesBornAt(prisma, minute)` (`server/src/exploration/spawn-data.ts`) acha a parte do dia com `dayPhaseAt(minute, <day_phases do banco>)` e devolve o conjunto dos Ecobeasts dela em `species_day_phases`. `ExplorationService.start` o chama uma vez por entrada, com `minuteOfDay(Date.now())`, no mapa sorteado e nas ilhas.
- **RF-07:** `rollMapTamers`, `rollChallenger` e o `POST /v1/me/exploration/spawns` não mudam: as equipes e o Ecobeast do debug saem de qualquer parte do dia.
- **RF-08:** O corpo de `POST /v1/me/exploration` aceita `debug_minute` (número de 0 a 1439, opcional). Com `ENABLE_TEST_BATTLE` ligado, ele é usado no lugar de `minuteOfDay(Date.now())`; desligado, é ignorado. Fora da faixa, a resposta é 400. A rota documenta o campo em `/docs`.
- **RF-09:** No jogo, `api_game_service.gd` manda `debug_minute` com `WorldClock.minute_of_day()` ao entrar num mapa quando `WorldClock.debug_offset_minutes` não é 0.

## Critérios de aceite

- [ ] Depois da migração, `species_day_phases` tem 4 linhas para cada Ecobeast, e o mapa sorteado e as ilhas continuam com os mesmos selvagens de antes, em qualquer hora.
- [ ] Os testes de `spawns.spec.ts` mostram que um Ecobeast sem a parte do dia não nasce, que um bioma só com ele fica vazio e que os outros nascem como antes.
- [ ] Os testes de `area-spawns.spec.ts` mostram o mesmo para as áreas das ilhas.
- [ ] Um e2e da entrada com `debug_minute` mostra que um Ecobeast só da Noite, posto por uma linha temporária em `species_day_phases` e desfeita no fim, não nasce num `debug_minute` da Manhã. O e2e entra no grupo `e2e-catalog-writers`.
- [ ] Tirando pelo painel as partes do dia de um Ecobeast, menos a Noite, e entrando no mapa com o "Debug: +1 hora" até a Manhã, ele não aparece; à Noite, ele aparece.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam, e o jogo abre com o servidor no ar sem erro do `CatalogValidator`.

## Desenho técnico

- **Servidor:**
  - `prisma/migrations/<data>_species_day_phases/migration.sql`, `schema.prisma` e `seed-data/species_day_phases.json`
  - `src/catalog/catalog-tables.ts` e `catalog-tables.spec.ts` (a contagem passa a 45)
  - `src/exploration/spawn-data.ts`: `loadSpawnSpecies` lê as partes do dia, e uma função nova lê `day_phases`
  - `src/domain/exploration/spawns.ts` e `src/domain/islands/area-spawns.ts`, com os testes
  - `src/exploration/exploration.service.ts`, o `StartExplorationBodyDto` e o controller
  - `test/exploration.e2e-spec.ts` (ou um e2e novo no grupo `e2e-catalog-writers`) e `test/database.e2e-spec.ts`, se ele conferir a lista de tabelas
- **Jogo:** `core/services/api_game_service.gd` e o espelho da tabela em `core/data/catalog_schema.gd` (regra do `client/CLAUDE.md`: tabela nova muda o schema do jogo, o do servidor e o [game-data/architecture.md](../game-data/architecture.md) juntos).
- **Reutilizar:** `minuteOfDay` e `dayPhaseAt` de `src/domain/world-clock/world-clock.ts`, e o `requireTestRoutes` da exploração como modelo para conferir `ENABLE_TEST_BATTLE`.

## Tarefas

- [x] Migração, modelo, carga inicial e catálogo.
- [x] O filtro em `rollSpawns` e `rollAreaSpawns`, com os testes de unidade.
- [x] A parte do dia e o `debug_minute` na entrada, com o e2e.
- [x] O `debug_minute` no jogo.
- [x] A suíte inteira e o jogo aberto com o servidor no ar.

## Resultado da verificação

Em 2026-11-15:

- **A migração** rodou no banco e gravou 56 linhas, as 4 partes do dia para cada um dos 14 Ecobeasts do banco; a carga inicial tem as 36 dos 9 de `species.json`.
- **Desvio da spec, pelo desenho:** no lugar de mudar `SpawnSpecies` e a assinatura de `rollSpawns` e `rollAreaSpawns`, o filtro virou duas funções à parte, `bornIn` e `areasBornIn` (RF-04 a RF-06 já reescritos). O resultado é o mesmo, e os sorteios e as equipes dos Domadores NPC não mudam.
- **Testes de unidade:** 3 em `spawns.spec.ts` e 3 em `area-spawns.spec.ts` (quem não nasce some, o bioma ou a área fica vazia, e com todos nascendo o sorteio é igual ao de antes), mais a carga inicial em `catalog-tables.spec.ts`.
- **E2e** `test/day-phase-spawns.e2e-spec.ts`, no grupo `e2e-catalog-writers`: tira as partes do dia, menos a Noite, do Ecobeast de maior taxa, confere 6 mapas com o `debug_minute` da Manhã sem ele e 6 da Noite com ele, recusa `debug_minute` -1, 1440, 12,5 e "600", e devolve as linhas no fim. O `database.e2e-spec.ts` conta a tabela nova e confere a FK da parte do dia.
- `npm run lint`, `npm run typecheck`, `npm test` (958 testes) e `npm run test:e2e` (599 testes) passam. O servidor no ar (`start:dev`) já serve a tabela no `GET /v1/catalog`, e o jogo abre sem janela, com o catálogo baixado, sem erro de script nem do `CatalogValidator`.
- **Não conferido:** o passo no jogo aberto, com uma espécie só da Noite pelo painel e o "Debug: +1 hora".
# 01. O relógio do mundo

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [backend-api](../backend-api/)

## Contexto

O dono quer um dia de 24 minutos reais, com 4 partes. Por enquanto a hora só muda o visual, mas depois vai decidir quais Ecobeasts nascem, então o servidor precisa saber a hora desde já ([README](README.md#decisões)). Esta fase cria o relógio e as partes do dia, sem nada visível ainda, além de um aviso de debug.

## Escopo

- A tabela `day_phases` no banco, na carga inicial e no catálogo (servidor e jogo).
- O domínio do relógio e a rota `GET /v1/world-clock` no servidor.
- O autoload `WorldClock` no jogo, com a sincronização e o sinal da troca de parte.
- Um botão de debug na exploração que adianta a hora, no menu de debug que já existe (aparece em toda build de debug, inclusive o APK de teste no celular).

## Fora do escopo

- O filtro da luz e o indicador ([02](02-day-light.md)).
- Qualquer regra de jogo pela hora.
- A coluna `evolutions.time_of_day`, que fica como está.

## Requisitos

- **RF-01:** A migração `<data>_day_phases` (SQL escrito à mão, aplicado com `prisma migrate deploy`) cria `ecobeasts.day_phases` com as colunas e as regras do [architecture.md](architecture.md#as-partes-do-dia): `slug` único com o CHECK `^[a-z0-9_]+$` e `start_minute` único com o CHECK de 0 a 1439. O `schema.prisma` ganha o modelo `DayPhase`, com os comentários das CHECKs, como os outros.
- **RF-02:** `server/prisma/seed-data/day_phases.json` tem as 4 partes do [architecture.md](architecture.md#as-partes-do-dia), e a carga inicial as grava.
- **RF-03:** `GET /v1/catalog` traz a tabela `day_phases` (entrada em `server/src/catalog/catalog-tables.ts`), e a versão do catálogo muda quando ela muda.
- **RF-04:** `server/src/domain/world-clock/world-clock.ts` exporta `EPOCH_MS`, `CYCLE_MS`, `minuteOfDay(nowMs: number): number` e `dayPhaseAt(minute: number, phases: { id: number; startMinute: number }[])`, pelas contas do [architecture.md](architecture.md#o-relógio-do-mundo). Para um `nowMs` antes de `EPOCH_MS`, o resultado continua entre 0 e 1440.
- **RF-05:** `GET /v1/world-clock`, sem login, devolve `{ "minute_of_day": <número> }` com `minuteOfDay(Date.now())`, documentada em `/docs`.
- **RF-06:** O jogo lê `day_phases` no catálogo (`catalog_schema.gd`, modelo `DayPhase` em `res://domain/models/day_phase.gd`, `GameData.get_day_phases()`), e o `CatalogValidator` recusa um catálogo sem nenhuma parte do dia ou com `start_minute` fora de 0 a 1439.
- **RF-07:** O autoload `WorldClock` tem `sync() -> bool` (assíncrono), `is_synced() -> bool`, `minute_of_day() -> float`, `hour() -> float`, `phase() -> DayPhase`, `clock_text() -> String` (como "19h05", para o debug) e os sinais `phase_changed(phase: DayPhase)` e `synced`, com a conta e as regras do [architecture.md](architecture.md#o-relógio-do-mundo). Ele não usa o relógio do celular.
- **RF-08:** O `WorldClock` sincroniza depois de o catálogo carregar, na abertura do jogo (`res://screens/main/main.gd`), de novo ao abrir a tela `exploration` e quando o app volta do segundo plano. Uma falha de rede não trava nada: ele fica como estava e tenta na próxima vez.
- **RF-09:** No menu de debug da exploração (o que aparece com `OS.is_debug_build()`, para dar para testar a noite no celular sem esperar), o botão "Debug: +1 hora" soma 60 minutos a um `debug_offset_minutes` do `WorldClock`, que vale só neste aparelho e volta a 0 ao fechar o jogo. Cada toque mostra a hora e a parte do dia na mensagem da tela, por exemplo "19h00 — Noite". Logo abaixo, a linha da hora mostra a hora do jogo, uma barra para escolher a hora (de 15 em 15 minutos, `WorldClock.debug_set_minute`, e o relógio segue andando dali) e o botão "Hora real", que zera o `debug_offset_minutes`. Pedido do dono depois da fase pronta: "coloque no debug uma opção definir o tempo".

## Critérios de aceite

- [ ] `GET /v1/world-clock` responde sem login, e dois pedidos com 10 segundos de diferença dão minutos com 10 de diferença (ou dão a volta em 1440).
- [ ] `GET /v1/catalog` traz as 4 partes do dia com os nomes Manhã, Tarde, Final de tarde e Noite.
- [ ] Os testes de `world-clock.spec.ts` cobrem a volta no fim do dia, um momento antes da `EPOCH_MS` e a noite atravessando a 0h (minuto 0 e minuto 359 dão Noite; 360 dá Manhã).
- [ ] No jogo, o botão "Debug: +1 hora" mostra a hora andando de hora em hora, e a parte do dia muda nos horários da tabela.
- [ ] Mudar a hora do celular não muda a hora do jogo.
- [ ] O jogo abre com o servidor no ar sem erro do `CatalogValidator`, e `godot --headless --path client --quit-after 60` roda sem erro de script.

## Desenho técnico

- **Servidor:**
  - `server/prisma/migrations/<data>_day_phases/migration.sql`
  - `schema.prisma`
  - `seed-data/day_phases.json` e a carga inicial
  - `src/catalog/catalog-tables.ts`
  - `src/domain/world-clock/world-clock.ts` e `.spec.ts`
  - Um módulo `src/world-clock/` com o controller da rota, registrado no `app.module.ts`
  - O e2e `test/world-clock.e2e-spec.ts`
  - Os testes do catálogo que contam tabelas (`catalog-tables.spec.ts`)
- **Jogo:**
  - `core/data/catalog_schema.gd`, `domain/models/day_phase.gd`, `core/autoload/game_data.gd` e o `CatalogValidator`
  - `core/autoload/world_clock.gd`, registrado em `project.godot` como `WorldClock`
  - A chamada no `screens/main/main.gd` e na tela `exploration`
  - O botão no menu de debug de `exploration_screen.tscn`
- **Reutilizar:** o padrão de rota pública do `health.controller.ts` e o `Api.request` do jogo.

## Verificação

- `npm test` e `npm run test:e2e` em `server/` (os e2e tocados durante a fase; a suíte inteira antes do commit).
- `curl http://localhost:3000/v1/world-clock` duas vezes, com 10 s de intervalo.
- F5 no Godot: entrar na exploração e tocar "Debug: +1 hora" até dar a volta no dia.

## Tarefas

- [x] Migração (`20261218000000_day_phases`), modelo, carga inicial e catálogo do servidor.
- [x] Domínio do relógio com os testes.
- [x] Rota `GET /v1/world-clock` com o e2e.
- [x] Catálogo no jogo (`DayPhase.at` escolhe a parte no jogo) e o `CatalogValidator`.
- [x] Autoload `WorldClock` e as sincronizações.
- [x] Botão de debug e a linha para escolher a hora.
- [x] Atualizar `CLAUDE.md`, `client/CLAUDE.md`, o README da iniciativa e as tabelas das specs.

Conferido por Claude: os testes do servidor, a rota respondendo, o catálogo com as 4 partes no jogo, a escolha da parte nos minutos 0, 359, 360, 720, 1020, 1139, 1140 e 1439,9 e o "+1 hora" mudando a hora e a parte. Fica para o dono: o botão no celular.

# 02. O sinal de cada minuto

- **Status:** concluída
- **Depende de:** [01-counters-server](01-counters-server.md)

## Contexto

As horas jogadas, os dias e a distância não passam por nenhuma rota de hoje. O dono pediu: "um count que cresce cada vez que o usuário muda um hexagono e enviamos essa info junto a cada minuto junto com o sync do tempo". O servidor põe o teto do [architecture.md](architecture.md#o-sinal-de-cada-minuto), para o cliente não ser a autoridade.

## Escopo

- A rota `POST /v1/me/counters/ping`, com as horas, os dias, os dias seguidos e os hexágonos por bioma.
- Os `biomeIds` e o `hexesCreditedAt` na exploração guardada.
- No jogo: o relógio do sinal no `Session` e a contagem de hexágonos na tela de Explorar.

## Fora do escopo

- Contar o passeio da ilha da Home.
- Guardar os hexágonos não enviados no aparelho: se o app fechar antes do sinal, eles se perdem.

## Requisitos

- **RF-01:** `POST /v1/me/counters/ping` aceita `{ "hexes": [{ "biome": slug, "count": int ≥ 0 }] }`, com no máximo 32 itens, e responde 204. Sem Domador, 404.
- **RF-02:** As horas: com `elapsed = agora - last_ping_at` até `PING_MAX_GAP` (90 s), `play_seconds` sobe `round(elapsed / 1000)`; com `last_ping_at` nulo ou `elapsed` acima disso, não sobe. O `last_ping_at` vira agora.
- **RF-03:** Os dias: com o dia de hoje em `America/Sao_Paulo` diferente de `last_play_day`, `play_days` sobe 1, e `play_streak` vira o anterior + 1 se `last_play_day` for ontem, ou 1 se não for. O `last_play_day` vira hoje. O primeiro sinal de um Domador novo já conta o dia.
- **RF-04:** Os hexágonos só contam com uma exploração aberta. Um bioma que não está nos `biomeIds` dela é ignorado.
- **RF-05:** O total aceito é no máximo `floor((agora - hexesCreditedAt) / MIN_STEP_MS)`. Acima disso, cada bioma é cortado na mesma proporção (`floor(count × teto / total)`). `biome_hexes` sobe por bioma, e `hexes_walked`, pela soma aceita. O `hexesCreditedAt` vira agora, e começa no horário de abertura da exploração.
- **RF-06:** No jogo, cada troca do `_player_coord` durante o andar de Explorar soma 1 no bioma do hexágono novo.
- **RF-07:** O `Session` manda o sinal a cada 60 s enquanto há um Domador carregado e o app está na frente, e um sinal na hora ao carregar o Domador, ao ir para o fundo, ao voltar para a frente, ao esconder Explorar (antes da luta) e ao sair dela. O sinal da volta recomeça a contagem: sem ele, o primeiro minuto depois da volta passaria dos 90 s e seria perdido.
- **RF-08:** Um sinal que falha devolve os hexágonos à fila do próximo, sem aviso, como as descobertas da névoa.

## Critérios de aceite

- [x] Com o jogo aberto 3 minutos, `play_seconds` fica entre 150 e 190.
- [x] Com o app 5 minutos no fundo, `play_seconds` não sobe por esse tempo.
- [x] Andar 20 hexágonos em Explorar sobe `hexes_walked` em 20, e os biomas pisados aparecem em `biome_hexes`.
- [x] Um sinal com 500 hexágonos 1 minuto depois de abrir a exploração aceita no máximo `floor(60000 / MIN_STEP_MS)`.
- [x] Um sinal com um bioma que não está no mapa não conta nada para ele.
- [x] Jogar em dois dias seguidos deixa `play_days` 2 e `play_streak` 2; pular um dia volta o `play_streak` a 1.

## Desenho técnico

**Domínio** (`server/src/domain/counters/ping.ts`, sem Nest nem Prisma):

- `PING_MAX_GAP_MS = 90_000` e `PLAY_TIME_ZONE = 'America/Sao_Paulo'`.
- `playSecondsFor(lastPingAt: Date | null, now: Date): number`, a RF-02.
- `playDayOf(now: Date): string`, o `AAAA-MM-DD` no fuso, pelo `Intl.DateTimeFormat('en-CA', { timeZone })`.
- `nextStreak(lastPlayDay: string | null, today: string, streak: number): { newDay: boolean; streak: number }`, a RF-03.
- `cappedHexes(hexes: { biomeId: number; count: number }[], limit: number): { biomeId: number; count: number }[]`, a RF-05.

**Servidor:**

- `server/src/exploration/exploration.store.ts`: o `StoredExploration` ganha `biomeIds: Set<number>` e `hexesCreditedAt: number`, preenchidos no `ExplorationService.start` e no `startIsland` com os biomas dos hexágonos do mapa (os slugs trocados pelo id do catálogo de biomas, `biomeIdsOf`). O próprio `ExplorationStore` ganha `creditHexes(userId, hexes): BiomeHexes[]`, que filtra pelos `biomeIds`, aplica o `cappedHexes` com o `MIN_STEP_MS`, grava o `hexesCreditedAt` e devolve o aceito (vazio sem exploração). Ele fica no guarda, e não no `ExplorationService`, porque o `ExplorationModule` já depende do `CountersModule` (o `maps_explored`).
- `server/src/exploration/exploration-store.module.ts`: o `ExplorationStore` num módulo só dele, importado pelo `ExplorationModule` (que o reexporta para a luta) e pelo `CountersModule`, sem ciclo entre os dois.
- `MIN_STEP_MS` (300) sai do `battle-records.service.ts` e passa a ser exportado de `server/src/domain/exploration/hex.ts`.
- `server/src/counters/counters.service.ts`: `ping(userId, body)`, numa transação: troca os slugs pelo id do bioma (um slug desconhecido sai), lê `last_ping_at` e `last_play_day`, chama as funções do domínio e o `creditHexes`, grava as duas colunas, os `increments` e o `play_streak` (este por `upsert` com `set`). A gravação das duas colunas é um `updateMany` com `last_ping_at` igual ao lido: se outro sinal chegou ao mesmo tempo e ganhou, este não soma tempo nem dia, e só os hexágonos contam.
- `server/src/counters/counters.controller.ts`: `@Post('ping')` com `@HttpCode(204)` e o DTO `CountersPingDto` (`class-validator`, como os outros DTOs).

**Jogo:**

- `res://core/services/game_service.gd` e `api_game_service.gd`: `send_counters_ping(hexes: Dictionary[String, int]) -> Result`.
- `res://core/autoload/session.gd`: `count_hex(biome: String)`, a fila `_pending_hexes: Dictionary[String, int]`, `send_counters_ping()` (que tira a fila, manda e a devolve se falhar) e um `Timer` de 60 s, ligado quando o Domador é carregado e parado sem Domador; o `_notification` trata `NOTIFICATION_APPLICATION_PAUSED` e `NOTIFICATION_APPLICATION_FOCUS_OUT` (mandar na hora e parar) e `NOTIFICATION_APPLICATION_RESUMED` e `NOTIFICATION_APPLICATION_FOCUS_IN` (recomeçar o relógio).
- `res://screens/exploration/exploration_screen.gd`: no laço do andar, onde o `_player_coord` muda (hoje perto da linha 437), `Session.count_hex(_map.tile_at(coord).biome)`; ao sair de Explorar, junto do `Session.send_island_discoveries()`, o `Session.send_counters_ping()`.

## Verificação

- `npm test` (os testes de `ping.spec.ts`) e o `test/counters.e2e-spec.ts` com os casos do sinal; a suíte inteira antes do commit.
- `godot --headless -d --path client --quit-after 60`, sem erro nem aviso de script.
- No jogo (F5), com o servidor no ar: andar em Explorar, esperar 1 minuto e ver `hexes_walked` e `play_seconds` subirem no `GET /v1/me/counters` (pelo `/docs`). Quem implementa diz o que conferiu e o que fica para o dono.

## Tarefas

- [x] **Domínio, primeiro os testes.** `server/src/domain/counters/ping.spec.ts`:
  - `playSecondsFor(null, agora)` → 0; 60 s depois → 60; 91 s depois → 0;
  - `playDayOf(new Date('2026-11-22T02:30:00Z'))` → `'2026-11-21'` (ainda dia 21 em Brasília);
  - `nextStreak(null, '2026-11-21', 0)` → `{ newDay: true, streak: 1 }`; `nextStreak('2026-11-20', '2026-11-21', 3)` → `{ true, 4 }`; `nextStreak('2026-11-19', '2026-11-21', 3)` → `{ true, 1 }`; `nextStreak('2026-11-21', '2026-11-21', 4)` → `{ false, 4 }`;
  - `cappedHexes([{1, 30}, {2, 10}], 20)` → `[{1, 15}, {2, 5}]`; abaixo do teto, sai igual.
  Rode, veja falhar, escreva `ping.ts`, rode até passar.
- [x] **A exploração.** Os campos novos do `StoredExploration` e o `creditHexes`, com casos no `exploration.store.spec.ts` ou num spec do serviço: sem exploração devolve vazio, e um bioma fora dos `biomeIds` sai.
- [x] **A rota.** Casos e2e no `test/counters.e2e-spec.ts`: o primeiro sinal conta o dia e nada de tempo; dois sinais com o relógio controlado (o teste regrava `last_ping_at` e `last_play_day` no banco e o `hexesCreditedAt` no guarda) somam o tempo; o teto e o bioma de fora; sem exploração os hexágonos não contam; corpo com 33 itens → 400. Escreva o DTO, o `ping` e a rota até passar.
- [x] **O jogo.** O serviço, o `Session` e a tela de Explorar; rode o jogo sem janela e faça a conferência manual.
- [x] Rode a suíte inteira, marque as tarefas e mude o status desta fase e da tabela do [README](README.md) para `concluída`.

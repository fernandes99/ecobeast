# player-stats: arquitetura

O desenho que as 3 fases dividem. As decisões e os motivos estão no [README](README.md).

## Dados

### O catálogo `counters`

Uma tabela de design no schema `ecobeasts`, com ids estáveis, como as outras do catálogo ([game-data/architecture.md](../game-data/architecture.md)):

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave, estável |
| `slug` | text | único, `^[a-z0-9_]+$`; o código procura o contador pelo slug |
| `name` | text | o nome em pt-BR, mostrado no Perfil |
| `subject` | text | `none`, `element`, `day_phase` ou `biome`: o que o `subject_id` das linhas do jogador quer dizer |

Ela entra no `GET /v1/catalog` e é conferida pelo `CatalogValidator` do jogo (`res://core/data/catalog_validator.gd`). Como toda tabela nova do catálogo, muda junto `server/prisma/schema.prisma`, `server/src/catalog/catalog-tables.ts`, `res://core/data/catalog_schema.gd` e `.specs/game-data/architecture.md`; as linhas entram pela migration e pelo `server/prisma/seed-data/counters.json`, porque o `seed.ts` lê um arquivo por tabela de `CATALOG_TABLES`, como o `voices.json` da `dialogue-voices`.

Os contadores da primeira leva (ids e nomes _a revisar_):

| id | slug | subject | O que conta |
| --- | --- | --- | --- |
| 1 | `wins_wild` | none | Vitórias contra selvagens |
| 2 | `wins_tamer` | none | Vitórias contra Domadores (do mapa e do Desafiar) |
| 3 | `defeats` | none | Derrotas |
| 4 | `captures` | none | Ecobeasts capturados |
| 5 | `spheres_used` | none | Esferas gastas na luta |
| 6 | `captures_first_sphere` | none | Lutas que terminaram em captura com uma Esfera só gasta |
| 7 | `captures_by_element` | element | Capturas por Elemento (um de dois Elementos conta nos dois) |
| 8 | `captures_by_day_phase` | day_phase | Capturas por parte do dia, pelo relógio do mundo na hora da captura |
| 9 | `hexes_walked` | none | Hexágonos andados em Explorar |
| 10 | `biome_hexes` | biome | Hexágonos andados em cada bioma; os biomas pisados são as linhas com valor acima de 0 |
| 11 | `maps_explored` | none | Explorações abertas, na ilha ou no mapa sorteado |
| 12 | `xp_gained` | none | XP ganho pela equipe, somado |
| 13 | `coins_earned` | none | Moedas ganhas nas lutas |
| 14 | `coins_spent` | none | Moedas gastas na Loja |
| 15 | `heals` | none | Curas no Refúgio |
| 16 | `play_seconds` | none | Segundos jogados |
| 17 | `play_days` | none | Dias diferentes em que o jogador jogou |
| 18 | `play_streak` | none | Dias seguidos até hoje; volta a 1 quando um dia passa sem jogo |

Todo contador só cresce, menos o `play_streak`, que o servidor regrava.

### As linhas do jogador

`player_counters`:

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `player_id` | uuid | FK `players`, apaga junto |
| `counter_id` | int | FK `counters`, restrict |
| `subject_id` | int | 0 quando o `subject` é `none`; senão o id do Elemento, da parte do dia ou do bioma |
| `value` | int | ≥ 0; o `int` cabe 68 anos de `play_seconds` e evita o `BigInt`, que o JSON não serializa |

A chave é (`player_id`, `counter_id`, `subject_id`). Um índice em (`counter_id`, `subject_id`, `value` desc) deixa o ranking futuro numa consulta só. O `subject_id` não tem FK porque aponta para tabelas diferentes conforme o `subject`; o servidor só grava ids que leu do catálogo.

Uma conquista futura é uma linha "contador X, recorte Y, chegou a N", ligada ao `counters`.

### Fora do `player_counters`

- `creature_instances.battles` (int, ≥ 0, padrão 0): as lutas de cada Ecobeast, para o "parceiro". É um número do Ecobeast, e não do Domador.
- `players.last_ping_at` (timestamptz, nulo) e `players.last_play_day` (date, nulo): o estado do sinal de cada minuto.

## Onde cada contador sobe

Todo incremento é um `upsert` com `increment`, dentro da transação que já grava o evento, para o número nunca divergir do que aconteceu.

| Lugar | Contadores |
| --- | --- |
| `BattleRecordsService.finish` / `saveTeam` (`server/src/battle/battle-records.service.ts`) | 1 a 8, 12, 13 e `creature_instances.battles`. Nada sobe na luta `sandbox`, na luta com `noRewards` nem com `godMode` |
| `InventoryService.buy` (`server/src/inventory/inventory.service.ts`) | 14, com o preço pago |
| A cura do Refúgio (`POST /v1/me/heal`, `PlayerController`) | 15 |
| `ExplorationService.start` e `startIsland` (`server/src/exploration/exploration.service.ts`) | 11 |
| O sinal de cada minuto (`POST /v1/me/counters/ping`) | 9, 10 e 16 a 18 |

Na luta:

- **Esfera** é o item com `captureBonus`; as Esferas gastas são o `used` desses itens no `state.bag`.
- **Quem lutou** é a união dos `foughtBy` dos inimigos, o mesmo critério da divisão de XP (`server/src/domain/battle/experience.ts`). Cada um ganha +1 em `battles`, na vitória e na derrota.
- **O Elemento** do capturado vem da espécie; **a parte do dia** vem do `dayPhaseAt` do relógio do mundo (`server/src/domain/world-clock/world-clock.ts`), como o `ProgressionService` já faz.

## O sinal de cada minuto

`POST /v1/me/counters/ping`, com o corpo `{ "hexes": [{ "biome": "plains", "count": 12 }, ...] }`: o bioma vai pelo slug, que é o que o `HexTile.biome` do jogo guarda, e o servidor troca pelo id do catálogo. A lista pode vir vazia. A resposta é 204.

O servidor faz, nesta ordem:

1. **Horas.** `elapsed = agora - last_ping_at`. Se `elapsed` for até `PING_MAX_GAP` (90 s), soma `elapsed` em `play_seconds`; senão não soma nada, porque o app ficou fechado ou parado. Grava `last_ping_at = agora`.
2. **Dias.** O dia de hoje em `America/Sao_Paulo`. Se for diferente de `last_play_day`: `play_days` +1, e o `play_streak` vira +1 se `last_play_day` for ontem, ou 1 se não for. Grava `last_play_day`.
3. **Hexágonos.** Só com uma exploração aberta no `ExplorationStore`. Ela ganha `biomeIds` (os biomas do mapa, guardados no `start` e no `startIsland`) e `hexesCreditedAt`. Um bioma fora de `biomeIds` é ignorado. O total aceito é no máximo `floor((agora - hexesCreditedAt) / MIN_STEP_MS)`; se passar, os biomas são cortados na mesma proporção. Soma em `biome_hexes` por bioma e o total em `hexes_walked`, e grava `hexesCreditedAt = agora`.

O jogo manda o sinal a cada 60 s enquanto o app está na frente, e um último ao ir para o fundo (`NOTIFICATION_APPLICATION_PAUSED` e `NOTIFICATION_APPLICATION_FOCUS_OUT`) e ao sair de Explorar. Os hexágonos que não foram enviados voltam para a fila do próximo sinal, como as descobertas da névoa (`Session.send_island_discoveries`).

No aparelho, o `exploration_screen.gd` soma 1 no bioma do hexágono novo cada vez que o `_player_coord` muda durante o andar. O Domador não anda na água, então todo bioma contado é de terra.

## A leitura

`GET /v1/me/counters`:

```json
{
  "counters": [{ "counter_id": 1, "subject_id": 0, "value": 102 }],
  "partner": { "creature_uid": "…", "species_id": 19, "battles": 212 },
  "created_at": "2026-10-03T14:00:00Z",
  "walkable_biomes": 10
}
```

Só vêm as linhas do jogador; um contador sem linha vale 0. O `partner` é nulo enquanto nenhum Ecobeast lutou. O jogo acha cada número pelo slug do catálogo `counters`.

## O Perfil

O esboço A, escolhido pelo dono:

```
[Domador]  Nome  Nv 24
           Domador desde 03/10/2026
[ 128 Vitórias ] [ 57 Capturas ] [ 37h Jogadas ]
[Luta] [Captura] [Mapa] [Ecobeasts] [Geral]
  linha: nome ............ valor
  ...
[Aparência]
```

- Os 3 destaques: vitórias (selvagens + Domadores), capturas e horas jogadas.
- **Luta:** vitórias contra selvagens, vitórias contra Domadores, derrotas e taxa de vitória (vitórias ÷ (vitórias + derrotas), "—" sem luta).
- **Captura:** capturas, Esferas usadas, na primeira Esfera, espécies vistas e capturadas do Bestiário, e as capturas por Elemento e por parte do dia.
- **Mapa:** hexágonos andados, mapas explorados e biomas pisados, como "9 de 12". O total são os biomas do catálogo que não são água (a regra do `isWater` de `server/src/domain/exploration/map-generator.ts`), vindo do servidor junto do `GET /v1/me/counters` como `walkable_biomes`.
- **Ecobeasts:** XP ganho e o parceiro, com o rosto (`CreatureFace`) e as lutas.
- **Geral:** horas jogadas, dias jogados, dias seguidos, moedas, moedas ganhas, moedas gastas e curas no Refúgio.

Os textos e os números usam o tema de hoje (`SecondaryLabel` e `BoldLabel`) e o `NumberFormat.thousands`.

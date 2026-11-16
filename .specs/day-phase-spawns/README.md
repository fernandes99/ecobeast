# day-phase-spawns

Cada Ecobeast tem as partes do dia em que pode nascer como selvagem. Ao entrar num mapa, o servidor olha a parte do dia daquele momento e só sorteia os Ecobeasts dela, no mapa sorteado e nas áreas das ilhas.

## Contexto

Em 2026-11-15, o dono pediu: "agora temos diferença de manhã, tarde nite e final da tarde, e vão ter ecobeasts que só vão poder aparecer em um determinado tempo, para isso quero registrar isso para cada ecobeast. hoje todos os ecobeast podem ser encontrados em todos os periodos."

A [day-night](../day-night/) criou o relógio do mundo (`server/src/domain/world-clock/world-clock.ts`, um dia em 24 minutos reais) e as 4 partes do dia no catálogo (`day_phases`: Manhã às 6h, Tarde às 12h, Final de tarde às 17h e Noite às 19h). A hora ainda não muda nenhuma regra.

Hoje os selvagens são sorteados uma vez, quando o Domador entra no mapa (`POST /v1/me/exploration`), e ficam na memória do servidor até ele sair:

- **No mapa sorteado**, por `rollSpawns` (`server/src/domain/exploration/spawns.ts`), com as taxas por bioma de `species_biomes`, lidas por `loadSpawnSpecies` (`server/src/exploration/spawn-data.ts`).
- **Nas ilhas**, por `rollAreaSpawns` (`server/src/domain/islands/area-spawns.ts`), com a lista de Ecobeasts de cada área, escolhida no editor.

As equipes dos Domadores NPC do mapa e do Desafiar também saem de `loadSpawnSpecies`.

## Objetivos

1. Guardar, para cada Ecobeast, as partes do dia em que ele pode nascer, editáveis pelo painel do Supabase.
2. Começar com todos os Ecobeasts em todas as partes do dia, para nada mudar até o dono tirar alguma.
3. Ao entrar no mapa sorteado ou numa ilha, só nascem os Ecobeasts da parte do dia daquele momento.

## Anti-objetivos

- Um Ecobeast sumir do jogo sem o dono ter tirado as partes do dia dele.
- A hora do celular decidir quem nasce.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| O período é registrado por Ecobeast | "quero registrar isso para cada ecobeast" |
| Hoje todos podem nascer em todos os períodos | "hoje todos os ecobeast podem ser encontrados em todos os periodos" |
| O período vale só ao entrar no mapa: os selvagens ficam até o Domador sair, mesmo que a parte do dia mude | Escolheu "Só ao entrar" no lugar de trocar os selvagens na virada |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Uma tabela de ligação, `species_day_phases` (`species_id`, `day_phase_id`), com uma linha por parte do dia em que o Ecobeast nasce | É o formato das outras listas do catálogo, como `species_biomes`, e o [game-data/architecture.md](../game-data/architecture.md) pede FKs `<singular>_id` |
| Sem linha, o Ecobeast não nasce naquela parte do dia; a migração grava as 4 partes para todo Ecobeast que já existe | Igual a `species_biomes`, onde sem linha ele não nasce naquele bioma. Um Ecobeast novo, criado pelo painel, precisa das linhas dele, como já precisa das de bioma |
| O filtro vale para os selvagens do mapa sorteado e das áreas das ilhas | São os dois sorteios de selvagens |
| As equipes dos Domadores NPC (no mapa e no Desafiar) não são filtradas | O Domador leva os Ecobeasts dele a qualquer hora |
| O Ecobeast posto pelo debug (`POST /v1/me/exploration/spawns`) não é filtrado | É para testar qualquer espécie |
| A parte do dia vem do relógio do servidor (`minuteOfDay(Date.now())`) | O servidor é a autoridade, e é a mesma hora que o jogo mostra |
| Com `ENABLE_TEST_BATTLE` ligado, a entrada aceita `debug_minute`, e o jogo o manda quando a hora de debug está mexida | O "Debug: +1 hora" do jogo só muda a hora no aparelho; sem isso, testar a Noite pediria esperar até 24 minutos |
| Uma área de ilha sem nenhum Ecobeast da parte do dia fica vazia; um bioma sem nenhum, também | É o mesmo que acontece hoje com um bioma sem taxa |

## Fora do escopo

- Trocar os selvagens quando a parte do dia muda com o Domador no mapa.
- Mostrar no Bestiário, no editor de ilhas ou no F1 em que partes do dia cada Ecobeast nasce; por enquanto, edita-se pelo painel do Supabase.
- Taxas diferentes por parte do dia (mais comum à Noite, por exemplo): aqui é só nasce ou não nasce.
- Partes do dia por bioma ou por área de ilha (nascer na Floresta só à Noite).
- A Evolução por horário (`evolutions.time_of_day`).

## Pré-requisitos

- [day-night](../day-night/): o relógio do mundo e a tabela `day_phases`.
- [biome-encounters](../biome-encounters/) e [islands](../islands/): os dois sorteios de selvagens.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-phase-spawns](01-phase-spawns.md) | A tabela `species_day_phases` e o filtro no sorteio dos selvagens | concluída (falta o dono conferir) |

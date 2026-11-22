# player-stats

O Perfil passa a mostrar os números do Domador: vitórias e derrotas, capturas, distância andada, biomas pisados, horas jogadas e outros. O objetivo é dar mais vontade de jogar. O servidor conta cada número no momento em que o evento acontece. Os contadores ficam guardados de um jeito que serve, depois, para as conquistas e para um ranking.

- **Status:** aprovada
- **Depende de:** [hub-start](../hub-start/) (a tela Perfil), [board-battle](../board-battle/), [inventory-shop](../inventory-shop/), [heal-station](../heal-station/), [wild-battle](../wild-battle/) e [day-night](../day-night/)

## Contexto

Em 2026-11-21 o dono escreveu: "nas informações do jogador quero salvar e mostrar para eles varios dados, como: vitórias, derrotas, horas jogadas, ecobeast capiturados, e etc... eu quero mostrar muitas coisas [...] A ideia e trazer mais empolgação para jogar o jogo."

Claude conferiu o jogo de hoje:

- A tela Perfil (`res://screens/profile/profile_screen.gd`, [hub-start/02](../hub-start/02-ecobeasts-profile-settings.md)) mostra o Domador desenhado, o nome, o nível, as moedas e as espécies vistas e capturadas do Bestiário. A hub-start deixou "medalhas, tempo de jogo ou estatísticas" fora do escopo, e o [roadmap](../roadmap.md) tinha a `profile-settings` planejada, com as Configurações já entregues pela hub-start.
- A tabela `players` não guarda nenhum contador. Por isso os números começam do zero no dia em que esta iniciativa entrar.
- O fim de cada luta é uma transação só (`BattleRecordsService.finish`, em `server/src/battle/battle-records.service.ts`), que já sabe o resultado (`victory`, `defeat`, `fled` ou `captured`), o oponente (`wild` ou `tamer`), o XP de cada um, as moedas, as Esferas gastas e quem foi capturado.
- O Domador anda só no aparelho. O servidor só confere onde ele está quando ele entra numa luta (`confirmPosition`, com o passo mínimo `MIN_STEP_MS`). Nada mede o tempo de jogo.
- O nome `stats` já é o catálogo dos atributos (HP, Ataque…, `model Stat`). Os números do Domador se chamam **contadores** no código.

## Objetivos

1. O jogador vê, no Perfil, o quanto já jogou e o que já conquistou.
2. Cada número é decidido pelo servidor, e o jogo só mostra.
3. Uma conquista ou um ranking futuros leem os contadores sem mudar o jeito de guardar.

## Não objetivos

- Conquistas, medalhas e ranking: vêm depois, lendo os contadores.
- Mostrar o perfil de um jogador para outro.
- Recalcular o passado: os contadores começam do zero.

## Os números

Escolhidos pelo dono em 2026-11-21, depois de descartar a sequência de vitórias, o golpe mais forte, a vitória mais apertada, os Ecobeasts derrotados, as fugas, os golpes super efetivos, a taxa de acerto das Esferas, a captura mais rara, a névoa descoberta, os NPCs, as pontes, as Evoluções, as Técnicas aprendidas, o companheiro mais antigo, os itens usados e a parte do dia favorita.

| Tema | Números |
| --- | --- |
| Luta | Vitórias contra selvagens, vitórias contra Domadores, derrotas e taxa de vitória |
| Captura | Capturas no total, Esferas usadas, capturas na primeira Esfera, capturas por Elemento e capturas por parte do dia; as espécies vistas e capturadas do Bestiário continuam |
| Mapa | Distância andada em hexágonos, mapas explorados e biomas pisados ("9 de 12") |
| Ecobeasts | XP ganho no total e o Ecobeast mais usado em luta (o "parceiro") |
| Geral | Horas jogadas, dias jogados, dias seguidos, moedas, moedas ganhas, moedas gastas e curas no Refúgio |

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| Só o próprio jogador vê os números, por enquanto | "só o jogador por enquanto" |
| Os contadores servem, depois, para o ranking e para as conquistas | "vamos guardando os contadores de um jeito que sirva para ranking e conquistas depois" |
| O Perfil segue o esboço A: 3 números grandes no topo e o resto em abas por tema | Ele escolheu o A entre três esboços (o B tinha cartões com a barra do próximo marco, e o C um cartão do Domador) |
| Um catálogo de contadores mais as linhas do jogador, no lugar de uma coluna por número ou de um registro de eventos | Ele escolheu a opção 1: encaixa na regra dos dados de design (ids estáveis, editáveis no painel), e a conquista é "o contador X chegou a N" |
| A distância andada entra, contada no aparelho e mandada a cada minuto junto com o sinal de tempo | "podemos guardar essa informação no cliente, um count que cresce cada vez que o usuário muda um hexagono e enviamos essa info junto a cada minuto junto com o sync do tempo" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O servidor põe um teto na distância e nas horas: aceita no máximo os hexágonos que caberiam no tempo que passou (pelo `MIN_STEP_MS`) e no máximo o tempo real entre dois sinais | O cliente não é a autoridade; com o teto, trapacear rende no máximo "andar sem parar", e o número já nasce bom para um ranking |
| Os hexágonos vêm separados por bioma, e o servidor só aceita um bioma que existe no mapa aberto | Os biomas pisados saem do mesmo pacote, conferidos pelo mapa que o próprio servidor gerou ou leu |
| Só o andar de Explorar conta, e não o passeio da ilha da Home | A ilha da Home é um enfeite do Hub, sem exploração no servidor |
| A luta de teste da Técnica (`sandbox`) e a luta com o modo deus (`godMode`) não contam | São ferramentas de desenvolvimento |
| Um Ecobeast de dois Elementos conta uma captura para cada Elemento | "Capturas de Água" deve incluir o Tempestide, que é Água/Volt |
| A "captura na primeira Esfera" é a luta que termina em captura com uma Esfera só gasta | É o que o fim da luta já sabe, sem guardar cada arremesso |
| As moedas gastas são só as da Loja; as moedas perdidas numa derrota não entram | "Gastas" é o que o jogador escolheu gastar |
| O dia de jogo usa a hora de Brasília (`America/Sao_Paulo`) | O jogo é em pt-BR e o servidor precisa de um fuso para a virada do dia; com jogadores fora do Brasil, isso muda |
| O "parceiro" é o Ecobeast do jogador com mais lutas, contado em `creature_instances.battles`; uma luta conta para quem lutou, pelo mesmo critério da divisão de XP | O número é de cada Ecobeast, e não do Domador; se ele for solto, sai junto |
| A taxa de vitória é vitórias ÷ (vitórias + derrotas); a fuga e a captura ficam de fora | Fugir e capturar não são perder |
| A quinta aba se chama Geral e junta o tempo, as moedas e as curas | O esboço tinha a aba Tempo, mas as moedas e as curas não cabiam em outra |

## Fora do escopo

- Conquistas, medalhas, barras do próximo marco e ranking.
- O perfil público e a comparação com outros jogadores.
- Mudar as Configurações.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-counters-server](01-counters-server.md) | O catálogo `counters`, as linhas `player_counters`, os contadores da luta, da Loja, do Refúgio e de Explorar e a rota `GET /v1/me/counters` | aprovada |
| 2 | [02-play-ping](02-play-ping.md) | O sinal de cada minuto (`POST /v1/me/counters/ping`), com as horas, os dias, os dias seguidos e os hexágonos por bioma, e o lado do jogo que conta e manda | aprovada |
| 3 | [03-profile-screen](03-profile-screen.md) | O Perfil do esboço A, com os destaques e as 5 abas | aprovada |

O desenho que as fases dividem está no [architecture.md](architecture.md).

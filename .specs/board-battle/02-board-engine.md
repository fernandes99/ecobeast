# 02. Motor do tabuleiro

- **Status:** concluída
- **Depende de:** [01](01-skill-areas.md), [battle-slots/01](../battle-slots/01-engine-slots.md), [architecture.md](architecture.md)

## Contexto

O motor de hoje (`server/src/domain/battle/engine.ts`) joga turnos em que todos escolhem juntos e agem por prioridade e Velocidade. A battle-slots deixou as peças dele (dano, efeitos, status, Traços, XP, moedas, captura) recebendo um `Spot {side, position}`, então elas servem para mais de um Ecobeast por lado.

Esta fase escreve o juiz do tabuleiro sobre essas peças, em `server/src/domain/board/`, só com testes unitários. Nenhuma rota usa o motor ainda, e o motor antigo não muda.

## Escopo

- Geometria, estado, largada, fila e vez.
- Andar, áreas das Técnicas, alvo e marcas no chão.
- Fim da vez, queda e entrada, troca, item, Esfera, fuga, espera e fim da luta.
- A IA dos selvagens.

## Fora do escopo

- Rotas e DTOs (vêm na [03](03-board-api.md)).
- Formas além de `single` e `line`, empurrar e puxar.
- A prioridade das Técnicas.

## Requisitos

**Tabuleiro e largada**

- **RF-01:** `makeBoard()` devolve os 42 hexágonos de 6 × 7 e as duas áreas do [architecture.md](architecture.md#tabuleiro).
- **RF-02:** `startBoardBattle(player, enemies, catalog, random, bag, options)` aceita `slots` de 1 a 3 por lado. Cada vaga ocupada começa no hexágono de largada da tabela de colunas, com os eventos de entrada e os Traços de hoje, e a primeira rodada começa.

**Fila e vez**

- **RF-03:** A fila de cada rodada tem todos os Ecobeasts de pé no tabuleiro, pela Velocidade efetiva, com empate sorteado e sem prioridade. Evento `round_started`.
- **RF-04:** `applyBoardVez(state, vez, catalog, random)` só aceita a vez do primeiro da fila, quando ele é do jogador. Fora disso, recusa com "Não é a vez desse Ecobeast.".
- **RF-05:** Depois da vez do jogador, o motor joga as vezes dos selvagens até a próxima vez do jogador, um `choose_next` ou o fim, e devolve todos os eventos na ordem.
- **RF-06:** Quem não pode agir (sono, congelamento, paralisia, medo) perde a vez inteira, sem andar. Item, troca, Esfera e fuga sem andar são do Domador e não passam por essa conferência, como na luta de hoje.

**Andar**

- **RF-07:** `move` é um hexágono a até `MOVE_RANGE` (3) passos por hexágonos sem Ecobeast. Um hexágono ocupado ou longe demais é recusado com "Não dá para chegar lá.", e mandar `move` com `flee` é recusado com "Fugir não combina com andar.".
- **RF-08:** O evento `moved` leva um dos caminhos mais curtos, sem a origem. Andar por cima de uma marca não aplica nada.

**Técnicas**

- **RF-09:** A área de cada Técnica segue [Técnicas no tabuleiro](architecture.md#técnicas-no-tabuleiro). A Técnica em si mesmo ignora o alvo.
- **RF-10:** Um alvo fora do alcance, fora das linhas retas na `line`, ou sem inimigo numa `single` sem marca é recusado com as mensagens do architecture.md, sem mudar nada.
- **RF-11:** Cada inimigo atingido sofre a Técnica com os próprios sorteios, na ordem do caminho. O PP é gasto uma vez, mesmo sem ninguém atingido.
- **RF-12:** A Técnica com marca deixa a marca em cada hexágono da área, substituindo a que já houver, com `mark_placed`.
- **RF-13:** A Técnica de emergência é corpo a corpo, com alcance 1.

**Fim da vez**

- **RF-14:** O fim da vez segue a ordem do [architecture.md](architecture.md#rodada-e-vez): status de quem jogou, marcas sobre quem está nelas, `remaining` das marcas, desmaios e entradas, e fim da luta.
- **RF-15:** Cada marca age sobre todo Ecobeast de pé no hexágono dela, dos dois lados, com `ground_damage` (no mínimo 1 de dano) e o status do `ground_effect`, com as imunidades de hoje.

**Entrada, troca, item, Esfera e fuga**

- **RF-16:** Um desmaio do jogador com reserva leva ao `choose_next`, com `pendingPositions` e `entryCells`. Cada entrada precisa de um `cell` entre os `entryCells`, sem repetir, senão é recusada com "Esse hexágono não está livre para entrar.".
- **RF-17:** Um desmaio do inimigo com reserva põe o próximo no primeiro hexágono livre da área do inimigo, linha da frente primeiro.
- **RF-18:** Quem entra, por queda ou troca, só joga na rodada seguinte. Na troca, ele fica no hexágono de quem saiu.
- **RF-19:** A Esfera vale contra qualquer selvagem do tabuleiro, pelo hexágono dele. O capturado sai do tabuleiro, e a luta continua se sobrar selvagem de pé.
- **RF-20:** Item, troca, Esfera e fuga gastam a vez, com as regras e as recusas de hoje. A fuga vale para a equipe toda.
- **RF-21:** `wait` só gasta a vez, com `waited`.

**IA, fim e recompensas**

- **RF-22:** A IA segue [A vez dos selvagens](architecture.md#a-vez-dos-selvagens).
- **RF-23:** O fim da luta, o XP de quem esteve no tabuleiro contra cada selvagem e as moedas por selvagem seguem a battle-slots, com os mesmos eventos.

## Critérios de aceite

- [x] Num 1×1, os dois começam a 4 hexágonos, nas linhas 1 e 5, e a fila põe o mais rápido primeiro.
- [x] Andar 3 passos por hexágonos livres funciona. 4 passos, ou passar por um Ecobeast, é recusado sem mudar nada.
- [x] Arranhão atinge um inimigo ao lado e é recusado a 2 hexágonos.
- [x] Faísca Rápida, numa linha com dois inimigos, atinge só o primeiro. A mesma linha com `pierces` atinge os dois. Um alvo fora das 6 linhas é recusado.
- [x] Chama Espiral num hexágono vazio a 3 deixa a marca. Um Ecobeast que termina a vez nela toma dano depois de cada vez da fila, e a marca some depois de 6 vezes.
- [x] Passar por cima da marca andando não dá dano.
- [x] Num 2×2, um Ecobeast do jogador que cai com reserva leva ao `choose_next`. Quem entra fica num hexágono da área verde e não joga na mesma rodada.
- [x] A troca põe quem entra no hexágono de quem saiu.
- [x] Capturar um de dois selvagens, longe, mantém a luta com o outro.
- [x] O selvagem longe anda até o alvo mais perto, e o que já alcança fica e ataca.
- [x] Uma vez do jogador devolve os eventos de todos os selvagens até a próxima vez dele.
- [x] Os testes do motor antigo passam sem mudança.

## Desenho técnico

**Criar** em `server/src/domain/board/`:

- `board.ts`: as constantes, `makeBoard`, as casas de largada, os vizinhos dentro do tabuleiro e `reachable(state, from, steps)`.
- `areas.ts`: `areaOf(skill, from, target, state)`, com os hexágonos e os inimigos atingidos, e as recusas de alvo.
- `marks.ts`: colocar, aplicar e envelhecer as marcas.
- `queue.ts`: a fila da rodada, a partir de `compare` de `turn-order.ts` sem a prioridade.
- `board-engine.ts`: `startBoardBattle`, `applyBoardVez`, as vezes dos selvagens, o fim da vez, as entradas e o fim da luta.
- `board-ai.ts`: a vez de um selvagem.
- `types.ts`: `BoardState`, `Board`, `GroundMark`, `BoardVez` e os eventos novos.
- `testing.ts` e um `*.spec.ts` por arquivo, com os critérios de aceite.

**Reutilizar** de `server/src/domain/battle/`: `actions.ts` (o golpe contra um `Spot`), `effects.ts`, `status.ts`, `traits.ts`, `experience.ts`, `capture.ts`, `damage.ts`, `accuracy.ts`, `stages.ts`, `field.ts` e o `useItem` de `server/src/domain/items/`. Uma peça que precise de mudança muda de um jeito que o motor antigo continue igual, com os testes dele passando.

**Catálogo:** `server/src/battle/battle-catalog.ts` passa a levar `areaShape`, `range`, `pierces`, `groundEffectId` e `groundTurns` em cada `BattleSkill`, e os `ground_effects`.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test
```

## Tarefas

- [x] Tabuleiro, largada e fila, com os testes falhando primeiro (RF-01 a RF-06).
- [x] Andar (RF-07 e RF-08).
- [x] Áreas, alvo e marcas (RF-09 a RF-15).
- [x] Entrada, troca, item, Esfera, fuga e espera (RF-16 a RF-21).
- [x] IA, fim e recompensas (RF-22 e RF-23).
- [x] Rodar a verificação, marcar a spec e o README como `concluída` e fazer o commit `feat: motor da luta no tabuleiro`.

## Divergências

O que a implementação fez diferente desta spec e do [architecture.md](architecture.md), e por quê:

- **Item, troca, Esfera e fuga sem andar** não passam pelo "pode agir?" (RF-06): quem age é o Domador, como na luta de hoje. Sem isso, um Ecobeast dormindo nunca poderia ser trocado.
- **A fila guarda quem ocupava a vaga** (`QueueEntry`, com `teamIndex`). Assim, quem entra numa vaga que ainda tinha lugar na fila não herda esse lugar (RF-18).
- **`creature_left` sai sempre que alguém deixa o tabuleiro**, desmaiado ou capturado, mesmo com reserva para entrar. Na luta de hoje, ele só sai quando a vaga fica vazia de vez.
- **Uma marca com status** não tenta de novo em quem já tem um status principal: ela age a cada vez da fila, e repetiria o `effect_failed` sem parar.
- **Uma Técnica em si mesmo** não aplica os efeitos que miram o adversário: no tabuleiro não há "o adversário", e a luta de hoje usava o primeiro de pé. Nenhuma Técnica do catálogo usa isso hoje.
- **Os eventos novos** entraram no `BattleEvent` de `server/src/domain/battle/types.ts`, junto com os de hoje, porque as peças compartilhadas (dano, status, XP) empurram eventos na mesma lista. A luta de hoje nunca os gera.
- **As peças da luta de hoje** que o tabuleiro usa foram só exportadas ou divididas, sem mudar o comportamento: `resolveSkill` em `actions.ts`, `applyStatusDamage` em `status.ts`, e as recusas e o item em `engine.ts`.
- **Duas recusas novas:** "Ninguém está esperando para entrar." (quem entra fora do `choose_next`) e "Escolha o próximo Ecobeast." (uma vez no `choose_next`).

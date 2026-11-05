# 01. Vagas no motor

- **Status:** concluída em parte (a iniciativa foi substituída antes do fim, ver o [README](README.md))
- **Depende de:** [battle-core](../battle-core/), [progression](../progression/), [architecture.md](architecture.md)

## Contexto

O motor em `server/src/domain/battle/` tem um ativo por lado (`activeIndex`), recebe uma ação por turno e sempre mira o único adversário. Esta fase troca isso pelas vagas do [architecture.md](architecture.md). A luta 1 contra 1 de hoje segue com as mesmas regras e os mesmos sorteios, e o jogo continua funcionando sem mudar, pelo contrato antigo.

## Escopo

- Vagas no estado e no motor, uma ação por vaga, alvo e reposição de vaga.
- IA com alvo, XP por quem esteve em campo, e moedas por selvagem.
- Os campos novos dos eventos, o `creature_left` e o contrato novo da API, junto com o antigo.
- A batalha de teste com `slots` e `enemies`.

## Fora do escopo

- Qualquer mudança no jogo (vem na [02](02-client-slots.md)).
- Lutas de mais de uma vaga fora da batalha de teste.
- Técnicas de vários alvos ou em aliados.

## Requisitos

**Estado**

- **RF-01:** `BattleSide.activeIndices: (number | null)[]` substitui `activeIndex`, e `BattleState.player.pendingPositions: number[]` guarda as vagas que o jogador precisa preencher no `choose_next`.
- **RF-02:** `startBattle` recebe `slots: { player: number; enemy: number }` nas opções, com 1 e 1 por padrão. Cada número fica entre 1 e `MAX_SLOTS` (3).
- **RF-03:** No começo, cada vaga recebe o próximo de pé da equipe, em ordem, e o Traço de entrada vale para cada um, primeiro o jogador, em ordem de posição.

**Ações**

- **RF-04:** `applyAction` passa a receber `actions: BattleAction[]`, cada uma com `position`. A lista é conferida inteira antes de o turno começar, com as recusas do [architecture.md](architecture.md#ações). Uma recusa não muda nada.
- **RF-05:** Toda vaga ocupada por alguém de pé precisa de exatamente uma ação, e não há ação para vaga vazia ou desmaiada. A exceção é `[{"type": "flee"}]`.
- **RF-06:** `target` é a posição de um adversário de pé em campo. Ele é obrigatório em `skill`, `emergency` e `capture` contra o adversário quando há mais de um de pé, e, com um só, vale esse um.
- **RF-07:** Duas trocas para o mesmo `team_index` no mesmo turno são recusadas, com "Esse Ecobeast já vai entrar.".
- **RF-08:** No `choose_next`, a lista traz um `switch` por posição de `pendingPositions`, e só isso.

**Turno**

- **RF-09:** O turno segue a [Ordem de um turno](architecture.md#ordem-de-um-turno). Troca, item e Esfera vêm antes de qualquer Técnica, em ordem de posição. Depois, as Técnicas dos dois lados são ordenadas juntas.
- **RF-10:** A IA escolhe a Técnica de cada inimigo de pé em campo como hoje, um depois do outro em ordem de posição. Ela sorteia o alvo entre os Ecobeasts do jogador de pé em campo, sem sorteio quando há um só.
- **RF-11:** Uma Técnica cujo alvo caiu vai para o adversário de pé de menor posição, e, sem nenhum, não acontece nem gasta PP.
- **RF-12:** No fim do turno, cada vaga de alguém desmaiado ou capturado fica vazia, com `creature_left`. Depois, as vagas do inimigo são preenchidas, e as do jogador viram `pendingPositions`, como em [Vagas](architecture.md#vagas).
- **RF-13:** A Esfera com sucesso tira o capturado da luta. Ela só termina em `captured` se não sobrar inimigo de pé, e a vitória vale sempre que algum inimigo desmaiou.

**XP e moedas**

- **RF-14:** `recordEntry` anota no `foughtBy` de cada inimigo em campo todo Ecobeast do jogador que esteve em campo com ele.
- **RF-15:** `settleCoins` segue [XP e moedas](architecture.md#xp-e-moedas): um `coins_gained` por inimigo desmaiado, e um `coins_lost` com a média dos níveis.

**API**

- **RF-16:** `POST /v1/me/battle/action` aceita `{ "actions": [...] }` e o corpo antigo, como uma ação na posição 0.
- **RF-17:** A resposta traz `active_indices`, `pending_positions`, `enemy.actives` e os campos novos dos eventos, junto com `active_index`, `enemy.active` e `captured_to` na raiz, como no [architecture.md](architecture.md#api).
- **RF-18:** `POST /v1/me/battle` aceita `slots` (1 a 3) e `enemies` (1 a 6, cada um com `species_id` e `level`), além do par `species_id` e `level`. Um corpo com os dois é recusado com "Use species_id ou enemies.". `/battle/wild` continua com 1 vaga.

## Critérios de aceite

- [x] Todos os testes unitários e e2e de hoje passam, ajustados só onde o evento ganhou campos ou o `creature_left` entrou.
- [x] Num 2 contra 2:
  - cada um age uma vez por turno, na ordem de Velocidade;
  - o alvo escolhido é atingido;
  - quem caiu antes perde a vez.
- [x] Um alvo que caiu no meio do turno passa para o outro adversário de pé.
- [x] Faltar ação para uma vaga, mandar ação para uma vaga vazia ou omitir o alvo com dois adversários é recusado, sem mudar nada.
- [x] Com dois do jogador em campo e um desmaio, a fase vira `choose_next` com a posição certa. Sem reserva, a vaga fica vazia, e a luta continua.
- [x] A derrota só vem quando todos os Ecobeasts do jogador caem.
- [x] Capturar um de dois selvagens mantém a luta, e o outro continua agindo.
- [x] Dois selvagens derrubados dão dois `coins_gained`, e o XP de cada um vai para quem esteve em campo contra ele.
- [x] Fugir dentro de uma lista com outras ações é recusado.
- [ ] A batalha de teste abre um 2 contra 2 com `slots: 2` e dois `enemies`. O código existe, mas o e2e não foi escrito.
- [x] `typecheck` e `lint` passam sem erros.

## Desenho técnico

**Alterar**, em `server/src/domain/battle/`:

- `types.ts`: `BattleSide`, `pendingPositions`, a `position` e o `target` nas ações, os campos novos nos eventos e o `creature_left`.
- `field.ts`: `activeAt(state, side, position)`, `activePositions(state, side)` (as posições ocupadas por alguém de pé) e `MAX_SLOTS`. `activeOf` sai.
- `engine.ts`:
  - `startBattle` com `slots`;
  - `applyAction` com a lista;
  - as recusas;
  - a ordem do turno, a reposição e o fim.
- `actions.ts`: a `FieldAction` com autor e alvo por posição, e o alvo que cai.
- `ai.ts`: uma escolha por inimigo em campo, com o alvo.
- `effects.ts`, `status.ts` e `traits.ts`: o lado e a posição no lugar de só o lado.
- `experience.ts`: `recordEntry`, `awardXp` e `settleCoins` com vagas.
- `testing.ts`: `makeState` com `slots`.

Em `server/src/battle/`:

- `battle.dto.ts` e `battle.controller.ts`: o corpo novo e o antigo, e a batalha de teste com `slots` e `enemies`.
- `battle.mapper.ts`: os campos novos e os antigos da resposta.
- `battle.service.ts`: a lista de ações e os inimigos da batalha de teste.

**Criar:** `server/src/domain/battle/slots.spec.ts`, com as lutas 2 contra 2 dos critérios.

**Atualizar:** `.specs/battle-core/architecture.md`, com um aviso no topo apontando para o [architecture.md](architecture.md) desta iniciativa.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

O jogo abre e uma luta 1 contra 1 pelo mapa funciona como antes, pelo contrato antigo.

## Tarefas

- [x] Testes de 2 contra 2 em `slots.spec.ts`. Foram escritos depois do código; para conferir que pegam erro, o alvo que cai e as moedas por selvagem foram quebrados de propósito, e os testes falharam.
- [x] Vagas no estado, `field.ts` e `startBattle` (RF-01 a RF-03).
- [x] Lista de ações, alvo e recusas (RF-04 a RF-08).
- [x] Ordem do turno, IA, alvo que cai e reposição (RF-09 a RF-13).
- [x] XP e moedas (RF-14 e RF-15).
- [ ] API e batalha de teste (RF-16 a RF-18): o código está feito e os e2e de hoje passam, mas os e2e do corpo `actions`, de `slots` e `enemies` e da recusa "Use species_id ou enemies." não foram escritos.
- [ ] O teste da ordem com 3 ou mais ações em `turn-order.spec.ts` e o aviso em `.specs/battle-core/architecture.md`: ficaram de fora com a troca de ideia.
- [x] Rodar a verificação e fazer o commit `feat: vagas no motor da batalha`.

## Divergências

O que a implementação fez diferente desta spec, e por quê:

- `applyAction` aceita também uma ação só, além da lista: os testes e o serviço de hoje continuam chamando com uma ação.
- O `captured_to` do `capture_attempted` é uma previsão do motor, feita com as vagas livres da equipe (`partyFree`): o motor não vê o banco.
- Os `coins_gained` saem na ordem da equipe inimiga.
- Quem desmaia fica na vaga até ser trocado (RF-12). O `creature_left` só sai quando a vaga fica vazia de vez, sem reserva: assim a luta 1 contra 1 segue com os mesmos eventos de hoje.
- O capturado é gravado em qualquer fim da luta, até numa derrota depois da captura, e não só no resultado `captured`.


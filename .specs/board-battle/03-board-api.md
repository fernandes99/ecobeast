# 03. Rotas da luta no tabuleiro

- **Status:** rascunho
- **Depende de:** [02](02-board-engine.md), [architecture.md](architecture.md#api)

## Contexto

O motor do tabuleiro existe, mas nenhuma rota o usa. Esta fase cria as rotas dele, ao lado das de `/v1/me/battle`, que continuam como estão até o jogo trocar de luta na [05](05-board-actions.md). O que acontece antes e depois da luta não muda: o encontro do hexágono de Explorar zona, a gravação de HP, PP e status, a captura e o XP, a subida de nível e a Evolução.

## Escopo

- `BoardBattleController`, os DTOs, o serviço e o mapper em `server/src/board-battle/`.
- A batalha de teste, o encontro selvagem e a vez do jogador.
- O que se grava ao fim da luta, como hoje.
- A documentação em `/docs`.

## Fora do escopo

- Mudar ou tirar as rotas de `/v1/me/battle`.
- O jogo (vem na [04](04-board-screen.md)).

## Requisitos

- **RF-01:** `POST /v1/me/board-battle` começa a luta de teste com `enemies` (1 a 6, cada um com `species_id` e `level`) e `slots` (1 a 3, padrão 1), só com `ENABLE_TEST_BATTLE` ligada.
- **RF-02:** `POST /v1/me/board-battle/wild` começa o encontro de Explorar zona com o mesmo corpo, as mesmas conferências e as mesmas respostas de erro de `POST /v1/me/battle/wild`, com 1 vaga.
- **RF-03:** `POST /v1/me/board-battle/action` aceita a vez `{position, move?, action}` no `choose_action` e `{entries}` no `choose_next`, com as ações do [architecture.md](architecture.md#api). Uma recusa do motor volta como 400, com a mensagem em pt-BR, sem mudar nada.
- **RF-04:** A resposta é `{battle, events}`. `battle` tem os campos de hoje e:
  - `round`;
  - `board: {cells: {q, r}[], zones: {player: {q, r}[], enemy: {q, r}[]}}`;
  - `marks: {q, r, ground_effect_id, remaining}[]`;
  - `queue: {side, position}[]`, com quem joga agora primeiro;
  - `player.cells` e `enemy.cells`, por vaga, com `{q, r}` ou `null`;
  - `player.entry_cells`, no `choose_next`.
- **RF-05:** O Domador tem no máximo uma luta. Começar uma luta no tabuleiro descarta a antiga, e vice-versa. Mandar uma vez do tabuleiro sem luta no tabuleiro responde 404 com "Nenhuma batalha em andamento.".
- **RF-06:** No fim da luta, HP, PP, status, captura, XP, moedas, subida de nível, Técnica nova e Evolução são gravados e respondidos como em `/v1/me/battle/action`.
- **RF-07:** O inimigo continua escondendo Técnicas e Traço, como hoje.

## Critérios de aceite

- [ ] Um e2e começa um 1×1 de teste e recebe o tabuleiro de 42 hexágonos, as duas áreas, as casas dos dois Ecobeasts e a fila.
- [ ] Um e2e anda 3 hexágonos e usa Arranhão ao lado de um selvagem, e recebe os eventos dele e da vez do selvagem.
- [ ] Um e2e recebe 400 com "Não dá para chegar lá." ao andar 4 hexágonos, e o estado não muda.
- [ ] Um e2e começa um 2×2 de teste, derruba um Ecobeast do jogador com reserva e escolhe o hexágono de entrada.
- [ ] Um e2e captura o selvagem e encontra o capturado na equipe.
- [ ] Um e2e do encontro selvagem funciona como o de `/battle/wild`, com o Ecobeast saindo do mapa.
- [ ] Os e2e de `/v1/me/battle` passam sem mudança.
- [ ] `/docs` mostra as três rotas, com os corpos e os erros.

## Desenho técnico

**Criar** em `server/src/board-battle/`: `board-battle.controller.ts`, `board-battle.dto.ts`, `board-battle.service.ts`, `board-battle.mapper.ts`, os specs deles e `board-battle.module.ts`.

**Reutilizar** de `server/src/battle/`:

- `BattleStore`, guardando o tipo da luta junto com o estado, para uma luta descartar a outra;
- o carregamento da equipe e do catálogo;
- a criação do inimigo e o encontro do hexágono;
- `saveTeam`, a captura e a progressão, tirados do `BattleService` para um lugar que os dois serviços usem, sem mudar o comportamento.

**Criar:** `server/test/board-battle.e2e-spec.ts`, com os critérios de aceite.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e
```

## Tarefas

- [ ] DTOs e mapper, com testes (RF-04 e RF-07).
- [ ] Serviço e controller da batalha de teste e do encontro (RF-01, RF-02 e RF-05).
- [ ] A vez do jogador e o fim da luta (RF-03 e RF-06).
- [ ] e2e e `/docs`.
- [ ] Rodar a verificação, marcar a spec e o README como `concluída` e fazer o commit `feat: rotas da luta no tabuleiro`.

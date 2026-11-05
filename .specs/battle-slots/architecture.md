# Arquitetura

O que muda no contrato da batalha ([battle-core/architecture.md](../battle-core/architecture.md)) para aceitar vagas. O que não aparece aqui continua como está lá. Com 1 vaga por lado, as regras e a sequência de sorteios ficam as de hoje. As exceções são os campos novos dos eventos, o `creature_left` e as moedas de uma equipe inimiga com mais de um Ecobeast, que só existe na batalha de teste: agora cada um paga.

## Vagas

Uma **vaga** é um lugar em campo, numerado da esquerda para a direita a partir de 0: a **posição**. Cada lado tem de 1 a 3 vagas (`MAX_SLOTS = 3`), fixadas ao começar a luta.

```ts
interface BattleSide {
  team: Combatant[];
  /** Por posição: o índice na equipe de quem está ali, ou null com a vaga vazia. */
  activeIndices: (number | null)[];
}
```

`activeIndices.length` é o número de vagas do lado. `activeIndex` sai, e `activeOf(state, side)` vira `activeAt(state, side, position)`.

- **Começo:** cada vaga recebe, em ordem, o próximo da equipe que esteja de pé. Sobrando vaga, ela começa vazia.
- **Desmaio:** quem desmaia continua na vaga até o fim do turno, sem agir nem ser alvo. No fim do turno, a vaga fica vazia.
- **Inimigo:** cada vaga vazia recebe, em ordem de posição, o próximo da equipe de pé que não esteja em campo. O Traço de entrada vale.
- **Jogador:** com reserva de pé fora de campo, a fase vira `choose_next`, e `pendingPositions` lista as vagas que ele precisa preencher, no máximo uma por reserva de pé. Sem reserva, a vaga fica vazia.

## Ações

No `choose_action`, o jogador manda **uma ação por vaga ocupada por alguém de pé**, cada uma com `position`. Os tipos são os de hoje, com dois campos novos:

| `type`    | Novo campo | Regra |
| --- | --- | --- |
| `skill` e `emergency` | `target` (posição do adversário) | Obrigatório quando a Técnica mira o adversário e há mais de um adversário de pé. Com um só, pode faltar. Em si mesmo, é ignorado |
| `capture` | `target` | Igual ao de `skill` |
| `flee`    | — | Só vale sozinho, na lista `[{"type": "flee"}]`. Serve para a equipe toda |
| `switch`, `item` | — | Como hoje, com a `position` de quem gasta a ação |

Os motivos de recusa novos, em pt-BR:

- "Escolha uma ação para cada Ecobeast em campo."
- "Escolha o alvo."
- "Esse alvo não está na luta."
- "Fugir vale para a equipe toda."
- "Esse Ecobeast já vai entrar."

No `choose_next`, a lista traz um `switch` por posição de `pendingPositions`, com `position` e `team_index`.

## Ordem de um turno

Os passos de hoje, generalizados:

1. **Conferir** a lista. Se uma ação não valer, nada muda.
2. **Fugir:** como hoje. Com falha, os inimigos agem sozinhos.
3. **Primeiro, troca, item e Esfera**, em ordem de posição, antes de qualquer Técnica:
   - **Troca:** quem entra ocupa a vaga de quem saiu.
   - **Esfera:** com sucesso, o capturado deixa a vaga. A luta só termina em `captured` se não sobrar inimigo de pé.
4. **IA:** cada inimigo de pé em campo escolhe a Técnica como hoje. O alvo é sorteado entre os Ecobeasts do jogador de pé em campo. Com um só, não há sorteio.
5. **Ordenar** todas as Técnicas dos dois lados: prioridade, Velocidade efetiva e sorteio, como hoje.
6. **Executar** cada uma, se o autor seguir de pé. Se o alvo caiu, a Técnica vai para o adversário de pé de menor posição. Sem nenhum, ela não acontece.
7. **Fim do turno**, como hoje, na ordem em que agiram.
8. **Conferir o fim:**
   - sem inimigo de pé na luta (em campo ou na reserva): fim da luta;
   - sem Ecobeast do jogador de pé: `defeat`;
   - senão, as vagas vazias são preenchidas como em [Vagas](#vagas).

O resultado do fim é `victory` se algum inimigo desmaiou na luta. Se todos foram capturados, é `captured`. Um inimigo desmaiado ou capturado sai da luta; um capturado nunca dá XP nem moedas.

## XP e moedas

- **XP:** o `foughtBy` de cada inimigo passa a juntar todo Ecobeast do jogador que esteve em campo ao mesmo tempo que ele, em qualquer vaga. A divisão e o `xp_gained` ficam como hoje, logo depois do `fainted` daquele inimigo.
- **Vitória:** um `coins_gained` por inimigo desmaiado, na ordem em que caíram, logo antes do `battle_ended`. Cada um usa o nível dele ÷ a média dos níveis dos Ecobeasts do jogador em campo no fim, arredondada para baixo e no mínimo 1. A soma vai para `coinsChange`.
- **Derrota:** um `coins_lost` só, com a média dos níveis dos inimigos em campo no fim ÷ a média dos níveis dos Ecobeasts do jogador em campo no fim. As médias são arredondadas para baixo.

"Em campo no fim" inclui quem desmaiou no último turno e ainda não deixou a vaga.

## Eventos

Todo evento com `side` ganha `position`, a vaga de quem sofre o evento, ou de quem errou em `missed`. Também mudam:

| `type` | Mudança |
| --- | --- |
| `creature_entered` | + `position` e `team_index` (o índice na equipe daquele lado) |
| `capture_attempted` | + `target` e `captured_to` (`party`, `storage` ou nulo) |
| `coins_gained` | + `species_id` do inimigo que pagou |
| `coins_lost` | + `species_ids` dos inimigos em campo no fim, em ordem de posição |
| `creature_left` | Novo: `side`, `position`. A vaga ficou vazia no fim do turno, depois de um desmaio ou de uma captura |

## API

As rotas são as mesmas.

- **`POST /v1/me/battle/action`:** o corpo passa a ser `{ "actions": [ … ] }`. Um corpo com `type` na raiz vale como `{ "actions": [ { …corpo, "position": 0 } ] }`.
- **`POST /v1/me/battle`** (de teste, atrás de `ENABLE_TEST_BATTLE`): aceita `"slots": 1 a 3`, para os dois lados, e `"enemies": [ { "species_id", "level" } ]`, de 1 a 6, no lugar do par `species_id` e `level`. A rota de encontro (`/battle/wild`) continua sempre com 1 vaga.

`battle` muda assim:

```json
{
  "phase": "choose_next",
  "player": {
    "active_indices": [0, null],
    "pending_positions": [1],
    "team": [ … ]
  },
  "enemy": {
    "actives": [ { "species_id": 7, "level": 4, "hp": 9, … }, null ],
    "team_size": 2,
    "fainted": 1
  }
}
```

Até a [02](02-client-slots.md), a resposta também traz os campos de hoje:

- `player.active_index`: a primeira posição ocupada;
- `enemy.active`: o primeiro inimigo em campo;
- `captured_to` na raiz: o da última captura do turno.

A 02 tira esses campos.

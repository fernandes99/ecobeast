# Arquitetura

O desenho que as fases compartilham. Nenhuma tabela muda: `creature_instances` já separa a equipe (`location = party`, `party_slot` de 1 a 6) do Santuário (`location = storage`, `party_slot` nulo).

## Rotas

Todas exigem sessão. As de escrita respondem `200 { "player" }`, o mesmo formato de `GET /v1/me`, e descartam a batalha aberta, sem gravar nada dela.

| Rota | Corpo | Resposta | Erros |
| --- | --- | --- | --- |
| `GET /v1/me/storage` | — | `200 { "creatures": [...] }`, com o mesmo `CreatureDto` da equipe | `409` "Crie seu Domador primeiro." |
| `POST /v1/me/team/order` | `{ "uids": [...] }` | `{ "player" }` | `400` "Ordem inválida." |
| `POST /v1/me/team/bring` | `{ "uid", "replace_uid"? }` | `{ "player" }` | `404` "Ecobeast não encontrado." · `400` "Esse Ecobeast já está na equipe." · `409` "A equipe está cheia." |
| `POST /v1/me/team/store` | `{ "uid" }` | `{ "player" }` | `404` "Ecobeast não encontrado." · `400` "Esse Ecobeast já está no Santuário." · `400` "A equipe precisa de ao menos 1 Ecobeast." |

Toda rota de escrita responde `409` "Crie seu Domador primeiro." sem Domador. Filtrar pelo dono faz o Ecobeast de outro Domador parecer inexistente, como em `PATCH /v1/me/creatures/:uid`.

## Regras

- **`order`:** `uids` tem de ser exatamente a equipe atual, sem faltar, sobrar nem repetir ninguém. Os Ecobeasts ficam nas vagas de 1 a N, na ordem recebida, e vagas no meio somem.
- **`bring` sem `replace_uid`:** o Ecobeast entra na primeira vaga livre. Sem vaga, `409`.
- **`bring` com `replace_uid`:** os dois trocam de lugar. O que estava na equipe vai para o Santuário, e o outro fica com a vaga dele. Um `replace_uid` que não esteja na equipe do Domador é `404`.
- **`store`:** o Ecobeast vai para o Santuário, e a vaga dele fica livre. Se ele for o último da equipe, a rota recusa.
- HP, status, PP, Genes, Treino e apelido nunca mudam nessas rotas.

Cada rota lê e grava em uma transação interativa, que começa travando a linha do Domador com um `update` que não muda nada (`coins + 0`). De dois pedidos ao mesmo tempo, o segundo espera o primeiro e lê a equipe já mudada, então a equipe nunca fica sem ninguém nem acima de 6. Só a transação não bastaria: os dois leriam a mesma equipe antes de qualquer escrita.

`player_id + party_slot` é único e checado linha a linha, e o `CHECK` só aceita vagas de 1 a 6. Por isso, `order` e a troca de `bring` não podem mudar as vagas direto. Na mesma transação, os Ecobeasts afetados passam primeiro para `storage` e voltam depois, já nas vagas certas.

## Regras puras

`server/src/domain/team/party.ts`:

- `PARTY_SIZE` e `firstFreePartySlot`, movidas de `domain/battle/capture.ts`.
- `isSameTeam(current: string[], requested: string[]): boolean`.

## O cliente

O `GameService` ganha `load_storage`, `reorder_team`, `bring_to_team` e `send_to_storage`.

O `Session` guarda `storage: Array[CreatureInstance]`, lido por `load_storage` ao abrir o Santuário e relido depois de qualquer mudança de equipe. Depois de `set_nickname`, o Santuário é relido se o Ecobeast estiver nele, porque a resposta só traz a equipe.

A tela de detalhes passa a procurar o Ecobeast na equipe e em `Session.storage`. Hoje ela só olha a equipe, e um Ecobeast do Santuário abriria vazio.

## A troca na luta

Na [API da batalha](../battle-core/architecture.md), a ação `switch` passa a valer também em `choose_action`:

| Situação | Recusa, sem gastar a rodada |
| --- | --- |
| A posição não existe, ou o Ecobeast tem 0 HP | "Esse Ecobeast não pode lutar." |
| O Ecobeast já está em campo | "Esse Ecobeast já está em campo." |
| Quem está em campo está Preso | "Não dá para trocar agora." |

Sem recusa, o Ecobeast entra em campo, com os estágios e os efeitos temporários zerados e o Traço de entrada aplicado, como já acontece. Depois, o inimigo age sozinho, e o turno termina como depois de um item.

Em `choose_next`, a ação continua como está e não gasta rodada.

A tela só conhecia quem entrava depois de tudo o que aconteceu no turno, e copiava o estado final. Com a troca voluntária, o Ecobeast entra e pode apanhar no mesmo turno, então o cartão mostraria o dano antes da linha do ataque. Por isso, `creature_entered` ganha `hp` e `status`, e o cartão usa esses valores ao entrar.

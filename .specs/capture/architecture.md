# Arquitetura

O desenho que as duas fases compartilham. A regra fica em `server/src/domain/battle/capture.ts`; o cliente nunca calcula a chance nem decide o resultado.

## Fórmula

```text
a = (3 × HP máximo − 2 × HP atual) × capture_rate × bônus da Esfera ÷ (3 × HP máximo) × bônus de status
chance = mínimo entre a ÷ 100 e 1
```

Os bônus de status valem só para o status principal do inimigo. Confuso, Amedrontado e Preso não contam.

| Status do inimigo | Bônus |
| --- | --- |
| `sleep`, `freeze` | 2,5 |
| `paralysis`, `burn`, `poison` | 1,5 |
| Nenhum | 1 |

Exemplos com `capture_rate` 45 e sem status: Esfera de Vínculo, de 15% com HP cheio a quase 45% com HP mínimo; Esfera Suprema, de 30% a quase 90%. Todos os valores são _a revisar_: `capture_rate` e `capture_bonus` mudam pelo painel do Supabase, e os bônus de status, no código.

## Ação e eventos

Na [API da batalha](../battle-core/architecture.md), `POST /v1/me/battle/action` ganha:

```json
{ "type": "capture", "item_id": 1 }
```

A ação só vale em `choose_action`. Em `choose_next`, ela recebe a recusa que já existe: "Escolha o próximo Ecobeast.".

| Situação | Recusa, sem gastar a rodada nem a Esfera |
| --- | --- |
| O item não está na `bag`, ou não existe | "Você não tem esse item." |
| O item não tem `capture_bonus` | "Esse item não pode ser usado agora." |
| O inimigo tem `capture_rate` 0 | "Esse Ecobeast não pode ser capturado." |

A ação `item` continua recusando Esferas: elas só funcionam pela `capture`.

Sem recusa, nesta ordem:

1. A Esfera sai da `bag` (`quantity − 1`, `used + 1`).
2. O sorteio compara a chance com a fonte de `random`. A Velocidade não importa, e o inimigo não age antes.
3. Sai o evento `capture_attempted`, com `item_id` e `success`.
4. Se deu certo, a luta acaba com `result = "captured"` e o evento `battle_ended`.
5. Se falhou, o inimigo age sozinho, e o turno segue como depois de um item.

A resposta da ação ganha `captured_to`, ao lado de `battle` e `events`:

| Valor | Quando |
| --- | --- |
| `"party"` | Capturado, e entrou na equipe |
| `"storage"` | Capturado, e foi para o Santuário |
| `null` | Em todos os outros casos |

## O capturado

O motor recebe só o `Combatant`, que não tem Genes, Temperamento nem gênero, e essa parte fica de fora do estado de propósito. Por isso, `StoredBattle` guarda, em `wild`, o `NewCreature` do inimigo e os `statIds`, os mesmos que `createCreature` e `loadCreatureBlueprint` já devolvem. Nada disso vai para o cliente.

No fim da luta, `saveTeam` grava o capturado na mesma transação do HP, do PP, do status e dos itens gastos:

| Coluna | Valor |
| --- | --- |
| `player_id`, `original_player_id` | O jogador |
| `current_hp`, `status_condition_id`, PP das Técnicas | Os do `Combatant`, no fim da luta |
| `species_id`, `level`, `current_xp`, `temperament_id`, `trait_id`, `gender`, `bond`, `is_prismatic`, Genes, Treino | Os do `NewCreature` |
| `location`, `party_slot` | `party` e a primeira vaga de 1 a 6; sem vaga, `storage` e nulo |
| `caught_at` | Agora |
| `nickname`, `held_item_id`, `caught_zone_id` | Nulos |

`createCreature` já é usado no inicial. A montagem do `data` do `creatureInstance.create` sai de `PlayerService` para uma função usada pelos dois.

As vagas são lidas logo antes da transação. Nada muda a equipe durante uma luta, e `player_id + party_slot` é único, então uma corrida impossível hoje viraria erro, nunca dois Ecobeasts na mesma vaga.

Se o Domador foi apagado no meio da luta, nada é gravado, `captured_to` é `null` e a luta termina sem erro, como já acontece em `saveTeam`. Todo Domador tem ao menos o inicial, então uma equipe vazia significa que ele não existe mais.

## A tela

O carregamento acontece depois da resposta do servidor. `capture_attempted` já traz o resultado, e a tela só o revela no fim da animação. Se a rede falhar, nenhuma animação começa, e o erro aparece no histórico como em qualquer ação.

Sem arremesso e sem tremidas. A sequência, com a tela escurecida por cima da luta:

1. O sprite do inimigo fica acima da Esfera e um anel começa a encher em volta dela, com o texto "Entrando na Esfera...".
2. Durante o carregamento, o sprite encolhe e desce para dentro da Esfera, até sumir.
3. Com o anel cheio, aparece "Capturado!" ou "Escapou!". Se escapou, o sprite volta ao tamanho original.
4. A tela de cima fecha, e o turno continua no histórico.

O carregamento dura 3,5 s, e o resultado fica 1,2 s na tela. Os dois valores são constantes, _a revisar_.

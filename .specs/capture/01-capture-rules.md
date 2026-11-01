# 01. Regra da captura

- **Status:** concluída
- **Depende de:** [inventory-shop/04-battle-items](../inventory-shop/04-battle-items.md)

## Contexto

O motor da batalha conhece a `bag`, mas recusa as Esferas. Esta fase cria a fórmula, a ação `capture` e a gravação do capturado, tudo no servidor. A tela vem na [02](02-capture-screen.md).

## Escopo

- A fórmula da chance.
- A ação `capture`, o evento `capture_attempted` e o resultado `captured`.
- `capture_rate` e `capture_bonus` no catálogo da batalha.
- Guardar os dados do inimigo durante a luta.
- Gravar o capturado na equipe ou no Santuário.
- `captured_to` na resposta da ação.

## Fora do escopo

- Qualquer mudança no cliente.
- Novas colunas ou migrations.
- Mudar a ação `item`.

## Requisitos

**Fórmula**

- **RF-01:** `captureChance` calcula a chance descrita em [architecture.md](architecture.md#fórmula), de 0 a 1, sem nunca passar de 1.
- **RF-02:** Só `sleep`, `freeze`, `paralysis`, `burn` e `poison` dão bônus de status.

**Motor**

- **RF-03:** `BattleCatalog` traz o `capture_rate` de cada espécie e o `capture_bonus` de cada item, lidos do banco.
- **RF-04:** A ação `{ "type": "capture", "item_id" }` só vale em `choose_action`.
- **RF-05:** A ação é recusada com as mensagens de [architecture.md](architecture.md#ação-e-eventos), sem gastar a rodada nem a Esfera.
- **RF-06:** Sem recusa, a Esfera é gasta antes do sorteio, com ou sem sucesso.
- **RF-07:** O evento `capture_attempted` traz `item_id` e `success`, antes de qualquer evento do inimigo.
- **RF-08:** Com sucesso, a luta termina com `result = "captured"`, sem o inimigo agir e sem dano de fim de turno.
- **RF-09:** Com falha, o inimigo age sozinho, e o turno termina como depois de um item.
- **RF-10:** A chance usa o HP e o status do inimigo no momento da ação.

**Gravação**

- **RF-11:** `StoredBattle` guarda o `NewCreature` do inimigo e os `statIds`, que nunca vão para o cliente.
- **RF-12:** Com `result = "captured"`, `saveTeam` cria o Ecobeast na mesma transação do resto, com os valores de [architecture.md](architecture.md#o-capturado).
- **RF-13:** O capturado ocupa a primeira vaga livre de 1 a 6. Sem vaga, vai para `storage`, com `party_slot` nulo.
- **RF-14:** A Esfera gasta sai da Mochila com sucesso e com falha, no fim da luta. Uma luta abandonada não grava nada.
- **RF-15:** Domador apagado no meio da luta não grava nada, e a resposta vem sem erro.
- **RF-16:** A resposta da ação traz `captured_to`, com `party`, `storage` ou `null`.
- **RF-17:** O OpenAPI descreve a ação, `captured` e `captured_to`, em pt-BR.

## Critérios de aceite

- [x] Com HP cheio, `capture_rate` 45, bônus 1 e sem status, a chance é 0,15.
- [x] Com HP 1 de 300, `capture_rate` 45, bônus 2 e sem status, a chance fica acima de 0,89 e abaixo de 0,9.
- [x] Sono e Congelado multiplicam por 2,5; Paralisado, Queimado e Envenenado, por 1,5.
- [x] Confuso, sozinho, não muda a chance.
- [x] A chance nunca passa de 1.
- [x] `capture_rate` 0 é recusado sem gastar a Esfera.
- [x] Um Tônico na ação `capture` é recusado com "Esse item não pode ser usado agora."
- [x] Uma Esfera fora da `bag` é recusada com "Você não tem esse item."
- [x] `capture` em `choose_next` é recusada com "Escolha o próximo Ecobeast."
- [x] Uma Esfera na ação `item` continua recusada.
- [x] Com sorteio favorável, a luta termina em `captured`, sem evento do inimigo.
- [x] Com sorteio contrário, o inimigo ataca depois de `capture_attempted`, e a luta segue.
- [x] Se o inimigo derrotar o último Ecobeast depois da falha, a luta termina em `defeat`, e a Esfera sai da Mochila.
- [x] O capturado aparece em `GET /v1/me`, na equipe, com o HP e os PP do fim da luta.
- [x] Os seis Genes, o Temperamento, o Traço e o gênero gravados são os do inimigo daquela luta.
- [x] Com 6 na equipe, o capturado vai para `storage`, e `GET /v1/me` continua com 6.
- [x] Com a vaga 2 livre e a 3 ocupada, o capturado entra na vaga 2.
- [x] O status do inimigo é gravado no capturado.
- [x] A resposta nunca traz os Genes do inimigo.
- [x] Uma luta abandonada depois de uma falha não gasta a Esfera.
- [x] Uma falha na transação não deixa capturado nem Esfera gasta pela metade.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/domain/battle/capture.ts`, com `capture.spec.ts`: `captureChance`, `firstFreePartySlot(occupied: number[]): number | null` e a mensagem nova.
- `server/test/capture.e2e-spec.ts`: o fluxo com o banco.

**Alterar**

- `server/src/domain/battle/types.ts`: `BattleItem`, `captureRates` em `BattleCatalog`, `captured` em `BattleResult`, a ação e o evento.
- `server/src/domain/battle/engine.ts`: a recusa e a função `tryCapture`, que reaproveita `playEnemyAlone` e `endBattle`. O desconto da `bag` vira uma função usada também por `useBagItem`.
- `server/src/domain/battle/testing.ts`, `engine.spec.ts`: os casos novos.
- `server/src/battle/battle-catalog.ts`, com a spec: `capture_rate` e `capture_bonus`.
- `server/src/battle/battle.store.ts`: o inimigo em `StoredBattle`.
- `server/src/battle/battle.service.ts`: `createEnemy` devolve também os dados do inimigo, `saveTeam` cria o capturado e `act` devolve `captured_to`.
- `server/src/battle/battle.mapper.ts`, `battle.dto.ts`: a ação, `captured` e `captured_to`.
- `server/src/player/creature-params.ts`: `newCreatureData`, que monta o `data` do `creatureInstance.create`, tirada de `PlayerService`.
- `server/src/player/player.service.ts`: usa essa função.
- `.specs/battle-core/architecture.md`: a ação, o evento e o resultado.

**Reaproveitar**

`createCreature`, `loadCreatureBlueprint`, `rollChance`, `playEnemyAlone`, `endBattle` e a gravação de itens em `saveTeam`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Os e2e não conferem valores de balanceamento. Para fixar o resultado, trocam o `capture_rate` e o HP direto no `BattleStore`, como os testes de batalha já fazem com o HP, e leem o resto do banco.

Sem passos do dono nesta fase: ela não muda nada na tela.

## Tarefas

- [x] Testes de `captureChance` e `firstFreePartySlot`; ver falhar; implementar (RF-01, RF-02).
- [x] Testes do motor; ver falhar; ação, evento e resultado (RF-03 a RF-10).
- [x] Testes e2e; ver falhar; guardar o inimigo e gravar o capturado (RF-11 a RF-16).
- [x] OpenAPI e `.specs/battle-core/architecture.md` (RF-17).
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: regra da captura`.

## Decisões da implementação

- **`captureBonus` foi para `BattleItem`, não para `UsableItem`:** a rota da Mochila usa `UsableItem` e não captura nada. O catálogo da batalha estende esse tipo, e a spec previa o campo no tipo compartilhado.
- **`NOT_CAPTURABLE` mora em `domain/battle/capture.ts`:** a Mochila não recusa Esferas por esse motivo, e por isso `use-item.ts` não mudou.
- **Domador apagado:** `capturePlace` lê a equipe e devolve nulo quando ela está vazia, porque todo Domador tem ao menos o inicial. Um pedido que apague o Domador exatamente entre essa leitura e a transação daria erro, sem gravar nada.
- **Teste da falha na gravação:** o e2e troca um `statId` no `BattleStore` por um que não existe. A chave estrangeira derruba a transação de verdade, e o teste confere que o inicial, a Esfera e o capturado ficaram como estavam.
- **Conferência:** os testes novos falharam antes do código e passaram depois. `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 471 testes; `npm run test:e2e` com 360. Sem mudança na tela: o jogo ainda não envia a ação `capture`.

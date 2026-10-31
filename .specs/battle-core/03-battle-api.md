# 03. Batalha pela API

- **Status:** concluída
- **Depende de:** [02-battle-engine](02-battle-engine.md), [auth-google/03-player-api](../auth-google/03-player-api.md)

## Contexto

O motor funciona, mas ninguém o alcança. Esta fase o expõe: o NestJS monta os combatentes a partir do banco, guarda a batalha na memória, responde a cada ação e, quando a luta acaba, grava HP, PP e status. Como ainda não há zonas, a rota de começar recebe espécie e nível do inimigo, atrás de uma variável de ambiente. A `wild-battle` a troca por encontros de verdade.

## Escopo

- `BattleModule`, `BattleStore`, `BattleService` e `BattleController`.
- Leitura do `BattleCatalog` do banco.
- Criação do inimigo, gravação do fim e documentação da API.
- `ENABLE_TEST_BATTLE`.

## Fora do escopo

- Qualquer mudança no cliente.
- Migrations: as colunas já existem.
- Limite de tempo por turno.

## Requisitos

**Começar**

- **RF-01:** `POST /v1/me/battle` com `ENABLE_TEST_BATTLE` desligado dá `404`, como uma rota que não existe.
- **RF-02:** Sem Domador ou sem criaturas na equipe: `409` "Crie seu Domador primeiro."
- **RF-03:** Sem nenhuma criatura com HP: `409` "Cure sua equipe no Refúgio."
- **RF-04:** `species_id` que não existe ou `level` fora de 1–100: `400` "Esse inimigo não existe."
- **RF-05:** Os combatentes do jogador vêm da equipe, na ordem dos slots, com `current_hp`, PP e status do banco. Um Adormecido entra sorteando os turnos.
- **RF-06:** O inimigo é criado com `createCreature`, sem ser gravado.
- **RF-07:** Começar uma batalha com outra em andamento descarta a anterior, sem gravar nada.
- **RF-08:** A resposta é `201 { "battle", "events" }`, no formato de [architecture.md](architecture.md#api).

**Agir**

- **RF-09:** `POST /v1/me/battle/action` sem batalha na memória: `404` "Nenhuma batalha em andamento."
- **RF-10:** Corpo malformado: `400` "Ação inválida." Ação recusada pelo motor: `400` com a mensagem dele.
- **RF-11:** A resposta é `200 { "battle", "events" }`, com os eventos só deste turno.
- **RF-12:** O JSON nunca traz as Técnicas nem o Traço do inimigo, nem as criaturas dele fora de campo.

**Memória**

- **RF-13:** `BattleStore` guarda uma batalha por jogador, num `Map` do processo.
- **RF-14:** Uma batalha sem ação há 30 minutos some, sem gravar nada, conferido a cada acesso ao `BattleStore`.
- **RF-15:** Reiniciar o servidor perde as batalhas, sem gravar nada.

**Fim**

- **RF-16:** Quando `phase` vira `ended`, o `BattleService` tira a batalha da memória e grava, numa transação com `updateMany`, `current_hp` e `status_condition_id` de cada criatura do jogador e `current_pp` de cada Técnica. Vale para `victory`, `defeat` e `fled`.
- **RF-17:** Status voláteis, estágios e o inimigo não são gravados.
- **RF-18:** Se a gravação falhar, a rota dá `500`, a batalha continua fora da memória, e a equipe fica como antes dela.
- **RF-19:** Abandonar a batalha, de qualquer forma, não grava nada.

**Configuração e documentação**

- **RF-20:** `ENABLE_TEST_BATTLE`, booleana, padrão falso, em `env.ts` e `.env.example`; ligada no `vitest.config.e2e.ts`.
- **RF-21:** As rotas estão no OpenAPI, em pt-BR, com exemplos, sob a tag "Batalha".
- **RF-22:** `secureRandom` sai do `player.service.ts` para um arquivo comum, usado pelos dois serviços.

## Critérios de aceite

- [x] Sem token, as duas rotas dão `401`.
- [x] Com a variável desligada, começar dá `404`.
- [x] Sem Domador, `409`; com a equipe toda a 0 HP, `409` "Cure sua equipe no Refúgio."; com espécie 999 ou nível 101, `400`.
- [x] Uma batalha começa com o Fagulho, e o JSON não mostra as Técnicas do inimigo.
- [x] Usar Técnicas até vencer dá `victory`, e o banco fica com o `current_hp` e o PP da resposta.
- [x] Uma derrota grava 0 HP, e a batalha seguinte dá `409`.
- [x] Fugir com sucesso grava o HP e o PP daquele momento.
- [x] Um status principal no fim fica em `status_condition_id`; um Confuso, não.
- [x] Sem batalha, agir dá `404`; uma segunda ação depois do fim, também.
- [x] Começar outra batalha no meio da primeira não muda o banco.
- [x] Um jogador não age na batalha do outro.
- [x] O relógio do `BattleStore`, adiantado 30 minutos em teste, faz a batalha sumir sem gravar.
- [x] Apagar o Domador no meio da luta não dá erro no fim: a gravação não encontra nada, e a batalha some.
- [x] As rotas aparecem em `/docs/openapi.json`, com o cadeado.
- [x] Os e2e apagam os Domadores que criaram.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**, em `server/src/battle/`:

- `battle.module.ts`, `battle.controller.ts`, `battle.service.ts` e `battle.dto.ts`.
- `battle.store.ts`: `get`, `set` e `delete`, com o relógio por parâmetro, para o teste do RF-14.
- `battle-catalog.ts`: lê do banco o `BattleCatalog`.
- `battle.mapper.ts`, com `battle.mapper.spec.ts`: criatura → `Combatant`, estado → JSON sem o que é escondido do jogador.
- `server/test/battle.e2e-spec.ts`.
- `server/src/common/secure-random.ts`.
- `server/src/player/creature-params.ts`: o que `createCreature` precisa do catálogo, usado pelo jogador e pela batalha.

**Alterar**

- `server/src/config/env.ts`, `server/.env.example`, `server/vitest.config.e2e.ts`.
- `server/src/app.module.ts`.
- `server/src/player/player.service.ts` (RF-22).
- `GDD.md`: a regra da fuga e o golpe de emergência.
- `server/CLAUDE.md`: `src/battle/` na estrutura.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Os e2e usam tokens de `test/support/tokens.ts` e o catálogo real, mas não conferem valores de balanceamento: verificam fases, resultados e o que foi gravado. Para vencer de forma previsível, usam um inimigo de nível 1 contra uma criatura ajustada no banco pelo próprio teste.

## Tarefas

- [x] `ENABLE_TEST_BATTLE` e `secure-random` (RF-20, RF-22).
- [x] `BattleStore`, com testes; ver falhar; implementar (RF-13 a RF-15).
- [x] Mapper e catálogo, com testes (RF-05, RF-06, RF-12).
- [x] Testes e2e de começar e agir; ver falhar; serviço e controller (RF-01 a RF-11).
- [x] Testes e2e do fim; ver falhar; gravação (RF-16 a RF-19).
- [x] Documentação (RF-21), `GDD.md` e `server/CLAUDE.md`.
- [x] Marcar esta spec, a tabela do README e o roadmap como `concluída`; commit `feat: batalha pela API`.

## Decisões da implementação

- **`creature-params.ts` saiu do `PlayerService`:** o inimigo precisa da mesma leitura, em qualquer nível. Ela também traz os Elementos da espécie e o slug dos Traços, que o `Combatant` usa.
- **`creatureStats` foi para `player.mapper.ts`:** a batalha e a resposta do jogador precisam calcular os stats do mesmo jeito.
- **O catálogo fica guardado com a batalha:** uma edição no painel não muda uma luta em andamento, e agir não lê o banco.
- **`act` não tem `await` entre ler e escrever no `BattleStore`:** dois pedidos ao mesmo tempo não jogam o mesmo turno. No fim, a batalha sai da memória antes de gravar, então o segundo pedido recebe `404`.
- **A faixa do nível é conferida no serviço:** a validação junta as mensagens de cada regra, e o erro viraria a mesma frase repetida. Pelo mesmo motivo, `level` só é validado com `species_id` válido.
- **Com `ENABLE_TEST_BATTLE` desligada, a sessão é conferida antes:** sem token, a rota dá `401`; com token, `404` "Rota não encontrada."
- **O PP é gravado por `skillId`:** o `Combatant` não guarda o slot, e um slot vago não pode desalinhar a escrita.
- **Uma ação recusada não renova os 30 minutos:** só uma ação aceita conta.
- **`BattleStore` não usa injeção:** nasce numa fábrica no módulo, para o relógio continuar um parâmetro simples.
- **Status no e2e:** o teste muda o estado direto no `BattleStore`, porque nenhuma Técnica aplica Confuso e o sorteio não é controlável pela API.
- **Conferência extra:** um teste temporário jogou 3.000 lutas com o catálogo real, Técnicas e Elementos sorteados, conferindo HP, estágios, PP e que toda luta termina. Foi removido depois.
- **Conferência:** `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 348 testes; `npm run test:e2e` com 245.

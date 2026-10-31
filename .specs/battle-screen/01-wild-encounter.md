# 01. Encontro selvagem

- **Status:** aprovada
- **Depende de:** [battle-core/03-battle-api](../battle-core/03-battle-api.md)

## Contexto

`POST /v1/me/battle` recebe a espécie e o nível do inimigo, por isso só existe com `ENABLE_TEST_BATTLE` ligada. O jogo precisa de uma rota em que o próprio servidor escolha o oponente, sempre disponível. Esta fase a cria. A [wild-battle](../roadmap.md) troca o sorteio pelas zonas mais tarde.

## Escopo

- Regra pura do sorteio do encontro.
- Rota `POST /v1/me/battle/wild`.

## Fora do escopo

- Zonas e tabelas de encontro.
- Qualquer mudança no cliente.
- Mudar a rota de teste ou `ENABLE_TEST_BATTLE`.

## Requisitos

**Sorteio**

- **RF-01:** `rollEncounter(speciesIds: number[], referenceLevel: number, random: Random)` devolve `{ speciesId, level }`, com a espécie sorteada por igual entre `speciesIds`.
- **RF-02:** O nível é `referenceLevel` somado a um inteiro sorteado por igual de -2 a +1, limitado a 1–100. Os valores ficam em constantes, _a revisar_.
- **RF-03:** A função é pura, e o sorteio vem de `random`, nesta ordem: espécie, depois nível.

**Rota**

- **RF-04:** `POST /v1/me/battle/wild`, sem corpo, exige a sessão e responde `201 { "battle", "events" }`, no formato de [battle-core/architecture.md](../battle-core/architecture.md#api).
- **RF-05:** Funciona com `ENABLE_TEST_BATTLE` ligada ou desligada.
- **RF-06:** Sem Domador ou sem criaturas na equipe: `409` "Crie seu Domador primeiro."
- **RF-07:** Sem nenhuma criatura com HP: `409` "Cure sua equipe no Refúgio."
- **RF-08:** As espécies são todas as da tabela `species`. O `referenceLevel` é o nível da primeira criatura de pé da equipe, a que entra em campo.
- **RF-09:** O resto segue a batalha de teste: inimigo criado com `createCreature`, sem gravar; fuga permitida; uma batalha em andamento é descartada, sem gravar nada.
- **RF-10:** A rota está no OpenAPI, em pt-BR, sob a tag "Batalha".

## Critérios de aceite

- [ ] Com o sorteio 0, sai a primeira espécie e o nível de referência menos 2; com 0,99, a última e o nível mais 1.
- [ ] Referência 1 nunca dá nível abaixo de 1, e referência 100 nunca dá acima de 100.
- [ ] Sem token, a rota dá `401`.
- [ ] Sem Domador, `409`; com a equipe toda a 0 HP, `409` "Cure sua equipe no Refúgio."
- [ ] Com `ENABLE_TEST_BATTLE` desligada, a rota responde `201`, e a rota de teste continua dando `404`.
- [ ] O inimigo é uma espécie do catálogo, com nível de 2 abaixo a 1 acima do Ecobeast de frente.
- [ ] Com o primeiro da equipe a 0 HP, o nível usa o segundo.
- [ ] A luta começada pela rota aceita `POST /v1/me/battle/action` até o fim, e o fim grava HP e PP.
- [ ] A rota aparece em `/docs/openapi.json`, com o cadeado.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/domain/battle/encounter.ts`, com `encounter.spec.ts`: `rollEncounter`.

**Alterar**

- `server/src/battle/battle.service.ts`: `startWild(userId)`. A parte comum com `start` (carregar a equipe, ler o catálogo, chamar `startBattle` e guardar) vira um método privado.
- `server/src/battle/battle.controller.ts`: a rota `wild`.
- `server/test/battle.e2e-spec.ts`: os casos desta fase.
- `.specs/battle-core/architecture.md`: a rota na tabela da API.

**Reaproveitar**

`loadCreatureBlueprint`, `toEnemyCombatant`, `BATTLE_PLAYER_INCLUDE` e `secureRandom`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Os e2e não conferem qual espécie saiu, só que ela existe e que o nível está na faixa.

## Tarefas

- [ ] Testes de `rollEncounter`; ver falhar; implementar (RF-01 a RF-03).
- [ ] Testes e2e da rota; ver falhar; serviço e controller (RF-04 a RF-10).
- [ ] Marcar esta spec e a tabela do README como `concluída`; commit `feat: encontro selvagem aleatório`.

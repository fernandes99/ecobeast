# 01. Rota de cura

- **Status:** concluída
- **Depende de:** [battle-screen/01-wild-encounter](../battle-screen/01-wild-encounter.md)

## Contexto

O fim de uma luta grava HP, PP e status em `creature_instances` e `creature_instance_skills`, e nenhuma rota os recupera. Esta fase cria a rota de cura. A tela vem na [02](02-heal-screen.md).

## Escopo

- Rota `POST /v1/me/heal`.
- Descartar a batalha aberta do jogador ao curar.

## Fora do escopo

- Qualquer mudança no cliente.
- Cobrar moedas.
- Curar quem está no Santuário.

## Requisitos

- **RF-01:** `POST /v1/me/heal`, sem corpo, exige a sessão e responde `200 { "player" }`, no mesmo formato de `GET /v1/me`.
- **RF-02:** Cada criatura com `location` `party` fica com `current_hp` igual ao HP máximo calculado, sem `status_condition_id`, e cada Técnica dela com `current_pp` igual ao `max_pp` do catálogo.
- **RF-03:** Criaturas com `location` `storage` não mudam.
- **RF-04:** As moedas do jogador não mudam.
- **RF-05:** A cura é uma transação só: ou a equipe inteira é curada, ou nada muda.
- **RF-06:** Sem Domador ou sem criaturas na equipe: `409` "Crie seu Domador primeiro."
- **RF-07:** Com a equipe já curada, a rota responde `200` com o jogador, sem erro.
- **RF-08:** A batalha aberta do jogador é descartada, sem gravar nada dela. Depois disso, `POST /v1/me/battle/action` responde `404`.
- **RF-09:** A rota está no OpenAPI, em pt-BR, sob a tag "Jogador", com o cadeado.

## Critérios de aceite

- [x] Sem token, a rota dá `401`.
- [x] Sem Domador, `409` "Crie seu Domador primeiro."
- [x] Com duas criaturas feridas, com status e sem PP, as duas voltam com HP e PP máximos e sem status, e a resposta já mostra isso.
- [x] Uma criatura no Santuário continua com o HP, o PP e o status de antes.
- [x] As moedas continuam iguais.
- [x] Repetir a rota com a equipe curada responde `200` e não muda nada.
- [x] Com a equipe toda a 0 HP, `POST /v1/me/battle/wild` dá `409`; depois de curar, dá `201`.
- [x] Com uma luta aberta, curar faz `POST /v1/me/battle/action` responder `404`, e o HP continua o da cura.
- [x] Com uma falha no meio da gravação, nenhuma criatura muda.
- [x] A rota aparece em `/docs/openapi.json`, com o cadeado.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/test/heal.e2e-spec.ts`: os casos desta fase. A falha na gravação usa `vi.spyOn(app.get(PrismaService), '$transaction')`.

**Alterar**

- `server/src/player/player.service.ts`: `heal(userId: string): Promise<PlayerDto>`. Lê as criaturas da equipe com `PLAYER_INCLUDE` e o `max_pp` de cada Técnica, descarta a batalha e grava tudo num `$transaction`, com um `updateMany` por criatura e um por Técnica, como `BattleService.saveTeam`.
- `server/src/player/player.controller.ts`: a rota, com `@HttpCode(200)`.
- `server/src/player/player.module.ts`: importa `BattleModule`.
- `server/src/battle/battle.module.ts`: exporta `BattleStore`, para o serviço do jogador usar a mesma instância.
- `.specs/auth-google/architecture.md`: a rota na tabela da API.

**Reaproveitar**

`PLAYER_INCLUDE`, `creatureStats` (o HP máximo é `creatureStats(row).hp`), `toPlayerDto`, `PlayerResponseDto`, `BattleStore.delete`.

A cura não tem fórmula, por isso não ganha um arquivo em `src/domain/`: ela só copia os máximos. O preço, quando existir, é regra de jogo e nasce lá.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

## Tarefas

- [x] Testes e2e da rota; ver falhar; serviço, controller e módulos (RF-01 a RF-09).
- [x] Marcar esta spec e a tabela do README como `concluída`; commit `feat: rota de cura do Refúgio`.

## Decisões da implementação

- **Técnicas por `slot`:** a chave de `creature_instance_skills` é criatura + slot, então a cura grava por ela.
- **A batalha sai depois da leitura e antes da escrita:** uma falha ao ler não perde a luta, e nenhuma ação chega entre o descarte e a gravação. Se a gravação falhar, a luta já foi descartada; isso não prejudica o jogador, porque a tela de batalha não deixa chegar ao Refúgio com uma luta na tela.
- **O teste da falha substitui o `$transaction`:** ele mostra que nada é gravado fora da transação. A garantia de desfazer uma transação pela metade é do banco e não foi testada aqui.
- **Conferência:** 12 testes novos falharam antes da rota e passaram depois. `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 359 testes; `npm run test:e2e` com 266.

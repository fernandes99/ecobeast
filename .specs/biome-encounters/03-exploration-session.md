# 03. Exploração no servidor

- **Status:** concluída
- **Depende de:** [02-spawn-rules](02-spawn-rules.md)

## Contexto

Hoje o servidor gera o mapa e esquece dele, e o encontro não olha para nada do mapa. Para o Ecobeast do hexágono ser o que entra na luta, o servidor precisa lembrar quem está em cada hexágono e conferir onde o Domador está.

## Escopo

- `ExplorationStore`, com os Ecobeasts e a posição confirmada.
- `POST /v1/me/exploration` sorteia os Ecobeasts e os devolve sem nível.
- `POST /v1/me/battle/wild` recebe a posição, confere e abre a luta contra um Ecobeast dali.
- Remoção do `rollEncounter`.

## Fora do escopo

- Mudanças de tela ([fase 04](04-map-creatures.md)). Até ela, o botão Procurar do jogo para de funcionar, então as fases 03 e 04 vão juntas para o dono testar.
- Guardar a exploração no banco.

## Requisitos

- **RF-01:** `POST /v1/me/exploration` calcula a média dos níveis da equipe principal e sorteia os Ecobeasts com as taxas do banco.
- **RF-02:** A resposta traz `map.creatures`, com `id`, `species_id`, `q` e `r`, e nunca o nível.
- **RF-03:** Uma exploração nova substitui a anterior do mesmo jogador.
- **RF-04:** A posição inicial da exploração é `map.start`, confirmada no momento da resposta.
- **RF-05:** `POST /v1/me/battle/wild` exige `q` e `r` inteiros.
- **RF-06:** Sem exploração guardada, a rota responde 404 com "Essa exploração acabou. Saia e entre de novo."
- **RF-07:** Uma posição mais longe do que dá para andar no tempo passado responde 409 com "Você não chegou até aí.", como na [arquitetura](architecture.md#conferir-a-posição).
- **RF-08:** Sem Ecobeast no hexágono, a rota responde 409 com "Nada por aqui."
- **RF-09:** Com mais de um Ecobeast no hexágono, o servidor escolhe um ao acaso.
- **RF-10:** A luta acontece contra a espécie e o nível guardados no Ecobeast escolhido.
- **RF-11:** O Ecobeast sai da exploração quando a luta começa, e a resposta traz o id dele em `spawn_id`.
- **RF-12:** Uma equipe sem HP recebe a mensagem de hoje, e nenhum Ecobeast sai do mapa.
- **RF-13:** Dois pedidos ao mesmo tempo não enfrentam o mesmo Ecobeast.
- **RF-14:** A posição aceita passa a ser a nova posição confirmada, mesmo que os pedidos seguintes falhem.

## Critérios de aceite

- [x] A resposta da exploração não contém `level` em nenhum Ecobeast.
- [x] Procurar longe do início logo depois de entrar responde 409 "Você não chegou até aí."
- [x] Procurar longe depois de passado o tempo do caminho funciona.
- [x] Procurar em um hexágono sem Ecobeast responde 409 "Nada por aqui."
- [x] A luta vem com a espécie e o nível guardados.
- [x] Procurar duas vezes em um hexágono com um Ecobeast responde 409 "Nada por aqui." na segunda.
- [x] Em um hexágono com dois, as duas buscas enfrentam Ecobeasts diferentes.
- [x] Com a equipe sem HP, o Ecobeast continua no mapa depois de curar.
- [x] Sem exploração, Procurar responde 404.
- [x] `POST /v1/me/battle` com `ENABLE_TEST_BATTLE` continua igual.

## Desenho técnico

### Arquivos novos

- `server/src/exploration/exploration.store.ts`: `ExplorationStore`, com `MAX_IDLE_MS` de 2 horas, relógio injetado e a interface da [arquitetura](architecture.md#exploração-no-servidor). Ele fica disponível para o `BattleModule`.

### Arquivos alterados

- `server/src/exploration/exploration.service.ts`: troca o `count` da equipe por uma busca dos níveis, carrega `species_biomes` e `evolutions`, chama `rollSpawns` com `secureRandom` e grava no store. Sem equipe, a resposta continua "Crie seu Domador primeiro."
- `server/src/exploration/exploration.dto.ts`: `MapCreatureDto`, e `creatures` em `ExplorationMapDto`.
- `server/src/battle/battle.dto.ts`: `StartWildBodyDto` com `q` e `r`, a mensagem "Posição inválida." e `spawn_id` em `BattleResponseDto`, com `null` fora do início selvagem.
- `server/src/battle/battle.service.ts`: `startWild(userId, position)`.
- `server/src/battle/battle.controller.ts`: corpo e respostas documentadas no `/docs`.
- `server/test/`: `battle`, `capture`, `heal` e `items` chamam `POST /v1/me/battle/wild`. Um helper coloca um Ecobeast direto no `ExplorationStore`, pelo `app.get`, na posição do Domador.

### Arquivos removidos

- `server/src/domain/battle/encounter.ts` e `encounter.spec.ts`.

### Ordem no `startWild`

Da leitura do store até a remoção do Ecobeast não há `await`, a mesma técnica do `act` no `BattleService`:

1. `await this.loadTeam(userId)`, que recusa a equipe sem HP antes de gastar o Ecobeast.
2. Lê a exploração, confere a posição, grava a posição e escolhe o Ecobeast do hexágono. Falhas lançam a exceção da tabela da [arquitetura](architecture.md#contrato).
3. Tira o Ecobeast do store.
4. `await this.createEnemy(speciesId, level)` e `this.begin(...)`.

Um erro no passo 4 só aconteceria com o catálogo quebrado, e o Ecobeast fica perdido nesse caso. Isso é aceito.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e
```

## Tarefas

- [x] Escrever o `ExplorationStore` com testes, vendo falhar antes. A distância usa o `hexDistance` de `domain/exploration/hex.ts`, que já existe.
- [x] Escrever os e2e da exploração e do encontro, e ver falhar.
- [x] Sortear e guardar os Ecobeasts na exploração.
- [x] Mudar `startWild`, o corpo e a resposta.
- [x] Remover `encounter.ts` e atualizar os e2e que chamam a rota.
- [x] Atualizar o `battle-screen/01` e o `battle-core/architecture.md`, que descrevem o sorteio antigo.
- [x] Rodar a verificação e conferir a rota em `/docs`.

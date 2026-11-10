# 01. Registros do Bestiário

- **Status:** rascunho
- **Depende de:** [architecture.md](architecture.md)

## Contexto

O servidor só sabe dos Ecobeasts que o jogador tem agora (`creature_instances`). Os pontos que esta fase toca:

- `BoardBattleService` (`server/src/board-battle/board-battle.service.ts`): as aberturas (`start`, `startWild`, `startTamer`, `startChallenge`, que passam pelo `begin`) e o `act` montam a resposta com `toResponse`, e os eventos já trazem `creature_entered` com `side` e `species_id`.
- `BattleRecordsService.finish` (`server/src/battle/battle-records.service.ts`): grava o fim numa transação só, criando os capturados com `newCreatureData`.
- `ProgressionService.applyEvolution` (`server/src/progression/progression.service.ts`): troca a espécie numa transação.
- `PlayerService` (`server/src/player/player.service.ts`): cria o inicial com `creatureInstance.create`.

## Escopo

- A tabela `codex_entries`, a migração e a carga de quem já joga.
- O `CodexService` e os quatro pontos que registram.
- `registered_species_ids` nas respostas da luta e da Evolução.
- `GET /v1/me/codex` e o `DELETE` de depuração.

## Fora do escopo

- O jogo: vem na [02](02-codex-screen.md) e na [03](03-codex-registered.md).
- A luta antiga (`/v1/me/battle`).

## Requisitos

### Tabela

- **RF-01:** o `schema.prisma` ganha o modelo `CodexEntry` (`codex_entries`), com as colunas, a chave, o índice e as FKs da [arquitetura](architecture.md#tabela), e as relações em `Player` e `Species`.
- **RF-02:** a migração cria a tabela no schema `ecobeasts`, com o `CHECK` de `caught_at >= seen_at` escrito à mão, e insere, para cada par jogador e espécie de `creature_instances`, uma linha com `seen_at` e `caught_at` iguais ao menor `caught_at` desse par. Depois, para cada jogador com Ecobeast, insere como vistos os iniciais de `starter_options` que ele não tem, com `seen_at` igual ao `created_at` dele.

### Registros

- **RF-03:** `CodexService.recordSeen(userId, speciesIds)` e `recordCaught(userId, speciesIds)` fazem o que a [arquitetura](architecture.md#registrar-no-servidor) descreve. Ids repetidos na entrada contam uma vez, e lista vazia não toca no banco. O `recordCaught` também tem uma forma que devolve a escrita, um `INSERT ... ON CONFLICT ... RETURNING` só, para entrar na lista do `$transaction([...])` de quem chama, como a [arquitetura](architecture.md#registrar-no-servidor) explica.
- **RF-04:** toda resposta da luta no tabuleiro registra como vistas as espécies dos `creature_entered` do lado `enemy` daquela resposta, inclusive a luta de teste. A gravação acontece depois de o estado da luta ser guardado, e uma falha nela vai para o log, sem mudar a resposta.
- **RF-05:** o fim de uma luta com captura registra a espécie do capturado como capturada, na transação que cria o Ecobeast. Vale quem foi gravado (`places`): se ninguém for gravado, nada é registrado. Um fim sem captura não registra nada além do visto.
- **RF-06:** a Evolução aceita registra a espécie nova como capturada, na transação que troca a espécie. A cancelada não registra.
- **RF-07:** a escolha do inicial registra a espécie dele como capturada e as outras espécies de `starter_options` como vistas, numa transação com a criação do Ecobeast. O segundo pedido simultâneo continua respondendo "inicial já escolhido" (`STARTER_TAKEN`).

### Contrato

- **RF-08:** o `BoardBattleResponseDto` e o `EvolutionResponseDto` ganham `registered_species_ids: number[]`, as espécies que ficaram capturadas pela primeira vez naquela resposta, documentado no OpenAPI.
- **RF-09:** `GET /v1/me/codex` devolve `{ entries: [{ species_id, caught }] }`, na ordem do `species_id`, num controller novo com a tag "Bestiário" no `/docs`. Sem Domador criado, a lista vem vazia.
- **RF-10:** `DELETE /v1/me/codex` apaga as linhas do jogador e responde 204, só com `ENABLE_TEST_BATTLE`. Sem ela, responde 404 "Rota não encontrada.", como as outras rotas de teste.

## Critérios de aceite

- [ ] A migração roda num banco com jogadores, e cada um fica com as espécies que tem como capturadas, e com os outros iniciais como vistos.
- [ ] Abrir uma luta contra um selvagem registra a espécie dele como vista, e o `GET /v1/me/codex` a mostra com `caught: false`.
- [ ] Uma luta contra Domador registra as espécies dos Ecobeasts do NPC.
- [ ] Capturar um Ecobeast de espécie nova traz `registered_species_ids` com ela no fim da luta, e o `GET` a mostra com `caught: true`. Capturar outro da mesma espécie traz `[]`.
- [ ] Aceitar uma Evolução para uma espécie nova a traz em `registered_species_ids`. Cancelar traz `[]`.
- [ ] Escolher o inicial registra a espécie dele como capturada e os outros dois iniciais como vistos.
- [ ] Apagar o progresso apaga o Bestiário.
- [ ] O `DELETE` apaga os registros com `ENABLE_TEST_BATTLE` e responde 404 sem ela.
- [ ] Testes, lint e typecheck passam.

## Desenho técnico

Arquivos novos:

- `server/prisma/migrations/<data>_codex_entries/migration.sql`: a tabela, o `CHECK` e a carga.
- `server/src/codex/codex.service.ts`, `codex.controller.ts`, `codex.dto.ts` e `codex.module.ts`.
- `server/src/codex/codex.service.spec.ts` e `server/test/codex.e2e-spec.ts`.

Arquivos alterados:

- `server/prisma/schema.prisma`: o modelo e as relações.
- `server/src/board-battle/board-battle.service.ts` e `.dto.ts`: o visto em toda resposta e o `registered_species_ids`, que vem do `BattleFinish`.
- `server/src/battle/battle-records.service.ts`: o capturado registrado na transação do fim, devolvido no `BattleFinish`.
- `server/src/progression/progression.service.ts` e o DTO da Evolução.
- `server/src/player/player.service.ts`: o inicial.
- `server/src/app.module.ts`: o `CodexModule`.
- `server/test/database.e2e-spec.ts`: uma tabela a mais.
- `server/CLAUDE.md`: uma linha sobre o Bestiário.

## Verificação

```bash
cd server && npx prisma migrate dev
cd server && npm test && npm run test:e2e && npm run lint && npm run typecheck
```

## Tarefas

- [ ] Tabela, migração e carga.
- [ ] `CodexService`, com testes.
- [ ] O visto nas lutas do tabuleiro.
- [ ] O capturado na captura, na Evolução e no inicial, com `registered_species_ids`.
- [ ] As rotas `GET` e `DELETE`.
- [ ] Rodar a verificação, atualizar o `server/CLAUDE.md` e mudar o status aqui e no README.

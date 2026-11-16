# 01. A descoberta guardada no servidor

- **Status:** concluída
- **Depende de:** [islands](../islands/)

## Contexto

Nas ilhas, o que o Domador descobre fica guardado na conta ([README](README.md#decisões)). O jogo é quem percebe o que foi descoberto, porque o servidor não acompanha o andar; esta fase dá ao servidor onde guardar, o que devolver na entrada e as rotas para gravar e apagar. O jogo só passa a usá-las na [03](03-island-memory.md).

## Escopo

- A tabela `ecobeasts.island_discoveries`, com a migração e o modelo do Prisma.
- O campo `discovered` na resposta da entrada (`POST /v1/me/exploration`).
- `POST /v1/me/islands/{id}/discoveries`, que grava hexágonos descobertos.
- `DELETE /v1/me/islands/{id}/discoveries`, de depuração, que apaga a descoberta da ilha.

## Fora do escopo

- Qualquer mudança no jogo (fases 02 e 03).
- Conferir se o Domador chegou perto dos hexágonos que manda.
- Guardar a descoberta do mapa sorteado.

## Requisitos

- **RF-01:** A tabela `ecobeasts.island_discoveries` tem `player_id` (uuid, FK para o jogador, `ON DELETE CASCADE`), `island_id` (FK para `islands`, `ON DELETE CASCADE`), `q` e `r` (inteiros) e `discovered_at` (`timestamptz`, padrão `now()`), com a chave primária (`player_id`, `island_id`, `q`, `r`). O modelo do Prisma é `IslandDiscovery`, no estilo de `CodexEntry`. A migração é escrita à mão e aplicada com `prisma migrate deploy`.
- **RF-02:** A resposta de `POST /v1/me/exploration` ganha `discovered: {q, r}[]`. Com `{island_id}`, são os hexágonos do jogador naquela ilha que existem na versão publicada (os de uma versão antiga que sumiram ficam na tabela, mas não voltam). Sem `island_id`, é uma lista vazia.
- **RF-03:** `POST /v1/me/islands/{id}/discoveries`, com o corpo `{tiles: {q, r}[]}`, de 1 a 1000 itens, grava os hexágonos que existem na versão publicada da ilha e ainda não estavam gravados para o jogador, numa só instrução SQL (`INSERT ... SELECT` juntando com `island_tiles` da versão publicada e com `players`, e `ON CONFLICT DO NOTHING`). Os que não existem na ilha são ignorados, sem erro, e um usuário sem Domador grava 0. Responde `201` com `{added: number}`, a quantidade de linhas novas.
- **RF-04:** Uma ilha que não existe ou nunca foi publicada responde `404` com `ISLAND_NOT_FOUND`; um `id` que não é inteiro, `400` com `ISLAND_NOT_FOUND` (um inteiro sem ilha, como 0, cai no `404`). Um corpo sem `tiles`, com a lista vazia ou com mais de 1000 itens, ou com um `q` ou `r` que não é inteiro (ou passa de 100.000 em módulo), responde `400` com a mensagem nova `INVALID_DISCOVERY` ("Hexágonos descobertos inválidos.").
- **RF-05:** `DELETE /v1/me/islands/{id}/discoveries` apaga todas as linhas do jogador naquela ilha e responde `200` com `{removed: number}`. A rota só existe com `ENABLE_TEST_BATTLE` ligada; sem ela, responde `404`, como as outras rotas de depuração.
- **RF-06:** As três rotas pedem a sessão (`AuthGuard`), e cada jogador só lê e grava as próprias linhas. Elas aparecem em `/docs`, com as respostas de erro.

## Critérios de aceite

- [x] Entrar numa ilha nunca visitada devolve `discovered: []`; no mapa sorteado também.
- [x] Depois de gravar 3 hexágonos da ilha, entrar nela devolve os 3, e outro jogador recebe `[]`.
- [x] Gravar de novo os mesmos 3 devolve `{added: 0}`; gravar 2 que existem e 1 fora da ilha devolve `{added: 2}`.
- [x] Gravar numa ilha que não existe devolve `404`; com 1001 itens, `400` com `INVALID_DISCOVERY`.
- [x] Um hexágono gravado que some ao republicar a ilha não volta em `discovered`.
- [x] O `DELETE` apaga só a ilha pedida e só do jogador; com `ENABLE_TEST_BATTLE` desligada, responde `404`.
- [x] Os testes do servidor passam.

## Desenho técnico

- **Criar:**
  - `server/prisma/migrations/<timestamp>_island_discoveries/migration.sql` (com um timestamp depois da última migração).
  - `server/src/islands/discoveries.service.ts`: `listDiscovered(userId, islandId, tiles)` (filtra pelos hexágonos da versão publicada que a entrada já leu), `addDiscovered(userId, islandId, tiles)` e `forget(userId, islandId)`.
  - `server/test/island-discoveries.e2e-spec.ts`.
- **Alterar:**
  - `server/prisma/schema.prisma` (`IslandDiscovery` e as relações em `Player` e `Island`).
  - `server/src/islands/islands.controller.ts` (`@Controller('me/islands')`): as rotas `POST` e `DELETE` de `:id/discoveries`.
  - `server/src/islands/islands.dto.ts`: `DiscoveriesBodyDto`, `DiscoveriesAddedDto`, `DiscoveriesRemovedDto` e `INVALID_DISCOVERY`.
  - `server/src/islands/islands.module.ts`: o serviço novo, exportado para a exploração.
  - `server/src/exploration/exploration.service.ts` e `exploration.dto.ts`: `discovered` na `ExplorationResponseDto`.
- **Reutilizar:** a busca da versão publicada que a entrada já faz (`ISLAND_NOT_FOUND`), o `HexCoord` do domínio, o jeito de checar `ENABLE_TEST_BATTLE` de `board-battle.service.ts` e o jeito de achar o jogador pela sessão de `codex.service.ts`.

## Verificação

- `npm test` e `npm run test:e2e` em `server/`.
- Em `/docs`, chamar a entrada numa ilha, o `POST` com 3 hexágonos, a entrada de novo e o `DELETE`.

## Tarefas

- [x] Migração e modelo do Prisma.
- [x] Serviço e rotas `POST` e `DELETE`.
- [x] `discovered` na entrada.
- [x] Testes e2e.
- [x] Atualizar `server/CLAUDE.md`, o README e as tabelas das specs.

Conferido por Claude: `npm run lint`, `npm run typecheck`, `npm test` e o `test/island-discoveries.e2e-spec.ts`, com os e2e de ilhas e de exploração.

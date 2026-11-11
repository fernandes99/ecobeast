# 02. A exploração numa ilha

- **Status:** rascunho
- **Depende de:** [01-area-spawn-count](01-area-spawn-count.md), [architecture.md](architecture.md)

## Contexto

Com a [01](01-area-spawn-count.md), cada área de uma ilha diz quantos Ecobeasts nascem nela. Hoje, só as rotas do editor leem as ilhas, e `POST /v1/me/exploration` sempre gera um mapa sorteado. Esta fase dá ao jogador a lista das ilhas publicadas e deixa a mesma rota de exploração começar numa ilha, com os Ecobeasts sorteados pelas áreas e as construções na resposta. A luta, a captura e a conferência da posição não mudam: elas usam a exploração guardada no `ExplorationStore`, e uma ilha é uma exploração com outro mapa.

## Escopo

- O `IslandsService` compartilhado, com a leitura de uma versão que hoje está no `IslandsEditorService`.
- `GET /v1/me/islands`.
- `POST /v1/me/exploration` com `{island_id}`.
- O sorteio dos Ecobeasts pelas áreas, numa função pura.

## Fora do escopo

- As telas do jogo (a [03](03-island-screens.md)).
- Os Domadores NPC na ilha.
- Guardar em cache a versão publicada: cada entrada lê a ilha do banco.
- Liberar as ilhas por jogador.

## Requisitos

### A lista

- **RF-01:** `GET /v1/me/islands`, com `AuthGuard`, responde `200 {islands: [{id, name}]}` com as ilhas que têm versão publicada, em ordem de `id`. O nome é o da versão publicada, e não o do rascunho. Sem nenhuma, `islands` é `[]`.
- **RF-02:** a rota não exige Domador: a lista é a mesma para todo jogador logado.

### Começar numa ilha

- **RF-03:** o corpo de `POST /v1/me/exploration` passa a ser opcional. Sem corpo, ou sem `island_id`, a rota faz o mapa sorteado de hoje, sem mudança.
- **RF-04:** com `island_id`, a ordem das respostas é:
  1. `400` "Ilha não encontrada." se `island_id` não é um inteiro maior que 0 (a validação do corpo vem antes de tudo);
  2. `409` "Crie seu Domador primeiro." sem Domador ou sem equipe, como hoje;
  3. `404` "Ilha não encontrada." se a ilha não existe ou nunca foi publicada;
  4. `201` com o mapa da versão publicada.
- **RF-05:** o mapa da ilha vem no mesmo formato de hoje (`seed`, `start`, `tiles`, `creatures`, `tamers`), com:
  - `seed` igual ao id da ilha, a mesma que o editor usa para as decorações e os escorridos, então a ilha fica igual à do editor;
  - `start` igual à chegada da versão publicada;
  - os hexágonos dela, só com `q`, `r`, `biome`, `shape` e `variant`: a área de cada hexágono, que a leitura da versão traz, não vai para o jogador;
  - `tamers` vazio.
- **RF-06:** o `map` ganha `island` e `buildings` nas duas explorações:
  - numa ilha, `island` é `{id, name}`, com o nome da versão publicada, e `buildings` é a lista das construções, cada uma com `building_type_id` e os `tiles` (`{q, r}`);
  - no mapa sorteado, `island` é `null` e `buildings` é `[]`.
- **RF-07:** o servidor guarda a exploração da ilha no `ExplorationStore` como guarda a sorteada: os Ecobeasts por id, nenhum Domador e a posição na chegada. Uma exploração nova, sorteada ou numa ilha, troca a anterior.

### Os Ecobeasts da ilha

- **RF-08:** em cada área com espécie e com pelo menos um hexágono fora de construção, nascem `spawn_count` Ecobeasts. Para cada um, o servidor sorteia:
  - o hexágono, de forma uniforme entre os hexágonos da área que não são de construção, podendo repetir;
  - a espécie, pelo peso dela na área;
  - o nível, de forma uniforme entre o mínimo e o máximo da espécie, com os dois inclusos.
- **RF-09:** uma área sem hexágonos fora de construção não sorteia nenhum. Um hexágono sem área nunca recebe Ecobeast.
- **RF-10:** a espécie e o nível do mapa são os da luta. A espécie é a que o dono pôs na área, mesmo com um nível acima do de Evolução dela. Procurar (`POST /v1/me/board-battle/wild`) e a captura não mudam.
- **RF-11:** os ids dos Ecobeasts vão de 1 em diante, na ordem das áreas e do sorteio. As rotas de depuração (`/v1/me/exploration/spawns` e `/tamers`) funcionam numa ilha como no mapa sorteado.

### A documentação

- **RF-12:** `/docs` descreve o corpo opcional, o `404`, os campos `island` e `buildings` e a rota da lista, na tag "Exploração" e numa tag "Ilhas".

## Critérios de aceite

- [ ] Com uma ilha publicada e outra só em rascunho, `GET /v1/me/islands` traz só a publicada, com o nome publicado mesmo depois de o rascunho mudar de nome.
- [ ] `POST /v1/me/exploration {island_id}` de uma ilha publicada traz os hexágonos, a chegada, as construções e `island`; de uma em rascunho ou inexistente, `404`; com `"x"` ou `0`, `400`.
- [ ] Sem corpo, a rota responde como antes, com `island: null` e `buildings: []`.
- [ ] Numa ilha com duas áreas de `spawn_count` 3 e 5, vêm 8 Ecobeasts, cada um num hexágono da sua área, nenhum em construção, com espécies da área.
- [ ] Procurar no hexágono de um desses Ecobeasts abre a luta com a espécie e um nível entre o mínimo e o máximo dele, e a captura funciona.
- [ ] Os testes do servidor passam.

## Desenho técnico

Arquivos novos:

- `server/src/islands/islands.module.ts`: `IslandsModule`, que importa o `AuthModule` (para o `AuthGuard`, como o `ExplorationModule`), com o `IslandsService` exportado e o `IslandsController`.
- `server/src/islands/islands.service.ts`: `IslandsService`.
  - `readVersion(client, islandMapId)`: a leitura de hoje do `IslandsEditorService`, movida sem mudança de comportamento, agora com o `spawnCount`.
  - `listPublished()`: as ilhas com versão publicada, `{id, name}`.
  - `readPublished(islandId)`: `{id, name, draft}` da versão publicada, ou `null`.
  - `ISLAND_NOT_FOUND` ("Ilha não encontrada.") sai do `islands-editor.service.ts` e passa a morar aqui; o editor importa daqui.
- `server/src/islands/islands.controller.ts`: `GET /v1/me/islands`.
- `server/src/islands/islands.dto.ts`: `PlayerIslandDto` e `PlayerIslandsResponseDto`. Os nomes não podem repetir os do editor (`IslandSummaryDto`): o `/docs` guarda os esquemas pelo nome da classe, e um apagaria o outro.
- `server/src/domain/islands/area-spawns.ts`, com as funções puras:
  - `spawnAreas(draft)`: as áreas do rascunho, cada uma com os hexágonos fora de construção, a quantidade e as espécies;
  - `rollAreaSpawns(areas, random)`: os `MapSpawn`s. Usa o `pickWeighted` de `domain/exploration/spawns.ts`.
- `server/src/domain/islands/area-spawns.spec.ts`, com uma `random` fixa:
  - a quantidade por área;
  - nenhum Ecobeast em construção nem fora da área;
  - a área sem espécie e a área só de construção;
  - o nível nos limites;
  - o peso.
- `server/test/islands.e2e-spec.ts`: a lista e a exploração numa ilha, com as ilhas de teste criadas e apagadas pelo próprio teste.

Arquivos alterados:

- `server/src/editor/islands-editor.service.ts`: usa o `IslandsService.readVersion`; o `EditorModule` importa o `IslandsModule`.
- `server/src/exploration/exploration.dto.ts`: `StartExplorationBodyDto` (`island_id` opcional, `@IsInt` e `@Min(1)` com a mensagem "Ilha não encontrada.", o `@Min` só com um inteiro, por `@ValidateIf`, como no `DebugSpawnBodyDto`: a validação junta as mensagens numa frase só, e `"x"` daria a mensagem duas vezes), `MapIslandDto`, `MapBuildingDto`, e `island` e `buildings` no `ExplorationMapDto`.
- `server/src/exploration/exploration.service.ts`: `start(userId, islandId?)`. Sem ilha, o mapa sorteado de hoje com `island: null` e `buildings: []`. Com ilha, ele confere o Domador, lê a versão publicada, sorteia pelas áreas e guarda a exploração.
- `server/src/exploration/exploration.controller.ts`: o corpo opcional e as respostas novas no `/docs`.
- `server/src/exploration/exploration.module.ts`: importa o `IslandsModule`.
- `server/src/app.module.ts`: o `IslandsModule`.
- `server/test/exploration.e2e-spec.ts`: `island: null` e `buildings: []` no mapa sorteado.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Com o servidor local e uma ilha publicada pelo editor: chamar `GET /v1/me/islands` e `POST /v1/me/exploration {island_id}` pelo `/docs`, conferir as construções e os Ecobeasts nas áreas, e Procurar num deles.

## Tarefas

- [ ] O `IslandsService`, com a leitura movida, e o editor usando ele.
- [ ] `spawnAreas` e `rollAreaSpawns`, com os testes.
- [ ] `GET /v1/me/islands`.
- [ ] A exploração numa ilha, com o e2e.
- [ ] Rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README da iniciativa.

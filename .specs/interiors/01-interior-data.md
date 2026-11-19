# 01. As salas no banco

- **Status:** concluída
- **Depende de:** [free-objects](../free-objects/), [island-npcs](../island-npcs/)

## Contexto

As salas são dados de design e moram no banco ([architecture](architecture.md#as-tabelas)). Esta fase cria as tabelas, as rotas do jogo e do editor, a sala na peça solta e a primeira sala, o Refúgio, convertida do quarto de exemplo do pacote. O jogo ainda não entra em nenhuma sala.

## Escopo

- As tabelas `interiors`, `interior_tiles`, `interior_objects`, `interior_blocks` e `interior_npcs`, e a coluna `island_props.interior_id`.
- As rotas `GET /v1/interiors/:id` e as de `/v1/editor/interiors`.
- O `interior_id` da peça no salvar e na publicação da ilha, no mapa de Explorar e no `MapProp` do jogo.
- As folhas do pacote no jogo e o script que converte o `Interior1.tmx`.
- A sala 1, "Refúgio", na migration.

## Fora do escopo

- A tela do interior (fase 02).
- O modo Interiores do F2 e a escolha da sala na peça (fase 03).

## Requisitos

- **RF-01:** A migration `interiors` cria as tabelas e a coluna com as colunas, as chaves, as FKs e os `CHECK` da [architecture](architecture.md#as-tabelas), à mão, com `prisma migrate deploy`, como as outras.
- **RF-02:** O `client/assets/interiors/import_tmx.py <arquivo.tmx> <nome>` lê um mapa do Tiled com as folhas do pacote e escreve, na saída, o SQL que insere a sala:
  - as camadas `Floor` → `floor`, `Tile Layer 6` → `floor_detail`, `Walls` → `wall` e `Windows` → `wall_detail`; as camadas `Boxes`, `Objects1` e `Objects2` viram objetos;
  - a sala começa no menor quadrado usado (o `.tmx` é infinito, com pedaços em coordenadas negativas) e tem o tamanho do que é usado;
  - nas camadas de objetos, os tiles vizinhos que também são vizinhos na folha, na mesma posição relativa, viram um objeto só, do retângulo que os cobre, quando o grupo enche o retângulo; senão, cada trecho seguido de uma coluna do grupo vira um objeto. Os objetos saem na ordem das camadas (`Boxes`, `Objects1`, `Objects2`) e, em cada uma, de cima para baixo e da esquerda para a direita;
  - os tapetes (os tiles da folha `interior` nas linhas 16 a 22) de uma camada de objetos vão para a camada `floor_detail`, por cima do que já estiver nela, para ficarem por baixo do Domador (no `Interior1.tmx`, o tapete vermelho já está na `Tile Layer 6`, e o redondo está na `Objects1`);
  - os bloqueios são os quadrados com um tile sólido na camada `wall` ([architecture](architecture.md#quando-um-quadrado-bloqueia)), os da linha de baixo de cada objeto com 2 ou mais linhas e os do objeto inteiro com 1 linha;
  - a porta é o quadrado com chão e fora dos bloqueios, na linha mais de baixo que tem um, o mais perto do meio dela.
  
  Ele usa o Pillow para ler a transparência dos tiles, como os scripts de arte das peças (`make_*.py`).
- **RF-03:** A migration insere a sala 1, "Refúgio", com o SQL do script sobre o `Interior1.tmx` do pacote, sem NPCs.
- **RF-04:** `walls_floor.png`, `Interior.png` e `Doors_windows_animation.png` vão para `client/assets/interiors/main_home/` com os nomes `walls_floor.png`, `interior.png` e `doors_windows.png`, sem mudar os pixels, com o `.import` sem filtro, como a outra arte. Os créditos vão para `client/assets/interiors/CREDITOS.md`.
- **RF-05:** As rotas da [architecture](architecture.md#as-rotas), com as mensagens e os limites dela. `GET /v1/interiors/:id` fica num módulo novo, `server/src/interiors/`, e as do editor em `server/src/editor/interiors-editor.*`.
- **RF-06:** O rascunho da ilha guarda o `interior_id` de cada peça, a publicação o copia, e o `GET` do editor e o mapa de Explorar o devolvem (0 ou ausente é sem sala, como o resto do mapa trata os nulos). Uma sala que não existe no salvar da ilha dá 400 "Esse interior não existe.".
- **RF-07:** No jogo, o `MapProp` ganha `interior_id: int` (0 sem sala), lido do mapa de Explorar e do rascunho do editor, e o `Session.load_interior(id) -> Result` devolve a sala como `Interior`. Os modelos `Interior`, `InteriorTile`, `InteriorObject` e `InteriorNpc` leem e escrevem o corpo da [architecture](architecture.md#as-rotas).

## Critérios de aceite

- [x] `GET /v1/interiors/1` devolve o Refúgio convertido, com tiles nas 4 camadas, objetos, bloqueios e a porta num quadrado de chão.
- [x] `GET /v1/interiors/999` dá 404 "Esse lugar não existe.".
- [x] O `PUT /v1/editor/interiors/:id` troca a sala e devolve os `id` novos; com a porta num quadrado bloqueado, dá 400 com a mensagem da porta; com um tile fora da sala, dá 400.
- [x] O `POST` cria uma sala vazia, e o `DELETE` a apaga; o `DELETE` de uma sala ligada a uma peça dá 409.
- [x] As rotas do editor dão 403 a quem não está em `MAP_EDITOR_USER_IDS`.
- [x] Salvar uma ilha com uma peça ligada a uma sala e publicar faz o mapa de Explorar trazer o `interior_id` da peça.
- [x] Rodar o `import_tmx.py` de novo dá o mesmo SQL.
- [x] A suíte inteira do servidor passa, menos as 2 falhas que já existiam no `seed.e2e`.
- [x] `godot --headless --path client --quit-after 30` roda sem erro de script.

## Desenho técnico

- **Criar:**
  - `server/prisma/migrations/<data>_interiors/migration.sql`
  - `server/src/interiors/` (módulo, controller, service e DTO)
  - `server/src/editor/interiors-editor.controller.ts`, `.service.ts` e `.dto.ts`
  - `server/test/interiors.e2e-spec.ts`, no grupo que escreve (`CATALOG_WRITERS`), apagando o que cria
  - `client/assets/interiors/import_tmx.py`, `CREDITOS.md` e `main_home/*.png`
  - `client/domain/models/interior.gd`, `interior_tile.gd`, `interior_object.gd` e `interior_npc.gd`
- **Alterar:**
  - `server/prisma/schema.prisma` (os 5 modelos e o `IslandProp.interiorId`)
  - `server/src/domain/islands/island-draft.ts`, `server/src/editor/islands-editor.dto.ts` e `.service.ts`, `server/src/islands/islands.service.ts` e `server/src/exploration/exploration.dto.ts` (o `interior_id` da peça, pelo caminho do `no_smoke`)
  - `server/test/database.e2e-spec.ts` (5 tabelas a mais)
  - `client/domain/models/map_prop.gd`, `client/tools/map_editor/island_draft.gd` e o `stamp.gd` (o carimbo leva o `interior_id`)
  - `client/core/services/game_service.gd`, `api_game_service.gd` e `client/core/autoload/session.gd`
  - `.specs/game-data/architecture.md` (as tabelas novas)

## Verificação

- `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` no `server/`.
- `godot --headless --path client --quit-after 30`.
- O `import_tmx.py` rodado duas vezes, com a saída comparada.
- Uma imagem da sala 1 montada pelo script a partir do SQL, comparada com o quarto de exemplo.

## Tarefas

- [x] A migration, o script e as folhas.
- [x] As rotas, o `interior_id` da peça e o e2e.
- [x] Os modelos e o `Session.load_interior` no jogo.

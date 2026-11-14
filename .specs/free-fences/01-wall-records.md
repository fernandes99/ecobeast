# 01. As paredes no banco e no desenho

- **Status:** concluída (falta o dono ver no editor e no jogo)
- **Depende de:** [free-trails/03](../free-trails/03-trail-records.md) (concluída), que esta fase repete para as paredes

## Contexto

A iniciativa está no [README](README.md), e o desenho no [architecture.md](architecture.md). Esta fase traz:
- o catálogo `wall_types`;
- a tabela `island_walls`;
- o contrato do editor e de Explorar numa ilha;
- o desenho das cercas no jogo e no editor.

As paredes ainda não bloqueiam (é a [02](02-wall-blocking.md)), e o editor ainda não as desenha (é a [03](03-fence-tool.md)). Até lá, os testes põem paredes pelo contrato.

## Escopo

- O catálogo e a tabela, com a validação e o `content_hash`.
- As paredes no salvar, no ler e no publicar do editor, e na resposta de Explorar numa ilha.
- O `MapWall`, o `ExplorationMap.walls` e o rascunho do editor com as paredes.
- A arte `assets/walls/<slug>.png`, o `HexWalls` e o desenho no `HexMapView`, no editor e na visão de cima.

## Fora do escopo

- O bloqueio ([02](02-wall-blocking.md)), a ferramenta Cerca ([03](03-fence-tool.md)) e a conversão ([04](04-fence-conversion.md)).
- A Cerca (cidade) continua igual nesta fase.

## Requisitos

- **RF-01:** a migration `20261127000000_free_fences_walls`, escrita à mão com o prefixo `"ecobeasts".` e aplicada com `migrate deploy`:
  - cria `wall_types` (`id`, `slug` único, `name`, `visible`) com as 3 linhas do [architecture.md](architecture.md#o-catálogo-wall_types-fase-1);
  - cria `island_walls` com os `CHECK`s da tabela de lá (`points` de 4 a 256 números, tamanho par).
  - No `schema.prisma`, os modelos `WallType` e `IslandWall`. No `seed-data`, o `wall_types.json`. No catálogo, a tabela `wall_types`.
- **RF-02:** o rascunho (`domain/islands/island-draft.ts`) tem `walls?: DraftWall[]` (`{ type: string; points: number[] }`), conferido como no architecture. Os limites são `MAX_WALLS = 2000` e `MAX_WALL_POINTS = 128`. As mensagens:
  - "A ilha pode ter até 2.000 paredes."
  - "A parede 3 tem um tipo que não existe."
  - "A parede 3 precisa ter de 2 a 128 pontos inteiros."
  - "A parede 3 tem um ponto fora da ilha."
  - O `canonicalDraft` leva as paredes, na ordem, só quando há alguma.
- **RF-03:** salvar grava as paredes na ordem recebida (`position`), ler as devolve na mesma ordem, e publicar as copia com a versão, como os traços.
- **RF-04:** a resposta de Explorar numa ilha manda `walls`, na ordem, sempre presente (vazia sem paredes). O mapa sorteado manda `walls: []`, como faz com `trails`.
- **RF-05:** a arte `client/assets/walls/<slug>.png` (só os tipos visíveis) tem 192×72: a célula 0 é o poste e a célula 1 é a travessa reta, tirados do desenho da Cerca (cidade) no `make_town.gd`, com o pé em (48, 43). A faixa da travessa são as colunas 0 a 27 da célula 1 (revisto na implementação; ver o Resultado).
- **RF-06:** o `HexWalls.pieces(wall)` devolve os pedaços de uma parede no chão plano, como no [architecture.md](architecture.md#o-desenho-fase-1):
  - uma fatia por passo de 1 px no eixo em que o trecho mais anda;
  - um poste em cada ponto e postes a espaços iguais entre eles, de cerca de 20 px (`POST_GAP`), ou de cerca de 10 px (`STEEP_POST_GAP`) num trecho que anda mais na vertical.
  - A parede invisível não tem pedaços.
- **RF-07:** o `HexMapView` desenha os pedaços nas faixas de decoração, sem vento:
  - cada um na altura do hexágono embaixo do pé e na faixa do pé (`band_of`);
  - na faixa, em ordem de y, com o poste por cima das fatias do mesmo ponto.
  - O `set_walls(walls, changed)` remonta só os pedaços de mapa que as paredes mudadas tocavam e tocam.
- **RF-08:** no editor:
  - a parede invisível aparece como uma linha tracejada por cima do mapa;
  - a visão de cima mostra todas as paredes como linhas finas;
  - apagar hexágonos tira das paredes os pontos que caíram fora (`clip_walls`, como `clip_trails`).

## Critérios de aceite

- [x] O editor salva uma ilha com paredes (postas pelo contrato) e, ao abrir de novo, elas voltam iguais, na mesma ordem.
- [x] O servidor recusa: um tipo que não existe, um ponto só, mais de 128 pontos, pontos não inteiros, um ponto fora da ilha e mais de 2.000 paredes, cada um com a mensagem do RF-02.
- [x] Uma ilha sem paredes tem o mesmo `content_hash` de antes.
- [x] Numa imagem, uma cerca de madeira e um muro de pedra em vários ângulos (deitado, diagonal, quase vertical) e cruzando um degrau aparecem como no teste aprovado, e o Domador fica atrás de um trecho na frente dele e na frente de um trecho atrás dele.
- [ ] A parede invisível não aparece no jogo (conferido) e aparece tracejada no editor (com o dono, no F2).

## Desenho técnico

**Servidor** (o mesmo caminho dos traços, [free-trails/03](../free-trails/03-trail-records.md#desenho-técnico)):

- `prisma/migrations/20261127000000_free_fences_walls/migration.sql`, `prisma/schema.prisma` e `prisma/seed-data/wall_types.json`.
- `src/catalog/catalog-tables.ts`: `table('wall_types', 'wallType')`.
- `src/domain/islands/island-draft.ts`:
  - `DraftWall`, `walls` no `IslandDraft`, `wallSlugs` no `KnownIds`;
  - `wallsError` ao lado de `trailsError`, e as paredes no `canonicalDraft`.
- `src/editor/islands-editor.dto.ts` e `.service.ts`: o `DraftWallDto` e o `wallSlugs`, montado como o `groundSlugs`; a gravação e a leitura.
- `src/islands/islands.service.ts`, `src/exploration/exploration.dto.ts` (`MapWallDto`, `toWallDto`) e `.service.ts`.

**Cliente:**

- `core/data/catalog_schema.gd`: a tabela `wall_types`.
- `domain/models/map_wall.gd` (novo): `type: String`, `points: PackedVector2Array` (com o `MapTrail.ORIGIN`), `from_dict`, `to_dict` e `copy`.
- `domain/models/exploration_map.gd`: `walls: Array[MapWall]`, lidas do contrato.
- `assets/map_objects/make_town.gd`: gera `assets/walls/wood_fence.png` (variante 1) e `stone_fence.png` (variante 2) com `_town_fence_parts`.
- `ui/components/hex_walls.gd` (novo): `class Piece` (`flat: Vector2i` o pé no chão plano, `post: bool`, `column: int`, `slug: String`) e `static func pieces(wall: MapWall) -> Array[Piece]`.
- `ui/components/hex_map_view.gd`:
  - `_walls_by_chunk`, montado no `set_map` e no `set_walls(walls: Array[MapWall], changed: Array[MapWall])`;
  - os pedaços entram no `_add_decorations`, numa malha por textura e por faixa, como o `_add_file_props`.
- `tools/map_editor/island_draft.gd`: `walls`, lidas e mandadas, `copy_walls`, `walls_state` e `clip_walls`, chamado onde o `clip_trails` é.
- `tools/map_editor/editor_canvas.gd` e `island_overview.gd`: a linha tracejada e as linhas finas.

## Verificação

- **Servidor:**
  - os testes de unidade da validação, vendo falhar antes;
  - os e2e do banco (as tabelas e os `CHECK`s), do editor (ida e volta, ponto fora da ilha) e de Explorar (as paredes numa ilha, vazio no sorteado);
  - o lint, o typecheck e as duas suítes inteiras antes do commit.
- **Cliente:** uma cena temporária em `client/zz_tmp_check/`, com janela por poucos quadros, que falha antes e passa depois, apagada no fim. Ela confere:
  - o `MapWall` lendo e voltando ao contrato;
  - o `IslandDraft` com as paredes;
  - o `HexWalls.pieces` de uma parede reta de 40 px deitada (41 fatias e 3 postes) e de uma quase vertical (postes a cerca de 10 px);
  - o `clip_walls`;
  - a ida e volta pelo servidor local.
- **Print:** a imagem do critério de aceite, com o Domador na frente e atrás.
- **Projeto:** o jogo sem janela abre sem erros de script e sem avisos novos.

## Tarefas

- [x] **1. Servidor, catálogo e tabela:** a migration, o `schema.prisma`, o `seed-data` e a tabela no catálogo. Teste: o e2e do banco com as 3 linhas de `wall_types` e o `CHECK` dos pontos recusando 3 números.
- [x] **2. Servidor, contrato:** `DraftWall`, `wallsError`, o canônico, o editor, a publicação e Explorar.
  - **Testes de unidade** em `island-draft.spec.ts`, vendo falhar antes:
    - aceita uma parede `wood_fence` de 2 pontos;
    - recusa cada caso do RF-02 com a mensagem exata;
    - o hash de uma ilha sem paredes não muda.
  - **e2e:** a ida e volta no editor e as paredes em Explorar.
- [x] **3. Cliente, dados:** `wall_types` no esquema, `MapWall`, `ExplorationMap.walls`, o `IslandDraft` e o `clip_walls`. Teste na cena temporária: as conferências de dados da Verificação.
- [x] **4. Cliente, arte e pedaços:** as folhas de `assets/walls/` e o `HexWalls.pieces`. Teste na cena: as contagens de fatias e postes da Verificação.
- [x] **5. Cliente, desenho:** o `HexMapView` (faixas, altura, `set_walls`), a linha tracejada no editor e a visão de cima. Conferido pela imagem do critério de aceite.
- [x] **6. Fechamento:**
  - as suítes do servidor e o jogo sem janela;
  - o `client/CLAUDE.md` e o `server/CLAUDE.md`, onde citam os traços;
  - o status desta fase no README;
  - o commit `feat: as paredes no banco e no desenho (free-fences 01)`.

## Pontos de atenção

- **Um trecho de 1 px:** dois pontos iguais ou vizinhos não podem dividir por zero no `pieces`. Sai um poste só.
- **Um trecho sobre a água ou na beira:** o pé pode cair num hexágono de água ou fora da ilha. Sobre a água, o pedaço sobe a altura da água. Fora da ilha, ele não é desenhado (o servidor já recusa o ponto, mas a fatia entre dois pontos pode passar fora).
- **Muitas paredes:** 2.000 paredes de 128 pontos é o pior caso. Os pedaços são montados uma vez por pedaço de mapa, nunca a cada quadro.
- **A ordem com o Domador:** um poste de 14 px de altura com o pé atrás do Domador não pode cobrir o rosto dele. O pé decide a faixa, como nas peças soltas.
- **A emenda do muro de pedra:** os tijolos precisam fechar na repetição da faixa.

## Resultado da verificação

Em 2026-11-14:

- **Desvios da spec**, os dois no [architecture.md](architecture.md):
  - **A travessa:** é uma célula reta própria, com a faixa de 28 colunas (`RAIL_SPAN`). O muro de pedra tem uma emenda a cada 7 px; com 24 colunas, ela quebrava. A emenda da travessa reta é desenhada exata (`_straight_wall`), porque a do muro em diagonal saía irregular pelo arredondamento.
  - **A linha de desenho:** cada pedaço vai na linha do hexágono mais à frente que a base dele toca, com a altura do hexágono do pé. Na primeira imagem, o chão da linha seguinte cortava a base dos postes perto da divisa.
- **O `make_town.gd`** tem cópias do caminho e do tamanho da célula das paredes, porque o `HexWalls` usa o `GameData`, que um script com `-s` não tem (como o `HexFences`).
- **Servidor:**
  - **Testes de unidade:** os 5 da validação das paredes falharam antes (o de aceitar já passava) e passaram depois. O teste do `wall_types.json` falhou antes, sem o arquivo.
  - **Banco:** a migration `20261127000000_free_fences_walls` foi aplicada com `migrate deploy`, e o `migrate diff` saiu vazio.
  - **e2e:** o banco (60 tabelas, os `CHECK`s dos pontos e do slug), o editor (ida e volta, ponto fora da ilha, tipo que não existe) e Explorar (as paredes numa ilha, vazio no sorteado). Eles foram escritos depois do código, então não foram vistos falhando.
  - **Suítes:** o lint, o typecheck e os testes de unidade (833 de 833) passaram. A suíte e2e inteira passou (526 de 526).
- **Cliente:**
  - **Teste sem janela** (`zz_tmp_check/walls_check`, apagado): 21 de 21. Ele falhou antes, sem o `MapWall` e sem o `HexWalls`, e confere:
    - o contrato, o mapa, o rascunho e o `clip_walls`;
    - 41 fatias e 3 postes numa reta de 40 px;
    - os postes a cerca de 10 px num trecho quase vertical;
    - um poste só com dois pontos iguais, e a invisível sem pedaços.
  - **Imagem** (`zz_tmp_check/walls_render`, apagada), conferida:
    - um cercado de madeira, um muro de pedra cruzando um platô de altura 3 e outro em diagonal, uma cerca quase vertical, e a parede invisível sem aparecer;
    - o Domador na frente do lado de trás do cercado e atrás do lado da frente.
  - **Projeto:** o jogo sem janela abre sem erros de script e sem avisos.
- **Revisão final** (um revisor novo, sobre toda a mudança). Três correções, cada uma com um teste que falhou antes e passou depois (`zz_tmp_check/walls_fix_check`, 5 de 5, apagado):
  - **A cerca atrás de um hexágono mais alto** ia para a linha da frente e aparecia por cima dele. Agora ela só muda de linha para um hexágono que não é mais alto que o do pé.
  - **Apagar, pôr ou subir um hexágono no editor** deixava os pedaços de cerca onde estavam. O `update_tiles` agora refaz o índice das paredes, com os pedaços de cada parede guardados (`_wall_pieces`) para não montar tudo de novo.
  - **O corte de altura** escondia pelo hexágono onde o pedaço é desenhado. Agora esconde pelo hexágono do pé (`_wall_entries`).
- **Para a [03](README.md#fases):** o `set_walls` refaz o índice inteiro, e o `refresh_walls` compara as listas com `Array.has`. Com a ferramenta Cerca mudando paredes a cada clique, isso precisa ficar só nas paredes mudadas.
- **O servidor da porta 3100,** que já estava rodando, devolveu erro 500 no catálogo depois da tabela nova (o cliente do Prisma dele é de antes). Os testes do cliente rodaram num servidor separado, na porta 3101, desligado no fim. Ele volta ao normal ao ser reiniciado.
- **Não conferido:** a linha tracejada da parede invisível e a visão de cima com o editor aberto (F2), e uma ilha publicada com paredes no jogo (F5).

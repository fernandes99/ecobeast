# 01. Altura do terreno

- **Status:** concluída
- **Depende de:** [README](README.md), [map-editor](../map-editor/), [islands](../islands/)

## Contexto

O hexágono tem `biome`, `shape` e `variant`, e a altura sai de `HexTile.level()` (`res://domain/models/hex_tile.gd`), a partir do bioma e da forma. O dono quer Colina e Montanha como biomas e a altura pintada à parte, em qualquer bioma. As decisões e o motivo de cada uma estão no [README](README.md).

Esta fase troca `shape` por `height` em todo lugar: no banco, no gerador, na API, no desenho do mapa, no tabuleiro de luta e no editor. Ao final, o mapa sorteado e as ilhas que já existem têm a mesma aparência de antes, e o editor pinta biomas e alturas separados.

## Escopo

- A coluna `height` em `island_tiles`, com as ilhas salvas convertidas, e o fim da coluna `shape`.
- O gerador devolvendo `biome` (7 biomas) e `height`.
- O bioma de encontro passando a ser o próprio bioma do hexágono.
- As rotas do mapa, das ilhas e do editor com `height` no lugar de `shape`.
- O desenho do mapa e do tabuleiro a partir de `biome` e `height`.
- No editor: os 7 biomas e a ferramenta Altura no lugar da Forma.

## Fora do escopo

Está no [README](README.md#fora-do-escopo): nenhuma regra de altura, nada de arte nova, nenhuma mudança na quantidade de montanhas e nada de altura na visão de cima.

## Requisitos

### O hexágono

- **RF-01:** todo hexágono que a API manda ou recebe tem `q`, `r`, `biome`, `height` e `variant`, e não tem mais `shape`. Isso vale para o mapa de `POST /v1/me/exploration`, para as ilhas (`/v1/islands`) e para o editor (`/v1/editor`).
- **RF-02:** `biome` é um dos 7 biomas de terreno: `temperate`, `boreal`, `stone`, `hill`, `mountain`, `wshallow` e `wdeep`. São os mesmos slugs da tabela `biomes`.
- **RF-03:** `height` é um inteiro de 0 a 4, aceito em qualquer bioma, inclusive na água.
- **RF-04:** `variant` vai de 1 a 3 nos biomas `hill` e `mountain`, e de 1 a 6 nos outros. A altura não muda a faixa da variante.

### As ilhas salvas

- **RF-05:** uma migration converte cada linha de `island_tiles`, do rascunho e da publicada, pela tabela abaixo, aplicada de cima para baixo (vale a primeira linha que bate). O bioma novo sai da forma e a altura sai da regra de `HexTile.level()`:

  | Antes | Bioma depois | Altura |
  | --- | --- | --- |
  | forma `mont`, qualquer bioma | `mountain` | 4 |
  | forma `hill`, bioma `stone` | `hill` | 3 |
  | forma `flat`, bioma `stone` | `stone` | 3 |
  | forma `hill`, outro bioma (água incluída) | `hill` | 2 |
  | forma `flat`, bioma `wshallow` ou `wdeep` | o mesmo | 0 |
  | forma `flat`, bioma `temperate` ou `boreal` | o mesmo | 1 |

- **RF-06:** depois da migration, `island_tiles` tem `height` com `CHECK` de 0 a 4 e `variant` com `CHECK` de 1 a 6, e não tem mais `shape` nem o `CHECK` dela. A faixa de 1 a 3 nos biomas `hill` e `mountain` é conferida pela rota, porque o `CHECK` não lê o slug do bioma.
- **RF-06b:** depois da migration, o `content_hash` de cada `island_maps`, do rascunho e da publicada, é recalculado pelo `draftHash` do formato novo. Uma ilha publicada e sem mudança continua aparecendo como "Publicada", e não como "Rascunho" com mudanças. Hoje o hash inclui `shape` (`canonicalDraft`), e o SQL não consegue refazer o `JSON.stringify` com sha-256. Por isso o recálculo é um script em TypeScript, rodado uma vez logo depois da migration.

### O gerador

- **RF-07:** `generateMap` continua decidindo a forma por dentro, como hoje, e converte cada hexágono no fim pela tabela da RF-05. Para uma mesma seed e os mesmos parâmetros, o mapa sai com as mesmas coordenadas, as mesmas variantes e a mesma aparência de antes. A única diferença é o paredão da colina de pedra (RF-13).
- **RF-07b:** a etapa de antes da conversão (bioma de 5 e forma) fica exportada para os testes. Os testes de hoje que conferem a forma (água funda só junto de água, pedra com plano, colina e montanha, montanhas nos 3 biomas de terra, ilhotas raras, a fração de pedra) continuam rodando sobre ela. Os testes novos da conversão rodam sobre o `generateMap`.
- **RF-08:** a chegada continua sendo o hexágono de terra plana mais perto do centro. Pelo formato novo, é um hexágono `temperate`, `boreal` ou `stone`.

### Encontros

- **RF-09:** o bioma de encontro de um hexágono é o `biome` dele, sem tradução. A altura não muda as taxas. Uma ilhota de colina no meio da água, que já contava como colina, agora é `hill` de verdade.
- **RF-10:** o sorteio dos Domadores NPC continua fugindo da água pelo `biome`. Uma ilhota de colina ou montanha deixa de ser água e pode receber um Domador. A mudança foi aceita.

### O desenho

- **RF-11:** `HexTile` tem `height: int` no lugar de `shape`, e a altura na tela é a de `height`, com os mesmos 0, 8, 16, 24 e 32 px de hoje.
- **RF-12:** a textura, as decorações, os arremates e o escorrido de um hexágono saem do `biome`. A Colina usa a arte que hoje é da forma `hill`, e a Montanha a da forma `mont`.
- **RF-13:** o paredão sai do bioma do hexágono de cima: `cliff.png` na Pedra e na Montanha, `side.png` nos outros, água incluída. A altura dele continua sendo a diferença entre os dois níveis, e a lateral da borda do mapa continua com 26 px a mais.
- **RF-14:** a água é reconhecida pelo bioma, e não pela altura 0. Em qualquer altura, ela recebe a espuma da terra vizinha e não tem arremate entre rasa e funda, como hoje no nível 0.
- **RF-15:** a luta aberta do mapa recebe `biome` e `height` do hexágono do Domador, e o chão do tabuleiro usa os dois.

### O editor

- **RF-16:** a ferramenta 2 passa a se chamar **Altura**, com a frase "Troca a altura dos hexágonos que já existem.". A frase de Pôr hexágono passa a ser "Cria hexágonos onde não há, com o bioma e a altura escolhidos abaixo.".
- **RF-17:** o bloco Bioma mostra os 7 biomas, nesta ordem: Planície, Boreal, Pedra, Colina, Montanha, Água rasa e Água profunda. Cada amostra aparece na altura 1.
- **RF-18:** o bloco Forma dá lugar ao bloco **Altura**, com 5 amostras, "Altura 0" a "Altura 4". Cada uma mostra o bioma escolhido naquela altura. Ao abrir o editor, a altura escolhida é 1.
- **RF-19:** pintar com a ferramenta Bioma troca só o bioma. A variante fica, a menos que passe do máximo do bioma novo. Nesse caso, ela é sorteada de novo de 1 a 3.
- **RF-20:** pintar com a ferramenta Altura troca só a altura. A variante não muda.
- **RF-21:** Pôr hexágono cria o hexágono com o bioma e a altura escolhidos por último. A variante é sorteada como hoje: nos biomas `hill` e `mountain`, de 1 a 3; nos outros, de 4 a 6 com a chance `detailChance`, e de 1 a 3 no resto.
- **RF-22:** a ilha nova do zero é toda de Planície na altura 1. A ilha nova pelo gerador chega no formato novo, pela RF-07.
- **RF-23:** a linha de baixo do editor, com o hexágono sob o ponteiro, mostra "(q, r)  ·  Bioma  ·  Altura N".
- **RF-24:** desfazer e refazer guardam o bioma, a altura, a variante e a área de cada hexágono.

## Critérios de aceite

- [x] Uma ilha salva antes da migration aparece igual depois dela, no editor e em Ilhas: as mesmas texturas, alturas, paredões e decorações. A exceção é o paredão de uma colina de pedra, que passa a usar `side.png` (RF-13).
- [x] Um mapa de Explorar zona tem a mesma cara de antes, inclusive as ilhotas na água e as montanhas. A exceção é a mesma das ilhas: a colina de pedra passa a usar `side.png`.
- [x] Logo depois da migration e do recálculo do hash, as ilhas publicadas e sem mudança aparecem como "Publicada" na lista do editor.
- [x] O teste do gerador confere, em vários mapas, que todo hexágono tem um bioma dos 7, altura de 0 a 4 e variante na faixa do bioma. Confere também que `mountain` está sempre na 4, `stone` na 3, `hill` na 2 ou na 3, a terra comum na 1 e a água na 0.
- [x] O teste dos encontros confere que o bioma de encontro é o próprio `biome`, em qualquer altura.
- [x] As rotas do editor recusam `height` fora de 0 a 4, bioma fora dos 7, variante 4 em `hill` ou `mountain` e o hexágono sem `height`.
- [x] No editor, há 7 biomas e 5 alturas, e uma Planície na altura 4, uma Montanha na altura 0 e uma Água rasa na altura 3, ao lado de uma Planície na altura 1, aparecem com o paredão certo (`side.png` sob a Planície e a água, `cliff.png` sob a Montanha).
- [x] A água na altura 3 tem espuma na divisa com a terra.
- [x] Pintar bioma não muda a altura, pintar altura não muda o bioma, e Ctrl+Z desfaz os dois.
- [x] Salvar, publicar e abrir a ilha em Ilhas mostra as alturas pintadas.
- [x] Uma luta aberta em cima de uma Colina mostra o chão de colina no tabuleiro.
- [x] `npm test` e `npm run test:e2e` passam no servidor.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

### Servidor

**Criar**

- `server/prisma/migrations/<data>_terrain_height/migration.sql`:
  1. adiciona `height`;
  2. preenche pela RF-05, lendo os ids de `hill` e `mountain` pelo slug em `biomes`;
  3. troca o `biome_id` das formas `hill` e `mont`;
  4. tira `shape` e os dois `CHECK` antigos;
  5. cria os `CHECK` da RF-06.

  Os `CHECK` são escritos à mão, como na migration `islands`.
- `server/scripts/recompute-island-hashes.ts` (ou o lugar onde o servidor já guarda scripts avulsos): lê cada `island_maps` pelo mesmo caminho do serviço do editor, calcula o `draftHash` e grava o `content_hash` (RF-06b). Ele pode ser rodado de novo sem mudar nada.

**Alterar**

- `server/prisma/schema.prisma`: `IslandTile` com `height Int` e sem `shape`, e o comentário do `biomeId` dizendo que são os 7 biomas.
- `server/src/domain/exploration/map-generator.ts`:
  - `BIOMES` passa a ter os 7 slugs, e um tipo separado guarda os 5 biomas que o gerador sorteia por dentro.
  - `TERRAIN_SHAPES` e `TerrainShape` deixam de ser exportados e ficam só dentro do arquivo.
  - Entra `MAX_HEIGHT = 4`.
  - `MapTile` passa a ter `{ q, r, biome, height, variant }`.
  - A conversão da RF-05 vira uma função deste arquivo, usada no fim de `generateMap`. `rollVariant` continua olhando a forma, o que dá a mesma faixa da RF-04.
  - A etapa de antes da conversão é exportada para os testes (RF-07b).
- `server/src/domain/exploration/spawns.ts`: `ENCOUNTER_BIOMES` é o mesmo `BIOMES`, e `encounterBiome` sai; quem a chamava usa `tile.biome`.
- `server/src/domain/tamers/tamers.ts`: troca `encounterBiome(tile)` por `tile.biome`.
- `server/src/domain/islands/island-draft.ts`: `DraftTile` com `height`; confere `height` e a variante pela RF-04.
- `server/src/exploration/exploration.dto.ts` e `server/src/editor/islands-editor.dto.ts`: `height` (`IsInt`, de 0 a 4) no lugar de `shape`, e `biome` entre os 7.
- `server/src/exploration/exploration.service.ts`, `server/src/islands/islands.service.ts` e `server/src/editor/islands-editor.service.ts`: leem e gravam `height`.
- Os testes que montam hexágonos com `shape` passam a usar `height`:
  - unitários: `map-generator.spec.ts`, `spawns.spec.ts`, `tamers.spec.ts`, `island-draft.spec.ts` e `area-spawns.spec.ts`;
  - e2e: `database`, `exploration`, `islands` e `islands-editor`.

### Jogo

**Alterar**

- `res://domain/models/hex_tile.gd`:
  - `height: int` no lugar de `shape`;
  - `is_water()`;
  - `from_dict` lê `height` e recusa o hexágono sem ele.

  `level()` sai, e quem o chamava usa `height`. `surface()` sai, porque a superfície passa a ser o próprio `biome` (veja o próximo item).
- `res://assets/terrain/surfaces/mont.png`: passa a se chamar `mountain.png`, com o `.import`, para o nome da textura ser o slug do bioma. As chaves `mont` viram `mountain` em `HexTransitions` (`SURFACE_ORDER`, `MATERIAL_ROWS`) e em `HexDecorations` (`RECIPES`). O `SURFACE_OF_BIOME` de `res://tools/content_viewer/content_files.gd` sai.
- `res://ui/components/hex_map_view.gd`:
  - o paredão escolhe a textura pelo bioma (RF-13), no lugar de `FACE_TEXTURES` por nível;
  - a altura em pixels continua em `LEVEL_HEIGHTS`, indexada por `height`.
- `res://ui/components/hex_transitions.gd`: usa `is_water()` onde hoje olha o nível 0 (RF-14).
- `res://screens/exploration/exploration_screen.gd`: manda `biome` e `height` para a luta e usa `height` nas camadas de cor das construções.
- `res://screens/board_battle/board_battle_screen.gd` e `board_view.gd`: `set_board(cells, biome, height)`, com a altura padrão 1.
- `res://tools/map_editor/`:
  - `island_draft.gd`: `BLANK_HEIGHT := 1`, `roll_variant(biome, ...)`, `add_tile(coord, biome, height, variant)`, e o estado do desfazer com a altura;
  - `editor_tools.gd`: `Tool.HEIGHT`, os 7 biomas e as 5 alturas;
  - `map_editor.gd`: a linha do hexágono sob o ponteiro;
  - `editor_canvas.gd` e `island_overview.gd`: `height` e `biome` no lugar de `level()` e `surface()`.

- `res://tools/map_editor/terrain_swatch.gd`: o paredão da amostra é escolhido pelo bioma, com a mesma regra do `HexMapView` (RF-13), porque hoje ele lê `HexMapView.FACE_TEXTURES[level]`, que sai.

**Reaproveitar**

- `TerrainSwatch`, que já desenha uma superfície numa altura (`set_terrain(surface, name, level)`), com o paredão trocado acima.
- As malhas, os arremates e o escorrido do `HexMapView`, que não mudam fora da escolha da textura.

### Documentos

Atualize o que fala de `shape` e de forma:

- `.specs/wild-battle/architecture.md`: o hexágono e a elevação;
- `.specs/map-editor/architecture.md`: `island_tiles`, o JSON e os pincéis;
- `.specs/islands/architecture.md`: o JSON;
- `.specs/biome-encounters/architecture.md`: a tradução da forma;
- `client/CLAUDE.md`, se citar a forma.

Nas specs concluídas, acrescente só uma linha apontando para esta.

## Verificação

```bash
cd server && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

Antes de aplicar a migration, tire capturas de uma ilha publicada e de um rascunho no editor. Depois, compare com as mesmas vistas.

Uma cena temporária em `res://zz_tmp_check/` monta um mapa à mão com cada bioma em cada altura e confere:

- a textura do paredão de cada um;
- a espuma da água alta;
- o `from_dict` recusando o hexágono sem `height`.

Depois, a pasta é apagada.

Passos no editor (F2):

1. Pintar os 7 biomas e as 5 alturas.
2. Pôr hexágono com bioma e altura escolhidos.
3. Desfazer e refazer.
4. Salvar, publicar e abrir a ilha em Ilhas.
5. Abrir uma luta em cima de uma Colina.

Passos em Explorar zona: andar por montanhas e ilhotas e conferir que o mapa tem a cara de antes.

## Tarefas

- [x] Capturas de antes; migration, `schema.prisma` e o script do `content_hash`.
- [x] Gerador, encontros, Domadores NPC e rascunho de ilha, com os testes unitários.
- [x] DTOs e serviços, com os e2e.
- [x] `HexTile`, renomear `mont.png`, `HexMapView`, `HexTransitions` e `HexDecorations`.
- [x] Tela de exploração e tabuleiro.
- [x] Editor: rascunho, ferramentas, linha do ponteiro, canvas e visão de cima.
- [x] Verificação; atualizar os documentos; marcar esta spec, o README da iniciativa, o `.specs/README.md`, o `roadmap.md` e o escopo do `CLAUDE.md` como `concluída`.

## Decisões da implementação

- **Os tipos da forma continuam exportados:** `TERRAIN_SHAPES`, `TerrainShape`, `SHAPED_BIOMES` e `generateShapedMap` saem do `map-generator.ts`, porque os testes da etapa de dentro (RF-07b) precisam deles. Nenhum outro arquivo do servidor os usa.
- **Hexágono que ainda manda `shape`:** a `ValidationPipe` não recusa campos a mais, e ligar isso valeria para todas as rotas. O que a rota recusa é o hexágono sem `height`, que é o caso de um cliente antigo. O critério foi ajustado.
- **Capturas de antes trocadas por uma comparação de dados:** antes da migration, as tabelas das ilhas foram copiadas para um JSON. Depois dela, um script comparou os 7.573 hexágonos: bioma e altura novos contra os de `surface()` e `level()` de antes, mais variante e área. Nenhum ficou diferente. As ilhas tinham `hill` em Planície, Boreal e água, e `mont` em Boreal, e nenhuma colina de pedra. Então nenhum paredão delas mudou.
- **Decorações:** elas usam a mesma seed e a mesma receita (a chave `mont` virou `mountain`), então saem iguais. A exceção prevista no README não aconteceu.
- **`content_hash`:** o script fica em `server/prisma/recompute-island-hashes.ts`, ao lado do seed, e roda com `npx tsx prisma/recompute-island-hashes.ts`. Ele recalculou as 3 versões, e a ilha publicada continuou com rascunho e publicada iguais. Rodado de novo, não mudou nada.
- **Migration à mão:** o `prisma migrate dev` não roda sem terminal interativo e recusou a coluna nova sem valor padrão. A migration `20261111220000_terrain_height` foi escrita à mão e aplicada com `prisma migrate deploy`. Depois, o `prisma migrate diff` não mostrou diferença entre o banco e o `schema.prisma`.
- **A Pedra continua com 6 variantes**, como os outros biomas fora da Colina e da Montanha. A `max_variant` do editor e a `maxVariant` do servidor usam a mesma regra.

## Verificação feita

Em 2026-11-11:

- **Servidor:**
  - `npm run lint` e `npm run typecheck` sem erro;
  - `npm test` com 757 testes passando, entre eles os da conversão (`terrainOf`), os do `generateMap` (biomas, alturas, variantes e chegada) e os da etapa de dentro;
  - os e2e tocados (`database`, `exploration`, `islands` e `islands-editor`) com 96 testes passando, e depois a suíte inteira, com 18 arquivos e 467 testes passando.
- **Banco:**
  - os 7.573 hexágonos das ilhas convertidos sem nenhuma diferença;
  - o hash das 3 versões recalculado.
- **Jogo:**
  - `godot --headless --path client --editor --quit` reimportou a `mountain.png`;
  - `godot --headless -d --path client --quit-after 60` mostrou só os avisos de antes.
- **Cena temporária** (já apagada): 50 conferências passaram.
  - Os 15 scripts tocados compilam.
  - O `from_dict` recusa o hexágono sem `height` e com `height` 5, e aceita a água na altura 3.
  - Os 7 biomas têm textura e o paredão certo.
  - As 13 combinações de antes dão a mesma superfície, altura e paredão, menos a colina de pedra.
  - A água na altura 3 recebe espuma.
  - A Montanha na altura 4 sobe.
  - A ilha nova fica toda na altura 1, e o `to_dict` tem `height` sem `shape`.
  - Pintar bioma troca só o bioma e corrige a variante, e pintar altura troca só a altura.
  - Pôr hexágono usa o bioma e a altura escolhidos, e o desfazer guarda a altura.
  - O tabuleiro aceita bioma e altura.
- **Captura de tela,** aberta e revisada: aparecem a Planície na altura 3 com um lago em cima, a Montanha na altura 0 afundada na grama, os 7 biomas nas alturas 2 e 4, com paredão de rocha só na Pedra e na Montanha, e as amostras de altura.

**Falta do dono:**

1. No F2, pintar os biomas e as alturas e conferir o painel.
2. Abrir a ilha publicada em Ilhas.
3. Andar num mapa de Explorar zona.
4. Abrir uma luta em cima de uma Colina.

Nenhum celular foi testado.

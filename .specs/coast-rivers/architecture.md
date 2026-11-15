# coast-rivers: desenho

## O gerador

`server/src/domain/exploration/map-generator.ts`, na ordem:

1. **A região** (`growRegion`), como hoje.
2. **Os campos**, como hoje (altitude, umidade, temperatura, pedra e crista), e um sorteio à parte para o mar e a água (`WATER_SALT`), para os outros ruídos da seed não mudarem.
3. **O mar** (fase 1). Um ângulo da seed escolhe o lado. A borda do mapa que olha até 60° para esse lado é a fonte do mar. Cada hexágono tem uma nota: a distância, em hexágonos, até essa borda, mais um ruído de costa vezes `coastRoughness` vezes a maior distância. O mar cresce a partir da fonte, sempre pelo vizinho de menor nota, até ter `seaFraction` dos hexágonos. Crescer pelos vizinhos, e não cortar por uma reta, importa: o recorte padrão do mapa tem lóbulos ligados por estreitos, e uma reta deixava o mar num lóbulo que só encostava na terra por um hexágono. A água a até `shallowWidth` hexágonos da terra é rasa (`wshallow`), e o resto é fundo (`wdeep`). Uma terra cercada pelo mar fica como ilha, com a Praia dela.
4. **A altura de escoar** (fase 2). Cada hexágono de terra ganha `drain = 0,5 · altitude + 0,5 · min(distância até o mar / 20, 1)`. A altitude cai em direção ao mar.
5. **Os lagos** (fases 2 e 4). `lakeCount` lagos, redondos: cada um é o disco dos hexágonos a até metade de uma largura sorteada entre `lakeMinWidth` e `lakeMaxWidth` (no mínimo 6) do centro, com a borda recortada por um ruído só para fora. O centro é o de menor `drain` entre alguns hexágonos sorteados onde o disco inteiro cabe, longe do mar, de outro lago e da borda. O lago que partiria a terra é sorteado de novo. Num lago de 12 hexágonos ou mais, a água sem terra vizinha é funda.
6. **O enchimento** (fase 2). Um Priority-Flood a partir do mar e dos lagos dá a cada hexágono de terra o nível de saída (`spill`): o menor nível que leva até uma saída sem subir. Nos empates, a distância até a saída desempata, então todo hexágono tem um vizinho por onde descer.
7. **Os rios** (fases 2 e 3). `riverCount` rios. Cada um, com a chance `throughRiverChance`, é um rio que atravessa e nasce num hexágono da borda do mapa, do lado oposto ao mar (fase 3). Os outros nascem dentro da terra, num hexágono entre os 20% de `drain` mais alto, longe de outra água; com a chance `springLakeChance`, a nascente é um lago pequeno, de 2 a 5 hexágonos. O rio desce pelo vizinho de menor `spill` (depois de menor `drain`) até encostar no mar, num lago ou em outro rio, e cada hexágono dele vira `wshallow`, plano.
8. **A Praia** (fases 1 e 4). A terra a até `beachMinWidth`–`beachMaxWidth` hexágonos do mar (a largura vem de um ruído ao longo da costa) vira `beach`, menos a de forma `mont` e a que encosta num rio: o rio chega ao mar pela terra dele, sem a faixa de areia.
9. **As formas, as montanhas e a limpeza**, como hoje, menos as ilhotas: a água fica sempre plana, e o `islandChance` saiu.
10. **As travessias** (fase 3). Ao longo de cada rio que atravessa, a cada `crossingSpacing` hexágonos (no mínimo 1), um hexágono de rio com terra dos dois lados opostos ganha uma travessia: com a chance `fordShare`, o hexágono vira `wford`; senão, uma ponte de madeira liga o centro das duas margens. Depois, uma busca a partir da chegada (terra, vau e pontes) confere a terra que ficou de fora. Cada pedaço de 3 hexágonos ou mais encostado num rio ganha mais uma travessia, até não sobrar nenhum.
11. **A chegada**, como hoje.

**A largura do rio** (fase 4). O rio desce como uma linha do meio (`path`) e depois ganha largura (`widen`): ela vai de `riverMinWidth` na nascente a `riverMaxWidth` na foz (o rio que vem da borda já começa no meio do caminho). Em volta de cada hexágono da linha entram os vizinhos até metade da largura, e numa largura par entra mais o vizinho mais baixo. O mar e os lagos não entram.

**A linha da travessia** (fase 4). Num rio largo, a travessia é uma linha reta num dos 3 eixos do hexágono, de margem a margem, só por hexágonos de rio, com no máximo 6 hexágonos (`spansAt`, a mais curta). A ponte vai do centro de uma margem ao da outra; o vau põe `wford` em todos os hexágonos da linha.

`GeneratedMap` e `ShapedMap` ganham `bridges: { type, points, width }[]`, no formato de `MapBridgeDto`, com os pontos em pixels do chão plano a partir do centro do hexágono (0, 0), pela mesma conta de `HexMapView.flat_center`.

## Os parâmetros

`MapConfig` perde `waterFraction`, `deepFraction` e `islandChance` e ganha (no editor, em `snake_case`):

| Campo | Padrão | Faixa | Fase |
| --- | --- | --- | --- |
| `seaFraction` | 0,3 | 0 a 0,8 | 1 |
| `coastRoughness` | 0,25 | 0 a 1 | 1 |
| `shallowWidth` | 2 | 1 a 6, inteiro | 1 |
| `beachMinWidth` | 2 | 1 a 8, inteiro | 4 |
| `beachMaxWidth` | 4 | 1 a 8, inteiro | 4 |
| `lakeCount` | 4 | 0 a 20, inteiro | 2 |
| `lakeMinWidth` | 6 | 6 a 40, inteiro | 4 |
| `lakeMaxWidth` | 12 | 6 a 40, inteiro | 4 |
| `riverCount` | 5 | 0 a 20, inteiro | 2 |
| `riverMinWidth` | 2 | 1 a 6, inteiro | 4 |
| `riverMaxWidth` | 4 | 1 a 6, inteiro | 4 |
| `springLakeChance` | 0,35 | 0 a 1 | 2 |
| `throughRiverChance` | 0,3 | 0 a 1 | 3 |
| `crossingSpacing` | 14 | 4 a 60, inteiro | 3 |
| `fordShare` | 0,5 | 0 a 1 | 3 |

Com 5 rios e a chance de 0,3, um mapa tem em média 1,5 rio que atravessa, e 17% dos mapas não têm nenhum.

## O catálogo

| id | slug | name | description |
| --- | --- | --- | --- |
| 10 | `beach` | Praia | Areia clara na beira do mar, com conchas e o vento salgado. |
| 11 | `wford` | Vau | Água rasa sobre o cascalho, onde dá pé para atravessar. |

## O vau no jogo

- `HexTile.WATER_BIOMES` ganha `wford`, então o desenho o trata como água (sem paredão, sem decoração). `HexTile.is_ford()` e `HexTile.blocks()` (água que não é vau) separam o andar.
- `ExplorationMap.is_clear`, o `path_to_any` e o editor usam `blocks()` no lugar de `is_water()` onde a pergunta é se dá para andar.
- `HexMapView._add_surface`, para o `wford`, desenha primeiro o cascalho (`grounds/gravel_trail.png`, escurecido a 0,82) e por cima a água rasa a 45% (`FORD_WATER_ALPHA`), com o mesmo ondular do `code 4`.
- No servidor, `isWater` continua valendo para o `wford` (a chegada e os NPC não ficam nele), e `blocksWalking` (água que não é vau) é o que a busca de travessias usa.

## A arte da Praia

`assets/terrain/make_beach.py`, como o `make_desert_snow.py`:

- `surfaces/beach.png`: a textura da Colina recolorida para uma areia mais clara e fria que a do Deserto, com pontinhos de concha.
- Linha 8 de `transitions.png` (a Praia vem antes do Deserto na ordem: a areia da praia fica por baixo da grama) e linha 5 de `drips.png`.
- Linhas 47 a 50 de `decorations.png`: `shells`, `starfish`, `driftwood` e `beach_rock`, com 4 variantes cada, que também viram os tipos de peça 91 a 94.
- Receita da Praia: `driftwood` 0,08 (1), `beach_rock` 0,1 (1), `dune_grass` 0,3 (1 a 2), `shells` 0,3 (1 a 2), `starfish` 0,08 (1).

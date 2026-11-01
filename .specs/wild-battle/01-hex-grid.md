# 01. Sprites e grade hexagonal

- **Status:** rascunho
- **Depende de:** [battle-screen](../battle-screen/)

## Contexto

Esta fase valida o que todo o resto usa: os sprites no jogo e o encaixe da grade. Nada muda para o jogador ainda. O mapa é montado à mão, com todos os sprites, e o desenho é conferido em vários tamanhos de tela. Geometria, coordenadas e o cálculo dos pixels estão em [architecture.md](architecture.md).

## Escopo

- Os 108 sprites em `res://assets/terrain/`.
- Os modelos do mapa.
- O nó que desenha o mapa.

## Fora do escopo

- O gerador e a rota ([02](02-map-generator.md)).
- A tela, o andar e qualquer mudança no Hub ([03](03-exploration-screen.md)).

## Requisitos

**Sprites**

- **RF-01:** Os 108 PNGs ficam em `res://assets/terrain/`, com os nomes de [architecture.md](architecture.md#sprites) e o conteúdo sem alteração.

**Modelos**

- **RF-02:** `HexTile` guarda `coord: Vector2i`, `biome`, `shape` e `variant`, e monta o caminho do sprite.
- **RF-03:** `ExplorationMap` guarda `seed`, `start` e os tiles por coordenada, sem repetir posição.
- **RF-04:** `ExplorationMap` responde `has(coord)`, `tile_at(coord)` e `neighbors(coord)`, que devolve as seis posições vizinhas que pertencem ao mapa.
- **RF-05:** `ExplorationMap.from_dict` lê o JSON de [architecture.md](architecture.md#contrato). Um tile sem coordenada, bioma ou forma é ignorado, sem derrubar o jogo.

**Desenho**

- **RF-06:** `HexMapView` desenha cada tile no ponto de [architecture.md](architecture.md#coordenadas), usando os passos de 32 e 21 px.
- **RF-07:** Os tiles são desenhados de cima para baixo, para quem está mais abaixo cobrir a lateral de quem está acima.
- **RF-08:** `HexMapView` usa filtro `NEAREST`.
- **RF-09:** `HexMapView` se escala por um número inteiro de pixels reais, recalculado quando a janela muda.
- **RF-10:** `surface_center(coord)` devolve o centro da superfície de um hexágono, para a câmera e o toque da [03](03-exploration-screen.md).
- **RF-11:** Um sprite que não existe gera `push_error` e não derruba o jogo.

## Critérios de aceite

- [ ] Os 108 arquivos existem em `res://assets/terrain/` e carregam.
- [ ] Cada PNG copiado é idêntico byte a byte ao original.
- [ ] `tile_at` acha um tile existente e devolve `null` fora do mapa.
- [ ] `neighbors` devolve 6 posições no meio do mapa e menos na borda.
- [ ] Um tile repetido no JSON não cria uma segunda posição.
- [ ] Um mapa com todos os sprites é desenhado sem emendas, sobreposições erradas nem fundo aparecendo entre as superfícies.
- [ ] Um terreno alto cobre o tile de cima, e o tile de baixo cobre a lateral dele.
- [ ] Em 405×720, 720×1280 e 1080×1920, cada pixel da arte ocupa um bloco inteiro e igual de pixels reais, conferido por comparação com a arte ampliada.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/assets/terrain/`: os sprites, com os arquivos `.import` que o Godot cria.
- `client/domain/models/hex_tile.gd` e `client/domain/models/exploration_map.gd`.
- `client/ui/components/hex_map_view.gd`: `class_name HexMapView`, `extends Node2D`. Desenha tudo em `_draw`, com `set_map(map: ExplorationMap)`, `surface_center(coord: Vector2i) -> Vector2` e `pixel_scale() -> float`.

`_draw` é a função em que um nó do Godot desenha a si mesmo. Um único nó desenhando 300 tiles é mais simples de ordenar do que 300 nós, e dá a ordem exata de RF-07. As texturas são guardadas por caminho, para cada arquivo carregar uma vez só.

**Alterar**

- `client/CLAUDE.md`: `assets/terrain/` na lista de ilustrações.

**Reaproveitar**

`DictFields` em `from_dict`.

## Verificação

Uma cena temporária monta um mapa à mão com todos os sprites, numa ordem que coloca terrenos altos ao lado dos planos, e salva capturas nos três tamanhos. Ela compara cada captura com a arte ampliada e confere os modelos. As capturas são todas abertas e revisadas.

```bash
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [ ] Verificação temporária; ver falhar.
- [ ] Copiar e renomear os sprites (RF-01).
- [ ] Modelos (RF-02 a RF-05).
- [ ] `HexMapView` (RF-06 a RF-11).
- [ ] Remover os arquivos temporários; marcar esta spec e a tabela do README como `concluída`; commit `feat: grade hexagonal do mapa`.

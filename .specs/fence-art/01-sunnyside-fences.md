# 01. A cerca e o muro do Sunnyside

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-fences/01](../free-fences/01-wall-records.md)

## Contexto

O dono quer cercas mais bonitas e escolheu a arte do pacote Sunnyside World ([README](README.md#contexto)).

## Escopo

- O script `client/assets/walls/make_walls.py`, que recorta a folha do pacote.
- A folha nova de `wood_fence` e `stone_fence`.
- O `HexWalls` e o `HexMapView._add_wall_mesh` com a travessa vista de cima.
- A saída das paredes do `make_town.gd`.

## Requisitos

- **RF-01:** `python -I make_walls.py <spr_tileset_sunnysideworld_16px.png> <pasta de saída>` grava `wood_fence.png` e `stone_fence.png`, sem mudar os pixels do pacote, menos a travessa vista de cima do muro. Cada folha tem 3 células de 96×72 (`HexWalls.CELL_SIZE`), com o pé em (48, 43) (`CELL_FOOT`):

  | Célula | O que é | Onde fica |
  | --- | --- | --- |
  | 0 | O poste (madeira) ou o pilar (pedra) | o pé do poste no pé da célula |
  | 1 | A travessa deitada entre dois postes, nas colunas 0 a 15 (`RAIL_SPAN`): a coluna 0 é o meio de um poste e a 16 seria o do seguinte | a linha do chão da travessa na linha do pé |
  | 2 | A travessa vista de cima, nas linhas 0 em diante, centrada na coluna 48 | — |

  Recortes do pacote (x, y na folha de 1024 px):
  - madeira: o poste e a travessa da peça de (613, 0), 27×11, com o pé na linha 9 dela; a travessa de cima é a do pacote, 4 px (`#9a5a43`, `#e2b78a`, `#e2b78a`, `#9a5a43`), 1 linha que se repete;
  - pedra: o pilar e o muro da fileira de pilares de (720, 48), unidade de 16 px, pilar nas colunas 4 a 11, com o pé na linha 14; a travessa de cima tem 8 px e 8 linhas: 7 de `abccccba` e uma junta `aaaaaaaa` (`a` `#5a6988`, `b` `#8b9bb4`, `c` `#c0cbdc`).
- **RF-02:** O `HexWalls` parte cada trecho assim:
  - **Deitado** (até 60°, `|dy| <= |dx| * STEEP_SLOPE`, com `STEEP_SLOPE` 1,73): uma fatia de 1 px de largura da célula 1 a cada passo de 1 px no eixo que mais anda; a coluna é a posição da fatia entre os dois postes vizinhos, de 0 a 15. Postes a espaços iguais, de cerca de 16 px (`POST_GAP`).
  - **Em pé** (acima de 60°): uma linha de 1 px de altura da célula 2 a cada passo de 1 px na vertical, centrada no ponto da linha, na altura do chão; a linha da célula é o passo dividido pela quantidade de linhas da travessa de cima do tipo. Postes a espaços iguais, de cerca de 16 px na madeira e 24 px na pedra (`STEEP_POST_GAP`, por tipo).
  - Um poste em cada ponto clicado, como antes.
- **RF-03:** As linhas da travessa de cima são desenhadas por baixo do poste que as cobre: na mesma faixa, a ordem é pelo pé, com o poste por cima no mesmo ponto, como as fatias.
- **RF-04:** O `make_town.gd` não gera mais as paredes; a arte delas sai só do `make_walls.py`. Os créditos do pacote ficam em `client/assets/walls/CREDITOS.md`.

## Critérios de aceite

- [ ] No jogo e no editor, a cerca de madeira tem postes de topo redondo e uma travessa, e o muro tem pilares, em qualquer ângulo.
- [ ] Um trecho quase em pé mostra a travessa vista de cima ligando os postes, sem faixa grossa nem fio.
- [ ] O Domador continua parando na cerca, e a cerca fica na frente ou atrás dele pela posição.
- [ ] `godot --headless --path client --quit-after 30` roda sem erro de script.

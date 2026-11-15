# 02. A cerca de estacas

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [fence-art/01](../fence-art/01-sunnyside-fences.md)

## Contexto

O dono quer mais uma cerca, com a arte do pacote Main Characters Home ([README](README.md#contexto)).

## Escopo

- O `make_walls.py` com a segunda folha e a arte `client/assets/walls/picket_fence.png`.
- O tipo de parede 4 na migração `20261216000000_home_pack` e na carga inicial.
- O `HexWalls` e o `HexMapView._add_wall_mesh` com o espaço entre postes e a subida da travessa de cima por tipo.

## Requisitos

- **RF-01:** `python -I make_walls.py <spr_tileset_sunnysideworld_16px.png> <exterior.png> <pasta de saída>` grava as 3 folhas. A de `picket_fence` sai de `exterior.png`, sem mudar os pixels, no formato de 3 células da [fence-art/01](../fence-art/01-sunnyside-fences.md):
  - poste: a estaca de (177, 16), 7×16, com o pé em (3, 14); saem os 2 pixels da travessa de cada lado dela, em (177, 22 a 24) e (183, 22 a 24);
  - travessa deitada: a coluna 184 entre duas estacas, repetida nas 8 primeiras colunas da célula 1;
  - travessa vista de cima: o trecho em pé de (169, 25), 7×8, que tem uma estaca vista de cima entre as duas travessas.
- **RF-02:** O tipo de parede 4 é `picket_fence`, "Cerca de estacas", visível.
- **RF-03:** O `HexWalls` usa, por tipo:
  - deitado: postes a cada 8 px (`FLAT_GAP`), e a coluna da travessa vai de 0 até o espaço menos 1;
  - em pé (acima de 60°): só o poste do começo de cada trecho e o do fim, e a travessa vista de cima com 7 px, 8 linhas que se repetem e 8 px acima do chão (`STEEP.lift`, `HexWalls.top_lift`), na altura da travessa deitada.
  A madeira e o muro não mudam.

## Critérios de aceite

- [ ] A ferramenta Cerca do editor tem a Cerca de estacas.
- [ ] Deitada ou torta, a cerca tem as estacas em pé ligadas pela travessa; quase em pé, o trecho do pacote liga as pontas, sem degrau na travessa.
- [ ] O Domador para na cerca.
- [ ] `godot --headless --path client --quit-after 60` roda sem erro de script.

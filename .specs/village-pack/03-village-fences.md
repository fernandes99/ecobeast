# 03. As cercas da vila

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [fence-art/01](../fence-art/01-sunnyside-fences.md), [home-pack/02](../home-pack/02-picket-fence.md)

## Contexto

O dono pediu também as cercas do tileset Village ([README](README.md#contexto)): a cerca de madeira (postes com duas travessas) e o muro de pedra (blocos claros com topo de pedra), cada uma em peças de 16 px deitadas e em pé.

## Escopo

- O `make_walls.py` com a terceira folha e a arte `client/assets/walls/village_fence.png` e `village_wall.png`.
- Os tipos de parede 5 e 6 na migração `20270111000002_village_fences`.
- O `HexWalls` com o espaço entre postes e a travessa vista de cima dos dois tipos, se precisar.

## Requisitos

- **RF-01:** `python -I make_walls.py <spr_tileset_sunnysideworld_16px.png> <exterior.png> <FDR_Village.png> <pasta de saída>` grava as 5 folhas; as 3 de antes saem iguais, byte a byte. As novas saem do `FDR_Village.png`, sem mudar os pixels, no formato de 3 células da [fence-art/01](../fence-art/01-sunnyside-fences.md):
  - cerca: o poste de (117, 161), 6×16, com o pé em (3, 15); a travessa deitada das colunas 123 a 132 entre dois postes (a 16 px um do outro, como no pacote); e, vista de cima, a fileira em pé do pacote de (117, 177), 6×16, que já tem um poste a cada 16 linhas;
  - muro: a face de (128, 210), 16×12, com o pé na linha 11, repetida inteira (dois tijolos); o poste é uma coluna vazia, porque o muro do pacote não tem pilar; e, vista de cima, a lateral do pacote de (117, 226), 6×8.
- **RF-02:** O tipo de parede 5 é `village_fence`, "Cerca da vila", e o 6 é `village_wall`, "Muro da vila", os dois visíveis.
- **RF-03:** O `HexWalls.STEEP` ganha, acima de 60°: a cerca com só os postes das pontas, 6 px de largura, 16 linhas e sem subida; o muro com só as pontas, 6 px, 8 linhas e 12 px de subida, para a lateral sair do topo do muro deitado na quina, como no pacote. Os dois têm postes a cada 16 px deitados (o padrão). As paredes de antes não mudam.

## Critérios de aceite

- [ ] A ferramenta Cerca do editor tem a Cerca da vila e o Muro da vila.
- [ ] Deitadas, tortas ou quase em pé, as duas ficam inteiras, sem buraco nem degrau.
- [ ] O Domador para nelas.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script, e os testes do servidor passam.

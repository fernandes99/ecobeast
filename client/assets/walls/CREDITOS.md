# Créditos

A cerca de madeira e o muro de pedra vêm do **Sunnyside World Asset Pack V2.1** (Daniel Diggle), comprado pelo dono e usado pela licença do pacote. O `make_walls.py` recorta a folha `Tileset/spr_tileset_sunnysideworld_16px.png` sem mudar os pixels: só separa o poste e a travessa de cada parede. A travessa vista de cima do muro é montada com as cores do pacote (fence-art/01).

A cerca de estacas vem do **Main Characters Home Free Top-Down Pixel Art Asset** da craftpix.net, pela licença dela (https://craftpix.net/file-licenses/): o `make_walls.py` recorta a estaca, a travessa e o trecho em pé da folha `PNG/exterior.png` sem mudar os pixels (home-pack/02).

A cerca da vila e o muro da vila vêm do tileset **Village** (`FDR_Village.png`) do pacote **Fantasy Dreamland Reborn**, da ElvGames, pela licença do pacote (o dono confirma a licença): o `make_walls.py` recorta o poste, a travessa e o trecho em pé da cerca e a face e a lateral do muro sem mudar os pixels; o poste do muro fica vazio, porque o muro do pacote não tem pilar (village-pack/03).

Para refazer: `python -I make_walls.py <spr_tileset_sunnysideworld_16px.png> <exterior.png> <FDR_Village.png> .`, de dentro desta pasta.

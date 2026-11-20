# 02. Sem o Vau

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [coast-rivers/03](../coast-rivers/03-crossings.md)

## Contexto

O dono decidiu tirar o Vau ("Tirar, só pontes"). Ele saía em poucos hexágonos por mapa, nenhuma ilha usa e só o Tidebud (taxa 20) e o Kelpcoil (taxa 8) nasciam nele. Os dois também nascem na água rasa.

## Escopo

- **Servidor:**
  - `wford` sai de `BIOMES` e de `SHAPED_BIOMES`.
  - `fordShare` sai do `MapConfig`.
  - As travessias do `placeCrossings` são só pontes.
- **Banco:** a migração `20270117000000_remove_ford` apaga as linhas do bioma 11 em `species_biomes`, `species_biome_zones` e `biome_zones`, e a linha 11 de `biomes`. Um hexágono de ilha com o Vau viraria água rasa, mas nenhuma ilha o usava. Também saem as linhas dele no `seed-data` (`biomes.json` e `biome_zones.json`), para os e2e que comparam o seed com o banco.
- **Cliente:**
  - `HexTile.FORD` e o `_add_ford` do `hex_map_view.gd` saem.
  - Sai a cor do Vau no `minimap_palette.gd`.
  - O Vau sai da lista do editor (`editor_tools.gd`) e o `ford_share` sai do `new_island_panel.gd`.
  - Sai a amostra `surfaces/wford.png` e quem a gera no `make_beach.py`.

## Requisitos

- **RF-01:** Cada travessia é a linha reta mais curta de margem a margem cujas margens aceitam ponte (`canBridge`: mesma altura e nenhuma Montanha).
  - Quando nenhuma linha perto do ponto aceita, a travessia vai para o próximo trecho do rio.
  - Se uma terra só se liga à chegada por margens de alturas diferentes, as duas margens da linha mais curta viram terra plana, fora da Montanha, e ganham a ponte.
- **RF-02:** Toda terra de 3 hexágonos ou mais encostada num rio continua chegando à chegada, por terra ou ponte.

## Critérios de aceite

- [x] Nenhum mapa tem `wford`, e o `GET /v1/catalog` não lista o bioma 11.
- [x] O teste de alcance da coast-rivers/03 passa só com pontes.
- [x] O jogo sem janela abre sem erro (`--quit-after 240`).

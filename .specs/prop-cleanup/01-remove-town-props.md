# 01. As peças da cidade que saem

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [editor-ui/01](../editor-ui/01-prop-categories.md)

## Escopo

| id | slug | Nome | Arte de |
| --- | --- | --- | --- |
| 18 | `lamp_post` | Poste de luz | `make_town.gd` |
| 19 | `sign` | Placa | `make_town.gd` |
| 23 | `shop_building` | Prédio da Loja | `make_town.gd` |
| 24 | `town_house` | Casa (cidade) | `make_town.gd` |
| 25 | `town_house_medium` | Casa média (cidade) | `make_town.gd` |
| 26 | `town_house_large` | Casa grande (cidade) | `make_town.gd` |
| 27 | `observatory` | Observatório | imagem do dono ([town-art/06](../town-art/06-observatory.md)) |

## Requisitos

- **RF-01:** A migração `20270112000001_remove_town_props` apaga as peças desses tipos em todas as ilhas (em Liora, 12 Postes de luz e 2 Placas, no rascunho e na publicada) e depois os tipos. As linhas de bloqueio e as luzes deles saem pela cascata. Depois dela, o `recompute-island-hashes.ts` refaz a versão das ilhas mexidas.
- **RF-02:** A carga inicial (`seed-data/prop_types.json`, `prop_type_blocks.json` e `prop_type_lights.json`) perde as linhas dos 7 tipos.
- **RF-03:** As pastas `client/assets/props/<slug>/` dos 7 tipos saem do repositório.
- **RF-04:** O `make_town.gd` só desenha o canteiro e o banco, que saem iguais byte a byte; as funções e as cores que só os tipos apagados usavam saem.
- **RF-05:** O `find_lights.py` não lista os tipos apagados; o `LAMPS` e o `SKIP_ABOVE` ficam vazios, prontos para uma peça nova.
- **RF-06:** O carimbo "Refugio Temp" (`tools/map_editor/stamps/refugio_temp.json`) perde o Poste de luz que tinha; um carimbo com um tipo que não existe não poderia ser posto.
- **RF-07:** O teste e2e das ilhas usa a Casa grande (`big_house`) no lugar da Casa (cidade).

## Critérios de aceite

- [ ] A ferramenta Peças do F2 não mostra mais as 7 peças.
- [ ] Liora abre no jogo sem os postes e as placas, sem erro.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script, e os testes do servidor passam.

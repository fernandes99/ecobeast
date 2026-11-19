# 02. As plantas por zona

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-zone-records](01-zone-records.md), [nature-variety](../nature-variety/)

## Contexto

Depois da fase 01, o mapa sorteado manda a zona de cada hexágono, mas o cliente ainda desenha a receita do bioma. Aqui cada zona ganha a sua receita.

## Escopo

- `HexTile.zone` e as receitas das zonas em `HexDecorations`.
- O tabuleiro da luta com as plantas da zona do hexágono onde a luta começou.
- A aba Biomas do F1 mostrando as zonas.

## Fora do escopo

- Arte nova.
- Os vagalumes por zona: `SWARM_CHANCE` continua por bioma.

## Requisitos

- **RF-01:** `HexTile` ganha `zone: String` (vazio na Comum), lido de `zone` no `from_dict`.
- **RF-02:** `HexDecorations.decorations_of` usa a receita de `tile.zone` quando ela não é vazia e a do `tile.biome` quando é. Uma zona sem receita no cliente usa a do bioma e avisa uma vez com `push_warning`. A receita de cada Comum é a de hoje, sem mudar uma vírgula, para o sorteio de hoje continuar igual.
- **RF-03:** As receitas novas, no formato de `RECIPES` (tipo, chance, mínimo, máximo), da maior para a menor (_a revisar_):

| Zona | Receita |
| --- | --- |
| `temperate_woods` | oak 0.5 1–2, tree 0.5 1–2, birch 0.4 1–2, bush 0.2 1–1, log 0.1 1–1, stump 0.08 1–1, fallen_branch 0.2 1–1, mushrooms 0.2 1–2, tuft 0.4 1–3 |
| `temperate_shrubland` | bush 0.8 2–4, berry_bush 0.2 1–1, pebbles 0.1 1–1, flowers 0.1 1–1, tall_grass 0.3 1–2, tuft 0.5 1–3 |
| `temperate_clearing` | tuft 0.35 1–2, clover 0.15 1–1 |
| `temperate_meadow` | flowers 0.8 2–4, wildflowers 0.7 1–3, yellow_flowers 0.4 1–2, tall_grass 0.2 1–1, clover 0.3 1–2, tuft 0.5 1–3 |
| `boreal_clearing` | pebbles 0.1 1–1, fern 0.3 1–2, mushrooms 0.1 1–1 |
| `boreal_ferns` | pine 0.15 1–1, mossy_rock 0.15 1–1, dark_bush 0.3 1–2, fern 0.9 3–5, mushrooms 0.25 1–2 |
| `hill_scree` | rock 0.5 1–2, brown_rock 0.2 1–1, pebbles 0.6 1–3, dry_tuft 0.2 1–2 |
| `hill_dry_brush` | dry_shrub 0.8 2–3, thistle 0.4 1–2, dry_branch 0.2 1–1, dry_tuft 0.6 2–4 |
| `stone_crags` | spire 0.5 1–2, boulder 0.5 1–2, rock_pile 0.3 1–1, lichen_rock 0.2 1–1 |
| `desert_dunes` | pebbles 0.05 1–1, dune_grass 0.15 1–1 |
| `desert_cacti` | cactus 0.8 2–3, sand_rock 0.1 1–1, desert_flower 0.3 1–2, dry_tuft 0.2 1–2 |
| `snow_field` | ice_shards 0.05 1–1, snow_tuft 0.15 1–1 |
| `snow_pines` | snow_pine 0.9 2–4, snow_bush 0.15 1–1, snow_log 0.1 1–1, frozen_branch 0.15 1–1 |

- **RF-04:** O tabuleiro da luta recebe a zona junto com o bioma (`params.zone`, vazia na Comum) e desenha as plantas dela.
- **RF-05:** A aba Biomas do F1 mostra, em cada bioma, as zonas com o nome, a parte no mapa sorteado, a receita e as exceções de `species_biome_zones`.

## Critérios de aceite

- [x] Um hexágono da Comum tem as mesmas decorações de antes, em toda seed.
- [x] No mapa sorteado, o Bosque aparece cheio de árvores, a Clareira quase vazia, e as outras zonas com a cara da tabela.
- [ ] Uma luta começada num Bosque tem o tabuleiro com as plantas do Bosque.
- [x] O F1 mostra as zonas de cada bioma.
- [x] `godot --headless --path client --quit-after 30` sem erro de script.

## Desenho técnico

- `client/domain/models/hex_tile.gd`, `client/ui/components/hex_decorations.gd`.
- `client/screens/board_battle/board_battle_screen.gd`, `board_view.gd` e quem abre a luta em `client/screens/exploration/`.
- `client/tools/content_viewer/biomes_tab.gd`.
- Conferência numa cena temporária em `client/zz_tmp_check` (apagada no fim), que compara `decorations_of` de hexágonos da Comum com o código de antes e tira uma foto de um mapa sorteado com as zonas.

## Tarefas

- [x] `HexTile.zone` e as receitas.
- [x] O tabuleiro da luta.
- [x] A aba Biomas do F1.

# 01. As pedras como peças

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [vegetation-packs/01](../vegetation-packs/01-pack-props.md), [prop-depth-blocks/02](../prop-depth-blocks/), [editor-ui](../editor-ui/)

## Escopo

- `client/assets/props/make_giant_rocks.py` e os PNGs que ele grava em `client/assets/props/<slug>/<n>.png`.
- A migration `20270118000000_giant_rocks`: os tipos em `prop_types` e as linhas em `prop_type_blocks`. Como no Altar-portal e na village-pack, o `seed-data` não muda.
- O grupo "Pedras gigantes" do pincel Vegetação (`vegetation_panel.gd`).

## Os tipos

Todos na categoria Pedras (`prop_category_id` 6).

| id | slug | Nome | Variantes |
| --- | --- | --- | --- |
| 131 | `giant_crag` | Rochedo | 3: marrom, com musgo, de granito |
| 132 | `giant_pinnacles` | Pináculos | 1 |
| 133 | `giant_slab` | Laje inclinada | 1 |
| 134 | `giant_boulders` | Matacões | 1 |
| 135 | `giant_ridge` | Crista | 1 (2 hexágonos de largura) |
| 136 | `snowy_crag` | Rochedo com neve | 1 |
| 137 | `snowy_pinnacles` | Pináculos com neve | 1 |
| 138 | `snowy_boulders` | Matacões com neve | 1 |

## Requisitos

- **RF-01:** O `make_giant_rocks.py` desenha cada pedra com blocos de facetas: contorno escuro de 1 px (e entre blocos), até 7 tons por material com a luz de cima à esquerda, rachaduras entre as facetas, e, conforme a pedra, musgo, líquen, neve no topo, capim seco e pedrinhas no pé. A sombra fica embaixo, e o pé é o meio da borda de baixo do PNG.
- **RF-02:** Cada variante bloqueia por uma linha fechada de 6 pontos no pé, que o script imprime: um hexágono achatado com 80% da largura da base da pedra e até 28 px de altura. Com o pé no meio de um hexágono, a linha fecha só esse hexágono (a Crista, os dois hexágonos debaixo dela).
- **RF-03:** A migration cria os 8 tipos e uma linha por tipo, de variante 0 (o Rochedo tem a mesma linha nas 3).
- **RF-04:** O pincel Vegetação ganha o grupo "Pedras gigantes", com os 8 tipos, 0,25 peça por hexágono na Média e os 3 de neve desligados no começo. O pincel só confere o espaço dentro do hexágono, e o raio das peças de arte própria para em 15 px, então duas pedras de hexágonos vizinhos podem se encostar: o dono apaga uma com a Borracha.

## Critérios de aceite

- [x] Os 8 tipos têm os PNGs de 1 até `variants`, e o catálogo passa no `CatalogValidator`.
- [ ] A ferramenta Peças mostra os 8 tipos em Pedras, e uma peça põe e bloqueia (no F2, com o dono).
- [x] O jogo sem janela abre sem erro.
- [ ] O dono conferiu no F2.

## Resultado da verificação

Em 2026-11-20:

- **Arte:** 10 PNGs em 8 pastas, do Pináculos com neve (76 × 112 px) à Crista (160 × 96 px). As linhas impressas pelo script estão na migration.
- **Banco:** a migration `20270118000000_giant_rocks` foi aplicada com `migrate deploy`.
- **Jogo sem janela:** o catálogo passou no `CatalogValidator`; o `vegetation_panel.gd` e o `island_draft.gd` compilam, e os 8 tipos e a variante 3 do Rochedo têm arte.

## Verificação

```bash
cd client/assets/props && python -I make_giant_rocks.py
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --import
```

# 02. Os front.png das linhas do Clod e do Hushling

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-ruvo-nilu-fronts.md) (o mesmo caminho)

## Contexto

As imagens do dono ficam em `art-source/clod/line.webp` e `art-source/hushling/line.webp`. A primeira traz o Clod, o Crag e o Ingot, da esquerda para a direita. A segunda traz três versões da linha do gelo, das quais o dono descartou a primeira. As duas vêm com o fundo transparente.

## Requisitos

- **RF-01:** Os cinco `front.png` são recortados pelo `crop_line.py`, como na [01](01-ruvo-nilu-fronts.md):
  - `clod`, `crag` e `ingot`, da imagem do Clod;
  - `hushling` e `echofrost`, da segunda e da terceira forma da imagem do Hushling.
- **RF-02:** O `crop_line.py` passa a aceitar `-` no lugar de um slug: a forma daquela coluna é contada (para as peças soltas não irem para as outras) e descartada.
- **RF-03:** O `board.png` dos cinco é refeito pelo `board_sprites.gd`.
- **RF-04:** Nenhum código do jogo muda. As folhas de `explore/` ficam como estão.

## Critérios de aceite

- [x] Os cinco `front.png` têm 512×512, com alfa só 0 ou 255, e os bigodes do Hushling e do Echofrost ficaram neles.
- [x] Os cinco `board.png` foram refeitos.
- [x] O jogo sem janela abre sem erros de script.
- [ ] No Bestiário e no F1, as cinco formas aparecem com a arte nova.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/clod/line.webp clod crag ingot
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/hushling/line.webp - hushling echofrost
godot --headless --path client -s res://tools/board_sprites.gd -- clod crag ingot hushling echofrost
godot --headless --path client --import
godot --headless -d --path client --quit-after 120
```

Verificado em 2026-11-20, sem janela:
- Uma imagem com os cinco `front.png` e os `board.png` de antes e de depois foi mandada ao dono.
- O jogo abriu sem erros de script.

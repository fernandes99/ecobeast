# 01. Os front.png das linhas do Ruvo e da Nilu

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [seedlet-line](../seedlet-line/01-seedlet-line.md) (o recorte pelo `crop_line.py`)

## Contexto

As imagens do dono ficam em `art-source/ruvo/line.webp` (Ruvo, Ruvak e Ruvaroth, da esquerda para a direita) e `art-source/nilu/line.webp` (Nilu, Nilgar e Nilgorr). As duas já vêm com o fundo transparente, mas com perda: o alfa do miolo é 252 ou 253, e a borda vem meio apagada.

## Requisitos

- **RF-01:** Os seis `client/assets/creatures/<slug>/front.png` são recortados pelo `.claude/skills/creature-sprites/scripts/crop_line.py`, como na [seedlet-line](../seedlet-line/01-seedlet-line.md) (RF-02): 512×512, o lado maior com 480 px, centralizados, sem suavização, e as chamas e respingos soltos indo para a forma mais perto.
- **RF-02:** O `crop_line.py` passa a deixar o alfa só em 0 ou 255 (a partir de 128 é opaco), para a pixel art não ficar transparente nem com borda meio apagada.
- **RF-03:** O `board.png` dos seis é refeito pelo `client/tools/board_sprites.gd`, que passa a aceitar os slugs (`-- ruvo ruvak ...`). Sem slugs, refaz o de todos, como antes.
- **RF-04:** Nenhum código do jogo muda. As folhas de `explore/` e de `battle/` ficam como estão.

## Critérios de aceite

- [x] Os seis `front.png` têm 512×512, alfa só 0 ou 255, e nenhum halo do fundo.
- [x] Os seis `board.png` foram refeitos; os de outros Ecobeasts não mudaram.
- [x] O jogo sem janela abre sem erros de script.
- [ ] Na escolha do inicial, no Bestiário e no F1, as seis formas aparecem com a arte nova.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/ruvo/line.webp ruvo ruvak ruvaroth
python -I .claude/skills/creature-sprites/scripts/crop_line.py art-source/nilu/line.webp nilu nilgar nilgorr
godot --headless --path client -s res://tools/board_sprites.gd -- ruvo ruvak ruvaroth nilu nilgar nilgorr
godot --headless --path client --import
godot --headless -d --path client --quit-after 120
```

Verificado em 2026-11-20, sem janela:
- Uma imagem com o antes e o depois dos seis `front.png` e dos seis `board.png` foi mandada ao dono.
- O jogo abriu sem erros de script.

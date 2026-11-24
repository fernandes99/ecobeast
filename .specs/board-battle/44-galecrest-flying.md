# 44. O Galecrest voando, do PixelLab

- **Status:** concluída (falta o dono ver no jogo)
- **Depende de:** [07](07-battle-sprites.md), [41](41-battle-sprite-size.md), [43](43-custom-pixellab.md)

## Contexto

Em 2026-11-24, o dono gerou o Galecrest no PixelLab, no canvas de 80, com duas animações de voo: a que paira no lugar, batendo as asas, e a `flying`. Ele quis o Galecrest sempre no ar, como o Arbornix da [43](43-custom-pixellab.md): "o walking sera o mesmo que o iddle". E escolheu por vista: "Na pasta flying você vai usar apenas a versão east, west. O restante vai usar da outra pasta."

## Escopo

- O zip em `art-source/galecrest/pixellab.zip`, o `battle.json` e as folhas `idle.png` e `walk.png` em `client/assets/creatures/galecrest/battle/`, pelo `battle_sheets.py`.

## Fora do escopo

- Mudar o jogo: o `BattleSheets` acha as folhas pelo slug.
- A Puffcoo, que ainda não tem folha de luta.

## Requisitos

- **RF-01:** A vista de lado (east) vem da animação `flying`. O west não é lido: o jogo espelha o east ([07](07-battle-sprites.md)).
- **RF-02:** As outras 4 vistas (south, north, south-east e north-east) vêm da animação que paira no lugar.
- **RF-03:** O walk repete o idle, vista por vista: na luta, o Galecrest bate as asas parado e ao se mover.

| Ecobeast | m | Canvas | Célula | Altura | Largura |
| --- | --- | --- | --- | --- | --- |
| Galecrest | 1,50 | 80 | 104 | 62 px | 81 px |

## Critérios de aceite

- [x] O `check_battle.py galecrest` passa.
- [x] As duas folhas têm 5 linhas e 9 quadros por linha, com o east da `flying`.
- [ ] O dono vê o Galecrest na luta.

## Verificação

```bash
cd server && npm run start:dev
python -I .claude/skills/creature-sprites/scripts/battle_sheets.py galecrest
python -I .claude/skills/creature-sprites/scripts/check_battle.py galecrest
```

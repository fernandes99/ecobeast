# 42. A linha do Ruvo inteira do PixelLab

- **Status:** concluída (falta o dono ver no jogo)
- **Depende de:** [07](07-battle-sprites.md), [17](17-idle-facing.md), [41](41-battle-sprite-size.md)

## Contexto

Até aqui, só o Ruvo tinha as duas folhas da luta do PixelLab, no modelo `bear`. O Ruvak tinha o idle do PixelLab da [24](24-ruvak-idle.md) e o walk do boneco de peças, e o Ruvaroth não tinha folha de luta. Em 2026-11-23, o dono gerou no PixelLab o idle e o walk dos três, nas 8 direções, no modelo `dog` e no canvas da regra da [41](41-battle-sprite-size.md), e pediu para atualizar o projeto.

## Escopo

- Os zips em `art-source/<slug>/pixellab.zip` e as folhas `idle.png` e `walk.png` em `client/assets/creatures/<slug>/battle/` do Ruvo, do Ruvak e do Ruvaroth, pelo `battle_sheets.py`.
- O boneco do Ruvak deixa de escrever no jogo.

## Fora do escopo

- Mudar o jogo: o `BattleSheets` acha as folhas pelo slug, e o Ruvaroth passa a ter as dele sem código novo.
- As folhas do mapa e as dos outros Ecobeasts.

## Requisitos

- **RF-01:** Cada zip vai para `art-source/<slug>/pixellab.zip` como veio, e as folhas saem do `battle_sheets.py` com as 5 vistas do idle e do walk, 8 quadros por vista.
- **RF-02:** O Ruvak passa a vir só do `pixellab.zip`: saem o `art-source/ruvak/pixellab_idle.zip` e o `battle.json` das trocas pela imagem parada, e o idle da [24](24-ruvak-idle.md) é substituído (fica no histórico do git), assim como o idle novo da fase 40, que outra sessão deixou sem commit.
- **RF-03:** O `client/assets/creatures/ruvak/battle/sprites.py` fica como o exemplo do boneco de peças, gravando as folhas dele só na pasta das prévias.

| Ecobeast | Canvas | Célula | Altura do idle / walk | Largura |
| --- | --- | --- | --- | --- |
| Ruvo | 48 | 64 | 44 / 44 px | 42 px |
| Ruvak | 64 | 64 | 43 / 45 px | 38 px |
| Ruvaroth | 80 | 84 | 61 / 63 px | 57 px |

O efeito da [41](41-battle-sprite-size.md) aparece aqui: no modelo `dog`, o Ruvo no canvas de 48 sai quase da altura do Ruvak no de 64.

## Critérios de aceite

- [x] O `check_battle.py` passa nos três.
- [x] As folhas têm 5 linhas e 8 quadros por linha, nas duas folhas dos três.
- [ ] O dono vê os três na luta (o Ruvaroth pela luta de teste do F1).

## Verificação

```bash
cd server && npm run start:dev
python -I .claude/skills/creature-sprites/scripts/battle_sheets.py ruvo
python -I .claude/skills/creature-sprites/scripts/battle_sheets.py ruvak
python -I .claude/skills/creature-sprites/scripts/battle_sheets.py ruvaroth
python -I .claude/skills/creature-sprites/scripts/check_battle.py ruvaroth
```

# 43. A linha do Seedlet do PixelLab, no modelo Custom

- **Status:** concluída (falta o dono ver no jogo)
- **Depende de:** [07](07-battle-sprites.md), [41](41-battle-sprite-size.md), [42](42-ruvo-line-pixellab.md)

## Contexto

O Seedlet anda em duas pernas, com cauda, e o Arbornix é uma fênix que voa: nenhum dos dois cabe nos esqueletos `humanoid` e `quadruped` do PixelLab. Em 2026-11-23, o dono gerou a linha inteira no modelo **Custom**, sem esqueleto: o Seedlet parado e andando, com as animações descritas em texto, o Grovequill com o Idle e o Walking prontos do V3, e o Arbornix só pairando, batendo as asas. Para o Arbornix, ele pediu: "o walk do arbonix será o mesmo que o iddle, use o mesmo por favor".

## Escopo

- Os zips em `art-source/<slug>/pixellab.zip` do Seedlet, do Grovequill e do Arbornix, os `battle.json` e as folhas `idle.png` e `walk.png` dos três, pelo `battle_sheets.py`.
- A largura máxima das folhas da luta, no RF-04 da [41](41-battle-sprite-size.md).

## Fora do escopo

- Mudar o jogo: o `BattleSheets` acha as folhas pelo slug.

## Requisitos

- **RF-01:** As animações descritas em texto ganham o nome do texto no zip, sem "idle" nem "walk". O `art-source/<slug>/battle.json` diz ao `battle_sheets.py` qual animação vai em cada vista.
- **RF-02:** O Seedlet tira o idle da animação parada e o walk da que anda (que já tem "walking" no nome). O Grovequill, com os nomes Idle e Walking, não precisa de `battle.json`.
- **RF-03:** O Arbornix tira o idle e o walk da mesma animação de voo, nas 5 vistas: na luta, ele bate as asas parado e ao se mover.

| Ecobeast | m | Canvas | Célula | Altura | Largura | Ocupa |
| --- | --- | --- | --- | --- | --- | --- |
| Seedlet | 0,40 | 48 | 56 | 40 / 41 px | 43 px | 85% |
| Grovequill | 1,00 | 64 | 80 | 56 px | 54 px | 88% |
| Arbornix | 1,80 | 80 | 112 | 79 px | 94 px | 99% |

O Custom ocupa o canvas mais que o `dog` (67%). O Arbornix, de asas abertas, passava dos 90 px de largura do RF-04 da [41](41-battle-sprite-size.md) nas vistas de frente (91 px) e de costas (94 px), no auge da batida; nas diagonais e de lado, fica entre 53 e 81 px.

- **RF-04:** O limite de largura do RF-04 da [41](41-battle-sprite-size.md) sobe de 90 para 96 px, a largura do hexágono, por decisão do dono: "Aceitar até 96 px". As asas do Arbornix cabem no hexágono, só sem a folga de antes.

## Critérios de aceite

- [x] O `check_battle.py` passa no Seedlet e no Grovequill.
- [x] O `check_battle.py arbornix` passa, com o limite de 96 px.
- [x] As folhas dos três têm 5 linhas, com 9 quadros por linha no Seedlet e no Arbornix e 8 no Grovequill.
- [ ] O dono vê os três na luta.

## Verificação

```bash
cd server && npm run start:dev
python -I .claude/skills/creature-sprites/scripts/battle_sheets.py seedlet
python -I .claude/skills/creature-sprites/scripts/battle_sheets.py grovequill
python -I .claude/skills/creature-sprites/scripts/battle_sheets.py arbornix
python -I .claude/skills/creature-sprites/scripts/check_battle.py seedlet
python -I .claude/skills/creature-sprites/scripts/check_battle.py grovequill
python -I .claude/skills/creature-sprites/scripts/check_battle.py arbornix
```

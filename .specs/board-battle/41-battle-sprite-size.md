# 41. O tamanho dos Ecobeasts na luta

- **Status:** concluída
- **Depende de:** [07](07-battle-sprites.md), [24](24-ruvak-idle.md), [40](40-ruvak-new-idle.md)

## Contexto

A [07](07-battle-sprites.md) deixou o canvas de cada folha da luta _a revisar_: Ruvo 48, Ruvak 64 e Ruvaroth 96. Em 2026-11-23, o dono propôs escolher o canvas pela altura do catálogo. A primeira versão desta fase fixava a altura do desenho por uma conta (30 + 22 × m), mas o PixelLab não ocupa o canvas sempre na mesma proporção:

| Folha | Canvas do PixelLab | Altura do desenho | Ocupa |
| --- | --- | --- | --- |
| Ruvo (modelo `bear`) | 48 | 40 a 42 px | 85% |
| Ruvak, idle novo (modelo `dog`) | 64 | 42 a 43 px | 67% |

Pela conta, o Ruvak pedia 52 px, e só um canvas maior que 64 chegaria lá. O dono decidiu manter o que o PixelLab entrega: "Quero manter a proporção que ele trazer para mim no canvas selecionado". A regra passa a ser só o canvas escolhido no PixelLab, e o desenho fica do tamanho que vier, sem ampliar nem reduzir. Depois, ele quis 4 canvas, com o 80 entre o 64 e o 96, para os degraus crescerem menos.

O efeito conhecido: com modelos diferentes, uma evolução pode sair quase da altura da forma anterior, como o Ruvo (42 px) e o Ruvak parado (43 px).

## Escopo

- A regra do canvas das folhas da luta.
- A conferência `check_battle.py`, na skill `creature-sprites`.

## Fora do escopo

- Refazer as folhas de hoje ou fazer as do Ruvaroth.
- Mudar o jogo: o tabuleiro já mostra a folha em 1×, do tamanho que ela tiver.
- As folhas do mapa, que seguem a [creature-scale](../creature-scale/).

## Requisitos

- **RF-01:** O canvas do personagem no PixelLab sai da altura do catálogo (`height_m`), em 4 degraus: 48 até 0,6 m, 64 até 1,0 m, 80 até 2,0 m e 96 acima de 2,0 m. Em 2026-11-23, o catálogo tem 20 espécies no 48, 11 no 64, 19 no 80 e nenhuma no 96: o dono quis o maior canvas só para quem passa de 2 m ("quero aumentar na verdade o tamanho do 96, talvez acima de 2m"). O 96 fica para os gigantes que vierem; o desenho dele, de uns 62 a 82 px, ainda cabe nos 87 px de altura do hexágono.
- **RF-02:** A folha de uma vista do PixelLab mantém o desenho como veio, sem ampliar nem reduzir. A célula da folha pode ser maior que o canvas, quando a ferramenta centra o canvas numa célula maior ([07](07-battle-sprites.md)).
- **RF-03:** Uma folha desenhada à mão, como o walk do Ruvak pelo boneco, fica na faixa do canvas do RF-01: a altura do desenho entre 60% do canvas e o canvas (29 a 48, 38 a 64, 48 a 80 ou 58 a 96 px).
- **RF-04:** A largura do desenho fica em até 96 px, a largura do hexágono. Era 90, com 6 px de folga; o dono subiu para 96 na [43](43-custom-pixellab.md), quando as asas abertas do Arbornix chegaram a 94 px ("Aceitar até 96 px").
- **RF-05:** O `check_battle.py <slug>` confere:
  - o canvas de cada zip do PixelLab em `art-source/<slug>/` (o `size` do `metadata.json` ou do `.json` da folha) contra o RF-01;
  - as folhas que não vêm de um zip pela faixa do RF-03: o `pixellab.zip` cobre as duas folhas, e o `pixellab_idle.zip` ou o `pixellab_walk.zip` cobrem uma só;
  - a largura do RF-04 nas duas;
  - a altura, de `GET /v1/catalog`, com o servidor no ar, como no `check_sheets.py`.

| Ecobeast | m | Canvas |
| --- | --- | --- |
| Nilu | 0,30 | 48 |
| Ruvo | 0,50 | 48 |
| Owlume | 0,90 | 64 |
| Ruvak | 1,00 | 64 |
| Kelpcoil | 1,10 | 80 |
| Galecrest | 1,50 | 80 |
| Ruvaroth | 1,60 | 80 |
| Tempestide | 2,00 | 80 |
| acima de 2 m | | 96 |

## Critérios de aceite

- [x] O `check_battle.py ruvo` passa: o zip tem o canvas de 48.
- [x] O `check_battle.py ruvak` passa: o zip do idle tem o canvas de 64, e o walk do boneco tem 61 px, na faixa de 38 a 64.
- [x] O zip `Idle-spritesheet (1).zip` que o dono mandou em 2026-11-23, o Ruvak no canvas de 64 com 43 px, fica na regra (`check_battle.py ruvak <zip>`).

## Desenho técnico

**Criar:** `.claude/skills/creature-sprites/scripts/check_battle.py`, em Python sem bibliotecas de fora, com o `read_png` do `spritekit.py`; a regra do RF-01 é a `battle_canvas(height_m)` dele.

**Alterar:** a seção das folhas da luta na skill `creature-sprites`, com a regra e a conferência; o RF-07 da [07](07-battle-sprites.md), que aponta para esta fase.

## Verificação

```bash
cd server && npm run start:dev
python -I .claude/skills/creature-sprites/scripts/check_battle.py ruvo
python -I .claude/skills/creature-sprites/scripts/check_battle.py ruvak
```

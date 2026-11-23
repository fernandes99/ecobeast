# 41. O tamanho dos Ecobeasts na luta

- **Status:** concluída (o Ruvak está fora da regra e espera folhas novas)
- **Depende de:** [07](07-battle-sprites.md), [24](24-ruvak-idle.md), [40](40-ruvak-new-idle.md)

## Contexto

A [07](07-battle-sprites.md) deixou o canvas de cada folha da luta _a revisar_: Ruvo 48, Ruvak 64 e Ruvaroth 96. Em 2026-11-23, o dono propôs uma regra pela altura do catálogo: até 1 m, 48; de 1 a 1,5 m, 64; acima, 96. Medidas as folhas de hoje, o canvas não garante o tamanho, porque o PixelLab ocupa o canvas em proporções diferentes:

| Folha | Canvas | Altura do desenho |
| --- | --- | --- |
| Ruvo, idle e walk | 48 | 35 a 42 px |
| Ruvak, idle novo do PixelLab ([40](40-ruvak-new-idle.md)) | 64 | 38 a 43 px |
| Ruvak, walk do boneco | 64 | 56 a 61 px |

O Ruvak parado ficou do tamanho do Ruvo e encolhe ao parar de andar. Além disso, as formas do meio da linha ficam quase todas entre 0,9 e 1,2 m (Owlume 0,88, Ruvak 1,02, Kelpcoil 1,09, Venomaw 1,22), e o corte em 1 m as dividiria. O dono aceitou a proposta: a regra é a **altura do desenho**, por uma conta da altura do catálogo, e o canvas é a caixa onde ele cabe, com os cortes nos vãos entre os grupos.

## Escopo

- A regra da altura do desenho e do canvas das folhas da luta.
- A conferência `check_battle.py`, na skill `creature-sprites`.

## Fora do escopo

- Refazer as folhas do Ruvak e fazer as do Ruvaroth: chegam pelo PixelLab ou pelo boneco, numa entrega própria.
- Mudar o jogo: o tabuleiro já mostra a folha em 1×, do tamanho que ela tiver.
- As folhas do mapa, que seguem a [creature-scale](../creature-scale/).

## Requisitos

- **RF-01:** A altura do desenho de uma folha da luta, do pixel mais alto ao pé, com orelhas e chamas, no quadro mais alto, é `arredondar(30 + 22 × height_m)`, entre 32 e 80 px. A altura é a `height_m` do catálogo.
- **RF-02:** O canvas (a célula) é 48 até 0,6 m, 64 de 0,6 a 1,3 m e 96 acima de 1,3 m. O desenho do maior de cada faixa ainda deixa folga para o balanço e a chama: 43 px no 48 e 59 px no 64.
- **RF-03:** A largura do desenho fica em até 90 px, abaixo dos 96 px do hexágono. Quem passaria disso, como uma serpente esticada ou uma cauda longa, fica mais compacto, nunca cortado.
- **RF-04:** O `check_battle.py <slug>` lê as duas folhas de `battle/` como o jogo (`BattleSheets._find_rows`: o idle com 2 ou 5 linhas e o walk com 3 ou 5, na mesma célula), mede a altura e a largura do desenho em cada folha e falha quando a altura sai mais de 3 px da do RF-01 ou a largura passa do RF-03. O canvas fora do RF-02 só gera aviso, porque o tamanho na tela é o do desenho. A altura vem do catálogo do servidor, como no `check_sheets.py`.

| Ecobeast | m | Desenho | Canvas |
| --- | --- | --- | --- |
| Nilu | 0,27 | 36 px | 48 |
| Ruvo | 0,50 | 41 px | 48 |
| Owlume | 0,88 | 49 px | 64 |
| Ruvak | 1,00 | 52 px | 64 |
| Galecrest | 1,50 | 63 px | 96 |
| Ruvaroth | 1,63 | 66 px | 96 |
| 1,9 m ou mais | | 72 a 80 px | 96 |

A escala não é a real: a Nilu viraria uma mancha, e um grande passaria do hexágono. A conta comprime a diferença (o maior tem cerca de 2,2 vezes a altura do menor), e cada evolução ainda cresce de forma visível.

## Critérios de aceite

- [x] O `check_battle.py ruvo` passa (42 px no idle e no walk, contra 41), com o aviso da célula de 64, onde a ferramenta da [07](07-battle-sprites.md) centrou o canvas de 48.
- [x] O `check_battle.py ruvak` falha, dizendo a altura de cada folha (43 px no idle e 61 no walk) e a pedida (52).
- [ ] As folhas novas do Ruvak e as do Ruvaroth passam no `check_battle.py`.

## Desenho técnico

**Criar:** `.claude/skills/creature-sprites/scripts/check_battle.py`, em Python sem bibliotecas de fora, com o `read_png` do `spritekit.py`; `battle_height_in_pixels(height_m)` e `battle_canvas(height_m)` ficam nele.

**Alterar:** a seção das folhas da luta na skill `creature-sprites`, com a regra e a conferência; o RF-07 da [07](07-battle-sprites.md), que aponta para esta fase.

## Verificação

```bash
cd server && npm run start:dev
python -I .claude/skills/creature-sprites/scripts/check_battle.py ruvo
python -I .claude/skills/creature-sprites/scripts/check_battle.py ruvak
```

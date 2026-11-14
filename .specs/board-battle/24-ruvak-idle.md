# 24. O idle do Ruvak, do PixelLab

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [07](07-battle-sprites.md) e [17](17-idle-facing.md) (as folhas da luta e o idle de 5 vistas)

## Contexto

Na [07](07-battle-sprites.md), as folhas da luta do Ruvak foram desenhadas à mão, com o boneco de peças (`puppet.py`), com o idle de 2 vistas. Em 2026-11-13, o dono gerou o Ruvak no PixelLab e mandou só o idle: "temos as animações agora do ruvak, temos apenas so o idle dele, pegue por enquanto". O walk continua o do boneco até o dono mandar o novo.

O zip veio num formato que o `battle_sheets.py` não lê: uma folha só (`Idle.png`, 768 × 1056, células de 96) com um `Idle.json` que diz o que tem em cada linha. Ele traz as 8 rotações paradas, o "Run" de frente e da diagonal descendo (4 quadros) e o idle nas 8 direções (8 quadros). O desenho cabe numa célula de 64, a do walk do boneco, e tem quase a mesma altura dele (58 pixels contra 61).

## Escopo

- O zip em `art-source/ruvak/pixellab_idle.zip`.
- O `idle.png` da luta do Ruvak com as 5 vistas do PixelLab.
- Uma ferramenta que tira o idle de um zip de folha única, na célula do walk que já existe.

## Fora do escopo

- O walk do Ruvak: continua o do boneco, num estilo diferente do idle novo, até chegar o do PixelLab.
- As folhas do mapa (`explore/`).
- O "Run" do zip, que tem só 2 das 3 vistas que o walk precisa.

## Requisitos

- **RF-01:** O `idle.png` do Ruvak tem 5 linhas ([17](17-idle-facing.md), RF-01): south, north, south-east, east e north-east, com os 8 quadros do idle do PixelLab em cada uma. Parado, ele olha para o último passo.
- **RF-02:** A célula é a do `walk.png` (64), para o jogo achar as linhas pela proporção das alturas ([17](17-idle-facing.md), RF-04). O desenho fica centrado no pivô do PixelLab (o meio da célula de 96) e com os pés na linha dos pés do walk (63), para o Ecobeast não subir nem descer quando para de andar.
- **RF-03:** `idle_from_spritesheet.py <slug> <zip>`, na skill `creature-sprites`, lê o `.json` e a folha, escolhe as linhas de "Idle" das 5 vistas e escreve só o `idle.png`. Para com uma mensagem quando falta uma vista ou quando o desenho passa da célula.
- **RF-04:** O `sprites.py` do boneco do Ruvak passa a escrever só o `walk.png`, para não apagar o idle do PixelLab; o idle dele vai só para as prévias.

## Critérios de aceite

- [x] O jogo lê as folhas do Ruvak com o idle de 5 linhas de 8 quadros e o walk de 3 linhas, na célula de 64, com os pés na linha 63.
- [x] Na luta, o Ruvak parado aparece com a arte nova, de frente, de costas e de lado depois de andar.
- [ ] O dono vê o Ruvak na luta com F5.

## Desenho técnico

**Criar:** `art-source/ruvak/pixellab_idle.zip` (o zip do dono) e `.claude/skills/creature-sprites/scripts/idle_from_spritesheet.py`.

**Alterar:** `client/assets/creatures/ruvak/battle/idle.png`; o `sprites.py` do boneco do Ruvak (RF-04); a seção das folhas da luta na skill.

```bash
python -I .claude/skills/creature-sprites/scripts/idle_from_spritesheet.py ruvak art-source/ruvak/pixellab_idle.zip
```

## Verificação

- A ferramenta escreve o `idle.png` com 512 × 320 (8 colunas e 5 linhas de 64).
- Um teste sem janela do `BattleSheets` confere a célula, as linhas, os quadros e os pés do Ruvak.
- Um print com janela, de poucos segundos, mostra o Ruvak de frente, de lado depois de andar e andando, ao lado do Ruvo.

## Tarefas

- [x] Spec.
- [x] A ferramenta e o `idle.png`.
- [x] O teste sem janela e o print.
- [ ] O dono ver com F5.

## Resultado da verificação

Em 2026-11-13: a ferramenta escreveu o `idle.png` com 512 × 320, célula de 64 e pés na linha 63, a mesma do walk. O teste sem janela leu o Ruvak com o idle de 5 linhas de 8 quadros e o walk de 3 linhas de 4, com os pés na 63 e a linha de lado presente. O print mostrou o Ruvak selvagem de frente, o do jogador de lado depois de andar, com a arte nova e na mesma altura do chão, e outro andando, com o walk do boneco, num estilo mais simples. Falta o dono ver na luta com F5.

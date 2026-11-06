# 07. Sprites da luta em alta resolução

- **Status:** em andamento: o Ruvo está pronto e o dono já testou; o Ruvak está desenhado e falta o dono ver; o Ruvaroth está pendente.
- **Depende de:** [06](06-board-look.md)

## Contexto

Na [06](06-board-look.md), cada Ecobeast entrou no tabuleiro com o `board.png`, que é o `front.png` reduzido por um programa e mostrado 2× maior. O resultado ficava parado, meio borrado e com uma vista só. O dono quer os Ecobeasts da luta com mais qualidade e animados, andando nas 6 direções do tabuleiro.

Em 2026-11-05, o dono gerou o Ruvo no PixelLab, um site de pixel art, a partir da descrição do `front.png`. Veio um personagem de 48 × 48 com:

- as 8 direções paradas;
- o walk de 4 quadros nas 8 direções;
- o idle de 15 quadros, de frente e de costas.

O idle de costas pedido pela API saiu errado: era a criatura de frente, num estilo mais simples. O dono gerou outro pelo site. Esta fase transforma o zip do PixelLab nas folhas da luta e as liga ao tabuleiro.

O mapa de Explorar continua com as folhas desenhadas à mão pela skill `creature-sprites`, na escala real do Domador. O dono viu um teste com o Ruvo do PixelLab reduzido para 27, 20, 13 e 7 px, ao lado do Domador, e decidiu manter a escala real no mapa ("queria manter a escala real ainda"). Reduzido a 7 px, o Ruvo vira uma mancha. Por isso cada criatura tem duas pastas, uma por tela, com os nomes que o dono escolheu: `explore/` e `battle/`.

## Escopo

- As pastas `explore/` e `battle/` em `client/assets/creatures/<slug>/`. As folhas do mapa mudam para `explore/` sem mudar um pixel.
- Os originais do PixelLab, guardados em `art-source/<slug>/` na raiz do repositório.
- Uma ferramenta que monta `battle/idle.png` e `battle/walk.png` a partir do zip do PixelLab.
- O tabuleiro usando as folhas de `battle/`, com o idle e o walk nas 6 direções.
- As folhas de luta do Ruvo (do PixelLab), do Ruvak (desenhadas à mão, decisão do dono) e do Ruvaroth.

## Fora do escopo

- As folhas de luta das outras espécies. Cada uma chega numa entrega própria, sem mudar código.
- Redesenhar as folhas do mapa, ou reduzir a arte da luta para o mapa.
- Animações de Técnica, de dano e de queda.
- O retrato dos cartões e da equipe, que continua sendo o `front.png`.

## Requisitos

**Pastas**

- **RF-01:** Cada Ecobeast tem a pasta `client/assets/creatures/<slug>/explore/`, com as folhas do mapa (`idle.png` e `walk.png`) e o `sprites.py` que as desenha. Até esta fase elas ficavam na raiz da pasta da criatura. O `front.png` continua na raiz. O mapa, o spawn de depuração e a skill `creature-sprites` passam a usar `explore/`, e nada muda na tela.
- **RF-02:** Cada Ecobeast pode ter `client/assets/creatures/<slug>/battle/`, com as folhas da luta `idle.png` e `walk.png`.
- **RF-03:** O zip baixado do PixelLab fica em `art-source/<slug>/pixellab.zip`, como veio, para a ferramenta poder gerar as folhas de novo. A pasta fica fora de `client/`, e o Godot não importa nada dela. Uma folha desenhada à mão tem o `sprites.py` dela na pasta `battle/`, como as do mapa.

**As folhas da luta**

- **RF-04:** Uma linha por vista e uma coluna por quadro, em células quadradas.
  - O `idle.png` tem 2 linhas: 0, de frente (south); 1, de costas (north).
  - O `walk.png` tem 3 linhas: 0, diagonal descendo (south-east); 1, de lado (east); 2, diagonal subindo (north-east).
  - Todas olham para a direita. A esquerda é a mesma arte espelhada.
- **RF-05:** O número de quadros pode mudar de linha para linha. O resto de uma linha mais curta fica vazio, e nenhum quadro pode ser vazio. Cada quadro dura 0,2 s no idle (o tempo dos GIFs do PixelLab) e 0,15 s no walk. O zip não traz o tempo, então esses valores são _a revisar_.
- **RF-06:** O jogo tira da própria imagem tudo o que precisa saber. A célula é a altura da folha dividida pelas linhas. Cada linha tem os quadros até a primeira célula vazia. Os pés ficam na última linha de pixels de todas as células. Não há arquivo de dados ao lado das folhas: não temos configuração de export no repositório que garanta que um `.json` solto vá para o Android.
- **RF-07:** O pixel da arte tem o mesmo tamanho para todos: uma evolução parece maior por ter mais pixels, não pixels maiores. Canvas (_a revisar_): Ruvo 48, Ruvak 64, Ruvaroth 96.
- **RF-08:** A ferramenta lê `art-source/<slug>/pixellab.zip`. Ela usa a animação com "idle" no nome para o idle e a com "walk" para o walk. Um `art-source/<slug>/battle.json` opcional troca a fonte de uma vista: o nome de outra animação, ou `"rotation"` para a imagem parada daquela direção. Uma vista que falta, ou um quadro vazio, fazem a ferramenta parar com uma mensagem que diz o que falta.

**No tabuleiro**

- **RF-09:** Quem tem as duas folhas de `battle/` aparece com elas. Quem não tem continua com o `board.png` ou o `front.png`, como na [06](06-board-look.md).
- **RF-10:** Parado, o Ecobeast toca o idle olhando para o adversário. Os do jogador, que estão embaixo, ficam de costas (north); os selvagens, em cima, ficam de frente (south). Quem tem as folhas não respira por escala, porque o idle já respira. A exceção é um idle de um quadro só, que é uma imagem parada e por isso continua respirando por escala.
- **RF-11:** Andando, o Ecobeast toca o walk na direção do passo:
  - para o lado, a linha de lado;
  - descendo, a diagonal descendo;
  - subindo, a diagonal subindo;
  - para a esquerda, a mesma linha espelhada.

  Cada passo de hexágono dura um ciclo do walk, sem o pulinho da [06](06-board-look.md). Ao chegar, o Ecobeast volta ao idle do RF-10.
- **RF-12:** A sombra, a barra de HP e o número de dano continuam como na [06](06-board-look.md), no tamanho da folha nova. O contorno branco no sprite de quem joga sai, a pedido do dono ("Remove o contorno branco que fica no turno daquele ecobeast"): quem joga fica destacado só pelo hexágono. O shader `creature_outline.gdshader` foi apagado.
- **RF-13:** A folha aparece sem ampliar: 1 pixel da arte vale 1 pixel do tabuleiro, sem filtro. O tabuleiro inteiro continua ampliado para caber na tela. O dono viu os prints em 1× e em 2× e decidiu ficar com 1× ("quero ver como vai ficar").

## Critérios de aceite

- [x] O mapa de Explorar e o spawn de depuração mostram os mesmos Ecobeasts de antes, lendo de `explore/`.
- [x] Com o zip em `art-source/ruvo/`, a ferramenta gera `battle/idle.png` e `battle/walk.png` no formato do RF-04.
- [x] Sem uma vista, a ferramenta para e diz qual falta.
- [x] No tabuleiro, o Ruvo selvagem fica de frente e o do jogador de costas, os dois tocando o idle.
- [x] Andando para cada uma das 6 direções, o Ruvo toca o walk na vista certa, espelhada para a esquerda.
- [x] Um Ecobeast sem `battle/` continua aparecendo com o `board.png`.
- [x] O projeto abre sem erros nem avisos de script.
- [ ] O Ruvak e o Ruvaroth têm as folhas da luta.

## Desenho técnico

**Pastas:** `git mv` de `idle.png`, `walk.png`, `sprites.py` e dos `.import` de cada Ecobeast para `explore/`. O `source_file` dos `.import` passa a apontar para o novo caminho, e o `sprites.py` sobe um nível a mais para achar a skill.

**Ferramenta:** `.claude/skills/creature-sprites/scripts/battle_sheets.py`, em Python sem bibliotecas de fora. Ela reaproveita o `read_png_bytes` e o `write_png` do `spritekit.py`. Uso: `python -I .claude/skills/creature-sprites/scripts/battle_sheets.py <slug>`. Quando um canvas é menor que a célula, ele fica centrado nela, porque o PixelLab aumenta o canvas das animações pelas bordas.

**Jogo:**

- `res://ui/components/creature_sprite.gd`: o `SHEET_PATH` passa para `explore/`.
- `res://screens/board_battle/battle_sheets.gd` (novo, `BattleSheets`): lê as duas folhas de uma espécie, uma vez só, e tira delas a célula, os quadros de cada linha, os pés e a altura. Tem `has_sheets(slug)` e `for_slug(slug)`.
- `res://screens/board_battle/board_view.gd`:
  - o `Token` toca as folhas num `Sprite2D`, com `hframes`, `vframes` e `frame_coords`;
  - `_rest` escolhe o idle de cada lado, e `_face` escolhe a vista do walk;
  - quem não tem as folhas fica como estava.

**Skill:** a `creature-sprites` passa a escrever em `explore/` e ganha uma seção sobre as folhas da luta.

## Verificação

```bash
python -I .claude/skills/creature-sprites/scripts/battle_sheets.py ruvo
godot --headless --path client --import
godot --headless --path client --quit-after 60
```

Também roda um teste sem janela do `BattleSheets` e do `BoardView`, e um print da tela, que abre uma janela e exige avisar o dono antes. No jogo: F5, Explorar zona, o spawn de depuração e uma luta.

## Tarefas

- [x] Mover as folhas do mapa para `explore/` e ajustar o mapa e a skill (RF-01).
- [x] A ferramenta das folhas da luta (RF-03 a RF-08).
- [x] As folhas do Ruvo.
- [x] O `BattleSheets` e o tabuleiro (RF-09 a RF-13).
- [x] As folhas do Ruvak, desenhadas à mão com o boneco de peças (`puppet.py`).
- [ ] As folhas do Ruvaroth.
- [ ] Atualizar o README e o `architecture.md`, rodar a verificação e fazer o commit `feat: sprites da luta em alta resolução`.

## Divergências

O que a implementação fez diferente do primeiro rascunho desta spec, e por quê:

- **Sem o `sheets.json`.** O rascunho guardava a célula, os quadros e o tempo num arquivo ao lado das folhas. Agora o jogo tira tudo da imagem (RF-06), e o tempo de cada quadro fica no código.
- **Sem o `BattleCreatureSprite`.** O `Token` já tinha um `Sprite2D`, e as folhas tocam nele com `hframes` e `vframes`. O `SheetSprite` do mapa não mudou.
- **A entrada da ferramenta é o zip, e não os GIFs.** Com a chave da API do dono, o zip do personagem traz cada quadro em PNG, separado por animação e direção.
- **O Ruvak é desenhado à mão**, por decisão do dono, sem o PixelLab. Desenhar texto pixel a pixel nesse tamanho deixaria cada vista de um jeito. Por isso, ele é um boneco de elipsoides (`.claude/skills/creature-sprites/scripts/puppet.py`), virado para cada vista e pintado em 3 tons, com o contorno e os olhos em carimbos. O desenho está em `client/assets/creatures/ruvak/battle/sprites.py`, que escreve as folhas na mesma pasta.

## Resultado da verificação

**Conferido por quem implementou, sem janela:**

- As 11 folhas do mapa, geradas de novo a partir de `explore/`, são iguais às de antes, pixel a pixel, e passam no `check_sheets.py`.
- A ferramenta gerou as folhas do Ruvo: célula de 64, pés na linha 53, idle com 15 + 15 quadros e walk com 4 quadros nas 3 vistas. Sem o zip, ela para com "falta art-source\ruvak\pixellab.zip".
- O teste do tabuleiro passou nos 22 itens:
  - o idle de cada lado;
  - o idle trocando de quadro;
  - as 6 direções do walk, com o espelho;
  - a volta ao idle depois de andar;
  - o Ruvak sem folhas usando o `board.png`;
  - o contorno de quem joga.
- O projeto abre sem erros nem avisos.

**Com janela:** prints da tela com o Ruvo dos dois lados, em 1× e em 2×.

**Visto pelo dono no jogo:** o Ruvo ("já testei o ruvo e ta ok").

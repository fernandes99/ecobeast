# 03. As folhas dos médios

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02-small-sheets](02-small-sheets.md)

## Contexto

Os médios ganham 4 pixels, de 13–16 para 17–20. Nesse tamanho cabem o contorno, olhos de 2 pixels e as patas desenhadas por posição, como a skill já faz. O que muda é o tamanho e o acabamento novo, com até 3 tons por material e até 16 cores.

## Escopo

As folhas `idle.png` e `walk.png` de Explorar destes quatro, desenhadas de novo pelo `sprites.py` de cada um, com a skill `creature-sprites`:

| Ecobeast | Pasta | Altura | Hoje |
| --- | --- | --- | --- |
| Nilgar | `client/assets/creatures/nilgar/explore/` | 17 | 13 |
| Ruvak | `client/assets/creatures/ruvak/explore/` | 19 | 15 |
| Grovequill | `client/assets/creatures/grovequill/explore/` | 19 | 15 |
| Kelpcoil | `client/assets/creatures/kelpcoil/explore/` | 20 | 16 |

## Fora do escopo

- As folhas da luta (`battle/`), inclusive o idle do Ruvak que veio do PixelLab.
- As folhas dos grandes: a fase [04](04-large-sheets.md).

## Requisitos

- **RF-01:** Cada folha tem a altura da regra nova, conferida pelo `check_sheets.py`, no formato de hoje.
- **RF-02:** Cada folha segue o acabamento novo da skill.
- **RF-03:** A largura cabe na célula: o Nilgar, que hoje tem 22 pixels de largura, chega a uns 29 e cabe sem compactar.
- **RF-04:** Cada criatura mantém o que a torna reconhecível no `front.png` e a anatomia das folhas de hoje:
  - o Nilgar é um caranguejo de patas curtas e pinças encostadas na frente do corpo;
  - o Ruvak anda em quatro patas, com a chama;
  - o Grovequill é uma ave-dinossauro de duas pernas, com a cauda longa de folhas;
  - o Kelpcoil flutua em pé, com a cauda enrolada no chão.

## Critérios de aceite

- [x] O `check_sheets.py` passa nas 4 pastas, com o servidor no ar.
- [x] Os GIFs de prévia mostram as 5 vistas animadas, sem parte solta.
- [ ] No jogo (F5), o spawn do menu Debug de Explorar mostra os 4 no tamanho da tabela, maiores que os pequenos da fase 02 e menores que o Domador.

## Desenho técnico

- `client/assets/creatures/<slug>/explore/sprites.py`: o desenho de hoje cresce pelo `stretched` (fase [01](01-scale-rule.md#o-que-entrou-a-mais-na-implementação)), repetindo linhas lisas da testa, dos olhos, do tronco, das patas, das asas e da cauda, com as posições das partes refeitas. Esses já tinham o contorno escuro e o sombreado do acabamento pedido, e o dono tinha aprovado o desenho deles; a largura não cresce, para caber nos 32 pixels.
- `idle.png`, `walk.png` e os `.import` gerados de novo.
- Nenhum script do jogo muda.

## Verificação

A mesma da fase [02](02-small-sheets.md#verificação), para estes 4.

## Tarefas

- [x] Nilgar.
- [x] Ruvak.
- [x] Grovequill.
- [x] Kelpcoil.
- [x] Importar no Godot (falta o dono conferir no spawn) e marcar a fase como concluída aqui, na [README](README.md), no `.specs/README.md` e no `.specs/roadmap.md`.

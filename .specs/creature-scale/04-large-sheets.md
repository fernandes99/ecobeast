# 04. As folhas dos grandes

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [03-medium-sheets](03-medium-sheets.md)

## Contexto

Os grandes ganham de 3 a 4 pixels e chegam perto do limite da célula de 32×32. O Tempestide, com 2,0 m, encosta no máximo de 32 pixels. Crescendo na proporção, o Ruvaroth teria 35 pixels de largura e o Nilgorr 33, mais que a célula. Por isso, os dois ficam mais compactos (decisão na [README](README.md#decisões)).

## Escopo

As folhas `idle.png` e `walk.png` de Explorar destes seis, desenhadas de novo pelo `sprites.py` de cada um, com a skill `creature-sprites`:

| Ecobeast | Pasta | Altura | Hoje | Largura de hoje |
| --- | --- | --- | --- | --- |
| Nilgorr | `client/assets/creatures/nilgorr/explore/` | 26 | 22 | 28 |
| Galecrest | `client/assets/creatures/galecrest/explore/` | 26 | 22 | 23 |
| Ruvaroth | `client/assets/creatures/ruvaroth/explore/` | 28 | 24 | 30 |
| Echofrost | `client/assets/creatures/echofrost/explore/` | 29 | 25 | 26 |
| Arbornix | `client/assets/creatures/arbornix/explore/` | 30 | 26 | 27 |
| Tempestide | `client/assets/creatures/tempestide/explore/` | 32 | 29 | 24 |

## Fora do escopo

- As folhas da luta (`battle/`).
- Trocar o tamanho da célula.

## Requisitos

- **RF-01:** Cada folha tem a altura da regra nova, conferida pelo `check_sheets.py`, no formato de hoje.
- **RF-02:** Cada folha segue o acabamento novo da skill.
- **RF-03:** Em todo quadro, a criatura cabe nos 32 pixels de largura sem corte:
  - o Ruvaroth traz a cauda e a chama mais perto do corpo;
  - o Nilgorr traz as pinças mais perto do corpo, sem as patas longas que o fariam parecer uma água-viva (item da skill).
- **RF-04:** O Tempestide ocupa a célula inteira na altura. Nada dele sobe acima da primeira linha, então o balanço do idle desce, nunca sobe.
- **RF-05:** Cada criatura mantém o que a torna reconhecível no `front.png` e a anatomia das folhas de hoje.

## Critérios de aceite

- [x] O `check_sheets.py` passa nas 6 pastas, com o servidor no ar.
- [x] Nenhum quadro das 12 folhas tem pixel na primeira ou na última coluna cortando a criatura, e o Tempestide não perde os chifres em nenhum quadro.
- [x] Os GIFs de prévia mostram as 5 vistas animadas, sem parte solta.
- [ ] No jogo (F5), o spawn do menu Debug de Explorar mostra os 6 no tamanho da tabela. O Ruvaroth, o Echofrost, o Arbornix e o Tempestide ficam um pouco mais altos que o Domador.

## Desenho técnico

- `client/assets/creatures/<slug>/explore/sprites.py`: o desenho de hoje cresce pelo `stretched` (fase [01](01-scale-rule.md#o-que-entrou-a-mais-na-implementação)), repetindo linhas lisas da testa, dos olhos, do tronco, das patas, das asas e da cauda, com as posições das partes refeitas. Esses já tinham o contorno escuro e o sombreado do acabamento pedido, e o dono tinha aprovado o desenho deles; a largura não cresce, para caber nos 32 pixels.
- `idle.png`, `walk.png` e os `.import` gerados de novo.
- Nenhum script do jogo muda.

## Verificação

A mesma da fase [02](02-small-sheets.md#verificação), para estes 6. Com a fase concluída, rodar o `check_sheets.py` nas 16 pastas de `client/assets/creatures/*/explore/`: todas passam.

## Tarefas

- [x] Nilgorr.
- [x] Galecrest.
- [x] Ruvaroth.
- [x] Echofrost.
- [x] Arbornix.
- [x] Tempestide.
- [x] Importar no Godot (falta o dono conferir no spawn), rodar a conferência nas 16 pastas e marcar a fase e a iniciativa como concluídas aqui, na [README](README.md), no `.specs/README.md`, no `.specs/roadmap.md` e no resumo do `CLAUDE.md` da raiz.

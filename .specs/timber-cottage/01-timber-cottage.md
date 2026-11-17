# 01. A casinha enxaimel

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-props](../free-props/) (as peças soltas) e [day-night](../day-night/) (as luzes das peças)

## Contexto

O dono quer a casa enxaimel da imagem dele nas ilhas, com as cores das outras casas ([README](README.md#contexto)).

## Escopo

- O script `client/assets/props/make_timber_cottage.py`, a imagem `art-source/timber_cottage/reference.png` e a arte `assets/props/timber_cottage/`.
- O tipo de peça 100, com o bloqueio padrão e a luz da janela, na migração `20261229000000_timber_cottage` e na carga inicial.

## Requisitos

- **RF-01:** `python -I make_timber_cottage.py`, de dentro de `client/assets/props`, lê a cor de cada pixel da arte pela mediana dos 3×3 pixels do meio dele na imagem (a grade começa em (203,79; 28,22) e anda 5,12 pixels), junta as cores a menos de 14 em cada canal, apaga o fundo branco, recorta pelos pixels (120×134), dá o material a cada pixel (RF-02), reduz a arte a 70% (RF-03), troca as cores pelas da Casa grande e grava `timber_cottage/1.png` a `8.png` (86×96).
- **RF-02:** Cada cor ganha um material pelo matiz, pela saturação e pelo valor: contorno (quase preto), vidro (azul), pedra (cinza), reboco (claro e pouco saturado), telha (vermelho saturado) e madeira (o resto). Os ajustes por lugar:
  - o vermelho na moldura da janela (x de 78 a 99, y de 90 a 110) é madeira, e o azul fora dela é pedra;
  - a telha e, nos 60% de cima, a pedra com menos de 40% do mesmo material nos 5×5 em volta são soltas e ficam com o material da maioria em volta, como os escuros que podem ser de telha ou de madeira; o vidro não conta nessa maioria.
- **RF-03:** A redução (pedido do dono em 2026-11-17: "a casa ficou desproporcional, ficou muito maior") leva os 120×134 a 84×94 (`SIZE` 0,7). Cada pixel novo fica com a cor e o material que mais cobrem a área dele na arte grande, com o contorno e as cores de brilho abaixo de 70 valendo 2,5 vezes (`DARK_VOTE`), para os traços de 1 px das telhas e das vigas não sumirem.
- **RF-04:** Em cada material, as cores da imagem, do claro ao escuro, viram os tons da Casa grande (`big_house/1.png`) na mesma proporção de pixels que eles têm lá (`RAMPS`). O contorno vira o escuro do material da maioria em volta: o da telha (`3f1428`), o da madeira (`482a2a`), o da pedra (`28282e`) e o do reboco (`423432`). A sombra translúcida da Casa grande (`(53, 53, 43, 89)`) fica 1 px do lado das paredes, abaixo do beiral, e nas 2 linhas de baixo, menos sob a porta.
- **RF-05:** As variantes são as 8 cores da Casa grande, pelos mesmos grupos de cor (telhado, pedra e creme, que aqui é o reboco) e as mesmas regras do `make_houses.py` ([home-pack/03](../home-pack/03-house-shapes.md#requisitos)). A madeira e o vidro não mudam de cor.
- **RF-06:** O tipo de peça 100 é `timber_cottage`, "Casinha enxaimel", com 8 variantes. O bloqueio padrão (variante 0) é o retângulo fechado de (−39, −2) a (38, −16) em volta do pé, e a luz (variante 0, todas as cores) fica no meio da janela, em (20, −26), com raio 9 e a cor `ffcf70` das janelas das outras casas.

## Critérios de aceite

- [ ] A ferramenta Peças do editor mostra a Casinha enxaimel, com as 8 cores pelas teclas ← →, espelhada ou não.
- [ ] O Domador para no pé da casa e passa atrás dela, coberto pelo telhado.
- [ ] À noite, a janela acende.
- [x] `GET /v1/catalog` traz o tipo 100, o bloqueio e a luz dele.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script.
- [x] O teste das tabelas do catálogo passa.

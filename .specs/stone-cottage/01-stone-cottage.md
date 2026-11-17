# 01. A casinha de pedra

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-props](../free-props/) (as peças soltas)

## Contexto

O dono quer a casinha da imagem dele nas ilhas ([README](README.md#contexto)).

## Escopo

- O script `client/assets/props/make_stone_cottage.py`, a imagem `art-source/stone_cottage/reference.png` e a arte `assets/props/stone_cottage/`.
- O tipo de peça 99, com o bloqueio padrão, na migração `20261225000000_stone_cottage` e na carga inicial.

## Requisitos

- **RF-01:** `python -I make_stone_cottage.py`, de dentro de `client/assets/props`, lê a cor de cada pixel da arte pela mediana dos 4×4 pixels do meio dele na imagem (a grade começa em (306,9; 5,8) e anda 8,53 pixels), junta as cores a menos de 16 em cada canal, apaga o fundo branco e o que não é contorno e encosta no fundo por fora do contorno preto (as sobras da suavização), recorta pelos pixels (48×66), troca as cores pelas da Casa grande e grava `stone_cottage/1.png` a `8.png` (50×68).
- **RF-02:** A casinha usa a paleta da Casa grande (`big_house/1.png`), pedido do dono em 2026-11-17 ("o contorno de fora é um preto muito forte comparado da casa a direita"):
  - cada cor da imagem vira a da Casa grande pelo papel do pixel (`TONES`): a água da esquerda do telhado, mais clara, a da direita, mais escura, a cumeeira (x de 22 a 25, até a linha 28, com a coluna da esquerda mais clara), a pedra, a soleira e a porta (x de 17 a 31 e y de 45 a 64, menos a pedra do arco);
  - o contorno preto vira o escuro da parte vizinha, nesta ordem: o da porta (`482a2a`), o da soleira (`423432`), o do telhado (`3f1428`) e o da pedra (`28282e`);
  - a sombra translúcida da Casa grande (`(53, 53, 43, 89)`) fica 1 px do lado das paredes, abaixo do beiral, e nas 2 linhas de baixo, menos sob a porta.
- **RF-03:** As variantes são as 8 cores da Casa grande, pelos mesmos grupos de cor (telhado, pedra e creme, que aqui é a soleira) e as mesmas regras do `make_houses.py` ([home-pack/03](../home-pack/03-house-shapes.md#requisitos)).
- **RF-04:** O tipo de peça 99 é `stone_cottage`, "Casinha de pedra", com 8 variantes. O bloqueio padrão (variante 0) é o retângulo fechado de (−21, −2) a (20, −16) em volta do pé.

## Critérios de aceite

- [ ] A ferramenta Peças do editor mostra a Casinha de pedra, com as 8 cores pelas teclas ← →, espelhada ou não.
- [ ] O Domador para no pé da casinha e passa atrás dela, coberto pelo telhado.
- [x] `GET /v1/catalog` traz o tipo 99 e o bloqueio dele.
- [x] `godot --headless -d --path client --quit-after 240` roda sem erro de script.
- [x] Os testes do servidor passam.

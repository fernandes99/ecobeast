# 01. A casa grande com a fumaça

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-objects/04](../free-objects/04-objects-to-props.md), [prop-depth-blocks/01](../prop-depth-blocks/01-depth-order.md)

## Contexto

O dono quer a casa grande do pacote Main Characters Home nas ilhas, com a fumaça da chaminé animada ([README](README.md#contexto)).

## Escopo

- O script `client/assets/props/make_big_house.py` (hoje `make_houses.py`, [03](03-house-shapes.md)) e a arte `assets/props/big_house/`.
- O tipo de peça 95, com o bloqueio padrão, na migração `20261216000000_home_pack` e na carga inicial.
- A fumaça no `HexMapView` e no shader `plant_wind.gdshader`.

## Requisitos

- **RF-01:** `python -I make_big_house.py <pasta PNG do pacote>`, de dentro de `client/assets/props`, grava:
  - `big_house/1.png`: a casa de `exterior.png` (131×128), recortada pelos pixels ligados a ela até a linha 127, sem mudar nenhum;
  - `big_house/smoke.png`: os 6 quadros de 48×48 de `Smoke_animation.png`, lado a lado, com o canto do quadro em (16, −16) da folha `exterior.png`. Sai todo pixel igual ao da casa embaixo, e fica só a fumaça.
- **RF-02:** O tipo de peça 95 é `big_house`, "Casa grande", com 1 variante. O bloqueio padrão (variante 0) é o retângulo fechado de (−60, −2) a (61, −44) em volta do pé.
- **RF-03:** O `HexMapView` desenha a fumaça logo depois da casa, na mesma faixa, pela `PROP_SMOKE`: o canto do quadro em (−63, −144) do pé, que vira (`largura % 2` + 63 − 48, −144) na casa espelhada, com a textura invertida.
- **RF-04:** A fumaça troca de quadro no shader das plantas: `CUSTOM1` é (2, quadros, quadros por segundo, 0), e o quadro é `floor(TIME × 6 + ruído do pé × 6) mod 6`. Cada casa começa num ponto do ciclo.
- **RF-05:** Os créditos do pacote ficam em `client/assets/props/CREDITOS.md`.

## Critérios de aceite

- [ ] A ferramenta Peças do editor mostra a Casa grande, e ela fica no mapa, espelhada ou não.
- [ ] A fumaça sai da chaminé em loop, e duas casas não soltam a fumaça juntas.
- [ ] O Domador para no pé da casa e passa atrás dela, coberto pelo telhado.
- [ ] `godot --headless --path client --quit-after 60` roda sem erro de script.

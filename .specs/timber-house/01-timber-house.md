# 01. A casa enxaimel

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [home-pack/03](../home-pack/03-house-shapes.md), [day-night/03](../day-night/03-night-lights.md)

## Contexto

O dono quer a casa do pacote Glassblower's Workshop nas ilhas, em várias cores ([README](README.md#contexto)).

## Escopo

- O script `client/assets/props/make_timber_house.py` e a arte `assets/props/timber_house/`.
- O tipo de peça 98, com o bloqueio padrão e as luzes, na migração `20261223000000_timber_house` e na carga inicial.
- A fumaça na `HexMapView.PROP_SMOKE` e o tipo no `find_lights.py`.

## Requisitos

- **RF-01:** `python -I make_timber_house.py <pasta Tiled_files do pacote>`, de dentro de `client/assets/props`, cola as camadas `Walls`, `Windows_top`, `Roof`, `stovepipe` e `Roof_detail` do `Exterior.tmx`, na ordem, com o tile de cada gid (o primeiro quadro dos animados), recorta pelos pixels e grava `timber_house/1.png` a `8.png` (129×149) e `timber_house/smoke.png`, a cópia de `big_house/smoke.png`.
- **RF-02:** As variantes são as cores: 1 a original (telhado vermelho); 2 telhado azul; 3 telhado verde e pedra cor de areia; 4 telha de madeira escura, madeira mais escura e reboco branco; 5 ardósia, madeira acinzentada e pedra escura; 6 telhado roxo; 7 telhado verde-água e madeira clara; 8 telhado laranja e pedra quente. Cada pixel cai num grupo pelo matiz e pela saturação (telhado: saturação ≥ 0,5 e matiz ≥ 320°; madeira: saturação ≥ 0,42 e matiz < 45°; pedra e reboco: saturação < 0,32 e matiz < 40° ou > 340°, o reboco com valor ≥ 0,7), e só os grupos da variante mudam, mantendo a luz e a sombra de cada pixel. Os vidros, a sombra translúcida e o resto ficam iguais.
- **RF-03:** O tipo de peça 98 é `timber_house`, "Casa enxaimel", com 8 variantes. O bloqueio padrão (variante 0) é o retângulo fechado de (−53, −3) a (52, −44) em volta do pé.
- **RF-04:** A fumaça fica com o canto do quadro em (−41, −179) do pé, com a boca da chaminé da casa enxaimel no lugar da boca da Casa grande.
- **RF-05:** As luzes da noite (variante 0, cor `ffcf70`) ficam na janela do frontão (0, −94, raio 11), nas duas do andar de madeira (±19, −54, raio 9) e nas duas de baixo (−25 e 24, −24, raio 9), achadas pelo `find_lights.py`, que passa a ignorar um grupo de vidro com menos de 4 px num lado (as maçanetas).
- **RF-06:** Os créditos do pacote ficam em `client/assets/props/CREDITOS.md`.

## Critérios de aceite

- [ ] A ferramenta Peças do editor mostra a Casa enxaimel, com as 8 cores pelas teclas ← →, espelhada ou não.
- [ ] A fumaça sai da chaminé em loop, espelhada ou não.
- [ ] À noite, as 5 janelas acendem.
- [ ] O Domador para no pé da casa e passa atrás dela, coberto pelo telhado.
- [ ] `godot --headless --path client --quit-after 60` roda sem erro de script.

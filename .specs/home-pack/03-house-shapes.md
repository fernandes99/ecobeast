# 03. As cores e os formatos das casas

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [01-big-house](01-big-house.md)

## Contexto

Em 2026-11-15, o dono perguntou se dava para gerar mais casas com o pacote. Claude mostrou duas prévias: 8 cores (telhado, pedra e frontão) e 7 formatos remontados com os pixels do pacote, sem desenhar nenhum novo. O dono pediu: "mantém a pequena e o sobrado pequeno. o resto descarta, salve com as variações de cores nesses dois também". As 7 cores novas já tinham sido aprovadas ("pode manter as que foram alteradas apenas a cor").

## Escopo

- O `client/assets/props/make_houses.py` (antes `make_big_house.py`), que grava os 3 formatos em 8 cores.
- Os tipos de peça 96 e 97 e as 8 variantes do 95, com o bloqueio dos novos, na migração `20261217000000_house_shapes` e na carga inicial.
- A fumaça dos formatos novos na `HexMapView.PROP_SMOKE`.

## Requisitos

- **RF-01:** `python -I make_houses.py <pasta PNG do pacote>`, de dentro de `client/assets/props`, grava `<formato>/1.png` a `8.png` e `<formato>/smoke.png` (a fumaça da [01](01-big-house.md#requisitos)) para:

  | Tipo | Formato | Arte |
  | --- | --- | --- |
  | 95 `big_house`, "Casa grande" | a casa do pacote | 131×128 |
  | 96 `small_house`, "Casa pequena" | sem 30 colunas da ala direita (o telhado do resto sobe 10 px, 1 a cada 3, como a inclinação dele) e com a parede janela, janela, porta, janela | 101×128 |
  | 97 `small_townhouse`, "Sobrado pequeno" | a pequena com um andar de 20 linhas a partir da linha 100, de janelas, com uma janela em cima da porta | 101×148 |

  A parede de cada coluna vem de uma coluna da casa do pacote, a partir da primeira pedra abaixo do beiral; onde o beiral fica mais alto que a parede de origem, a pedra de cima se repete.
- **RF-02:** As variantes são as cores, iguais nos 3 formatos: 1 a original; 2 telhado azul; 3 telhado verde e pedra cor de areia; 4 telha de madeira e frontão branco; 5 ardósia e pedra escura; 6 telhado roxo; 7 telhado verde-água e frontão azulado; 8 telhado laranja e pedra quente. Só as cores do telhado, da pedra (a chaminé junto) e do frontão mudam, pelo matiz, mantendo a luz e a sombra de cada pixel.
- **RF-03:** O tipo 95 passa a ter 8 variantes. O 96 e o 97 bloqueiam pelo retângulo fechado de (−45, −2) a (43, −44) em volta do pé.
- **RF-04:** A fumaça fica com o canto do quadro em (−63, −144) do pé na Casa grande, (−48, −144) na Casa pequena e (−48, −164) no Sobrado pequeno.

## Critérios de aceite

- [ ] A ferramenta Peças tem a Casa grande, a Casa pequena e o Sobrado pequeno, com as 8 cores pelas teclas ← →.
- [ ] A fumaça sai da chaminé nos 3, espelhados ou não.
- [ ] O Domador para no pé de cada uma.
- [ ] `godot --headless --path client --quit-after 60` roda sem erro de script.

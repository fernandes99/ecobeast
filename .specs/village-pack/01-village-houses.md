# 01. As casas da vila

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [home-pack/03](../home-pack/03-house-shapes.md), [day-night/03](../day-night/03-night-lights.md)

## Contexto

O dono quer o máximo de casas do tileset Village, em tamanhos diferentes e em 8 cores ([README](README.md#contexto)). O pacote não tem a casa pronta: o telhado, o corpo, a frente de frontão, a porta, as janelas e a chaminé são tiles separados.

## Escopo

- O script `client/assets/props/make_village_houses.py`, a prévia e a arte `assets/props/village_<formato>/`.
- Os tipos de peça 102 a 111, com o bloqueio e as luzes, na migração `20270111000000_village_houses`.
- A fumaça na `HexMapView.PROP_SMOKE`, os tipos no `find_lights.py` e no `LUZES.md`, e os créditos em `assets/props/CREDITOS.md`.

## Requisitos

- **RF-01:** `python -I make_village_houses.py <FDR_Village.png> [--preview <arquivo>]`, de dentro de `client/assets/props`, monta cada formato colando tiles da folha, sem desenhar pixel novo:
  - o telhado da cor do pacote (vermelho, azul ou ardósia) do formato, ou um pedaço dele repetido para esticar uma ala;
  - o corpo de reboco e postes por baixo, esticado pela coluna do meio de uma parede lisa;
  - a porta fechada no batente de madeira (o primeiro quadro) no meio do frontão;
  - uma janela de vidro em cada ala (o tile de vidro azul de 16×16), e no frontão, acima da porta, quando houver espaço;
  - a chaminé de pedra numa ala (ou no lado do telhado, na casinha), por baixo do telhado onde ela some atrás dele.
  Recorta pelos pixels e grava `village_<formato>/1.png` a `8.png` e `smoke.png` (a cópia de `big_house/smoke.png`), e imprime o tamanho de cada formato e o canto do quadro da fumaça em relação ao pé.
- **RF-02:** Com `--preview`, o script não grava as pastas: grava uma folha com todos os formatos candidatos na cor 1, lado a lado sobre um fundo de grama, com o Domador ao lado para a escala e o nome de cada um. Os candidatos:

  | Formato | Nome | Como monta |
  | --- | --- | --- |
  | `cottage` | Casinha da vila | o frontão só, com a parede baixa |
  | `house` | Casa da vila | o frontão e uma ala curta, com a parede baixa |
  | `wing_house` | Casa de ala comprida | o frontão e uma ala comprida |
  | `manor` | Casa grande da vila | a casa larga do pacote, com o frontão e duas alas |
  | `longhouse` | Casa comprida da vila | a casa com as alas compridas do pacote |
  | `townhouse` | Sobrado da vila | a casinha com um andar a mais |
  | `large_townhouse` | Sobrado grande da vila | a casa grande com um andar a mais |
  | `long_townhouse` | Sobrado comprido da vila | a casa comprida com um andar a mais |
  | `twin_house` | Casa de dois frontões | dois frontões, com uma ala entre eles |
  | `row_house` | Casa de três frontões | três frontões, com uma ala entre cada dois |

  A parede alta é a do pacote (16 px a mais que a baixa); o andar a mais repete 20 linhas da parede lisa. Fora a casinha e a casa da vila, todas têm a parede alta e a janela redonda no frontão.

  O dono escolheu pela prévia os 10, que ganham os ids 102 a 111, na ordem da tabela, e o slug `village_<formato>`.
- **RF-03:** As variantes são as cores, na numeração das outras casas: 1 vermelho (do pacote), 2 azul (do pacote), 3 verde, 4 telha de madeira escura com reboco mais branco, 5 ardósia (do pacote), 6 roxo, 7 verde-água, 8 laranja. As cores 3, 4, 6, 7 e 8 repintam o telhado vermelho pelo matiz, mantendo a luz e a sombra de cada pixel, como o `make_timber_house.py`. O vidro, a madeira dos postes e a pedra da chaminé não mudam, menos onde a cor diz.
- **RF-04:** Cada tipo tem 8 variantes, e o bloqueio padrão (variante 0) é o retângulo fechado da base: das colunas da arte nas 20 linhas de baixo, menos 2 px de cada lado, de 2 px acima do pé até 14 px acima dele.
- **RF-05:** Todo formato tem chaminé, e a fumaça entra na `PROP_SMOKE` com o canto impresso pelo script (a boca 2 px abaixo do topo da chaminé, no ponto (21, 38) do quadro da fumaça da `big_house`), `size` 48, 6 quadros e 6 por segundo, e respeita o `no_smoke` da peça.
- **RF-06:** As luzes da noite saem do `find_lights.py`, com os formatos novos em `TYPES`: uma em cada janela de vidro e na redonda do frontão, com a cor `ffcf70` das outras casas (31 luzes; a Casinha da vila não tem janela de vidro e fica sem luz). O telhado azul (cor 2) não vira janela pela regra de hoje (grupo largo nos 45% de cima). O JSON novo se compara ao de antes, e só as linhas dos tipos novos mudam.
- **RF-07:** Os créditos do pacote (nome, autor e a licença que o dono confirmar) ficam em `client/assets/props/CREDITOS.md`.

## Critérios de aceite

- [x] O dono escolheu os formatos pela prévia.
- [ ] A ferramenta Peças do editor mostra cada casa escolhida, com as 8 cores pelas teclas ← →, espelhada ou não.
- [ ] A fumaça sai da chaminé em loop, espelhada ou não, e o botão da fumaça a desliga.
- [ ] À noite, as janelas de vidro acendem.
- [ ] O Domador para no pé da casa e passa atrás dela, coberto pelo telhado.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script, e os testes do servidor passam.

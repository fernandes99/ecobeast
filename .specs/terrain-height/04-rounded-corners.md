# 04. As pontas arredondadas

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [03-height-visibility](03-height-visibility.md), [water-motion](../water-motion/)

## Contexto

Onde a altura ou o bioma muda, a ponta do hexágono aparece inteira: no alto do platô, no paredão e na beira da água. O dono quer o terreno mais natural, com essas pontas arredondadas, sem mudar a grade. Nasceu de um teste, em 2026-11-14, e ficou.

## Requisitos

- **RF-01:** em cada canto, quem é diferente dos outros dois hexágonos (primeiro pela altura e, com as três iguais, pelo bioma; fora do mapa conta como mais baixo) perde a ponta num arco de 6 px de raio, e os dois iguais avançam sobre ela com o mesmo arco, cada um até a reta que continua o lado entre eles.
- **RF-02:** com três alturas diferentes, o mais alto perde a ponta e os outros dois avançam. Com três biomas diferentes na mesma altura, o canto fica reto.
- **RF-03:** o paredão, a cachoeira e os escorridos seguem o contorno arredondado; a sombra do paredão vai da clara (borda da esquerda) à escura (borda da direita) pela curva.
- **RF-04:** é só o desenho. A grade, o toque (`coord_at`), a altura dos atores e das peças, as regras e o servidor não mudam.
- **RF-05:** o menu Debug do mapa tem a chave "Pontas: arredondadas / retas" (`HexMapView.rounded_corners`, ligada por padrão).

## Fora do escopo

- A espuma da praia, as transições entre biomas, o chão das trilhas e o contorno continuam pelo lado reto do hexágono.

## Resultado

- `ui/components/hex_rounding.gd` (`HexRounding.shape_of`) monta a forma de cada hexágono: os triângulos da superfície e os lados com o vizinho de cada um. O `HexMapView` a usa no `_add_surface`, no `_add_faces`, no `_add_waterfalls` e no `_add_drips`. O raio é `HexRounding.RADIUS`.
- Conferido numa cena temporária com platôs de 3 alturas, a pedra, um lago e a beira da ilha. O raio começou em 18 px e foi a 9 e depois a 6, a pedido do dono.
- **Não conferido:** o editor aberto e o tempo de montar uma ilha grande (um hexágono com cantos arredondados tem de 10 a 20 triângulos, contra 4).

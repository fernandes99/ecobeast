# 03. A espuma da praia mais sutil e animada

- **Status:** concluída
- **Depende de:** [01-water-surface](01-water-surface.md), [wild-battle/09](../wild-battle/09-biome-transitions.md)

## Contexto

A água ao lado da terra recebe a espuma da praia pelas transições (`HexTransitions`, linha `foam` de `transitions.png`), em todas as bordas com terra. Com um vizinho mais alto na frente, a espuma subia até a borda de cima dele ([wild-battle/09](../wild-battle/09-biome-transitions.md), RF-07). O dono, em 2026-11-14, vendo a ilha: a espuma não deve subir para a borda de cima de um campo mais alto que a água, deve ficar no pé do barranco da terra de trás, e deve ser mais sutil e ter animação.

## Escopo

- Sem espuma subindo para a borda de cima de um vizinho mais alto na frente.
- A espuma mais fraca e mexendo.

## Fora do escopo

- A arte da espuma em `transitions.png` e os arremates entre terras.

## Requisitos

- **RF-01:** a água não recebe espuma na borda de baixo cujo vizinho da frente é mais alto (a espuma não sobe mais a diferença de altura); fica como a terra, que já não recebia arremate aí. As bordas de cima da água, no pé do barranco da terra de trás, e as bordas com terra da mesma altura continuam com espuma. Isso substitui o RF-07 da [wild-battle/09](../wild-battle/09-biome-transitions.md) para a água.
- **RF-02:** a espuma fica translúcida, com 55% da opacidade de antes.
- **RF-03:** uma onda corre pela costa, apagando e acendendo os pixels da espuma, em passos de 1/6 s. Os pixels se apagam sempre na mesma ordem (um sorteio fixo por pixel), então a espuma afina e engrossa, sem piscar. O ciclo fecha quando o `TIME` volta a zero.

Números de partida: onda de 40 px de comprimento, a 0,25 volta por segundo; na parte fraca da onda, sobra 1 pixel de cada 4.

## Critérios de aceite

- [x] A água atrás de uma pedra mais alta não tem a linha clara na borda de cima da pedra, e a água na frente de um barranco de grama tem a espuma no pé dele.
- [x] A espuma das outras bordas está mais fraca e muda entre fotos tiradas com 0,7 s de intervalo.
- [x] Os arremates entre terras estão iguais.

## Desenho técnico

- `hex_transitions.gd`: no `transitions_of`, o vizinho da frente mais alto corta o arremate também para a água; e `is_foam(transition)`. O `_front_lift` do `HexMapView`, que subia a espuma, saiu.
- `hex_map_view.gd`: o `_add_transitions` põe a espuma numa malha própria, com o código 7 (`SHORE_CODE`) no `CUSTOM0.w`.
- `hex_grounds.gdshader`: o código 7, que usa o ponto da arte (`art_point`) para o sorteio e para a onda, e baixa o alfa.

## Resultado

- Conferido numa cena temporária com um lago raso no meio da grama e um mar fundo, em fotos ampliadas com 0,7 s de intervalo, e com água entre um barranco de grama atrás e uma pedra de altura 3 na frente.
- O contorno dos hexágonos, a pedido do dono, na mesma revisão: fica desligado, e o botão "Contorno" do menu Debug do mapa ([wild-battle/13](../wild-battle/13-debug-menu.md)) o liga e desliga na hora (`HexMapView.contour_visible`, estático, e `set_contour_visible`, que remonta as linhas). Ligado, ele tem metade da opacidade de antes (`CONTOUR_ALPHA`, 0,5). A escolha vale até fechar o jogo, no jogo e no editor, que tem a mesma chave no painel Camadas (`EditorCanvas.set_contour`).
- **Não conferido:** no editor e no celular.

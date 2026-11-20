# 02. As Esferas em pixel art

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [01-tonics-balm](01-tonics-balm.md)

## Contexto

Claude escreveu o prompt para o Gemini, com as 3 Esferas lado a lado, ampliadas 8 vezes, num fundo magenta chapado (#FF00FF), sem as metades vermelha e branca nem o botão de uma bola de captura conhecida. O dono gerou duas versões, e Claude reduziu as duas a 32×32 com o `from_sheet.py`. Depois o dono mandou as Esferas da segunda versão já em 32×32, dizendo: "esses aqui já tem um tamanho mais ideal". São essas que ficam.

## Requisitos

- **RF-01:** `bond_sphere.png`, `reinforced_sphere.png` e `supreme_sphere.png` são as imagens de 32×32 do dono, com os pixels como vieram, menos os de alfa abaixo de 16 (pontos soltos invisíveis, que tiravam a Esfera do centro), e deslocadas para ficar centradas na largura com 1 px livre embaixo, como os frascos. Ficam com 23×24, 20×22 e 28×26 px visíveis.
- **RF-02:** A tela de captura (`capture_overlay.tscn`) mostra a Esfera em 128 px, no mesmo centro de antes, e a marca de capturado do Bestiário (`codex_cell.tscn`), em 32 px, com o filtro mais próximo.
- **RF-03:** O `client/assets/items/from_sheet.py` faz ícones de 32×32 de uma imagem de IA com os objetos lado a lado, de fundo transparente ou magenta: reduz todos pelo mesmo fator, com cada pixel novo pegando a cor que mais cobre a área dele numa paleta de 18 cores do objeto, o que vale também quando a IA desenha pixels de tamanhos diferentes.

## Decisões

| Decisão | Quem | Motivo |
| --- | --- | --- |
| As Esferas ficam menores que os frascos (de 22 a 26 px de altura, abaixo dos 24 a 30 do padrão) | Dono | "esses aqui já tem um tamanho mais ideal" |

## Critérios de aceite

- [ ] Na Loja, na Mochila, na captura e no Bestiário, as Esferas aparecem nítidas e centradas.
- [ ] O jogo abre os ícones sem erro.

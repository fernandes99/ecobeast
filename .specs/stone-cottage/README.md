# stone-cottage

A casinha de pedra com telhado vermelho que o dono mandou em imagem entra nas ilhas como peça solta, em 8 cores.

## Contexto

Em 2026-11-17, o dono mandou a imagem de uma casinha em pixel art e pediu: "Monte um objeto que é esse aqui". A primeira imagem veio pequena e borrada, e ele mandou uma maior, que virou a fonte (`art-source/stone_cottage/reference.png`).

A casinha tem uma parede de pedra azulada com porta de madeira em arco, telhado de telhas vermelhas com cumeeira e contorno preto. Ela não tem janela nem chaminé. Na imagem, cada pixel da arte ocupa uns 8,53 pixels, com as bordas suavizadas, e a arte tem 48×66 pixels.

## Objetivos

1. A casinha é uma peça solta, posta pela ferramenta Peças, espelhável e com um bloqueio no pé.
2. As 8 cores são as variantes dela, trocadas pelas teclas ← → do editor.
3. A arte sai de um script que lê a imagem do dono, sem desenhar pixel novo.

## Anti-objetivos

- As peças de antes não mudam.
- A casinha não ganha ação; o editor pode dar uma pela lista Ação, como a qualquer peça.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A casinha é o tipo de peça 99 (`stone_cottage`, "Casinha de pedra") | O 98 é o último tipo |
| A arte fica no tamanho dos pixels dela, 48×66 (50×68 com a sombra), sem ampliar | Um pixel da arte é um pixel do mapa, como nas outras peças. A porta fica da altura do Domador |
| A paleta, o contorno colorido, a sombra e as 8 cores são os da Casa grande ([home-pack/03](../home-pack/03-house-shapes.md)) | O dono pediu: o contorno preto da imagem destoava da Casa grande. As casas ficam combinando numa vila |
| Sem fumaça e sem luzes à noite | A casinha não tem chaminé nem janela |
| A arte fica fora do [guia de estilo da cidade](../town-art/style-guide.md) | É a arte do dono, como o Observatório |

## Fora do escopo

- A casinha no mapa sorteado.
- Uma luz na porta à noite.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-stone-cottage](01-stone-cottage.md) | A casinha como peça 99, em 8 cores, com o bloqueio no pé | concluída (falta o dono conferir) |

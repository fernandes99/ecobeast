# timber-cottage

A casinha enxaimel de telhado vermelho que o dono mandou em imagem entra nas ilhas como peça solta, em 8 cores.

## Contexto

Em 2026-11-17, o dono mandou a imagem de uma casa enxaimel em pixel art e pediu: "Faça uma casa com as variantes de cores e seguindo o padrão das outras". A imagem virou a fonte (`art-source/timber_cottage/reference.png`).

A casa é vista de frente, com telhado de telhas vermelhas em duas águas, uma viga no meio que sobe até a cumeeira, o oitão de reboco claro com vigas em X, a porta de tábuas, uma janela de 4 vidros e a base de pedra cinza. Ela não tem chaminé. Na imagem, cada pixel da arte ocupa 5,12 pixels, com as bordas suavizadas e dezenas de tons, e a arte tem 120×134 pixels.

## Objetivos

1. A casa é uma peça solta, posta pela ferramenta Peças, espelhável, com um bloqueio no pé e a janela acesa à noite.
2. As 8 cores da Casa grande são as variantes dela, trocadas pelas teclas ← → do editor.
3. A arte sai de um script que lê a imagem do dono, sem desenhar pixel novo.

## Anti-objetivos

- As peças de antes não mudam.
- A casa não ganha ação; o editor pode dar uma pela lista Ação, como a qualquer peça.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A casa é o tipo de peça 100 (`timber_cottage`, "Casinha enxaimel") | O 99 é o último tipo. As 9 casas de teste que usaram os ids 100 a 108 foram apagadas no mesmo dia, sem nunca entrar num commit nem numa ilha |
| A arte é reduzida a 70%, de 120×134 para 84×94 (86×96 com a sombra) | No tamanho dos pixels da imagem, a porta tinha 36 px de altura e a da Casa grande, 26: o dono viu a casa no mapa e achou desproporcional, muito maior. Com 70%, a porta e a janela ficam do tamanho das da Casa grande |
| A paleta, o contorno colorido, a sombra e as 8 cores são os da Casa grande ([home-pack/03](../home-pack/03-house-shapes.md)), como na [Casinha de pedra](../stone-cottage/README.md) | O dono pediu o padrão das outras casas |
| Os tons trocam por material e pela proporção de claro e escuro da Casa grande, não cor a cor | A imagem tem dezenas de tons parecidos; uma tabela à mão, como a da Casinha de pedra, seria enorme |
| Sem fumaça; a janela acende à noite | A casa não tem chaminé |
| A arte fica fora do [guia de estilo da cidade](../town-art/style-guide.md) | É a arte do dono, como a Casinha de pedra |

## Fora do escopo

- A casa no mapa sorteado.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-timber-cottage](01-timber-cottage.md) | A casa como peça 100, em 8 cores, com o bloqueio no pé e a luz da janela | concluída (falta o dono conferir) |

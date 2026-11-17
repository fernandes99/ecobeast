# refuge-art

O prédio do Refúgio (tipo de peça 22) ganha a arte da imagem que o dono mandou, no padrão das casas: a paleta, o contorno, a sombra e as 8 cores da Casa grande, a fumaça na chaminé e as luzes à noite.

## Contexto

Em 2026-11-17, o dono mandou a imagem de um Refúgio em pixel art e pediu: "reformule o refugio, faça com esse asset, deixe ele nos padrões das casas". A imagem virou a fonte (`art-source/refuge_building/reference.png`).

O prédio é um enxaimel visto de frente, em forma de T: duas alas compridas de telhado vermelho e uma frente de oitão no meio, com uma viga em cruz no telhado. A frente tem a placa com a cruz vermelha, a porta dupla, duas lanternas e dois bancos. A ala da esquerda é de pedra, com uma estufa de vidro na frente, e a da direita é de reboco. As alas têm janelas com floreiras, e a ala da esquerda tem a chaminé, com fumaça desenhada. Há barris e uma placa pendurada com a cruz. Na imagem, cada pixel da arte ocupa 5,12 pixels, como na da [Casinha enxaimel](../timber-cottage/README.md), e a arte tem 178×132 pixels.

A arte de antes era do `make_town.gd` (128×88, uma cor), no estilo do [guia da cidade](../town-art/style-guide.md).

## Objetivos

1. O tipo 22 continua sendo o prédio do Refúgio, agora com a arte da imagem e as 8 cores da Casa grande, trocadas pelas teclas ← → do editor.
2. A chaminé solta a fumaça animada das casas, que o botão da fumaça do F2 pode tirar, como nas casas.
3. À noite, as 4 janelas das alas e as 2 lanternas da porta acendem.
4. O bloqueio padrão segue o pé do prédio em T.
5. A arte sai de um script que lê a imagem do dono, sem desenhar pixel novo.

## Anti-objetivos

- O tipo, o slug e o nome não mudam: as ilhas que já têm o Refúgio passam a mostrar a arte nova na cor 1 (a do telhado vermelho).
- A ação Refúgio não muda: continua na peça ou nos hexágonos, como cada ilha a pôs.
- A Loja e as casas da cidade do `make_town.gd` não mudam.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A arte fica no tamanho da imagem, 180×134 com a sombra, sem a redução de 70% da Casinha enxaimel | A porta dupla tem 20 px de altura, perto dos 26 da porta da Casa grande. Com 70%, ela ficaria com 14 px, menor que o Domador. O prédio fica o maior da vila, como cabe ao Refúgio |
| A paleta, o contorno colorido, a sombra e as 8 cores são os da Casa grande, como na Casinha enxaimel | O dono pediu o padrão das casas |
| A cruz vermelha das placas, as flores das floreiras, as plantas da estufa e as lanternas ficam com as cores da imagem | São pequenas e dizem o que o prédio é. Trocadas pelos tons de telha ou de madeira, a cruz mudaria com o telhado, e as flores e as lanternas sumiriam |
| A fumaça desenhada na imagem sai, e a chaminé ganha a fumaça animada da Casa grande (`smoke.png`, copiada pelo script) | É o padrão das casas com chaminé ([home-pack/01](../home-pack/01-big-house.md)) e deixa o botão da fumaça valer para o Refúgio |
| As luzes ficam à mão, fora do `find_lights.py` | O script acenderia a estufa e os barris (o vidro e a água azuis) e não veria uma das janelas, cujo vidro tem o cinza da pedra |
| As 5 luzes de antes (ids 3 a 7) ganham a posição nova, e a 6ª é a 149 | Os ids são estáveis; os de antes seguem sendo do Refúgio |
| O `make_town.gd` para de desenhar o Refúgio | Rodá-lo apagaria a arte nova |
| A arte fica fora do [guia de estilo da cidade](../town-art/style-guide.md) | É a arte do dono, como as casinhas |

## Fora do escopo

- Refazer a Loja no mesmo padrão.
- Pôr o Refúgio em Liora.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-refuge-art](01-refuge-art.md) | A arte em 8 cores, a fumaça, as luzes e o bloqueio novo do tipo 22 | concluída (falta o dono conferir) |

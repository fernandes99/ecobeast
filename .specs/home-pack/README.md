# home-pack

A casa grande, com a fumaça da chaminé animada, e mais dois formatos dela (a pequena e o sobrado pequeno), em 8 cores, e a cerca de estacas do pacote gratuito **Main Characters Home** da craftpix.net entram nas ilhas: as casas como peças soltas e a cerca como um tipo novo de parede.

## Contexto

Em 2026-11-15, o dono pediu: "adicione uma casa grande que seja desse pacote [...] e nessa casas faça a animação da chaminé (já tem as artes para isso). também adicione mais uma versão de uma cerca e utilize a cerca desse pacote", apontando a pasta `PNG` do pacote.

O pacote tem uma casa só (`exterior.png`, telhado vermelho e paredes de pedra), a fumaça da chaminé em 6 quadros (`Smoke_animation.png`) e uma cerca de estacas marrons com travessa azulada (também em `exterior.png`), deitada e em pé.

## Objetivos

1. As casas são peças soltas, postas pela ferramenta Peças, espelháveis e com um bloqueio no pé.
2. A fumaça sai da chaminé em loop, cada casa num ponto do ciclo.
3. A cerca de estacas é uma parede como as outras: desenhada pela ferramenta Cerca e bloqueando pela linha, bonita em qualquer ângulo.
4. A arte sai de scripts que recortam as folhas do pacote, sem mudar os pixels.

## Anti-objetivos

- As peças, as paredes e as ações de antes não mudam.
- A casa não ganha ação; o editor pode dar uma pela lista Ação, como a qualquer peça.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A casa é o tipo de peça 95 (`big_house`, "Casa grande") e a cerca o tipo de parede 4 (`picket_fence`, "Cerca de estacas") | Os ids 91 a 94 já eram da [coast-rivers](../coast-rivers/), em andamento |
| A fumaça guarda só os pixels que mudam em cima da casa, e o shader das plantas troca o quadro | A casa fica numa malha só, como as outras peças, e a fumaça segue a ordem pelo pé |
| A cerca tem uma estaca a cada 8 px, como no pacote, e cada estaca é um poste | Num trecho torto, as estacas ficam em pé, e a travessa liga uma à outra |
| Acima de 60°, a cerca usa o trecho em pé do pacote (estacas vistas de cima entre duas travessas), 8 px acima do chão, e só tem os postes das pontas | O trecho em pé do pacote já traz as estacas, na altura da travessa deitada |
| A arte do pacote fica fora do [guia de estilo da cidade](../town-art/style-guide.md) | O dono pediu a casa e a cerca do pacote |
| Cada formato de casa é um tipo de peça, e as 8 cores são as variantes dele | O bloqueio e o lugar da fumaça dependem só do formato |

## Fora do escopo

- O resto do pacote (árvores, pedras, interior, gato, pássaros, portas e janelas animadas).
- Os formatos da prévia que o dono descartou: a casa média, a comprida, o sobrado grande e a de dois frontões ([03](03-house-shapes.md#contexto)).
- A casa no mapa sorteado.

## Pré-requisitos

- [free-objects](../free-objects/): as peças com bloqueio e ação.
- [fence-art](../fence-art/): a folha de 3 células das paredes e o `make_walls.py`.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-big-house](01-big-house.md) | A casa grande como peça 95, com a fumaça animada | concluída (falta o dono conferir) |
| 2 | [02-picket-fence](02-picket-fence.md) | A cerca de estacas como parede 4 | concluída (falta o dono conferir) |
| 3 | [03-house-shapes](03-house-shapes.md) | As 8 cores das casas, a Casa pequena (96) e o Sobrado pequeno (97) | concluída (falta o dono conferir) |

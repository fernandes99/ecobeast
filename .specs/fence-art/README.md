# fence-art

A cerca de madeira e o muro de pedra das ilhas ganham a arte do pacote **Sunnyside World** (comprado pelo dono): a madeira com postes de topo redondo e uma travessa, e o muro com pilares. O traço, o bloqueio e o editor da [free-fences](../free-fences/) não mudam.

## Contexto

Em 2026-11-15, o dono pediu: "Quero melhorar visualmente as cercas, consegue deixar ela mais bonita? Se preferir use a cerca que está nesse pacote", apontando a pasta `Tileset` do Sunnyside World.

Hoje a arte das paredes é desenhada por código no `make_town.gd`: um poste e uma travessa, cortada em fatias de 1 px ao longo da linha pelo `HexWalls`. Num trecho quase em pé, a fatia vira um fio, e os postes ficam a cada 10 px para cobrir.

Claude montou uma prévia com a arte de hoje e a do pacote, no mesmo desenho do jogo, em vários ângulos e com o Domador para escala. O dono escolheu a do pacote nas duas.

## Objetivos

1. A cerca de madeira e o muro de pedra usam a arte do pacote, sem mudar os pixels dele.
2. A cerca fica bonita em qualquer ângulo: deitada, de lado pelas fatias; quase em pé, a travessa vista de cima ligando os postes, como o pacote desenha a cerca vertical.
3. A arte sai de um script que recorta a folha do pacote, como as pontes.

## Anti-objetivos

- Nenhuma mudança no servidor, no banco nem no catálogo (`wall_types` fica igual).
- O bloqueio, a ferramenta Cerca e a parede invisível não mudam.
- A ordem de desenho pelo pé (faixas de 7 px) não muda.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| A arte do Sunnyside nas duas paredes | Escolhida na prévia, contra a de hoje e contra só a madeira |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os postes ficam a cada 16 px, a unidade do pacote; a travessa entre dois postes é a do pacote, esticada de leve para os postes ficarem a espaços iguais | A emenda do muro cai sempre no meio entre dois pilares |
| Acima de 60° (mais de 1,73 px na vertical por pixel na horizontal), o trecho usa a travessa vista de cima, em linhas de 1 px, e os postes a cada 16 px na madeira e 24 px na pedra | Deitada assim, a travessa empilha e vira uma faixa grossa; 60° foi o ponto que ficou melhor na prévia |
| A travessa vista de cima da madeira é a do pacote (4 px); a do muro é montada com as cores do pacote (8 px, com uma junta a cada 8 linhas) | O pacote não tem um trecho vertical do muro que se repita |
| A arte do pacote fica fora do [guia de estilo da cidade](../town-art/style-guide.md) | O dono escolheu o pacote; o guia já deixa de fora as árvores e pedras dos pacotes |

## Fora do escopo

- Portão, cantos e pontas especiais da cerca.
- Tipos novos de parede (o pacote tem outras cores de muro).
- Mudar a cerca do mapa sorteado (ele não tem paredes).

## Pré-requisitos

- [free-fences](../free-fences/): as paredes, o `HexWalls` e a folha de cada tipo.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-sunnyside-fences](01-sunnyside-fences.md) | A folha nova das duas paredes e o `HexWalls` com a travessa vista de cima | concluída (falta o dono conferir) |

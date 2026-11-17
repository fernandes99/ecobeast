# timber-house

A casa enxaimel (madeira aparente em cima, pedra embaixo) do pacote gratuito **Free Glassblower's Workshop Top-Down Pixel Art Asset** da craftpix.net entra nas ilhas como peça solta, em 8 cores.

## Contexto

Em 2026-11-16, o dono pediu: "Crie uma casa que tem nesse tileset [...] crie várias versões com cores diferentes", apontando a pasta `Tiled_files` do pacote.

O pacote não tem a casa numa imagem só: ela é montada por tiles de 16×16 no mapa `Exterior.tmx`, nas camadas `Walls`, `Windows_top`, `Roof`, `stovepipe` e `Roof_detail`, ao lado de uma tenda, uma placa, barris e uma carroça. Os tiles da porta e das janelas são animados no Tiled (a porta abrindo e as venezianas), e o pacote não tem fumaça de chaminé.

## Objetivos

1. A casa é uma peça solta, posta pela ferramenta Peças, espelhável e com um bloqueio no pé.
2. As 8 cores são as variantes dela, trocadas pelas teclas ← → do editor.
3. À noite, as janelas acendem, e a chaminé solta fumaça, como nas casas da [home-pack](../home-pack/).
4. A arte sai de um script que monta a casa pelos tiles do pacote, sem desenhar pixel novo.

## Anti-objetivos

- As peças, as luzes e a fumaça de antes não mudam.
- A casa não ganha ação; o editor pode dar uma pela lista Ação, como a qualquer peça.

## Decisões

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A casa é o tipo de peça 98 (`timber_house`, "Casa enxaimel") | O 97 é o último tipo |
| A porta e as janelas ficam paradas, no primeiro quadro (a porta fechada) | A peça é uma malha só; a animação dos tiles fica para depois, se o dono pedir |
| A fumaça é a da Casa grande (`big_house/smoke.png`), copiada | O pacote não tem fumaça, e a boca da chaminé tem os mesmos 10 px de largura da casa grande |
| As cores seguem as da [home-pack/03](../home-pack/03-house-shapes.md), com a madeira mudando junto em algumas | As casas dos dois pacotes ficam combinando numa vila |
| O `find_lights.py` ignora o grupo de vidro com menos de 4 px num lado | As maçanetas da porta são azuis e viravam janela; as luzes das outras peças não mudam |
| A arte do pacote fica fora do [guia de estilo da cidade](../town-art/style-guide.md) | O dono pediu a casa do pacote |

## Fora do escopo

- O resto do pacote (tenda, placa, barris, carroça, interior, forja, personagens, muros e chão).
- A porta abrindo e as venezianas animadas.
- A casa no mapa sorteado.

## Pré-requisitos

- [home-pack](../home-pack/): a fumaça da chaminé e as cores das casas.
- [day-night](../day-night/): as luzes das janelas (`prop_type_lights`).

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-timber-house](01-timber-house.md) | A casa enxaimel como peça 98, em 8 cores, com a fumaça e as luzes | concluída (falta o dono conferir) |

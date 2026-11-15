# vegetation-wind

Os arbustos dos pacotes da [vegetation-packs](../vegetation-packs/) balançam com o mesmo vento das decorações do bioma. As árvores ficam paradas por enquanto.

## Contexto

Em 2026-11-15, o dono pediu: "coloque animação em todas essas novas vegetações que vieram do pacote".

Os pacotes não trazem quadros de animação: cada planta é uma imagem parada. O mapa já tem o vento das decorações do bioma (`plant_wind.gdshader`): o topo da arte anda alguns pixels para os lados e o pé fica parado. As peças de arte própria passam pelo mesmo shader, mas com o vento zerado.

Claude propôs ligar esse vento nas peças dos pacotes, com as pedras, o tronco cortado e os cactos parados. O dono respondeu "Pode seguir". Depois de ver o GIF, ele pediu o vento do shader só nos arbustos: "para as árvores eu queria algo melhor que isso".

## Objetivos

1. Os arbustos, flores e samambaias dos pacotes balançam no mapa, no jogo e no editor.
2. O balanço é o mesmo das decorações do bioma: a mesma onda, a mesma rajada e o mesmo sentido, em pixels inteiros.
3. A copa não é cortada na borda da arte quando balança.

## Anti-objetivos

- Nenhuma mudança no servidor, no banco nem no catálogo.
- As decorações do bioma balançam como antes.
- O bloqueio e a ordem de desenho das peças não mudam.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| As plantas dos pacotes balançam com o vento | "coloque animação em todas essas novas vegetações" |
| O vento do shader fica só nos arbustos; as árvores esperam uma animação melhor | "aplique apenas para as vegetações de arbusto, para as árvores eu queria algo melhor que isso" |
| As árvores ficam paradas por enquanto | Claude mostrou três caminhos (copa por partes, quadros desenhados e folhas caindo), e o dono escolheu a copa por partes. Ao ver o resultado: "ficou muito ruim, deixa estático por enquanto". O código saiu |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Usa o vento do shader de hoje, sem quadros desenhados | Os pacotes não têm quadros, e a planta nova balança junto com as do bioma |
| Os arbustos andam até 1 px no topo | É o valor do Arbusto do bioma |
| Ficam parados o tronco cortado (39), os dois cactos (48 e 49) e as 8 pedras (53 a 60) | Não são plantas que o vento dobra |
| A força fica numa tabela do jogo, por `slug`, como a das decorações (`KIND_SWAY`) | É ajuste de visual, sem regra de jogo |

## Fora do escopo

- A animação das árvores. A copa por partes (tronco, copa e tufos de folhas mexidos pelo shader) foi testada e descartada; sobram os quadros desenhados e as folhas caindo.
- Vento nas peças da cidade (banco, poste, canteiro) e nos prédios.
- Mudar a força do vento pelo editor.

## Pré-requisitos

- [vegetation-packs](../vegetation-packs/): os tipos 28 a 60.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-pack-sway](01-pack-sway.md) | O vento nos arbustos dos pacotes | concluída (falta o dono conferir) |

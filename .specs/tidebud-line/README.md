# tidebud-line

Uma linha nova de três formas, o cavalo-marinho de folhas e raios: o **Tidebud**, o **Kelpcoil** e o **Tempestide**. É a primeira linha de Volt do catálogo: Água no filhote e Água/Volt nas duas formas seguintes, com as primeiras Técnicas de Volt e a marca Maré Elétrica.

## Contexto

Em 2026-11-19, o dono mandou a imagem da linha (`art-source/tidebud/line.webp`, 1774×887, com fundo transparente) e pediu sugestões de nome, descrição e o resto. A imagem mostra:

- um filhote de cavalo-marinho de olhos grandes, com crista e nadadeiras de folha, a cauda enrolada e uma faísca azul na crista;
- um dragão-marinho esguio, com crina de folhas, veias douradas, cristais azuis nas costas e raios saindo das folhas;
- um dragão-marinho enorme, com chifres dourados em galho, véus de folha, cristais e uma tempestade de raios em volta.

Claude sugeriu três trios de nomes e a ficha, e o dono escolheu o trio 1 (*tide* + *bud*, *kelp* + *coil*, *tempest* + *tide*).

## Objetivos

1. As espécies 17, 18 e 19, com Elementos, atributos, Traços, evolução, learnset, biomas e partes do dia.
2. Os `front.png` recortados da imagem.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As primeiras Técnicas de Volt, com a marca Maré Elétrica, sem regra nova no motor.

## Anti-objetivos

- Regra nova no motor da luta.

## Decisões

Do dono, em 2026-11-19:

| Decisão | Motivo |
| --- | --- |
| Os nomes Tidebud, Kelpcoil e Tempestide | Escolha do trio 1 entre as sugestões de Claude |
| As Técnicas de Volt que Claude propôs (Faísca de Alga, Corrente Viva, Maré Elétrica e Tempestade de Algas) | Pedido do dono, depois da fase 1 |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Água no Tidebud, Água/Volt no Kelpcoil e no Tempestide | Ele vive na água, as folhas são camuflagem, e os raios crescem com a evolução. Era a recomendação de Claude, e o dono só respondeu os nomes |
| Raro, crescimento Médio, captura 45 e o XP dos iniciais (62, 142 e 236) | É uma linha especial, a primeira de Volt, com o peso de um inicial |
| Evolui nos níveis 18 e 38 | Um pouco depois dos iniciais (16 e 36), por ser selvagem |
| Atacante especial rápido: totais 315, 420 e 530 | Os raios pedem Ataque Especial e Velocidade; a Defesa fica baixa |
| Maré Furiosa no slot 1 e Instinto oculto no slot 3 | Não há Traço de Volt; o de Água combina com a forma de partida |
| Nasce na Água rasa, no Vau e na Praia, e o Tempestide também na Água profunda, com taxas baixas | É raro e vive na água; as ilhas o põem pelas áreas do editor |
| As duas primeiras formas nascem no Final de tarde e à Noite, e o Tempestide a qualquer hora | O brilho azul combina com o escuro, e a tempestade não escolhe hora |
| As Técnicas de Volt deixam o alvo Paralisado, e a Maré Elétrica é uma marca que paralisa quem para nela | O Paralisado já existe no motor (perde a vez em 25% e anda com metade da Velocidade), e Volt é imune a ele |
| A imagem é cortada pelo `crop_line.py` da skill `creature-sprites`, que saiu do recorte da [seedlet-line](../seedlet-line/) | As duas linhas cortam do mesmo jeito |

## Fora do escopo

- O ícone do Elemento Volt e os ícones, efeitos e sons das Técnicas novas.
- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-tidebud-line](01-tidebud-line.md) | As três espécies, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-volt-skills](02-volt-skills.md) | As 4 Técnicas de Volt e a marca Maré Elétrica nos learnsets | concluída (falta o dono conferir no jogo) |

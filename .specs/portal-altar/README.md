# portal-altar

O altar-portal do Veilmoth, a mariposa arcana que teleporta, entra nas ilhas como peça solta, em duas variantes: com a mariposa no pedestal e vazio.

## Contexto

Em 2026-11-19, o dono quis pensar em como teleportar entre as ilhas: uma construção com um Ecobeast que teleporta. Ele ligou a ideia ao Elemento Arcano, que o Instituto Meridian tenta entender, e escolheu, entre as ideias de Claude, as mariposas gêmeas: o **Veilmoth**, que evolui para o **Gatemoth**. A mariposa tem olhos-de-portal nas asas e só se teleporta para onde há outra do mesmo bando, então cada ilha com uma estação guarda uma mariposa, e o Domador só vai para onde ela já está.

Claude desenhou um conceito da mariposa de frente e dela no altar, em Explorar. O dono gostou e pediu o prompt do `front.png` com o Gatemoth e o objeto. Esta iniciativa é o objeto; a espécie e a regra do teleporte são outras entregas.

## Objetivos

1. O altar é uma peça solta, posta pela ferramenta Peças, espelhável, com bloqueio na base e luz arcana à noite.
2. A variante 1 tem o Veilmoth no pedestal e o portal aceso; a variante 2 está vazia, com o portal apagado, para a ilha a que a mariposa ainda não chegou.
3. A arte sai de um script, como as dos prédios da cidade.

## Anti-objetivos

- As peças de antes não mudam.
- A peça não ganha ação: o editor dá a Viagem (`travel`) pela lista Ação, como a qualquer peça.

## Decisões

Do dono, em 2026-11-19:

| Decisão | Motivo |
| --- | --- |
| A mariposa gêmea, Veilmoth e Gatemoth, de Arcano | Escolha entre as ideias de Claude: o teleporte vem do bando, e não da mente |
| Ela fica num altar-portal, a construção do teleporte | Pedido do dono |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O tipo de peça 101 (`portal_altar`, "Altar-portal"), com 2 variantes | O 100 é o último tipo |
| O altar é de pedra (a da Casa grande desde a [fase 2](02-altar-art.md)), com um arco sobre dois pilares, a pedra-chave de cristal, um anel arcano gravado na base e um pedestal com bacia no meio | Foi o conceito que o dono aprovou |
| A mariposa está desenhada na arte da variante 1, parada | O Veilmoth ainda não existe como espécie nem tem folhas de Explorar; quando tiver, ele pode virar um NPC em cima do altar vazio |
| Uma paleta nova, Arcano, no [guia de estilo](../town-art/style-guide.md#detalhes) | O guia pede uma paleta para cada material novo |

## Fora do escopo

- A espécie Veilmoth e Gatemoth, a arte de frente e as folhas do mapa.
- A regra do teleporte: o altar liga só as ilhas que já têm a mariposa.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-portal-altar](01-portal-altar.md) | O tipo de peça 101, com a arte, o bloqueio e as luzes | concluída (falta o dono conferir) |
| 2 | [02-altar-art](02-altar-art.md) | A arte refeita na pedra da Casa grande e a animação de 16 quadros | concluída (falta o dono conferir no jogo) |

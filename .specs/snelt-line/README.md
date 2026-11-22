# snelt-line

Uma linha nova de três formas, o caracol-fornalha: o **Snelt**, o **Smeltrudge** e o **Magmollusk**, de Metal, com o Fogo entrando na forma final. É o primeiro Ecobeast de Metal puro e o primeiro canhão especial lento: aguenta bem, anda devagar e tem o maior Ataque Especial do jogo.

## Contexto

Em 2026-11-22, o dono pediu um resumo de todos os Ecobeasts por Elemento, papel e bioma, para ver o que falta e decidir o próximo, e pediu que isso virasse uma skill (`catalog-balance`). O retrato mostrou:

- 4 Elementos que nunca abrem uma linha: Volt, Metal, Toxina e Psíquico. O Metal só aparecia como 2º Elemento do Nilgorr e do Ingot, e não tinha nenhuma Técnica Especial.
- O atacante especial rápido com 5 das 15 formas finais, e nenhum canhão especial lento.
- A Montanha sem nenhuma linha nativa, e o Vulcão só com o Ruvo.
- Só 2 linhas Comuns (Puffcoo e Snekit).

Das três candidatas da skill, a de Metal fechava mais lacunas. O dono escolheu o caracol-fornalha entre três animais e aprovou o desenho de Claude ("Pode seguir"). Ele gerou a imagem da linha numa IA e a mandou. Ela fica em `art-source/snelt/line.webp`, com fundo transparente e as três formas da esquerda para a direita; o Snelt olha para a direita, e o Smeltrudge e o Magmollusk para a esquerda.

A imagem mostra:

- **Snelt:** um caracolzinho de corpo bege-acinzentado, de olhar meio fechado e esnobe, com a concha de ferro em espiral, rebites e frestas de brasa laranja, e um fio de fumaça saindo de um furo aceso no topo.
- **Smeltrudge:** maior e emburrado, com a concha virada fornalha: chaminé com fumaça, uma portinha de grade acesa na lateral, espinhos de ferro e as antenas de ponta acesa.
- **Magmollusk:** um caracol enorme e velho, de corpo de pedra rachada com lava nas frestas e barbicha creme, a concha uma fornalha cheia de espinhos e placas rebitadas, a chaminé soltando fogo e fumaça escura, e metal derretido escorrendo da boca da fornalha.

## Objetivos

1. As espécies 38 a 40, com os Elementos, os atributos, os Traços, as evoluções, o learnset, os biomas, a zona e as partes do dia.
2. Os `front.png`, recortados da imagem, e os `face.png`.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As quatro primeiras Técnicas Especiais e de Suporte de Metal da [fase 2](02-metal-skills.md).

## Anti-objetivos

- Regra nova no motor da luta: as Técnicas usam o dano, o estado Queimado, a mudança de atributo em si e a marca Chão em chamas, que já existem.
- Marca nova no chão: pediria o desenho animado dela no cliente.

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| A próxima linha é a de Metal da Montanha e do Vulcão | A recomendação da `catalog-balance` que ele aceitou ("Sim, planejar Metal") |
| O caracol-fornalha, artesão perfeccionista e vaidoso, que não se apressa | A escolha dele entre três animais |
| O desenho de Claude (nomes, números, Técnicas e biomas) | "Pode seguir" |
| A arte da imagem dele | Ele mandou a imagem no lugar do prompt |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Metal → Metal → Metal/Fogo | A fornalha só acende de verdade na forma final, que despeja metal derretido |
| Totais 290, 400 e 515, com o Atq.E no alto (130 na final, o maior do jogo) e a Vel baixa (25, 35 e 40) | O canhão especial lento; o total um pouco abaixo das linhas Incomuns de três formas, por ser Comum |
| Comum, crescimento Médio, captura 70, 40 e 25, XP 55, 140 e 225 | A base fácil de achar no começo; as formas evoluídas mais difíceis, como o Snekit e o Venomaw |
| As evoluções nos níveis 16 e 32 | Um pouco antes das linhas Incomuns (18 e 36), por ser Comum |
| Casca Dura (4) no slot 1 e Fúria Ardente (1) oculta no slot 3 | A concha de ferro; a fornalha que ferve com o HP baixo, como o Traço do Ruvo |
| Nasce na Montanha, na Pedra (o dobro no Rochedo) e no Vulcão, nas 4 partes do dia | A Montanha sem linha nativa; a base Comum fácil de achar a qualquer hora |
| A altura de 0,3 m, 0,9 m e 1,6 m e o peso de 6, 120 e 450 kg | A proporção da imagem; o ferro deixa todos pesados |

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas.
- Pôr a linha nas áreas das ilhas, que o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-snelt-line](01-snelt-line.md) | As três espécies, os `front.png`, os `face.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-metal-skills](02-metal-skills.md) | Quatro Técnicas de Metal nos learnsets | concluída (falta o dono conferir no jogo) |

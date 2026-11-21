# sandlurk-line

Uma linha nova de duas formas, o escorpião enterrado: o **Sandlurk** e o **Dunestrike**, os dois Inseto/Toxina. É um tanque lento que bate forte de perto, o contrário do Mantorn e do Venomaw, e evolui no nível 30.

## Contexto

Em 2026-11-21, o dono pediu sugestões de um Ecobeast "inseto + toxico, que lembre um escorpião". Claude propôs três linhas, e o dono escolheu a do caçador enterrado: "Vamos de Sandlurk e Dunestrike".

Ele gerou a imagem da linha numa IA, a partir do prompt da skill `creature-front-prompt`. Ela fica em `art-source/sandlurk/line.webp`: 1774×887, com fundo branco, o Sandlurk à esquerda e o Dunestrike à direita. O Dunestrike veio olhando para a esquerda, e o dono pediu: "você deve espelhar ela para ficar no padrão, olhando para a direita".

A imagem mostra:

- **Sandlurk:** um escorpião filhote achatado e largo, de carapaça bege-areia e ocre com faixas marrom-queimado e grãos de areia nas costas, os olhos amarelos meio fechados, entediados, as pinças curtas e grossas na frente do rosto e a cauda curta enrolada, com a gota de veneno amarelo-mostarda no ferrão.
- **Dunestrike:** o adulto grande e blindado, com placas pontudas, areia e pedrinhas entre elas, os olhos amarelos frios e calculistas, as pinças largas e serrilhadas e a cauda longa erguida em arco, pingando o veneno amarelo.

Os dois não são simpáticos: o Sandlurk é preguiçoso e entediado, e o Dunestrike é paciente e frio.

## Objetivos

1. As espécies 29 e 30, com os Elementos, os atributos, os Traços, a evolução, o learnset, os biomas, as zonas e as partes do dia.
2. Os `front.png`, recortados da imagem, com o Dunestrike espelhado.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As quatro Técnicas da [fase 2](02-dune-skills.md).

## Anti-objetivos

- Regra nova no motor da luta: as Técnicas usam o Preso, o Paralisado, a mudança de atributo e o crítico, que já existem.

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| Um escorpião Inseto/Toxina, de duas formas | O pedido |
| Os nomes Sandlurk e Dunestrike, o caçador preguiçoso e paciente que fica enterrado | A escolha dele entre as três propostas |
| A arte da imagem dele, com o Dunestrike espelhado | "você deve espelhar ela para ficar no padrão" |
| Seguir com a ficha de Claude | "Pode seguir", depois de ver a ficha |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| As duas formas são Inseto/Toxina | A proposta: o filhote já tem o ferrão com veneno |
| Incomum, crescimento Médio, captura 45 e 25, XP 60 e 175 | Um caçador enterrado é difícil de achar |
| Tanque lento de Ataque físico: totais 300 e 485, com a Defesa mais alta | O caçador que recebe o golpe e devolve |
| O Traço Casca Dura (4) no slot 1 e nenhum oculto | Não há Traço de Inseto nem de Toxina, e ele combina com a carapaça |
| A evolução no nível 30, pelo gatilho de nível | O servidor já oferece esse gatilho, então a linha não espera a [bond](../bond/README.md) |
| Nasce no Deserto e na Praia, mais nas Dunas e menos no Cactal, de Manhã e de Tarde | Areia solta para se enterrar, nas horas quentes. Não divide o horário com o Snekit (Tarde e Final de tarde) |
| A altura de 0,4 m e 1,1 m | O corpo é baixo; a cauda erguida dá a altura |

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas, que vêm depois, como na [board-battle/29](../board-battle/29-earth-volt-water-flora-skills.md).
- Pôr o escorpião nas áreas das ilhas, que o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-sandlurk-line](01-sandlurk-line.md) | As duas espécies, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-dune-skills](02-dune-skills.md) | Quatro Técnicas de escorpião nos learnsets | concluída (falta o dono conferir no jogo) |

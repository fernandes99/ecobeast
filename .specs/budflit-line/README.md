# budflit-line

Uma linha nova de três formas, a borboleta torcedora: o **Budflit** (Inseto), a **Cheerwing** (Inseto/Psíquico) e a **Galafly** (Inseto/Psíquico). É o primeiro Suporte Inspirador, o primeiro Suporte Comum e a segunda linha pensada para o Campo florido do começo do jogo, depois da [nectoad-line](../nectoad-line/).

## Contexto

Em 2026-11-22, depois do sapo, o dono pediu outro Ecobeast do Campo florido, Comum e que representasse bem a zona, "tipo uma borboleta". A skill `catalog-balance`, já com o Nectoad, mostrou:

- Psíquico era o único Elemento que nunca começa uma linha.
- Nenhum Inspirador e nenhum Suporte Comum ([creature-roles](../creature-roles/README.md#os-papéis-de-hoje)).
- De Tarde, só a Puffcoo nascia a mais no Campo florido.
- O Inseto não tinha nenhuma Técnica Especial.

Claude propôs três borboletas, e a recomendada foi a torcedora, Suporte Inspirador. O dono pediu três formas, sem a lagarta e o casulo, e Claude montou as três já borboleta, mudando as asas e o jeito. Depois, ao mandar a imagem, o dono trocou os Elementos de Psíquico, Psíquico e Psíquico/Inseto para **Inseto, Inseto/Psíquico e Inseto/Psíquico**. Com isso, o Psíquico continua sem começar uma linha.

A imagem da linha, gerada numa IA, fica em `art-source/budflit/line.webp`, com fundo branco e as três formas da esquerda para a direita, todas olhando para a direita:

- **Budflit:** uma borboletinha redonda e sentada, de asas fechadas lilás, rosa e creme, com a cabeça lilás, o olho grande magenta, as antenas de bolinha rosa e uma gola de pétalas rosa.
- **Cheerwing:** a borboleta de asas abertas, roxas, rosa e creme com pintas douradas, de corpo roxo fino e peito de penugem creme, com um topete rosa e dourado, o olho magenta e os traços amarelos de comemoração do lado.
- **Galafly:** a borboleta grande de quatro asas largas, roxas, rosa, lilás e douradas, com uma estrela na asa da frente, o peito de pétalas creme e rosa, a crista de pétalas, as caudas longas nas asas de trás e os brilhos rosa e dourados soltos em volta.

## Objetivos

1. As espécies 45 a 47, com os Elementos, os atributos, os Traços, as duas evoluções, o learnset, os biomas, as zonas e as partes do dia.
2. Os `front.png`, recortados da imagem do dono, e os `face.png`.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As três Técnicas da [fase 2](02-cheer-skills.md), que sustentam o papel.

## Anti-objetivos

- Regra nova no motor da luta: as Técnicas usam o dano, a Confusão e a mudança de atributo num aliado, que já existem.
- A sequência lagarta → casulo → borboleta.

## Papel

Pela regra da [creature-roles](../creature-roles/README.md#regras-para-toda-linha-nova):

| | |
| --- | --- |
| **Papel principal** | Suporte Inspirador |
| **Secundário** | — |
| **Segundo eixo** | rápido (Velocidade 125 na Galafly), para fortalecer os aliados antes de eles agirem |
| **Atributos** | (HP 95 + Def.E 110) / 2 = 102,5, 27 acima do maior ataque (75) |
| **Traço** | Brisa Ligeira: +1 de Velocidade ao entrar na luta |
| **As 3 melhores Técnicas** | Ovação (sobe muito os dois ataques de um aliado), Pó Animador (sobe os dois ataques de um aliado) e Vento a Favor (sobe a Velocidade e a evasão de um aliado) |

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| Uma borboleta Comum do Campo florido | "queria algo que represente bem essa zona e que seja comum, tipo uma borboleta" |
| Três formas | "quero que tenha ideias de 3 evoluções" |
| Os nomes Budflit, Cheerwing e Galafly e o desenho de Claude | "Ok, gostei da ideia" |
| Os Elementos Inseto, Inseto/Psíquico e Inseto/Psíquico | "vamos mudar o tipo dele. Será inseto, inseto/psiquico, inseto/psiquico" |
| A arte da imagem dele | Ele mandou a imagem junto ("segue ela") |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Totais 300, 405 e 520, com o HP e a Def. Especial altos e a Velocidade de 125 na final | Suporte que aguenta pelo lado especial e age antes de todos |
| Comum, crescimento Médio, captura 75, 45 e 25, XP 52, 138 e 220 | Perto do Snelt, a outra linha Comum de três formas |
| As evoluções nos níveis 14 e 30 | Cedo, para o jogador ver a torcedora no começo do jogo |
| Brisa Ligeira (6) no slot 1 e Instinto (2) oculto no slot 3 | Quem já entra se mexendo, para dar o buff primeiro |
| Nasce na Planície e na Colina, o dobro no Campo florido e 150% na Clareira, de Manhã e de Tarde | A borboleta das flores ao sol; ocupa a Tarde do Campo florido |
| A altura de 0,2 m, 0,6 m e 1,3 m e o peso de 0,3 kg, 2,5 kg e 12 kg | A borboletinha de mão e a grande de asas de palco |
| Temperamento: tímida, depois torcedora empolgada, depois a mestra da festa, segura e generosa | O temperamento muda na evolução, e nenhum Ecobeast de hoje é torcedor |

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas.
- Pôr a linha nas áreas das ilhas, que o dono faz pelo F2.
- Uma Técnica de área que fortaleça todos os aliados de uma vez, que pediria conferir o alvo no motor.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-budflit-line](01-budflit-line.md) | As três espécies, os `front.png`, os `face.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-cheer-skills](02-cheer-skills.md) | Três Técnicas novas nos learnsets | concluída (falta o dono conferir no jogo) |

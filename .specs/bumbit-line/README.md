# bumbit-line

Uma linha nova de três formas, a abelha operária: o **Bumbit** (Inseto), o **Buzzwork** (Inseto) e o **Bloomarch** (Inseto/Flora). É o primeiro Controlador Arquiteto, o primeiro Controlador pensado para o Campo florido e a terceira linha Comum da zona, depois da [nectoad-line](../nectoad-line/) e da [budflit-line](../budflit-line/).

## Contexto

Em 2026-11-22, depois da borboleta, o dono pediu "um novo ecobeast comum que ficará presente na zona de flores", "um inseto característico com 2 evoluções". A skill `catalog-balance`, já com a Budflit, mostrou:

- O Controlador é o papel mais vazio: só o Blizzvolt, 1 de 19 formas finais, contra os 15% da distribuição alvo ([creature-roles](../creature-roles/README.md#os-papéis-de-hoje)).
- Nenhum Arquiteto nem Enfraquecedor como papel principal.
- O Inseto já é o Elemento que mais começa uma linha (Prayling, Sandlurk e Budflit), e a Budflit já é o inseto Comum do Campo florido, de Manhã e de Tarde. Um inseto novo ali só se justifica com outro papel.
- Nenhuma linha junta o Inseto e a Flora.

Claude propôs três insetos (a abelha operária, Controlador Arquiteto; a joaninha cavaleira, Guardião Muralha mista; e o grilo da noite, Controlador Perturbador), e o dono escolheu a abelha ("A abelha"). Os nomes da proposta eram provisórios: o Combuzz e o Hivarch viraram o **Buzzwork** e o **Bloomarch**, para ficar longe das abelhas de favo do Pokémon, e pela mesma razão nenhuma forma tem o corpo de favo, o abdômen de colmeia ou coroa.

Claude mandou o título, o Elemento e o desenho resumido de cada forma, e o dono mandou a imagem da linha, gerada numa IA ("pronto, faça esse ecobest, mandei a arte"). Ela fica em `art-source/bumbit/line.webp`, de 1536×1024 com fundo transparente e as três formas da esquerda para a direita, todas olhando para a direita. Vale a imagem:

- **Bumbit:** um zangãozinho redondo, uma bolinha de pelo amarelo e marrom-café em listras, de asinhas creme pequenas demais para o corpo, os olhos grandes castanhos, as antenas curtas e um pouco de pólen no focinho, com as perninhas curtas embaixo.
- **Buzzwork:** a operária em pé nas duas pernas finas, de listras amarelas e marrons, com um lenço de folha verde amarrado na testa, a gola de penugem creme, as asas translúcidas, os cestos de pólen dourado grandes nas pernas e uma folha enrolada debaixo do braço, como a planta da obra.
- **Bloomarch:** um zangão grande de pé, de corpo listrado coberto de folhas, com um colar de pétalas rosa e trevos, quatro asas largas âmbar e laranja, as antenas longas, o olhar de chefe, mel escorrendo da boca e as duas mãos dentro de manoplas de mel dourado que pingam, com gotas de mel soltas em volta.

## Objetivos

1. As espécies 48 a 50, com os Elementos, os atributos, os Traços, as duas evoluções, o learnset, os biomas, as zonas e as partes do dia.
2. Os `front.png`, recortados da imagem do dono, e os `face.png`.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. A marca Melado e as quatro Técnicas da [fase 2](02-hive-skills.md), que sustentam o papel.

## Anti-objetivos

- Regra nova no motor da luta: o Melado usa o Preso e a mudança de atributo de marca, que já existem, e as Técnicas usam o dano, a Confusão, a área em triângulo e a mudança de atributo no inimigo.
- A sequência larva → pupa → abelha.

## Papel

Pela regra da [creature-roles](../creature-roles/README.md#regras-para-toda-linha-nova):

| | |
| --- | --- |
| **Papel principal** | Controlador Arquiteto |
| **Secundário** | Controlador Perturbador (Zumbido) e Enfraquecedor (Nuvem de Pólen) |
| **Segundo eixo** | especial, médio (Velocidade 90 no Bloomarch) |
| **Atributos** | equilibrados, de 70 a 95, com o Ataque Especial (85) como o maior ataque e a Def. Especial (95) em destaque. Pela regra da `catalog-balance`, sairia Lutador misto ((HP 90 + Def 90) / 2 = 90, só 5 acima do maior ataque); vale o papel da spec, porque as 3 melhores Técnicas são de controle |
| **Traço** | Brisa Ligeira: +1 de Velocidade ao entrar na luta, para pôr a marca antes de os inimigos chegarem |
| **As 3 melhores Técnicas** | Mel Grudento (o Melado no chão: quem termina a vez nele fica Preso e perde Velocidade), Zumbido (dano em triângulo, com 30% de deixar Confuso) e Nuvem de Pólen (baixa a Precisão de certeza, em triângulo) |

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| Um inseto Comum do Campo florido, de três formas | "um novo ecobeast comum que ficará presente na zona de flores, eu queri um inseto cracteristico com 2 evoluções" |
| A abelha operária, Controlador Arquiteto | Escolheu a primeira das três candidatas ("A abelha") |
| A arte da imagem dele | Ele mandou a imagem ("mandei a arte") |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Os nomes Bumbit, Buzzwork e Bloomarch, no lugar do Combuzz e do Hivarch da proposta | O favo e a colmeia no nome e no corpo lembravam as abelhas do Pokémon |
| Inseto, Inseto e Inseto/Flora | A primeira linha de Inseto com Flora; a Flora chega no manto de pétalas da forma final |
| Totais 300, 405 e 520, todos os atributos de 70 a 95 na final | Controlador equilibrado, que aguenta o bastante para pôr as marcas e não derruba ninguém sozinho |
| Comum, crescimento Médio, captura 75, 45 e 25, XP 54, 140 e 222 | Perto da Budflit, a outra linha Comum de três formas da zona |
| As evoluções nos níveis 15 e 32 | O Buzzwork logo depois da Cheerwing (14); o Bloomarch perto do Magmollusk (32) |
| Brisa Ligeira (6) no slot 1 e Casca Dura (4) oculta no slot 3 | Agir cedo para marcar o chão; a Casca Dura, para o pelo grosso de zangão |
| Nasce na Planície e na Colina, o dobro no Campo florido e a metade no Mato seco, de Manhã e no Final de tarde | A abelha das flores, que sai cedo e volta no fim do dia; a Tarde do Campo florido já é da Budflit |
| A altura de 0,3 m, 0,8 m e 1,5 m e o peso de 0,6 kg, 7 kg e 28 kg | A bolinha de mão, a operária do tamanho de um cachorro pequeno e o zangão pesado |
| Temperamento: ansiosa e com mania de ordem, depois a fiscal mandona que conta cada flor, por fim a chefe de obra calma, que organiza o campo inteiro | Nenhum Ecobeast de hoje é o trabalhador que manda nos outros; a ansiedade vira comando conforme cresce |

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas.
- Pôr a linha nas áreas das ilhas, que o dono faz pelo F2.
- Uma Técnica que crie favos no tabuleiro bloqueando hexágonos, que pede o efeito Obstáculo ([creature-roles](../creature-roles/README.md#3-controlador), 🆕).

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-bumbit-line](01-bumbit-line.md) | As três espécies, os `front.png`, os `face.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-hive-skills](02-hive-skills.md) | A marca Melado e quatro Técnicas novas nos learnsets | concluída (falta o dono conferir no jogo) |

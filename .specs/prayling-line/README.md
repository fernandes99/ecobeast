# prayling-line

Uma linha nova, o louva-a-deus, a primeira de Inseto: o **Prayling** e o **Mantorn** (Inseto) e, na última forma, o **Solantis** (Inseto/Luz) se evoluir de dia, ou o **Umbrantis** (Inseto/Sombra) se evoluir à noite. É a primeira evolução que se divide, a primeira por horário e o primeiro Ecobeast de Luz.

## Contexto

Em 2026-11-20, o dono perguntou que Elemento ainda não tinha Ecobeast (eram Luz, Arcano e Inseto) e pediu "um ecobeast de 4 evoluções do tipo inseto, a ideia é que na quarta evolução pode ser um tipo luz ou sombra dependendo se a evolução será a noite ou de dia". Depois reduziu: "vamos reduzir para 3 evoluções, e a terceira vai ser luz ou sombra". Entre as ideias de Claude, ele escolheu o louva-a-deus ("gostei do louva deus"), recebeu os nomes e as descrições do primeiro trio, gerou as duas imagens da linha numa IA (`art-source/prayling/line-day.webp` e `line-night.webp`, 1774×887, com fundo transparente) e disse "vamos criar".

As imagens mostram:

- um filhote de louva-a-deus marrom cor de galho, de cabeça triangular e olhos verdes enormes, com as patas da frente dobradas;
- um louva-a-deus esguio, marrom com manchas de casca, de foices com espinhos;
- de dia, um louva-a-deus branco e dourado, com asas de pétalas de luz, uma auréola e as foices brilhando;
- à noite, um louva-a-deus seco como uma folha morta rasgada, de olhos roxos, com uma névoa roxa em volta.

## Objetivos

1. A evolução por horário no servidor (o gatilho `time_of_day`, que já está no catálogo), com o Bestiário mostrando a linha que se divide.
2. As espécies 25 a 28, com Elementos, atributos, Traços, as evoluções, learnset, biomas e partes do dia.
3. Os `front.png` recortados das imagens e as folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As primeiras Técnicas de Inseto e de Luz: Golpe de Foice, Emboscada, Dança da Foice, Raio de Sol e Lâmina Solar.

## Anti-objetivos

- Evolução por Vínculo, por item ou por zona: a evolução por Vínculo é a [bond](../bond/), que também muda o `evolutionOffer`.
- Mudar a evolução de quem já existe.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| Uma linha de Inseto de 3 formas, a última Luz ou Sombra pela hora em que evolui | O pedido |
| O louva-a-deus | "gostei do louva deus" |
| Os nomes Prayling, Mantorn, Solantis e Umbrantis, e as descrições | O primeiro trio que Claude mandou; ele gerou as imagens com eles |
| A arte das duas imagens dele | "Ok, vamos criar, ou te passar as imagens deles" |
| As 5 Técnicas de Inseto e de Luz que Claude propôs | "Sim, fase 3" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O "dia" é a Manhã e a Tarde; o Final de tarde e a Noite contam como noite | Claude propôs e o dono não se opôs. O Final de tarde já escurece o mapa |
| Mantorn no nível 18, e o Solantis e o Umbrantis no 36 | A linha é rápida: 2 formas antes da divisão |
| Incomum, crescimento Médio, captura 45 e o XP da linha do Lume (60, 140 e 230) | Igual à outra linha nova de três formas |
| Atacante físico rápido de pouca Defesa: totais 310, 420 e 525. O Solantis é mais equilibrado, e o Umbrantis bate mais e é mais rápido | Caçador de emboscada; os dois finais pedem jeitos de lutar diferentes |
| Instinto no slot 1 e Casca Dura oculto no slot 3 | Instinto (+1 Vel ao derrotar) é o caçador; a Casca Dura é o exoesqueleto. Não há Traço de Inseto |
| O Prayling e o Mantorn nascem nas 4 partes do dia; o Solantis só de dia, e o Umbrantis só à noite | A forma final selvagem respeita a hora em que se forma |
| Na fase 2, o learnset usa só Técnicas que existem (Instinto, a Garra de Espinho, as de Sombra e o Rasante) | Não há Técnica de Inseto nem de Luz; elas vêm na fase 3, como as de Sombra na [lume-line](../lume-line/) |
| As imagens são cortadas pelo `crop_line.py`, o Solantis da imagem do dia e o Umbrantis da da noite | As duas primeiras formas são iguais nas duas imagens; vale a da imagem do dia |

## Fora do escopo

- O ícone dos Elementos Inseto e Luz e os ícones, efeitos e sons das Técnicas novas.
- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Pôr a linha nas áreas das ilhas: o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-time-evolution](01-time-evolution.md) | A evolução por horário no servidor e a linha que se divide no Bestiário | concluída (falta o dono conferir no jogo) |
| 2 | [02-prayling-line](02-prayling-line.md) | As quatro espécies, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 3 | [03-insect-light-skills](03-insect-light-skills.md) | Técnicas de Inseto e de Luz nos learnsets | concluída (falta o dono conferir no jogo) |

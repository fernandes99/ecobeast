# glimshell-line

Uma linha nova de três formas, o jabuti de cristal: o **Glimshell**, o **Lumoshell** e o **Prismback**, de Luz. É o primeiro tanque especial e o primeiro Ecobeast de Luz pura, lento e sonolento, com HP e Defesa Especial muito altos e a Defesa física baixa.

## Contexto

Em 2026-11-21, Claude listou os papéis e os Elementos que faltam no catálogo: não havia tanque especial (a maior Defesa Especial era 100), nem muralha de HP (o maior HP era 100), e a Luz só aparecia como 2º Elemento do Solantis. O dono pediu "algum pensando em tanque especial e hp" e, depois, "algum que tenha 3 evoluções". Das três propostas de Claude, escolheu o jabuti: "Me mande o resumo do Glimshell, Lumoshell e Prismback".

Ele gerou a imagem da linha numa IA e mandou com "Bora criar ele". Ela fica em `art-source/glimshell/line.webp`, com fundo branco e as três formas da esquerda para a direita, todas olhando para a direita.

A imagem mostra:

- **Glimshell:** um filhote de jabuti gorducho, de pele dourada, com a cara emburrada e os olhos meio fechados, de sono. O casco é de cristal âmbar facetado, com uma pedrinha clara no topo.
- **Lumoshell:** maior, de pescoço comprido e enrugado, com o casco de placas de cristal âmbar que brilham pelas frestas e uma ponta de cristal no topo. O bico é curvo, e o olhar é pesado e cansado.
- **Prismback:** um jabuti enorme e velho, com o casco virado num monte de prismas de cristal furta-cor (pontas grandes no topo e menores em volta), a barbicha creme, as pálpebras caídas e uma cauda pontuda.

## Objetivos

1. As espécies 33 a 35, com o Elemento, os atributos, o Traço, as evoluções, o learnset, os biomas, as zonas e as partes do dia.
2. Os `front.png`, recortados da imagem.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As quatro Técnicas de Luz da [fase 2](02-light-skills.md).

## Anti-objetivos

- Regra nova no motor da luta: as Técnicas usam o dano, a mudança de atributo (em si, num aliado e no inimigo) e a cura, que já existem.
- Marca nova no chão: pediria o desenho animado dela no cliente.

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| Um tanque especial com HP alto | "algum pensando em tanque especial e hp" |
| Uma linha de três formas | "Quero algum que tenha 3 evoluções" |
| O jabuti de cristal de Luz, velho e sonolento | A escolha dele entre as três propostas |
| A arte da imagem dele | "Bora criar ele" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Totais 305, 400 e 525, com HP e Def.E no alto (125 e 140 na final), Def e Vel baixas | A proposta que o dono aceitou: o tanque especial puro |
| Incomum, crescimento Lento, captura 45, XP 62, 145 e 240 | O patamar das linhas de três formas incomuns (Clod e Lume); o Lento combina com o jabuti |
| As evoluções nos níveis 18 e 36, pelo gatilho de nível | O ritmo das outras linhas de três formas |
| O Traço Casca Dura (4) no slot 1 | O casco de cristal; é o mesmo da linha do Clod e do Sandlurk |
| Nasce na Pedra e na Praia, mais no Rochedo e menos no Coqueiral, de Manhã e de Tarde | Cristal entre as pedras e na areia, tomando sol; a Luz é de dia |
| A altura de 0,35 m, 0,8 m e 1,3 m | A proporção da imagem; a folha de 32 px da Prismback precisa caber na largura do casco |
| Aprende o Beliscão, o Cochilo e o Raio de Sol, que já existem | A mordida do jabuti, o sono e a Luz; o Cochilo combina com o temperamento |

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas.
- Pôr a linha nas áreas das ilhas, que o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-glimshell-line](01-glimshell-line.md) | As três espécies, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-light-skills](02-light-skills.md) | Quatro Técnicas de Luz nos learnsets | concluída (falta o dono conferir no jogo) |

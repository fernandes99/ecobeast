# hopling-line

Uma linha nova de duas formas, a canguru médica: o **Hopling** e a **Pouchmend**, só de Instinto. É o primeiro Ecobeast de suporte: cura os aliados, aumenta a defesa deles e deixa o Jardim no chão, com HP e Defesa Especial em destaque.

## Contexto

Em 2026-11-21, o dono pediu "algum ecobeast mais de suporte", "algum tipo de canguru [...] que vai ter apenas instinto de elemento, e varias habilidades para suporte". Ele aceitou o filhote na bolsa, mesmo lembrando uma criatura conhecida: "Não ligo que seja uma identidade forte de pokemon nesse caso, pode seguir". Entre as três propostas de Claude, escolheu a médica rabugenta: "Vamos de Hopling → Pouchmend".

Ele gerou a imagem da linha numa IA. Ela fica em `art-source/hopling/line.webp`: 1536×1024, com fundo branco, o Hopling à esquerda e a Pouchmend à direita, os dois olhando para a direita. Sobre a ficha, disse: "o hp e defesa especial altos, mas não tanto, o visual não ficou tão 'parrudo' [...] vai ser mais equilibrado do que eu imaginava mas ainda se destacando pelo hp e defesa especial".

A imagem mostra:

- **Hopling:** um canguru filhote esguio, de pelo laranja-areia com a barriga creme e as patas marrons, as orelhas compridas com o miolo rosado e uma atadura amarrada na testa, com as pontas soltas. Os olhos amarelos são meio fechados, com olheiras, numa cara emburrada. A bolsa é pequena, com uma folha, e ele segura um maço de ervas.
- **Pouchmend:** a canguru adulta, alta e magra, com a mesma atadura (agora com folhas presas) e a mesma cara cansada e rabugenta. Leva uma bolsa grande de pano a tiracolo, com folhas desenhadas, e dela espia o filhote, animado, de olhos grandes e uma folha na boca. Tem ervas presas na cintura e a cauda comprida.

## Objetivos

1. As espécies 31 e 32, com o Elemento, os atributos, o Traço, a evolução, o learnset, os biomas, as zonas e as partes do dia.
2. Os `front.png`, recortados da imagem.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As quatro Técnicas de suporte da [fase 2](02-support-skills.md).

## Anti-objetivos

- Regra nova no motor da luta: as Técnicas usam a cura, a mudança de atributo num aliado e a marca Jardim, que já existem.

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| Um canguru de suporte, só de Instinto | O pedido |
| A médica rabugenta, Hopling → Pouchmend, com o filhote na bolsa | A escolha dele, aceitando a semelhança |
| A arte da imagem dele | "bora seguir para a criação desse ai" |
| Atributos equilibrados, com HP e Defesa Especial em destaque | "mais equilibrado do que eu imaginava mas ainda se destacando pelo hp e defesa especial" |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Incomum, crescimento Médio, captura 45 e 30, XP 62 e 172 | O mesmo patamar das outras linhas de duas formas |
| Totais 305 e 480, com HP e Def.E de 65 e 100 e o resto entre 40 e 80 | Equilibrado, como o dono pediu, sem virar tanque |
| A evolução no nível 28, pelo gatilho de nível | O servidor já oferece esse gatilho |
| O Traço Instinto (2) no slot 1 e nenhum oculto | O único Traço do catálogo ligado ao Elemento dela; não há Traço de suporte |
| Nasce na Planície e na Colina, mais no Mato seco e no Campo florido, de Manhã e no Final de tarde | Campo aberto e ervas; os cangurus saem nas horas frescas |
| A altura de 0,6 m e 1,6 m | A proporção da imagem, com as orelhas |
| A Pouchmend aprende o Brotar (Flora) ao evoluir | As ervas da bolsa; o Brotando cura aos poucos |

## Fora do escopo

- **Tirar os estados ruins de um aliado** (o Remédio Amargo da proposta): pede um efeito novo no motor da luta e fica para uma iniciativa própria.
- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas.
- Pôr a linha nas áreas das ilhas, que o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-hopling-line](01-hopling-line.md) | As duas espécies, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-support-skills](02-support-skills.md) | Quatro Técnicas de suporte nos learnsets | concluída (falta o dono conferir no jogo) |

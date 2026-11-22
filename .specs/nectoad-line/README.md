# nectoad-line

Uma linha nova de duas formas, o sapo do néctar: o **Nectoad** (Toxina) e o **Toxbloom** (Toxina/Flora). É a primeira linha que começa em Toxina, o primeiro Guardião Muralha física e o primeiro Guardião Comum, e a primeira linha pensada para o Campo florido do começo do jogo.

## Contexto

Em 2026-11-22 o dono pediu linhas Comuns do começo do jogo, a começar pelo Campo florido (a zona 13 da Planície). A skill `catalog-balance`, já com os papéis da [creature-roles](../creature-roles/), mostrou:

- No Campo florido, só a Puffcoo (Atacante Veloz) e o Hopling (Suporte Curandeiro, Incomum) nascem mais; à noite, nenhum Ecobeast tem bônus na zona.
- As 4 linhas Comuns (Puffcoo, Snekit, Snelt e Fuzzap) são três Atacantes e um Controlador: nenhuma é Guardião, Suporte ou Lutador.
- Toxina e Psíquico nunca começam uma linha; a Toxina tem só 1 Técnica Especial e 1 de Suporte.
- Nenhuma Muralha física ou mista, e 11 das 17 formas finais são Atacantes.

Das três candidatas (o sapo, a lebre vidente e o carneiro florido), o sapo fechava mais lacunas, e o dono escolheu ele ("O sapo"). A lebre vidente, Suporte Inspirador de Psíquico, fica como a próxima linha do Campo florido.

Claude montou o prompt pela skill `creature-front-prompt` (com o fundo magenta, porque a ideia tinha verde-limão), e o dono mandou a imagem da linha, gerada numa IA ("Aqui, use esse"). Ela fica em `art-source/nectoad/line.webp`, com fundo branco e as duas formas da esquerda para a direita; o Nectoad olha para a frente, um pouco à direita, e o Toxbloom para a esquerda. A imagem saiu um pouco diferente do prompt, e vale ela:

- **Nectoad:** um sapinho agachado de pele verde-limão com pintas rosa, a barriga creme, os olhos laranja de pálpebra caída, uma folha e uma pétala na cabeça, a gola de pétalas rosa em volta do pescoço, os dedos rosa e gotas de néctar verde-limão soltas em volta.
- **Toxbloom:** um sapo enorme e pesado, de pele verde verrugosa com pintas rosa e a barriga creme, o queixo erguido e os olhos meio fechados, com uma flor de lírio carmim e violeta, de estames dourados, aberta por cima das costas e da cabeça, entre folhas, pingando néctar verde-limão, que faz uma poça embaixo dele.

## Objetivos

1. As espécies 43 e 44, com os Elementos, os atributos, os Traços, a evolução, o learnset, os biomas, as zonas e as partes do dia.
2. Os `front.png`, recortados da imagem do dono, e os `face.png`.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As três Técnicas da [fase 2](02-toxin-guard-skills.md), que sustentam o papel.

## Anti-objetivos

- Regra nova no motor da luta: as Técnicas usam o dano, o Envenenado, o Brotando, a mudança de atributo e a marca Poça Tóxica, que já existem.
- Um subpapel 🆕 (Provocador ou Guarda-costas): a linha é Muralha, que já dá para fazer.

## Papel

Pela regra da [creature-roles](../creature-roles/README.md#regras-para-toda-linha-nova):

| | |
| --- | --- |
| **Papel principal** | Guardião Muralha |
| **Secundário** | Controlador Arquiteto (a Poça Tóxica e o Abraço da Flor, que envenenam o chão) |
| **Segundo eixo** | físico, lento (Velocidade 45 no Toxbloom) |
| **Atributos** | (HP 100 + Def 110) / 2 = 105, 30 acima do maior ataque (75) |
| **Traço** | Casca Dura: não recebe golpe crítico |
| **As 3 melhores Técnicas** | Pele de Néctar (sobe as defesas e cura aos poucos), Poça Tóxica (a marca) e Abraço da Flor (o golpe forte, que deixa a marca) |

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| A próxima linha é o sapo do néctar, Guardião de Toxina, no Campo florido | Ele escolheu entre as três candidatas ("O sapo") |
| O desenho de Claude (nomes, números, Técnicas, biomas e a arte proposta) | "Aprovado, faz o prompt" |
| A arte da imagem dele | Ele mandou a imagem da linha ("Aqui, use esse") |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Toxina → Toxina/Flora | O veneno vem do néctar da pele; a flor de verdade só nasce na forma final |
| Totais 290 e 480, com a Defesa de 110 e a Velocidade de 45 na final | Muralha física: aguenta muito e é o último a agir |
| Comum, crescimento Médio, captura 75 e 35, XP 56 e 170 | A base fácil do começo; o XP um pouco acima do Fuzzap (52 e 165) pelo tanque |
| A evolução no nível 22 | Entre a Puffcoo (20) e o Fuzzap (24), as Comuns de duas formas do começo |
| Casca Dura (4) no slot 1 e Raiz Furiosa (5) oculta no slot 3 | Pele grossa de tanque; o oculto puxa a flor das costas |
| Nasce na Planície e no Boreal, o dobro no Campo florido e a metade no Bosque, de Manhã, no Final de tarde e à Noite | O sapo das flores e do orvalho; ocupa a noite do Campo florido |
| A altura de 0,35 m e 1,0 m e o peso de 2 kg e 70 kg | O sapinho de mão e o sapo pesado da forma final |
| Temperamento vaidoso | Cada Ecobeast tem o seu, e nenhum de hoje é vaidoso |

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas.
- Pôr a linha nas áreas das ilhas, que o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-nectoad-line](01-nectoad-line.md) | As duas espécies, os `front.png`, os `face.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-toxin-guard-skills](02-toxin-guard-skills.md) | Três Técnicas novas nos learnsets | concluída (falta o dono conferir no Testar técnica) |

# fuzzap-line

Uma linha nova de duas formas, o lêmingue de estática: o **Fuzzap** (Volt) e o **Blizzvolt** (Volt/Gelo). É o primeiro Ecobeast de Volt puro e o primeiro de controle, que atrapalha o inimigo com o Paralisado e com as marcas no chão em vez de ganhar no dano.

## Contexto

Em 2026-11-22, depois da [snelt-line](../snelt-line/), o dono perguntou qual o próximo Ecobeast. A skill `catalog-balance` mostrou:

- 3 Elementos que nunca abrem uma linha: Volt, Toxina e Psíquico. O Volt só aparecia no Kelpcoil e no Tempestide, e não tinha nenhuma Técnica Física.
- Nenhum Ecobeast de controle, nenhum tanque misto, e o atacante especial rápido com 5 das 16 formas finais.
- A Geleira com 1 linha nativa e a Neve com 2.
- 3 linhas Comuns.

Das três candidatas, o lêmingue de estática fechava mais lacunas (Volt puro, controle, Neve e Geleira, Comum e as Técnicas Físicas de Volt). O dono escolheu ele ("Sim, o lêmingue"), aprovou o desenho de Claude e mandou a imagem da linha, gerada numa IA. Ela fica em `art-source/fuzzap/line.webp`, com fundo branco e as duas formas da esquerda para a direita; o Fuzzap olha para a direita, e o Blizzvolt para a esquerda.

A imagem mostra:

- **Fuzzap:** uma bola de pelo branco e azul-lavanda, de pontas espetadas, com dois olhos azuis enormes e redondos, orelhinhas, as patinhas curtas e uma cauda fofa, com raios amarelos saindo do pelo.
- **Blizzvolt:** um bicho de quatro patas, grande e esguio como uma raposa, de pelo branco, azul, lilás e verde-água em mechas que brilham como aurora, a juba volumosa, o olhar sério e desconfiado, uma orelha de cristal de gelo e outra com um raio amarelo, a cauda enrolada de pelo e cristal, e raios azuis e cristais de gelo soltos em volta.

## Objetivos

1. As espécies 41 e 42, com os Elementos, os atributos, os Traços, a evolução, o learnset, os biomas, as zonas e as partes do dia.
2. Os `front.png`, recortados da imagem, e os `face.png`.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As quatro Técnicas da [fase 2](02-volt-skills.md), as primeiras Físicas de Volt.

## Anti-objetivos

- Regra nova no motor da luta: as Técnicas usam o dano, o estado Paralisado e a marca Geada, que já existem.
- Marca nova no chão: pediria o desenho animado dela no cliente.

## Decisões

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| A próxima linha é o lêmingue de estática de Volt, de controle, na Neve e na Geleira | A recomendação da `catalog-balance` que ele aceitou ("Sim, o lêmingue") |
| O desenho de Claude (nomes, números, Técnicas e biomas) | "Aprovado" |
| A arte da imagem dele | Ele mandou a imagem junto com a aprovação |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Volt → Volt/Gelo | A estática vem do pelo; o gelo chega com a cauda de cristal da forma final |
| Totais 300 e 480, equilibrados, com a Velocidade média (85 na final) | O controle não é o melhor de nenhum atributo: aguenta e atrapalha |
| Comum, crescimento Rápido, captura 75 e 35, XP 52 e 165 | A base fácil de achar; o lêmingue que se multiplica rápido |
| A evolução no nível 24 | As linhas Comuns de duas formas evoluem entre 20 (Puffcoo) e 32 (Snekit) |
| Brisa Ligeira (6) no slot 1 e Instinto (2) oculto no slot 3 | O nervoso que já entra correndo |
| Nasce na Neve, na Geleira e na Montanha, o dobro no Campo de neve e a metade no Pinheiral nevado, de Manhã, no Final de tarde e à Noite | O frio aberto, onde o pelo junta estática; a aurora da noite |
| A altura de 0,25 m e 0,9 m e o peso de 1,5 kg e 45 kg | O lêmingue pequeno e o bicho grande e esguio da imagem |

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas.
- Pôr a linha nas áreas das ilhas, que o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-fuzzap-line](01-fuzzap-line.md) | As duas espécies, os `front.png`, os `face.png` e as folhas do mapa | concluída |
| 2 | [02-volt-skills](02-volt-skills.md) | Quatro Técnicas novas nos learnsets | concluída |

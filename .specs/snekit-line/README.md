# snekit-line

Uma linha nova de duas formas, a serpente: o **Snekit** (Instinto) e o **Venomaw** (Instinto/Toxina). É a primeira linha com Toxina, e a evolução é por Vínculo com o Domador mais o nível 32.

## Contexto

Em 2026-11-20, o dono pediu um Ecobeast novo baseado em serpente: "Algo mais basico", "Que tenha apenas instinto e tóxico", com só duas formas. Ele escolheu o par Snekit → Venomaw, entre três propostas de Claude.

Depois, ele gerou a imagem da linha numa IA. Ela fica em `art-source/snekit/line.webp`: 1774×887, com fundo transparente, o Snekit à esquerda e o Venomaw à direita. Também pediu: "recrie a descrição dela com base na imagem".

Sobre a personalidade, o dono disse: "nem todos serão simpaticos [...] alguns serão timidos, raivosos". Cada Ecobeast tem um temperamento próprio, e estes dois não são fofos.

A imagem mostra:

- **Snekit:**
  - uma cobrinha enrolada, de escamas roxo-ameixa com marcas verde-limão em forma de chama e a barriga creme em placas;
  - três espinhos para trás na cabeça e a ponta da cauda numa barbatana curva com uma lasca verde;
  - os olhos verde-limão meio fechados, num olhar de lado, desconfiado e debochado, com a língua vermelha bifurcada de fora.
- **Venomaw:**
  - uma serpente grossa e pesada, de várias voltas, com as mesmas cores e as marcas verdes maiores, como labaredas;
  - uma juba de espinhos em volta da cabeça;
  - a boca escancarada, com presas longas, a língua de fora e o veneno verde pingando;
  - raivosa e ameaçadora.

## Objetivos

1. As espécies 23 e 24, com os Elementos, os atributos, os Traços, a evolução, o learnset, os biomas e as partes do dia.
2. Os `front.png`, recortados da imagem.
3. As folhas `idle.png` e `walk.png` do mapa, pela skill `creature-sprites`.
4. As Técnicas de serpente da [fase 2](02-serpent-skills.md), depois do ok do dono.

## Anti-objetivos

- Regra nova no motor da luta.
- O sistema de Vínculo: ele mora na iniciativa [bond](../bond/README.md).

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| Uma serpente básica, só de Instinto e Toxina, com duas formas | O pedido |
| Os nomes Snekit e Venomaw | A escolha dele entre as propostas |
| O Snekit é Instinto puro, e o Venomaw é Instinto/Toxina | "Snekit (Fera)", "Venomaw (Fera/Toxina)" da proposta escolhida. O Elemento 13 se chama Instinto no banco |
| Temperamentos próprios, e nenhum simpático | "preciso de mais singularidade de cada um deles" |
| A arte da imagem dele | "Vamos criar esse ecobeast" |
| A evolução é por Vínculo com o Domador mais o nível 32 | "A evolução será através da amizade com o treinador + level (32)" |
| Seguir com a linha e as Técnicas de serpente, com o Vínculo depois | "vamos continuar daqui, pode seguir", depois de ver a ficha com as 4 Técnicas |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| As descrições do Bestiário da [fase 1](01-snekit-line.md) | Reescritas pela imagem, a pedido do dono |
| Comum, crescimento Médio, captura 80 e 30, XP 58 e 170 | Uma cobra de campo, fácil de achar. O Venomaw é mais difícil de pegar. A captura vai de 0 a 100 (a proposta de 190 e 60 não cabia) |
| Atacante física rápida, de Defesa média: totais 295 e 470 | Bote rápido; duas formas, como o Hushling (o Echofrost soma perto de 470) |
| O Vínculo mínimo de 220 | O mesmo número do Hushling e do GDD ("Bond ≥ 220 ao subir de nível") |
| O Traço Instinto (2) no slot 1 e nenhum oculto | O único Traço do catálogo que combina; não há Traço de Toxina |
| Nasce na Planície, na Colina e no Deserto, de Tarde e no Final de tarde | Uma cobra que toma sol nas pedras quentes |
| Na fase 1, o learnset usa só Técnicas que já existem | As de serpente vêm na fase 2, como as de Sombra na [lume-line](../lume-line/) |

## Ponto aberto: a evolução por Vínculo

Hoje o jogo não faz evolução por Vínculo, e a próxima sessão precisa saber disso:

- A tabela `evolutions` já guarda as duas condições numa linha: `evolution_trigger_id` 3 (`bond`), `min_level` 32 e `min_bond` 220.
- O servidor só oferece a evolução de gatilho `level`: veja `evolutionOffer` em `server/src/domain/progression/evolution.ts`, que ignora as outras.
- O Vínculo (`bond`) de todo Ecobeast nasce em 70 (`START_BOND` no `server/src/domain/rules/creature-factory.ts`), e nada o faz subir.
- O Hushling evolui para o Echofrost com Vínculo 220 e já está travado hoje.

**Os dois caminhos:**

1. **A linha agora e o Vínculo depois (recomendado por Claude):** a fase 1 grava a regra como ela é. Até a [bond](../bond/README.md) existir, o Snekit não evolui, e o Venomaw só aparece selvagem.
2. **O Vínculo antes:** fazer a [bond](../bond/README.md) primeiro e só depois a fase 1.

Em 2026-11-20, o dono mandou seguir ("vamos continuar daqui, pode seguir"), e Claude foi pelo caminho 1, o recomendado: a regra está gravada, e a evolução espera a [bond](../bond/README.md).

## Fora do escopo

- O `board.png`, as folhas da luta (`battle/`) e o `call.wav`.
- Os ícones, os efeitos e os sons das Técnicas novas, que vêm depois, como na [board-battle/29](../board-battle/29-earth-volt-water-flora-skills.md).
- Pôr a serpente nas áreas das ilhas, que o dono faz pelo F2.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-snekit-line](01-snekit-line.md) | As duas espécies, os `front.png` e as folhas do mapa | concluída (falta o dono conferir no jogo) |
| 2 | [02-serpent-skills](02-serpent-skills.md) | Quatro Técnicas de serpente nos learnsets | concluída (falta o dono conferir no jogo) |

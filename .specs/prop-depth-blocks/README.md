# prop-depth-blocks

Três ajustes nas peças soltas:

- **Ordem de desenho:** o Domador e os outros atores entram na frente ou atrás de cada peça pela altura do pé, também entre hexágonos de linhas vizinhas.
- **Bloqueio padrão por variante:** as pedras grandes e as árvores grandes dos pacotes já nascem bloqueando.
- **Ferramenta Bloqueios:** o editor edita as linhas de qualquer peça do mapa sem escolher a peça antes.

## Contexto

Em 2026-11-15, andando na ilha "Teste dos pacotes" ([vegetation-packs](../vegetation-packs/)), o dono viu uma árvore cobrindo o Domador, que estava na frente dela. Ele disse: "isso é para os outros objetos também. Principalmente se ele está em outro hexágono". Pediu também:

- "nas pedras grandes devem ter bloqueio de passagem, também nas bases das árvores grandes";
- "quero ter o controle dos bloqueios gerais no map editor, talvez separar em uma camada apenas para eu visualizar os bloqueios e poder editar".

O que Claude achou no `HexMapView`:

- **A linha do hexágono manda na ordem.** Cada linha de hexágonos desenha o chão e depois 4 faixas de decoração, e a linha seguinte vem inteira depois. A ponta de baixo de um hexágono entra na linha de baixo, no zigue-zague. Quem tem o pé ali fica atrás de tudo da linha seguinte, mesmo de uma peça com o pé mais acima, que está atrás dele.
- **As faixas são largas.** Uma faixa tem 14,5 px. O ator entra na divisa mais perto do pé e erra até uns 7 px.
- **As malhas da mesma faixa não se comparam.** Dentro de uma faixa, cada textura é uma malha, desenhada uma depois da outra.

Claude mostrou duas formas de editar os bloqueios. O dono escolheu a "Opção A": uma ferramenta no editor com os pontos de todas as peças editáveis. Ele não quis o painel do catálogo que desenha o padrão sobre a arte ampliada.

## Objetivos

1. O ator fica na frente de toda peça com o pé atrás do dele, a até uns 3 px de erro, entre linhas e entre hexágonos.
2. O bloqueio padrão pode ser de uma variante. As pedras e as árvores grandes dos pacotes já vêm com o delas.
3. Um bloqueio só bloqueia o hexágono para o servidor quando pega o centro dele.
4. A ferramenta Bloqueios edita as linhas de qualquer peça e salva o padrão de uma variante ou do tipo.

## Anti-objetivos

- O paredão de um hexágono mais alto continua cobrindo o que está atrás dele.
- Nenhuma mudança no mapa sorteado além da ordem de desenho.
- A floresta com bloqueio nas árvores não perde os Ecobeasts.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| A ferramenta Bloqueios mostra as linhas de todas as peças com os pontos editáveis, sem escolher a peça | "Opção A" |
| Pedras grandes e base das árvores grandes bloqueiam por padrão | Pedido do dono, que também evita o ator encostar no pé da árvore |
| Um hexágono só conta como bloqueado no servidor quando o bloqueio pega o centro dele | "Só se pegar o centro". Antes, qualquer toque bloqueava ([free-objects](../free-objects/README.md#decisões)), e uma floresta de árvores com bloqueio ficaria sem Ecobeasts |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e no `architecture.md`):

| Decisão | Motivo |
| --- | --- |
| A ordem vem do pé no chão plano, em fatias de 42 px (a altura de uma linha), com 6 faixas de 7 px cada | O pé de qualquer hexágono cai numa fatia só, e 7 px deixam o erro em 3,5 px |
| Uma peça só passa para a fatia da linha de baixo quando os dois vizinhos de baixo não são mais altos que o hexágono dela | Senão, o paredão do vizinho mais alto deixaria de cobri-la |
| "Pega o centro" é ter o centro dentro de uma linha fechada ou a até 8 px de um trecho | 8 px é o `TOUCH_REACH`. Com menos, o Domador e o Ecobeast não cabem no centro |
| As pedras bloqueiam nas variantes 1 e 2, e as árvores nas variantes 1 e 2. O bloqueio é calculado da arte: uma linha fechada em volta da base da pedra e uma elipse pequena no pé do tronco | São os tamanhos do grupo "Pedras grandes (pacote)" e as árvores que cobrem o Domador |
| O bloqueio do tipo guarda a variante (0 vale para todas). Uma variante com linhas próprias usa só as dela | A tabela continua uma só, e os tipos de antes continuam com a variante 0 |

## Fora do escopo

- Desenhar a arte de cada peça num painel do catálogo, fora do mapa (a "Opção B").
- Bloqueio por altura (passar por baixo de um arco).
- Ordenar duas texturas diferentes dentro da mesma faixa de 7 px.

## Pré-requisitos

- [free-objects](../free-objects/): as linhas de bloqueio, a camada Bloqueios e o cadeado da peça.
- [vegetation-packs](../vegetation-packs/): os tipos e as variantes dos pacotes.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-depth-order](01-depth-order.md) | A ordem de desenho pelo pé, em fatias e faixas de 7 px, e os atores que passeiam entrando pela altura do pé | concluída (falta o dono jogar) |
| 2 | [02-variant-blocks](02-variant-blocks.md) | O bloqueio padrão por variante, os padrões das pedras e árvores grandes, e o hexágono bloqueado só pelo centro | concluída (falta o dono conferir no editor) |
| 3 | [03-blocks-tool](03-blocks-tool.md) | A ferramenta Bloqueios do editor | concluída (falta o dono usar) |
| 4 | [04-tap-through](04-tap-through.md) | Tocar na arte de uma peça sem ação anda até o ponto tocado, no chão atrás dela | concluída (falta o dono jogar) |

O desenho compartilhado está no [architecture.md](architecture.md).

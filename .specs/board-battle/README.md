# board-battle

A luta passa a acontecer num **tabuleiro de hexágonos**. Cada Ecobeast ocupa um hexágono, age sozinho na sua vez, numa fila pela Velocidade, e na vez dele pode andar e depois usar uma Técnica. As Técnicas ganham alcance e forma no chão, e algumas deixam o chão marcado, como em chamas, por algumas vezes da fila.

A ideia é do dono, em 2026-11-04, inspirada no formato de um jogo tático por turnos que ele mandou em print. Do print vale só o formato: nenhum nome, termo ou visual dele entra no jogo. Ela substitui a [battle-slots](../battle-slots/), da qual fica só o motor com vários Ecobeasts por lado, que serve de base.

A luta nova substitui a de hoje em Explorar zona. A luta atual deixa de ser usada em qualquer lugar, mas o código dela fica no repositório, como legado, até o dono ficar satisfeito com a nova e pedir para apagar.

## Objetivos

- Lutas de 1 contra 1, 2 contra 2 e 3 contra 3 num tabuleiro de 6 × 7 hexágonos. As lutas de Explorar zona continuam 1 contra 1, e as maiores existem na batalha de teste.
- Uma fila de vezes por Velocidade, à mostra no topo da tela. Na sua vez, o jogador anda e depois age.
- Técnicas com alcance, forma e marca no chão, vindas do catálogo e editáveis pelo painel.
- O servidor continua decidindo tudo: caminho, alcance, quem foi atingido, dano, marcas e a vez dos selvagens. O jogo desenha e prevê o que é só visual.

## Decisões

| Decisão | Motivo |
| --- | --- |
| Tabuleiro de 6 colunas × 7 linhas, fixo e sem obstáculos. No futuro ele varia com o bioma e pode ser sorteado | Decisão do dono ("pequeno e fixo por enquanto"). O servidor manda a lista de hexágonos, para o tabuleiro poder mudar sem mudar o contrato |
| Cada lado começa numa área de 2 linhas: os selvagens nas duas de cima, os do jogador nas duas de baixo, a 4 hexágonos uns dos outros | Decisão do dono, a partir do rascunho da opção "pequeno e fixo" |
| Lutas de 1×1, 2×2 e 3×3 | Decisão do dono |
| Uma fila por Velocidade, com empate sorteado. Cada Ecobeast age sozinho na sua vez, e o jogador joga cada um dos seus quando a vez dele chega | Decisão do dono |
| A fila é montada no começo de cada rodada. Uma mudança de Velocidade no meio da rodada só vale na próxima | Proposta aceita pelo dono: a fila na tela não fica pulando |
| A prioridade das Técnicas não vale no tabuleiro, por enquanto | Proposta aceita pelo dono: na fila, a Técnica é escolhida quando a vez já chegou, e não há nada para a prioridade furar |
| Na vez, o Ecobeast pode andar 1 hexágono e depois agir. As duas partes são opcionais, e andar vem sempre antes de agir | Proposta do planejamento, aceita pelo dono ("faz como você faria"), com 3 hexágonos. Em 2026-11-05, depois de jogar a tela, o dono baixou para 1 ("inicialmente vamos ter um limite de andar apenas um bloco por turno"). O número é _a revisar_ |
| O movimento é o mesmo para todos, e não sai da Velocidade | Proposta aceita pelo dono: a Velocidade já decide a fila, e não deve contar duas vezes |
| Cada Técnica tem alcance, forma, se atravessa os Ecobeasts e uma marca no chão opcional, com a duração. Por enquanto, as formas são um alvo a até N hexágonos e a linha reta | Decisão do dono. Áreas maiores, empurrar e puxar ficam para depois, uma de cada vez |
| No começo, só 3 Técnicas ganham forma: Arranhão (corpo a corpo), Faísca Rápida (linha reta) e Chama Espiral (à distância, deixa o chão em chamas). As outras ficam corpo a corpo, com alcance 1 | Decisão do dono: 2 ou 3 Técnicas no início, e as outras corpo a corpo. A escolha das 3 é _a revisar_ |
| A marca no chão age sobre quem estiver no hexágono **depois de cada vez da fila**, de qualquer Ecobeast, e a duração conta vezes da fila. Passar pelo hexágono andando não aplica nada | Decisão do dono |
| Quem entra depois de uma queda entra num hexágono livre da área de largada do próprio lado, que o jogador escolhe. Quem entra numa troca entra no hexágono de quem saiu. Quem entra só age na rodada seguinte | Proposta aceita pelo dono: entrar em qualquer lugar seria roubado, e entrar onde o outro caiu é quase sempre no meio da briga |
| Item, troca, Esfera e fuga gastam a vez de quem está jogando. A Esfera vale contra qualquer selvagem do tabuleiro, a qualquer distância. A fuga vale para a equipe toda | Decisão do dono, para a Esfera. O resto é a regra de hoje |
| Sem caixa de mensagens: um botão de informação abre o histórico da luta | Decisão do dono |
| Fim, XP e moedas como hoje: o XP vai para quem esteve no tabuleiro contra o selvagem, e cada selvagem derrubado paga moedas | Regra de hoje, da [progression](../progression/) e da [battle-slots/01](../battle-slots/01-engine-slots.md) |
| As regras ficam no servidor, e o jogo prevê o que é só visual: onde dá para andar e a área de cada Técnica. Um pedido por vez do jogador, e a resposta traz a vez de todos os selvagens até a próxima vez dele | Decisão do dono, depois de comparar com regras no jogo. A captura, o XP e as moedas ficam gravados, e regras no jogo deixariam trapacear neles |
| Pedidos HTTP, como hoje. A luta é desenhada como troca de mensagens (a vez vai, os acontecimentos voltam), para trocar por socket quando houver luta contra outro jogador | Decisão do dono |
| A luta nova nasce em rotas novas, ao lado das antigas, e só toma o lugar da atual em Explorar zona na [05](05-board-actions.md), quando ela já tem Mochila, Esfera, troca e fuga | Escolha do planejamento: cada fase é um commit, e o jogo não pode perder a captura entre eles |

## Fora do escopo

- Tabuleiros sorteados, obstáculos, relevo e o tabuleiro por bioma.
- Áreas maiores que a linha, como a área de 6 hexágonos, empurrar e puxar.
- A prioridade das Técnicas.
- Animações de Técnica. O Ecobeast anda com a folha `walk`, e o resto é estático, com números de dano.
- Luta contra Domador NPC e contra outro jogador, e o socket.
- Apagar a luta antiga. Isso só acontece quando o dono pedir.

## Pré-requisitos

- [battle-core](../battle-core/), [capture](../capture/), [team-and-storage](../team-and-storage/) e [progression](../progression/) concluídas.
- O motor com vagas da [battle-slots/01](../battle-slots/01-engine-slots.md), commitado.
- As folhas `idle.png` e `walk.png` dos Ecobeasts (skill `creature-sprites`). Quem não tem folha aparece com o `front.png` reduzido.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-skill-areas](01-skill-areas.md) | Catálogo: alcance, forma, atravessar e marca no chão das Técnicas, com as 3 primeiras | concluída |
| 2 | [02-board-engine](02-board-engine.md) | Servidor: o motor do tabuleiro, com fila, andar, áreas, marcas, IA, queda, troca, Esfera, fuga e fim | concluída |
| 3 | [03-board-api](03-board-api.md) | Servidor: as rotas da luta no tabuleiro, ao lado das antigas | concluída |
| 4 | [04-board-screen](04-board-screen.md) | Jogo: a tela do tabuleiro, com a vez, andar, Técnicas, os selvagens, a entrada depois de uma queda e o histórico, aberta pelo menu de depuração | concluída |
| 5 | [05-board-actions](05-board-actions.md) | Jogo: Mochila, Esfera, troca e fuga. Explorar zona passa a usar o tabuleiro, e o andar cai para 1 hexágono | concluída (falta o teste do dono no editor) |

O desenho compartilhado está no [architecture.md](architecture.md).

## Referência

Em 2026-11-04, o dono mandou dois prints de um protótipo de outro jogo: um tabuleiro de hexágonos numa clareira de floresta, com a área vermelha dos inimigos em cima, a verde dos aliados embaixo, a fila de vezes e o painel de ações. Vale só o formato.

Os rascunhos da conversa (os três tamanhos de tabuleiro e a tela) ficaram em `.superpowers/brainstorm/`, fora do repositório.

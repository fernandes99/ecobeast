# npc-tamers

Domadores controlados pelo jogo. Eles nascem ao acaso no mapa de Explorar zona, cada um passeando no próprio hexágono, e quem entra no hexágono de um deles é desafiado: uma fala aparece no log, o mapa trava e tocar no log começa a luta, que é obrigatória. O botão **Desafiar** do Hub também passa a funcionar, contra um Domador sorteado na hora.

A ideia é do dono, em 2026-11-09. As equipes são sorteadas por enquanto; Domadores com nome e equipe montados à mão (a "equipe fixa" do roadmap, na tabela `npc_tamers`) ficam para outra iniciativa.

## Contexto

O que já existe e esta iniciativa reaproveita:

- **Lutas de 1×1, 2×2 e 3×3** no tabuleiro ([board-battle](../board-battle/)): o motor já aceita até 3 vagas por lado, e hoje só a batalha de teste do menu Debug as usa. Quando um Ecobeast cai e há reserva, o próximo entra.
- **Sem fuga:** o `BattleState.canFlee` já existe, comentado "Falso contra Domadores", e o motor do tabuleiro já recusa a fuga com ele desligado.
- **Ecobeasts no mapa** ([biome-encounters](../biome-encounters/)): a exploração fica guardada na memória do servidor (`ExplorationStore`), com os selvagens por hexágono, e o servidor confere se o Domador chegou ao hexágono andando (`MIN_STEP_MS`). O nível do selvagem sai da média da equipe (`wildLevel`) e a espécie das taxas do bioma (`spawnWeight`).
- **Recompensas** ([progression](../progression/)): XP e moedas por Ecobeast derrubado, gravados no fim da luta. A progression deixou para esta iniciativa o bônus de XP contra Domador (1,5×, do `GDD.md`) e as moedas dos Domadores: as do selvagem são pequenas de propósito.
- **O Domador do mapa** é o `TamerSprite`, com as folhas do template (`res://assets/tamer/idle.png` e `run.png`). Os NPCs usam as mesmas folhas.
- **Desafiar** já é um card do Hub ("Enfrente outros Domadores."), que hoje abre a tela placeholder.

## Objetivos

1. Cada mapa de Explorar zona nasce com alguns Domadores NPC, cada um num hexágono de terra, passeando dentro dele.
2. Entrar no hexágono de um Domador trava o mapa e mostra no log uma fala dele, sorteada entre as do catálogo. Tocar no log começa a luta. Não há como recusar.
3. Cada Domador luta 1×1, 2×2 ou 3×3, sorteado, com uma equipe sorteada pelo bioma do hexágono e pela média da equipe do jogador.
4. Vencer paga mais XP e moedas que um selvagem. Perder tira moedas e leva o jogador de volta ao Hub, encerrando a exploração.
5. Desafiar, no Hub, abre na hora uma luta contra um Domador sorteado. Na luta de N×N, entram os N primeiros Ecobeasts da equipe.
6. O servidor decide tudo: onde estão os Domadores, a equipe, o tamanho da luta, a vez deles, as recompensas e o fim da exploração.

## Decisões

Do dono, em 2026-11-09:

| Decisão | Motivo |
| --- | --- |
| Os Domadores nascem ao acaso quando o mapa é gerado, e cada um fica num hexágono, passeando dentro dele | Pedido do dono |
| Os NPCs usam o mesmo sprite do Domador do jogador, o do template | Pedido do dono |
| Entrar no hexágono de um NPC mostra no log uma fala sorteada entre 3, e tocar no log começa a luta | Pedido do dono, que pediu para inventar as 3 falas |
| A luta é obrigatória: com a fala no log, não dá para andar, Procurar, abrir a Mochila nem voltar | Pedido do dono: "não vai ter como fazer nada quando o log tiver passando" |
| Cada NPC luta 1×1, 2×2 ou 3×3, sorteado | Pedido do dono |
| Vencer dá mais moedas e XP que um selvagem | Pedido do dono |
| Perder tira moedas e volta ao Hub | Pedido do dono ("voltar para o lobby") |
| Depois da luta, o NPC some do mapa | Proposta aceita pelo dono, igual ao selvagem |
| A equipe do NPC sai das taxas do bioma e da média da equipe do jogador, como os selvagens. A equipe fixa fica para outra iniciativa | Decisão do dono: "por enquanto vamos fazer randomicamente" |
| Desafiar, no Hub, enfrenta um Domador sorteado | Pedido do dono |
| Na luta de N×N, entram os N primeiros da equipe, e quem cai pode ser substituído pelos outros, até os 6 | Pedido do dono. É a regra de hoje do tabuleiro: a largada põe os primeiros de pé, na ordem da equipe, e depois de uma queda o jogador escolhe quem entra e em qual hexágono (`choose_next`) |

Propostas do planejamento aceitas pelo dono em 2026-11-09 ("ta tudo certo"), todas _a revisar_:

| Decisão | Motivo |
| --- | --- |
| Os três tamanhos têm a mesma chance | O mais simples. Fica em `TAMER_CONFIG` |
| No mapa, a espécie de cada Ecobeast do NPC sai das taxas do bioma de encontro do hexágono dele, e o nível do `wildLevel`. No Desafiar, valem as taxas de todos os biomas | Reaproveita as regras dos selvagens: o NPC fica no nível do jogador, e uma evolução continua rara para um time abaixo do nível dela |
| Cerca de 25 Domadores por mapa, nunca na água | 500 selvagens dão cerca de 3 por tela. 25 Domadores dão um a cada 6 ou 7 telas |
| Cada Domador tem um nome sorteado de uma lista, e a fala aparece com ele: "Lia: O que está fazendo aqui? Vamos nos enfrentar!" | Dá cara ao NPC sem a equipe fixa |
| No Desafiar, o chão do tabuleiro é o da planície (`temperate`, `flat`), e o jogador volta ao Hub, vencendo ou perdendo | O Hub não tem hexágono. A planície já é o chão padrão do tabuleiro (`BoardView.DEFAULT_BIOME`) |
| XP de 1,5× o do selvagem | É o bônus de Domador do `GDD.md` |
| Moedas com a conta do selvagem, com base 60 na vitória (por Ecobeast derrubado) e 15 na derrota | Três vezes as bases do selvagem (20 e 5) |

Escolhas do planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| As falas e os nomes moram no catálogo, em `npc_tamer_greetings` e `npc_tamer_names`, editáveis pelo painel. O mapa e a luta mandam só os ids | Regra do projeto: dados de design são tabelas, e o estado guarda só ids. O dono troca as frases sem commit |
| A equipe de um NPC tem exatamente N Ecobeasts, sem reserva | O tamanho sorteado é o tamanho da equipe, e a luta é fácil de ler. A reserva do NPC pode vir com a equipe fixa. _A revisar_ |
| Do lado do jogador, as vagas são N, ou menos se ele tiver menos Ecobeasts de pé | O motor aceita vagas diferentes por lado. Um jogador com 1 Ecobeast de pé ainda pode lutar contra um 3×3, sem ficar preso |
| O NPC não nasce no hexágono de largada nem a até 3 hexágonos dele, e nunca dois no mesmo hexágono | Ninguém é desafiado ao abrir o mapa, e um hexágono tem um só desafiante |
| O NPC divide o hexágono com selvagens, e a luta contra ele vem primeiro: o servidor recusa Procurar nesse hexágono enquanto o Domador estiver lá. Os selvagens continuam lá depois | Não muda o sorteio dos selvagens, e um cliente alterado não pula o Domador |
| Fechar o app com a fala na tela escapa do Domador, porque a exploração seguinte gera outro mapa | O servidor não sabe dos passos, só das lutas. É o mesmo aceite de "Abandonar batalha" do [roadmap](../roadmap.md) |
| A Esfera é recusada contra Ecobeast de Domador, e a tela não oferece Esferas nem Fugir nessa luta | O original faz assim, e a fuga já tem o `canFlee` |
| A derrota contra um NPC do mapa apaga a exploração no servidor | O servidor garante o "volta ao Hub": o mapa não pode ser retomado |
| Se o servidor recusar a luta (equipe toda sem HP, exploração vencida), a tela da luta mostra o motivo, como hoje, e de volta ao mapa ele fica destravado até o jogador sair do hexágono e entrar de novo | Senão, o jogador ficaria preso num hexágono sem poder lutar nem sair |
| A derrota contra um selvagem continua como hoje: volta para o mapa | Fora do pedido do dono |
| Um botão no menu Debug do mapa põe um Domador de 1, 2 ou 3 no hexágono do jogador, como o spawn de Ecobeast. A equipe dele usa as taxas de todos os biomas, como a do Desafiar | É como o dono testa as três lutas sem procurar pelo mapa. O servidor não guarda os hexágonos, então não sabe o bioma de onde o jogador está |

## Fora do escopo

- A equipe fixa, com Domadores nomeados e equipes montadas à mão na tabela `npc_tamers`.
- Arenas, Mestres de Arena e a Liga (`arenas-league`).
- NPC que anda entre hexágonos, persegue o jogador ou vê o jogador de longe.
- Sprite próprio do NPC, retrato, nível do Domador e falas de vitória ou de derrota do NPC.
- Reserva na equipe do NPC, troca de Ecobeast pelo NPC e uso de itens pelo NPC.
- Bater de novo no mesmo Domador. Ele some, e o mapa só se renova na próxima exploração.
- Mostrar os Domadores e os textos no visualizador de conteúdo (F1) da [content-viewer](../content-viewer/).
- Apostas e Desafiar contra outro jogador.

## Pré-requisitos

- [board-battle](../board-battle/), [biome-encounters](../biome-encounters/) e [progression](../progression/) concluídas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-tamer-texts](01-tamer-texts.md) | Catálogo: as tabelas `npc_tamer_names` e `npc_tamer_greetings`, com os nomes e as 3 falas | concluída |
| 2 | [02-tamer-rules](02-tamer-rules.md) | Servidor, regras puras: os Domadores do mapa, o desafiante do Hub e a luta contra Domador (sem Esfera, sem fuga, XP e moedas maiores) | concluída |
| 3 | [03-tamer-api](03-tamer-api.md) | Servidor: os Domadores no mapa, as rotas da luta do mapa, do Desafiar e de depuração, e a exploração encerrada na derrota | rascunho |
| 4 | [04-map-tamers](04-map-tamers.md) | Jogo: os Domadores passeando no mapa, a fala que trava o mapa, a luta contra eles e a volta ao Hub na derrota | rascunho |
| 5 | [05-hub-challenge](05-hub-challenge.md) | Jogo: Desafiar, no Hub, abre a luta contra um Domador sorteado | rascunho |

O desenho compartilhado está no [architecture.md](architecture.md).

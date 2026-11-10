# battle-intro

A abertura da luta: a transição de zoom pixelado e a música retrô. Ao enfrentar um Ecobeast selvagem ou um Domador, a tela pisca, aproxima do Domador enquanto os pixels crescem e escurece, e a luta aparece desfazendo o pixelado. Uma música de luta toca desde a transição até o fim, uma para selvagem e outra para Domador, e a vitória tem um toque curto próprio.

A ideia é do dono, em 2026-11-10, como um refinamento antes das próximas iniciativas.

## Contexto

O que já existe e esta iniciativa reaproveita:

- **As entradas da luta:** a tela de exploração abre a tela `board_battle` pelo Procurar, pelo toque no log do Domador NPC e pelos botões de teste do Debug. O Hub a abre pelo Desafiar. Todas usam `Router.push`.
- **A tela da luta** (`res://screens/board_battle/board_battle_screen.gd`) pede a luta ao servidor em `_begin`, monta o tabuleiro e mostra a abertura. No fim, `_show_exit` mostra o resultado, e `_leave` volta.
- **Sons:** a luta já toca os sons das Técnicas e dos golpes com `AudioStreamPlayer`, todos no canal Master. O jogo ainda não tem música, nem canal de áudio separado.
- **O roadmap** tem a `audio` (#18), com os sons do jogo. Esta iniciativa traz só a música da luta. O resto continua lá.

## Objetivos

1. Toda entrada numa luta de verdade mostra a transição de zoom pixelado.
2. Contra selvagem toca uma música, e contra Domador toca outra, em loop do começo ao fim da luta.
3. A vitória e a captura trocam a música pelo toque de vitória. A derrota e a fuga fazem a música sumir aos poucos.
4. As músicas são originais, geradas por um script do projeto que dá para ajustar e rodar de novo.

## Decisões

Do dono, em 2026-11-10:

| Decisão | Motivo |
| --- | --- |
| A transição é o zoom pixelado: dois clarões, a tela aproxima do Domador com os pixels crescendo e escurece, e a luta aparece desfazendo o pixelado | Pedido do dono. Escolhido entre três prévias mostradas no navegador ("Gostei do primeiro") |
| A mesma transição vale para selvagem e para Domador | Proposta aceita pelo dono |
| Música de luta em estilo retrô, como a dos jogos de bolso antigos, com uma composição original | Pedido do dono. A regra do projeto proíbe copiar o Pokémon |
| Duas músicas, uma contra selvagem e outra contra Domador, e um toque curto de vitória | Proposta aceita pelo dono ("pode ser") |

Propostas do planejamento aceitas pelo dono em 2026-11-10 ("Ok pode seguir"), todas _a revisar_:

| Decisão | Motivo |
| --- | --- |
| A transição também abre o Desafiar do Hub e a luta de teste do Debug | Os dois são o jogador enfrentando alguém |
| A volta da luta para o mapa ou o Hub não tem transição | O pedido é a entrada na luta |
| A música começa junto com a transição e toca em loop até o fim. Na vitória e na captura, ela para e toca o toque de vitória. Na derrota e na fuga, ela some aos poucos | O fim da luta muda o clima, como nos jogos de referência |
| As músicas são geradas por um script Python guardado ao lado delas, sem biblioteca de fora, e salvas em `.ogg` pelo `ffmpeg` | Dá para mudar notas e andamento e gerar de novo, como o `sprites.py` dos Ecobeasts |
| Música no mapa e no Hub fica para depois | Fora do pedido |
| Volume e botão de silenciar ficam para o Perfil e as Configurações (`profile-settings`). A música vai para um canal de áudio próprio, `Music`, com volume moderado | O jogo ainda não tem tela de configurações. O canal deixa o volume pronto para ela |

Escolhas do planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| A transição pixela a tela ao vivo, com um shader sobre tudo, e não uma foto da tela | O mesmo efeito serve para cobrir o mapa e para revelar a luta, e o mapa continua animado durante o zoom |
| A transição e a música moram em dois autoloads novos, `BattleIntro` e `Music`, porque continuam enquanto as telas trocam | Uma tela some quando outra abre; um autoload fica |
| O centro do zoom é o Domador do jogador no mapa, inclusive nos botões de teste do Debug. No Hub, é o centro da tela | É de onde a luta "sai". No mapa, o Domador fica quase sempre no meio da tela |
| Se o servidor demorar com a tela já preta, aparece "Procurando..." no meio dela | O jogador não fica olhando uma tela preta sem saber o que acontece |
| O voltar do aparelho não faz nada com a tela coberta, e qualquer troca para uma tela que não seja a luta revela sozinha | A tela nunca fica preta para sempre, nem quando a sessão cai no meio |
| A abertura da luta começa por baixo do pixelado, sem esperar o revelar terminar | A luta fica mais rápida, e o pixelado ainda esconde o primeiro instante |
| Na captura, o toque de vitória começa antes do aviso "Novo registro no Bestiário!" | O toque comemora a captura, e o aviso vem por cima dele |
| A tela da luta revela depois de montar o tabuleiro, ou logo ao mostrar um erro do servidor. Com erro, a música some aos poucos | A luta não aparece pela metade, e um erro não deixa a tela coberta |
| O Desafiar toca a música de Domador, e a luta de teste toca a de selvagem | O Desafiar é contra Domador. A de teste é sempre contra Ecobeasts escolhidos no Debug |

## Fora do escopo

- Transição na volta da luta, entre telas comuns e na luta antiga (legado da `battle-core`).
- Música do mapa, do Hub, de Arena ou de Liga.
- Volume, silenciar e configurações de áudio.
- Sons novos de interface, passos ou Ecobeasts (`audio` e `creature-sounds`).

## Pré-requisitos

- [board-battle](../board-battle/) e [npc-tamers](../npc-tamers/) concluídas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-battle-transition](01-battle-transition.md) | Jogo: o zoom pixelado ao entrar na luta, em todas as entradas | concluída |
| 2 | [02-battle-music](02-battle-music.md) | As músicas e o toque de vitória, o script que as gera e o autoload `Music` tocando na luta | concluída |
| 3 | [03-explore-music](03-explore-music.md) | A música de fundo de Explorar zona, que dá lugar à da luta e volta depois dela | concluída (falta o teste do dono no editor) |

O desenho compartilhado está no [architecture.md](architecture.md).

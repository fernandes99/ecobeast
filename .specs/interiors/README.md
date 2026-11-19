# interiors

Os prédios ganham o lado de dentro. O Domador entra no Refúgio, anda pela sala e fala com quem estiver lá: com o NPC do balcão, a conversa termina no menu de cura de hoje. O interior é uma sala de quadrados de 16 px, montada com o tileset do pacote Main Characters Home, e o dono monta cada sala no F2, como monta as ilhas.

- **Status:** concluída (falta o dono conferir no F2 e no F5)
- **Depende de:** [island-npcs](../island-npcs/), [free-objects](../free-objects/), [home-island](../home-island/), [dialogue-voices](../dialogue-voices/)

## Contexto

Hoje o Refúgio é a peça solta do tipo 22 com a ação `refuge`. O Domador toca no prédio, anda até a linha de bloqueio dele e, ao encostar, o jogo abre a tela `heal_station` por cima de Explorar (`Router.push`): uma lista da equipe com o botão de curar. O Voltar devolve o Domador a Liora, no mesmo ponto. A cura do servidor (`POST /v1/me/heal`) não confere onde o Domador está. O servidor guarda uma exploração só por jogador, e Explorar monta o mapa de hexágonos dela.

O pacote Main Characters Home (craftpix.net, a mesma licença das casas 95 a 97 e da cerca de estacas) traz, na pasta `Tiled_files`, as folhas `walls_floor.png` (chão de tábuas, paredes de pedra com o arremate creme, arcos e portas), `Interior.png` (cama, estantes, mesas, cadeiras, tapetes, poções, barris, plantas) e `Doors_windows_animation.png` (portas e janelas), em tiles de 16 px vistos de cima, de frente, e um quarto de exemplo, o `Interior1.tmx`, do programa Tiled.

O dono pediu: "quando eu entrar no refugio eu quero abrir uma tela do interior do refugio", com o tileset do pacote, para "andar com o Domador e falar no balcão ou com qualquer npc que tiver lá dentro", e "editar as telas de interior como faço nas ilhas no f2".

## Abordagens consideradas

| Abordagem | Troca | Escolha |
| --- | --- | --- |
| **Uma sala de quadrados, numa tela própria por cima de Explorar** | Fiel ao tileset (parede e chão retos) e o Godot desenha os quadrados sozinho (`TileMapLayer`); Liora fica parada embaixo, sem mexer na exploração do servidor. Pede uma tela nova e um modo novo no F2 | **escolhida pelo dono** |
| O interior como uma ilha pequena de hexágonos | Reaproveita o editor, os NPCs e as cenas, mas a parede reta do pacote fica feia sobre hexágonos, e entrar abriria outra exploração no servidor, sorteando Liora de novo na volta | descartada |
| Montar as salas no Tiled e o jogo ler o `.tmx` | Sem editor nosso, mas a sala fica fora do F2 | descartada: o dono quer editar no F2 |

## Objetivos

1. Tocar num prédio com interior leva o Domador para dentro, numa tela própria, e pisar na porta o traz de volta para Liora, no mesmo lugar.
2. Lá dentro, o Domador anda por toque, barrado pelas paredes e pelos móveis, e passa atrás e na frente dos móveis como no mapa de fora.
3. Tocar num NPC abre as falas na caixa de fala, com a voz dele, e a ação dele no fim; no Refúgio, a cura.
4. O dono cria, monta e salva as salas no F2, com a folha do pacote como paleta, e liga cada prédio à sua sala.

## Não objetivos

- Ecobeasts selvagens, Procurar, Domadores NPC, névoa, minimapa ou luta dentro de um interior.
- As cenas da história dentro de um interior.
- Andares (a escada do pacote não leva a lugar nenhum).

## Antiobjetivos

- Sair do interior e achar Liora diferente: os Ecobeasts sorteados de novo, a névoa ou a posição perdidas.
- Uma sala que prende o Domador: a porta coberta por um bloqueio ou o Domador nascendo dentro de um móvel.
- A arte borrada: os tiles sempre em pixels inteiros, como o mapa de fora.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| O interior é uma sala de quadrados numa tela aberta por cima de Explorar | Escolha do dono entre as abordagens acima |
| O Domador anda por toque e fala com os NPCs lá dentro | Pedido do dono |
| A arte é do tileset do Main Characters Home | Pedido do dono; é o mesmo pacote das casas de Liora |
| As salas se montam no F2 | Pedido do dono |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| As salas moram no banco (`interiors` e as tabelas dela), sem rascunho: salvar no F2 já vale no jogo | Dados de design moram no banco ([game-data](../game-data/architecture.md)); o rascunho das ilhas existe porque uma ilha é grande, e uma sala se monta em minutos |
| O jogo baixa a sala ao entrar (`GET /v1/interiors/:id`), e não no catálogo | O catálogo é baixado inteiro no boot, e uma sala tem centenas de tiles que só servem quando o Domador entra |
| A peça solta ganha a sala (`island_props.interior_id`), e a ação dela continua dizendo o que o prédio é | O ícone do Refúgio no minimapa e o nome do prédio continuam vindo da ação; uma peça com sala abre a sala em vez da tela da ação |
| No Refúgio, a cura vem do NPC do balcão, com a ação `refuge` dele | Reaproveita a tela `heal_station` e a regra sem equipe de hoje, sem mudar nada no servidor |
| A sala tem 4 camadas de tiles (chão, detalhe do chão, parede, detalhe da parede) e os objetos, cada um um retângulo de tiles da folha | O tile da parede se ordena pela linha dele, e o objeto pelo pé, para o Domador passar atrás de uma estante alta sem ficar por cima dela |
| O bloqueio é por quadrado: sem chão bloqueia sozinho; a parede sólida e a linha de baixo de cada objeto viram bloqueios ao serem postos, e o resto se pinta à mão | No pacote, a camada de parede também cobre o chão livre com o contorno fino; a transparência do tile separa a parede de verdade sem uma tabela dos 750 tiles, e o servidor não precisa ler as folhas |
| A porta é um quadrado de chão: o Domador nasce nele, e chegar nele vindo de outro quadrado sai | Como a ação de um hexágono, que só dispara para quem entra nele vindo de fora |
| Os NPCs ficam parados lá dentro | O passeio é dos hexágonos; numa sala, parado basta para o balcão |
| Quem segue o Domador nas cenas (`_followers`) não entra | As cenas não tocam lá dentro; entrar junto pede o passeio dos seguidores na grade quadrada. Corrige a proposta da conversa |
| O zoom lá dentro é o degrau de Explorar (`ViewSettings`), sem pinça | Mantém o tamanho da arte igual ao de fora; a pinça lá dentro fica para depois |
| A primeira sala, o Refúgio, nasce do `Interior1.tmx` do pacote, convertido por um script | Dá ao dono uma sala pronta para arrumar, em vez de uma vazia |
| As animações das portas e das janelas ficam paradas no primeiro quadro | A folha guarda os quadros de um jeito que o `TileSet` do Godot não lê; fica para depois |

## Fora do escopo

- As cenas da história, os seguidores e o Testar daqui dentro de um interior.
- A pinça de zoom lá dentro.
- As portas e janelas animadas, as luzes e a hora do dia lá dentro (é sempre de dia).
- Passeio dos NPCs lá dentro.
- Andares e escadas que levam a outra sala.
- Interior para hexágonos de ação (`island_actions`), só para peças.

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01](01-interior-data.md) | As salas no banco: as tabelas, a sala na peça, as rotas do jogo e do editor, e o Refúgio convertido do `Interior1.tmx` | concluída |
| [02](02-interior-screen.md) | A tela do interior: entrar pela peça, desenhar a sala, andar, falar com os NPCs, curar no balcão e sair pela porta | concluída (falta o dono conferir no F5) |
| [03](03-interior-editor.md) | O modo Interiores do F2: criar, pintar, pôr objetos, bloqueios, NPCs e a porta, salvar e ligar a sala à peça | concluída (falta o dono conferir no F2 e no F5) |

O desenho que as fases compartilham está em [architecture.md](architecture.md).

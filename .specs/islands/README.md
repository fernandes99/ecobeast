# islands

Jogar nas ilhas feitas no editor ([map-editor](../map-editor/)). O Hub ganha a ação **Ilhas**, que abre a lista das ilhas publicadas, o mapa-múndi simples por enquanto. Entrar numa ilha abre o mapa dela na tela de Explorar zona, com o Domador na chegada. Pisar no Refúgio ou na Loja abre a tela deles, e os Ecobeasts selvagens nascem pelas áreas que o dono pintou, cada área com a sua quantidade e as espécies e os níveis fixos dela.

A ideia é do dono, em 2026-11-10 e 2026-11-11, na conversa que criou a `map-editor`.

## Contexto

O que já existe e esta iniciativa reaproveita:

- **As ilhas no banco** ([map-editor/01](../map-editor/01-island-records.md)): a versão publicada de cada ilha (`island_maps` com `kind = published`), com os hexágonos, as construções e as áreas de Ecobeasts. Cada área tem uma lista de espécies, e cada espécie tem peso no sorteio e nível mínimo e máximo. Hoje, só as rotas do editor (`/v1/editor`) leem as ilhas.
- **A exploração** ([wild-battle](../wild-battle/), [biome-encounters](../biome-encounters/)): `POST /v1/me/exploration` gera um mapa, sorteia os Ecobeasts (`rollSpawns`) e os Domadores NPC e guarda na memória do servidor os Ecobeasts, os Domadores e a posição (`ExplorationStore`). Procurar (`POST /v1/me/board-battle/wild`) enfrenta um Ecobeast do hexágono do Domador, conferindo a posição (`BattleRecordsService.takeSpawn`).
- **A tela de Explorar zona** (`res://screens/exploration/exploration_screen.gd`): anda pelo mapa, mostra os Ecobeasts perto, Procurar, Mochila, a música de explorar, a luta com a transição, e tira do mapa o Ecobeast enfrentado.
- **As telas do Refúgio e da Loja** (`heal_station` e `shop`), que hoje abrem pelo Hub.
- **A camada de cor do editor** (`HexTintLayer`, em `res://tools/map_editor/`), que pinta hexágonos com uma cor, de perto na altura do terreno.

## Objetivos

1. O jogador escolhe uma ilha publicada no Hub e anda nela como no Explorar zona.
2. Os Ecobeasts de uma ilha nascem só nas áreas, na quantidade de cada área, com as espécies, os pesos e os níveis que o dono definiu.
3. As construções da ilha aparecem no mapa, e o Refúgio e a Loja abrem as telas deles.
4. O Explorar zona sorteado continua igual.

## Decisões

Do dono:

| Decisão | Motivo |
| --- | --- |
| As ilhas são escolhidas numa lista no Hub, que faz o papel do mapa-múndi por enquanto | Pedido do dono ("uma lista por enquanto. Depois melhoramos ele") |
| Chegar numa construção abre a tela dela, como o Hub faz hoje | Pedido do dono |
| O nível dos Ecobeasts de uma ilha é fixo, o da área, e não segue a equipe | Pedido do dono ([map-editor](../map-editor/README.md#decisões)) |
| Por enquanto, a ilha tem só os selvagens das áreas, sem os Domadores NPC sorteados | Pedido do dono ("depois fazemos os npcs sorteados") |
| A quantidade de Ecobeasts de cada área é definida no editor, área por área | Pedido do dono, em vez de uma quantidade proporcional ao tamanho |
| O Explorar zona sorteado continua como está | Pedido do dono, na `map-editor` |

Escolhas do planejamento (corrigíveis; ao mudar uma, atualize aqui e no [architecture.md](architecture.md)):

| Decisão | Motivo |
| --- | --- |
| A ação nova do Hub se chama **Ilhas** e fica depois de Explorar zona, com a cor própria e a arte de Explorar zona até haver uma sua | O Explorar zona continua, então a ilha precisa de uma entrada sua |
| A ilha usa a tela de Explorar zona, e não uma tela nova | Andar, Procurar, Mochila, música e luta já existem lá; o que muda é de onde vem o mapa |
| A mesma rota começa as duas explorações: `POST /v1/me/exploration` sem corpo sorteia como hoje, e com `{island_id}` usa a ilha publicada | A luta, a captura e a posição já usam a exploração guardada; uma ilha é uma exploração com outro mapa |
| Os Ecobeasts de uma ilha são sorteados a cada entrada: em cada área, a quantidade dela, cada um num hexágono da área, com a espécie pelo peso e o nível sorteado entre o mínimo e o máximo | É o mesmo jeito do Explorar zona: o enfrentado sai do mapa, e entrar de novo sorteia de novo |
| Num hexágono sem área (a cidade, por exemplo), Procurar não acha nada, como num hexágono vazio de hoje | Sem área, sem selvagens |
| As construções aparecem como hexágonos na cor do tipo, com o nome por cima, até existir arte | O jogador precisa achar o Refúgio e a Loja; a arte é outra iniciativa |
| Pisar no Refúgio ou na Loja abre a tela; Arena e Casa não fazem nada por enquanto | A Arena é da `arenas-league`, e a Casa não tem tela |
| Fechar a tela da construção volta para a ilha, no mesmo hexágono. Ela só abre de novo ao sair da construção e entrar outra vez; andar dentro de uma construção de vários hexágonos não abre de novo | Não prende o jogador num laço de abrir e fechar |
| Os selvagens de uma área não nascem em hexágono de construção | Um Ecobeast em cima do Refúgio não faz sentido |
| Todas as ilhas publicadas aparecem para todo jogador | A ordem da história e a liberação ficam para depois |
| Uma ilha publicada depois que o jogador entrou só muda para ele na próxima entrada | A exploração fica guardada na memória do servidor, como hoje |

## Fora do escopo

- Os Domadores NPC sorteados nas ilhas, e os Domadores fixos (`npc-fixed-teams`).
- Um mapa-múndi desenhado e a ordem de liberação das ilhas pela história.
- A arte das construções e a Arena funcionando (`arenas-league`).
- O Campo da luta pelo bioma do hexágono (`biome-terrain`).
- Entrar na ilha por outro lugar que não a chegada.

## Pré-requisitos

- [map-editor](../map-editor/) concluída.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-area-spawn-count](01-area-spawn-count.md) | Servidor e editor: a quantidade de Ecobeasts de cada área (`spawn_count`), no banco, nas rotas do editor e no painel de área | concluída |
| 2 | [02-island-exploration](02-island-exploration.md) | Servidor: a lista das ilhas publicadas para o jogador, e a exploração numa ilha, com os Ecobeasts pelas áreas e as construções na resposta | concluída |
| 3 | [03-island-screens](03-island-screens.md) | Jogo: a ação Ilhas no Hub, a tela da lista e a tela de Explorar zona numa ilha, com as construções no mapa e o Refúgio e a Loja abrindo | concluída |

O desenho compartilhado está no [architecture.md](architecture.md).

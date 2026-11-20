# home-island: arquitetura

O desenho que as fases da [home-island](README.md) compartilham.

## A ilha casa

- `islands.is_home` (`Boolean`, padrão `false`), com um índice único parcial (`CREATE UNIQUE INDEX islands_one_home ON ecobeasts.islands (is_home) WHERE is_home`): no máximo uma ilha casa.
- Só uma ilha publicada (`published_at` não nulo) pode virar casa. Ligar a casa numa ilha desliga a da outra na mesma transação.
- `GET /v1/me/islands` devolve, em cada ilha, `home: boolean`. É assim que o jogo descobre a casa: não há id no código nem no catálogo.
- O editor liga a casa por `PUT /v1/editor/islands/:id/home` (corpo `{ "home": true | false }`), atrás do mesmo guard das rotas do editor ([map-editor](../map-editor/architecture.md)).

No jogo, `Session.home_island_id: int` (0 sem casa) é lido ao abrir o jogo, pelo `Session.load_home()` (uma chamada a `list_islands()` logo depois do `load_player()`). Trocar a casa no F2 vale na próxima abertura.

## A ação Viagem

Um tipo de ação novo no catálogo, como o Refúgio e a Loja ([island-villages](../island-villages/architecture.md)):

| id | slug | name | color_hex | kind |
| --- | --- | --- | --- | --- |
| 5 | `travel` | Viagem | `#3FA7A0` _a revisar_ | `open_screen` |

Vale nas três formas que já levam ação: os hexágonos de uma construção (`island_actions`), uma peça (`island_props.action_type_id`) e um NPC (`island_npcs.action_type_id`). Em Explorar, `ACTION_SCREENS` ganha `"travel": &"travel"`, e `MAP_MARKER_ACTIONS` ganha `travel`, com um ícone de barco no minimapa e no mapa grande.

## Navegação

O [Router](../foundation/architecture.md) tem a pilha (`push`/`back`) e o `go_to`, que esvazia a pilha. A regra desta iniciativa:

| De | Para | Como |
| --- | --- | --- |
| Liora | menu do Domador, Equipe, Mochila, a Loja e o Refúgio dos prédios, a tela Viagem | `push`: Liora fica viva embaixo, e o Voltar volta a ela |
| a tela Viagem | outra ilha, a zona, o Desafiar, a Arena | `go_to`: a exploração de Liora acaba |
| qualquer viagem | Liora | `go_to` pelo `Home.go()` |

O servidor guarda uma exploração por Domador (`ExplorationStore`, [wild-battle](../wild-battle/architecture.md)). Começar outra apaga a de Liora; por isso Liora nunca fica embaixo de uma viagem, e voltar a ela pede um mapa novo ao servidor.

`Home` (`client/core/home.gd`, `class_name Home`, só funções estáticas):

- `static func go() -> void`: com `Session.home_island_id > 0`, `Router.go_to(&"exploration", {"island_id": Session.home_island_id})`; sem casa, `Router.go_to(&"hub")`.
- `static func is_home(island_id: int) -> bool` e `static func has_home() -> bool`.

## O menu do Domador

A tela `hub` continua sendo a mesma cena (`res://screens/hub/hub_screen.tscn`), com a equipe, o avatar e a arte de fundo, mas:

- os cartões ficam Refúgio, Santuário, Bestiário e Mochila (sem Explorar zona, Ilhas, Desafiar, Arenas e Loja);
- as abas ficam Equipe, Bestiário e Perfil (a aba Loja sai, e a Home vira o botão Voltar, que volta a Liora);
- sem ilha casa, o Hub é a primeira tela, sem Voltar, com os cartões de antes, e os de viagem viram um só, "Viagem", que abre a tela Viagem ([03](03-travel-screen.md)).

O avatar continua abrindo a Aparência.

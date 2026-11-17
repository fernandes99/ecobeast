# 03. A tela Viagem e as voltas

- **Status:** concluída
- **Depende de:** [02](02-open-at-home.md)

## Contexto

Com o app abrindo em Liora ([02](02-open-at-home.md)), as viagens passam a sair da ação Viagem ([01](01-home-and-travel-data.md)) e a voltar sempre para a casa ([architecture](architecture.md#navegação)).

## Escopo

- A tela Viagem.
- A ação Viagem em Explorar.
- A volta a Liora de outra ilha, da zona, do Desafiar, da Arena e da derrota para um Domador NPC.
- O ícone da Viagem no minimapa e no mapa grande.

## Fora do escopo

- Chegar pelo cais em vez do ponto de início ([README](README.md#decisões)).
- Viajar sem equipe ([liora-intro](../liora-intro/) decide o que a Viagem mostra antes do inicial).

## Requisitos

- **RF-01:** A tela `travel` (`res://screens/travel/travel_screen.tscn`, registrada no `Router`) mostra o título "Viagem", o botão Voltar e, nesta ordem: as ilhas publicadas fora a casa (cada uma pelo nome, como na tela Ilhas), "Explorar zona", "Desafiar" e "Arenas", com os subtítulos de hoje do Hub.
- **RF-02:** Tocar numa ilha faz `Router.go_to(&"exploration", {"island_id": id})`; Explorar zona, `Router.go_to(&"exploration")`; Desafiar, a transição da luta (`BattleIntro.cover`) e `Router.go_to(&"board_battle", {"challenge": true})`; Arenas, `Router.push` do placeholder, como hoje.
- **RF-03:** Em Explorar, encostar numa ação `travel` faz `Router.push(&"travel")`, e o Voltar dela volta ao mapa de Liora.
- **RF-04:** Em Explorar fora da casa, o Voltar faz `Home.go()`. O Voltar do Android e o Esc, também (com a mesma trava de hoje durante o carregamento, a fala, a cena e o desafio).
- **RF-05:** O fim de uma luta de Desafiar e o fim de uma luta que hoje vai ao Hub (`_exits_to_hub()` em `board_battle_screen.gd`, a derrota para um Domador NPC) fazem `Home.go()`. A luta do Desafiar é a única tela da pilha (veio por `go_to`), e é por isso que o `_leave()` usa `Home.go()` sempre que `Router.can_go_back()` é falso.
- **RF-06:** As lutas que saem de Explorar e voltam para o mesmo mapa (`Router.back()`) não mudam.
- **RF-07:** A tela Ilhas (`islands`) sai do Router, e o cartão Viagem do Hub sem casa ([02](02-open-at-home.md), RF-07) passa a abrir a tela Viagem.
- **RF-08:** A Viagem aparece no minimapa e no mapa grande com o ícone `travel` (um barco de 7×7 desenhado pelo `make_minimap_art.py`, no estilo dos ícones do Refúgio e da Loja), quando descoberta, e na legenda do mapa grande como "Viagem".

## Critérios de aceite

- [ ] Em Liora, encostar no cais abre a Viagem; Voltar volta ao mesmo mapa.
- [ ] Ir a outra ilha e tocar em Voltar abre Liora de novo, no ponto de início.
- [ ] Ir à zona, perder para um Domador NPC e sair da luta abre Liora.
- [ ] Desafiar e sair da luta abre Liora.
- [ ] A casa não aparece na lista de ilhas da Viagem.

## Desenho técnico

- `client/screens/travel/` (novo): a tela, a partir do código da `islands_screen.gd`, que sai.
- `client/core/autoload/router.gd`: `travel` entra, `islands` sai.
- `client/screens/exploration/exploration_screen.gd`: `ACTION_SCREENS` e `MAP_MARKER_ACTIONS` com `travel`; o Voltar fora da casa.
- `client/screens/board_battle/board_battle_screen.gd`: `Home.go()` no `_leave()`.
- `client/screens/hub/hub_screen.gd`: o cartão Viagem abre a tela nova.
- O minimapa e o mapa grande: o ícone `travel` com os outros marcadores ([minimap](../minimap/)).

## Verificação

```bash
godot --headless --path client --quit-after 30
```

Manual (F5): os critérios de aceite, com uma segunda ilha publicada.

## Tarefas

- [x] A tela Viagem e o Router.
- [x] A ação em Explorar e o ícone.
- [x] As voltas (Voltar fora da casa, fim do Desafiar, derrota).

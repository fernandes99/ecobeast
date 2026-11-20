# 02. O app abre em Liora, com o menu do Domador

- **Status:** concluída
- **Depende de:** [01](01-home-and-travel-data.md)

## Contexto

Com a casa marcada ([01](01-home-and-travel-data.md)), o jogo passa a começar nela, e o Hub vira o menu do Domador ([architecture](architecture.md#o-menu-do-domador)). As viagens continuam saindo do menu até a [03](03-travel-screen.md); esta fase muda a primeira tela e o papel do Hub.

## Escopo

- A primeira tela do jogador com inicial: Explorar na ilha casa.
- O `Session.home_island_id` e o `Home`.
- O botão Menu em Explorar na ilha casa, no lugar do Voltar.
- O Hub como menu.

## Fora do escopo

- A tela Viagem e a volta das viagens (fase 03).
- O jogador sem nome ou sem inicial ([liora-intro](../liora-intro/)): a entrada (nome, Aparência, inicial) continua como hoje e termina no `Home.go()`.

## Requisitos

- **RF-01:** Depois do `load_player()`, o `main.gd` chama `Session.load_home()`, que lê `list_islands()` e guarda em `Session.home_island_id` o id da ilha com `home`, ou 0. Uma falha dessa chamada mostra o erro de carregamento com "Tentar de novo", como a falha do jogador. A casa só é lida ao abrir o jogo: trocar a casa no F2 vale na próxima vez.
- **RF-02:** `main.gd` abre, para o jogador com inicial, `Home.go()`, e não mais o Hub. A escolha do inicial (`starter_select_screen.gd`) também termina em `Home.go()`.
- **RF-03:** Em Explorar na ilha casa, o botão Voltar vira "Menu", com o mesmo lugar e o ícone `person`, e abre o Hub por `Router.push(&"hub")`. O Voltar do Android e o Esc também abrem o menu, e não saem de Liora.
- **RF-04:** Nas outras ilhas e na zona, o Voltar continua o mesmo até a [03](03-travel-screen.md).
- **RF-05:** O Hub, aberto em cima de Liora, mostra os cartões Refúgio, Santuário, Bestiário e Mochila (o Refúgio entrou em 2026-11-20, a pedido do dono) e as abas Equipe, Bestiário e Perfil. A aba Home vira o botão "Voltar", que faz `Router.back()` até Liora.
- **RF-06:** O Voltar do Android e o Esc no Hub voltam a Liora.
- **RF-07:** Sem ilha casa (`home_island_id == 0`), o jogo abre o Hub como primeira tela, igual ao de antes desta iniciativa (todos os cartões e abas). Na [03](03-travel-screen.md), os cartões de viagem viram um só, "Viagem", que abre a tela Viagem.
- **RF-08:** O "Apagar Domador" do Perfil continua levando à tela de entrada, como hoje.

## Critérios de aceite

- [ ] Com uma casa publicada, abrir o app com um Domador que tem inicial cai andando na casa, no ponto de início.
- [ ] Escolher o inicial numa conta nova termina na casa.
- [ ] Menu, em Liora, abre o Hub sem os cartões de viagem e da Loja, com o do Refúgio; Voltar, Esc e o voltar do Android voltam ao mesmo mapa, sem carregar de novo.
- [ ] Sem casa, o app abre o Hub de antes, e tudo continua alcançável.

## Desenho técnico

- `client/core/home.gd` (novo, [architecture](architecture.md#navegação)).
- `client/core/autoload/session.gd`: `home_island_id` e a leitura no fim do `load_player()`.
- `client/screens/main/main.gd`: `_open_first_screen` com `Home.go()`.
- `client/screens/starter_select/starter_select_screen.gd`: `Home.go()` no lugar do `go_to(&"hub")`.
- `client/screens/exploration/exploration_screen.gd`: o `_island_id` comparado com `Session.home_island_id`; o botão vira Menu e o `handle_back()` abre o menu na casa.
- `client/screens/hub/hub_screen.gd`: `ACTIONS`, `TABS` e `DESTINATIONS` conforme a casa; o botão Voltar; o cartão Viagem.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

Manual (F5): os critérios de aceite, com e sem a casa ligada no F2.

## Tarefas

- [x] `Home` e `Session.home_island_id`.
- [x] A primeira tela e o fim da escolha do inicial.
- [x] O botão Menu em Liora.
- [x] O Hub virado menu, com e sem casa.

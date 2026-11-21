# 01. O Hub

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [home-island](../home-island/) e [liora-intro](../liora-intro/)

## Contexto

O pedido e as decisões estão no [README](README.md). Esta fase tira de Liora a marca de casa e refaz o Hub como a primeira tela do jogo, com o botão Explorar abrindo o mapa gerado. A tela Ecobeasts, o Perfil e as Configurações são a [fase 2](02-ecobeasts-profile-settings.md); até lá, o ícone Ecobeasts abre a Equipe de hoje, o nome abre o placeholder do Perfil, e a engrenagem abre um placeholder "Configurações".

## Escopo

- A migração `<data>_hub_start`.
- `client/screens/hub/` (`hub_screen.gd` e `hub_screen.tscn`).
- `client/core/home.gd`, se o caminho sem casa pedir ajuste.
- Os comentários e as specs que dizem que o app abre em Liora.

## Requisitos

**O começo**

- **RF-01:** A migração `<data>_hub_start` faz `UPDATE "ecobeasts"."islands" SET "is_home" = false WHERE "is_home"`. Liora continua publicada, com as cenas e os NPCs, e o dono pode marcá-la de novo no F2.
- **RF-02:** Sem a casa, o app abre assim, pelo `Home.start()`:
  - o jogador novo: o login, a Aparência com o nome (`onboarding`), a escolha de 1 entre 3 e o Hub;
  - quem já tem nome e inicial: o Hub;
  - quem parou na introdução de Liora com nome e sem inicial: a escolha de 1 entre 3 e o Hub;
  - quem parou sem nome: a Aparência, a escolha e o Hub.
- **RF-03:** Nenhuma cena da história toca: os gatilhos só existem nas ilhas, e o Hub não abre nenhuma.

**O Hub**

- **RF-04:** O topo tem, da esquerda para a direita:
  - o avatar e o nome do Domador, que juntos abrem o Perfil;
  - o nível e a barra de XP (vazia, como hoje);
  - as moedas;
  - a engrenagem das Configurações.
- **RF-05:** No meio, o Ecobeast em destaque, grande, pelo `front.png`, com o nome, o nível e a barra de HP. Ao abrir o Hub, ele é o primeiro da equipe.
  - Tocar no destaque abre o detalhe dele (`creature_details`).
  - O destaque usa a arte de fundo de hoje (`assets/backgrounds/hub.png`, ou o céu em gradiente sem ela), limpa atrás dele e escurecida da fileira para baixo.
  - O indicador da parte do dia (`DayPhaseBadge`, da [day-night](../day-night/)) fica no canto de cima à direita do destaque, porque o topo não tem espaço para ele ao lado da engrenagem.
- **RF-06:** Embaixo do destaque, a fileira dos 6 espaços da equipe (`CreatureSlot`), como hoje.
  - Tocar num Ecobeast da fileira o põe em destaque, e o espaço dele fica marcado.
  - Um espaço vazio não faz nada.
  - O destaque não é gravado no servidor nem no aparelho, e não muda o líder.
- **RF-07:** Abaixo da fileira, o botão **Explorar**, o maior da tela. Ele abre o mapa gerado (`Router.go_to(&"exploration")`, sem `island_id`), com a transição de hoje.
- **RF-08:** Embaixo do Explorar, 4 ícones com o nome, numa linha: **Loja** (`shop`), **Refúgio** (`heal_station`), **Ecobeasts** (`team`; a tela Ecobeasts na [fase 2](02-ecobeasts-profile-settings.md)) e **Mochila** (`bag`), cada um com a cor da ação em `UiPalette.ACTION_COLORS` (a do Ecobeasts, `team`, é nova). Eles abrem a tela com `Router.push`, e o Voltar dela volta ao Hub.
- **RF-09:** Saem do Hub os cartões de ação de hoje (Viagem, Santuário e Bestiário viram caminhos da tela Ecobeasts), a barra de abas e o modo menu do Domador (`MENU_ACTIONS`, `MENU_TABS` e o `BACK_TAB`). O `ActionTile` fica no código, sem uso.
- **RF-10:** Sem nenhum Ecobeast na equipe (só depois de apagar o progresso, quando o Router já troca de tela), o Hub não quebra: o destaque fica vazio e o Explorar fica desligado.
- **RF-11:** O Hub cabe em retrato de 720×1280 a 1080×2400, sem rolar a tela. Os toques têm pelo menos 48 px de altura.

**As voltas**

- **RF-12:** O Voltar do mapa gerado, a derrota na luta, a vitória e a fuga voltam ao Hub. Hoje isso já é o `Home.go()` sem casa; confira cada um.
- **RF-13:** O Voltar do aparelho no Hub não sai do jogo nem abre outra tela.

## Fora do escopo

- O PVP e o PVE no Explorar.
- As telas da [fase 2](02-ecobeasts-profile-settings.md).
- O Desafiar e as Arenas: a tela Viagem continua no código, sem caminho a partir do Hub.

## Critérios de aceite

- [x] A migração aplicada deixa nenhuma ilha com `is_home`, e os e2e da `home-island` passam (eles criam a própria casa).
- [x] Um jogador novo (Apagar progresso) passa pela Aparência e pela escolha do inicial e chega ao Hub com ele em destaque.
- [x] O Hub mostra o nome, o nível, a barra, as moedas e a engrenagem, e o nome abre o Perfil.
- [x] Tocar noutro Ecobeast da fileira o põe em destaque; tocar no destaque abre o detalhe.
- [x] O Explorar abre um mapa gerado, diferente a cada vez, e o Voltar dele volta ao Hub; a derrota na luta também.
- [x] Os 4 ícones abrem a Loja, o Refúgio, a Equipe e a Mochila, e o Voltar de cada um volta ao Hub.
- [x] O jogo sem janela abre sem erro de script, e os testes do servidor passam, menos as falhas antigas.

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```

Depois, no jogo: Apagar progresso, criar o Domador, escolher o inicial e explorar.

## Tarefas

- [x] A migração.
- [x] O Hub novo: o topo, o destaque, a fileira, o Explorar e os 4 ícones.
- [x] Conferir as voltas ao Hub e o caminho do jogador que parou na introdução.
- [x] Atualizar o `CLAUDE.md`, o `.specs/README.md` e o comentário do `Home`.
- [x] A verificação.

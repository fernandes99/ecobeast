# 02. O mapa na tela inteira e os controles nos cantos

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [hub-start/04](../hub-start/04-game-look.md), [creature-faces](../creature-faces/)

## Contexto

O painel de baixo da tela Explorar tira uns 260 px do mapa e tem cara de aplicativo, enquanto a Home já ganhou cara de jogo. O desenho está no [README](README.md).

## Escopo

- `client/screens/exploration/` (`exploration_screen.tscn` e `.gd`).
- `client/ui/components/` (um `game_button_style.gd` novo, com o estilo do botão de jogo que hoje mora no `hub_screen.gd`).
- `client/screens/hub/hub_screen.gd` (passa a usar o componente; a aparência da Home não muda).

## Requisitos

**O mapa**

- **RF-01:** o `ControlsPanel` sai. O mapa ocupa a tela inteira, e os controles flutuam por cima dele, dentro do `SafeArea`. O toque no mapa (andar, a pinça e a roda) vale em toda a área fora dos controles.
- **RF-02:** o "ver mapa inteiro" do Debug encaixa o mapa na tela inteira.

**Os cantos**

- **RF-03:** canto de cima à esquerda: um botão redondo de 64 px com o ícone `back.svg` (na ilha casa, o `MENU_ICON`, abrindo o Menu como hoje) e, ao lado, uma placa escura meio transparente só com o nome da ilha (28 px, contornado) e o selo da parte do dia juntos. No mapa sorteado, a placa diz "Zona selvagem".
- **RF-04:** canto de cima à direita: o minimapa, como hoje.
- **RF-05:** canto de baixo à esquerda: a equipe, um `CreatureFace` de 56 px por Ecobeast, na ordem da equipe, com o anel de HP; o primeiro (o líder) fica 15% maior, e os outros não ficam apagados (a Home apaga os não escolhidos, aqui não há escolha). É o `CreatureFace` direto, sem a `PartyBubble`. (A [04](04-top-info.md) deixou todos do mesmo tamanho, como no protótipo.) Tocar em qualquer um abre a tela `team` (`Router.push`). Ela se refaz quando a equipe muda (`Session.player_changed`) e na volta da luta, do Refúgio e da Mochila.
- **RF-06:** canto de baixo à direita: o Procurar, um botão redondo de 128 px com o estilo de botão de jogo da Home (a cor de `UiPalette.ACTION_COLORS[&"explore"]`, a lateral que desce ao apertar e o texto contornado "Procurar" embaixo do ícone `explore.svg`), e, acima dele, a Mochila, um botão redondo de 72 px no mesmo estilo, na cor da superfície (`UiPalette.SURFACE_RAISED`), com o ícone `bag.svg`. Desligado, o Procurar fica cinza, como o Explorar da Home sem equipe.
- **RF-07:** sem equipe, a equipe e o Procurar somem, e na ilha casa o Menu também, como hoje (`_refresh_team_controls`).

**O aviso**

- **RF-08:** o `Message` vira um balão (fundo escuro meio transparente, cantos redondos, texto contornado), centrado acima da fileira da equipe. Ele some sozinho em 3 s (o de erro, `DangerLabel`, em 5 s), ou ao tocar nele; um aviso novo troca o de antes e reinicia a conta. O "Carregando..." da entrada fica até o mapa chegar, e o erro da entrada (o mapa não veio) fica até o jogador sair.

**Quando o mapa trava**

- **RF-09:** a caixa de fala (`TamerGreeting`) continua embaixo, na largura da tela; enquanto ela está aberta, os controles de baixo (a equipe, a Mochila e o Procurar) somem. Numa cena da história, todos os controles somem, como o painel some hoje (`story_began` e `story_ended`).
- **RF-10:** com os controles desligados (`_set_controls_enabled(false)`, durante a caminhada até um Domador NPC, por exemplo), os botões ficam desligados como hoje.

**O botão de jogo**

- **RF-11:** o estilo do botão de jogo da Home (`_explore_style`: a face, a borda clara, a lateral escura, o apertar que desce a face e o desligado cinza) vira o `GameButtonStyle` em `ui/components/`, com uma função que aplica os estilos dos estados num `Button` a partir da cor e do raio dos cantos. O Explorar da Home passa a usar ele, sem mudar a aparência.

**O Debug**

- **RF-12:** o botão Debug sai da tela. O F4 abre e fecha o `ExplorationDebugPanel`, na versão de depuração (`OS.is_debug_build()`, onde o botão aparece hoje), e não faz nada com o mapa travado (numa cena, numa fala ou com o mapa grande aberto). O painel abre por cima do mapa, embaixo da placa, como hoje.

## Fora do escopo

- O quadro de missões ([03](03-quest-tracker.md)).
- Mudar o minimapa, o mapa grande, a caixa de fala e o painel Debug por dentro.

## Critérios de aceite

- Sem erro de script, com e sem equipe, numa ilha e no mapa sorteado.
- Numa tela de 720 × 1280 e numa de 720 × 1560, nenhum controle cobre outro, e o Domador fica no meio do mapa.
- O F4 abre e fecha o Debug na versão de depuração; na de lançamento, nada acontece.
- A Home continua igual.

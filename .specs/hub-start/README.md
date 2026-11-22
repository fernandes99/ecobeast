# hub-start

O jogo começa sem história: o jogador cria o Domador, escolhe 1 entre 3 iniciais e cai no **Hub**, a tela de onde sai tudo. O Hub mostra a equipe de 6 com um Ecobeast em destaque e um botão grande **Explorar**, que abre um mapa novo gerado pelo servidor. Embaixo ficam a Loja, o Refúgio, os Ecobeasts e a Mochila, e no topo o Domador (que abre o Perfil), o nível, as moedas e as Configurações. Liora e as cenas da história ficam guardadas, sem tocar.

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [hub](../hub/), [home-island](../home-island/), [liora-intro](../liora-intro/), [onboarding](../onboarding/), [tamer-appearance](../tamer-appearance/), [team-and-storage](../team-and-storage/)

## Contexto

Desde a [home-island](../home-island/), o app abre em Explorar na ilha casa (Liora), e o Hub virou o menu do Domador, aberto pelo botão Menu do mapa. Depois, a [liora-intro](../liora-intro/) passou o nome e o inicial para as cenas da história.

Em 2026-11-21, o dono mandou a imagem de um Hub de jogo mobile (o Ecobeast grande num pedestal, a equipe embaixo, um botão Play grande e os ícones na barra de baixo) e pediu: "Quero que me ajude a elaborar o inicio do jogo. Eu não quero inicialmente criar um core ou história. talvez no futuro." Ele descreveu:

- depois de criar a conta, o jogador cria o personagem como hoje;
- depois vai para o Hub, com a equipe de 6 e "o primeiro ecobeast de foco", e um botão grande "Explorar", que leva às ilhas de exploração;
- no topo, o nome (que abre o Perfil), o XP, o dinheiro e um botão de configurações;
- embaixo do Explorar, os ícones da Loja, do Refúgio, dos Ecobeasts e da Mochila;
- a tela Ecobeasts mostra os 6 da equipe, com um botão para o Santuário e outro para o Bestiário.

Depois, ele escolheu: o primeiro Ecobeast vem da escolha de 1 entre 3; o Explorar leva "direto para uma ilha randomica", um mapa novo gerado; e o caminho "Refazer o Hub atual" (desmarcar Liora como casa e refazer as telas, sem uma chave entre a história e o Hub).

Claude leu o jogo de hoje:

- `Home.start()` (`client/core/home.gd`) já faz quase todo o caminho sem a casa: sem nome, abre a Aparência com `onboarding`; sem inicial, a escolha de 1 entre 3 (`starter_select`); com os dois, o `Home.go()`, que sem casa abre o Hub.
- Sair do mapa fora de casa e perder uma luta já chamam o `Home.go()`.
- O mapa gerado é o `Router.go_to(&"exploration")` sem `island_id`, o "Explorar zona" da tela Viagem.
- O Hub (`client/screens/hub/hub_screen.gd`) já tem o topo com o avatar, o nome, o nível, a barra de XP (sempre vazia: o Domador ainda não sobe de nível) e as moedas, a fileira de 6 da equipe, os cartões de ação e a barra de abas.
- Não há tela de Perfil nem de Configurações: o Perfil é um placeholder com o `ProfileDebugPanel` (Sair da conta e, só em depuração, Apagar progresso).

## Objetivos

1. Um jogador novo faz login, cria o Domador, escolhe o inicial e chega ao Hub, sem nenhuma cena da história.
2. Todo jogador abre o app no Hub.
3. Explorar abre um mapa novo gerado a cada vez, e sair dele ou perder uma luta volta ao Hub.
4. A equipe, a Loja, o Refúgio, a Mochila, o Santuário, o Bestiário, o Perfil e as Configurações ficam a um ou dois toques do Hub.

## Não objetivos

- O PVP e o PVE: escolher entre os dois no Explorar e ver os outros jogadores no mapa ficam para depois. O Explorar é o lugar onde essa escolha vai entrar.
- A regra para o Domador subir de nível: a barra de XP continua vazia.
- Arte nova para o Hub, o pedestal ou os ícones.
- Apagar Liora, as cenas, a ação Viagem ou a tela Viagem.

## Antiobjetivos

- Um jogador sem inicial chegar ao Hub, ou ficar preso sem caminho até ele.
- Uma cena da história tocar sem a ilha casa.
- Perder o progresso de quem já jogou a introdução de Liora.

## Decisões

Do dono, em 2026-11-21:

| Decisão | Motivo |
| --- | --- |
| O jogo começa sem história | "Eu não quero inicialmente criar um core ou história. talvez no futuro." |
| Criar o Domador, depois o Hub | "quando ele acabar de criar conta vai criar o personagem normalmente. Depois ele vai para uma tela de hub" |
| O primeiro Ecobeast vem da escolha de 1 entre 3 | Ele escolheu "Escolher 1 de 3" |
| Explorar abre um mapa novo gerado, sem lista | "Direto para uma ilha randomica" e "Mapa novo gerado" |
| O Hub de hoje é refeito, e Liora deixa de ser a casa | Ele escolheu "Refazer o Hub atual" |
| O topo: o nome (abre o Perfil), o XP, o dinheiro e as Configurações | O pedido dele |
| Embaixo do Explorar: Loja, Refúgio, Ecobeasts e Mochila | O pedido dele |
| A tela Ecobeasts: os 6 da equipe, o Santuário e o Bestiário | O pedido dele |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| Liora deixa de ser a casa por uma migração (`is_home = false`), e não por um campo novo | O jogo já sabe viver sem casa, e o dono religa a casa no F2 quando quiser a história. Religar vai pedir ajustar o Hub, porque ele não é mais o menu do Domador |
| O Ecobeast em destaque é o primeiro da equipe; tocar noutro da fileira o põe em destaque, e tocar no destaque abre o detalhe | O "primeiro ecobeast de foco" do dono. O destaque não é gravado: o líder continua sendo trocado na tela Ecobeasts |
| O Desafiar e as Arenas saem do Hub por enquanto | O Explorar é só exploração; as lutas contra Domadores voltam com o PVP e o PVE |
| A barra de abas de baixo sai | Os 4 ícones e o topo fazem o que as abas faziam |
| A tela Equipe vira a tela Ecobeasts, com os botões Santuário e Bestiário | Ela já mostra e reordena os 6 da equipe |
| O Perfil mostra o Domador, o nome, o nível, as moedas e o botão Aparência | O avatar do Hub hoje abre a Aparência; o Perfil passa a ser o caminho para ela |
| As Configurações têm o volume da música e dos sons, o Sair da conta e, só em depuração, o Apagar progresso | O Sair da conta e o Apagar progresso estão hoje no placeholder do Perfil; o volume é o que um jogo mobile pede primeiro |

## Fora do escopo

- O PVP, o PVE e os outros jogadores no mapa.
- O XP do Domador e a subida de nível dele.
- Mudar o mapa gerado, a luta, a captura, a Loja, o Refúgio, a Mochila, o Santuário ou o Bestiário.
- Desligar a ação Viagem nas ilhas: sem casa, nenhuma ilha é aberta pelo Hub.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-hub](01-hub.md) | Liora sem a marca de casa, o Hub novo (o topo, o destaque, o Explorar e os 4 ícones) e as voltas ao Hub | concluída |
| 2 | [02-ecobeasts-profile-settings](02-ecobeasts-profile-settings.md) | A tela Ecobeasts, o Perfil e as Configurações | concluída |
| 3 | [03-tab-bar](03-tab-bar.md) | A barra de abas no estilo do Clash Royale, com a Home no meio, e a Home como o palco no campo | concluída |

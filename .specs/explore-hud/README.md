# explore-hud

A tela Explorar (o mapa com o minimapa) ganha interface nova: o painel grande de baixo sai, o mapa ocupa a tela toda, os controles flutuam nos cantos com a cara de jogo da Home, o Debug abre no F4 e as missões aceitas aparecem num quadro no canto da tela.

## Contexto

Em 2026-11-23, o dono pediu: "Agora na tela de explorar em jogo no mapa (mesma tela que aparece o minimapa), quero melhorar todo o design dela, o debug vai abrir quando eu clicar em f4. [...] Também quero exibir em algum lugar as tarefas que ele está participando". Perguntado o que incomodava, ele respondeu: "Tudo, preciso que melhore toda a interface você decide."

O que existe hoje (`client/screens/exploration/exploration_screen.tscn`):

- **Topo:** a placa com o nome da ilha (só numa ilha) e o selo da parte do dia à esquerda, e o minimapa redondo à direita.
- **Embaixo:** um `SectionPanel` da largura da tela, com o aviso (`Message`), o botão Debug (na versão de depuração), o "Procurar Ecobeast" de 80 px e a fileira Mochila e Voltar (ou Menu, na ilha casa). O painel tira uns 260 px do mapa.
- **Missões:** o jogo não tem a lista delas. Ele só recebe os lugares do "Vá até" que faltam (`Session.quest_places`). O servidor guarda as aceitas em `player_quests`, e as de luta (capturar, derrotar, encontrar espécie, derrotar Domador) contam em qualquer mapa, o sorteado também (auralis/06 RF-05).

## Objetivos

1. O mapa na tela inteira, com os controles nos cantos.
2. A mesma cara de jogo da Home (`hub-start/04`): botões com lateral, textos contornados, rostos dos Ecobeasts.
3. Ver as missões aceitas e o progresso sem falar com o NPC.
4. O Debug fora da tela, no F4.

## Abordagens

| Abordagem | O que troca | Por que não (ou sim) |
| --- | --- | --- |
| **A. Cantos sobre o mapa** | O painel sai; cada controle flutua no seu canto | **Escolhida.** É o jeito dos jogos de celular, libera o mapa e cabe o quadro de missões |
| B. Barra de baixo no estilo da Home | Uma barra como a de abas do Hub, com o Procurar saltado no meio | Combina com o Hub, mas continua comendo a parte de baixo do mapa |
| C. Só repintar o painel | Os mesmos lugares, com os estilos novos | Pouco para "melhore toda a interface" |

O dono deixou a escolha com Claude ("você decide").

## O desenho

```
┌──────────────────────────────────────┐
│ (←) ┌─────────────────────┐   ╭────╮ │
│     │ Ilha Aurora · ☀ Tarde│   │mini│ │
│     └─────────────────────┘   │mapa│ │
│ ┌ Missões (2) ─────── ˅ ┐     ╰────╯ │
│ │ Capture 3 Ecobeasts   │            │
│ │ ▓▓▓▓▓▓░░░░  2/3       │            │
│ │ Vá até o Farol        │            │
│ │ ▓░░░░░░░░░  0/1       │            │
│ └───────────────────────┘            │
│                                      │
│              (mapa)                  │
│                                      │
│        ┌───────────────────┐         │
│        │ Nada por aqui.    │ (aviso) │
│        └───────────────────┘   (🎒)  │
│ (●)(●)(●)(●)(●)(●)          ╭─────╮  │
│  equipe: rostos + HP        │Procu│  │
│                             │ rar │  │
│                             ╰─────╯  │
└──────────────────────────────────────┘
```

- **Canto de cima à esquerda:** o botão redondo de sair (←; na ilha casa, o Menu) e, ao lado, a placa com o nome da ilha e a parte do dia juntos (no mapa sorteado, "Zona selvagem").
- **Canto de cima à direita:** o minimapa, como hoje.
- **Embaixo da placa:** o quadro de missões, recolhível, com até 3 missões e o progresso de cada uma; tocar abre a lista inteira.
- **Canto de baixo à esquerda:** a equipe, os rostos (`CreatureFace`) com o anel de HP; tocar abre a tela Ecobeasts.
- **Canto de baixo à direita:** o Procurar, um botão redondo grande de jogo, e a Mochila, um botão redondo menor acima dele.
- **Aviso:** um balão no meio de baixo, acima da equipe, que some sozinho.
- **F4:** abre e fecha o painel Debug de hoje (`ExplorationDebugPanel`), sem botão na tela.

## Decisões

| Decisão | Motivo |
| --- | --- |
| Abordagem A, cantos sobre o mapa | Do dono ("você decide"); a escolha é de Claude |
| O Debug sai da tela e abre no F4 | Do dono |
| Mostrar as missões aceitas na tela | Do dono |

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| O quadro mostra as missões de todas as ilhas, as da ilha aberta primeiro | As de luta contam em qualquer mapa, o sorteado também; esconder seria esconder progresso que anda |
| No quadro, até 3 missões; o resto na lista inteira | Mais que 3 cobre o mapa |
| As missões vêm de uma rota nova, `GET /v1/me/quests` | O jogo não tem a lista; o servidor já guarda tudo |
| O texto do progresso vem pronto do servidor | O "Explore" é em % e o "Fique" em minutos; o servidor já sabe escrever (`progressLine`) |
| O quadro recolhido fica lembrado no aparelho (`ViewSettings`) | Quem prefere o mapa limpo não precisa recolher a cada entrada |
| O F4 vale na versão de depuração, onde o botão aparece hoje | Quem já tinha o Debug continua tendo; no celular de depuração, sem teclado, ele deixa de abrir (o dono pediu o F4) |
| Os rostos da equipe abrem a tela Ecobeasts | É onde a equipe se arruma; a tela Explorar não troca o líder |
| "Missão pronta" só avisa a missão que ficou pronta enquanto o jogo estava aberto, uma vez | Repetir a cada entrada vira barulho; a missão pronta continua marcada no quadro |
| A cor da missão pronta é a do HP cheio (`UiPalette.HP_HIGH`) | A paleta não tem uma cor de sucesso, e o verde do HP já quer dizer "bem" |
| O estilo de botão de jogo da Home vira um componente (`GameButtonStyle`), usado pelas duas telas | Um lugar só para a lateral, a borda e o apertar |

## Fora do escopo

- Mudar o minimapa, o mapa grande, a caixa de fala ou as cenas da história.
- Marcar o lugar do "Vá até" no mapa ou no minimapa.
- Entregar, recusar ou abandonar missão pelo quadro (continua sendo pelo NPC).
- O F4 no celular.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-quest-list](01-quest-list.md) | Servidor: `GET /v1/me/quests`, as missões aceitas e não entregues com o progresso; jogo: `Session.load_quests()` | concluída |
| 2 | [02-hud-layout](02-hud-layout.md) | Jogo: o mapa na tela inteira, os controles nos cantos, o aviso em balão e o Debug no F4 | concluída (falta o dono conferir no jogo) |
| 3 | [03-quest-tracker](03-quest-tracker.md) | Jogo: o quadro de missões e a lista inteira | concluída (falta o dono conferir no jogo) |
| 4 | [04-top-info](04-top-info.md) | Jogo: as informações do protótipo do dono, o ícone (criado por código) e o nome do bioma do Domador e a hora com a parte do dia no topo, no visual da fase 2 | concluída (falta o dono conferir no jogo) |

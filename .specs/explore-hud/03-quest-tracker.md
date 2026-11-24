# 03. O quadro de missões

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01-quest-list](01-quest-list.md), [02-hud-layout](02-hud-layout.md)

## Contexto

O dono quer ver "as tarefas que ele está participando" na tela Explorar. A lista vem da [01](01-quest-list.md); o lugar do quadro, embaixo da placa da ilha, é da [02](02-hud-layout.md).

## Escopo

- `client/screens/exploration/` (um `quest_tracker.gd` e um `quest_list_panel.gd` novos, e a tela).
- `client/core/settings/view_settings.gd` (o quadro recolhido).

## Requisitos

**O quadro**

- **RF-01:** embaixo da placa da ilha, no canto de cima à esquerda, um quadro de fundo escuro meio transparente e cantos redondos, com no máximo 55% da largura da tela, sem passar por baixo do minimapa. No topo, "Missões (N)", com N o total das aceitas, e uma seta que recolhe e abre o quadro.
- **RF-02:** aberto, o quadro mostra até 3 missões: primeiro as da ilha aberta, depois as outras, cada grupo na ordem da lista. Cada linha tem o título numa linha só (cortado com reticências), embaixo uma barra fina de progresso e o `progress_text` à direita dela. Uma missão de outra ilha mostra o nome da ilha em texto secundário, ao lado do título.
- **RF-03:** uma missão cumprida (`done`) mostra a barra cheia na cor do HP cheio (`UiPalette.HP_HIGH`) e, no lugar do progresso, "Fale com <npc_name>".
- **RF-04:** recolhido, só o topo aparece. O estado fica guardado no aparelho (`ViewSettings`, `user://view.json`) e vale na próxima entrada.
- **RF-05:** sem missões aceitas, o quadro some.
- **RF-06:** o quadro some junto com os controles numa cena da história e com o mapa grande aberto; com a caixa de fala aberta, ele fica.

**A lista inteira**

- **RF-07:** tocar numa linha ou no "Missões (N)" (fora da seta) abre a lista inteira por cima da tela, como o mapa grande: as missões agrupadas por ilha (a aberta primeiro), cada uma com o título, o NPC que entrega ("de <npc_name>"), a barra e o progresso, numa lista que rola, e o Fechar. O voltar do aparelho fecha (`handle_back`). Aberta, o mapa fica travado e a caminhada para, como no mapa grande.

**Quando a lista muda**

- **RF-08:** a tela chama o `Session.load_quests()` ao entrar no mapa e ao voltar de outra tela (a luta, a Mochila, a sala); o `Session` relê sozinho depois de cada conversa de missão (`talk_quest` e `accept_quest`) e de cada lugar alcançado (`reach_quest_place`), porque elas também acontecem nas salas; a tela se redesenha no `Session.quests_changed`.
- **RF-09:** com uma missão "Fique" ou "Explore" da ilha aberta não cumprida, a tela também chama o `load_quests()` a cada 30 s enquanto está no mapa.
- **RF-10:** no `Session.quest_ready` ([01](01-quest-list.md) RF-07), com a tela Explorar aberta (ou na volta a ela, se a leitura foi em outra tela), o aviso da [02](02-hud-layout.md) mostra "Missão pronta: <título>. Fale com <npc_name>.".

## Fora do escopo

- Entregar ou recusar pelo quadro.
- Marcar no mapa onde a missão acontece.

## Critérios de aceite

- Sem missões, o quadro não aparece; com uma aceita, aparece com o progresso.
- Capturar um Ecobeast com "Capture 3" aceita muda o "0/3" para "1/3" na volta da luta, no mapa sorteado também.
- Recolher o quadro, sair e entrar de novo: ele continua recolhido.
- A lista inteira abre, rola, fecha pelo Fechar e pelo voltar.

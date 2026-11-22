# 09. Os itens no chão e a missão "Encontre X item"

- **Status:** concluída (falta o dono conferir no F2 e no jogo)
- **Depende de:** [06-island-quests](06-island-quests.md), [07-quest-editor](07-quest-editor.md), [islands](../islands/), [map-editor](../map-editor/), [inventory-shop](../inventory-shop/)

## Contexto

O dono pediu no começo da Auralis missões como "Encontre X item", e a [06](06-island-quests.md) deixou esse tipo de fora porque o jogo não tinha item no chão. Em 2026-11-22, ele adiou a fase 8 ("deixa para depois quando eu disser ou mencionar, igual a fase 2") e pediu esta. Nas perguntas da fase, ele escolheu:

- se o item volta depois de pego: "Você escolhe por item" (só uma vez, ou volta a cada entrada na ilha);
- como o item aparece: "Você escolhe por item" (visível, ou escondido);
- o que a missão "Encontre X item" conta: "Qualquer jeito de ganhar" (o chão, a Loja e as recompensas).

Depois de ver a fase pronta, ele pediu: "Em vez de aparecer o item, eu gostaria de ter alguma indicação que tem um item mas sem ter que mostrar ele. Talvez um brilho sutil indicando que tem um item ali, e na hora que ele for até o item, deve aparecer um dialogo".

## Decisões desta fase

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| Cada item posto no chão diz se volta: "só uma vez" (um tesouro, que some para sempre para aquele jogador) ou "volta a cada entrada na ilha" | "Você escolhe por item" |
| Cada item posto diz se aparece: visível ou escondido | "Você escolhe por item" |
| O item nunca aparece no mapa: só um brilho de quatro pontinhos em cruz piscando, sobre uma luz dourada que pulsa no chão e se soma à cor dele (mistura aditiva) | "Talvez um brilho sutil indicando que tem um item ali" e, depois de ver os pontinhos sozinhos, "deixe com um pouco mais de destaque" |
| Ao pegar, a caixa de fala mostra "Você encontrou N <item>!", com a voz da narração; tocar nela fecha | "na hora que ele for até o item, deve aparecer um dialogo" |
| A missão "Encontre X item" conta todo item daquele tipo ganho depois de aceitar: no chão, na Loja, na entrega de outra missão e na recompensa de nível do Domador | "Qualquer jeito de ganhar" |

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| Os itens do chão fazem parte do rascunho da ilha (como os NPCs), postos pela ferramenta Itens do F2 (grupo Jogo), com o desfazer, e valem no jogo ao publicar | São parte do mapa, e o dono já publica a ilha para mudar o resto |
| Cada item posto tem uma `key`, um número sorteado pelo F2 que não muda ao publicar; o progresso do jogador guarda a ilha e a `key` | As linhas de `island_maps` são refeitas a cada publicação; a `key` sorteada não volta a ser usada por um item apagado |
| No máximo um item por hexágono, fora da água, da lava e de hexágono bloqueado na publicação, e até 500 por ilha | O jogador pega ao pisar; um item num lugar sem acesso deixaria a missão sem jeito |
| O jogador pega o item ao pisar no hexágono dele (visível ou escondido), e a caminhada para na fala; se outra conversa ou cena está aberta, a frase vai para a mensagem da tela | É o jeito de achar o escondido, e o visível não pede um toque a mais |
| O "só uma vez" fica no banco (`player_ground_items`); o "volta a cada entrada" fica na memória da exploração, e some ao sair da ilha | O que volta não precisa de banco |
| O servidor confere que o Domador chegou ao hexágono do item (a mesma conferência do "Vá até") antes de dar o item | O servidor é a autoridade |
| O visível brilha sempre (embaixo da névoa); o escondido brilha mais fraco e só a até 2 hexágonos do Domador | Dá a pista do escondido sem entregar a posição de longe |
| A missão "Encontre X item" é o tipo 10 (`find_item`), com o item alvo em `quests.target_item_id` e a quantidade em `amount` (vazio vale 1); o título é "Encontre <item>" ou "Encontre N <item>" | Segue o "Encontre o Ecobeast X" |

## Escopo

- O catálogo: `island_ground_items` (os itens de cada versão de ilha), `player_ground_items` (os "só uma vez" já pegos), o tipo de missão 10 e `quests.target_item_id`.
- O servidor: o rascunho e a publicação com os itens, a exploração com os itens ainda não pegos, a rota de pegar, e o progresso do "Encontre X item" em todo ganho de item.
- O F2: a ferramenta Itens, e o tipo novo na ferramenta Missões.
- O jogo: os itens no mapa de Explorar, a coleta ao pisar e a fala.

## Fora do escopo

- Itens no mapa sorteado.
- Itens dentro das salas (`interiors`).
- Um item que volta depois de um tempo (a cada dia, por exemplo).
- Ver no F2 quem já pegou cada item.

## Onde ficou

- O banco: a migration `20270216000000_ground_items` (as tabelas `island_ground_items` e `player_ground_items`, `quests.target_item_id`, o tipo 10 em `quest_types` e o `quests_params_check` refeito com ele).
- As regras puras: a conferência dos itens no rascunho e na publicação em `server/src/domain/islands/island-draft.ts` (`DraftItem`, `itemsError`, o hash só com itens), os que o Domador ainda pode pegar e a fala em `server/src/domain/islands/ground-items.ts`, e o tipo 10 em `server/src/domain/quests/quests.ts` e `quest-input.ts`.
- O servidor: o módulo `server/src/ground-items/` (`GroundItemsService.available`, usado pela entrada na ilha, e `pick`, na rota `POST /v1/me/ground-items/pick`), o "volta a cada entrada" em `StoredExploration.pickedItemKeys`, e o progresso do "Encontre X item" em `server/src/quests/item-quests.ts` (`itemQuestWrite`), chamado pela Loja (`InventoryService.buy`), pela entrega de missão (`QuestsService.claim`), pelas recompensas de nível (`TamerLevelService.award`) e pelo chão.
- O F2: a ferramenta Itens (`EditorTools.Tool.ITEMS`, grupo Jogo, ícone `icons/item.svg`) com o `GroundItemPanel` (`client/tools/map_editor/ground_item_panel.gd`), os itens em `IslandDraft.items` e no desfazer (`items_before` e `items_after`), desenhados pelo `EditorCanvas._draw_ground_items`; Delete tira o escolhido e Esc solta. A ferramenta Missões tem o "Item a encontrar" no tipo 10, e o item da recompensa virou "Item de recompensa".
- O jogo: o `MapGroundItem` (`ExplorationMap.ground_items`), o `GroundItemSprite` (`client/ui/components/`, os 4 pontinhos e a luz do chão, com `BLEND_MODE_ADD`), o `Session.pick_ground_item` e, na `ExplorationScreen`, o `_check_ground_item` a cada hexágono novo e a fala pelo `_found_item`.
- Os testes: `ground-items.spec.ts`, os itens em `island-draft.spec.ts`, o tipo 10 em `quests.spec.ts` e `quest-input.spec.ts`, e o e2e `server/test/ground-items.e2e-spec.ts`. O "longe demais" (409) não entrou no e2e: com o banco remoto, a ida e volta já passa do passo mínimo de 300 ms; a conferência é a mesma do "Vá até" (`ExplorationStore.confirmPosition`). O F2 e o brilho foram conferidos sem janela e numa foto do sprite: falta o dono abrir.

## Requisitos

- **RF-01:** o rascunho e a versão publicada da ilha têm `items`: cada um com `key` (1 a 2.147.483.647, única na ilha), `item_id`, `q`, `r`, `quantity` (1 a 99), `once` (verdadeiro: só uma vez; falso: volta a cada entrada) e `hidden`. Salvar recusa, com a mensagem, um item fora da ilha, na água ou na lava, dois itens no mesmo hexágono, um `item_id` que não existe, a quantidade fora de 1 a 99, duas `key` iguais ou mais de 500 itens. Publicar também recusa um item num hexágono bloqueado. O hash da ilha sem itens não muda.
- **RF-02:** `POST /v1/me/exploration` numa ilha responde `ground_items`, os itens da versão publicada que o Domador ainda pode pegar: sem os "só uma vez" já pegos por ele. No mapa sorteado, vazia.
- **RF-03:** `POST /v1/me/ground-items/pick` com `key`, numa ilha, confere que o item existe na ilha da exploração e não foi pego (o "só uma vez" no banco, o "volta" nesta entrada), e que o Domador chegou ao hexágono dele; então soma a quantidade na Mochila, grava o "só uma vez" e soma nas missões "Encontre X item", numa transação, e responde `item_id`, `quantity` e `line` ("Você encontrou 2 Tônico Leve!"). Fora de uma ilha, 409; item que não existe ou já pego, 404; longe dele, 409.
- **RF-04:** o tipo de missão 10, `find_item` ("Encontre X item"), pede `target_item_id` (um item que existe) e aceita `amount` vazio (vale 1) ou de 1 a 9999. O progresso soma, nas missões aceitas e não entregues desse item, a quantidade de todo item ganho: no chão (RF-03), na Loja, na entrega de uma missão e nas recompensas de nível do Domador, com o teto do alvo.
- **RF-05:** a ferramenta Itens do F2 (grupo Jogo, depois de Missões) tem a lista dos itens com o ícone, a quantidade, "Volta a cada entrada" e "Escondido". O clique põe o item escolhido no hexágono (ou escolhe o que já está nele, para mudar as opções), e o botão direito tira. Os itens aparecem no mapa do editor com o ícone, e o escondido meio apagado. Tudo entra no desfazer.
- **RF-06:** a ferramenta Missões tem o tipo "Encontre X item", com a lista de itens alvo e a quantidade.
- **RF-07:** em Explorar numa ilha, o item não aparece: o visível é um brilho de pontinhos piscando sobre uma luz dourada que pulsa no chão; o escondido, o mesmo brilho mais fraco, só a até 2 hexágonos do Domador. Os dois ficam embaixo da névoa. Ao pisar no hexágono (o de chegada também), o jogo chama a rota (RF-03), relê o Domador (a Mochila), tira o brilho e para a caminhada com a caixa de fala "Você encontrou N <item>!", com a voz da narração, que fecha ao tocar; com outra conversa ou cena aberta, a frase vai para a mensagem da tela. Com erro, mostra a mensagem do servidor e deixa o item.

## Critérios de aceite

- [ ] No F2, pôr um item visível e um escondido, salvar e publicar.
- [ ] Em Explorar, ver o visível, achar o escondido pelo brilho e pegar os dois; o "só uma vez" não volta, e o "volta a cada entrada" volta ao sair e entrar.
- [ ] Uma missão "Encontre 2 Tônico Leve" conta o do chão e o da Loja, e não o de antes de aceitar.

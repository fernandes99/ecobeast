# 11. Os itens de missão

- **Status:** concluída (falta o dono conferir no F2 e no jogo)
- **Depende de:** [09-ground-items](09-ground-items.md), [inventory-shop](../inventory-shop/), [item-icons](../item-icons/)

## Contexto

Em 2026-11-26, o dono pediu: "Veja o item_sheets dentro de Downloads, e crie uns 10 itens de missão, (que serão itens que não vai ter efeito nenhum e será usado só para missão)".

A folha é o `Downloads/items_sheet.png` (576×560), com 1.244 ícones de 16×16 em pixel art, os mesmos do `Downloads/items/item<N>.png` (o ícone N é a célula N − 1 da folha, lida da esquerda para a direita). Hoje o jogo tem 6 itens, as 3 Esferas e os 3 de cura, e todos estão à venda na Loja.

## Decisões

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| A categoria nova **Missão** (`item_categories` 3, `quest`) | A Mochila já separa os itens por categoria, com o título de cada uma |
| Um item de missão não tem efeito (`capture_bonus` e `heal_amount` vazios, `cures_status` falso): a Mochila e a luta não mostram o Usar, e a rota de usar já responde "Esse item não pode ser usado agora." | É o que a Mochila e a luta já fazem com um item sem efeito |
| `items.price` aceita vazio: sem preço, o item não está à venda. A Loja não mostra o item, e a compra responde 409 "Esse item não está à venda." | Um item de missão comprado na Loja tiraria a graça do "Encontre X item"; a coluna nula diz isso sem uma regra presa à categoria |
| Os ícones são os de 16×16 da folha ampliados 2 vezes (pixel por pixel) para 32×32, sem outra edição | Ficam no padrão da [item-icons](../item-icons/): 32×32, com o objeto de 24 a 28 px de altura |
| Os 10 itens são coisas do mundo das ilhas que um NPC perderia, pediria ou guardaria, sem marca de nenhum lugar ou pessoa | O dono escreve as missões; os itens só precisam servir para várias histórias |

## Os itens

| id | slug | Nome | Ícone | Descrição |
| --- | --- | --- | --- | --- |
| 7 | `old_key` | Chave Antiga | 691 | Uma chave de bronze gasta. Abre alguma porta esquecida. |
| 8 | `old_scroll` | Pergaminho Antigo | 649 | Um rolo de papel amarelado, com uma letra difícil de ler. |
| 9 | `torn_map` | Mapa Rasgado | 662 | Um pedaço de mapa com um caminho marcado. |
| 10 | `parcel` | Encomenda | 717 | Uma caixa bem amarrada, à espera de quem a receba. |
| 11 | `clay_pot` | Pote de Barro | 680 | Um pote pesado e bem fechado. Melhor não abrir. |
| 12 | `golden_acorn` | Bolota Dourada | 1014 | Uma bolota que brilha como ouro. Os Ecobeasts do bosque adoram. |
| 13 | `crimson_flower` | Flor Rubra | 1038 | Uma flor vermelha rara, que só abre em lugares tranquilos. |
| 14 | `rare_shell` | Concha Rara | 1090 | Uma concha dourada. Encostada no ouvido, ainda se ouve o mar. |
| 15 | `blue_feather` | Pena Azul | 1243 | Uma pena leve e azul, perdida por alguma ave. |
| 16 | `tide_pearl` | Pérola da Maré | 598 | Uma pérola clara, polida pelas ondas. |

## Escopo

- O banco: a migration `quest_items` (o preço sem `NOT NULL`, a categoria 3 e os 10 itens) e o seed.
- O servidor: a compra recusando o item sem preço.
- O jogo: os ícones em `client/assets/items/<slug>.png`, o preço vazio no `Item` e no `CatalogSchema`, a Loja sem os itens sem preço e a cor da categoria Missão no `ItemIcon`.

## Fora do escopo

- Entregar o item ao NPC, tirando da Mochila, ao cumprir a missão: o "Encontre X item" conta o que o jogador ganha, e não tira nada.
- Vender um item ou jogá-lo fora.
- Criar itens pelo F2.

## Onde ficou

- O banco: a migration `20270224000000_quest_items` (o `price` sem `NOT NULL`, a categoria 3 e os itens 7 a 16), com o seed em `item_categories.json` e `items.json`.
- O servidor: `InventoryService.buy` responde `NOT_FOR_SALE` para o item sem preço; o e2e `shop.e2e-spec.ts` confere a recusa.
- O jogo: os ícones em `client/assets/items/<slug>.png` (as células 691, 649, 662, 717, 680, 1014, 1038, 1090, 1243 e 598 da folha, ampliadas 2 vezes), o `Item.for_sale()` (o preço vazio vira 0), o `price` anulável no `CatalogSchema`, a Loja só com os itens à venda, a cor `quest` em `UiPalette.ITEM_CATEGORY_COLORS` e o "fora da Loja" na aba Itens do F1.
- Conferido numa cena sem janela: o catálogo passa no validador, os 10 itens não têm efeito nem preço, e os ícones aparecem nítidos em 96 px. A Mochila, a Loja e o F2 não foram abertos.

## Requisitos

- **RF-01:** `items.price` aceita vazio, e o `items_price_check` continua pedindo pelo menos 1 quando há preço. O catálogo (`GET /v1/catalog`) responde `price: null` nesses itens.
- **RF-02:** a categoria 3 (`quest`, "Missão", ordem 3) e os 10 itens da tabela acima, nas ordens 7 a 16, sem preço e sem efeito.
- **RF-03:** `POST /v1/me/shop/buy` com um item sem preço responde 409 "Esse item não está à venda." e não muda as moedas nem a Mochila.
- **RF-04:** a Loja só mostra os itens com preço, e a aba de uma categoria sem nenhum item à venda não aparece.
- **RF-05:** a Mochila mostra os itens de missão do jogador sob o título "Missão", com o ícone e a descrição, sem o Usar; a Mochila da luta não os mostra.
- **RF-06:** a ferramenta Itens e a ferramenta Missões do F2 listam os itens de missão, como os outros (no chão, no "Encontre X item" e na recompensa).

## Critérios de aceite

- [ ] Os 10 itens aparecem no F2, na ferramenta Itens e no "Item a encontrar" das Missões.
- [ ] Pegar um item de missão no chão o põe na Mochila, sob "Missão", sem o Usar.
- [ ] A Loja não mostra nenhum item de missão.
- [ ] O dono confirma a licença da folha de ícones.

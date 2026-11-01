# Arquitetura

O desenho que as quatro fases compartilham. As regras de jogo ficam em `server/src/domain/items/`; o cliente nunca calcula preço, cura nem quantidade.

## Tabelas

No catálogo, editáveis pelo painel do Supabase e espelhadas em `res://core/data/catalog_schema.gd`:

**`item_categories`**

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | Chave |
| `slug` | string | Único |
| `name` | string | O nome da aba na Loja |
| `sort_order` | int | Único; a ordem das abas |

**`items`**

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | Chave |
| `slug` | string | Único; também é o nome do arquivo da imagem |
| `name` | string | Em pt-BR |
| `description` | string | O efeito, em pt-BR |
| `item_category_id` | int | FK para `item_categories` |
| `price` | int | `CHECK ≥ 1` |
| `sort_order` | int | Único; a ordem dentro da aba |
| `capture_bonus` | float? | `CHECK > 0`; só nas Esferas, lido pela `capture` |
| `heal_amount` | int? | `CHECK ≥ 1`; HP que o item cura |
| `cures_status` | bool | Padrão falso; remove o status principal |

`inventory_items` não muda de forma e ganha a FK que faltava: `item_id` → `items`, com `onDelete: Restrict`. A linha só existe com `quantity ≥ 1`, por isso o item some da Mochila ao chegar a zero.

`creature_instances.held_item_id` e `evolutions.item_id` continuam nulos, com o `CHECK` atual: são de outras iniciativas.

Um item pode ser usado quando tem `heal_amount` ou `cures_status`. A categoria só organiza as abas, sem decidir nenhuma regra.

## Conteúdo inicial

Tudo _a revisar_. Os valores de `price` e dos efeitos mudam pelo painel.

| `id` | Categoria | Nome | Efeito | Preço |
| --- | --- | --- | --- | --- |
| 1 | Esferas | Esfera de Vínculo | `capture_bonus` 1 | 100 |
| 2 | Esferas | Esfera Reforçada | `capture_bonus` 1,5 | 300 |
| 3 | Esferas | Esfera Suprema | `capture_bonus` 2 | 600 |
| 4 | Cura | Tônico Leve | `heal_amount` 20 | 100 |
| 5 | Cura | Tônico Forte | `heal_amount` 60 | 300 |
| 6 | Cura | Bálsamo Puro | `cures_status` | 150 |

Categorias: `1` `capture` "Esferas" e `2` `heal` "Cura". As outras do GDD entram quando tiverem itens.

## A carga inicial

A [carga inicial](../backend-api/03-catalog-seed.md) só rodava com o catálogo todo vazio, e um banco com parte das tabelas era um erro. Tabelas novas entram num banco já em uso, então `seedPlan` passa a devolver as tabelas vazias: ela carrega só essas e nunca toca nas que têm linhas. Com tudo preenchido, não faz nada.

Depois da migration, `npm run db:seed` preenche `item_categories` e `items`, sem alterar o resto do catálogo.

## Regra de uso

`server/src/domain/items/use-item.ts`, pura, é usada pela rota do mapa e pelo motor da batalha:

```ts
export interface UsableItem { healAmount: number | null; curesStatus: boolean }
export interface ItemTarget { currentHp: number; maxHp: number; hasStatus: boolean }
export interface ItemEffect { healed: number; curesStatus: boolean }

export function resolveItem(item: UsableItem, target: ItemTarget): ItemEffect | { error: string };
```

Na ordem, a primeira que valer decide:

1. Item sem `heal_amount` e sem `cures_status`: "Esse item não pode ser usado agora."
2. Alvo com 0 HP: "Só o Refúgio recupera um Ecobeast sem HP."
3. `healed` é o menor entre `heal_amount` e o HP que falta.
4. Sem HP a curar e sem status a remover: "Não teria efeito."

## Contrato

O JSON do jogador ganha `inventory`, em todas as rotas que devolvem `Player`:

```json
{ "inventory": [{ "item_id": 4, "quantity": 2 }] }
```

Em ordem de `item_id`.

| Rota | Corpo | Sucesso | Falhas |
| --- | --- | --- | --- |
| `POST /v1/me/shop/buy` | `{ "item_id": 4 }` | `200 { "player": Player }` | `400` "Esse item não existe." · `409` "Crie seu Domador primeiro." · `409` "Moedas insuficientes." |
| `POST /v1/me/items/use` | `{ "item_id": 4, "creature_uid": "…" }` | `200 { "player": Player }` | `400` "Esse item não existe." · `404` "Ecobeast não encontrado." · `409` "Crie seu Domador primeiro." · `409` "Você não tem esse item." · `409` com a mensagem da regra de uso |

Na batalha, `POST /v1/me/battle/action` aceita mais uma ação, e `battle.player` ganha `items`, no mesmo formato de `inventory`:

```json
{ "type": "item", "item_id": 4, "team_index": 0 }
```

Evento novo:

```json
{ "type": "item_used", "side": "player", "item_id": 4, "team_index": 0, "healed": 20, "hp": 31, "cured_status": null }
```

## O item na batalha

A batalha vive na memória, e o banco só muda no fim dela. Por isso, e porque `BattleService.act` não tem `await` entre ler e gravar o `store`, o item segue o mesmo caminho:

1. Ao começar, `BattleState` recebe `bag`: uma cópia da Mochila, com `{ itemId, quantity, used }` por item.
2. `applyAction` confere a quantidade na `bag`, aplica `resolveItem`, tira 1 de `quantity` e soma 1 em `used`.
3. No fim da luta, `saveTeam` grava na mesma transação o HP, o PP, o status e os itens gastos.
4. Uma luta abandonada não grava nada: o HP e o item voltam a ser os de antes.

Para cada item com `used > 0`, a gravação faz `deleteMany` quando `quantity ≤ used` e `updateMany` com `decrement` nos outros casos, nessa ordem. O `CHECK quantity ≥ 1` não permite guardar o zero.

Comprar não mexe em `bag`: a cópia só pode ficar menor que o estoque real, o que não dá item de graça. Usar um item fora da luta descarta a batalha aberta, antes da escrita, como o `heal`. Assim, a `bag` nunca fica maior que o estoque.

## Cliente

- **Modelos:** `Item`, `ItemCategory` e `InventorySlot`, em `res://domain/models/`. `Player.inventory` e `Player.quantity_of(item_id)`.
- **Catálogo:** `GameData.get_item(id)`, `get_items()` e `get_item_categories()`.
- **Serviço:** `buy_item(item_id)` e `use_item(item_id, creature_uid)` no `GameService`, no `ApiGameService` e no `Session`. As duas devolvem o `Player`, e o `Session` chama `_set_player`. Como o Hub ouve `player_changed`, as moedas se atualizam sozinhas.
- **Imagem:** `ItemIcon`, em `res://ui/components/`, mostra `assets/items/<slug>.png` se o arquivo existir. Sem ele, desenha um círculo com a inicial do nome, numa cor de `UiPalette` por categoria. É o mesmo padrão do `CreaturePortrait`.

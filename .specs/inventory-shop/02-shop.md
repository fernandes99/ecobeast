# 02. Loja

- **Status:** concluída
- **Depende de:** [01-item-catalog](01-item-catalog.md)

## Contexto

Com os itens no catálogo, falta comprá-los. Esta fase cria a rota de compra e troca o placeholder da Loja pela tela real (TELAS.md #12).

## Escopo

- Rota `POST /v1/me/shop/buy`.
- Tela da Loja, com abas por categoria.
- Componente `ItemIcon`.
- O destino de "Loja" no Hub, no botão e na aba inferior.

## Fora do escopo

- Escolher quantidade, vender e confirmar antes de comprar.
- Usar os itens comprados ([03](03-bag.md)).
- Ganhar moedas.

## Requisitos

**Rota**

- **RF-01:** `POST /v1/me/shop/buy`, com `{ "item_id" }`, exige a sessão e responde `200 { "player" }`, no mesmo formato de `GET /v1/me`.
- **RF-02:** A compra tira `price` das moedas e soma 1 à quantidade do item, criando a linha se ela não existir.
- **RF-03:** O preço vem do banco, e nunca do corpo do pedido.
- **RF-04:** Moedas e Mochila mudam numa transação só: ou as duas mudam, ou nada muda.
- **RF-05:** Dois pedidos ao mesmo tempo nunca deixam as moedas negativas.
- **RF-06:** Com moedas insuficientes, `409` "Moedas insuficientes.", sem mudar nada.
- **RF-07:** `item_id` que não é inteiro, ou que não existe: `400` "Esse item não existe."
- **RF-08:** Sem Domador ou sem equipe: `409` "Crie seu Domador primeiro."
- **RF-09:** A rota está no OpenAPI, em pt-BR, sob a tag "Mochila e Loja", com o cadeado.

**Tela**

- **RF-10:** Tocar em "Loja" no Hub, no card ou na aba inferior, abre a tela com `Router.push`.
- **RF-11:** O topo mostra as moedas, que se atualizam depois de cada compra.
- **RF-12:** Há uma aba por categoria com itens, na ordem de `sort_order`, começando pela primeira.
- **RF-13:** Cada card mostra `ItemIcon`, nome, descrição, preço, "Você tem N" e o botão "Comprar".
- **RF-14:** Com moedas abaixo do preço, "Comprar" fica desativado.
- **RF-15:** Tocar em "Comprar" compra 1 unidade. Enquanto o pedido volta, os botões de compra e "Voltar" ficam desativados, e o voltar do Android fica parado.
- **RF-16:** Com sucesso, a tela mostra "Item comprado!", atualiza moedas e quantidade e continua na Loja.
- **RF-17:** Com falha, a tela mostra o erro em `DangerLabel` e continua na Loja.
- **RF-18:** "Voltar" e o voltar do Android levam ao Hub, com as moedas atualizadas.
- **RF-19:** Sem o arquivo da imagem, `ItemIcon` mostra o círculo com a inicial. Com o arquivo, mostra a imagem, sem mudar código.

## Critérios de aceite

- [x] Sem token, a rota dá `401`.
- [x] Sem Domador, `409` "Crie seu Domador primeiro."
- [x] Comprar com moedas suficientes desconta o preço, e a resposta já mostra a quantidade nova.
- [x] Comprar de novo o mesmo item soma, sem criar outra linha.
- [x] Com moedas iguais ao preço, a compra passa e o saldo fica 0.
- [x] Com uma moeda a menos que o preço, `409`, sem mudar moedas nem Mochila.
- [x] Com `item_id` inexistente ou em texto, `400`.
- [x] Duas compras simultâneas com moedas para uma só resultam em uma compra.
- [x] Com uma falha na escrita da Mochila, as moedas não mudam.
- [x] A rota aparece em `/docs/openapi.json`, com o cadeado.
- [x] A Loja abre pelo card e pela aba do Hub.
- [x] As abas Esferas e Cura mostram 3 itens cada, na ordem do catálogo.
- [x] Depois de uma compra, a tela mostra "Item comprado!", as moedas e a quantidade novas.
- [x] Sem moedas para um item, o "Comprar" dele fica desativado.
- [x] Sem servidor, a tela mostra o erro e continua aberta.
- [x] Voltar ao Hub mostra as moedas atualizadas.
- [x] Em 360×640, nada fica cortado.
- [x] O projeto abre sem erros nem avisos de script.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/inventory/inventory.module.ts`, `inventory.controller.ts`, `inventory.service.ts` e `inventory.dto.ts`.
- `server/test/shop.e2e-spec.ts`.
- `client/screens/shop/shop_screen.tscn` e `.gd`, `shop_item_card.tscn` e `.gd`.
- `client/ui/components/item_icon.tscn` e `.gd`.

**Alterar**

- `server/src/app.module.ts`: `InventoryModule`.
- `server/src/player/player.module.ts`: exporta `PlayerService`, se ainda não exportar.
- `client/core/services/game_service.gd`, `api_game_service.gd` e `client/core/autoload/session.gd`: `buy_item`.
- `client/core/autoload/router.gd`: `&"shop"`.
- `client/screens/hub/hub_screen.gd`: o destino de "Loja".
- `client/ui/theme/`: uma cor por categoria em `UiPalette`.
- `.specs/visual-theme/README.md`: `assets/items/<slug>.png`, com o tamanho.
- `.specs/auth-google/architecture.md`: a rota na tabela.
- `.specs/onboarding/architecture.md`: `buy_item` na lista de rotas.
- `client/CLAUDE.md` e `server/CLAUDE.md`: a tela, o componente e a pasta `src/inventory/`.

**Reaproveitar**

- Servidor: `$transaction` interativo. `updateMany` com `coins: { gte: price }` nega a compra quando `count` é 0, o que cobre os pedidos simultâneos. `inventoryItem.upsert` soma a quantidade.
- Cliente: `SafeArea`, `CoinChip`, `SectionPanel`, as abas de `creature_details_screen`, `DangerLabel` e `BoldLabel`. O padrão do `handle_back` vem de `heal_station_screen.gd`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

Uma cena temporária, nos moldes da [heal-station/02](../heal-station/02-heal-screen.md), abre a Loja pelo Hub contra um servidor de teste, compra pelos botões reais, confere os critérios automáticos e salva capturas em 360×640, 405×720 e 720×1061. A falta de rede é simulada trocando o endereço do servidor, e o relatório diz isso.

Passos do dono no editor (F5) e no celular:

1. Abrir a Loja pelo card e pela aba.
2. Comprar um item de cada aba.
3. Conferir se o texto e os botões cabem bem.

## Tarefas

- [x] Testes e2e da rota; ver falhar; módulo, serviço e controller (RF-01 a RF-09).
- [x] Verificação temporária da tela; ver falhar.
- [x] `ItemIcon` e o card (RF-13, RF-19).
- [x] Tela, `buy_item`, registro e Hub (RF-10 a RF-12, RF-14 a RF-18).
- [x] Remover os arquivos temporários; atualizar as specs citadas; marcar esta spec e a tabela do README como `concluída`; commit `feat: Loja`.

## Decisões da implementação

- **As abas seguem a tela de detalhes:** a spec citava `TabButton` e `CurrentTabButton`, que são os da barra inferior, com ícone em cima. A aba atual usa o botão padrão, e as outras, `OutlineButton`, como em `creature_details_screen`.
- **`item_id` acima do limite do banco dá `400`:** sem essa conferência, um número enorme viraria erro `500` no Prisma.
- **Critério do texto maior retirado:** o jogo não tem ajuste de tamanho de texto, então a conferência foi feita em 360×640.
- **Imagem dos itens:** 256 × 256, com fundo transparente, _a revisar_. O dono manda os arquivos depois.
- **Conferência:** os 15 testes novos da rota falharam antes dela existir e passaram depois, incluindo a falha no meio da transação, que desfaz o desconto no banco de verdade, e as compras simultâneas. `npm run lint` e `npm run typecheck` sem avisos. Uma cena temporária abriu a Loja pelo Hub contra um servidor de teste, com toques entrando como cliques reais pela janela, e passou com 39 de 39 verificações em janelas de 360×640, 405×720, 412×915 e 720×1061, depois de falhar porque o card ainda abria o placeholder. Uma rodada extra, com um arquivo real em `assets/items/`, mostrou a imagem no lugar da forma, sem mudar código; o arquivo foi removido. A falta de rede foi simulada trocando o endereço do servidor. Das 25 capturas salvas na última passada de cada tamanho, 6 foram abertas e revisadas. O teste no celular fica para o dono, e os arquivos temporários foram removidos.

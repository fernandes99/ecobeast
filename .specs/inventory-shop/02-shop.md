# 02. Loja

- **Status:** rascunho
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

- [ ] Sem token, a rota dá `401`.
- [ ] Sem Domador, `409` "Crie seu Domador primeiro."
- [ ] Comprar com moedas suficientes desconta o preço, e a resposta já mostra a quantidade nova.
- [ ] Comprar de novo o mesmo item soma, sem criar outra linha.
- [ ] Com moedas iguais ao preço, a compra passa e o saldo fica 0.
- [ ] Com uma moeda a menos que o preço, `409`, sem mudar moedas nem Mochila.
- [ ] Com `item_id` inexistente ou em texto, `400`.
- [ ] Duas compras simultâneas com moedas para uma só resultam em uma compra.
- [ ] Com uma falha na escrita da Mochila, as moedas não mudam.
- [ ] A rota aparece em `/docs/openapi.json`, com o cadeado.
- [ ] A Loja abre pelo card e pela aba do Hub.
- [ ] As abas Esferas e Cura mostram 3 itens cada, na ordem do catálogo.
- [ ] Depois de uma compra, a tela mostra "Item comprado!", as moedas e a quantidade novas.
- [ ] Sem moedas para um item, o "Comprar" dele fica desativado.
- [ ] Sem servidor, a tela mostra o erro e continua aberta.
- [ ] Voltar ao Hub mostra as moedas atualizadas.
- [ ] Com o texto maior ou em 360×640, nada fica cortado, e a lista rola.
- [ ] O projeto abre sem erros nem avisos de script.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

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
- Cliente: `SafeArea`, `CoinChip`, `TabButton` e `CurrentTabButton`, `SectionPanel`, `DangerLabel` e `BoldLabel`. O padrão do `handle_back` vem de `heal_station_screen.gd`.

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

- [ ] Testes e2e da rota; ver falhar; módulo, serviço e controller (RF-01 a RF-09).
- [ ] Verificação temporária da tela; ver falhar.
- [ ] `ItemIcon` e o card (RF-13, RF-19).
- [ ] Tela, `buy_item`, registro e Hub (RF-10 a RF-12, RF-14 a RF-18).
- [ ] Remover os arquivos temporários; atualizar as specs citadas; marcar esta spec e a tabela do README como `concluída`; commit `feat: Loja`.

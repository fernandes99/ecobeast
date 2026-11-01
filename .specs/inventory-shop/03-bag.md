# 03. Mochila

- **Status:** rascunho
- **Depende de:** [02-shop](02-shop.md)

## Contexto

O jogador já compra itens, mas não tem como vê-los nem usá-los. Esta fase cria a regra de uso, a rota e a tela da Mochila (TELAS.md #13), que abre pelo Hub e pelo mapa.

## Escopo

- A regra `resolveItem`, pura e com testes.
- Rota `POST /v1/me/items/use`.
- Tela da Mochila, com a escolha do alvo.
- O destino de "Mochila" no Hub e o botão no mapa.

## Fora do escopo

- Usar itens na luta ([04](04-battle-items.md)).
- Usar Esferas de Vínculo.
- Alvos fora da equipe, no Santuário.
- Ordenar ou descartar itens.

## Requisitos

**Regra e rota**

- **RF-01:** `resolveItem` segue as regras de [architecture.md](architecture.md#regra-de-uso), nessa ordem.
- **RF-02:** `POST /v1/me/items/use`, com `{ "item_id", "creature_uid" }`, exige a sessão e responde `200 { "player" }`.
- **RF-03:** Com sucesso, o HP sobe até o máximo, sem passar dele, e o item com `cures_status` limpa `status_condition_id`.
- **RF-04:** A rota tira 1 da quantidade e apaga a linha quando ela chega a zero.
- **RF-05:** HP, status e Mochila mudam numa transação só.
- **RF-06:** Dois pedidos ao mesmo tempo com a última unidade gastam uma só; o segundo recebe "Você não tem esse item."
- **RF-07:** Item recusado pela regra não é gasto, e o `409` traz a mensagem da regra.
- **RF-08:** O alvo precisa estar na equipe do jogador. Caso contrário: `404` "Ecobeast não encontrado."
- **RF-09:** Depois de validar e antes de escrever, a batalha aberta é descartada, sem gravar nada dela.
- **RF-10:** A rota está no OpenAPI, em pt-BR, sob a tag "Mochila e Loja", com o cadeado.

**Tela**

- **RF-11:** Tocar em "Mochila" no Hub abre a tela com `Router.push`.
- **RF-12:** O mapa ganha o botão "Mochila", ao lado de "Voltar", ativo depois que o mapa aparece.
- **RF-13:** Voltar da Mochila ao mapa mantém o jogador no mesmo hexágono, porque o Router só esconde a tela de baixo.
- **RF-14:** A tela mostra os itens agrupados por categoria, na ordem do catálogo, com `ItemIcon`, nome, descrição e quantidade.
- **RF-15:** Sem nenhum item, a tela mostra "Sua Mochila está vazia."
- **RF-16:** Item que pode ser usado mostra "Usar". As Esferas aparecem sem esse botão.
- **RF-17:** "Usar" abre a lista da equipe, com retrato, nome e HP de cada Ecobeast.
- **RF-18:** Tocar em um Ecobeast usa o item nele. Enquanto o pedido volta, a tela fica parada, e o voltar do Android também.
- **RF-19:** Com sucesso, a tela mostra "<item> usado em <Ecobeast>.", atualiza a lista e fica na Mochila.
- **RF-20:** Com recusa, a tela mostra o erro em `DangerLabel`, e a quantidade não muda.
- **RF-21:** O voltar do Android fecha a lista da equipe, se aberta; senão, volta à tela anterior.

## Critérios de aceite

- [ ] Testes de `resolveItem`: cura parcial, cura limitada ao máximo, HP cheio, alvo com 0 HP, sem status, item de captura e item com cura e status.
- [ ] Sem token, a rota dá `401`.
- [ ] Um Tônico em Ecobeast ferido sobe o HP e gasta uma unidade.
- [ ] O Bálsamo remove o status e gasta uma unidade.
- [ ] Com HP cheio, `409` "Não teria efeito.", sem gastar o item.
- [ ] Com 0 HP, `409` "Só o Refúgio recupera um Ecobeast sem HP.", sem gastar o item.
- [ ] Uma Esfera dá `409` "Esse item não pode ser usado agora."
- [ ] A última unidade apaga a linha, e o item some de `inventory`.
- [ ] Sem o item, `409` "Você não tem esse item."
- [ ] Um Ecobeast de outro Domador, ou do Santuário, dá `404`.
- [ ] Com uma luta aberta, usar um item faz `POST /v1/me/battle/action` responder `404`.
- [ ] Um item recusado mantém a luta aberta.
- [ ] Com uma falha na escrita, nem o HP nem a Mochila mudam.
- [ ] A rota aparece em `/docs/openapi.json`, com o cadeado.
- [ ] A Mochila abre pelo Hub e pelo mapa, e voltar retorna à tela de origem.
- [ ] Voltar ao mapa mantém o hexágono, e a luta seguinte começa com o HP curado.
- [ ] O painel do mapa não fica mais alto com o botão novo.
- [ ] Sem itens, aparece "Sua Mochila está vazia."
- [ ] Usar a última unidade tira o item da lista.
- [ ] Em 360×640 e 720×1061, nada fica cortado, e a lista rola.
- [ ] O projeto abre sem erros nem avisos de script.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/domain/items/use-item.ts` e `.spec.ts`.
- `server/test/items.e2e-spec.ts`.
- `client/screens/bag/bag_screen.tscn` e `.gd`, `bag_item_row.tscn` e `.gd`, `bag_target_panel.tscn` e `.gd`.

**Alterar**

- `server/src/inventory/`: a rota de uso. O módulo importa `BattleModule`, para usar o mesmo `BattleStore`.
- `client/core/services/game_service.gd`, `api_game_service.gd` e `client/core/autoload/session.gd`: `use_item`.
- `client/core/autoload/router.gd`: `&"bag"`.
- `client/screens/hub/hub_screen.gd`: o destino de "Mochila".
- `client/screens/exploration/exploration_screen.gd` e `.tscn`: "Mochila" e "Voltar" numa mesma linha, em `%ControlsPanel`.
- `TELAS.md`: a #13 cita a abertura pelo mapa.
- `.specs/auth-google/architecture.md`: a rota na tabela.
- `.specs/onboarding/architecture.md`: `use_item` na lista de rotas.

**Reaproveitar**

- Servidor: `HEAL_INCLUDE` como modelo da leitura e `creatureStats(row).hp` como HP máximo. Em `$transaction` interativo, `updateMany` com `quantity: { gt: 1 }` e, se `count` for 0, `deleteMany` com `quantity: 1`. Se os dois derem 0, "Você não tem esse item."
- Cliente: `ItemIcon`, `CreaturePortrait`, `HpBar`, `SectionPanel`. A lista da equipe segue `next_creature_panel`, e o padrão de "parado enquanto o pedido volta" vem de `heal_station_screen.gd`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

Uma cena temporária abre a Mochila pelo Hub e pelo mapa contra um servidor de teste, usa itens pelos botões reais, confere os critérios automáticos e salva capturas. As capturas abertas são citadas no relatório.

Passos do dono no editor (F5) e no celular:

1. Comprar um Tônico, ferir um Ecobeast numa luta e usar o item pelo mapa.
2. Tentar usar com HP cheio e conferir o aviso.
3. Conferir se o botão "Mochila" está bem posicionado no mapa.

## Tarefas

- [ ] Testes de `resolveItem`; ver falhar; regra (RF-01).
- [ ] Testes e2e da rota; ver falhar; rota (RF-02 a RF-10).
- [ ] Verificação temporária da tela; ver falhar.
- [ ] Tela, linha, lista da equipe e `use_item` (RF-11, RF-14 a RF-21).
- [ ] Botão no mapa (RF-12, RF-13).
- [ ] Remover os arquivos temporários; atualizar as specs citadas; marcar esta spec e a tabela do README como `concluída`; commit `feat: Mochila`.

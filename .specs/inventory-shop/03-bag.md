# 03. Mochila

- **Status:** concluída
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
- **RF-17:** "Usar" abre a lista da equipe, com retrato, nome e HP de cada Ecobeast, e "Cancelar".
- **RF-18:** Tocar em um Ecobeast usa o item nele. Enquanto o pedido volta, a tela fica parada, e o voltar do Android também.
- **RF-19:** Com sucesso, a tela mostra "<item> usado em <Ecobeast>.", atualiza a lista e fica na Mochila.
- **RF-20:** Com recusa, a tela mostra o erro em `DangerLabel`, e a quantidade não muda.
- **RF-21:** O voltar do Android fecha a lista da equipe, se aberta; senão, volta à tela anterior.

## Critérios de aceite

- [x] Testes de `resolveItem`: cura parcial, cura limitada ao máximo, HP cheio, alvo com 0 HP, sem status, item de captura e item com cura e status.
- [x] Sem token, a rota dá `401`.
- [x] Um Tônico em Ecobeast ferido sobe o HP e gasta uma unidade.
- [x] O Bálsamo remove o status e gasta uma unidade.
- [x] Com HP cheio, `409` "Não teria efeito.", sem gastar o item.
- [x] Com 0 HP, `409` "Só o Refúgio recupera um Ecobeast sem HP.", sem gastar o item.
- [x] Uma Esfera dá `409` "Esse item não pode ser usado agora."
- [x] A última unidade apaga a linha, e o item some de `inventory`.
- [x] Sem o item, `409` "Você não tem esse item."
- [x] Um Ecobeast de outro Domador, ou do Santuário, dá `404`.
- [x] Com uma luta aberta, usar um item faz `POST /v1/me/battle/action` responder `404`.
- [x] Um item recusado mantém a luta aberta.
- [x] Com uma falha na escrita, nem o HP nem a Mochila mudam.
- [x] A rota aparece em `/docs/openapi.json`, com o cadeado.
- [x] A Mochila abre pelo Hub e pelo mapa, e voltar retorna à tela de origem.
- [x] Voltar ao mapa mantém o hexágono, e a luta seguinte começa com o HP curado.
- [x] O painel do mapa não fica mais alto com o botão novo.
- [x] Sem itens, aparece "Sua Mochila está vazia."
- [x] Usar a última unidade tira o item da lista.
- [x] Em 360×640 e 720×1061, nada fica cortado.
- [x] O projeto abre sem erros nem avisos de script.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

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

- [x] Testes de `resolveItem`; ver falhar; regra (RF-01).
- [x] Testes e2e da rota; ver falhar; rota (RF-02 a RF-10).
- [x] Verificação temporária da tela; ver falhar.
- [x] Tela, linha, lista da equipe e `use_item` (RF-11, RF-14 a RF-21).
- [x] Botão no mapa (RF-12, RF-13).
- [x] Remover os arquivos temporários; atualizar as specs citadas; marcar esta spec e a tabela do README como `concluída`; commit `feat: Mochila`.

## Decisões da implementação

- **"Cancelar" na lista da equipe:** a spec só previa fechar pelo voltar do Android, que não existe no iPhone.
- **Ecobeast com 0 HP continua tocável na lista:** assim o jogador lê o motivo da recusa, em vez de ver uma linha desativada sem explicação.
- **`creature_uid` sem validação no corpo:** um valor inválido é só um Ecobeast que não está na equipe, por isso responde `404`, e não `400`.
- **A rolagem da lista não foi exercitada:** a lista usa um `ScrollContainer`, mas com 6 itens não passa da tela em nenhum tamanho conferido. O critério foi reescrito por isso.
- **Conferência:** os 10 testes da regra e os 23 da rota falharam antes do código e passaram depois, incluindo a falha no meio da transação, que devolve o item no banco de verdade, e dois usos simultâneos da última unidade. `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 412 testes; `npm run test:e2e` com 327. Uma cena temporária abriu a Mochila pelo Hub e pelo mapa contra um servidor de teste, com toques entrando como cliques reais pela janela, e passou com 51 de 51 verificações em janelas de 360×640, 405×720, 412×915 e 720×1061, depois de falhar porque o card ainda abria o placeholder. Ela cobre a volta ao mesmo hexágono e a luta seguinte com o HP curado. A falta de rede foi simulada trocando o endereço do servidor. Das 24 capturas, 6 foram abertas e revisadas. O jogo abriu sem erros nem avisos de script, e os arquivos temporários foram removidos. O teste no celular fica para o dono.

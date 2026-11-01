# 04. Itens na batalha

- **Status:** concluída
- **Depende de:** [03-bag](03-bag.md)

## Contexto

O botão Itens da batalha está desativado desde a [battle-screen](../battle-screen/). Com a regra de uso pronta, esta fase cria a ação de usar item no motor e liga o botão. Usar um item gasta a rodada: ele faz efeito primeiro, e depois o inimigo ataca.

## Escopo

- A `bag` no estado da batalha.
- A ação `item` e o evento `item_used`.
- Gravar os itens gastos no fim da luta.
- O botão Itens e a escolha do item e do alvo.

## Fora do escopo

- Usar Esferas de Vínculo (`capture`).
- Domadores NPC usando itens.
- Trocar de Ecobeast por vontade própria (botão Equipe).
- Curar Confuso, Amedrontado ou Preso.

## Requisitos

**Motor e API**

- **RF-01:** `BattleState` guarda a `bag` descrita em [architecture.md](architecture.md#o-item-na-batalha), lida da Mochila ao começar a luta.
- **RF-02:** `BattleCatalog` traz os itens, lidos do banco.
- **RF-03:** A ação `{ "type": "item", "item_id", "team_index" }` só vale em `choose_action`.
- **RF-04:** A ação é recusada com "Você não tem esse item.", "Esse Ecobeast não existe." ou a mensagem da regra de uso, sem gastar a rodada nem o item.
- **RF-05:** Sem recusa, o item faz efeito antes de qualquer ação do inimigo, seja qual for a Velocidade dos dois.
- **RF-06:** Depois do item, o inimigo age, e o turno termina como numa fuga que falhou.
- **RF-07:** O alvo pode ser quem está em campo ou um reserva com HP.
- **RF-08:** O Bálsamo em um Ecobeast dormindo também zera `sleepTurns`.
- **RF-09:** O evento `item_used` traz `item_id`, `team_index`, `healed`, `hp` e `cured_status`, antes dos eventos do inimigo.
- **RF-10:** `battle.player.items` traz as quantidades restantes, sem os itens zerados.
- **RF-11:** No fim da luta, `saveTeam` grava os itens gastos na mesma transação do HP, do PP e do status.
- **RF-12:** Vitória, derrota e fuga gravam os itens gastos. Uma luta abandonada não grava nada.

**Tela**

- **RF-13:** O botão Itens fica ativo quando o jogador pode agir, e desativado enquanto o turno aparece.
- **RF-14:** Tocar em Itens abre um painel com os itens que podem ser usados, com `ItemIcon`, nome, descrição e quantidade. Esferas não aparecem.
- **RF-15:** Sem itens para usar, o painel mostra "Nenhum item para usar."
- **RF-16:** Tocar em um item, com um só Ecobeast na equipe, usa o item nele. Com mais de um, abre a escolha do alvo.
- **RF-17:** Na escolha do alvo, cada Ecobeast mostra nome e HP.
- **RF-18:** O histórico mostra "Você usou <item> em <Ecobeast>: +N de HP." ou "Você usou <item> em <Ecobeast>: não está mais <status>."
- **RF-19:** Com o alvo em campo, o cartão atualiza o HP e o status ao aparecer a linha.
- **RF-20:** Uma recusa aparece no histórico em vermelho, e o jogador continua podendo agir.
- **RF-21:** O voltar do Android fecha a escolha do alvo e depois o painel de itens.

## Critérios de aceite

- [x] Um item fora da `bag` é recusado com "Você não tem esse item."
- [x] Um inimigo mais rápido ataca depois do item.
- [x] Um Tônico em quem está em campo sobe o HP, e o evento vem antes do ataque do inimigo.
- [x] Um Tônico em um reserva muda o HP dele, sem mudar quem está em campo.
- [x] O Bálsamo tira o status e acorda quem dormia.
- [x] Com HP cheio, a ação é recusada, sem gastar turno nem item.
- [x] Item em alvo com 0 HP é recusado.
- [x] Item em `choose_next` é recusado com "Escolha o próximo Ecobeast."
- [x] Uma Esfera é recusada com "Esse item não pode ser usado agora."
- [x] Com o veneno ativo, o dano de fim de turno acontece depois do item.
- [x] Se o inimigo derrotar o alvo depois do item, a luta segue para `choose_next` ou `defeat`.
- [x] No fim da luta, a Mochila no banco perdeu só o que foi gasto.
- [x] A última unidade gasta na luta apaga a linha.
- [x] Comprar um item com a luta aberta não muda a `bag`, e o fim da luta não apaga a compra.
- [x] Uma luta abandonada não gasta o item.
- [x] O botão Itens abre o painel, e o item usado aparece no histórico.
- [x] Depois do item, o inimigo ataca, e a quantidade do painel diminui.
- [x] Depois da luta, a Mochila mostra a quantidade certa.
- [x] Em 360×640 e 720×1061, o painel cabe.
- [x] O projeto abre sem erros nem avisos de script.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `client/screens/battle/battle_items_panel.tscn` e `.gd`. As linhas reaproveitam `BagItemRow` e `NextCreatureRow`.

**Alterar**

- `server/src/domain/battle/types.ts`: `BattleBagItem`, `BattleItem`, `bag`, `items`, a ação e o evento.
- `server/src/domain/battle/engine.ts`: `startBattle` recebe a `bag`, `refusalFor` confere o item, e a nova função `useBagItem` aplica `resolveItem`. O trecho do inimigo em `flee` vira uma função usada pelos dois.
- `server/src/domain/battle/testing.ts`, `engine.spec.ts`: os casos novos.
- `server/src/battle/battle-catalog.ts`: os itens.
- `server/src/battle/battle.mapper.ts`: `inventory` em `BATTLE_PLAYER_INCLUDE`, `toBattleAction` e `items` em `toBattleDto`.
- `server/src/battle/battle.dto.ts`: a ação, `item_id` e `items`.
- `server/src/battle/battle.service.ts`: `loadTeam` devolve a `bag`, e `saveTeam` grava os itens gastos.
- `server/test/battle.e2e-spec.ts`: o fluxo com o banco.
- `client/domain/models/battle_view.gd`: `items`.
- `client/screens/battle/battle_screen.gd` e `.tscn`: `%ItemsButton` ativo e o painel.
- `client/screens/battle/battle_narrator.gd`: a linha de `item_used`, com os nomes da equipe.
- `client/screens/battle/battle_display.gd`: `item_used` atualiza o cartão quando `team_index` é quem está em campo.
- `.specs/battle-core/architecture.md`: a ação e o evento.
- `.specs/battle-screen/architecture.md`: o texto do evento.
- `.specs/roadmap.md`: `inventory-shop` concluída, e a dúvida da renda de moedas mantida.
- `CLAUDE.md`: o Escopo atual cita a `inventory-shop`.

**Reaproveitar**

`resolveItem`, `ItemIcon`, `next_creature_panel` como modelo do painel e `_act` para enviar a ação. O `_act` já mostra a recusa no histórico e devolve a vez ao jogador.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

Uma cena temporária abre uma luta contra um servidor de teste, usa um Tônico pelos botões reais, confere os critérios automáticos e salva capturas. As capturas abertas são citadas no relatório.

Passos do dono no editor (F5) e no celular:

1. Comprar um Tônico e um Bálsamo.
2. Numa luta, usar cada um e conferir se o inimigo ataca depois.
3. Depois da luta, conferir a quantidade na Mochila.

## Tarefas

- [x] Testes do motor; ver falhar; `bag`, ação e evento (RF-01 a RF-10).
- [x] Testes e2e; ver falhar; gravar no fim da luta (RF-11, RF-12).
- [x] Verificação temporária da tela; ver falhar.
- [x] Painel, botão, histórico e cartão (RF-13 a RF-21).
- [x] Remover os arquivos temporários; atualizar as specs citadas; marcar esta spec e as tabelas como `concluída`; commit `feat: itens na batalha`.

## Decisões da implementação

- **O painel reaproveita as linhas que já existiam:** `BagItemRow`, da Mochila, para os itens, e `NextCreatureRow`, do próximo Ecobeast, para o alvo. A spec previa uma linha nova, que seria uma cópia.
- **Reserva com 0 HP fica desativado na escolha do alvo:** é o comportamento da `NextCreatureRow`, e na luta o jogador não precisa ler a recusa para entender. O servidor recusa do mesmo jeito.
- **`NO_ITEM` foi para `domain/items/use-item.ts`:** o motor da batalha e a rota da Mochila usam a mesma mensagem.
- **O botão Itens usa o mesmo tamanho de texto de Atacar e Correr:** agora é uma ação de verdade. A troca veio depois da última rodada de capturas, e o jogo abriu sem erros.
- **A rolagem não foi exercitada:** com os itens atuais, o painel cabe em todos os tamanhos, por isso ele não tem rolagem, e o critério foi reescrito. Mais itens de cura vão pedir uma lista que role.
- **Conferência:** os testes novos do motor e os 12 de ponta a ponta falharam antes do código e passaram depois. `npm run lint` e `npm run typecheck` sem avisos; `npm test` com 438 testes; `npm run test:e2e` com 339. Uma cena temporária jogou lutas contra um servidor de teste, com toques entrando como cliques reais pela janela, e passou com 37 de 37 verificações em janelas de 360×640, 405×720, 412×915 e 720×1061, depois de falhar porque o painel não existia. O inimigo é sorteado, então cada tamanho enfrentou adversários diferentes. Das 20 capturas, 5 foram abertas e revisadas. O jogo abriu sem erros nem avisos de script, e os arquivos temporários foram removidos. O teste no celular fica para o dono.

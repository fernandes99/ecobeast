# 05. Moedas da vitória e da derrota

- **Status:** rascunho
- **Depende de:** [01-xp-and-levels](01-xp-and-levels.md), [03-level-up-screen](03-level-up-screen.md), [architecture.md](architecture.md)

## Contexto

Hoje as 1.000 moedas iniciais são tudo o que existe no jogo: nenhuma luta paga nada, e a Loja só gasta. O dono quer que vencer um Ecobeast selvagem dê moedas e que perder custe moedas, com uma linha no log:

> Você recebeu 🪙 18 por derrotar Ruvo.
>
> Você perdeu 🪙 4 para Ruvo.

A regra vem do `pokebattle`, outro projeto do dono: um sorteio em volta de uma base, multiplicada pela razão entre o nível do inimigo e o de quem está em campo. Vencer alguém mais forte paga mais, e ficar derrotando os fracos paga pouco. As bases são pequenas de propósito, porque quem vai pagar bem são os Domadores da `npc-tamers`.

## Escopo

- Servidor: sortear as moedas no fim da vitória e da derrota, emitir o evento e gravar no `coins` do Domador.
- Jogo: mostrar a linha com o ícone de moeda no log.

## Fora do escopo

- A recompensa dos Domadores NPC: vem com a `npc-tamers`, com regra própria.
- Bônus de moedas por item, Traço ou nível do Domador.
- Animar o número de moedas do Hub ou da Loja: eles já mostram o valor novo ao voltar, porque o jogo recarrega o Domador ao sair da luta.
- Cobrar a cura no Refúgio (é outra dúvida do [roadmap](../roadmap.md)).
- Som de moeda (vem com o `audio`).

## Requisitos

- **RF-01:** a conta usa `razão = nível do selvagem ÷ nível do Ecobeast do jogador em campo no fim da luta`, `d = BASE × razão` e `moedas = sorteio inteiro entre floor(0,5 × d) e floor(1,5 × d)`, com os dois limites incluídos. Na derrota, quem está em campo no fim é o último que desmaiou.
- **RF-02:** na vitória, `BASE = COINS_WIN_BASE = 20`, e as moedas são no mínimo 1. Na derrota, `BASE = COINS_LOSS_BASE = 5`. As duas bases são _a revisar_.
- **RF-03:** a derrota nunca tira mais do que o Domador tinha quando a luta começou. Quem tem 3 moedas e sorteia 6 perde 3, e quem tem 0 não perde nada.
- **RF-04:** o sorteio usa o mesmo `Random` da batalha, para os testes fixarem o valor.
- **RF-05:** na vitória, o servidor emite `{ type: 'coins_gained', amount }`. Na derrota com perda acima de 0, emite `{ type: 'coins_lost', amount }`. Os dois vêm logo antes do `battle_ended`, e na vitória isso fica depois dos `xp_gained`.
- **RF-06:** fuga e captura não mexem nas moedas nem emitem os eventos.
- **RF-07:** a soma ou a perda é gravada no `coins` do Domador, na mesma transação que grava o XP, o HP e os itens.
- **RF-08:** o modo God e a batalha de teste seguem as mesmas regras, só para depuração.
- **RF-09:** no log, a vitória mostra "Você recebeu {ícone} {quantia} por derrotar {nome}." e a derrota mostra "Você perdeu {ícone} {quantia} para {nome}.". O ícone é o de `res://ui/icons/coin.svg`, na altura do texto, e o nome é o que o log já usa para o inimigo.
- **RF-10:** na vitória, a linha de moedas entra depois das linhas de XP e antes da barra de XP, da comemoração, da evolução e das Técnicas.

Exemplos, com os limites incluídos:

| Selvagem | Em campo no fim | Vitória | Derrota |
| --- | --- | --- | --- |
| 5 | 5 | 10 a 30 | 2 a 7 |
| 10 | 5 | 20 a 60 | 5 a 15 |
| 5 | 10 | 5 a 15 | 1 a 3 |
| 30 | 30 | 10 a 30 | 2 a 7 |

## Critérios de aceite

- [ ] Vencer um selvagem nível 5 com um Ecobeast nível 5 em campo grava de 10 a 30 moedas a mais, e o log mostra a mesma quantia.
- [ ] Perder grava a perda sorteada, nunca abaixo de 0, e o log mostra a mesma quantia. Com 0 moedas, nada muda e a linha não aparece.
- [ ] Fugir ou capturar não muda as moedas, e o log não mostra a linha.
- [ ] Na vitória, a linha aparece com o ícone, depois de "{nome} recebeu X de XP." e antes da tela de comemoração.
- [ ] Ao voltar ao Hub, o número de moedas no topo já está atualizado.
- [ ] Testes unitários e e2e passam, com `typecheck` e `lint` sem erros.

## Desenho técnico

Servidor:

- `src/domain/progression/coins.ts`: `COINS_WIN_BASE`, `COINS_LOSS_BASE`, `winCoins(enemyLevel, fielderLevel, random)` e `lostCoins(enemyLevel, fielderLevel, coins, random)`.
- `BattleState.coins`, com as moedas do Domador no começo da luta, e `BattleState.coinsChange`, que começa em 0. O `startBattle` recebe as moedas nas opções, ao lado do `godMode`, e o `makeState` dos testes começa com 0 nos dois.
- `endBattle`, em `engine.ts`: antes do `battle_ended`, a vitória e a derrota sorteiam, guardam o valor em `coinsChange` (negativo na derrota) e emitem o evento. Os tipos novos entram em `BattleEvent` e na lista de eventos do [contrato da batalha](../battle-core/architecture.md).
- `BattleService`: o `loadTeam` lê as moedas do Domador. No `saveTeam`, um `coinsChange` diferente de 0 vira `player.update({ coins: { increment: coinsChange } })` dentro do `$transaction`. A Loja não abre durante a luta, então as moedas do começo continuam valendo no fim.

Jogo:

- `battle_narrator.gd`: `coins_gained` e `coins_lost` viram o texto da linha, com o nome do inimigo.
- `battle_screen.gd`: as linhas de moedas são as únicas do log com ícone. `_add_line` ganha um parâmetro opcional de ícone, e o escurecimento das linhas antigas passa a valer para elas também.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

Na tela real, em 360×640:

- Vencer um selvagem e conferir a linha de moedas depois das de XP, e o valor no Hub.
- Perder uma luta e conferir a linha e o valor.
- Captura e fuga não mostram a linha.

## Tarefas

- [ ] Testes unitários do sorteio e dos eventos, e e2e da gravação.
- [ ] `winCoins`, `lostCoins`, `coins`, `coinsChange` e os eventos.
- [ ] Gravar as moedas na vitória e na derrota.
- [ ] Linhas com ícone no log.
- [ ] Atualizar o contrato da batalha, o README da iniciativa e a dúvida "Renda de moedas" do roadmap.
- [ ] Rodar a verificação e dizer o que ficou para o dono.

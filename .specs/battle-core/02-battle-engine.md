# 02. Motor do turno

- **Status:** aprovada
- **Depende de:** [01-battle-rules](01-battle-rules.md)

## Contexto

Com as contas prontas, falta a máquina que roda um turno: recebe o estado e a ação do jogador e devolve o novo estado e a lista de eventos. O `GDD.md` a descreve como Início → Escolha → Ordenação → Execução → Fim de turno → Checagem de fim. A ordem completa está em [architecture.md](architecture.md#ordem-de-um-turno). Tudo continua puro: sem banco, sem Nest e sem memória.

## Escopo

- `startBattle` e `applyAction`.
- Status, efeitos de Técnicas, Traços, fuga, golpe de emergência e desmaio com escolha do próximo.
- IA do inimigo.

## Fora do escopo

- Guardar a batalha, rotas e gravação no banco ([03](03-battle-api.md)).
- Recompensas e itens.

## Requisitos

**Motor**

- **RF-01:** `startBattle(player: Combatant[], enemy: Combatant[], canFlee, catalog, random)` devolve `{ state, events }`, com a primeira criatura de pé de cada lado, `turn` 1, a fase `choose_action` e os eventos `battle_started` e `creature_entered`.
- **RF-02:** `applyAction(state, action, catalog, random)` devolve `{ state, events }` ou um erro com a mensagem em pt-BR, sem alterar o estado recebido.
- **RF-03:** Uma ação inválida devolve: "Essa Técnica não existe.", "Essa Técnica está sem PP.", "Ainda há Técnicas com PP.", "Não dá para fugir agora.", "Escolha o próximo Ecobeast.", "Esse Ecobeast não pode lutar." ou "A batalha já terminou."

**Status principais** (só um por vez)

- **RF-04:** Queimado: perde 1/16 do HP máximo no fim do turno, com mínimo de 1, e causa metade do dano físico (já na [01](01-battle-rules.md)).
- **RF-05:** Envenenado: perde 1/8 do HP máximo no fim do turno, com mínimo de 1.
- **RF-06:** Paralisado: 25% de chance de não agir; a Velocidade cai pela metade (já na [01](01-battle-rules.md)).
- **RF-07:** Adormecido: não age por 1 a 3 turnos, sorteados quando o status começa. Uma criatura que entra Adormecida sorteia de novo. Ao acordar, age no mesmo turno.
- **RF-08:** Congelado: 20% de chance de descongelar a cada tentativa de agir; ao descongelar, age no mesmo turno.
- **RF-09:** Um status não pega em quem tem outro status principal, nem em quem é imune pelo Elemento (`status_condition_immunities`): evento `effect_failed`.

**Status voláteis** (somem ao sair de campo e no fim da batalha)

- **RF-10:** Confuso: dura 2 a 5 turnos; a cada tentativa de agir, 33% de chance de se atingir, em vez de agir.
- **RF-11:** Amedrontado: perde a ação deste turno, se ainda não agiu, e o efeito some no fim do turno.
- **RF-12:** Preso: impede fugir.

**Efeitos de Técnicas**

- **RF-13:** `apply_status` aplica o status de `status_condition_id` ao alvo; `flinch` deixa o alvo Amedrontado.
- **RF-14:** `modify_stat`: soma `stages` em `stat_id`, entre -6 e +6, no alvo de `skill_target_id`; no limite, `effect_failed`.
- **RF-15:** `heal`: cura `percent`% do HP máximo do autor; com HP cheio, `effect_failed`.
- **RF-16:** `drain`: cura `percent`% do dano causado; `recoil`: tira `percent`% do dano causado do autor. Ambos com mínimo de 1, se houve dano.
- **RF-17:** `protect`: bloqueia as Técnicas do adversário até o fim do turno. Bloqueia também os efeitos delas.

**Traços**

- **RF-18:** `instinct`: +1 de Velocidade ao derrotar um inimigo com uma Técnica.
- **RF-19:** `tailwind`: +1 de Velocidade ao entrar em campo.
- **RF-20:** `hard_shell`, `blazing_fury`, `tidal_fury` e `rooted_fury` já estão na [01](01-battle-rules.md).
- **RF-21:** Um slug de Traço sem efeito no motor é ignorado, sem erro.

**Ações especiais**

- **RF-22:** Fugir: 20% de chance de falhar, numa constante `FLEE_FAIL_CHANCE`, com comentário de que a regra será revista. A falha gera `flee_failed`, e o inimigo age.
- **RF-23:** Golpe de emergência: só com todas as Técnicas sem PP, com os valores de [architecture.md](architecture.md#valores-a-revisar), em `emergency.ts`. O dano em si mesmo vem depois do golpe, e ele pode desmaiar quem o usa.
- **RF-24:** Quando a criatura ativa do jogador desmaia e sobra alguma, a fase passa a `choose_next`; `switch` põe a escolhida em campo com estágios zerados, sem gastar turno.
- **RF-25:** Todas as criaturas do jogador caídas dão `defeat`, mesmo que o inimigo tenha caído no mesmo turno.

**IA**

- **RF-26:** `chooseEnemyAction(state, catalog, random)` sorteia entre as Técnicas com PP, com peso proporcional ao dano estimado, sem crítico e com Aleatório 1, como porcentagem do HP atual do alvo, entre 1 e 100.
- **RF-27:** Uma Técnica de suporte tem peso 20. Efetividade 0 tem peso 1.
- **RF-28:** Sem PP em todas as Técnicas, o inimigo usa o golpe de emergência.

## Critérios de aceite

- [ ] Uma batalha com fonte de sorteio fixa termina sempre igual, com a mesma lista de eventos.
- [ ] O estado recebido por `applyAction` não muda.
- [ ] Atacar até vencer dá `victory`, com `battle_ended` como último evento.
- [ ] Quem tem mais Velocidade age primeiro; Técnica de prioridade passa na frente.
- [ ] Cada ação inválida do RF-03 devolve a sua mensagem, e o estado não muda.
- [ ] Gastar PP: errar gasta; não poder agir não gasta.
- [ ] Sem PP, `skill` é recusada, e `emergency` funciona e tira 1/8 do HP do autor; com PP, `emergency` é recusada.
- [ ] Queimado e Envenenado perdem o valor certo no fim do turno; Fogo não queima, e uma criatura com status não recebe outro.
- [ ] Adormecido não age nos turnos sorteados e age no turno em que acorda.
- [ ] Congelado descongela com o sorteio abaixo de 20%.
- [ ] Paralisado perde a vez com o sorteio abaixo de 25%.
- [ ] Ciclone com o sorteio abaixo de 20% faz o alvo perder a vez, se ele ainda não agiu.
- [ ] Casca Fechada bloqueia o golpe do turno e não bloqueia o do seguinte.
- [ ] Rugido Feroz baixa o Atq do inimigo e, depois de 6 usos, dá `effect_failed`.
- [ ] Seiva Vital cura metade do dano; Erupção Solar tira 33% do dano do autor.
- [ ] Efeito de chance 10% vale com o sorteio abaixo de 0,1, e não acima.
- [ ] Instinto e Brisa Ligeira dão +1 de Velocidade na hora certa.
- [ ] Fugir com sucesso dá `fled`; com falha, o inimigo age, e o turno avança. Com `canFlee` falso ou Preso, é recusado.
- [ ] Com duas criaturas, a primeira desmaia, a fase vira `choose_next`, o inimigo não age, e a segunda entra.
- [ ] Todos caídos dão `defeat`; recuo que derruba os dois dá `defeat`.
- [ ] Com equipe de inimigos, o próximo entra sozinho.
- [ ] A IA escolhe mais a Técnica de maior dano, em 10.000 sorteios, e nunca escolhe uma sem PP.
- [ ] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Desenho técnico

**Criar**, em `server/src/domain/battle/`, com seus `.spec.ts`:

- `engine.ts`: `startBattle` e `applyAction`.
- `actions.ts`: uma ação em campo, do "pode agir?" ao desmaio.
- `status.ts`, `effects.ts` e `traits.ts`.
- `emergency.ts`: o golpe de emergência.
- `ai.ts`: `chooseEnemyAction`.
- `testing.ts`, só para os testes: combatente, catálogo mínimo e uma fonte de sorteio com a sequência dada.

**Reaproveitar**

As funções da [01](01-battle-rules.md). O estado é copiado no começo de `applyAction` (`structuredClone`), e o resto trabalha na cópia.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test
```

## Tarefas

- [ ] `testing.ts`; testes de `startBattle` e de um turno simples; ver falhar; implementar.
- [ ] Status principais e voláteis (RF-04 a RF-12).
- [ ] Efeitos e Traços (RF-13 a RF-21).
- [ ] Fuga, golpe de emergência e desmaio (RF-22 a RF-25).
- [ ] IA (RF-26 a RF-28).
- [ ] Marcar esta spec e a tabela do README como `concluída`; commit `feat: motor do turno da batalha`.

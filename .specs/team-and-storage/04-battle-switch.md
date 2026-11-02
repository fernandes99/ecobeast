# 04. Troca durante a luta

- **Status:** concluída
- **Depende de:** [03-team-screen](03-team-screen.md)

## Contexto

A ação `switch` só vale depois de um desmaio, e o botão Equipe da batalha está desativado desde a [battle-screen](../battle-screen/). Esta fase deixa o jogador trocar quem está em campo por outro da equipe principal, gastando a rodada. O Santuário não entra na luta.

## Escopo

- A ação `switch` em `choose_action`.
- `hp` e `status` em `creature_entered`.
- O botão Equipe e a escolha de quem entra.

## Fora do escopo

- Trocar com o Santuário durante a luta.
- Domadores NPC trocando de Ecobeast.
- Mudar a troca depois de um desmaio, que não gasta rodada.

## Requisitos

**Motor e API**

- **RF-01:** A ação `{ "type": "switch", "team_index" }` passa a valer em `choose_action`.
- **RF-02:** A ação é recusada com as mensagens de [architecture.md](architecture.md#a-troca-na-luta), sem gastar a rodada.
- **RF-03:** Sem recusa, o Ecobeast entra antes de qualquer ação do inimigo, seja qual for a Velocidade dos dois.
- **RF-04:** Quem entra tem os estágios e os efeitos temporários zerados, e o Traço de entrada vale.
- **RF-05:** Depois da entrada, o inimigo age sozinho, e o turno termina como depois de um item.
- **RF-06:** Quem saiu mantém HP, status e PP.
- **RF-07:** `creature_entered` traz `hp` e `status`.
- **RF-08:** Em `choose_next`, a ação continua sem gastar a rodada.

**Tela**

- **RF-09:** O botão Equipe mostra "Equipe", com o tamanho de texto de Atacar e Correr.
- **RF-10:** O botão fica ativo quando o jogador pode agir e tem mais de 1 Ecobeast, e desativado enquanto o turno aparece.
- **RF-11:** Tocar em Equipe abre um painel com a equipe, sem o Santuário, e o botão "Voltar".
- **RF-12:** Quem está em campo aparece desativado, como quem tem 0 HP.
- **RF-13:** Tocar em um Ecobeast fecha o painel e faz a troca.
- **RF-14:** O histórico mostra "<Ecobeast> entrou na luta.", e depois os eventos do inimigo.
- **RF-15:** O cartão mostra o HP de quem entrou antes do dano do inimigo, e só cai junto com a linha do ataque.
- **RF-16:** Uma recusa aparece no histórico em vermelho, e o jogador continua podendo agir.
- **RF-17:** O voltar do Android fecha o painel.
- **RF-18:** Depois de um desmaio, o painel continua sem "Voltar".

## Critérios de aceite

- [x] A troca põe o outro Ecobeast em campo, e o turno avança.
- [x] Um inimigo mais rápido ataca depois da entrada.
- [x] O ataque do inimigo acerta quem entrou.
- [x] Trocar para quem está em campo é recusado sem gastar a rodada.
- [x] Trocar para quem tem 0 HP é recusado sem gastar a rodada.
- [x] Trocar para uma posição que não existe é recusado sem gastar a rodada.
- [x] Preso, a troca é recusada sem gastar a rodada.
- [x] Quem saiu mantém HP, status e PP, e volta sem as mudanças de atributos.
- [x] O veneno de quem entrou dói no fim do turno.
- [x] Se o inimigo derrubar quem entrou, a luta segue para `choose_next`.
- [x] O fim da luta grava o HP dos dois Ecobeasts.
- [x] Com 1 Ecobeast, o botão Equipe fica desativado.
- [x] O painel mostra só a equipe, com quem está em campo desativado.
- [x] O cartão mostra o HP cheio de quem entrou até a linha do ataque.
- [x] "Voltar" fecha o painel sem gastar a rodada.
- [x] Depois de um desmaio, o painel não tem "Voltar".
- [x] Em 360×640 e 720×1061, o painel cabe com 6 Ecobeasts.
- [x] O projeto abre sem erros nem avisos de script.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Alterar**

- `server/src/domain/battle/types.ts`: `hp` e `status` em `creature_entered`.
- `server/src/domain/battle/engine.ts`: a recusa, a nova função `switchCreature` e `enterField` com os dois campos.
- `server/src/domain/battle/engine.spec.ts`: os casos novos, e a recusa antiga de `switch` em `choose_action`.
- `server/src/battle/battle.dto.ts`: a descrição de `switch`.
- `server/test/battle.e2e-spec.ts`: o fluxo com o banco.
- `client/screens/battle/next_creature_panel.gd` e `.tscn`: `open` recebe quem está em campo e se pode voltar, e ganha o botão "Voltar".
- `client/screens/battle/next_creature_row.gd`: `set_creature` recebe se está em campo.
- `client/screens/battle/battle_display.gd`: `_enter` usa `hp` e `status` do evento.
- `client/screens/battle/battle_screen.gd` e `.tscn`: `%TeamButton` ativo.
- `.specs/battle-core/architecture.md`: a ação e o evento.
- `.specs/battle-screen/architecture.md`: o cartão ao entrar.
- `.specs/roadmap.md`: `team-and-storage` concluída.
- `CLAUDE.md`: o Escopo atual cita a `team-and-storage`.

**Reaproveitar**

`enterField`, `playEnemyAlone`, `_act`, `NextCreaturePanel` e `NextCreatureRow`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 60
```

Uma cena temporária abre lutas contra um servidor de teste, troca pelos botões reais, confere os critérios automáticos e salva capturas de tela. As capturas abertas são citadas no relatório.

Passos do dono no editor (F5) e no celular:

1. Com 2 ou mais Ecobeasts, trocar quem está em campo e conferir se o inimigo ataca quem entrou.
2. Depois de um desmaio, conferir se a escolha continua sem "Voltar".

## Tarefas

- [x] Testes do motor; ver falhar; ação e evento (RF-01 a RF-08).
- [x] Testes e2e; ver falhar; ajustar o que faltar.
- [x] Verificação temporária da tela; ver falhar.
- [x] Botão, painel e cartão (RF-09 a RF-18).
- [x] Remover os arquivos temporários; atualizar as specs citadas; marcar esta spec e as tabelas como `concluída`; commit `feat: troca durante a luta`.

## Decisões da implementação

- **A troca nunca termina em derrota:** quem sai tem HP, então sobra alguém de pé mesmo se o inimigo derrubar quem entrou. Por isso, o critério cita só `choose_next`.
- **O cartão começa sem estágios nem `confused`:** além de `hp` e `status`, que a spec pedia. O estado final da resposta já traria as mudanças do turno, e o cartão as mostraria antes da linha do ataque.
- **O título do painel não mudou:** "Escolha o próximo Ecobeast" serve à troca e ao desmaio.
- **Com os outros em 0 HP, o botão Equipe fica ativo:** a regra é ter mais de 1 Ecobeast. O painel abre com todos desativados, e "Voltar" fecha.
- **Quem está em campo não tem um aviso próprio:** a linha só fica desativada, como pede a RF-12.
- **Um Adormecido sorteia os turnos de novo ao entrar:** é a regra de sempre de `enterField`. Agora o jogador pode usá-la, trocando para fora e voltando. Fica para o balanceamento.
- **Rede simulada:** a falta de servidor foi testada trocando o endereço da API por uma porta sem nada.
- **Conferência:** os testes do motor falharam antes da regra, e os 4 e2e novos falharam com a regra desligada. Uma cena temporária abriu lutas contra um servidor de teste, com o mouse entrando por `Input.parse_input_event` em pixels da janela. Passou com 47 de 47 verificações em janelas de 360×640, 405×720, 412×915 e 720×1061, depois de falhar porque o botão e o "Voltar" não existiam. Quatro proteções da tela foram desligadas de propósito, e 10 verificações falharam, cobrindo todas elas. Das 20 capturas de tela, 4 foram abertas e revisadas. Os arquivos temporários foram removidos. O teste no celular fica para o dono.

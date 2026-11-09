# 16. O ícone do estado sobre a vida do Ecobeast

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [12-battle-signs](12-battle-signs.md) (as cores dos estados)

## Contexto

Na [12](12-battle-signs.md), o estado que pega sobe sobre o Ecobeast como um sinal ("Queimado"), que some. Depois dele, nada na tela diz que o Ecobeast continua queimado: o jogador só percebe quando o HP cai na vez seguinte. Em 2026-11-07, o dono perguntou como os estados funcionam na luta, Claude explicou as regras do servidor e apontou essa falta, e o dono pediu: "deixe um icone em baixo ou em cima da vida dele representando aquele estado. nas cores devidas (queimado é vermelho, toxico é verde, confuso é rosa, e etc)".

A fonte do jogo não tem símbolos como chama ou floco de neve, e o projeto não tem ícones de estado. Por isso o ícone é desenhado pelo Godot, como as setas da 12.

## Escopo

- Um ícone por estado, em cima da barra de vida de cada Ecobeast do tabuleiro, enquanto o estado durar.
- As cores dos estados pedidas pelo dono, que valem também para o sinal da 12.

## Fora do escopo

- O estado no cartão do Ecobeast.
- Um efeito quando a queimadura ou o veneno tiram HP.
- Mudar as regras dos estados, que são do servidor.

## Requisitos

- **RF-01:** Cada Ecobeast do tabuleiro mostra, em cima da barra de vida e centrada nela, uma linha com um ícone para cada estado que ele tem: primeiro o principal (queimado, envenenado, paralisado, dormindo ou congelado), depois confuso, com medo e preso. Sem estado, nada aparece.
- **RF-02:** O ícone é um círculo na cor do estado, com contorno escuro e um desenho escuro dentro (_a revisar_): chama (queimado), bolhas (envenenado), raio (paralisado), "Z" (dormindo), floco de neve (congelado), espiral (confuso), "!" (com medo) e cadeado (preso). Um estado desconhecido é um círculo na cor de `WARNING`, sem desenho.
- **RF-03:** As cores (`UiPalette.STATUS_COLORS`), pedido do dono para as três primeiras, as outras _a revisar_: queimado vermelho, envenenado verde, confuso rosa, paralisado amarelo, dormindo cinza-azulado, congelado azul-gelo, com medo violeta e preso marrom-claro. O sinal da 12 passa a usar as mesmas cores.
- **RF-04:** A tela acompanha os estados pelos eventos (`BattleStatuses`, em `res://screens/board_battle/battle_statuses.gd`):
  - `creature_entered` começa com o estado do evento, ou sem nenhum;
  - `status_applied` acrescenta o estado; o ícone aparece junto com o sinal da 12;
  - `woke_up` tira o "dormindo", `thawed` tira o "congelado" e `status_ended` tira o estado do evento (a confusão);
  - o medo sai no fim da próxima vez do Ecobeast, como no servidor: no `cannot_act` por medo ou no `vez_started` de quem joga depois dele;
  - `fainted` tira todos; `creature_left` esquece o Ecobeast; `battle_ended` tira confuso, com medo e preso de todos;
  - o item que cura o estado (`item_used` com `cured_status`) tira o principal do Ecobeast que o recebeu.
- **RF-05:** No fim de cada resposta do servidor, o principal e a confusão de cada Ecobeast ficam iguais aos do servidor (`status` e `confused`). O medo e o preso, que o servidor não manda, ficam como os eventos deixaram.

## Critérios de aceite

- [ ] Na luta, um Ecobeast queimado mostra a chama vermelha em cima da vida até cair ou a luta acabar.
- [ ] Um Ecobeast que acorda perde o "Z", e um confuso mostra a espiral rosa até a confusão acabar.

## Desenho técnico

**Criar:**

- `res://screens/board_battle/battle_statuses.gd` (`class_name BattleStatuses`, `RefCounted`): `of(key)`, `apply(event, key)` (devolve as vagas que mudaram), `cure(key)`, `sync(key, status, confused)` e `erase(key)`.
- `res://screens/board_battle/status_icons.gd` (`class_name StatusIcons`, `Node2D`): `slugs` e o desenho de cada ícone.

**Alterar:**

- `res://ui/theme/palette.gd`: as cores de queimado e envenenado.
- `res://screens/board_battle/board_view.gd`: `set_statuses(key, slugs)`, com os ícones logo acima da barra.
- `res://screens/board_battle/board_battle_screen.gd`: cada evento passa pelo `BattleStatuses`, o `item_used` cura, e o fim da resposta sincroniza.

## Verificação

- Um teste sem janela do `BattleStatuses` confere cada evento de RF-04 e a sincronização de RF-05.
- Um teste sem janela, com uma luta montada, confere: o selvagem queimado com a chama em cima da barra, na cor vermelha; o que entrou envenenado com as bolhas verdes; o confuso no servidor com a espiral; quem não tem estado sem ícone.
- Os testes da 09, 11, 12, 13, 14 e 15 seguem dando 0 falhas.
- O jogo sem janela abre sem erros nem avisos de script.
- Manual, com F5: o dono vê os ícones.

## Tarefas

- [x] Testes do `BattleStatuses` e da tela, vendo falhar.
- [x] `BattleStatuses`, `StatusIcons`, as cores, o `board_view` e a tela.
- [x] Os testes da 09, 11, 12, 13, 14 e 15.
- [ ] O dono ver com F5.

## Resultado da verificação

Em 2026-11-09, os dois testes falharam antes do código (sem o `battle_statuses.gd`; na tela, nenhum ícone, e queimado e envenenado ainda laranja e roxo) e passaram depois. O teste do `BattleStatuses` deu 0 falhas em cada evento de RF-04 e na sincronização de RF-05. Na luta montada, com o catálogo da API: o selvagem que a Técnica queimou ficou com `["burn"]`, a chama aparecendo aos 3,95 s, junto com o sinal "Queimado"; o que entrou envenenado, com `["poison"]`; o que o servidor diz confuso, com `["confusion"]`; os do jogador, sem ícone. Os ícones ficam centrados na barra, 16 pixels acima dela. As cores: queimado #F04438, envenenado #5CCB4A e confuso #F28AD0. Os testes da 09, 11, 12, 13, 14 e 15 e o do visualizador seguiram com 0 falhas, e o jogo sem janela, com o depurador, abriu sem erros nem avisos de script. A API, fora do ar, foi ligada só para os testes e desligada depois.

Os desenhos dos ícones não foram vistos com janela: falta o dono ver com F5.

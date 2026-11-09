# 12. Sinais de stat e de estado sobre o Ecobeast

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [11-support-skill-effects](11-support-skill-effects.md)

## Contexto

Na [11](11-support-skill-effects.md), a Rugido Feroz ganhou efeito e som, mas a queda do Ataque só aparece na frase do log. Claude tinha oferecido um sinal "Ataque ↓" sobre o alvo, e em 2026-11-06 o dono pediu: "pode colocar o sinal Ataque ↓, e pense que vai existir isso para mais tipos de status". Por isso o sinal é um só, para toda mudança de stat (os 7 que mudam na luta, para cima e para baixo) e para todo estado aplicado (Queimado, Envenenado e os outros), e um tipo novo de sinal entra em um lugar só.

A fonte do jogo (Nunito) não tem as setas ↑ e ↓ nem os triângulos ▲ e ▼: o texto as mostraria como um quadrado vazio. Por isso a seta é desenhada, ao lado do texto.

## Escopo

- O sinal de stat: o nome do stat e de 1 a 3 setas desenhadas, verde para cima e vermelha para baixo.
- O sinal de estado: o nome do estado, na cor dele.
- Os dois sobem sobre o Ecobeast e somem, como o número do dano.

## Fora do escopo

- Um ícone por estado sobre o Ecobeast enquanto o estado dura.
- O sinal quando o stat não muda mais (já em +6 ou −6) ou quando o estado não pega (`effect_failed`): a frase do log continua dizendo.

## Requisitos

- **RF-01:** `BattleSign.from_event(event)` (`res://screens/board_battle/battle_sign.gd`) diz o sinal de um evento: o texto, a cor e as setas (positivo para cima, negativo para baixo, 0 sem seta). Para um evento sem sinal, devolve `null`. Um tipo novo de sinal entra só aqui.
- **RF-02:** `stat_changed`: o texto é o nome do stat no catálogo ("Ataque", "Defesa Especial", "Precisão"), e as setas são os níveis que mudaram, até 3 ("Ataque" com 2 setas para baixo em −2; 3 setas em −4). A cor é `UiPalette.STAT_UP` (verde) para cima e `STAT_DOWN` (vermelho) para baixo.
- **RF-03:** `status_applied`: o texto é o nome do estado no catálogo ("Queimado"), sem seta, na cor de `UiPalette.STATUS_COLORS` (_a revisar_): burn laranja, poison roxo (na [16](16-status-icons.md), o dono pediu queimado vermelho e envenenado verde, e o sinal passou a usar essas cores), paralysis amarelo, sleep cinza-azulado, freeze azul-gelo, confusion rosa, fear violeta e trapped marrom-claro. Um estado sem cor usa `WARNING`.
- **RF-04:** O sinal aparece sobre o Ecobeast do evento, logo depois do efeito da Técnica (a [11](11-support-skill-effects.md), RF-03), e sobe e some como o número do dano, sem a sequência esperar por ele. Ele aparece também sem Técnica, como um estado vindo do chão.
- **RF-05:** As setas são triângulos desenhados com contorno escuro, como o contorno do texto, e não caracteres da fonte.

## Critérios de aceite

- [ ] Na luta, a Rugido Feroz mostra "Ataque" com uma seta vermelha para baixo sobre o alvo, depois da explosão marrom.
- [ ] Os sinais de stat e de estado saem certos para cada caso de RF-02 e RF-03.

## Desenho técnico

**Criar:** `res://screens/board_battle/battle_sign.gd` (`class_name BattleSign`, `RefCounted`): `text`, `color`, `arrows` e `static func from_event(event: Dictionary) -> BattleSign`.

**Alterar:**

- `res://ui/theme/palette.gd`: `STAT_UP`, `STAT_DOWN` e `STATUS_COLORS`.
- `res://screens/board_battle/board_view.gd`: `float_sign(key, sign)`, com o texto e as setas numa linha (`Arrows`, um `Control` que desenha os triângulos), subindo como o `float_number`; a subida dos dois passa a ser uma função só.
- `res://screens/board_battle/board_battle_screen.gd`: no `stat_changed` e no `status_applied`, depois do efeito, `float_sign` com o sinal do evento.

## Verificação

- Um teste sem janela, com o catálogo, confere `from_event` em cada caso: Ataque −1, Velocidade +2, Defesa −4 (3 setas), Queimado com a cor dele, um estado sem cor e um evento sem sinal.
- O teste da Rugido Feroz (11) confere o sinal "Ataque" com 1 seta para baixo sobre o alvo, depois do efeito.
- Os testes da Arranhão e do som de dano (09) seguem dando 0 falhas.
- Manual, com F5: o dono vê o sinal.

## Tarefas

- [x] Testes do sinal, vendo falhar.
- [x] `BattleSign`, as cores, o `float_sign` e a tela.
- [x] Os testes da 09, 11 e desta.
- [ ] O dono ver com F5.

## Resultado da verificação

Em 2026-11-06, os dois testes falharam antes do código (sem o `battle_sign.gd` e sem o sinal na tela) e passaram depois. O teste do `from_event`, com o catálogo da API, deu 0 falhas: Ataque −1 com 1 seta vermelha, Velocidade +2 com 2 verdes, Defesa −4 com 3, "Defesa Especial", Queimado na cor dele, as 8 cores de estado, um estado sem cor em `WARNING` e o dano sem sinal. No teste da Rugido Feroz, o sinal "Ataque" com 1 seta para baixo sobe aos 3,94 s, depois do efeito (3,44 s) e junto da frase. Os testes da Arranhão e do som de dano seguiram com 0 falhas. O projeto importou sem erros, e o jogo sem janela abriu sem erros nem avisos de script.

O desenho das setas não foi visto aqui: falta o dono ver com F5.

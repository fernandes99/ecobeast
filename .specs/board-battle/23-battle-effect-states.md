# 23. Os efeitos que duram, no Ecobeast e no chão, com a depuração F3

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [12](12-battle-signs.md) e [16](16-status-icons.md) (o sinal e o ícone dos estados)

## Contexto

Em 2026-11-13, o dono pediu os efeitos nos Ecobeasts durante a luta: "quero ligar um debug na batalha para conseguir testar, queria ter opções de ligar qualquer efeito tanto no campo quanto no ecobeast", e "mapie todos os efeitos e faça algum indicador ou efeito no campo de batalha/ecobeast (coloque também algum icone em algum lugar presetnando que aquele ecobeast está com aquele feito)".

Claude mapeou o que dura na luta, pelo catálogo e pelo servidor:

| Onde | Efeito | Hoje |
| --- | --- | --- |
| Ecobeast | Queimado, Envenenado, Paralisado, Adormecido, Congelado | o ícone em cima da vida ([16](16-status-icons.md)) |
| Ecobeast | Confuso, Amedrontado, Preso | o ícone em cima da vida |
| Ecobeast | Protegido (Casca Fechada): o servidor tira no começo da próxima vez dele | nada |
| Ecobeast | Os níveis de Ataque, Defesa, Ataque Especial, Defesa Especial, Velocidade, Precisão e Evasão, de −6 a +6 | só o sinal que sobe e some ([12](12-battle-signs.md)) |
| Chão | Chão em chamas, o único efeito de chão do catálogo | o hexágono pintado, parado |

O catálogo tem o tipo de efeito "Mudar clima", mas nenhum clima nem Técnica que o use: fica de fora.

Claude propôs o desenho abaixo, e o dono respondeu "Pode seguir".

## Escopo

- Um efeito em loop no corpo do Ecobeast para cada estado e para o Protegido.
- O ícone do Protegido, junto dos ícones de estado, e as plaquinhas dos atributos que mudaram.
- Chamas animadas no Chão em chamas.
- O painel de depuração F3 na luta, que liga e desliga cada efeito.

## Fora do escopo

- Mudar as regras: quem decide o efeito é o servidor.
- Efeitos no cartão do Ecobeast.
- Clima.

## Requisitos

- **RF-01:** Enquanto o efeito dura, o Ecobeast mostra no corpo, desenhado pelo Godot, sem arquivo (_a revisar_):

  | Efeito | No Ecobeast |
  | --- | --- |
  | Queimado | chaminhas subindo do corpo e o corpo piscando avermelhado |
  | Envenenado | bolhas verdes subindo e o corpo pulsando verde |
  | Paralisado | faíscas amarelas em zigue-zague, um tremor curto e um clarão amarelo de vez em quando |
  | Adormecido | "Z"s subindo da cabeça e a animação na metade da velocidade |
  | Congelado | o corpo azul-gelo e parado, com cristais brilhando em volta |
  | Confuso | três estrelinhas girando em cima da cabeça |
  | Amedrontado | o corpo tremendo, com gotas de suor caindo |
  | Preso | um anel de correntes girando nos pés, metade atrás e metade na frente do corpo |
  | Protegido | uma bolha translúcida em volta do corpo, com um brilho que gira |

  Com mais de um, todos aparecem juntos; a cor do corpo é a do primeiro deles que muda a cor, na ordem da tabela.

- **RF-02:** O Protegido ganha um ícone de escudo, azul, na linha de ícones da [16](16-status-icons.md), depois dos estados. A tela acompanha: uma Técnica com o efeito `protect` usada pelo Ecobeast o protege; ele perde a proteção no começo da próxima vez dele (como no servidor), ao cair, ao sair e no fim da luta.
- **RF-03:** Cada atributo com nível diferente de 0 ganha uma plaquinha embaixo dos pés do Ecobeast, por cima dos Ecobeasts vizinhos, duas por linha, na ordem do catálogo: o nome curto do catálogo ("Atq", "Def.E", "Vel") e de 1 a 3 setas, verdes para cima e vermelhas para baixo, como o sinal da [12](12-battle-signs.md) (+4 a +6 mostram 3 setas e o número). Os níveis vêm do servidor no fim de cada resposta (`stages`), e no meio dela o `stat_changed` põe o `value` do evento; o Ecobeast que entra começa sem nenhum.
- **RF-04:** O Chão em chamas, além da cor, mostra chaminhas que tremulam no hexágono. Um efeito de chão sem desenho continua só com a cor.
- **RF-05:** F3, só com o jogo rodando pelo editor do Godot (como o F1 e o F2), abre e fecha o painel de depuração na luta, no pé da tela, por cima dos controles. Com ele aberto, tocar num hexágono escolhe o hexágono e o Ecobeast que estiver nele, em vez de jogar. O painel tem:
  - os 9 efeitos do Ecobeast escolhido, para ligar e desligar;
  - os 7 atributos, com − e + (de −6 a +6);
  - os efeitos de chão do catálogo, para ligar e desligar no hexágono escolhido;
  - "Limpar tudo", que tira os efeitos de todos os Ecobeasts e do chão.

  O hexágono escolhido fica aceso, e o efeito ligado fica com o fundo na cor dele.

  A depuração é só visual: o servidor não sabe dela, e a próxima resposta dele pode corrigir o que ela mudou. Decisão de Claude.

## Critérios de aceite

- [x] Cada efeito do RF-01 aparece no corpo do Ecobeast e some quando o efeito acaba.
- [x] O escudo e as plaquinhas aparecem e somem com o efeito.
- [x] O Chão em chamas tremula.
- [x] O F3 liga e desliga cada efeito.
- [ ] O dono vê os efeitos com F5 e F3.

## Desenho técnico

**Criar:**

- `res://screens/board_battle/creature_aura.gd` (`class_name CreatureAura`, `Node2D`): `effects` e o desenho de cada efeito, contado pelo tempo, sem nós de partícula. Uma camada de trás, irmã antes do corpo, desenha a metade de trás do anel de correntes. Ela muda a cor (`sprite.modulate`) e a posição (`sprite.position`) do sprite do Ecobeast e a velocidade da animação (`Token.speed`).
- `res://screens/board_battle/stage_chips.gd` (`class_name StageChips`, `Node2D`): as plaquinhas, desenhadas com a fonte do tema.
- `res://screens/board_battle/battle_effects_debug.gd` (`class_name BattleEffectsDebug`, `PanelContainer` montado por código): o painel do RF-05, com os sinais `status_toggled`, `stage_changed`, `mark_toggled` e `cleared`.

**Alterar:**

- `status_icons.gd`: o escudo do `protect`. `palette.gd`: a cor do Protegido em `STATUS_COLORS`.
- `battle_statuses.gd`: `protect(key)`, `toggle(key, slug)` e `clear_all()`; o `vez_started` tira o `protect` de quem começa a vez; o `fainted`, o `creature_left` e o `battle_ended` o tiram também.
- `board_view.gd`: `set_statuses` também passa os efeitos à aura; `set_stages(key, stages)`; `set_marks(colors, kinds)` com as chamas numa camada entre o chão e os Ecobeasts; o `Token` ganha `speed`, `aura` e `stages`.
- `board_battle_screen.gd`: os níveis por Ecobeast, a proteção no `skill_used`, o F3 e o painel.

## Verificação

- Um teste sem janela do `BattleStatuses` confere a proteção (dada, tirada na vez dele, mantida na vez de outro, tirada ao cair) e o `toggle`.
- Um print com janela, de poucos segundos, de cada efeito, para o dono.
- Um teste sem janela, com uma luta montada: cada efeito liga a aura certa no Ecobeast (a cor do corpo no Queimado e no Congelado, a animação na metade no Adormecido e parada no Congelado); o escudo na linha de ícones; as plaquinhas depois de um `stat_changed` de −2 na Defesa e +1 na Velocidade; as chamas no hexágono do `mark_placed`; e o painel F3 ligando um estado, um atributo e o fogo no chão e limpando tudo.
- O jogo sem janela abre sem erros de script e sem avisos novos.
- Manual, com F5 e F3: o dono vê os efeitos.

## Tarefas

- [x] Spec.
- [x] A aura, o escudo, as plaquinhas e as chamas.
- [x] O painel F3.
- [x] Os testes sem janela e os prints.
- [ ] O dono ver com F5 e F3.

## Resultado da verificação

Em 2026-11-13:

- **Testes sem janela:** os dois falharam antes do código (sem o `protect` no `BattleStatuses`; sem a `aura` no Ecobeast) e passaram depois, com 0 falhas. Na luta montada à mão (uma cena temporária, já apagada, sem luta no servidor): o Queimado pisca o corpo em vermelho; o Congelado deixa o corpo azul e a animação parada; o Adormecido, na metade; sem efeito, o corpo volta ao normal; a Casca Fechada põe o escudo e a bolha, que saem na vez seguinte dele; dois `stat_changed` deixam as plaquinhas "Def" −2 e "Vel" +1; o `mark_placed` põe as chamas, e o `mark_ended` as tira; o F3 abre o painel, escolhe o hexágono tocado, liga o Envenenado, sobe o Ataque duas vezes, põe fogo no chão e limpa tudo.
- **Prints com janela:** os 9 efeitos, as plaquinhas e o painel, numa janela aberta por poucos segundos. No primeiro print, as plaquinhas ficavam atrás do Ecobeast de baixo, e as chamas, as faíscas e as estrelas ficavam pequenas nos Ecobeasts pequenos: as plaquinhas passaram para cima dos vizinhos, com duas por linha, e os três efeitos cresceram.
- **Projeto:** o jogo sem janela, com o depurador, abre sem erros de script, com os mesmos 9 avisos de antes desta fase.
- **Falta o dono:** ver os efeitos em movimento, com F5 e F3.

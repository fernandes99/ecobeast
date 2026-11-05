# battle-slots

> **Substituída em 2026-11-04.** O dono trocou a ideia da luta: ela passa a acontecer num tabuleiro de hexágonos, com cada Ecobeast agindo na sua vez, numa iniciativa nova. Desta iniciativa, só o motor da [01](01-engine-slots.md) foi feito, e fica como base da luta nova: vários Ecobeasts por lado, o alvo pela posição, a captura de um entre vários e XP e moedas por selvagem. A [02](02-client-slots.md) e a [03](03-battle-scene.md) foram canceladas, e as peças da cena de frente e de costas e da caixa de mensagens foram apagadas.

A batalha passa a aceitar de 1 a 3 Ecobeasts em campo por lado, e a tela ganha o visual dos mockups do dono. Hoje o motor, a API e a tela supõem 1 contra 1 em tudo: um ativo por lado, uma ação por turno e o alvo sempre o único adversário.

O dono quer lutas de até 3 contra 3 ([o print de referência](#referência)), começando por no máximo 2 contra 2. Mas as lutas de verdade continuam 1 contra 1 até ele decidir como as maiores aparecem: "inicialmente serão apenas lutas 1x1". Esta iniciativa deixa o motor e a tela prontos para mais vagas, e só a batalha de teste abre uma luta maior.

## Objetivos

- O motor joga lutas de 1 a 3 vagas por lado, com a luta 1 contra 1 de hoje sem mudar de regra.
- Com mais de uma vaga, o jogador escolhe uma ação para cada um dos seus em campo e o alvo de cada Técnica.
- A tela mostra o cenário dos mockups do dono, com uma frase por vez, os 4 botões e o painel de Técnicas, e cabe de 1 a 3 Ecobeasts por lado.
- O servidor continua decidindo tudo. O cliente só mostra e envia as escolhas.

## Decisões

| Decisão | Motivo |
| --- | --- |
| Até 3 vagas por lado. Por enquanto, toda luta de verdade é 1 contra 1, e o 2 contra 2 só existe na batalha de teste | Decisão do dono. Como as lutas maiores aparecem fica para depois |
| A cada turno, o jogador escolhe a ação de cada um dos seus em campo, da esquerda para a direita, e só então o turno roda. "Voltar" desfaz a escolha anterior | Proposta aprovada pelo dono |
| Uma Técnica contra o adversário pede o alvo quando há mais de um adversário em pé. Com um só, vai direto. Técnicas em si mesmo não pedem alvo | Proposta aprovada pelo dono |
| Todos em campo agem pela ordem de hoje (prioridade, Velocidade, sorteio). Se o alvo desmaiou antes, a Técnica vai para o adversário em pé de menor posição | Proposta aprovada pelo dono |
| Quem desmaia deixa a vaga. O jogador escolhe quem entra nela no fim do turno; sem reserva, a vaga fica vazia. A derrota só vem quando todos caem | Proposta aprovada pelo dono |
| Fugir só vale como ação do primeiro em campo e serve para a equipe toda | Proposta aprovada pelo dono |
| Item, troca e Esfera gastam a ação de quem os escolheu | Proposta aprovada pelo dono |
| A Esfera pede o alvo. O capturado sai da luta, e ela continua com os outros | Proposta aprovada pelo dono |
| Cada selvagem derrubado paga XP e moedas em separado. O XP vai para quem esteve em campo contra ele, e o "nível de quem estava em campo" das moedas vira a média dos níveis dos seus em campo | Proposta aprovada pelo dono. No 1 contra 1, a conta é a mesma de hoje |
| A tela segue os mockups do dono: fundo de cenário, o selvagem de frente e o Ecobeast do jogador de costas, uma frase por vez letra por letra com toque para avançar, o histórico ao tocar na caixa, e Lutar, Equipe, Mochila e Fugir. Sem animação por enquanto | Decisão do dono, em 2026-11-03 |
| Cada lado tem o próprio número de vagas | Escolha do planejamento: não custa nada a mais e deixa uma luta 2 contra 1 possível no futuro |
| O contrato antigo da API vale até a [02](02-client-slots.md) trocar o cliente | Escolha do planejamento: cada fase é um commit, e o jogo não pode quebrar entre eles |

## Fora do escopo

- Como as lutas de 2 ou 3 vagas aparecem no jogo, como encontro, Domador NPC ou Arena. É decisão futura do dono.
- Técnicas que acertam vários alvos ou um aliado. Nenhuma Técnica do catálogo usa o alvo `all` hoje.
- Traços que mexem com aliados.
- Animações e sons.
- O visual novo dos painéis de Mochila, Equipe, troca, captura, comemoração, evolução e Técnica nova.
- Os outros elementos do print de referência, como a barra de energia e o selo de fraqueza.

## Pré-requisitos

- [battle-core](../battle-core/), [battle-screen](../battle-screen/), [capture](../capture/), [team-and-storage](../team-and-storage/) e [progression](../progression/) concluídas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-engine-slots](01-engine-slots.md) | Servidor: vagas no motor, uma ação por vaga, alvo, XP e moedas por selvagem, e a batalha de teste com vagas | concluída em parte |
| 2 | [02-client-slots](02-client-slots.md) | Jogo: modelos, `Session`, narrador e `BattleDisplay` no contrato novo; o servidor larga o antigo | cancelada |
| 3 | [03-battle-scene](03-battle-scene.md) | Jogo: a cena dos mockups do dono, com as vagas, o alvo e a luta 2 contra 2 no menu de depuração | cancelada |

O desenho compartilhado está no [architecture.md](architecture.md).

## Referência

O dono mandou três imagens em 2026-11-03 e 2026-11-04:

- duas da tela 1 contra 1 que ele quer: a cena e o painel "Escolha uma técnica";
- um print de outro jogo, com 3 contra 3.

Do print, vale só a ideia do formato. Nenhum nome, termo ou visual dele entra no jogo.

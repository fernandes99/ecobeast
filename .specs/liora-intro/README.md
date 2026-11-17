# liora-intro

A introdução do jogo, em Liora: a natureza da ilha com a narração, a criação do Domador dentro da cena, a chegada do avô, o caminho até a Vila Raiz, o reencontro com a Mira, o convite dela e o primeiro vínculo no Refúgio. O jogador novo passa a começar por ela, e não pela tela de nome. Para isso, o Domador nasce sem nome, Liora abre sem equipe, os NPCs podem ser pessoas (com as camadas da aparência do Domador), as falas mudam com o corpo do Domador e as cenas ganham dois passos novos, criar o Domador e escolher o inicial.

- **Status:** em andamento
- **Depende de:** [home-island](../home-island/), [story](../story/), [tamer-appearance](../tamer-appearance/), [island-npcs](../island-npcs/)

## Contexto

O dono escreveu o roteiro da introdução (em 7 partes, resumidas na [fase 04](04-intro-scenes.md)) e a [story](../story/) entregou as ferramentas para tocá-lo: cenas com falas, escolhas, Marcos, câmera e atores. A [home-island](../home-island/) faz de Liora a casa do jogador. Faltam quatro coisas que o roteiro pede e o jogo ainda não tem:

1. **A criação dentro da cena.** Hoje o jogo começa pela tela de nome, depois a Aparência e o inicial, e só então o mapa. No roteiro, a primeira cena é a natureza de Liora, e a criação aparece por cima do mapa, com o Domador nele.
2. **Liora sem equipe.** Explorar exige equipe no servidor (`ExplorationService.start`), e a introdução inteira acontece antes do inicial.
3. **Pessoas como NPCs.** Um NPC hoje é sempre o desenho de um Ecobeast (`npcs.sprite`); o avô e a Mira são pessoas.
4. **O texto que segue o Domador.** Falas sobre o Domador mudam com o corpo escolhido ("Você chegou cansado?" ou "cansada?").

## Objetivos

1. O jogador novo entra no jogo pela cena de Liora, sem nenhuma tela de menu antes.
2. A criação do Domador (nome e aparência) acontece por cima do mapa, sem tirar o Domador do lugar.
3. O primeiro vínculo acontece no Refúgio de Liora, numa cena.
4. O dono ajusta as cenas da introdução no F2 como qualquer outra cena.
5. Quem já tinha Domador e inicial não passa pela introdução.

## Não objetivos

- Desenhar o mapa de Liora (o dono, no F2; ver [fase 04](04-intro-scenes.md#pré-requisito-o-mapa-de-liora)).
- Arte final do avô, da Mira e do responsável do Refúgio: eles usam as camadas provisórias da [tamer-appearance](../tamer-appearance/).
- A Pradaria Serena e o que vem depois do primeiro vínculo.
- Pular a introdução.

## Antiobjetivos

- O jogador ficar sem nome para sempre porque uma cena faltou ou falhou.
- Um Domador sem equipe conseguir lutar, viajar ou explorar outra ilha.
- A tela de criação esconder o mapa inteiro.
- O servidor passar a conhecer o roteiro.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| A introdução roda no tocador de cenas, em Explorar, em Liora | As cenas são do mapa, e a câmera passeia pela ilha de verdade |
| O Domador é criado sem nome no primeiro login, e a cena abre a criação | No roteiro, a criação acontece dentro da cena, depois da narração |
| A forma de tratamento segue o corpo escolhido: só masculino ou feminino, sem outra pergunta | Decisão do dono |
| Eu (a IA) escrevo as cenas a partir do roteiro, e o dono ajusta no F2 | O roteiro já está pronto; o dono revisa em vez de montar do zero |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| O texto da fala aceita um trecho com as duas formas, como `{cansado\|cansada}` | Um trecho por palavra que muda, ao lado do `{nome}` que já existe |
| Só a ilha casa abre sem equipe, e sem equipe não há luta nem viagem | O resto do jogo continua exigindo um Ecobeast, e o servidor não precisa de outra regra |
| Os passos novos `create_tamer` e `choose_starter` | O nome e o inicial ficaram fora do `open_screen` de propósito ([story](../story/architecture.md#os-passos)) |
| Um NPC tem o sprite de um Ecobeast ou a aparência de pessoa, nunca os dois | O avô e a Mira usam as mesmas camadas do Domador; os Ecobeasts continuam como estão |
| A aparência de um NPC pessoa se edita no F2, pela mesma tela Aparência | O dono veste o NPC como veste o Domador, sem o painel do Supabase |
| Sem nome depois das cenas de entrada, o jogo abre a criação sozinho | Garante o antiobjetivo de nunca ficar sem nome |
| Quem já tem inicial ganha o Marco `introducao_pulada`, numa migration | As contas antigas pulam a introdução sem o servidor saber da história |
| A tela de nome (`title`) sai | A criação passa a ser só pela cena (ou pela criação aberta sozinha) |

## Fora do escopo

- Escolher a forma de tratamento separada do corpo.
- Música e som nas cenas ([story](../story/README.md#fora-do-escopo)).
- Retratos na caixa de fala.
- Esconder um NPC da ilha até um Marco (o avô fica em casa desde o começo; ver [fase 04](04-intro-scenes.md)).

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01](01-nameless-tamer.md) | O Domador sem nome e Liora sem equipe: `POST /v1/me` sem nome, `PUT /v1/me/name`, a casa sem equipe e o Marco `introducao_pulada` | concluída |
| [02](02-person-npcs.md) | Os NPCs pessoas: a aparência no catálogo dos NPCs, o desenho no mapa e nas cenas, e o botão Aparência na ferramenta NPC do F2 | concluída |
| [03](03-intro-steps.md) | Os passos da introdução: `create_tamer` com a criação por cima do mapa, `choose_starter`, o texto que segue o corpo, a entrada nova do jogo e o jogo sem equipe em Liora | concluída |
| [04](04-intro-scenes.md) | As cenas da introdução, escritas a partir do roteiro do dono, e os NPCs dela | rascunho |

O desenho que as fases compartilham está em [architecture.md](architecture.md).

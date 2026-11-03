# Team and storage

O jogador organiza quem sai para explorar. A equipe principal tem até 6 Ecobeasts; os outros ficam no Santuário, ainda sem limite. Ele escolhe quem começa a luta, traz Ecobeasts do Santuário e, na luta, troca quem está em campo.

## Contexto

Desde a [capture](../capture/), um Ecobeast capturado com a equipe cheia vai para o Santuário, mas nenhuma tela mostra quem está lá. Os cards "Santuário" e a aba "Equipe" do Hub abrem placeholders, e o botão Equipe da batalha está desativado desde a [battle-screen](../battle-screen/).

A ordem da equipe já vale: o primeiro Ecobeast com HP começa a luta e define o nível dos inimigos. O jogador só não consegue mudá-la.

## Quem usa

- O jogador, entre uma luta e outra e durante elas.

## Objetivos

1. O jogador vê todos os Ecobeasts do Santuário, com busca, filtro e ordem.
2. O jogador move Ecobeasts entre o Santuário e a equipe.
3. O jogador muda a ordem da equipe e escolhe quem começa a luta.
4. Na luta, o jogador troca quem está em campo por outro da equipe principal.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| A equipe principal tem 6 Ecobeasts, e só ela sai para explorar | Pedido do dono |
| O Santuário ainda não tem limite | Pedido do dono |
| No Santuário, tocar em um Ecobeast oferece mover para a equipe; se ela estiver cheia, o jogo pede para escolher quem sai, e os dois trocam | Pedido do dono |
| O Santuário é uma grade | Opção A, escolhida entre 2 mockups |
| A tela Equipe serve para escolher quem começa, ver quem precisa de cura, trocar com o Santuário e abrir os detalhes | Sugestão aprovada pelo dono |
| A ordem da equipe muda ao segurar e arrastar | Opção B, escolhida entre 2 mockups |
| Na luta, o jogador troca quem está em campo, só com a equipe principal | Pedido do dono |
| A troca na luta gasta a rodada, e o inimigo ataca quem acabou de entrar | Confirmado pelo dono |
| Com o Ecobeast em campo Preso, a troca fica bloqueada | Confirmado pelo dono, é a regra da fuga |
| Quem saiu perde as mudanças de atributos e os efeitos temporários da luta, e mantém HP, status e PP | Confirmado pelo dono |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| Com vaga na equipe, mover entra direto, sem pedir troca | Não há ninguém para sair |
| A equipe nunca fica sem Ecobeast | Sem equipe, o jogador não luta, e o servidor trata isso como Domador sem inicial |
| Mover e trocar mantêm HP, status e PP | Sair da equipe não deve curar nem punir |
| O Refúgio continua curando só a equipe | É a regra atual, e obriga a trazer de volta quem está ferido |
| Mover, trocar e reordenar fora da luta descartam a batalha aberta | Pelo mesmo motivo do Refúgio: uma luta deixada para trás gravaria dados antigos por cima |
| "Começa a luta" marca o primeiro Ecobeast com HP, não o primeiro da lista | É quem o servidor põe em campo |
| Um Ecobeast com 0 HP pode ficar em qualquer posição e pode ir para a equipe | Ele só não entra em campo; o jogador resolve no Refúgio |
| O Santuário lista tudo de uma vez, e a busca, o filtro e a ordem acontecem na tela | Com poucos Ecobeasts, é o caso mais simples; ver Dúvidas em aberto |
| Sem filtro de raridade por enquanto | Hoje todas as espécies são "Raro", e o filtro não mudaria nada |
| A busca procura no apelido e no nome da espécie | É o nome que o jogador vê na tela |
| A ordem padrão é nível do maior para o menor, com um toque invertendo | É o critério mais útil para escolher quem levar |
| O filtro só mostra os Elementos presentes no Santuário | São 15 Elementos, e a maioria ficaria sem resultado |
| O botão Equipe da batalha fica desativado com 1 Ecobeast só | Não há com quem trocar |

## Fora do escopo

- Limite do Santuário e caixas.
- Soltar ou vender um Ecobeast.
- Curar pelo Santuário ou pela tela Equipe.
- Comparar atributos entre Ecobeasts.
- Item segurado.
- Filtro de raridade.
- Trocar com o Santuário durante a luta.
- Domadores NPC trocando de Ecobeast (`npc-tamers`).
- Sons (`audio`).

## Pré-requisitos

- [creature-details](../creature-details/), [battle-screen](../battle-screen/) e [capture](../capture/) concluídas.

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01-team-api](01-team-api.md) | Rotas do Santuário, de mover, trocar e reordenar | concluída |
| [02-storage-screen](02-storage-screen.md) | Tela do Santuário, com busca, filtro e troca | concluída |
| [03-team-screen](03-team-screen.md) | Tela Equipe, com segurar e arrastar | concluída |
| [04-battle-switch](04-battle-switch.md) | Trocar quem está em campo durante a luta | concluída |

## Dúvidas em aberto

- **Santuário grande:** listar tudo de uma vez funciona com centenas de Ecobeasts, mas não foi medido com milhares no celular. Se o limite continuar aberto, a lista vai precisar de páginas.

# Heal station

O Refúgio cura a equipe. Tocar em **Refúgio** no Hub abre uma tela própria com a equipe e o botão **Curar todos**. O servidor devolve o HP e o PP ao máximo e tira os status de todos os Ecobeasts da equipe, de graça por enquanto.

## Contexto

A batalha guarda HP, PP e status no fim da luta ([battle-core](../battle-core/README.md)). Hoje nada recupera esses valores: o card "Refúgio" ainda abre um placeholder, e depois de uma derrota total Explorar zona só mostra "Cure sua equipe no Refúgio.". O jogador fica sem poder lutar até corrigir o banco à mão ou apagar o progresso.

## Quem usa

- O jogador, depois de uma luta.
- O futuro gasto de moedas, que entra neste mesmo fluxo.

## Objetivos

1. Depois de uma derrota total, o jogador volta a lutar sem sair do jogo.
2. Quem decide a cura é o servidor; o cliente só pede e mostra o resultado.
3. Nenhuma luta antiga grava o HP de antes por cima da cura.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                              | Motivo                                                                   |
| -------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Refúgio é uma tela própria, com um botão para curar todos            | Pedido do dono                                                           |
| A cura é de graça por enquanto                                       | O dono quer cobrar moedas, mas depois; o preço ainda não existe          |
| Sem som nesta iniciativa                                             | Os sons do jogo entram juntos, em outra iniciativa                       |

Tomadas no planejamento e apresentadas ao dono (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                 | Motivo                                                                                                          |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- |
| Cura HP, PP e status, só da equipe                                      | O Santuário ainda não existe na prática; a `team-and-storage` decide o que acontece com quem está lá            |
| O servidor cura primeiro, e a tela só mostra o resultado depois          | A tela nunca mostra uma cura que falhou                                                                         |
| Curar descarta a batalha aberta, sem gravar nada dela                   | Uma luta deixada para trás fica na memória por até 30 minutos e, se terminasse, gravaria o HP antigo por cima   |
| Com a equipe já curada, a rota responde `200` sem mudar nada, e o botão fica desativado | Repetir o pedido não é um erro, e a tela evita um toque inútil                                  |
| Depois de curar, o jogador continua na tela e sai por Voltar            | Ele vê o resultado e decide quando sair                                                                         |

## Fora do escopo

- Gastar moedas na cura. O preço e a regra entram depois.
- Sons e qualquer outro áudio.
- Animações de cura.
- Curar Ecobeasts do Santuário.
- Levar o jogador direto ao Refúgio a partir da tela de batalha.
- Curar com itens (`inventory-shop`).

## Pré-requisitos

- [battle-screen](../battle-screen/) concluída.

## Fases

| Fase                              | Entrega                                                       | Status   |
| --------------------------------- | ------------------------------------------------------------- | -------- |
| [01-heal-api](01-heal-api.md)     | Rota que cura a equipe e descarta a batalha aberta            | concluída |
| [02-heal-screen](02-heal-screen.md) | A tela do Refúgio, a ligação com o Hub e a rota no `Session` | rascunho |

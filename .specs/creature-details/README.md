# Creature details

A tela de detalhes do Ecobeast (TELAS.md #8). Tocar em uma criatura da equipe no Hub mostra quem ela é: sprite grande, HP e XP, Temperamento, Traço, atributos e Técnicas. É também onde o jogador dá um apelido a ela.

## Contexto

O jogador já tem um Ecobeast no servidor, mas só vê nome, nível e HP no card do Hub. Tocar no card abre uma tela placeholder ([hub/01](../hub/01-hub-screen.md), RF-09). O [onboarding](../onboarding/README.md) deixou o apelido para esta tela. Esta iniciativa vem antes do `battle-core` por decisão do dono: quando a batalha chegar, Técnicas, Traços e atributos já estarão à vista do jogador.

## Quem usa

Todo jogador com equipe. A mesma tela será aberta depois pelo Santuário e pela tela Equipe ([roadmap](../roadmap.md), `team-and-storage`).

## Objetivos

1. Tocar em um Ecobeast do Hub abre os detalhes dele, e o voltar retorna ao Hub.
2. Sprite, nome, Elemento, nível, HP e XP ficam sempre à vista; o resto se divide em três abas, sem rolagem.
3. O jogador dá, troca e remove o apelido, e isso vale em todo aparelho.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                 | Motivo                                                                    |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| Topo fixo e três abas (Resumo, Atributos, Técnicas), sem rolagem        | Dá para usar com uma mão, e o Ecobeast fica sempre à vista                 |
| Atributos em gráfico de hexágono                                        | Mostra de relance no que a criatura é forte                                |
| O apelido entra agora                                                   | O onboarding o deixou para esta tela                                       |
| Genes e Treino ficam de fora                                            | O jogador ainda não pode fazer nada com eles                               |
| Depois desta iniciativa vem o `battle-core`                             | Decisão de ordem do dono                                                   |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                                       | Motivo                                                                                      |
| --------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| O servidor manda `level_xp` e `next_level_xp` em cada criatura                                | A curva de XP é regra de jogo; a tela só faz a conta da barra                               |
| O apelido segue a regra do nome do Domador: 2 a 16 letras, números ou espaços                 | Uma regra só para o jogador aprender e para o servidor conferir                             |
| Com apelido, o nome da espécie aparece em texto secundário                                    | Quem dá um apelido continua sabendo que criatura é                                          |
| O hexágono usa a escala do maior stat da própria criatura                                     | Mostra o perfil dela, em qualquer nível; os números exatos ficam ao lado de cada ponta      |
| Sem cena nova de abas: a aba atual usa o botão padrão, e as outras, o `OutlineButton`          | Reaproveita o tema; `TabButton` é da barra inferior, com ícone                              |

## Fora do escopo

- Genes e Treino na tela.
- Descrição de cada Técnica, esquecer ou reordenar Técnicas.
- Trocar o item equipado (entra na `inventory-shop`); sem item, a tela diz "Nenhum".
- Linha evolutiva (entra no `codex`).
- Abrir os detalhes pelo Santuário ou pela tela Equipe.
- Filtro de palavras no apelido.

## Pré-requisitos

- [auth-google](../auth-google/) concluída: o jogador mora no servidor.

## Fases

| Fase                                      | Entrega                                                       | Status   |
| ----------------------------------------- | ------------------------------------------------------------- | -------- |
| [01-server-contract](01-server-contract.md) | XP do nível em cada criatura e a rota do apelido              | concluída |
| [02-details-screen](02-details-screen.md) | A tela em abas, o painel de apelido e a ligação com o Hub     | concluída |

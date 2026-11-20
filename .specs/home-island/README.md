# home-island

Liora vira a casa do jogador. O app abre em Explorar, na ilha marcada como casa; o Hub deixa de ser a primeira tela e vira o menu do Domador, aberto por um botão no mapa; e as viagens (as outras ilhas, a zona sorteada, o Desafiar e as Arenas) saem de um lugar da ilha, a ação Viagem, que o dono põe onde quiser no F2. Voltar de qualquer viagem leva de novo a Liora.

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [islands](../islands/), [island-villages](../island-villages/), [free-objects](../free-objects/), [hub](../hub/), [map-editor](../map-editor/)

## Contexto

Hoje o jogo é um menu: o Hub abre todas as features, e as ilhas são uma delas ("Ilhas", [islands](../islands/README.md)). O dono escreveu a introdução do jogo em Liora, com a casa do avô e a Vila Raiz, e quer que a ilha seja o lugar onde o jogador mora e para onde volta, com visitas à casa do avô durante a campanha. A introdução em si é a iniciativa seguinte, [liora-intro](../liora-intro/); esta entrega a estrutura em que ela roda.

## Objetivos

1. O jogador com Domador e inicial abre o app e já está andando em Liora.
2. Equipe, Mochila, Bestiário, Santuário, Refúgio e Aparência ficam a um toque, pelo menu do Domador, sem sair do mapa.
3. As outras partes do jogo (outras ilhas, zona sorteada, Desafiar, Arenas) são viagens que saem de um ponto da ilha.
4. Toda viagem termina de volta em Liora.
5. O dono escolhe no F2 qual ilha é a casa e onde fica a Viagem, sem id escrito no código.

## Não objetivos

- A introdução de Liora, o Domador sem nome e o jogo sem equipe em Liora ([liora-intro](../liora-intro/)).
- Desenhar o mapa de Liora (é o dono, no F2).
- Arte nova para o cais ou para a tela Viagem: o cais é qualquer peça ou construção com a ação Viagem.
- Mudar as regras de luta, de captura ou da loja.

## Antiobjetivos

- O jogador ficar preso em outra ilha ou na zona sem caminho de volta para casa.
- Duas explorações vivas ao mesmo tempo, com o servidor guardando uma e o cliente mostrando outra.
- Liora repetir a Loja também no menu (ela abre pelo prédio, como em qualquer ilha).

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| Liora é a casa: o app abre em Explorar na ilha casa | Combina com a vida no lugar e as visitas à casa do avô |
| O Hub vira o menu do Domador, aberto por um botão em Explorar, com Equipe, Mochila, Bestiário, Santuário e Aparência | A casa é o mapa, e não uma tela antes do menu |
| As viagens saem de um lugar da ilha; a Loja só pelo prédio | O mundo fica dentro do mapa |
| O Refúgio também fica no menu, além do prédio (2026-11-20: "No menu libera a opção de refugio por lá também") | Curar a equipe sem andar até o prédio |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| O lugar das viagens é a ação nova Viagem (`action_types.slug = travel`), que abre a tela Viagem | O dono a põe em qualquer peça, construção ou NPC, como o Refúgio e a Loja |
| A ilha casa é um campo da ilha (`islands.is_home`), uma só, ligado no F2 | O jogo não depende de um id no código, e o dono troca a casa sem migration |
| Sair de Liora e voltar a ela usam `Router.go_to`, nunca a pilha | O servidor guarda uma exploração por Domador; a de Liora deixa de valer quando outra começa, então voltar abre Liora de novo |
| Voltar a Liora põe o Domador no ponto de início da ilha | O servidor já começa toda exploração de ilha no ponto de início; chegar pelo cais pediria outra regra de posição no servidor |
| Sem ilha casa publicada, o jogo abre o menu, e ele ganha o cartão Viagem | O banco de desenvolvimento pode não ter casa; o jogo continua jogável |
| A Arena continua sendo uma tela placeholder, agora dentro da Viagem | Ela ainda não existe ([roadmap](../roadmap.md)) |

## Fora do escopo

- Chegar a Liora pelo cais (o Domador volta no ponto de início).
- Viajar entre ilhas por um mapa do mundo de Auralis.
- Esconder a Viagem até a introdução terminar (a [liora-intro](../liora-intro/) trata o jogador sem equipe).

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01](01-home-and-travel-data.md) | A ilha casa e a ação Viagem: `islands.is_home`, o `home` em `GET /v1/me/islands`, a rota do editor e o "Casa do jogador" do F2, e o tipo de ação `travel` | concluída |
| [02](02-open-at-home.md) | O app abre em Liora, o botão Menu em Explorar e o Hub virado menu do Domador | concluída |
| [03](03-travel-screen.md) | A tela Viagem e as voltas: sair pela Viagem e voltar sempre a Liora, da ilha, da zona, do Desafiar e da derrota | concluída |

O desenho que as fases compartilham está em [architecture.md](architecture.md).

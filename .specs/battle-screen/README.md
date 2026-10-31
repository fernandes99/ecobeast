# Battle screen

A batalha que o jogador vê. Tocar em **Explorar zona** no Hub começa uma luta contra um Ecobeast sorteado pelo servidor, e a tela mostra o turno linha a linha, a partir dos eventos do [battle-core](../battle-core/). O jogo só diz o que o jogador quer fazer: quem decide tudo é o servidor.

## Contexto

O [battle-core](../battle-core/) roda uma batalha inteira pela API, com os dados gravados no fim, mas o jogo não o alcança: o card "Explorar zona" ainda abre um placeholder, e a rota de começar exige espécie e nível, atrás de `ENABLE_TEST_BATTLE`. Falta um encontro que o próprio servidor sorteie e a tela (TELAS.md #5). Sem ela, nenhuma iniciativa de combate chega ao jogador.

## Quem usa

- O jogador, ao tocar em Explorar zona.
- As iniciativas seguintes, que ligam os botões desativados: itens e captura, e depois a troca de Ecobeast.

## Objetivos

1. Uma luta completa acontece no jogo, do Hub de volta ao Hub, sem o cliente decidir nada.
2. Cada evento do servidor vira uma linha em pt-BR, mostrada no ritmo do turno.
3. O HP, os status e os estágios na tela acompanham as linhas, e o estado final é sempre o do servidor.
4. Nenhuma situação da batalha trava o jogador: sem PP, desmaio, derrota, queda de rede e batalha expirada têm saída.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                                     | Motivo                                                                  |
| ------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Explorar zona começa uma luta contra um Ecobeast aleatório                                  | As zonas e o algoritmo de exploração ficam para outra iniciativa        |
| Layout A do canvas: dois cartões, histórico no meio e quatro botões                         | Escolhido nos protótipos; a tela será melhorada mais adiante            |
| Atacar e Correr funcionam; Itens e Equipe ficam visíveis e desativados, com "Em breve"      | Itens e captura são grandes e entram logo depois, numa iniciativa própria |
| O sorteio do inimigo acontece no servidor                                                   | O cliente não pode escolher um oponente fácil                           |
| Inimigo entre as 9 espécies do catálogo, com nível de 2 abaixo a 1 acima do Ecobeast de frente | Provisório, _a revisar_; a `wild-battle` troca pelas zonas              |
| O `heal-station` vem logo depois desta iniciativa, antes de itens e captura                 | Sem Refúgio, uma derrota total deixa o jogador sem conseguir lutar      |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                          | Motivo                                                                             |
| -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| O encontro tem rota própria, sempre ligada; a rota de teste continua como está   | A rota de teste aceita espécie e nível do cliente e não pode ir para produção      |
| A tela abre antes de pedir a batalha                                             | Os erros de começar aparecem nela, e o Hub não muda                                |
| O voltar do Android não sai da luta                                              | Sair é Correr; fechar o app continua abandonando a batalha, sem gravar             |
| Os textos do turno são escritos pelo cliente, a partir dos eventos               | O servidor manda só ids e números ([battle-core](../battle-core/README.md))        |
| As duas artes olham para a direita, e o inimigo é espelhado                      | Só existe `front.png`; assim as criaturas ficam de frente uma para a outra         |

## Fora do escopo

- Itens em batalha, captura e Mochila.
- Troca voluntária de Ecobeast. A única escolha é a do próximo, depois de um desmaio.
- XP, moedas, subir de nível e a tela de fim de batalha (TELAS.md #7).
- Zonas e seleção de zona (TELAS.md #4).
- Domadores NPC e Arenas.
- Animações de golpe, sons e arte de cenário.
- Retomar a luta depois de fechar o app.
- Acelerar ou pular a sequência de linhas do turno.

## Pré-requisitos

- [battle-core](../battle-core/) concluída.

## Fases

| Fase                                        | Entrega                                                                        | Status   |
| ------------------------------------------- | ------------------------------------------------------------------------------ | -------- |
| [01-wild-encounter](01-wild-encounter.md)   | Rota que começa uma luta contra um Ecobeast sorteado pelo servidor             | concluída |
| [02-battle-client](02-battle-client.md)     | Modelos da batalha, rotas no `Session` e os textos de cada evento              | aprovada |
| [03-battle-screen](03-battle-screen.md)     | A tela, o ritmo do turno, a escolha do próximo, o fim e a ligação com o Hub    | aprovada |

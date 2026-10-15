# Onboarding

A primeira experiência do jogador: abrir o jogo, dizer como quer ser chamado e escolher o primeiro Ecobeast entre três. Ao fim, ele tem um Domador e uma equipe com uma criatura, e o jogo passa a abrir direto no Hub.

## Contexto

Com [foundation](../foundation/) e [game-data](../game-data/) prontos, o jogo abre, carrega o catálogo e navega entre telas, mas não existe jogador. Esta iniciativa cria o estado do jogador — o modelo, o serviço que o altera e onde ele é guardado — e as duas telas que o criam.

O jogo será só online, com login pelo Google e o servidor decidindo as regras. Ainda não há servidor: no MVP o jogador é guardado num arquivo local e as regras rodam no cliente, mas atrás das mesmas interfaces que depois vão chamar a API.

## Quem usa

Quem abre o jogo pela primeira vez (ou depois de apagar o progresso).

## Objetivos

1. Do primeiro toque ao Hub em menos de um minuto: nome, escolha, confirmação.
2. Fechar e reabrir o jogo mantém o Domador e o inicial; a criatura é a mesma (mesmos Genes, Temperamento e Traço).
3. Trocar o armazenamento local pela API não muda nenhuma tela.

## Como funciona

1. Primeira abertura: a tela de entrada mostra o logo e pede o nome do Domador.
2. "Começar" cria o Domador e abre a escolha do inicial.
3. A escolha mostra Fagulho, Gotículo e Brotelho. Tocar num deles pede confirmação.
4. Confirmar cria a criatura no nível 5, coloca na equipe e abre o Hub.
5. Nas próximas aberturas o jogo vai direto para o Hub. Se o jogador fechou o jogo entre o nome e a escolha, volta para a escolha.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                | Motivo                                                               |
| ---------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Por enquanto a entrada pede só o nome; login com Google vem depois     | Simplificar o MVP                                                    |
| 3 iniciais: Fogo, Água e Flora                                         | GDD                                                                  |
| Jogador guardado em `user://save.json` atrás de um `PlayerRepository`  | Sem servidor ainda; a interface é a mesma que vai chamar a API       |
| As regras rodam no cliente atrás do `GameService`; no futuro, no servidor | Telas não mudam; o servidor será a autoridade                     |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                                        | Motivo                                                                                  |
| ---------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Nome com 2 a 16 caracteres (letras, números e espaço), espaços extras removidos                 | Cabe no topo do Hub; evita nomes vazios ou só de símbolos                                |
| Domador começa no nível 1 com 1000 moedas                                                      | O GDD não define; valor de partida para a futura loja                                    |
| Inicial no nível 5, Genes aleatórios, Temperamento aleatório, Traço normal aleatório, Vínculo 70 | Nível 5 dá HP e técnicas razoáveis para a primeira batalha; Vínculo baixo deixa espaço para crescer até 220 |
| Técnicas iniciais: as 4 últimas aprendidas por nível até o nível atual                          | Mesma regra do GDD para criaturas selvagens                                              |
| Prismático sempre falso no MVP                                                                  | Prismáticos são pós-lançamento                                                           |
| Confirmação antes de escolher o inicial                                                         | A escolha é definitiva                                                                   |
| O save local não é criptografado                                                                | É provisório; o estado definitivo vai morar no servidor                                  |
| Save ilegível é renomeado para `save.corrupted.json` e o jogo começa do zero                    | Não travar o jogo; guardar o arquivo para investigar                                     |
| Sem apelido na escolha do inicial                                                               | Fica para a tela de detalhes da criatura                                                 |

## Fora do escopo

- Login com Google, contas e servidor ([roadmap](../roadmap.md)).
- Tutorial, história ou personagem guia.
- Apelido, gênero escolhido e aparência do Domador.
- Tela de configurações (o ícone de engrenagem do TELAS.md #1).

## Pré-requisitos

- [foundation/02-ui-shell](../foundation/02-ui-shell.md) e [game-data/03-starter-content](../game-data/03-starter-content.md) concluídas.

## Fases

| Fase                                                  | Entrega                                                                  | Status   |
| ----------------------------------------------------- | ------------------------------------------------------------------------ | -------- |
| [01-title-and-tamer-name](01-title-and-tamer-name.md) | Estado do jogador, serviços, boot e tela de entrada com o nome           | concluída |
| [02-starter-selection](02-starter-selection.md)       | Regras de criatura (stats, XP, geração) e tela de escolha do inicial     | rascunho |

O desenho compartilhado está em [architecture.md](architecture.md).

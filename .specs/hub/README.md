# Hub

A tela principal do jogo (a "Home" do TELAS.md #3): quem é o Domador, como está a equipe e o acesso a todas as features. No MVP só a tela existe de verdade; cada feature abre uma tela placeholder, e cada iniciativa futura troca o seu placeholder pela tela real.

## Contexto

Depois do [onboarding](../onboarding/), o jogador tem um Domador e uma criatura na equipe, e o jogo abre um placeholder "Hub". Esta iniciativa entrega o Hub com o layout final, para que o jogo já tenha a cara que vai ter e a navegação de todas as features possa ser testada.

## Quem usa

Todo jogador com o inicial escolhido; é a tela em que o jogo abre a partir da segunda vez.

## Objetivos

1. Em uma olhada: nome, nível e moedas do Domador e a equipe com nível e HP.
2. Toda feature do jogo 1.0 está a um toque, no lugar onde vai ficar.
3. Uma iniciativa futura liga a sua feature trocando um único id de tela.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                | Motivo                                       |
| ---------------------------------------------------------------------- | -------------------------------------------- |
| Toda feature ainda não feita abre uma tela placeholder com "Voltar"    | A navegação fica testável desde o MVP        |
| O Hub segue o TELAS.md #3                                              | Layout já definido no protótipo              |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                        | Motivo                                                                             |
| ------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------- |
| As ações e abas ficam numa tabela de dados no script do Hub (rótulo → tela)    | Ligar uma feature nova é trocar o id de tela na tabela                             |
| Equipe em grade de 3 × 2, slots vazios visíveis                                | Mostra que cabem 6 e convida a capturar mais                                       |
| Botões só com texto (sem ícones) no MVP                                         | Não há arte ainda; ícones entram com a direção de arte                            |
| "Apagar progresso" no placeholder do Perfil, só em build de debug               | Permite refazer o onboarding durante o desenvolvimento sem mexer em arquivos        |
| O nível do Domador aparece fixo em 1                                            | O GDD não define como ele sobe ([roadmap](../roadmap.md#dúvidas-globais-em-aberto)) |

## Fora do escopo

- Qualquer feature por trás dos botões (batalha, loja, Santuário… — ver [roadmap](../roadmap.md)).
- Reorganizar a equipe, tela de detalhes da criatura.
- Notificações, eventos, anúncios.

## Pré-requisitos

- [onboarding/02-starter-selection](../onboarding/02-starter-selection.md) concluída.

## Fases

| Fase                              | Entrega                                                       | Status   |
| --------------------------------- | ------------------------------------------------------------- | -------- |
| [01-hub-screen](01-hub-screen.md) | Hub com Domador, equipe, ações, barra inferior e placeholders | concluída |

# skill-test

Na aba Técnicas do F1, o botão **Testar técnica** abre uma luta de verdade no tabuleiro, com um Ecobeast emprestado que tem a Técnica. O dono escolhe quem usa, o oponente e o nível, e pode deixar o oponente parado. A Técnica volta na hora e não gasta PP, e nada da luta é gravado.

## Contexto

Em 2026-11-20, o dono pediu: "No f1, eu quero testar cada técnica como se fosse uma luta real de forma rápida". A ideia dele era "um botão de 'Testar técnica' e nele vai abrir um campo de batalha com um ecobeast que tem essa técnica de exemplo, e eu vou poder usar ela".

O que existe hoje:

- **A luta de teste** (`POST /v1/me/board-battle`, só com `ENABLE_TEST_BATTLE` ligada) é a que os botões de Debug de Explorar usam. Ela leva a equipe de verdade do jogador e, no fim, grava XP, HP, itens, moedas, evolução e o Bestiário (`BattleRecordsService.finish`). Para testar Técnicas, isso bagunçaria o progresso.
- **A luta copia as Técnicas quando começa** (`loadBattleCatalog` no `begin` do `BoardBattleService`). Uma Técnica salva pelo formulário do F1 ([skill-editor](../skill-editor/README.md)) vale no próximo teste.
- **O F1 é uma janela à parte** (`ContentViewer`, um `Window`). A luta abre na janela principal, pelo `Router`, como a de Explorar.

## Objetivos

1. Ver qualquer Técnica funcionando numa luta real em poucos segundos, sem caçar um Ecobeast que a aprenda.
2. Usar a Técnica várias vezes seguidas, contra o oponente escolhido.
3. Não mudar nada do jogador: nem a equipe, nem os itens, nem o Bestiário.

## Anti-objetivos

- Uma luta com regras diferentes das de verdade, além das duas opções de teste: o motor é o mesmo.
- O jogador ver isso: o F1 só existe com o jogo rodando pelo editor, e a rota só existe com `ENABLE_TEST_BATTLE` ligada.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| Um botão **Testar técnica** no F1 que abre uma luta com um Ecobeast que tem a Técnica | O pedido |
| O dono escolhe a espécie do oponente, e um botão deixa o oponente parado | Escolha do dono entre isso e um boneco parado |
| Uma rota nova de teste no servidor, com a luta sem gravar nada | Escolha do dono entre isso, a luta de teste de hoje com a equipe dele e uma luta simulada no jogo |

Escolhas de Claude (_a revisar_; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A luta é 1×1 por padrão; 2×2 e 3×3 vieram na [03](03-team-sizes.md), a pedido do dono | Basta para ver a Técnica, e o tabuleiro fica pequeno |
| O dono escolhe também quem usa, começando por quem aprende a Técnica | O Elemento de quem usa muda o dano, e uma Técnica nova pode não ter aprendiz |
| Um nível só para os dois lados, 50 por padrão | Os atributos ficam de luta de meio de jogo, e o dano dá para comparar |
| A Técnica testada fica no 1º espaço, com mais duas do learnset de quem usa | As outras ajudam a testar a combinação, e a barra fica como numa luta |
| A Técnica volta na hora e não gasta PP só do lado do jogador | O oponente com IA luta como luta de verdade |
| A luta de teste não dá XP nem moedas (`noRewards`), e perder não tira moedas | Sem isso, o histórico mostraria um XP que não é gravado |
| O oponente parado só passa a vez, sem andar nem agir | É o boneco de treino, e ele ainda leva os golpes e os estados |
| Sem itens, sem Esfera e sem moedas, com a fuga liberada | Fugir é o jeito de sair no meio |
| O oponente não fica visto no Bestiário | Nada do teste é gravado |
| No fim, **Testar de novo** abre a mesma luta outra vez | O teste fica rápido de repetir, e um oponente parado acaba caindo |
| O F1 continua aberto ao lado da luta | O dono pode mudar a Técnica no formulário e testar de novo |
| Um teste aberto dá lugar ao novo no **Começar**; uma luta de verdade aberta mostra o aviso | Do dono: "quero que termine ela e já inicie outra". Uma luta de verdade não se perde sem querer |

## Fora do escopo

- Lutas de teste com a equipe do jogador.
- Escolher as outras duas Técnicas, o Traço, os Genes ou o estado de quem usa.
- Escolher o bioma ou o tamanho do tabuleiro.
- O modo deus (`god`) na luta de teste.

## Pré-requisitos

- [skill-editor](../skill-editor/README.md) concluída: o detalhe da Técnica com o botão **Editar**.
- [board-size](../board-size/README.md) concluída: o tabuleiro sorteado por luta.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-test-route](01-test-route.md) | Servidor: a rota da luta de teste da Técnica, as três opções do motor e a luta que não grava | concluída |
| 2 | [02-test-button](02-test-button.md) | Jogo: o botão e o painel no F1, a luta de teste e o **Testar de novo** | concluída (falta o dono conferir no jogo) |
| 3 | [03-team-sizes](03-team-sizes.md) | Servidor e jogo: o teste em 2×2 e 3×3, com todos do jogador com a Técnica | concluída (falta o dono conferir no jogo) |

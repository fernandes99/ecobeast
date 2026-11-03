# progression

Ecobeasts ganham XP ao vencer, sobem de nível, aprendem Técnicas novas e evoluem. Hoje vencer não muda nada: a equipe fica no nível em que nasceu ou foi capturada, e as evoluções só chegam por captura. Sem isso, as regras do [biome-encounters](../biome-encounters/), que dependem do nível médio da equipe, quase não aparecem no jogo.

## Objetivos

- Vencer por nocaute dá XP a quem lutou, dividido em partes iguais, e o log da luta mostra quanto cada um recebeu.
- Quem passa de nível vê uma tela de comemoração com o nível e os stats de antes e depois.
- Uma Técnica liberada no nível entra sozinha se houver vaga. Com as 4 ocupadas, o jogador escolhe qual esquecer ou não aprende.
- No nível de evolução, o Ecobeast evolui, e o jogador pode cancelar. Quem cancelou tem nova chance na próxima vez que subir de nível.
- O servidor decide tudo: XP, nível, stats, quais Técnicas foram oferecidas e se a evolução está disponível. O cliente só mostra e envia as escolhas.

## Decisões

| Decisão | Motivo |
| --- | --- |
| Só a vitória por nocaute dá XP. Captura, fuga e derrota não dão nada | Decisão do dono |
| O XP de um inimigo derrubado é dividido em partes iguais entre quem entrou em campo contra ele e não desmaiou | Decisão do dono: trocar de Ecobeast no meio da luta continua sendo estratégia, e não um jeito de multiplicar XP |
| Quem desmaiou durante a luta não recebe XP | Decisão do dono |
| Depois da luta, uma tela de comemoração por Ecobeast que subiu: ele grande e animado, o nível antigo e o novo, e os stats de antes e depois | Decisão do dono, opção B entre os três esboços mostrados |
| Com as 4 vagas ocupadas, o jogador escolhe qual Técnica esquecer ou toca em "Não aprender" | Decisão do dono |
| A evolução pode ser cancelada durante a animação. Quem cancelou recebe a mesma pergunta na próxima vez que subir de nível | Decisão do dono |
| No jogo, o termo é "Evolução" e "evoluir". "Ascensão" sai do glossário, do catálogo e dos textos | Decisão do dono: "não utilize a palavra ascendeu, utilize evoluir mesmo" |
| Fórmula do XP: `floor(xp_base × nível do inimigo ÷ 7)`, a do GDD sem o bônus de Domador nem de item | O GDD já define. O bônus de Domador chega com a `npc-tamers`, e o de item quando houver item. Os números são _a revisar_ |
| Um Ecobeast no nível 100 não entra na divisão | Escolha do planejamento: ele não pode usar o XP, e incluí-lo tiraria XP de quem pode. _A revisar_ |
| As escolhas que ficam pendentes (Técnica com as vagas cheias e evolução) moram na memória do servidor, como a exploração | Escolha do planejamento: o XP e o nível já foram gravados. Se o jogo fechar no meio, a evolução volta no próximo nível, e uma Técnica não escolhida conta como "Não aprender". Mesmo aceite de "Abandonar batalha" do [roadmap](../roadmap.md) |
| As telas de comemoração, evolução e Técnica abrem por cima da tela de batalha, antes do botão "Voltar" | Escolha do planejamento, a mesma forma da Esfera na [capture](../capture/): sair continua sendo um `Router.back()` para o mapa |

## Fora do escopo

- O bônus de XP contra Domadores NPC (vem com a `npc-tamers`) e os itens que dão XP ou dividem XP com quem não lutou.
- Moedas por vitória: a renda de moedas é uma dúvida global do [roadmap](../roadmap.md).
- Evoluções por item, Vínculo, horário, zona, troca ou Temperamento: o catálogo já tem esses gatilhos, mas só o de nível entra agora.
- Reaprender uma Técnica esquecida ou recusada, e ensinar Técnicas por item (`teachable`).
- Ganho de Vínculo ao subir de nível, nível do Domador e o Bestiário registrando a espécie evoluída (vem com o `codex`).
- Sons (vem com o `audio`).
- Retomar uma escolha pendente depois de fechar o jogo.

## Pré-requisitos

- [battle-core](../battle-core/) e [battle-screen](../battle-screen/): a batalha no servidor e a tela que a mostra.
- [team-and-storage](../team-and-storage/): a troca de Ecobeast na luta, que decide quem entrou em campo.
- [creature-details](../creature-details/): o XP do Ecobeast já aparece em barra (`level_xp`, `next_level_xp`).

## Fases

| #   | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-xp-and-levels](01-xp-and-levels.md) | Servidor: XP dividido entre quem lutou, nível e stats gravados, e o termo Evolução no catálogo | rascunho |
| 2 | [02-skills-and-evolution](02-skills-and-evolution.md) | Servidor: Técnicas aprendidas ou oferecidas, evolução oferecida e as rotas das escolhas | rascunho |
| 3 | [03-level-up-screen](03-level-up-screen.md) | Jogo: XP no log, barra de XP enchendo e a tela de comemoração | rascunho |
| 4 | [04-evolution-and-skills-screens](04-evolution-and-skills-screens.md) | Jogo: tela da evolução com "Cancelar" e tela de escolher a Técnica | rascunho |

O desenho compartilhado está no [architecture.md](architecture.md).

# dialogue-voices

As falas ganham voz: enquanto a caixa de fala escreve o texto, toca um bipe curto de videogame antigo, e cada personagem tem a sua voz. O avô é grave e fala devagar, a Mira é aguda e rápida, a narração é suave, e os Ecobeasts piam. A voz é escolhida no NPC, pelo F2.

- **Status:** concluída (falta o dono ouvir no jogo)
- **Depende de:** [island-npcs](../island-npcs/), [story](../story/), [liora-intro](../liora-intro/)

## Contexto

A caixa de fala (`TamerGreetingPanel`) escreve o texto letra por letra, a 60 letras por segundo, e é a mesma nas cenas da história, na conversa com os NPCs da ilha e na fala dos Domadores NPC. Ela é muda. O jogo não tem nenhum som de interface: só a música ([battle-intro](../battle-intro/)), os sons de golpe da luta e o lugar do `call.wav` de cada Ecobeast ([creature-sounds](../creature-sounds/)), que ainda não toca. O dono quer "um sonzinho característico" para as falas.

## Abordagens consideradas

| Abordagem | Troca | Escolha |
| --- | --- | --- |
| Uma voz só para todos | O mais simples, e já dá o som do jogo, mas não ajuda a saber quem fala | descartada pelo dono |
| **Uma voz por personagem** | Dá personalidade às cenas com várias pessoas e diz quem fala antes do nome; pede uma tabela nova no catálogo, um campo no NPC e alguns sons | **escolhida pelo dono** |

O dono ouviu as duas numa demonstração com as falas do roteiro de Liora e escolheu a segunda.

## Objetivos

1. Toda fala na caixa de fala toca a voz de quem fala, junto com as letras aparecendo.
2. O dono troca a voz de um NPC no F2 e ouve como ela fica antes de salvar.
3. A voz não cansa: o bipe toca a cada poucas letras, fica calado nos espaços e na pontuação, e para quando o jogador toca para completar a linha.

## Não objetivos

- Fala gravada ou sintetizada com palavras.
- Tocar o `call.wav` do Ecobeast ([creature-sounds](../creature-sounds/)).
- Uma tela de volume ou uma opção para desligar a voz.
- Outros sons de interface (botões, menus).

## Antiobjetivos

- Um bipe por letra a 60 letras por segundo, virando um zumbido.
- A voz tocar depois que a linha já está completa, ou passar por cima da próxima fala.
- Um NPC sem voz quebrar a fala ou o catálogo.

## Decisões

Tomadas com o dono do projeto:

| Decisão | Motivo |
| --- | --- |
| Uma voz por personagem, escolhida no NPC | Decisão do dono, depois de ouvir a demonstração |
| O som é um bipe de chip de videogame antigo, gerado por um script, como a música | Combina com a música retrô e não imita voz de gente nem de bicho (como os sons da [creature-sounds](../creature-sounds/)) |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão | Motivo |
| --- | --- |
| As vozes são uma tabela do catálogo (`voices`), e o NPC aponta para uma (`npcs.voice_id`) | Dados de design moram no banco ([game-data](../game-data/architecture.md)); a mesma voz serve a vários NPCs |
| O som de cada voz é um arquivo `res://assets/sounds/voices/<slug>.wav`, e o catálogo guarda o ritmo (letras por segundo, letras por bipe e a variação de altura) | O timbre fica no arquivo, como os outros sons do jogo; o ritmo se ajusta no painel do Supabase sem gerar o som de novo |
| A voz também muda a velocidade do texto | O avô falando devagar e a Mira rápido é metade da personalidade na demonstração |
| A narração e o Domador têm vozes fixas, achadas pelo slug (`narration` e `tamer`) | Eles não são NPCs; o slug é estável como os ids |
| Os Domadores NPC falam com a voz `medium` | Eles não têm NPC no catálogo, e uma voz neutra serve a todos por enquanto |
| A altura muda um pouco a cada bipe, sempre igual para a mesma letra da mesma fala | A variação tira o som de máquina, e repetir a fala soa igual |
| As vozes tocam num canal de áudio próprio (`Voices`) | Fica pronto para um volume separado, sem mexer na música |

## Fora do escopo

- O volume nas opções e desligar a voz.
- Uma voz por corpo do Domador (masculino ou feminino).
- Uma voz por Domador NPC.
- Vozes no log da luta.
- Uma fala com uma voz diferente da do NPC (um passo de cena que troca a voz).

## Fases

| Fase | Entrega | Status |
| --- | --- | --- |
| [01](01-voice-catalog.md) | As vozes no catálogo: a tabela `voices`, o `npcs.voice_id`, a rota do editor que troca a voz e a conferência no jogo | concluída |
| [02](02-voice-blips.md) | Os bipes na caixa de fala: os sons gerados, o canal `Voices`, a voz de quem fala nas cenas, nos NPCs da ilha e nos Domadores NPC | concluída |
| [03](03-voice-editor.md) | A voz no F2: escolher e ouvir a voz do NPC na ferramenta NPC | concluída |

O desenho que as fases compartilham está em [architecture.md](architecture.md).

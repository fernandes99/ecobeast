# 10. As conversas da missão

- **Status:** concluída (falta o dono conferir no F2 e no jogo)
- **Depende de:** [06-island-quests](06-island-quests.md), [07-quest-editor](07-quest-editor.md), [story](../story/), [island-npcs](../island-npcs/)

## Contexto

Hoje, falar com o NPC que dá missões mostra a fala padrão dele e, depois, as falas automáticas do servidor, com a voz da narração: "Nova missão: <título>.", "<título>: 3 de 5." e "Missão cumprida: <título>!". O dono não controla o que o NPC diz em cada momento da missão.

Em 2026-11-22, ele pediu: "quero ter um controle de diálogo quando a missão for iniciar, quando o usuário estiver fazendo a missão ainda, e um opcional de quando ele já finalizou a missão". Os exemplos dele:

- antes de começar, "um diálogo antes com o usuário, ou até mesmo uma cena antes";
- durante a missão de buscar um item, "Cadê meu item!!!" ou "Encontrou o que eu precisava?", com duas opções: no sim, "Não é isso que estou procurando, acredito que vá encontrar em X lugar"; no não, "Aaah ainda não? Já tentou procurar em X lugar";
- ao terminar, "Ah muito obrigado por ter derrotado aquele ecobeast, agora posso dormir tranquilo", e depois o NPC volta ao diálogo padrão.

Nas perguntas da fase, ele decidiu que uma opção pode recusar a missão ("Podem recusar") e escolheu as falas morando na própria missão, no banco, editadas na ferramenta Missões do F2 ("Vamos com a A"). Aprovou esta spec com "Aprovo, faça todas as fases".

## Caminhos considerados

| Caminho | Troca | Escolha |
| --- | --- | --- |
| **A.** As três conversas moram na missão, no banco, no formato das falas das cenas (fala e escolha); o início pode ser uma cena da história | Muda na hora pelo F2, sem gerar o jogo de novo, e apagar a missão apaga as falas; a cena do início não recusa | **Escolhido** pelo dono |
| **B.** Tudo vira cena da história, com gatilhos pelo estado da missão e os passos "aceitar" e "recusar" | Tem câmera, atores e Marcos em toda conversa, mas cada mudança gera o jogo de novo, cada missão vira 2 ou 3 arquivos e apagar a missão deixa cenas soltas | Descartado |

## Decisões desta fase

Do dono, em 2026-11-22:

| Decisão | Motivo |
| --- | --- |
| Cada missão tem três conversas: **início** (antes de aceitar), **durante** (aceita e ainda não cumprida) e **fim** (na entrega, opcional) | "controle de diálogo quando a missão for iniciar, quando o usuário estiver fazendo a missão ainda, e um opcional de quando ele já finalizou" |
| A conversa de início pode ser trocada por uma cena da história | "ou até mesmo uma cena antes" |
| Uma conversa tem falas e escolhas de 2 a 4 opções, e cada opção leva às próprias falas | O exemplo do "Encontrou o que eu precisava?" |
| Na conversa de início, uma opção pode recusar a missão | "Podem recusar" |
| As conversas moram na missão, no banco, e se escrevem na ferramenta Missões do F2 | "Vamos com a A" |
| Depois da entrega, o NPC volta à fala padrão | "E depois carrega o diálogo padrão do personagem" |

Escolhas de Claude (_a revisar_):

| Decisão | Motivo |
| --- | --- |
| A conversa da missão entra **no lugar** da fala padrão do NPC; sem conversa escrita para o momento, fica como hoje (a fala padrão e depois as falas automáticas) | É o "controlar o diálogo" do pedido; as missões já criadas não mudam |
| Quem fala em cada fala: o NPC (com o nome e a voz dele), o Domador ou a narração, como o `speaker` das cenas | O formato das cenas, que o dono já usa |
| As falas automáticas continuam depois da conversa: "Nova missão" ao aceitar, o progresso no fim da conversa de durante e "Missão cumprida" com a recompensa no fim da conversa de fim | O jogador vê o título, o quanto falta e o que ganhou, que o dono não precisa escrever |
| A conversa de início sem escolha que recuse aceita no fim; uma escolha nela tem, em cada opção, "Aceita", "Recusa" ou "Segue". Aceita e Recusa tocam as falas da opção e **encerram** a conversa (os passos depois da escolha não tocam); Segue toca as falas da opção e continua do passo seguinte à escolha | Uma conversa termina sempre com a missão aceita ou recusada, e o caso comum ("Pode me ajudar?", Sim ou Não) é um clique por opção; depois de "Agora não… Tudo bem, volte quando puder", o resto da conversa não faria sentido |
| Recusar não grava nada: a próxima conversa com o NPC oferece a missão de novo, com a conversa de início do começo | O jogador pode mudar de ideia; recusa guardada pediria uma tabela e uma regra de quando volta |
| As escolhas das conversas de durante e de fim só mudam as falas | Só o início decide algo (aceitar ou recusar); a entrega já é decidida pelo servidor |
| Na entrega com uma próxima missão na fila, a próxima não é mais aceita sozinha: a mesma conversa segue com o início dela (a conversa ou a cena), e o jogador aceita ou recusa | A próxima missão também pode ter conversa de início e pode ser recusada |
| A cena do início toca sem olhar os `requires` nem os `forbids` dela, com o NPC como o ator tocado; ao acabar, a missão é aceita | A missão é quem decide a hora da cena; a cena não tem como recusar (só a conversa escrita recusa) |
| As cenas ganham o gatilho novo "Pela missão" (`quest`), que nunca dispara sozinho; só elas aparecem na lista do início no F2 | Uma cena "ao entrar", "ao pisar" ou "ao tocar no NPC" tocaria também fora da missão, ou na frente dela, sem aceitar |
| Numa sala, a cena do início não toca (a sala não tem o tocador de cenas): vale a conversa de início escrita, ou a fala padrão, e a missão é aceita no fim; o F2 avisa quando o NPC da missão só está numa sala e ela tem cena | Levar o tocador de cenas para a sala é outra fase |
| Recusar fecha só a conversa da missão: depois vem a luta (se o NPC é Domador) ou a ação dele, como hoje, também quando a recusa é da próxima missão depois de uma entrega | A missão não tranca o Refúgio, a Loja nem a luta do Domador da ilha |
| As falas aceitam o `{forma masculina\|forma feminina}` das cenas | O dono já escreve assim nas cenas |
| Uma fala com linha em branco vira uma caixa por parágrafo, com o mesmo nome e a mesma voz, como a fala padrão do NPC e a das peças (`MapNpc.paragraphs`) | O dono escreveu três parágrafos numa fala e eles apareciam todos numa caixa só ("Deveria ta quebrando por paragrafo") |
| Até 3 níveis de escolha dentro de escolha, até 40 passos por conversa contando as opções, cada fala de 1 a 300 caracteres e cada opção de 1 a 40 | Os limites seguram a tela da caixa de fala e o formulário do F2 |
| As conversas se salvam com a missão, no mesmo Salvar da ferramenta Missões | É parte da missão, como o tipo e a recompensa |
| As conversas valem também dentro das salas (interiores) | O NPC que dá missão pode estar numa sala, como na [06](06-island-quests.md) |
| No F2, a aba Início mostra a lista das cenas e, embaixo, a conversa escrita, as duas juntas, em vez de uma escolha entre "Conversa" e "Cena" | Numa sala a cena não toca e vale a conversa escrita, então as duas podem ser preenchidas |
| Numa ilha, a conversa com o NPC passou a perguntar ao servidor antes da fala padrão (o `QuestConversation`), e não mais depois dela | Só assim a conversa da missão entra no lugar da fala padrão |

## Como fica a conversa no jogo

Ao tocar num NPC que dá missões numa ilha (fora ou numa sala), sem cena da história presa ao toque dele (a cena da história continua vindo antes de tudo):

1. O jogo pergunta ao servidor em que ponto está a primeira missão não entregue do NPC (a conversa já cumpre as "Fale com" ele, como hoje).
2. **Nenhuma missão a dar:** a fala padrão, como hoje.
3. **Oferecer:** a conversa de início (ou a cena). Aceitou: o servidor aceita e vem "Nova missão: <título>.". Recusou: fecha a conversa, sem nada gravado. Sem conversa de início nem cena: a fala padrão e a missão aceita no fim, como hoje.
4. **Em andamento:** a conversa de durante e depois "<título>: 3 de 5.". Sem ela: a fala padrão e o progresso, como hoje.
5. **Cumprida:** o servidor entrega; vem a conversa de fim, "Missão cumprida: <título>!" e a recompensa. Se há uma próxima missão na fila, a conversa segue para o passo 3 com ela. Sem conversa de fim: a fala padrão antes, como hoje.
6. Depois, a luta (se o NPC é Domador) ou a ação dele, como hoje.

Exemplo de uma conversa de durante:

```
NPC: Encontrou o que eu precisava?
Escolha
  ├─ "Sim"  → NPC: Não é isso que estou procurando. Acho que vai encontrar perto do Farol.
  └─ "Ainda não" → NPC: Aaah, ainda não? Já tentou procurar perto do Farol?
(automática) Encontre 2 Tônico Leve: 0 de 2.
```

## Escopo

- O banco: as tabelas das conversas (os passos e as opções) e a cena do início na missão.
- As regras puras: conferir uma conversa (os limites, a recusa só no início) e passar da árvore às linhas e de volta.
- O servidor: as conversas nas rotas do editor de missões, a conversa com o NPC respondendo o momento e a conversa dele, sem aceitar sozinha, e a rota de aceitar.
- O F2: a parte Conversas no formulário da ferramenta Missões, com Início, Durante e Fim, e a lista das cenas da ilha para o início.
- O jogo: tocar a conversa da missão em Explorar e nas salas, com as escolhas, a recusa, a cena do início (só em Explorar) e as falas automáticas.
- A história: o gatilho "Pela missão" das cenas.

## Onde ficou

- O banco: a migration `20270217000000_quest_dialogues` (as tabelas `quest_dialogue_steps` e `quest_dialogue_options`, com os CHECKs da faixa de cada coluna, e `quests.offer_scene`, com o CHECK `^[a-z0-9_]{1,64}$`).
- As regras puras em `server/src/domain/quests/quest-dialogue.ts`: `parseDialogues` (lê o que o editor manda, sem confiar no formato, e confere os limites, com as mensagens em pt-BR), `parseOfferScene`, `dialogueWrites` (a árvore em linhas) e `dialoguesFromRows` (as linhas em árvore), com os testes em `quest-dialogue.spec.ts`.
- O editor: `QuestsEditorService` lê e grava `dialogues` e `offer_scene`, trocando os passos inteiros numa transação (as opções levam as respostas aninhadas).
- A conversa: `QuestsService.talk` responde `stage`, `quest_id`, `dialogue`, `offer_scene` e `next`, sem aceitar nem a oferecida nem a próxima da fila depois da entrega; `QuestsService.acceptQuest`, na rota `POST /v1/me/quests/accept`, aceita só a primeira não entregue do NPC (`QUEST_NOT_NEXT`, 409; `QUEST_NOT_FOUND`, 404).
- O jogo: o `QuestTalk` ganhou o momento, a conversa e a próxima; `GameService.accept_quest` e `Session.accept_quest`; o `QuestConversation` (`client/screens/exploration/quest_conversation.gd`) toca a conversa inteira (a fala padrão, a conversa escrita, uma caixa por parágrafo de cada fala, as escolhas pelo `StoryChoicePanel`, a recusa, a aceitação e as falas automáticas), usado pela `ExplorationScreen._converse` (com a cena do início pelo `_quest_scene`, que toca a cena achada por `Story.library.find` sem olhar as condições) e pela `InteriorScreen._talk`, que ganhou as opções em cima da caixa de fala. No mapa sorteado, a fala padrão continua como antes.
- A história: o gatilho `quest` no `StoryValidator.TRIGGERS` e "Pela missão" na ferramenta Cenas; o `Story` não o dispara sozinho, porque só procura `auto`, `npc` e `area`. A Linha da história não mostra gatilhos e não mudou.
- O F2: o `QuestDialogueEditor` (`client/tools/map_editor/quest_dialogue_editor.gd`), no fim do formulário da ferramenta Missões, com as abas, "+ Fala", "+ Escolha" (até 3 uma dentro da outra), "+ Opção" (2 a 4), Aceita, Recusa ou Segue no Início, ↑, ↓ e ✕, a lista das cenas "Pela missão" da ilha e o aviso do NPC só numa sala.
- Os testes: `quest-dialogue.spec.ts`, as conversas no e2e `quests-editor.e2e-spec.ts`, a oferta, a aceitação e a próxima da fila em `island-quests.e2e-spec.ts`, e a aceitação em `ground-items.e2e-spec.ts`. As escolhas e a recusa do `QuestConversation` foram conferidas sem janela, e o editor numa foto: falta o dono abrir o F2 e o jogo.

## Fora do escopo

- Contas no texto, como "{progresso}" ou "{alvo}" (o progresso continua na fala automática).
- Uma escolha que faz outra coisa além de aceitar ou recusar (dar item, ligar Marco, abrir luta).
- A cena da história na conversa de durante ou de fim, e a cena dentro das salas.
- Guardar a recusa ou contar quantas vezes o jogador recusou.
- Câmera e atores que andam numa conversa escrita (é o que a cena faz).

## Os dados

`quest_dialogue_steps`: `id`, `quest_id` (apaga junto), `stage` (1 início, 2 durante, 3 fim), `option_id` (nulo no primeiro nível; senão a opção de quem a fala é a resposta, apaga junto), `position` (a ordem, de 1 em diante, única por missão, conversa e opção), `kind` (1 fala, 2 escolha), `speaker` (1 NPC, 2 Domador, 3 narração; só na fala) e `text` (só na fala, 1 a 300 caracteres).

`quest_dialogue_options`: `id`, `step_id` (a escolha, apaga junto), `position` (de 1 a 4), `text` (1 a 40 caracteres) e `outcome` (nulo, 1 aceita ou 2 recusa; só nas escolhas do início).

`quests.offer_scene`: o `slug` de uma cena da história (`^[a-z0-9_]+$`), opcional. Com ela, a conversa de início escrita é ignorada pelo jogo, e o F2 mostra uma ou outra.

Nas rotas, a conversa vai como árvore, em `snake_case`:

```json
{
  "dialogues": {
    "offer": [
      { "type": "say", "speaker": "npc", "text": "Pode me ajudar?" },
      { "type": "choice", "options": [
        { "text": "Claro", "outcome": "accept", "steps": [] },
        { "text": "Agora não", "outcome": "decline",
          "steps": [{ "type": "say", "speaker": "npc", "text": "Tudo bem, volte quando puder." }] }
      ]}
    ],
    "ongoing": [],
    "done": []
  },
  "offer_scene": null
}
```

## Requisitos

- **RF-01:** as rotas do editor de missões (ler, criar e salvar) leem e gravam `dialogues` e `offer_scene`. Salvar troca as conversas inteiras numa transação e recusa, com a mensagem em pt-BR: uma fala vazia ou com mais de 300 caracteres, uma escolha com menos de 2 ou mais de 4 opções, uma opção vazia ou com mais de 40, mais de 3 níveis de escolha, mais de 40 passos numa conversa, um `outcome` fora da conversa de início e um `offer_scene` com caracteres fora de `[a-z0-9_]`.
- **RF-02:** `POST /v1/me/quests/talk` com `npc_id`, nas mesmas condições de hoje (numa ilha, com o NPC posto), cumpre as "Fale com" ele e responde `stage` (`none`, `offer`, `ongoing` ou `done`), `quest_id`, `dialogue` (a árvore da conversa daquele momento, vazia se não há), `offer_scene`, `lines` (as falas automáticas), `reward`, `tamer_progress`, `island_unlocked`, `quest_places` e, no `done` com uma próxima missão, `next` com `quest_id`, `dialogue` e `offer_scene` do início dela. No `offer`, **não aceita**. No `done`, entrega como hoje, sem aceitar a próxima.
- **RF-03:** `POST /v1/me/quests/accept` com `quest_id` aceita a missão se ela é a primeira não entregue do NPC dela nesta ilha, com o NPC posto, e responde `lines` ("Nova missão: <título>.") e `quest_places`. Uma missão que não é a da vez dá 409, e uma já aceita responde sem mudar nada.
- **RF-04:** no jogo, a conversa segue [Como fica a conversa no jogo](#como-fica-a-conversa-no-jogo): as falas do NPC com o nome e a voz dele, as do Domador com a voz do Domador, a narração com a voz da narração, as escolhas pelos botões das cenas, a recusa fechando a conversa sem chamar o servidor e a aceitação chamando o RF-03. Igual em Explorar e nas salas.
- **RF-05:** as cenas ganham o gatilho "Pela missão" (`quest`, no `StoryValidator` e na ferramenta Cenas), que o `Story` nunca dispara sozinho. Em Explorar, a cena do início toca pelo `StoryPlayer`, com o NPC como o ator tocado, sem olhar os `requires` nem os `forbids` dela, e aceita a missão ao acabar. Numa sala, ou com uma cena que não existe no jogo, ela é ignorada, e vale a conversa de início escrita (ou a fala padrão).
- **RF-06:** no F2, o formulário da ferramenta Missões ganha a parte Conversas, com as abas Início, Durante e Fim. Cada aba tem a lista dos passos, com "+ Fala" (quem fala e o texto) e "+ Escolha" (2 a 4 opções, cada uma com o texto, as falas dela e, no Início, Aceita, Recusa ou Segue), subir, descer e tirar. O Início tem a lista das cenas da ilha de gatilho "Pela missão" ("Nenhuma" usa a conversa) em cima da conversa escrita, e o aviso quando o NPC só está numa sala. O Salvar manda tudo, e o erro do servidor aparece como hoje.
- **RF-07:** recusar fecha a conversa da missão e segue para a luta ou a ação do NPC, como depois de qualquer conversa.

## Critérios de aceite

- [ ] No F2, escrever uma conversa de início com "Claro" e "Agora não", uma de durante com uma escolha e uma de fim, salvar e reabrir igual.
- [ ] No jogo, recusar não aceita, e falar de novo oferece de novo; aceitar mostra "Nova missão".
- [ ] Durante, cada opção leva à resposta dela, e o progresso vem depois.
- [ ] Na entrega, a conversa de fim, "Missão cumprida" e a recompensa; a próxima missão da fila vem com a conversa de início dela.
- [ ] Uma missão com cena no início toca a cena e fica aceita.
- [ ] Uma missão sem conversas fica como hoje.

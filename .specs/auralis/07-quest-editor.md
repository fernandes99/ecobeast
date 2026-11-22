# 07. A ferramenta Missões do F2

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [06-island-quests](06-island-quests.md), [map-editor](../map-editor/), [island-npcs](../island-npcs/)

## Contexto

A [06](06-island-quests.md) deixou as missões como linhas em `quests`, criadas pelo painel do Supabase. Em 2026-11-22, depois de ver as receitas em SQL, o dono pediu: "vamos para as próximas fases, termine até deixar essa configuração no F2". Esta fase põe a criação das missões no editor de ilhas, ao lado do NPC, sem SQL e sem procurar ids.

## Decisões desta fase

| Decisão | Motivo |
| --- | --- |
| A ferramenta Missões entra no grupo Jogo do F2, depois de NPC e antes de Cenas | As missões são presas aos NPCs da ilha; o grupo Jogo já tem as ferramentas que mexem no jogo |
| As missões se salvam na hora, pelas rotas `/v1/editor`, fora do rascunho da ilha, do Salvar e do desfazer | O progresso dos jogadores aponta para o id da missão; publicar a ilha não deve apagar nem recriar missões |
| A ilha precisa estar salva (ter id) para ganhar missões | A missão guarda o `island_id` |
| Cada rota de escrita devolve a lista inteira da ilha | O painel redesenha tudo de uma vez, sem conta no cliente |
| A missão nova entra no fim da fila do NPC que dá; trocar o NPC de uma missão a põe no fim da fila do novo; ↑ e ↓ trocam a ordem com a vizinha da mesma fila | A ordem é a da fila (`position`), e o dono não digita números |
| O servidor limpa os parâmetros que o tipo não usa e confere os que ele pede, com as mensagens em pt-BR, antes do CHECK do banco | O formulário pode guardar campos de outro tipo; o erro do banco não diz o que falta |
| O "Derrote o NPC X" só aceita um NPC que é Domador desta ilha (`tamers`) | Sem isso, a missão nunca se cumpre |
| Os hexágonos do "Vá até" se escolhem no mapa pelo "Escolher no mapa", um clique põe ou tira, como a área da ferramenta Cenas, e precisam existir no rascunho da ilha | O dono vê o lugar em vez de digitar `q` e `r` |
| A lista mostra o título pronto que o jogador vê (`display_title`), montado pelo servidor | O cliente não repete a regra do título |
| O número de missões pedidas para abrir a próxima ilha (`islands.required_quests`) fica no topo do painel, com 0 valendo "todas" | O mesmo número da regra da ilha completa |
| A lista da ferramenta NPC mostra a figura de cada NPC (o Ecobeast pelo primeiro quadro parado, a pessoa vestida com a aparência dela), os selos "No mapa" (com ×N quando ele está mais de uma vez) e "N missões", a busca, e os NPCs desta ilha num grupo em cima dos outros | Pedido do dono em 2026-11-22: o ícone de pessoa era igual para todos, e não dava para saber quem já estava na ilha |
| O NPC escolhido no mapa mostra, logo abaixo do nome, as missões que ele dá, e cada uma, como o "+ Nova missão", abre a ferramenta Missões já nela (ou com ele como quem dá) | O dono vê e mexe nas missões de um NPC sem procurar na lista da ilha |
| Escolher na lista um NPC que já está na ilha escolhe também o primeiro dele no mapa; um que não está desescolhe o do mapa | A lista vira o atalho para achar o NPC posto; clicar no mapa continua pondo o NPC da lista |

## Escopo

- As rotas do editor: ler as missões de uma ilha, criar, salvar, apagar, subir ou descer na fila e mudar o `required_quests`.
- A ferramenta Missões no F2: o painel com a lista por NPC, o formulário, o "Escolher no mapa" do "Vá até" e os hexágonos do lugar desenhados no mapa.

## Fora do escopo

- Ver o progresso dos jogadores no F2.
- Desfazer uma missão apagada (ela some com o progresso de quem a aceitou).
- As missões extras ([08](README.md#fases)) e os itens no chão ([09](README.md#fases)).

## Onde ficou

- A conferência pura da missão do editor em `server/src/domain/quests/quest-input.ts` (`checkQuestDraft`, com as mensagens em `QUEST_INPUT_ERRORS`): os parâmetros de cada tipo, os limites e a limpeza do que o tipo não usa (o texto vazio vira nulo, os hexágonos repetidos saem, o item sem quantidade vale 1).
- As rotas em `server/src/editor/quests-editor.controller.ts` e o `QuestsEditorService`, que confere no banco o NPC, o alvo (Domador desta ilha no tipo 9), a espécie, o item e os hexágonos do rascunho, e troca a posição na fila por uma posição de sobra, por causa do índice único (`island_id`, `npc_id`, `position`).
- No F2: o `QuestPanel` (`client/tools/map_editor/quest_panel.gd`), a ferramenta `EditorTools.Tool.QUESTS` no grupo Jogo (com o ícone `icons/quest.svg`), as rotas no `EditorApi` (`list_quests`, `create_quest`, `save_quest`, `delete_quest`, `move_quest` e `set_required_quests`) e os hexágonos do lugar pelo `scene_marks` do `EditorCanvas`, o mesmo da ferramenta Cenas. A lista carrega quando a ferramenta aparece com uma ilha salva, e o NPC que dá lista primeiro os postos no mapa e, depois de um separador, os outros (os das salas). Apagar pede um segundo clique.
- A barra de baixo do F2 já mostrava o `(q, r)` do hexágono sob o mouse.
- A lista da ferramenta NPC: cada linha é um `NpcListRow` (`client/tools/map_editor/npc_list_row.gd`), com a figura (a pessoa é um `TamerSprite` parado no primeiro quadro), o nome, a descrição numa linha e os selos; o `NpcPanel` põe o NPC escolhido no topo, com as missões dele, e embaixo a busca e os grupos "Nesta ilha" e "Outros NPCs". As missões vêm do `QuestPanel`, que carrega a lista da ilha também com a ferramenta escondida (`ensure_loaded`, `quests_of`, o sinal `quests_changed`) e abre uma missão vinda do painel NPC (`open_for`, pelo `EditorTools._open_quest`).
- Os testes: `server/src/domain/quests/quest-input.spec.ts` e o e2e `server/test/quests-editor.e2e-spec.ts`. O painel foi conferido sem janela, com a resposta do servidor de mentira: falta o dono abrir no F2.

## Requisitos

- **RF-01:** `GET /v1/editor/islands/:id/quests` responde `required_quests` (nulo pede todas), `types` (os 9 de `quest_types`: `id`, `slug`, `name`, `description`) e `quests`, em ordem de NPC e de `position`, cada uma com `id`, `npc_id`, `position`, `quest_type_id`, `amount`, `species_id`, `target_npc_id`, `place_name`, `title`, `coins`, `item_id`, `item_quantity`, `counts_for_unlock`, `tiles` e `display_title`. Ilha sem linha em `islands` dá 404.
- **RF-02:** `POST /v1/editor/islands/:id/quests` cria a missão no fim da fila do `npc_id` e responde a lista (RF-01) com 201. O corpo tem `npc_id`, `quest_type_id`, os parâmetros, `title`, `coins`, `item_id`, `item_quantity`, `counts_for_unlock` e `tiles`.
- **RF-03:** `PUT /v1/editor/quests/:id` troca tudo da missão, menos a ilha. A posição fica, se o NPC é o mesmo; com outro NPC, a missão vai para o fim da fila dele. Responde a lista.
- **RF-04:** `DELETE /v1/editor/quests/:id` apaga a missão (e o progresso dela) e responde a lista. `POST /v1/editor/quests/:id/move` com `direction` `up` ou `down` troca a posição com a vizinha da mesma fila; na ponta, não muda nada.
- **RF-05:** `PUT /v1/editor/islands/:id/required-quests` com `required_quests` (nulo ou maior que 0) responde a lista.
- **RF-06:** a conferência, com 400 e a mensagem: o tipo de 1 a 9; o NPC que dá existe; nos tipos 1, 2 e 6, `amount` maior que 0; no 3, de 1 a 100; no 4, `place_name` de 1 a 40 caracteres e de 1 a 50 hexágonos, todos no rascunho da ilha; nos 5 e 9, o NPC alvo existe, e no 9 é Domador desta ilha; nos 7 e 8, a espécie existe, e o `amount` é nulo ou maior que 0; o título até 60 caracteres; `coins` de 0 a 1.000.000; o item existe, com a quantidade de 1 a 99. Os parâmetros que o tipo não usa ficam nulos, e os hexágonos só ficam no tipo 4.
- **RF-07:** no F2, a ferramenta Missões (grupo Jogo) mostra, com a ilha salva, o campo das missões pedidas para abrir a próxima ilha, a lista por NPC (nome, número na fila e título pronto, com ↑ e ↓) e o botão Nova missão; escolher uma abre o formulário com os campos do tipo (Quantidade, Porcentagem ou Minutos; Espécie; NPC alvo; Nome do lugar com "Escolher no mapa" e o número de hexágonos), o título opcional, as moedas, o item e a quantidade, "Conta para abrir a próxima ilha", Salvar, Apagar e Cancelar. Sem a ilha salva, só o aviso.
- **RF-08:** com o "Escolher no mapa" ligado, um clique no mapa põe ou tira o hexágono do lugar; o botão direito ou Esc desligam. Os hexágonos do lugar da missão aberta aparecem marcados no mapa enquanto a ferramenta está aberta.
- **RF-09:** na ferramenta NPC, a lista mostra a figura de cada NPC, o nome, a descrição, o selo "No mapa" (×N com mais de um) e, com a ilha salva, o selo das missões que ele dá; a busca filtra pelo nome e pela descrição, e os NPCs desta ilha ficam no grupo "Nesta ilha", em cima de "Outros NPCs". O NPC escolhido mostra as missões dele (número na fila e título pronto) e o "+ Nova missão"; tocar numa abre a ferramenta Missões nela, e o "+ Nova missão" abre a missão nova com ele como quem dá.

## Critérios de aceite

- [ ] No F2, criar uma missão de cada tipo, salvar e vê-la na lista com o título pronto.
- [ ] Trocar a ordem com ↑ e ↓ e o NPC que dá, e ver a fila certa.
- [ ] Um "Vá até" com os hexágonos escolhidos no mapa funciona no jogo.
- [ ] Um campo que falta mostra a mensagem do servidor na barra de baixo, sem salvar.
- [ ] Na ferramenta NPC, cada NPC aparece com a figura dele, os da ilha em cima com "No mapa", e o NPC escolhido mostra as missões que dá.

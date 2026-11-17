# 03. A voz no F2

- **Status:** concluída
- **Depende de:** [01](01-voice-catalog.md), [02](02-voice-blips.md)

## Contexto

A voz de um NPC mora no catálogo ([01](01-voice-catalog.md)) e toca na caixa de fala ([02](02-voice-blips.md)). O dono escolhe as vozes no F2, onde já põe os NPCs na ilha e veste os NPCs pessoa pelo botão Aparência da ferramenta NPC ([liora-intro/02](../liora-intro/02-person-npcs.md)). Esta fase põe ali a escolha da voz, com um botão para ouvir.

## Escopo

- O campo Voz e o botão Ouvir na ferramenta NPC.
- Salvar a voz pela rota da [01](01-voice-catalog.md).

## Fora do escopo

- Criar ou mudar vozes no F2. Elas se ajustam no painel do Supabase, e o timbre se muda no `make_voices.py`.
- A voz na janela de conteúdo (F1).

## Requisitos

- **RF-01:** Na ferramenta NPC do F2, com um NPC escolhido, entra uma linha **Voz**: uma lista com as vozes do catálogo, pelo `name`, na ordem do `id`, com a voz do NPC marcada. Ao lado, o botão **Ouvir**, com o ícone de tocar.
- **RF-02:** O Ouvir toca, numa caixa de fala pequena na própria ferramenta, a primeira fala do diálogo do NPC na ilha, ou "Olá! Tudo bem por aqui?" quando ele não tem diálogo. A fala usa a voz marcada na lista, mesmo antes de salvar.
- **RF-03:** Trocar a voz na lista chama `EditorApi.set_npc_voice(npc_id, voice_id)`, que usa o `PUT /v1/editor/npcs/:id/voice`. Se der certo, atualiza o NPC no `GameData` sem baixar o catálogo de novo; se falhar, a lista volta para a voz de antes e a mensagem de erro aparece na barra do F2, como nas outras rotas do editor.
- **RF-04:** A voz é do NPC do catálogo, não do NPC na ilha. O F2 avisa isso embaixo da lista: "A voz vale para este NPC em todas as ilhas.".

## Critérios de aceite

- [x] Escolher o avô na ferramenta NPC mostra Grave marcada.
- [x] Ouvir toca a primeira fala dele com a voz grave; trocar a lista para Aguda e ouvir de novo já toca aguda.
- [ ] Trocar a voz e fechar o F2 deixa a voz nova nas cenas, sem reabrir o jogo.
- [ ] Com a API desligada, trocar a voz devolve a lista para a de antes e mostra o erro.
- [x] O script da ferramenta NPC compila (`load(...).can_instantiate()`).

## Desenho técnico

- **Alterar:**
  - `client/tools/map_editor/npc_panel.gd` (a linha Voz, o Ouvir e a caixa de fala pequena)
  - `client/tools/map_editor/editor_api.gd` (`set_npc_voice`)
  - `client/core/autoload/game_data.gd`, se precisar de um jeito de trocar o `voice_id` de um NPC já carregado
- **Reutilizar:** o `TamerGreetingPanel` da [02](02-voice-blips.md), para a fala do Ouvir soar igual à do jogo.

## Notas da implementação

- O Ouvir usa o ícone `tools/map_editor/icons/play.svg`. Tocar na caixa de fala pequena a fecha, e trocar o NPC escolhido também.
- A mensagem de sucesso ou de erro vai para a barra do F2 pelo sinal `NpcPanel.message`.
- O erro foi conferido com uma voz que não existe (400): a lista volta e a mensagem aparece. Falta conferir com a API desligada.

## Verificação

- `godot --headless --path client --quit-after 30`, e o `can_instantiate()` do `npc_panel.gd` numa cena temporária fora de `client/zz_tmp_check`.
- F2: os critérios acima, com a API local.

## Tarefas

- [x] A linha Voz e o Ouvir.
- [x] Salvar pela rota e atualizar o `GameData`.
- [x] O `client/CLAUDE.md`, o README e as tabelas das specs.

# 02. A ferramenta NPC no editor

- **Status:** concluída
- **Depende de:** [01-npc-records](01-npc-records.md), [map-editor/06](../map-editor/06-tool-groups.md)

## Contexto

Com a [01](01-npc-records.md), o rascunho guarda os NPCs. Esta fase dá ao editor a ferramenta para pô-los, no grupo Jogo, ao lado de Chegada, Ação e Área. O esboço aprovado pelo dono: a lista dos NPCs do catálogo, e, para o NPC escolhido no mapa, Passeia ou Parado, os hexágonos do passeio, o diálogo e a ação.

## Escopo

- A ferramenta NPC (ícone `npc`), com o `NpcPanel`.
- Os NPCs desenhados no mapa do editor, parados, com as folhas de explorar.
- Desfazer e refazer.

## Fora do escopo

- O passeio animado no editor (ele aparece só no jogo).
- Cadastrar NPCs no editor: o catálogo se edita no Supabase.

## Requisitos

- **RF-01:** O painel lista os NPCs do catálogo, cada um com o primeiro quadro da folha de explorar parada (de frente, ampliado), o nome e a descrição. Um NPC sem as folhas aparece desligado.
- **RF-02:** Clique num hexágono sem NPC põe o NPC escolhido na lista, como Passeia, sem diálogo nem ação, e o escolhe. Clique num hexágono com NPC escolhe o de lá. Botão direito escolhe o NPC do hexágono, ou nenhum.
- **RF-03:** O NPC escolhido tem o contorno do hexágono dele e o dos hexágonos do passeio, em outra cor, e o painel mostra:
  - o nome e o hexágono;
  - Passeia ou Parado;
  - "Marcar passeio": ligado, cada clique num hexágono da ilha o põe ou tira do passeio (o do próprio NPC não sai);
  - o diálogo, um campo de texto de várias linhas, com a dica "Cada parágrafo é uma fala";
  - a ação: "Sem ação" ou um tipo de `action_types`;
  - "Apagar NPC" (também a tecla Delete).
- **RF-04:** Cada mudança vira um passo de desfazer; as letras seguidas do diálogo viram um passo só.
- **RF-05:** Tirar um hexágono da ilha apaga o NPC que nasce nele e o tira dos passeios.
- **RF-06:** Digitar no diálogo não dispara os atalhos do editor.

## Critérios de aceite

- [x] O NPC aparece na lista com a figura, e posto no mapa, parado, no hexágono.
- [x] Marcar o passeio, escrever o diálogo e escolher a ação, salvar e abrir de novo: tudo volta igual.
- [x] Ctrl+Z desfaz pôr, apagar, o passeio e o diálogo.

## Desenho técnico

- `tools/map_editor/npc_panel.gd` (novo, `NpcPanel`).
- `island_draft.gd`: `npcs` (como o servidor manda), `npc_at`, `npc_tiles`, `map_npcs()`, e o `remove_tile`.
- `editor_history.gd`: `npcs_before` e `npcs_after`.
- `editor_tools.gd`: `Tool.NPC`, no grupo Jogo, e `_paint_npc`.
- `editor_canvas.gd`: `refresh_npcs()`, que põe um `NpcSprite` parado por NPC, e o contorno do escolhido.
- `map_editor.gd`: os `refresh_npcs` e a tecla Delete.
- `tools/map_editor/icons/npc.svg`.

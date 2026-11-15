# 03. A ferramenta Ponte

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [02-bridge-drawing](02-bridge-drawing.md) e [free-fences/03](../free-fences/03-fence-tool.md)

## Contexto

O dono desenha as pontes no editor como desenha as cercas.

## Escopo

- A ferramenta Ponte, no grupo Peças, depois de Cerca, com o painel dos estilos.

## Requisitos

- **RF-01:** Com a ferramenta Ponte:
  - o primeiro clique põe uma ponta, e a prévia segue o mouse;
  - o segundo clique põe a outra ponta e termina a ponte;
  - Esc ou o botão direito desistem;
  - uma ponta na água, fora dos hexágonos editáveis ou a menos de 16 px da outra não entra, e a barra de status diz por quê.
- **RF-02:** Um clique perto do corredor de uma ponte a escolhe. Com uma escolhida, o painel troca o estilo dela, e Delete a apaga.
- **RF-03:** Cada ponte feita, trocada ou apagada é um passo do desfazer (`EditorHistory`).
- **RF-04:** O salvar manda as pontes, e uma recusa do servidor aparece como hoje.

## Critérios de aceite

- [ ] Sem janela, desenhar, trocar o estilo, apagar e desfazer uma ponte deixa o `IslandDraft` como esperado.
- [ ] No editor (F2), o dono desenha pontes em vários ângulos, salva e abre de novo.

## Desenho técnico

**Criar:**
- `client/tools/map_editor/bridge_panel.gd` e o ícone `icons/bridge.svg`.

**Alterar:**
- `client/tools/map_editor/editor_tools.gd`, `editor_canvas.gd`, `editor_history.gd` e `map_editor.gd`.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

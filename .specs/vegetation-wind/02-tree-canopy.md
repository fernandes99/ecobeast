# 02. Os pixels da copa no vento

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [01-pack-sway](01-pack-sway.md)

## Contexto

A copa por partes ficou ruim e saiu ([README](README.md#decisões)). Depois o dono pediu "3 animações nas árvores e só a parte de cima", e Claude fez 3 quadros com o topo andando 1 px. Vendo o GIF, ele mostrou o vento das árvores do jogo Taiji e perguntou: "consegue mudar aleatoriamente cada pixel?".

Na referência, cada pixel da copa pega a cor de um vizinho próximo, por um ruído que corre com o vento. A folhagem se mexe em grupinhos de pixels, e o tronco fica parado. Na primeira versão, com grupos de 3 px e muitos pixels mexendo, o dono achou que "perdeu muita qualidade" e pediu mais suave.

## Escopo

- O shader do vento distorce, pixel a pixel, a copa das árvores dos pacotes.
- A base da copa de cada arte, calculada pelo jogo.

## Requisitos

- **RF-01:** Valem os 11 tipos de árvore (28 a 38), em todas as variantes (`HexMapView.TREE_CANOPY`).
- **RF-02:** `TreeCanopy.base_of` acha a base da copa: a linha mais baixa com pelo menos 60% da largura máxima da árvore, sem entrar nos 12% de baixo da arte.
- **RF-03:** No shader, um pixel da base da copa para cima pode mostrar a cor do vizinho 1 px para o lado. Só uma parte pequena da copa se mexe por vez, para o desenho não se perder:
  - o vizinho vem de um ruído em grupos de uns 5 px (`clump`), que corre na direção do vento (`flow_speed`) e muda devagar (`churn`);
  - o pixel só anda quando o ruído passa de um limite, que a rajada do bioma baixa (`reach` 0,8). Para cima e para baixo ele quase não anda (`vertical` 0,5);
  - nas 4 linhas logo acima da base, o empurrão cresce de 0 até o máximo, para o tronco não se soltar.
- **RF-04:** O tronco e a sombra não se mexem. A malha tem 1 px de folga em volta, e o que cai fora da arte fica transparente.
- **RF-05:** A árvore espelhada recebe o vento do mesmo lado que as outras.

## Critérios de aceite

- [x] Um GIF desenhado pelo jogo mostra os pixels da copa mexendo em grupos, com o tronco parado.
- [ ] No jogo (F5) e no editor (F2), as árvores se mexem assim.

## Desenho técnico

**Criar:**
- `client/ui/components/tree_canopy.gd` (`TreeCanopy`).

**Alterar:**
- `client/ui/components/hex_map_view.gd`: `TREE_CANOPY` e `_add_tree_props`.
- `client/ui/components/plant_wind.gdshader`: o modo da copa, ligado pelo `CUSTOM1`, com o ruído.

## Verificação

```bash
godot --headless --path client --quit-after 30
```

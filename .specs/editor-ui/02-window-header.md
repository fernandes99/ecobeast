# 02. O topo e a barra de baixo

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [map-editor/05](../map-editor/05-editor-ux.md)

## Contexto

Na janela padrão do F2, de 1600 px, o topo passa da borda: o Salvar sai cortado, e o Publicar e a "Casa do jogador" somem. A mensagem do editor (salvo, erro, aviso) fica no topo, espremida, e a dica fixa da barra de baixo é cortada ([README](README.md#contexto)).

## Escopo

- O topo e a barra de baixo do `MapEditor`.

## Requisitos

- **RF-01:** O topo tem, da esquerda para a direita:
  - o nome da ilha, com 220 px, e um espaço que cresce;
  - Ilhas, com o ícone e o texto;
  - Linha da história, Interiores, Altura e Camadas, só com o ícone e a dica do mouse, que diz o nome e o que o botão faz;
  - desfazer e refazer, como hoje;
  - Salvar, com a dica "Ctrl+S", Publicar e "Casa do jogador".
- **RF-02:** O botão Altura fica marcado enquanto o corte de altura está ligado, e a dica diz se a vista mostra tudo ou até a altura 4.
- **RF-03:** No tamanho mínimo da janela (1280 px) e no padrão (1600 px), todos os botões do topo cabem inteiros.
- **RF-04:** A barra de baixo mostra, à esquerda, o hexágono sob o mouse (como hoje) ou, fora do mapa, uma linha curta com os atalhos ("Roda: zoom · Botão do meio ou Espaço: arrastar · Tab: visão de cima · Ctrl+Z / Ctrl+Y: desfazer e refazer"); depois, a mensagem do editor, na cor de erro quando é erro; e, no canto direito, em negrito, a situação da ilha ("Publicada, com mudanças"). A situação saiu do topo porque, em 1280 px, ela virava "Pub".

## Critérios de aceite

- [x] Na janela de 1280 px e na de 1600 px, o Salvar, o Publicar e a "Casa do jogador" aparecem inteiros.
- [ ] Salvar mostra a mensagem na barra de baixo.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script.

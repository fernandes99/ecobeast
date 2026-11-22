# 06. O rosto, os Elementos e as setas na lista

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [01-viewer-window](01-viewer-window.md) (o par lista e detalhe) e [creature-faces](../creature-faces/README.md) (o `CreatureFace`)

## Contexto

Em 2026-11-22, com 42 Ecobeasts na lista, o dono pediu: "Quero que mostre o avatar delas na lista e uma flag dos tipos de cada um. Além disso quero mudar um por uma pelas setas do teclado."

## Escopo

- Na aba Ecobeasts, cada linha com o rosto e os Elementos.
- Em toda aba com lista, as setas para cima e para baixo escolhem o item de cima ou de baixo.

## Fora do escopo

- Busca e filtros na lista.
- As setas para os lados (continuam com a barra de abas, quando ela tem o foco).

## Requisitos

- **RF-01:** A linha do Ecobeast tem 46 px de altura: à esquerda, o rosto (`CreatureFace.set_species`, 36 px, sem anel de HP, com o `front.png` quando falta o `face.png`); no meio, "#N Nome" e, embaixo, uma etiqueta pequena por Elemento, com o nome na cor do Elemento (texto escuro sobre as cores claras, como o `ElementBadge`); à direita, a contagem de arquivos de antes ("3/7").
- **RF-02:** Com a janela F1 em foco, ↓ escolhe o item de baixo da lista da aba aberta e ↑ o de cima, sem dar a volta nas pontas; segurar a tecla repete. A lista rola até a linha escolhida ficar à vista, o que vale também ao abrir um item por um link de outra aba.
- **RF-03:** As setas não fazem nada com o foco num campo de texto (o formulário da Técnica) nem quando o detalhe mostra outra coisa que não um item da lista (`show_custom`, como o formulário de uma Técnica nova), para não sair do formulário sem querer.

## Critérios de aceite

- [ ] Com F1, a aba Ecobeasts mostra o rosto e os Elementos de cada um; o Noclume tem Sombra e Psíquico.
- [ ] ↓ e ↑ passam de um Ecobeast para o outro, e a lista acompanha até o fim.
- [ ] Na aba Técnicas, com o formulário aberto, as setas mexem só no campo de texto.

## Desenho técnico

**Alterar:**

- `res://tools/content_viewer/list_detail.gd`: `Row.lead` (um controle antes do texto), `Row.below` (um controle embaixo do texto) e `Row.height`; o `_input` das setas; a lista rola até o escolhido (`ensure_control_visible`). Os controles da linha deixam o clique passar para o botão.
- `res://tools/content_viewer/species_tab.gd`: o rosto e as etiquetas de Elemento nas linhas.

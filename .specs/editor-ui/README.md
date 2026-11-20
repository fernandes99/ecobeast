# editor-ui

O F2 fica mais fácil de usar: a ferramenta Peças ganha categorias, busca e uma grade de miniaturas no lugar da lista única de 130 peças, e o topo da janela volta a caber na tela.

## Contexto

Em 2026-11-20, depois da [village-pack](../village-pack/), o dono pediu: "Melhore a interface geral do F2, e também melhore as peças, deixe categorizado, tipo: "Construções", "Vegetações", "Iluminação", "Gerais"... Não precisa seguir a risca essas minhas sugestões, veja qual a melhor organização."

Claude abriu o F2 numa cena temporária, tirou fotos e achou dois problemas:

- **A ferramenta Peças é uma lista só, com 130 tipos**, cada um num botão de 76 px de altura com um ícone de 40 px. A lista tem perto de 10.000 px de altura, sem busca, na ordem dos ids: as casas da vila e as placas ficam no fim.
- **O topo não cabe na janela.** Na janela padrão, de 1600 px, o Salvar sai cortado, e o Publicar e a "Casa do jogador" ficam fora da tela. A dica de baixo também é cortada.

Claude propôs as categorias por tabela do catálogo, a busca, a grade de miniaturas, os botões do topo só com ícone e a barra de baixo com a mensagem. O dono respondeu: "Pode seguir".

## Objetivos

1. Achar uma peça em poucos cliques: escolher a categoria ou digitar parte do nome.
2. Ver a arte da peça antes de escolher, numa miniatura grande.
3. Ter o Salvar, o Publicar e a "Casa do jogador" sempre visíveis, a partir do tamanho mínimo da janela (1280 px).

## Anti-objetivos

- Nenhuma ferramenta muda o que faz. As teclas, o desfazer, a barra da peça no mapa (`ObjectBar`) e o pincel Vegetação continuam iguais.
- Nenhum tipo de peça muda de id, nome ou arte.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| As peças ficam em categorias, numa organização escolhida por Claude | Pedido do dono ("veja qual a melhor organização") |
| Seguir a proposta: categorias, busca, miniaturas, topo com ícones e mensagem embaixo | "Pode seguir" |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A categoria é uma tabela do catálogo (`prop_categories`) e uma coluna de `prop_types` | Dado de design mora no banco, editável pelo painel do Supabase; cada tipo novo nasce com a categoria na migração |
| 13 categorias pequenas, não 4 grandes ([01](01-prop-categories.md)) | Com 4, a Vegetação teria 90 peças, e o problema da lista longa voltaria |
| A busca procura em todas as categorias e ignora maiúsculas e acentos | "arvore" acha "Árvore" |
| No topo, Linha da história, Interiores, Altura e Camadas ficam só com o ícone e a dica do mouse | São os menos usados; Ilhas, Salvar e Publicar continuam com texto |
| A mensagem do editor (salvo, erro, aviso) e a situação da ilha vão para a barra de baixo, à direita | Elas eram cortadas no topo, e o topo precisa do espaço |

## Fora do escopo

- Os grupos do pincel Vegetação, que continuam os de hoje.
- Uma categoria para as paredes e as pontes, que têm ferramentas próprias.
- O modo Interiores.

## Pré-requisitos

- [map-editor](../map-editor/) (a janela, a coluna de grupos e o painel).
- [free-props](../free-props/) (a ferramenta Peças e o `PropArt`).

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-prop-categories](01-prop-categories.md) | As categorias no catálogo e a ferramenta Peças com busca, categorias e grade de miniaturas | concluída (falta o dono conferir) |
| 2 | [02-window-header](02-window-header.md) | O topo que cabe na janela e a barra de baixo com a mensagem e a situação da ilha | concluída (falta o dono conferir) |

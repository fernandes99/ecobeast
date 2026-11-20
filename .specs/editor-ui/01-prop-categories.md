# 01. As categorias das peças

- **Status:** concluída (falta o dono conferir)
- **Depende de:** [free-props/03](../free-props/03-pieces-tool.md)

## Contexto

A ferramenta Peças lista os 130 tipos de peça solta numa coluna só, na ordem dos ids ([README](README.md#contexto)).

## Escopo

- A tabela `prop_categories` e a coluna `prop_types.prop_category_id`, na migração `20270112000000_prop_categories`, no `schema.prisma`, no `CATALOG_TABLES`, no `catalog_schema.gd` e na [game-data/architecture.md](../game-data/architecture.md).
- O `seed-data/prop_categories.json`, porque toda tabela do catálogo tem o seu arquivo. O `prop_types.json` ganha o `prop_category_id` em cada linha, porque o teste e2e do pacote confere que as colunas do JSON são as do banco.
- O `ObjectPanel` do editor, com a busca, as categorias e a grade.

## Requisitos

- **RF-01:** `prop_categories` tem `id`, `slug` (`^[a-z0-9_]+$`, único) e `name`. A ordem do editor é a do `id`.
- **RF-02:** `prop_types.prop_category_id` é obrigatória, com chave estrangeira para `prop_categories`. O padrão é 10 (Objetos), para um tipo criado sem categoria.
- **RF-03:** As categorias e os tipos de cada uma:

  | id | slug | Nome | Tipos |
  | --- | --- | --- | --- |
  | 1 | `houses` | Casas | 24 a 26, 95 a 100, 102 a 111 |
  | 2 | `buildings` | Prédios | 22, 23, 27, 101 |
  | 3 | `trees` | Árvores | 1, 2, 28 a 38, 63, 67 a 69 |
  | 4 | `plants` | Plantas | 3, 4, 5, 7 a 10, 40, 42, 43, 46 a 52, 61, 65, 66, 73, 74, 76 a 78, 83, 86, 89 |
  | 5 | `flowers` | Flores | 6, 44, 45, 75, 80, 84, 128 |
  | 6 | `rocks` | Pedras | 11 a 17, 53 a 60, 62, 64, 81, 82, 88 |
  | 7 | `wood` | Troncos e galhos | 39, 41, 70 a 72, 79, 85, 87, 90 |
  | 8 | `beach` | Praia | 91 a 94 |
  | 9 | `lights` | Iluminação | 18, 123 |
  | 10 | `objects` | Objetos | 21, 116 a 119, 124, 125 |
  | 11 | `signs` | Placas | 19, 120 a 122, 129, 130 |
  | 12 | `water` | Água | 112 a 115 |
  | 13 | `garden` | Jardim e plantação | 20, 126, 127 |

  Todo tipo de 1 a 130 está em uma categoria só. Um tipo novo entra na migração dele com a categoria. Depois, os tipos 18, 19 e 23 a 27 saíram do jogo ([prop-cleanup/01](../prop-cleanup/01-remove-town-props.md)): Casas ficou só com as casas dos pacotes e da vila, Prédios com o Refúgio e o Altar-portal, Iluminação com a Lanterna pendurada e Placas com as 5 da vila.
- **RF-04:** A ferramenta Peças mostra, de cima para baixo:
  - a prévia, agora com 120 px de altura; "Variante N de M · teclas ← →" e os números das variantes, sem os botões de seta, que ocupavam uma linha inteira; o Espelhar; e as opções da peça escolhida no mapa;
  - o campo "Buscar peça";
  - os botões das 13 categorias, com o nome, em linhas que quebram sozinhas;
  - a grade das peças da categoria aberta, em 4 colunas: cada célula tem a miniatura da variante 1 (até 64 px, sem borrar o pixel) e o nome embaixo, em até 2 linhas. A peça em uso fica marcada.
- **RF-05:** Com texto na busca, a grade mostra as peças de todas as categorias cujo nome tem o texto, sem diferença de maiúsculas e acentos, e nenhuma categoria fica marcada. Apagar o texto volta para a categoria aberta. Sem resultado, a grade mostra "Nenhuma peça com esse nome."
- **RF-06:** Quando uma peça do mapa é escolhida (o botão direito), a ferramenta abre a categoria dela, apaga a busca e marca o tipo. A ferramenta abre na categoria Casas.
- **RF-07:** O `CatalogValidator` confere a chave estrangeira nova pelo `catalog_schema.gd`, como as outras.

## Critérios de aceite

- [x] A ferramenta Peças mostra as 13 categorias, e cada peça aparece na sua.
- [x] Digitar "arvore" mostra as árvores de todas as categorias.
- [x] Escolher uma peça no mapa abre a categoria dela.
- [x] `godot --headless --path client --quit-after 60` roda sem erro de script, e os testes do servidor passam.

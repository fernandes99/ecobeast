# Content viewer: arquitetura

O desenho que as 3 fases compartilham. As decisões e o motivo de cada uma estão no [README.md](README.md).

## Onde fica

Tudo mora em `res://tools/content_viewer/`, junto das outras ferramentas de desenvolvimento (`res://tools/board_sprites.gd`). Nenhuma tela do jogo depende desta pasta. A única ligação é o F1, na cena raiz.

```
res://tools/content_viewer/
  content_viewer.gd       a janela: abas, aviso sem catálogo, F1 para fechar
  content_files.gd        os caminhos dos arquivos e a conferência do que existe
  list_detail.gd          o par lista à esquerda e detalhe à direita, usado pelas abas
  file_preview.gd         um arquivo: a imagem, a folha animada, o efeito ou o som; ou o tracejado do que falta
  summary_tab.gd          Resumo (fase 01, e cresce nas fases 02 e 03)
  species_tab.gd          Ecobeasts (fase 01)
  skills_tab.gd           Técnicas (fase 02)
  elements_tab.gd         Elementos (fase 02)
  biomes_tab.gd           Biomas (fase 03)
  items_tab.gd            Itens (fase 03)
  traits_tab.gd           Traços (fase 03)
  temperaments_tab.gd     Temperamentos (fase 03)
  statuses_tab.gd         Estados (fase 03)
```

As telas são montadas no código, sem `.tscn`, como o `BoardCreatureCard`. São listas e textos, e montar no código deixa cada aba num arquivo só.

## A janela

- **Abrir e fechar:** a cena raiz (`res://screens/main/main.gd`) trata o F1 no `_unhandled_input`, só com `OS.has_feature("editor")`. A tag `editor` existe só quando o jogo roda pelo editor, e nunca num jogo exportado, nem de depuração. O F1 cria a janela escondida na primeira vez (o `force_native` só pode mudar com ela escondida), põe na árvore e a mostra; depois, mostra ou esconde a mesma. Com a janela em foco, as teclas vão para ela: ela mesma fecha com F1, e o X da janela também fecha.
- **Janela do sistema:** `ContentViewer` estende `Window`, com `force_native = true`. Um `Window` do Godot, por padrão, é desenhado *dentro* da janela do jogo. `force_native` faz dele uma janela de verdade do Windows, com barra de título, que pode ficar ao lado do jogo. Tamanho inicial de 1280×720, redimensionável, título "Ecobeast: conteúdo". Sem `content_scale`: os pontos são pixels da tela.
- **O jogo atrás** continua rodando e não muda de tamanho.
- **Tema:** a janela usa o tema do jogo (`res://ui/theme/main_theme.tres`, que já vale para o projeto todo), com textos menores que os do celular. O tamanho de fonte fica numa constante no topo de `content_viewer.gd`.
- **Abas:** um `TabContainer` com as abas na ordem Resumo, Ecobeasts, Técnicas, Elementos, Biomas, Itens, Traços, Temperamentos e Estados. A fase 01 cria só Resumo e Ecobeasts, e as outras fases acrescentam as delas. O nome de cada aba mostra a quantidade, como "Técnicas (52)". A janela lembra a aba e o item escolhidos enquanto o jogo estiver aberto.
- **Ir até um item:** `ContentViewer.show_item(tab: StringName, id: int)` troca para a aba e escolhe o item. Todo nome de outro item num detalhe (uma Técnica no Ecobeast, um Ecobeast na Técnica) é um botão com aparência de link que chama `show_item`.

## Os dados

- **De onde vêm:** o `GameData` (autoload), que baixou o catálogo da API na abertura do jogo. Nada é pedido ao servidor de novo, a não ser pelo "Tentar de novo".
- **Tabelas sem consulta pronta:** o `GameData` já tem consultas para Ecobeasts, Técnicas, Elementos, Evoluções, Traços, Temperamentos e Itens. Para o resto (biomas, `species_biomes`, `species_traits`, `skill_effects`, `status_conditions`, `status_condition_immunities`, `ground_effects`, `rarities`, `skill_categories`, `skill_targets`, `area_shapes`), a fase 01 acrescenta `Catalog.get_rows(table_name: String) -> Array[Dictionary]` e o atalho `GameData.get_rows(table_name)`. Ela devolve uma cópia das linhas, na ordem do `id` quando a tabela tem `id`. O visualizador não lê as tabelas por outro caminho.
- **Sem catálogo:** quando o `GameData` não tem catálogo (o servidor não respondeu, ou o `CatalogValidator` achou erro), a janela mostra no topo "Sem catálogo: o servidor não respondeu." (ou o primeiro erro do `GameData.errors`) e o botão **Tentar de novo**. O botão chama `await GameData.load_catalog()` e monta as abas de novo. Ele não mexe na tela do jogo. Enquanto isso, só a aba Resumo aparece, com as pastas de Ecobeast (veja a [fase 01](01-viewer-window.md), RF-10).

## Os arquivos

`ContentFiles` (`class_name`, `RefCounted`, só funções `static`) é o único lugar que sabe onde o jogo procura cada arquivo. Para cada caminho que já é constante de uma classe do jogo, ele usa essa constante. Para os que hoje só existem na tela da luta, que não tem `class_name`, a constante passa para o `ContentFiles`, e a tela da luta passa a usá-la de lá.

| Item | Arquivo | Caminho | Constante de onde vem |
| --- | --- | --- | --- |
| Ecobeast | front | `res://assets/creatures/<slug>/front.png` | `CreaturePortrait.SPRITE_PATH` |
| Ecobeast | tabuleiro | `res://assets/creatures/<slug>/board.png` | `BoardView.BOARD_SPRITE_PATH` |
| Ecobeast | explorar, parado e andando | `res://assets/creatures/<slug>/explore/idle.png` e `walk.png` | `CreatureSprite.SHEET_PATH` |
| Ecobeast | luta, parado e andando | `res://assets/creatures/<slug>/battle/idle.png` e `walk.png` | `BattleSheets.PATH` |
| Ecobeast | som característico (`call`) | `res://assets/creatures/<slug>/call.wav` | `CREATURE_CALL_PATH`, nova em `ContentFiles` ([creature-sounds/01](../creature-sounds/01-call-files.md)) |
| Técnica | ícone | `res://assets/skills/<slug>.png` | nova, em `ContentFiles` |
| Técnica | efeito | `res://assets/effects/skills/<slug>.png` | `SKILL_EFFECT_PATH`, que sai de `board_battle_screen.gd` |
| Técnica | som | `res://assets/sounds/skills/<slug>.wav` | `SKILL_SOUND_PATH`, que sai de `board_battle_screen.gd` |
| Técnica | projétil (opcional) | `res://assets/effects/skills/<slug>_projectile.png` | `SKILL_PROJECTILE_PATH`, nova em `ContentFiles` ([board-battle/15](../board-battle/15-projectile-effects.md)); opcional desde a [05](05-skill-projectile.md): não conta no que falta |
| Item | ícone | `res://assets/items/<slug>.png` | `ItemIcon.SPRITE_PATH` |
| Bioma | superfície | `res://assets/terrain/surfaces/<slug>.png` | `HexMapView.SURFACE_PATH` |

- **Existe ou não:** `ResourceLoader.exists(path)`, que é como o jogo carrega: um arquivo sem `.import` (o Godot ainda não importou) conta como faltando.
- **Pastas sem catálogo:** `ContentFiles.orphan_folders(dir: String, slugs: Array[String]) -> Array[String]` lista, em ordem alfabética, as subpastas (ou os prefixos de arquivo, para o terreno) que não batem com nenhum `slug` do catálogo. A lista vem do `DirAccess`, que funciona porque o jogo roda pelo editor.

## O par lista e detalhe

`ListDetail` (`HSplitContainer`) tem, à esquerda, uma lista de linhas clicáveis com até 30% da largura e, à direita, um `ScrollContainer` com o detalhe. Cada aba diz:

- as linhas: o texto, uma cor opcional (a do Elemento) e um texto à direita, como "4/6", que fica verde quando tudo está pronto, amarelo quando falta parte e vermelho quando falta tudo;
- como montar o detalhe de um `id`.

O detalhe é feito de *blocos*: painéis com um título pequeno em maiúsculas ("EVOLUÇÃO", "TÉCNICAS POR NÍVEL") e o conteúdo. Os detalhes são montados de novo a cada escolha, e não guardados.

## O preview de um arquivo

`FilePreview` (`PanelContainer`) mostra um arquivo num quadro com fundo xadrez e o nome embaixo (`front`, `explore idle`):

- **Imagem parada** (front, board, ícones, superfície): a imagem inteira, sem filtro (`TEXTURE_FILTER_NEAREST`) e ampliada por um número inteiro até caber no quadro.
- **Folha do explorar:** um preview por direção, quadro a quadro, no ritmo do jogo (`CreatureSprite.IDLE_SECONDS` e `WALK_SECONDS` por ciclo, com células de `SheetSprite.CELL_SIZE`), ampliado 3×. São as 5 linhas da folha mais as 3 do lado esquerdo, que são linhas do lado direito desenhadas espelhadas.
- **Folha da luta:** um preview por direção, com a célula e os quadros de cada linha lidos pelo `BattleSheets` e o tempo de `BattleSheets.FRAME_SECONDS`, ampliado 2×: a parada tem frente e costas, e a andando tem as 3 linhas mais as 3 espelhadas.
- **As direções** de cada folha (o nome, a linha e se é espelhada) ficam no `ContentFiles`, com as linhas tiradas das constantes do `SheetSprite` e do `BattleSheets`. As folhas da luta esperam as mesmas 8 direções do explorar; a direção que a folha ainda não tem fica com `ContentFiles.NO_ROW` e aparece tracejada. Quando as folhas da luta ganharem as linhas novas (e o `BattleSheets`, as constantes delas), basta trocar o `NO_ROW` pela constante.
- **Pronto:** um arquivo está pronto quando existe e, se for uma folha, tem todas as direções desenhadas (`Entry.complete()`). As contagens do visualizador contam os prontos.
- **Efeito de Técnica:** os quadros (largura ÷ altura, como em `BoardView.play_effect`), a 0,05 s cada (`BoardView.EFFECT_FRAME_SECONDS`), em repetição, com 0,6 s de pausa entre uma volta e outra.
- **Som:** um botão "▶ Ouvir" que toca o `.wav` num `AudioStreamPlayer` da janela.
- **Faltando:** o quadro com borda vermelha tracejada, a palavra "falta" e o caminho `res://...` embaixo, em letra pequena.

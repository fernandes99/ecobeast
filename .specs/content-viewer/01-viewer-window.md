# 01. A janela, o Resumo e os Ecobeasts

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [board-battle](../board-battle/) concluída

## Contexto

O dono quer ver todo o conteúdo do jogo num lugar só, para decidir o que falta terminar ([README](README.md)). Esta fase cria a janela que abre com F1, o par lista e detalhe e o preview de arquivos, que as outras abas reutilizam, a aba Resumo e a aba Ecobeasts. O desenho compartilhado está no [architecture.md](architecture.md).

## Escopo

- O F1 na cena raiz, só ao rodar pelo editor.
- A janela do sistema de 1280×720, com as abas Resumo e Ecobeasts.
- `ContentFiles`, `ListDetail` e `FilePreview`.
- `Catalog.get_rows` e `GameData.get_rows`.
- O aviso sem catálogo, com "Tentar de novo".
- As constantes de caminho do efeito e do som de Técnica, que saem da tela da luta e vão para o `ContentFiles`.

## Fora do escopo

- As abas Técnicas e Elementos ([02](02-skills-and-elements.md)) e Biomas, Itens, Traços, Temperamentos e Estados ([03](03-world-and-items.md)). Os nomes de Técnica no detalhe do Ecobeast só viram links na fase 02, quando a aba existe.
- Tudo o que o [README](README.md) põe fora do escopo.

## Requisitos

- **RF-01:** Com o jogo rodando pelo editor (F5), F1 abre a janela "Ecobeast: conteúdo", separada da janela do jogo, com 1280×720. Ela é redimensionável e pode ser movida. Num jogo exportado, F1 não faz nada.
- **RF-02:** F1, com o foco no jogo ou na janela, e o X da janela fecham a janela. Abrir de novo mostra a mesma aba e o mesmo item de antes. O jogo atrás não muda de tamanho nem para.
- **RF-03:** As abas são "Resumo" e "Ecobeasts (N)", com N igual à quantidade de Ecobeasts do catálogo. A janela abre no Resumo.
- **RF-04:** A lista de Ecobeasts mostra, em ordem de número do Bestiário (o `id`), "#N Nome" e, à direita, quantos dos 6 arquivos estão prontos ("4/6"); uma folha só está pronta com todas as direções (RF-05): verde com 6, amarelo com 1 a 5 e vermelho com 0. Clicar escolhe o Ecobeast; o primeiro vem escolhido.
- **RF-05:** O detalhe do Ecobeast tem, nesta ordem:
  1. o `front` (ou o tracejado), o nome com "#N", os Elementos em selos na cor deles, a raridade, a altura em metros e o peso em kg, e a descrição;
  2. **Evolução:** a linha inteira, do primeiro ao último estágio, com o gatilho entre um e outro ("Ruvo → nível 16 → Ruvak → nível 36 → Ruvaroth"). O Ecobeast escolhido fica em negrito, e os outros são links para o detalhe deles. Um gatilho que não é de nível usa o nome da tabela `evolution_triggers` com o valor (o item, o Vínculo mínimo, o horário ou a zona). Sem Evolução, "Não evolui.";
  3. **Técnicas por nível:** uma linha por entrada do `species_skills`, ordenada por nível e depois pelo `id` da Técnica, com o nível (ou o nome do método, quando não é "Por nível"), o nome da Técnica e, à direita, "ícone ✓/✗ · efeito ✓/✗ · som ✓/✗";
  4. **Stats base:** os 6 stats com o nome, o valor e uma barra proporcional a 255, e o total;
  5. **Traços:** os nomes, com "(oculto)" no oculto;
  6. **Biomas:** o nome de cada bioma do `species_biomes` com a taxa, da maior para a menor; sem nenhum, "Não nasce no mapa.";
  7. **Arquivos:** o `front` e o `board` numa linha; depois, cada folha que existe (`explore idle`, `explore walk`, `battle idle` e `battle walk`) na sua linha, com todas as direções andando como no jogo, cada uma com o nome da direção; e, por último, os que faltam, tracejados com o caminho. As direções das folhas de explorar são 8: frente, desce à direita, direita, sobe à direita, costas, sobe à esquerda, esquerda e desce à esquerda. As folhas da luta esperam as mesmas 8 direções, a pedido do dono ("falta as outras direções do battle também (que ainda vou mandar)"), mas hoje a parada só tem frente e costas, e a andando só desce, direita e sobe. As direções que a folha ainda não tem aparecem tracejadas, com "· falta", e o título da folha diz quantas faltam ("battle idle · faltam 3 direções"). As do lado esquerdo são a arte do lado direito espelhada, como o jogo faz, e levam "(espelho)" embaixo; só as 5 desenhadas contam para a folha estar pronta.
- **RF-06:** O Resumo mostra blocos com um número grande e uma legenda, cada um verde quando está completo, amarelo quando falta parte e vermelho quando falta tudo:
  - Ecobeasts no catálogo (sem cor);
  - Ecobeasts com front, com board, com as duas folhas de explorar e com as duas folhas da luta, cada um como "N de M".
- **RF-07:** O Resumo lista as pastas de `res://assets/creatures/` que não batem com nenhum Ecobeast do catálogo, com o título "Pastas de Ecobeast fora do catálogo". Sem nenhuma, o bloco não aparece (hoje todas as 14 pastas têm um Ecobeast).
- **RF-08:** O Resumo lista os Ecobeasts aos quais falta algum arquivo ou direção, cada um com o que falta ("Ruvaroth: battle idle, battle walk"; "Ruvo: battle idle (3 direções), battle walk (2 direções)"). Clicar no nome abre o Ecobeast. Os cartões do RF-06 contam só as folhas prontas.
- **RF-09:** Um arquivo conta como existente quando `ResourceLoader.exists` o encontra no caminho do jogo. Um arquivo sem `.import` conta como faltando.
- **RF-10:** Sem catálogo, a janela mostra no topo "Sem catálogo: o servidor não respondeu." (ou o primeiro erro do `GameData.errors`) e o botão **Tentar de novo**. Só a aba Resumo aparece, com a lista das pastas de `res://assets/creatures/` e quantos dos 6 arquivos cada uma tem. Quando o "Tentar de novo" baixa o catálogo, as abas aparecem sem fechar a janela.
- **RF-11:** A tela da luta continua tocando o efeito e o som do Arranhão como antes, agora com os caminhos do `ContentFiles`.

## Critérios de aceite

- [ ] Com F5 e o servidor no ar, F1 abre a janela ao lado do jogo, e o jogo continua em retrato, do mesmo tamanho.
- [ ] F1 de novo fecha; o X também; reabrir volta ao mesmo Ecobeast.
- [ ] O Ruvo mostra "4/6" amarelo, a linha Ruvo → nível 16 → Ruvak → nível 36 → Ruvaroth, as 8 Técnicas por nível (Arranhão e Rugido Feroz no 1, … Chama Espiral no 31), HP 44 e Velocidade 66, Fúria Ardente e Instinto (oculto), o front, o board e as 4 folhas com as 8 direções, andando as que existem: as do explorar completas, e as da luta com 3 (parada) e 2 (andando) tracejadas.
- [ ] O Ruvaroth mostra "4/6" amarelo e os dois sprites da luta tracejados com `res://assets/creatures/ruvaroth/battle/idle.png` e `walk.png`.
- [ ] O Resumo mostra "14" Ecobeasts, "0 de 14" com as folhas da luta e "11 de 14" com as de explorar, nenhuma pasta fora do catálogo e os 14 Ecobeasts aos quais falta algo.
- [ ] Com o servidor desligado, F1 abre a janela com o aviso e as pastas; com o servidor ligado de novo, "Tentar de novo" mostra as abas.
- [ ] Na luta, o Arranhão ainda mostra o efeito e toca o som.

## Desenho técnico

**Criar** (em `res://tools/content_viewer/`, como no [architecture.md](architecture.md)): `content_viewer.gd`, `content_files.gd`, `list_detail.gd`, `file_preview.gd`, `summary_tab.gd` e `species_tab.gd`.

**Alterar:**

- `res://screens/main/main.gd`: no `_unhandled_input`, F1 (`KEY_F1`, sem uma ação no Input Map, para não aparecer nas configurações do jogo) com `OS.has_feature("editor")` cria o `ContentViewer` como filho da cena raiz na primeira vez e depois alterna `visible`. O F1 na própria janela é tratado pelo `ContentViewer`.
- `res://core/data/catalog.gd`: `get_rows(table_name: String) -> Array[Dictionary]`, com uma cópia das linhas ordenada por `id` quando a tabela tem a coluna. Uma tabela que não existe devolve um array vazio.
- `res://core/autoload/game_data.gd`: `get_rows(table_name)` repassa para o `catalog`.
- `res://screens/board_battle/board_battle_screen.gd`: tira `SKILL_EFFECT_PATH` e `SKILL_SOUND_PATH` e usa `ContentFiles.SKILL_EFFECT_PATH` e `ContentFiles.SKILL_SOUND_PATH`.
- `.specs/foundation/architecture.md`: a pasta `res://tools/content_viewer/` na árvore.

**Reutilizar:** as consultas do `GameData` (`get_all_species`, `get_learnset`, `get_evolutions`, `get_species_traits`, `get_element`, `get_skill`), o `BattleSheets` para ler as folhas da luta, as constantes de caminho listadas no [architecture.md](architecture.md) e o `UiPalette` para o verde, o amarelo e o vermelho, se houver (senão, constantes no topo de `content_viewer.gd`).

## Verificação

- `godot --headless --path client --import` e `godot --headless --path client --quit-after 30` sem erros nem avisos de script.
- Um script sem janela (no scratchpad, fora do repositório) baixa o catálogo da API, monta o `ContentViewer` sem mostrá-lo e confere: as contagens do Resumo (14 Ecobeasts, 0 com as folhas da luta prontas), nenhuma pasta fora do catálogo, "4/6" no Ruvo e no Ruvaroth, as direções das 4 folhas, as 8 linhas de Técnicas do Ruvo e o texto da Evolução.
- O mesmo script sem o servidor confere o aviso e a lista de pastas.
- Os testes da tela da luta que já existem continuam passando.
- Manual, com F5: os critérios de aceite. Prints da janela com o Ruvo e com o Ruvaroth.

## Tarefas

- [x] `Catalog.get_rows` e `GameData.get_rows`.
- [x] `ContentFiles`, com as constantes da tela da luta.
- [x] `FilePreview` e `ListDetail`.
- [x] `ContentViewer`, com o F1 na cena raiz e o aviso sem catálogo.
- [x] A aba Ecobeasts.
- [x] A aba Resumo.
- [x] A árvore no `foundation/architecture.md`.
- [x] Verificação sem janela e prints com janela.
- [ ] O dono ver com F5.

## Resultado da verificação

Em seguida, o dono disse que o Ruvo ainda não está completo: faltam as outras direções da luta, que ele vai mandar. As folhas da luta passaram a esperar as 8 direções do explorar, e o Ruvo e o Ruvak caíram para "4/6". O script confere o "0 de 14" das folhas da luta, os títulos com as direções que faltam e as direções tracejadas.

Antes, depois de ver a primeira versão, o dono pediu todas as direções das folhas ("quero que mostre todos, dos walks de todas as direções"): antes, cada folha mostrava só a primeira linha. O script sem janela passou a conferir as 4 folhas do Ruvo, as 9 direções espelhadas e as costas e o "desce à esquerda" nas 3 folhas que andam; o explorar, que no Ruvo tem 7 pixels de altura, ficou ampliado 3×, e a luta, 2×.

Em 2026-11-06, o projeto importou sem erros, e o jogo sem janela abriu sem erros nem avisos de script.

Na primeira versão, o script sem janela, com o catálogo da API, deu 0 falhas em 31 conferências: as 2 abas com "Ecobeasts (14)", o Resumo (14 Ecobeasts, "14 de 14" com front e board, "11 de 14" com as folhas de explorar, "2 de 14" com as da luta, nenhuma pasta fora do catálogo e 12 Ecobeasts com falta), o "6/6" do Ruvo e o "4/6" do Ruvaroth, a Evolução com os níveis 16 e 36, as 8 Técnicas por nível, os stats, os Traços, a Planície com 60, "Raro · 0,5 m · 9 kg", os caminhos do que falta no Ruvaroth, o `show_item`, o aviso e as pastas sem catálogo e o "Tentar de novo".

A checagem de carga e os testes do tabuleiro, do tabuleiro parado, do golpe, dos sons e do log seguem com 0 falhas, com os caminhos do efeito e do som vindo do `ContentFiles`.

Os primeiros números da spec vinham do seed do servidor, que tem 9 Ecobeasts. O catálogo da API tem 14, e a spec passou a usar os dele.

Prints com janela mostraram o Resumo, o Ruvo, o Ruvaroth (com os dois sprites da luta tracejados e o caminho) e o aviso sem catálogo. Eles pegaram dois erros que o script não pegava, já corrigidos: a linha escolhida antes continuava marcada, e o "✔" saía como emoji roxo, então os sinais passaram a ser ✓ e ✗.

O F1 pela cena raiz não foi testado sem janela, porque a cena raiz faz o login com a sessão do dono. Falta o dono ver com F5.

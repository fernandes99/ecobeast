# 03. Pincéis de terreno

- **Status:** concluída
- **Depende de:** [02-editor-window](02-editor-window.md), [architecture.md](architecture.md)

## Contexto

Com a [02](02-editor-window.md), o editor abre, cria, mostra e salva ilhas, mas não muda o terreno. Esta fase traz os pincéis de terreno, a chegada e o desfazer. O `HexMapView` monta as linhas de hexágonos uma vez, e as transições e decorações de um hexágono dependem dos vizinhos. Por isso pintar precisa refazer as linhas tocadas e as vizinhas, sem montar a ilha de novo.

## Escopo

- Os pincéis: bioma, forma, pôr hexágono, tirar hexágono e chegada.
- O tamanho do pincel e o contorno dele sob o ponteiro.
- `HexMapView.update_tiles(coords)`.
- Desfazer e refazer.

## Fora do escopo

- Construções e áreas ([04](04-buildings-and-areas.md)).
- Escolher a variante à mão: ela é sempre sorteada.
- Pincéis de forma livre (balde de tinta, linha, retângulo).

## Requisitos

### Os pincéis

- **RF-01:** o painel da esquerda ganha as ferramentas, acima da lista de ilhas, em blocos:
  - **Ferramenta:** Bioma, Forma, Pôr hexágono, Tirar hexágono e Chegada. A escolhida fica azul, com a borda clara, e uma frase embaixo diz o que ela faz. As teclas 1 a 5 escolhem nessa ordem.
  - **Bioma:** os 5 biomas de terreno, cada um como um hexágono com a textura e a altura do jogo (`TerrainSwatch`) e o nome do catálogo embaixo.
  - **Forma:** Plano, Colina e Montanha, também como hexágonos. O Plano mostra o bioma escolhido.
  - **Pincel:** o tamanho, com a quantidade de hexágonos que ele pega.

  Pedido do dono, depois do primeiro teste: na primeira versão, os biomas eram quadrados sem nome, e ele não conseguia identificá-los.
- **RF-02:** o tamanho do pincel é um raio de 0 (um hexágono) a 10, mudado num controle do painel e com `[` e `]`. Sob o ponteiro, o contorno mostra os hexágonos que o pincel vai pegar, nas duas visões.
- **RF-03:** o botão esquerdo pinta: apertar e arrastar pinta todos os hexágonos por onde o pincel passa.
  - **Bioma:** troca o bioma dos hexágonos que existem.
  - **Forma:** troca a forma dos hexágonos que existem.
  - **Pôr hexágono:** cria os que não existem, com o bioma e a forma escolhidos por último nas ferramentas Bioma e Forma.
  - **Tirar hexágono:** apaga os que existem, menos a chegada. Um hexágono apagado sai também da construção e da área dele.
  - **Chegada:** move a chegada para o hexágono sob o ponteiro, se ele existir (o pincel ignora o tamanho).
- **RF-04:** trocar a forma, ou criar um hexágono, sorteia a variante como o gerador: em `flat`, `detailChance` escolhe entre 4 e 6 e o resto entre 1 e 3; nas outras formas, entre 1 e 3. Trocar só o bioma mantém a variante.
- **RF-05:** a ilha não pode passar de 20.000 hexágonos: Pôr hexágono para no limite e mostra "A ilha chegou a 20.000 hexágonos." na barra de cima.

### Desenhar

- **RF-06:** o `HexMapView` ganha `update_tiles(coords: Array[Vector2i])`, que refaz os pedaços desses hexágonos e os vizinhos, para as transições, as bordas e as decorações ficarem certas. A visão de cima repinta só os hexágonos tocados.
- **RF-07:** uma pincelada de raio 10 arrastada pela tela não trava o editor: o mapa é refeito no máximo uma vez por quadro, com os hexágonos acumulados.

### Desfazer

- **RF-08:** cada pincelada, do apertar ao soltar do botão, é um passo. Ctrl+Z desfaz o último, Ctrl+Y (e Ctrl+Shift+Z) refaz. Mover a chegada é um passo; renomear também.
- **RF-09:** salvar mantém o histórico; trocar de ilha, criar uma nova ou descartar as mudanças o apaga. Desfazer até o estado salvo tira o `*` do título.

## Critérios de aceite

- [x] Pintar bioma e forma muda o mapa na hora, com as transições e as decorações certas entre o hexágono pintado e os vizinhos.
- [x] Pôr e tirar hexágonos muda o contorno da ilha; a chegada não some com Tirar hexágono.
- [x] Uma pincelada de raio 10 arrastada pela ilha de 20.000 hexágonos não trava.
- [x] Ctrl+Z desfaz a pincelada inteira, e Ctrl+Y a refaz.
- [x] Salvar, fechar o jogo e abrir a ilha mostra o terreno pintado.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos, em `res://tools/map_editor/`:

- `editor_tools.gd`: as ferramentas, o tamanho, o contorno e o que cada uma muda no `IslandDraft`.
- `editor_history.gd`: o desfazer e refazer sobre o `UndoRedo` do Godot. Cada passo guarda os hexágonos de antes e de depois só dos que mudaram.
- `terrain_swatch.gd`: `TerrainSwatch`, a amostra em hexágono de um bioma ou de uma forma, com o paredão na altura do `HexTile.level()` e o nome em até duas linhas.

Arquivos alterados:

- `res://tools/map_editor/map_editor.gd`, `editor_canvas.gd` e `island_draft.gd`.
- `res://ui/components/hex_map_view.gd`: `update_tiles` e `chunk_columns`. Refazer as linhas inteiras não serviu: numa ilha de 163 hexágonos de largura, uma linha leva 10 ms, e o pincel de raio 10 toca 23 linhas (216 ms por quadro). Com `chunk_columns`, cada linha vira pedaços dessa largura em colunas, e `update_tiles` refaz só os pedaços tocados e os do lado. O editor usa pedaços de 16 colunas. Em 0, o padrão, a linha é um pedaço só, como o Explorar zona e o tabuleiro sempre usaram. Numa linha, o chão de todos os pedaços vem antes das decorações de trás, e estas antes das da frente, para uma árvore que passa da borda ficar por cima do chão do pedaço ao lado.
- `res://tools/map_editor/island_overview.gd`: a visão de cima vira um `MultiMesh`, uma instância por hexágono. Pintar troca a cor, e pôr ou tirar um hexágono usa uma vaga livre, sem remontar a ilha.
- `res://tools/map_editor/island_draft.gd`: `snapshot`, `restore`, `add_tile` e `remove_tile`, que tira o hexágono da área e da construção. A construção que fica sem hexágonos sai.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

No editor (F5): pintar cada bioma e cada forma, pôr e tirar hexágonos, mover a chegada, desfazer e refazer, pintar com raio 10 numa ilha de 20.000 hexágonos, salvar e abrir de novo.

Feita em 2026-11-10:
- **Projeto:** abre sem erro de script. Com `-d`, os avisos são os de antes.
- **Cenas temporárias, já apagadas,** conferiram:
  - o bioma em raio 2 pintando 19 hexágonos, com o Ctrl+Z e o Ctrl+Y voltando e refazendo, e o histórico de volta à versão salva;
  - a forma sorteando a variante de 1 a 3;
  - pôr hexágonos fora da ilha;
  - tirar sem levar a chegada, e tirando o hexágono da construção, com o desfazer devolvendo os dois;
  - a chegada indo para o último hexágono da pincelada, num passo só;
  - renomear letra por letra desfazendo de uma vez;
  - pôr parando em 20.000, com o aviso;
  - a ordem dos nós com pedaços e linhas novas, e o modo sem pedaços do Explorar zona (`set_current` e `set_actor_row`) e do tabuleiro (`build_all_rows`).
- **Velocidade, com `-d`:** a pincelada de raio 10 numa ilha de 19.927 hexágonos levou 31 ms por quadro em média e 80 ms no pior quadro, de perto. Antes dos pedaços eram 262 ms. Na visão de cima, o pior quadro foi de 28 ms.
- **Quadros do Movie Maker:** água com a margem atravessando os pedaços sem emenda, pedra com montanha e o buraco de Tirar hexágono com o paredão.
- **Com o dono, em 2026-11-11:** no F5, ele pediu um painel mais claro, porque não identificava os biomas. Com as amostras em hexágono, ele aprovou ("Ficou bom").

## Tarefas

- [x] `update_tiles` no `HexMapView` e o repintar da visão de cima.
- [x] As ferramentas, o tamanho e o contorno.
- [x] Desfazer e refazer.
- [x] Rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.

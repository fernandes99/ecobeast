# 03. Pincéis de terreno

- **Status:** aprovada
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

- **RF-01:** o painel da esquerda ganha as ferramentas, acima da lista de ilhas: Bioma (com os 5 biomas de terreno, cada um com a amostra da superfície), Forma (`flat`, `hill`, `mont`, com os nomes Plano, Colina e Montanha), Pôr hexágono, Tirar hexágono e Chegada. Uma ferramenta fica escolhida por vez, e as teclas 1 a 5 escolhem nessa ordem.
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

- **RF-06:** o `HexMapView` ganha `update_tiles(coords: Array[Vector2i])`, que refaz as linhas desses hexágonos e as linhas vizinhas, para as transições, as bordas e as decorações ficarem certas. A visão de cima repinta só os hexágonos tocados.
- **RF-07:** uma pincelada de raio 10 arrastada pela tela não trava o editor: o mapa é refeito no máximo uma vez por quadro, com os hexágonos acumulados.

### Desfazer

- **RF-08:** cada pincelada, do apertar ao soltar do botão, é um passo. Ctrl+Z desfaz o último, Ctrl+Y (e Ctrl+Shift+Z) refaz. Mover a chegada é um passo; renomear também.
- **RF-09:** salvar mantém o histórico; trocar de ilha, criar uma nova ou descartar as mudanças o apaga. Desfazer até o estado salvo tira o `*` do título.

## Critérios de aceite

- [ ] Pintar bioma e forma muda o mapa na hora, com as transições e as decorações certas entre o hexágono pintado e os vizinhos.
- [ ] Pôr e tirar hexágonos muda o contorno da ilha; a chegada não some com Tirar hexágono.
- [ ] Uma pincelada de raio 10 arrastada pela ilha de 20.000 hexágonos não trava.
- [ ] Ctrl+Z desfaz a pincelada inteira, e Ctrl+Y a refaz.
- [ ] Salvar, fechar o jogo e abrir a ilha mostra o terreno pintado.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos, em `res://tools/map_editor/`:

- `editor_tools.gd`: as ferramentas, o tamanho, o contorno e o que cada uma muda no `IslandDraft`.
- `editor_history.gd`: o desfazer e refazer sobre o `UndoRedo` do Godot. Cada passo guarda os hexágonos de antes e de depois só dos que mudaram.

Arquivos alterados:

- `res://tools/map_editor/map_editor.gd`, `editor_canvas.gd` e `island_draft.gd`.
- `res://ui/components/hex_map_view.gd`: `update_tiles`.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

No editor (F5): pintar cada bioma e cada forma, pôr e tirar hexágonos, mover a chegada, desfazer e refazer, pintar com raio 10 numa ilha de 20.000 hexágonos, salvar e abrir de novo.

## Tarefas

- [ ] `update_tiles` no `HexMapView` e o repintar da visão de cima.
- [ ] As ferramentas, o tamanho e o contorno.
- [ ] Desfazer e refazer.
- [ ] Rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.

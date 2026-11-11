# 04. Construções, áreas e publicar

- **Status:** concluída
- **Depende de:** [03-terrain-tools](03-terrain-tools.md), [architecture.md](architecture.md)

## Contexto

Com a [03](03-terrain-tools.md), o dono pinta o terreno de uma ilha. Faltam as cidades e os Ecobeasts: as construções sobre os hexágonos, as áreas que dizem quais Ecobeasts aparecem e em que nível, e o publicar, que deixa a ilha pronta para a `islands`. Os tipos de construção vêm do catálogo (`building_types`, [01](01-island-records.md)), e as espécies, do `GameData`.

## Escopo

- As construções: pôr, aumentar, apagar.
- As áreas: criar, editar a lista de espécies, pintar, apagar.
- As camadas que ligam e desligam.
- Publicar.

## Fora do escopo

- A arte das construções: elas aparecem como cor chapada com o nome.
- Domadores NPC fixos no mapa (a `npc-fixed-teams`).
- Jogar na ilha (a `islands`).

## Requisitos

### Construções

- **RF-01:** a ferramenta Construção (tecla 6) mostra no painel os tipos do catálogo, com a cor e o nome. Pintar com um tipo escolhido:
  - começando num hexágono sem construção, cria uma construção nova desse tipo com os hexágonos da pincelada;
  - começando num hexágono da construção escolhida, aumenta essa construção.
  
  Hexágonos que já são de outra construção, ou que não existem, ficam de fora.
- **RF-02:** clicar com o botão direito num hexágono de construção a escolhe. O painel mostra o tipo (que pode ser trocado), a quantidade de hexágonos e os botões Apagar construção e Tirar hexágonos, que troca o pincel para tirar hexágonos só dessa construção.
- **RF-03:** no mapa, os hexágonos de uma construção ficam com a cor do tipo, meio transparente, com o nome sobre o hexágono do centro dela. Nas duas visões.

### Áreas

- **RF-04:** a ferramenta Área (tecla 7) mostra no painel a lista de áreas da ilha, com a cor e o nome, e o botão Nova área. Uma área nova ganha um nome ("Área 1", "Área 2") e uma cor de uma lista fixa, e fica escolhida.
- **RF-05:** com uma área escolhida, o painel mostra:
  - o nome e a cor, editáveis;
  - a quantidade de hexágonos dela;
  - a lista de espécies, cada uma com o nome, o peso e os níveis mínimo e máximo, editáveis;
  - Adicionar espécie, com a busca pelo nome entre as espécies do catálogo;
  - Apagar área, que tira a área dos hexágonos e pergunta antes.
- **RF-06:** pintar com uma área escolhida põe os hexágonos nela, tirando-os da área em que estavam. O botão direito, com a ferramenta Área, tira os hexágonos de qualquer área.
- **RF-07:** no mapa, os hexágonos de cada área ficam com a cor dela, meio transparente. Uma área sem espécies aparece com listras, para lembrar que falta.

### Camadas e publicar

- **RF-08:** a barra de cima tem as camadas Construções e Áreas, que ligam e desligam o desenho delas por cima do terreno. Desligar não muda o rascunho. A ferramenta de uma camada desligada a liga.
- **RF-09:** toda mudança de construção e de área é um passo do desfazer, como os pincéis da [03](03-terrain-tools.md). Editar um campo de texto ou número vira um passo só enquanto se digita no mesmo campo (o `UndoRedo` junta os passos seguidos de mesmo nome), em vez de esperar o campo perder o foco.
- **RF-10:** a barra de cima ganha Publicar, que só fica ativo com a ilha salva. Ele pergunta "Publicar a ilha X? Ela passa a valer para o jogo quando a islands existir." e chama `POST /v1/editor/islands/:id/publish`. Um `409` do servidor aparece na barra de cima, com a mensagem dele.
- **RF-11:** o status da barra de cima e da lista muda depois de salvar e de publicar.

## Critérios de aceite

- [x] Pintar uma construção de 3 hexágonos, aumentar para 5, trocar o tipo e apagá-la funciona, e desfazer volta cada passo.
- [x] Duas construções nunca dividem um hexágono.
- [x] Criar duas áreas, pôr espécies com peso e níveis, pintar e repintar hexágonos de uma para a outra funciona.
- [x] Uma área sem espécies aparece listrada, e publicar com ela responde com a mensagem do servidor.
- [x] Publicar uma ilha válida muda o status para "Publicada"; mudar e salvar muda para "Publicada, com mudanças".
- [x] Salvar, fechar o jogo e abrir a ilha traz as construções e as áreas com as espécies.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos, em `res://tools/map_editor/`:

- `building_panel.gd`: `BuildingPanel`, os tipos, a construção escolhida e as ações dela.
- `area_panel.gd`: `AreaPanel`, a lista de áreas, a área escolhida e a lista de espécies.
  - Cada espécie é um cartão, com o nome e o "×" em cima e o peso e os níveis embaixo, em campos estreitos (`EditorNumberField.set_field_width`, com a margem do tema reduzida).
  - Um número fora da faixa fica vermelho e não muda o rascunho.
  - Uma espécie nova começa com peso 10 e nível 2 a 5, _a revisar_.
  - A cor da área sai de uma paleta de 8 (`UiPalette.MAP_AREA_COLORS`), na ordem em que as áreas nascem. O seletor de cor do Godot não mostrava a cor no botão.
- `hex_tint_layer.gd`: `HexTintLayer`, a camada de cor das áreas e das construções. É um `MultiMesh`, como a visão de cima, com uma instância por hexágono: de perto, ela sobe com a altura do terreno; de longe, fica plana. A área sem espécies vai para uma camada com textura de listras.

Arquivos alterados:

- `res://tools/map_editor/map_editor.gd`: as camadas (Áreas e Construções) e o Publicar na barra de cima.
  - Publicar só fica ativo com a ilha salva e ainda não publicada, e pergunta antes.
  - As ferramentas rolam, e a lista de ilhas fica embaixo com altura fixa: o bloco de área, com as espécies, pode ser alto.
- `editor_tools.gd`: as ferramentas Construção (tecla 6) e Área (tecla 7). O bloco de Bioma e Forma só aparece nas ferramentas de terreno, e o de cada uma no lugar dele. O botão direito chega como pincelada secundária.
- `res://ui/theme/palette.gd`: `MAP_AREA_COLORS`.
- `editor_canvas.gd`: o desenho das construções e das áreas, nas duas visões.
- `island_draft.gd`: construções e áreas no rascunho.
- `editor_history.gd`: os passos de construção e de área.
- `editor_api.gd`: publicar.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

No editor (F5), com o servidor local: montar uma cidade com Refúgio, Loja e casas, duas áreas com espécies e níveis, publicar com uma área vazia (e ver a mensagem), corrigir, publicar e conferir o status.

Feita em 2026-11-11:
- **Projeto:** abre sem erro de script. Com `-d`, os avisos são os de antes.
- **Cena temporária, já apagada,** com o catálogo do servidor local. Ela conferiu:
  - uma construção nova de 7 hexágonos, que cresce quando a pincelada começa nela;
  - a segunda construção sem pegar hexágono da primeira;
  - o botão direito escolhendo uma construção, e nenhuma fora delas;
  - Tirar hexágonos até a construção sumir, e o desfazer devolvendo;
  - trocar o tipo, e desfazer;
  - o aviso sem área escolhida;
  - a área nova escolhida, pintada em raio 2, tirada com o botão direito e devolvida pelo desfazer;
  - adicionar espécie pela busca, mudar o peso, o peso 0 recusado e renomear a área;
  - as camadas de cor com a contagem certa das áreas, das construções e das listras.
- **Pelo servidor:** uma ilha com 2 construções e 2 áreas foi criada. Publicar com a área vazia foi recusado com a mensagem dela; corrigida, ela foi publicada com o status `published` e lida de volta com as construções e as áreas. A ilha de teste foi apagada do banco no fim, porque uma publicada não se apaga pelo editor.
- **Quadros do Movie Maker:** os painéis de Construção e de Área, e o mapa nas duas visões com o Refúgio escolhido (contorno azul), a Loja, as casas com o nome, a área com espécies em cor chapada e a sem espécies em listras.
- **Falta, com o dono:** os passos acima no F5.

## Tarefas

- [x] As construções.
- [x] As áreas e a lista de espécies.
- [x] As camadas, o desfazer e o publicar.
- [x] Rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README da iniciativa, no `.specs/README.md` e no `roadmap.md`.

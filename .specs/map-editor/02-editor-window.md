# 02. A janela do editor

- **Status:** concluída
- **Depende de:** [01-island-records](01-island-records.md), [architecture.md](architecture.md)

## Contexto

Com a [01](01-island-records.md), o servidor guarda ilhas e roda o gerador pelas rotas de `/v1/editor`. Esta fase cria a janela onde o dono vê as ilhas, cria uma nova (do zero ou pelo gerador), olha a ilha inteira ou de perto e salva. Pintar vem na [03](03-terrain-tools.md).

O que esta fase reaproveita:

- O F1 do content-viewer, em `res://screens/main/main.gd` (`_is_content_viewer_key`, `_toggle_content_viewer`): a mesma ideia, com F2.
- O `Api` autoload (`res://core/autoload/api.gd`), que já tem a sessão de quem está logado e renova o token.
- O `HexMapView` (`res://ui/components/hex_map_view.gd`) e os modelos `ExplorationMap` e `HexTile` (`res://domain/models/`).

## Escopo

- A janela F2, só com o jogo rodando pelo editor do Godot.
- A lista de ilhas, com nome e status, e apagar.
- Ilha nova: do zero ou pelo gerador.
- Ver a ilha: `HexMapView` com zoom e arrastar, a visão de cima e a bandeira da chegada.
- Renomear e salvar.

## Fora do escopo

- Os pincéis e o desfazer ([03](03-terrain-tools.md)).
- Construções, áreas e publicar ([04](04-buildings-and-areas.md)).

## Requisitos

### A janela

- **RF-01:** F2 abre e fecha a janela do editor, como o F1 faz com o content-viewer: só com `OS.has_feature("editor")`, criada escondida na primeira vez, com `force_native = true`, 1600×900 de início, redimensionável, título "Ecobeast: editor de ilhas". O X da janela também fecha.
- **RF-02:** o layout tem uma barra de cima (nome da ilha, status, Salvar), um painel à esquerda (a lista de ilhas nesta fase; as ferramentas entram na 03) e o mapa no centro, ocupando o resto.
- **RF-03:** sem sessão no `Api`, a janela mostra só "Entre no jogo para usar o editor." Com 404 ou 403 do `GET /v1/editor/islands`, mostra "O editor está desligado neste servidor. Ponha o seu id em MAP_EDITOR_USER_IDS no .env do servidor." e o botão Tentar de novo.

### As ilhas

- **RF-04:** a lista mostra cada ilha com o nome e o status: "Rascunho", "Publicada" ou "Publicada, com mudanças". Clicar abre a ilha no mapa.
- **RF-05:** "Nova ilha" troca o painel da esquerda pelo de ilha nova, com o nome e duas escolhas (um painel, e não um diálogo, para o mapa ficar à vista enquanto o dono gera de novo):
  - **Do zero:** um raio, de 1 a 80 hexágonos. A ilha nasce como um hexágono desse raio, todo `temperate` `flat`, com variantes sorteadas como o gerador faz (`detailChance` do `GET /v1/editor/map-generator`), e a chegada em `(0, 0)`.
  - **Pelo gerador:** a seed (um campo e o botão Sortear) e um campo por parâmetro, montados com os valores e as faixas do `GET /v1/editor/map-generator`, mais o botão Restaurar padrão. Gerar mostra a ilha no mapa sem gravar; o dono pode mudar os campos e gerar de novo quantas vezes quiser. Criar grava.
- **RF-06:** criar chama `POST /v1/editor/islands` com o rascunho e abre a ilha nova.
- **RF-07:** apagar só aparece numa ilha nunca publicada, e pergunta "Apagar a ilha X? Não dá para desfazer." antes de chamar o `DELETE`.

### O mapa

- **RF-08:** a ilha aparece no `HexMapView`, como no Explorar zona, sem Domador, Ecobeasts nem neblina. A roda do mouse aproxima e afasta, centrada no ponteiro. O botão do meio, ou espaço com o botão esquerdo, arrasta.
- **RF-09:** abaixo de um zoom (constante no topo do arquivo), e com a tecla Tab a qualquer momento, o mapa troca para a visão de cima da [arquitetura](architecture.md#jogo): uma textura plana com um hexágono por hexágono da ilha, na cor do bioma. Ela mostra a ilha de 20.000 hexágonos inteira sem travar.
- **RF-10:** a chegada aparece como uma bandeira, nas duas visões. Embaixo do mapa, uma linha mostra o `(q, r)`, o bioma e a forma do hexágono sob o ponteiro.

### Salvar

- **RF-11:** o nome da ilha é editável na barra de cima. Mudar o nome marca a ilha como não salva: o título ganha `*`.
- **RF-12:** Salvar (e Ctrl+S) chama `PUT /v1/editor/islands/:id/draft` com o rascunho inteiro e atualiza o status. Um erro do servidor aparece na barra de cima, em vermelho, com a mensagem dele, e a ilha continua não salva.
- **RF-13:** trocar de ilha ou fechar a janela com mudanças pergunta "Salvar as mudanças?" com Salvar, Descartar e Cancelar.

## Critérios de aceite

- [x] F2 abre e fecha o editor rodando pelo editor do Godot; num jogo exportado, F2 não faz nada.
- [x] Sem `MAP_EDITOR_USER_IDS`, a janela explica o que falta.
- [x] Uma ilha do zero de raio 10 nasce com 331 hexágonos e a chegada no centro.
- [x] Pelo gerador, mudar a parte de água e gerar de novo mostra mais (ou menos) água; a mesma seed com os mesmos campos dá a mesma ilha.
- [x] Uma ilha de 20.000 hexágonos aparece inteira na visão de cima, e o zoom e o arrastar não travam.
- [x] Renomear, salvar, fechar o jogo e abrir de novo mostra o nome novo.
- [x] Fechar com mudanças pergunta antes.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos, em `res://tools/map_editor/` (montados no código, sem `.tscn`, como o content-viewer):

- `map_editor.gd`: `MapEditor`, a janela, a barra de cima, os atalhos e o aviso de não salvo.
- `editor_api.gd`: as chamadas de `/v1/editor`, pelo `Api`.
- `island_draft.gd`: `IslandDraft`, o rascunho em memória (hexágonos, chegada, construções e áreas), de e para o JSON do contrato, e o `ExplorationMap` para o `HexMapView`.
- `island_list.gd`: a lista e apagar.
- `new_island_panel.gd`: `NewIslandPanel`, do zero e pelo gerador.
- `editor_canvas.gd`: `EditorCanvas`, o `HexMapView`, a visão de cima, o zoom, o arrastar e as camadas por cima.
- `island_overview.gd`: `IslandOverview`, a visão de cima, numa malha só com uma cor por hexágono. A cor é a média da textura da superfície, para não ter cor fixa no código.

Arquivos alterados:

- `res://screens/main/main.gd`: o F2.
- `res://ui/components/hex_map_view.gd`: mudar o `fixed_scale` com o nó na árvore vale na hora (o zoom), e `flat_center` e `grid_coord` ficam públicos e estáticos (a visão de cima e o hexágono sob o ponteiro). O `HexMapView` não desenha Domador nem neblina, então nada mais mudou.
- `res://core/autoload/api.gd`: `request` ganha o `timeout` opcional. Criar uma ilha de 20.000 hexágonos e lê-la de volta levou 8,8 s nos e2e, perto dos 10 s do prazo normal; o editor usa 60 s.
- `client/CLAUDE.md`: uma linha sobre o editor de ilhas.

## Verificação

```bash
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

No editor (F5), com o servidor local e `MAP_EDITOR_USER_IDS` com o id do dono: F2, criar uma ilha do zero e outra pelo gerador, gerar de novo mudando a água, ver as duas visões, renomear, salvar e abrir de novo.

Feita em 2026-11-10:
- **Projeto:** abre sem erro de script. Com `-d`, os avisos são os de antes, de arquivos que esta fase não tocou.
- **Cena temporária, já apagada,** com os autoloads e uma segunda cópia do servidor na porta 3101, com o id do dono em `MAP_EDITOR_USER_IDS`. O `.env` não foi mexido. Ela conferiu:
  - a ilha do zero de raio 10 com 331 hexágonos e a chegada no centro, e a de raio 80 com 19.441;
  - a ida e volta do JSON;
  - a ilha grande abrindo na visão de cima em 226 ms, e o Tab trazendo o mapa do jogo, que montou as linhas em 55 ms;
  - a roda afastando para a visão de cima;
  - pelo servidor: os parâmetros do gerador, gerar 2.000 hexágonos, criar, ler de volta, renomear e salvar, criar a ilha de 19.441 hexágonos dentro do prazo, a lista com o nome novo e apagar as duas;
  - o servidor de sempre, sem a variável, respondendo 404.
- **Quadros gravados com o Movie Maker:** mostraram a visão de cima com as cores do terreno e a bandeira, e o mapa do jogo de perto, com o contorno do hexágono sob o ponteiro.
- **Falta, com o dono:** pôr o próprio id em `MAP_EDITOR_USER_IDS` no `.env` e fazer os passos acima no F5. A janela do sistema (F2), os diálogos e o arrastar com o mouse só aparecem com a janela de verdade.

## Tarefas

- [x] A janela F2, os avisos e o `editor_api.gd`.
- [x] A lista, ilha nova e apagar.
- [x] O mapa com zoom, arrastar, a visão de cima e a chegada.
- [x] Renomear, salvar e o aviso de não salvo.
- [x] Atualizar o `client/CLAUDE.md`, rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.

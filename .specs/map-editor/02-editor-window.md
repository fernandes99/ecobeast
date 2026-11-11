# 02. A janela do editor

- **Status:** aprovada
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
- **RF-05:** "Nova ilha" abre um diálogo com o nome e duas escolhas:
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

- [ ] F2 abre e fecha o editor rodando pelo editor do Godot; num jogo exportado, F2 não faz nada.
- [ ] Sem `MAP_EDITOR_USER_IDS`, a janela explica o que falta.
- [ ] Uma ilha do zero de raio 10 nasce com 331 hexágonos e a chegada no centro.
- [ ] Pelo gerador, mudar a parte de água e gerar de novo mostra mais (ou menos) água; a mesma seed com os mesmos campos dá a mesma ilha.
- [ ] Uma ilha de 20.000 hexágonos aparece inteira na visão de cima, e o zoom e o arrastar não travam.
- [ ] Renomear, salvar, fechar o jogo e abrir de novo mostra o nome novo.
- [ ] Fechar com mudanças pergunta antes.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos, em `res://tools/map_editor/` (montados no código, sem `.tscn`, como o content-viewer):

- `map_editor.gd`: `MapEditor`, a janela, a barra de cima, os atalhos e o aviso de não salvo.
- `editor_api.gd`: as chamadas de `/v1/editor`, pelo `Api`.
- `island_draft.gd`: `IslandDraft`, o rascunho em memória (hexágonos, chegada, construções e áreas), de e para o JSON do contrato, e o `ExplorationMap` para o `HexMapView`.
- `island_list.gd`: a lista e apagar.
- `new_island_dialog.gd`: do zero e pelo gerador.
- `editor_canvas.gd`: o `HexMapView`, a visão de cima, o zoom, o arrastar e as camadas por cima.

Arquivos alterados:

- `res://screens/main/main.gd`: o F2.
- `res://ui/components/hex_map_view.gd`, se precisar: o modo sem Domador e sem neblina, e o zoom livre.
- `client/CLAUDE.md`: uma linha sobre o editor de ilhas.

## Verificação

```bash
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

No editor (F5), com o servidor local e `MAP_EDITOR_USER_IDS` com o id do dono: F2, criar uma ilha do zero e outra pelo gerador, gerar de novo mudando a água, ver as duas visões, renomear, salvar e abrir de novo.

## Tarefas

- [ ] A janela F2, os avisos e o `editor_api.gd`.
- [ ] A lista, ilha nova e apagar.
- [ ] O mapa com zoom, arrastar, a visão de cima e a chegada.
- [ ] Renomear, salvar e o aviso de não salvo.
- [ ] Atualizar o `client/CLAUDE.md`, rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README.

# 04. Construções, áreas e publicar

- **Status:** aprovada
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
- **RF-09:** toda mudança de construção e de área é um passo do desfazer, como os pincéis da [03](03-terrain-tools.md). Editar um campo de texto ou número conta como um passo quando o campo perde o foco.
- **RF-10:** a barra de cima ganha Publicar, que só fica ativo com a ilha salva. Ele pergunta "Publicar a ilha X? Ela passa a valer para o jogo quando a islands existir." e chama `POST /v1/editor/islands/:id/publish`. Um `409` do servidor aparece na barra de cima, com a mensagem dele.
- **RF-11:** o status da barra de cima e da lista muda depois de salvar e de publicar.

## Critérios de aceite

- [ ] Pintar uma construção de 3 hexágonos, aumentar para 5, trocar o tipo e apagá-la funciona, e desfazer volta cada passo.
- [ ] Duas construções nunca dividem um hexágono.
- [ ] Criar duas áreas, pôr espécies com peso e níveis, pintar e repintar hexágonos de uma para a outra funciona.
- [ ] Uma área sem espécies aparece listrada, e publicar com ela responde com a mensagem do servidor.
- [ ] Publicar uma ilha válida muda o status para "Publicada"; mudar e salvar muda para "Publicada, com mudanças".
- [ ] Salvar, fechar o jogo e abrir a ilha traz as construções e as áreas com as espécies.
- [ ] O projeto abre sem erros nem avisos de script.

## Desenho técnico

Arquivos novos, em `res://tools/map_editor/`:

- `building_panel.gd`: os tipos, a construção escolhida e as ações dela.
- `area_panel.gd`: a lista de áreas, a área escolhida e a lista de espécies.

Arquivos alterados:

- `res://tools/map_editor/map_editor.gd`: as camadas e o Publicar.
- `editor_tools.gd`: as ferramentas Construção e Área.
- `editor_canvas.gd`: o desenho das construções e das áreas, nas duas visões.
- `island_draft.gd`: construções e áreas no rascunho.
- `editor_history.gd`: os passos de construção e de área.
- `editor_api.gd`: publicar.

## Verificação

```bash
godot --headless -d --path client --quit-after 60
```

No editor (F5), com o servidor local: montar uma cidade com Refúgio, Loja e casas, duas áreas com espécies e níveis, publicar com uma área vazia (e ver a mensagem), corrigir, publicar e conferir o status.

## Tarefas

- [ ] As construções.
- [ ] As áreas e a lista de espécies.
- [ ] As camadas, o desfazer e o publicar.
- [ ] Rodar a verificação, dizer o que ficou para o dono e mudar o status aqui e no README da iniciativa, no `.specs/README.md` e no `roadmap.md`.

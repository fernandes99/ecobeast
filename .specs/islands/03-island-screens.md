# 03. As telas das ilhas

- **Status:** concluída
- **Depende de:** [02-island-exploration](02-island-exploration.md), [architecture.md](architecture.md)

## Contexto

Com a [02](02-island-exploration.md), o servidor lista as ilhas publicadas e começa uma exploração numa delas, com os Ecobeasts pelas áreas e as construções na resposta. Esta fase leva isso ao jogo: a ação Ilhas no Hub, a tela com a lista e a tela de Explorar zona num mapa de ilha, com o nome dela, as construções no mapa e o Refúgio e a Loja abrindo quando o Domador entra neles.

## Escopo

- A ação Ilhas no Hub.
- A tela `islands`, com a lista.
- A tela `exploration` numa ilha: o nome, as construções e entrar nelas.
- Os modelos e o serviço das rotas novas.
- A `HexTintLayer` em `res://ui/components/`.

## Fora do escopo

- A arte das construções, e a arte da ação Ilhas.
- A Arena e a Casa funcionando.
- Um mapa-múndi desenhado.
- Os Domadores NPC na ilha.

## Requisitos

### Hub

- **RF-01:** o Hub ganha a ação **Ilhas**, depois de Explorar zona, com o subtítulo "Visite as ilhas do mundo.". A cor fica em `UiPalette.ACTION_COLORS[&"islands"]`, um azul de mar (`#2C8FA8` e `#0B3A47`, _a revisar_). A arte é `res://assets/ui/actions/islands.webp` quando existir; até lá, a de Explorar zona.
- **RF-02:** com 9 ações na grade de 4 colunas, a última linha fica com uma ação só, alinhada à esquerda, como a grade faz hoje.
- **RF-03:** tocar em Ilhas abre a tela `islands`.

### A lista

- **RF-04:** a tela `islands` tem o título "Ilhas" e o botão de voltar, que leva ao Hub. Ela chama `Session.list_islands()` e mostra "Carregando ilhas..." até a resposta.
- **RF-05:** cada ilha é um cartão tocável, com o nome, na ordem da resposta. Sem nenhuma, a tela mostra "Nenhuma ilha publicada ainda.". Com erro, mostra a mensagem dele, em vermelho.
- **RF-06:** tocar numa ilha abre `exploration` com `{"island_id": id}`, por cima da lista: voltar do mapa leva de volta à lista.

### A ilha

- **RF-07:** a tela `exploration` recebe `island_id` em `setup(params)`. Sem ele, ou com 0, ela faz o mapa sorteado de hoje, sem mudança. Com ele, chama `Session.start_exploration(island_id)` e mostra "Chegando na ilha..." (_a revisar_) até a resposta.
- **RF-08:** numa ilha, o nome dela aparece no topo do mapa, num `NamePlatePanel` com `TitleLabel`. No mapa sorteado, ele fica escondido.
- **RF-09:** cada hexágono de construção fica com a cor do tipo (`color_hex` do catálogo), meio transparente (alfa 0,45, _a revisar_), na altura do terreno (colina e montanha incluídas), por cima dele e por baixo das decorações, do Domador e dos Ecobeasts. As árvores e pedras de um hexágono de construção continuam lá, como no editor. O destaque do hexágono atual fica um pouco mais fraco sob a cor, porque é desenhado no terreno.
- **RF-10:** o nome do tipo aparece sobre o hexágono do meio de cada construção (o mais perto do centro dela, como no editor), em texto da interface (tamanho 30, _a revisar_), legível e com contorno escuro. Ele acompanha o mapa quando o Domador anda.
- **RF-11:** quando um passo termina num hexágono de construção, vindo de um hexágono fora dela, a tela abre a tela do tipo, pelo `slug` do catálogo: `refuge` abre `heal_station` e `shop` abre `shop`, por cima do mapa (`Router.push`). Outros tipos não abrem nada.
- **RF-12:** andar entre dois hexágonos da mesma construção não abre a tela de novo. Chegar na ilha já dentro de uma construção também não abre: a chegada não pode ser em construção (map-editor/01).
- **RF-13:** fechar a tela da construção volta para o mapa, no mesmo hexágono, com o mapa, os Ecobeasts e a posição como estavam. A música do mapa segue tocando enquanto a tela da construção está aberta.
- **RF-14:** Procurar, a Mochila, a luta, a captura e o menu de depuração funcionam na ilha como no mapa sorteado. Num hexágono sem Ecobeast, Procurar mostra "Nada por aqui.".

## Critérios de aceite

- [x] O Hub mostra Ilhas depois de Explorar zona, com a cor e a arte de explorar.
- [ ] Sem ilha publicada, a lista mostra "Nenhuma ilha publicada ainda."; com duas, mostra as duas, e voltar leva ao Hub.
- [x] Tocar numa ilha abre o mapa dela, com o nome no topo, o Domador na chegada e as construções coloridas com o nome.
- [x] O Domador e os Ecobeasts aparecem por cima da cor das construções.
- [x] Entrar no Refúgio abre o Refúgio; curar e voltar deixa o Domador no mesmo hexágono. Andar dentro dele não abre de novo; sair e entrar abre.
- [x] Entrar na Loja abre a Loja; entrar na Arena ou numa Casa não abre nada.
- [ ] Procurar num hexágono com Ecobeast da área abre a luta, e ao voltar ele sumiu do mapa.
- [x] Explorar zona continua sorteando um mapa novo, sem nome no topo e sem construções.
- [x] O projeto abre sem erros nem avisos de script, e o jogo abre com o servidor no ar.

## Desenho técnico

Arquivos novos:

- `res://screens/islands/islands_screen.tscn` e `.gd`: a lista, dentro de um `SafeArea`, com os cartões num `ScrollContainer`. Cada cartão é um `TapPanel` com o nome em `BoldLabel`.
- `res://domain/models/island_summary.gd`: `IslandSummary` (`id`, `name`, `from_dict`).
- `res://domain/models/map_building.gd`: `MapBuilding` (`building_type_id`, `tiles: Array[Vector2i]`, `from_dict`).
- `res://ui/components/building_names_layer.gd`: `BuildingNamesLayer`, um `Control` por cima do mapa, com `mouse_filter = IGNORE` para não tirar os toques do `MapArea`, que desenha o nome de cada construção. O texto fica no tamanho da interface, e não escalado com a arte do mapa. A tela passa a posição e a escala do `HexMapView` para ele sempre que elas mudam: ao andar (`_move_map`) e no mapa inteiro da depuração (`_toggle_whole_map`).

Arquivos movidos:

- `res://tools/map_editor/hex_tint_layer.gd` (e o `.uid`) para `res://ui/components/hex_tint_layer.gd`. Hoje ela reserva `IslandDraft.MAX_TILES` instâncias, e o `IslandDraft` é do editor: o `_init` passa a receber a capacidade (`_init(striped := false, capacity := 0)`), o editor passa `IslandDraft.MAX_TILES`, e o jogo passa a quantidade de hexágonos de construção da linha. O editor continua usando a classe pelo `class_name`.

Arquivos alterados:

- `res://screens/hub/hub_screen.gd`: a ação em `ACTIONS`, com `"art": &"explore"`, e a entrada "Ilhas" na tabela de destinos.
- `res://ui/components/action_tile.gd`: `setup` aceita o id da arte (opcional, o próprio id por padrão), usado quando `assets/ui/actions/<id>.webp` não existe.
- `res://ui/theme/palette.gd`: `ACTION_COLORS[&"islands"]`.
- `res://core/autoload/router.gd`: `&"islands"` em `SCREENS`.
- `res://core/services/game_service.gd` e `api_game_service.gd`: `list_islands()` (`GET /v1/me/islands`, um `Array[IslandSummary]`) e `start_exploration(island_id: int = 0)`, que manda `{"island_id": id}` quando o id é maior que 0.
- `res://core/autoload/session.gd`: `list_islands()` e `start_exploration(island_id: int = 0)`.
- `res://domain/models/exploration_map.gd`: `island_id` (0 no mapa sorteado), `island_name`, `buildings: Array[MapBuilding]` e `building_at(coord) -> int`, o índice da construção do hexágono ou -1, por um dicionário montado no `from_dict`.
- `res://ui/components/hex_map_view.gd`: `set_ground_overlay(node, row)`, que põe um filho logo depois do terreno de uma linha e antes das decorações de trás dela, como o `set_actor_row` faz para os atores. Assim a linha seguinte e os atores ficam por cima.
- `res://screens/exploration/exploration_screen.gd` e `.tscn`:
  - `setup(params)` com o `island_id`;
  - o nome no topo;
  - uma `HexTintLayer` por linha com construção, com `set_raised(true)` (sem ele, a cor fica plana e some sob as colinas), posta com `set_ground_overlay` depois do `set_map`, que monta as linhas;
  - o `BuildingNamesLayer`;
  - no fim do `_step_to`, entrar na construção, comparando `building_at` do hexágono de antes e do de agora.

Documentos:

- `client/CLAUDE.md`: a `HexTintLayer` em `ui/components/`, a tela `islands` e a regra de entrar numa construção.
- `TELAS.md`: sem mudança. Ele descreve as 16 telas do protótipo, e a tela `islands` não é uma delas.

## Verificação

```bash
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
```

Uma cena temporária em `client/zz_tmp_check/`, apagada depois, com o servidor local e uma ilha publicada de teste: abrir a lista, entrar na ilha, conferir as camadas das construções, andar até o Refúgio e ver a tela aberta, voltar e conferir a posição. Quadros do Movie Maker da lista e do mapa da ilha.

No jogo (F5), com o dono: entrar na ilha que ele publicou, andar pela cidade, entrar no Refúgio e na Loja, Procurar numa área e lutar.

Feita em 2026-11-11:
- **Projeto:** abre sem erro de script. Com `-d`, os avisos são os de antes.
- **Cena temporária, já apagada, com o servidor local e a ilha do dono (id 85, "Ilha nova"):** 46 conferências, todas certas.
  - O Hub tem 9 ações, com Ilhas depois de Explorar zona e a arte dela.
  - A lista mostra "Carregando ilhas..." e depois a ilha; tocar nela abre o mapa com "Chegando na ilha...".
  - No mapa: o nome no topo, um nome por construção (4), uma camada de cor por linha com construção (6 linhas, 27 hexágonos), cada camada entre o terreno e as decorações da linha.
  - Entrar no Refúgio abre `heal_station` e na Loja abre `shop`, com o mapa escondido por baixo e a música dele tocando; voltar deixa o Domador no mesmo hexágono. A Casa e a Arena não abrem nada. Andar dentro da construção não abre de novo; sair e entrar abre.
  - Procurar num hexágono vazio mostra "Nada por aqui.". O mapa veio com 20 Ecobeasts e nenhum Domador NPC.
  - Explorar zona continua com "Gerando mapa...", sem nome no topo, sem nomes e sem camadas.
- **Capturas da tela:** o Hub, a lista, o mapa da ilha ao lado do Refúgio e o mapa inteiro da depuração, com os 4 nomes.
- **Não conferido aqui:** a lista vazia e a com duas ilhas (o banco tem uma só publicada), e a luta a partir de Procurar numa área, que não mudou nesta fase.
- **Para o dono:** no F5, Hub, Ilhas, "Ilha nova": andar até a cidade, entrar no Refúgio e na Loja, Procurar numa área e lutar. A cor de Ilhas, o alfa das construções, o tamanho do nome e o texto "Chegando na ilha..." estão _a revisar_.

## Tarefas

- [x] A `HexTintLayer` em `ui/components/`.
- [x] Os modelos, o serviço e o `Session`.
- [x] A ação no Hub e a tela `islands`.
- [x] A ilha na tela de exploração: o nome, as construções, os nomes e entrar nelas.
- [x] Rodar a verificação, dizer o que ficou para o dono e mudar o status aqui, no README da iniciativa e no `roadmap.md`.

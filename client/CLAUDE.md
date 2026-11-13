# Cliente Godot

O jogo, em **Godot 4.7 com GDScript**. Esta pasta é o projeto Godot: `res://` aponta para `client/`. As regras gerais (specs, vocabulário, servidor como autoridade) estão no `CLAUDE.md` da raiz.

## Estrutura

```
res://
  core/autoload/   GameData (catálogo), Router (telas), Api (HTTP e sessão), Session (jogador e login), Music (música, no canal Music), BattleIntro (transição da luta)
  core/auth/       AuthSession (a sessão no aparelho) e AuthService (login pelo navegador)
  core/data/       leitura do catálogo (da API) e validação
  core/net/        ApiResponse
  core/services/   Result, GameService e ApiGameService (as rotas do jogador)
  domain/models/   classes de dados (RefCounted, sem Node)
  ui/theme/        tema, paleta e fontes
  ui/components/   componentes reutilizáveis (.tscn + .gd)
  ui/icons/        ícones SVG da interface, brancos (a moeda é colorida), tingidos pelo tema ou por modulate
  screens/         uma pasta por tela; main/ é a cena raiz
  assets/          sprites e sons (creatures/<slug>/front.png); music/ tem as músicas e o compose.py que as gera
```

Detalhes em `.specs/foundation/architecture.md`.

## Regras do cliente

- **Camadas:** `domain/` não usa Node, autoload, arquivo nem `get_tree()` — são só classes de dados; as regras moram no servidor. Telas leem o catálogo pelo `GameData` e o estado do jogador pelo `Session`; nunca abrem JSON nem `user://`.
- **Telas não calculam regras.** HP máximo, técnicas, recompensas vêm prontos dos serviços.
- **Serviços** são chamados com `await` e devolvem `Result` (`ok`, `data`, `error`). Telas só falam com o `Session`, nunca com `GameService`; com `ok` falso, mostram `error` e deixam o jogador onde está.
- **Rede e sessão:** chamadas ao servidor passam pelo `Api.request` (só a `HttpDataSource` tem o seu próprio `HTTPRequest`), com `authenticated = true` nas rotas do jogador. O `Api` guarda a sessão em `user://session.json`, renova sozinho e emite `session_lost` quando o servidor a recusa. O login acontece só no navegador: nenhuma chave do Supabase entra no cliente.
- **Dados de design** (o catálogo) moram no banco do servidor. O jogo baixa tudo no boot por `GET /v1/catalog` (`HttpDataSource`), e as tabelas estão espelhadas em `core/data/catalog_schema.gd`. O jogo é só online: sem resposta do servidor, ele não entra.
- **GDScript tipado:** declaração sem tipo é erro de script no projeto. Arquivos em `snake_case`, classes em `PascalCase`, nós acessados por `%NomeUnico`.
- Textos do jogador direto nas cenas e scripts (sem `tr`).
- **Telas novas:** registrar o id em `Router.SCREENS` (`core/autoload/router.gd`); parâmetros chegam em `setup(params)` antes do `_ready`; o conteúdo fica dentro de um `SafeArea`; painel aberto por cima da tela se fecha no voltar via `handle_back() -> bool`. Componentes com `set_*()` aceitam ser chamados antes de entrar na árvore.
- **Visual:** paleta escura de `.specs/visual-theme/README.md`. Fontes e estilos vêm do tema (`ui/theme/main_theme.tres`): variações de texto `TitleLabel` (Nunito Black), `LogoLabel`, `SecondaryLabel`, `BoldLabel` e `DangerLabel`; botões `OutlineButton`, `DangerButton`, `TabButton` e `CurrentTabButton` (abas com ícone em cima); botão `IconButton`; painéis `AvatarPanel`, `PlayerPanel`, `CoinChip`, `SectionPanel`, `TabBarPanel`, `ElementPill`, `BannerPanel` e `NamePlatePanel`; barras `HpBar` e `XpBar`. Um painel inteiro tocável estende `TapPanel`. O hexágono de atributos é o `StatRadar`. A imagem de um item é o `ItemIcon`. O anel da captura é o `CaptureRing`. Ilustrações entram por arquivo, sem código: `assets/creatures/<slug>/front.png`, `assets/items/<slug>.png`, `assets/backgrounds/hub.png`, `assets/backgrounds/starter_select.webp`, `assets/ui/logo.png`, `assets/ui/elements/<slug>/` e `assets/ui/actions/<ação>.webp` (tamanhos em `.specs/visual-theme/README.md`). O Domador do mapa, o do jogador e os NPC, é o `TamerSprite`, com as folhas `assets/tamer/idle.png` e `run.png`. As folhas animadas de um Ecobeast são `assets/creatures/<slug>/idle.png` e `walk.png`, no mesmo formato e na escala do Domador (1,70 m são 25 pixels, então a altura vem de `height_m`), geradas pelo `sprites.py` da pasta dele com a skill `creature-sprites`, e o spawn do menu "Debug" do mapa mostra quem tem as duas, com o `CreatureSprite`. As texturas do mapa ficam em `assets/terrain/surfaces/<superfície>.png`, emendam nas quatro bordas e são desenhadas pelo `HexMapView`, sempre em pixels inteiros. Plantas e rochas ficam na folha `assets/terrain/decorations/decorations.png`, escolhidas por `HexDecorations`, com o vento no shader `ui/components/plant_wind.gdshader`, e os arremates entre biomas e o escorrido nos paredões nas folhas `assets/terrain/transitions/transitions.png` e `drips.png`, escolhidos por `HexTransitions` (`.specs/wild-battle/architecture.md`). Nenhuma cena ou script tem cor fixa: as da interface vêm de `UiPalette`, as de Elemento do catálogo, e um estilo que precisa mudar de cor por instância é copiado do tema (`duplicate`) antes de pintar. As cores do tema repetem as de `UiPalette`: mude as duas juntas.
- **Ecobeasts do mapa:** o servidor sorteia e manda só `id`, `species_id` e a posição (`MapCreature`). A tela de exploração mantém nós só para quem está a até `CREATURE_RADIUS` hexágonos do Domador, e o `CreatureSprite` reaproveita as animações por espécie. O inimigo sai do hexágono do Domador, e a tela tira o enfrentado do mapa ao voltar da luta (`.specs/biome-encounters/`).
- **Domadores NPC do mapa:** o servidor manda `id`, posição, `name_id` e `greeting_id` (`MapTamer`); o nome e a fala vêm do `GameData`. Cada um perto do jogador é um `TamerSprite` passeando no hexágono; o passeio dos Ecobeasts e dos Domadores mora no `WanderingSprite`. Chegar no hexágono de um trava o mapa e mostra a fala no `TamerGreetingPanel`, e tocar nela abre a luta contra ele, sem Fugir nem Esferas; perder leva ao Hub (`.specs/npc-tamers/`).
- **Bestiário:** o servidor manda só as espécies conhecidas, com capturado ou não (`Codex`), e a tela `codex` cruza com o catálogo: capturada colorida, vista em sombra (`CreaturePortrait.set_silhouette`, com o shader `ui/components/silhouette.gdshader`) e nunca vista como "???". O habitat e a linha evolutiva vêm do `GameData` (`get_habitat_names`, `get_evolution_line`). Na luta, o `CodexRegisteredOverlay` mostra "Novo registro no Bestiário!" para cada espécie de `registered_species_ids`, depois da captura e da Evolução (`.specs/codex/`).
- **Entrar na luta:** toda abertura da tela `board_battle` passa antes por `await BattleIntro.cover(foco, opponent)`, o zoom pixelado (shader `ui/components/pixel_zoom.gdshader` sobre a tela, numa camada acima de tudo). Se ele devolver `false`, não abra a luta. A tela da luta chama `BattleIntro.reveal()` quando o tabuleiro está montado ou quando mostra um erro. Com a tela coberta, o `Router.back` não faz nada, e abrir outra tela revela sozinho (sinal `Router.screen_changed`) (`.specs/battle-intro/`).
- **Música:** o autoload `Music` toca no canal `Music` (`default_bus_layout.tres`, a −6 dB). O `BattleIntro.cover` começa a música da luta (`play_battle(&"wild")` ou `&"tamer"`), e a tela da luta troca pelo toque de vitória (`play_victory`) ou faz sumir aos poucos (`fade_out`). O mapa de Explorar zona toca a sua (`play_explore`), que volta entrando aos poucos depois da luta e some ao sair para o Hub. As músicas são geradas pelo `assets/music/compose.py` (Python e `ffmpeg`): mude a partitura lá e rode de novo; o loop das lutas fica no `.import` (`loop=true`) (`.specs/battle-intro/`).
- **Editor de ilhas:** F2, só com o jogo rodando pelo editor do Godot, abre o `MapEditor` (`tools/map_editor/`), uma janela do sistema 16:9 que cria e salva as ilhas fixas pelas rotas de `/v1/editor`. Elas só respondem a quem está em `MAP_EDITOR_USER_IDS` no `.env` do servidor. O mapa é o `HexMapView`, com zoom (`fixed_scale`) e linhas em pedaços de 16 colunas (`chunk_columns`), para pintar refazer só os pedaços tocados (`update_tiles`); de longe, ele dá lugar à visão de cima (`IslandOverview`, um `MultiMesh`), porque montar a ilha inteira trava. Os pincéis ficam em `EditorTools` (com `ObjectPanel`, `ActionPanel` e `AreaPanel`), escolhidos numa coluna de ícones (`tool_column`, com os SVGs de `tools/map_editor/icons/`), e o painel tem largura fixa; no topo, Ilhas e Camadas abrem `PopupPanel`s, e o objeto escolhido ganha a `ObjectBar` no mapa e as teclas ← →, M, Delete e Esc (`.specs/map-editor/05-editor-ux.md`); o terreno é bioma e altura (`HexTile.biome` e `height`, de 0 a 4), pintados em ferramentas separadas (`.specs/terrain-height/`), mais o chão (`HexTile.ground`, trilha ou piso, desenhado por `HexGrounds` com o shader `hex_grounds.gdshader`, o material das linhas de terreno) e os objetos (`MapObject`, desenhados por `MapObjectSprite` e postos no `HexMapView` com `set_objects`) (`.specs/island-villages/`), e o desfazer em `EditorHistory`, sobre o `UndoRedo`. As cores das áreas e das ações por cima do mapa são `HexTintLayer`s (`ui/components/`, que o jogo também usa). Nenhuma tela do jogo depende dessa pasta (`.specs/map-editor/`).
- **Ilhas:** a ação Ilhas do Hub abre a tela `islands`, com as ilhas publicadas (`Session.list_islands()`), e tocar numa abre `exploration` com `{"island_id": id}`. A tela de exploração é a mesma do mapa sorteado: numa ilha, ela mostra o nome no topo, pinta cada ação com a cor do tipo (uma `HexTintLayer` por linha, posta com `HexMapView.set_ground_overlay`, por cima do terreno e por baixo das decorações e dos atores) e escreve o nome do tipo com o `BuildingNamesLayer`. Quando um passo termina numa ação, vindo de fora dela, a tela abre a tela do tipo pelo `slug` (`ACTION_SCREENS`: `refuge` e `shop`), com `Router.push`; os outros tipos não abrem nada. O Domador não entra num hexágono bloqueado (`ExplorationMap.is_blocked`); tocar num bloqueado com ação, ao lado dele, executa a ação, e o toque na arte de um objeto vale para o hexágono dele ao lado do Domador (`.specs/islands/`, `.specs/island-villages/`). Tocar num hexágono distante anda o caminho mais curto até ele (`ExplorationMap.path_to_any`), ou até o lado dele, se for bloqueado, executando a ação na chegada; um Domador NPC no caminho para a caminhada, e um toque no meio troca o destino. O caminho que falta aparece no chão, com pontos e um anel no destino (`RouteMark`) (`.specs/wild-battle/14-tap-to-walk.md`). A arte dos objetos fica em `assets/map_objects/<slug>/<variante>.png` (um objeto animado tem os quadros lado a lado, e o `MapObjectSprite` anda neles na velocidade de `FRAME_RATES`; a Vegetação, `plants`, não tem sprite: as plantas dela são as do `HexDecorations`, com o vento, e o PNG é só a prévia do editor; a Cerca, `fence`, se liga às vizinhas na mesma altura e é montada pelo `HexFences` com as peças de `fence/parts_<variante>.png`) e a do chão em `assets/terrain/grounds/<slug>.png`, geradas por `make_objects.gd` (a partir do pacote Sunnyside World, que fica fora do repositório e é passado como argumento), `make_town.gd` (a arte da cidade, só por código, que segue `.specs/town-art/style-guide.md`: hoje os prédios do Refúgio, da Loja e da Arena e as casas da cidade, tipos novos ao lado dos de antes) e `make_grounds.gd`.
- Versione os arquivos `.uid` que o Godot cria ao lado dos scripts; `.godot/` fica fora do git.

## Editando dados do catálogo

- O catálogo se edita no banco, pelo Table Editor do Supabase (schema `ecobeasts`). A mudança chega ao jogo na próxima abertura, em até 1 minuto (o servidor guarda o catálogo montado por 60 s).
- As colunas, tipos, chaves e FKs estão em `core/data/catalog_schema.gd`, espelho de `.specs/game-data/architecture.md` e de `server/prisma/schema.prisma`. Tabela ou coluna nova muda os três no mesmo commit, com a migration.
- Ids são estáveis: nunca renumere nem reaproveite.
- O `CatalogValidator` confere o catálogo baixado a cada abertura. Um erro aparece na tela "Erro nos dados do jogo", com a lista, e no console.
- `server/prisma/seed-data/` é só a foto da carga inicial do banco; não é editada.
- A última cópia baixada fica em `user://catalog_cache.json` (no Windows, `%APPDATA%\Godot\app_userdata\Ecobeast\`) e serve só para o servidor responder `304` quando nada mudou.

## Comandos

O executável do Godot está em `C:\Godot\` (use a versão `_console` na linha de comando). Da raiz do repositório:

```bash
# o servidor precisa estar no ar: o jogo baixa o catálogo dele
cd server && npm run start:dev

# rodar o jogo sem janela por alguns frames (confere erros de script)
godot --headless --path client --quit-after 30

# o mesmo, mostrando também os avisos de script (-d liga o depurador)
godot --headless -d --path client --quit-after 60
```

O endereço da API é a configuração `ecobeast/api/base_url` do `project.godot` (padrão `http://localhost:3100`). No editor do Godot, abra (ou importe) o arquivo `client/project.godot`.

Depois de criar uma classe nova (`class_name`), abra o projeto no editor uma vez (ou rode `godot --headless --path client --editor --quit`) para o cache de classes ser atualizado; o modo `--script` depende dele.

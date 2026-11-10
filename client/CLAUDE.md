# Cliente Godot

O jogo, em **Godot 4.7 com GDScript**. Esta pasta é o projeto Godot: `res://` aponta para `client/`. As regras gerais (specs, vocabulário, servidor como autoridade) estão no `CLAUDE.md` da raiz.

## Estrutura

```
res://
  core/autoload/   GameData (catálogo), Router (telas), Api (HTTP e sessão), Session (jogador e login), BattleIntro (transição da luta)
  core/auth/       AuthSession (a sessão no aparelho) e AuthService (login pelo navegador)
  core/data/       leitura do catálogo (da API) e validação
  core/net/        ApiResponse
  core/services/   Result, GameService e ApiGameService (as rotas do jogador)
  domain/models/   classes de dados (RefCounted, sem Node)
  ui/theme/        tema, paleta e fontes
  ui/components/   componentes reutilizáveis (.tscn + .gd)
  ui/icons/        ícones SVG da interface, brancos (a moeda é colorida), tingidos pelo tema ou por modulate
  screens/         uma pasta por tela; main/ é a cena raiz
  assets/          sprites e sons (creatures/<slug>/front.png)
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

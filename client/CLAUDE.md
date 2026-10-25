# Cliente Godot

O jogo, em **Godot 4.7 com GDScript**. Esta pasta é o projeto Godot: `res://` aponta para `client/`. As regras gerais (specs, vocabulário, servidor como autoridade) estão no `CLAUDE.md` da raiz.

## Estrutura

```
res://
  core/autoload/   GameData (catálogo), Router (telas), Session (jogador)
  core/data/       leitura do catálogo (da API) e validação
  core/services/   Result, GameService, PlayerRepository e as implementações locais
  core/util/       utilitários que usam a API do motor (ex.: Uuid)
  domain/models/   classes de dados (RefCounted, sem Node)
  domain/rules/    regras puras: stats, XP, criação de criatura
  ui/theme/        tema, paleta e fontes
  ui/components/   componentes reutilizáveis (.tscn + .gd)
  screens/         uma pasta por tela; main/ é a cena raiz
  assets/          sprites e sons (creatures/<slug>/front.png)
```

Detalhes em `.specs/foundation/architecture.md`.

## Regras do cliente

- **Camadas:** `domain/` não usa Node, autoload, arquivo nem `get_tree()` — recebe tudo por parâmetro, porque será reescrito no servidor. Telas leem o catálogo pelo `GameData` e o estado do jogador pelo `Session`; nunca abrem JSON nem `user://`.
- **Telas não calculam regras.** HP máximo, técnicas, recompensas vêm prontos dos serviços.
- **Serviços** são chamados com `await` e devolvem `Result` (`ok`, `data`, `error`). Telas só falam com o `Session`, nunca com `GameService` ou `PlayerRepository`; com `ok` falso, mostram `error` e deixam o jogador onde está.
- **Dados de design** (o catálogo) moram no banco do servidor. O jogo baixa tudo no boot por `GET /v1/catalog` (`HttpDataSource`), e as tabelas estão espelhadas em `core/data/catalog_schema.gd`. O jogo é só online: sem resposta do servidor, ele não entra.
- **GDScript tipado:** declaração sem tipo é erro de script no projeto. Arquivos em `snake_case`, classes em `PascalCase`, nós acessados por `%NomeUnico`.
- Textos do jogador direto nas cenas e scripts (sem `tr`).
- **Telas novas:** registrar o id em `Router.SCREENS` (`core/autoload/router.gd`); parâmetros chegam em `setup(params)` antes do `_ready`; o conteúdo fica dentro de um `SafeArea`; painel aberto por cima da tela se fecha no voltar via `handle_back() -> bool`. Componentes com `set_*()` aceitam ser chamados antes de entrar na árvore.
- **Visual:** paleta escura de `.specs/visual-theme/README.md`. Fontes e estilos vêm do tema (`ui/theme/main_theme.tres`): variações de texto `TitleLabel` (Nunito Black), `LogoLabel`, `SecondaryLabel`, `BoldLabel` e `DangerLabel`; botões `OutlineButton`, `DangerButton`, `ActionButton`, `TabButton` e `CurrentTabButton`; painéis `AvatarPanel`, `CoinDot`, `TabBarPanel` e `ElementPill`; barra `HpBar`. Um painel inteiro tocável estende `TapPanel`. Nenhuma cena ou script tem cor fixa: as da interface vêm de `UiPalette`, as de Elemento do catálogo, e um estilo que precisa mudar de cor por instância é copiado do tema (`duplicate`) antes de pintar. As cores do tema repetem as de `UiPalette`: mude as duas juntas.
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
```

O endereço da API é a configuração `ecobeast/api/base_url` do `project.godot` (padrão `http://localhost:3100`). No editor do Godot, abra (ou importe) o arquivo `client/project.godot`.

Depois de criar uma classe nova (`class_name`), abra o projeto no editor uma vez (ou rode `godot --headless --path client --editor --quit`) para o cache de classes ser atualizado; o modo `--script` depende dele.

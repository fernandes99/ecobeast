# Cliente Godot

O jogo, em **Godot 4.7 com GDScript**. Esta pasta é o projeto Godot: `res://` aponta para `client/`. As regras gerais (specs, vocabulário, servidor como autoridade) estão no `CLAUDE.md` da raiz.

## Estrutura

```
res://
  core/autoload/   GameData (catálogo), Router (telas), Session (jogador)
  core/data/       leitura e validação do catálogo
  core/services/   Result, GameService, PlayerRepository e as implementações locais
  core/util/       utilitários que usam a API do motor (ex.: Uuid)
  domain/models/   classes de dados (RefCounted, sem Node)
  domain/rules/    regras puras: stats, XP, criação de criatura
  ui/theme/        tema, paleta e fontes
  ui/components/   componentes reutilizáveis (.tscn + .gd)
  screens/         uma pasta por tela; main/ é a cena raiz
  data/            catálogo: um arquivo JSON por tabela
  assets/          sprites e sons (creatures/<slug>/front.png)
  tools/           validate_data.gd
```

Detalhes em `.specs/foundation/architecture.md`.

## Regras do cliente

- **Camadas:** `domain/` não usa Node, autoload, arquivo nem `get_tree()` — recebe tudo por parâmetro, porque será reescrito no servidor. Telas leem o catálogo pelo `GameData` e o estado do jogador pelo `Session`; nunca abrem JSON nem `user://`.
- **Telas não calculam regras.** HP máximo, técnicas, recompensas vêm prontos dos serviços.
- **Serviços** são chamados com `await` e devolvem `Result` (`ok`, `data`, `error`). Telas só falam com o `Session`, nunca com `GameService` ou `PlayerRepository`; com `ok` falso, mostram `error` e deixam o jogador onde está.
- **Dados de design** ficam em `res://data/<tabela>.json`, espelhados em `core/data/catalog_schema.gd`.
- **GDScript tipado:** declaração sem tipo é erro de script no projeto. Arquivos em `snake_case`, classes em `PascalCase`, nós acessados por `%NomeUnico`.
- Textos do jogador direto nas cenas e scripts (sem `tr`).
- **Telas novas:** registrar o id em `Router.SCREENS` (`core/autoload/router.gd`); parâmetros chegam em `setup(params)` antes do `_ready`; o conteúdo fica dentro de um `SafeArea`; painel aberto por cima da tela se fecha no voltar via `handle_back() -> bool`. Componentes com `set_*()` aceitam ser chamados antes de entrar na árvore.
- **Visual:** fontes e estilos vêm do tema (`ui/theme/main_theme.tres`, variações `TitleLabel`, `SecondaryLabel`, `BoldLabel` e os botões `OutlineButton`, `DangerButton`, `ActionButton`, `TabButton`, `CurrentTabButton`); um painel inteiro tocável estende `TapPanel`; cores da interface de `UiPalette`, cores de Elemento do catálogo. As cores do tema repetem as de `UiPalette`: mude as duas juntas.
- Versione os arquivos `.uid` que o Godot cria ao lado dos scripts; `.godot/` fica fora do git.

## Editando dados do catálogo

- Cada arquivo de `res://data/` é uma tabela: um array JSON de linhas, todas com exatamente as colunas da tabela (use `null`, nunca omita a coluna).
- As colunas, tipos, chaves e FKs estão em `core/data/catalog_schema.gd` (espelho de `.specs/game-data/architecture.md`). Tabela ou coluna nova muda os dois no mesmo commit.
- Ids são estáveis: nunca renumere nem reaproveite.
- Rode o validador antes de commitar qualquer mudança em `res://data/`. Depois de criar uma classe nova (`class_name`), abra o projeto no editor uma vez (ou rode `godot --headless --path client --editor --quit`) para o cache de classes ser atualizado; o modo `--script` depende dele.

## Comandos

O executável do Godot está em `C:\Godot\` (use a versão `_console` na linha de comando). Da raiz do repositório:

```bash
# rodar o jogo sem janela por alguns frames (confere erros de script)
godot --headless --path client --quit-after 30

# validar o catálogo
godot --headless --path client --script res://tools/validate_data.gd
```

No editor do Godot, abra (ou importe) o arquivo `client/project.godot`.

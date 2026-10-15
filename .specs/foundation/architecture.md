# Arquitetura

O desenho do projeto inteiro. As outras iniciativas acrescentam arquivos nesta árvore e seguem estas regras.

## Pastas

```
res://
  project.godot
  core/
    autoload/
      game_data.gd             GameData: catálogo carregado, consultas tipadas         (game-data/01)
      router.gd                Router: navegação em pilha                              (foundation/02)
      session.gd               Session: jogador atual e serviços                       (onboarding/01)
    data/
      data_source.gd           DataSource (@abstract): de onde vêm as tabelas          (game-data/01)
      static_json_data_source.gd  lê res://data/*.json                                 (game-data/01)
      catalog_schema.gd        tabelas, chaves, FKs e colunas obrigatórias             (game-data/01)
      catalog_validator.gd     confere o catálogo contra o schema                      (game-data/01)
      catalog.gd               índices e consultas sobre as tabelas                    (game-data/01)
    services/
      result.gd                Result: ok, data, error                                 (onboarding/01)
      game_service.gd          GameService (@abstract): ações do jogador               (onboarding/01)
      local_game_service.gd    implementação local do MVP                              (onboarding/01)
      player_repository.gd     PlayerRepository (@abstract): guardar o jogador         (onboarding/01)
      local_player_repository.gd  user://save.json                                     (onboarding/01)
    util/
      uuid.gd                  Uuid.v4()                                               (onboarding/01)
  domain/
    models/                    classes de dados (RefCounted, sem Node)
      element.gd  creature_species.gd  skill.gd  skill_effect.gd  creature_trait.gd
      temperament.gd  growth_rate.gd  learnset_entry.gd  evolution_rule.gd
      stat_block.gd                                                                    (game-data/01)
      creature_instance.gd  skill_slot.gd  player.gd  dict_fields.gd                   (onboarding/01)
    rules/                     regras puras: recebem dados, devolvem resultado
      stat_calculator.gd  xp_curve.gd  creature_factory.gd                             (onboarding/02)
  ui/
    theme/
      main_theme.tres          tema global                                            (foundation/02)
      palette.gd               UiPalette: cores da interface                          (foundation/02)
      fonts/                   Nunito-Variable.ttf, nunito_regular/bold.tres, OFL.txt (foundation/02)
    components/                peças reutilizáveis (cena .tscn + script .gd)
      safe_area  element_badge  creature_portrait  hp_bar                             (foundation/02)
      creature_slot                                                                   (hub/01)
  screens/                     uma pasta por tela (cena .tscn + script .gd)
    main/                      cena raiz, boot e ScreenHost                           (foundation/01, 02)
    placeholder/                                                                      (foundation/02)
    title/                                                                            (onboarding/01)
    starter_select/            tela, starter_card, confirm_panel                      (onboarding/02)
    hub/                       tela, profile_debug_panel                              (hub/01)
  data/                        catálogo: um arquivo JSON por tabela                   (game-data)
  assets/
    creatures/<slug>/front.png sprites (quando houver arte)
  tools/
    validate_data.gd           validador por linha de comando                         (game-data/01)
```

Pastas são criadas quando recebem o primeiro arquivo (o git não guarda pasta vazia).

## Camadas

```
screens/, ui/          telas e componentes: só exibem e repassam toques
   │  chamam
   ▼
core/autoload/         GameData (catálogo, leitura) · Session/GameService (estado do jogador) · Router
   │  usam
   ▼
core/data, services    de onde vêm os dados e como o estado é guardado
   │  usam
   ▼
domain/                modelos e regras puras
```

Regras:

- **`domain/` não conhece Node, cena, autoload nem arquivo.** Cada regra recebe por parâmetro tudo de que precisa (espécie, learnset, `RandomNumberGenerator`…) e devolve o resultado. É o código que será reescrito no servidor, então precisa ser lido sozinho.
- **Catálogo se lê pelo `GameData`; estado do jogador só pelo `Session` / `GameService`.** Nenhuma tela abre JSON, `user://` ou `FileAccess`.
- **Telas não calculam regras.** HP máximo, técnicas iniciais, recompensas: tudo vem pronto dos serviços.
- **Salvar só ids**, nunca objetos do catálogo. `CreatureInstance` guarda `species_id`, não a espécie.

## Serviços e `Result`

Todo método de serviço que no futuro será uma chamada à API:

- é chamado com `await`, mesmo que a implementação local seja imediata;
- devolve um `Result` (`res://core/services/result.gd`):

```gdscript
class_name Result
extends RefCounted

var ok: bool
var data: Variant
var error: String   # mensagem em pt-BR, pronta para a tela

static func success(value: Variant = null) -> Result
static func failure(message: String) -> Result
```

A tela confere `result.ok`; se falso, mostra `result.error` e mantém o jogador onde está.

Classes "interface" usam `@abstract` (GDScript 4.5+): `DataSource`, `GameService` e `PlayerRepository` declaram os métodos, e as implementações locais (`StaticJsonDataSource`, `LocalGameService`, `LocalPlayerRepository`) os preenchem. Quando houver backend, entram `HttpDataSource`, `ApiGameService` e `ApiPlayerRepository`, e só o ponto onde as instâncias são criadas muda.

## Autoloads

Registrados em `project.godot`, nesta ordem (cada um entra na fase que o cria):

| Nome       | Script                          | Papel                                                                 |
| ---------- | ------------------------------- | --------------------------------------------------------------------- |
| `GameData` | `res://core/autoload/game_data.gd` | Carrega e valida o catálogo; consultas como `get_species(id)`       |
| `Router`   | `res://core/autoload/router.gd`    | Troca de telas em pilha                                             |
| `Session`  | `res://core/autoload/session.gd`   | Guarda o `GameService` e o `Player` atual                           |

## Navegação

A cena principal é `res://screens/main/main.tscn`: um `Control` de tela cheia com um nó filho `ScreenHost`. O `Router` coloca as telas dentro do `ScreenHost`.

- **Registro de telas:** dicionário no `Router` de id (`StringName`) para caminho da cena. Ids do MVP: `&"title"`, `&"starter_select"`, `&"hub"`, `&"placeholder"`.
- **`go_to(id, params := {})`:** limpa a pilha e abre a tela. Usado quando não deve haver volta (ex.: depois de escolher o inicial).
- **`push(id, params := {})`:** esconde a tela atual (sem destruir) e abre a nova por cima.
- **`back()`:** destrói a tela do topo e mostra a anterior. Na última tela da pilha, não faz nada.
- **Parâmetros:** se a tela tiver `func setup(params: Dictionary) -> void`, o `Router` chama antes de adicioná-la à árvore.
- **Voltar do Android:** `application/config/quit_on_go_back = false`; a cena raiz recebe `NOTIFICATION_WM_GO_BACK_REQUEST` e chama `Router.back()`.

## Boot

`main.gd`, ao iniciar:

1. `GameData.load_catalog()`. Se falhar, mostra a lista de erros na própria cena raiz e para (é erro de quem editou os dados, não do jogador).
2. (a partir de [onboarding/01](../onboarding/01-title-and-tamer-name.md)) `await Session.load_player()` e decide a primeira tela:

| Situação                              | Primeira tela      |
| ------------------------------------- | ------------------ |
| Não há jogador salvo                  | `title`            |
| Há jogador, sem criatura na equipe    | `starter_select`   |
| Há jogador com equipe                 | `hub`              |

## Convenções de GDScript

- Arquivos e pastas em `snake_case`; `class_name` em `PascalCase`; constantes em `UPPER_SNAKE_CASE`; sinais no passado (`starter_chosen`).
- Toda variável, parâmetro e retorno tipado (`var level: int`, `-> void`, `Array[Skill]`). O projeto trata declaração sem tipo como erro.
- Uma classe por arquivo, com `class_name` quando for usada fora dele.
- Nós acessados com `%NomeUnico` (unique name) em vez de caminhos longos.
- Textos do jogador em pt-BR, direto na cena ou no script, com o vocabulário do [glossário](../glossary.md).
- Os arquivos `.uid` que o Godot cria ao lado dos scripts (ex.: `main.gd.uid`) vão para o git: o motor usa esses arquivos para manter as referências quando um arquivo muda de lugar.
- Ordem dentro do script: `class_name`, `extends`, sinais, constantes, `@export`, variáveis, `_ready`/callbacks, métodos públicos, métodos privados (`_nome`).

## Tela e toque

- Base 720×1280 (retrato). Toque mínimo de 64 px de altura em botões.
- Todo conteúdo de tela fica dentro de um `SafeArea` (componente de [foundation/02](02-ui-shell.md)), que respeita notch e barras do sistema.

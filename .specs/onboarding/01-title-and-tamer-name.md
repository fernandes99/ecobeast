# 01. Entrada e nome do Domador

- **Status:** concluída
- **Depende de:** [foundation/02-ui-shell](../foundation/02-ui-shell.md), [game-data/03-starter-content](../game-data/03-starter-content.md)

## Contexto

O jogo abre, valida o catálogo e mostra uma tela placeholder "Ecobeast". Ainda não existe jogador. Esta fase cria o estado do jogador e seus serviços ([architecture.md](architecture.md)), troca o boot provisório pelo boot de verdade e entrega a tela de entrada, onde o jogador digita o nome do Domador. A escolha do inicial vem na fase 02; até lá, depois do nome, o jogo abre o placeholder "Escolha do inicial".

## Escopo

- `Result`, `GameService`, `PlayerRepository`, `LocalGameService` (sem `choose_starter`), `LocalPlayerRepository`, `Uuid`.
- Modelos `Player`, `CreatureInstance`, `SkillSlot`.
- Autoload `Session`.
- Boot com a decisão da primeira tela.
- Tela `title` (TELAS.md #1, sem configurações).

## Fora do escopo

- Escolha do inicial e regras de criatura (fase 02).
- Login com Google, ícone de configurações, música.

## Requisitos

**Estado e serviços**

- **RF-01:** `Result`, `GameService`, `PlayerRepository` e `Session` seguem [architecture.md](architecture.md) e [foundation/architecture.md](../foundation/architecture.md#serviços-e-result).
- **RF-02:** `LocalGameService.create_player(name)` normaliza o nome (tira espaços das pontas e troca sequências de espaços por um só), valida com `^[\p{L}\p{N} ]{2,16}$`, recusa se já existe jogador, cria o `Player` (id `Uuid.v4()`, nível 1, 1000 moedas, `created_at` agora em UTC, equipe vazia), grava e devolve.
- **RF-03:** `LocalGameService.get_player()` devolve o jogador do repositório (ou `null`). `reset_progress()` chama `clear_player()` do repositório.
- **RF-04:** `LocalGameService.choose_starter()` nesta fase devolve `Result.failure("Ainda não disponível.")`; a fase 02 implementa.
- **RF-05:** `LocalPlayerRepository` lê e grava `user://save.json` no formato de [architecture.md](architecture.md#save-local), com gravação via arquivo temporário e o tratamento de arquivo ilegível descrito lá. `clear_player()` apaga `save.json` (sem erro se não existir).
- **RF-06:** `Player.to_dict()` seguido de `Player.from_dict()` devolve um jogador igual, incluindo a equipe (`CreatureInstance` e `SkillSlot` também fazem esse caminho de ida e volta; `stats` não entra no `to_dict` usado pelo save).

**Boot**

- **RF-07:** `main.gd`, depois do catálogo, faz `await Session.load_player()` e abre a tela da tabela de [architecture.md](architecture.md#boot), com `Router.go_to`. `starter_select` e `hub` abrem o placeholder com "Escolha do inicial" e "Hub" até existirem.
- **RF-08:** Se `load_player()` falhar, a cena raiz mostra a mensagem do `Result` e o botão "Tentar de novo", que refaz o passo.

**Tela de entrada** — `res://screens/title/title_screen.tscn`, registrada como `&"title"`.

- **RF-09:** De cima para baixo, centralizados dentro do `SafeArea`: o logo "Ecobeast" (texto, Bold, tamanho 72, cor primária), o subtítulo "Capture, treine e batalhe." (texto secundário), um espaço, o rótulo "Como você quer ser chamado, Domador?", o campo de nome com o texto de exemplo "Seu nome", a dica "De 2 a 16 letras ou números." (texto secundário, tamanho 18) e o botão "Começar" ocupando a largura do campo.
- **RF-10:** O campo aceita no máximo 16 caracteres (`max_length`).
- **RF-11:** "Começar" fica desabilitado enquanto o nome normalizado (regra do RF-02) não for válido; a validação acontece a cada tecla. Com nome inválido e não vazio, a dica fica na cor de perigo.
- **RF-12:** Tocar em "Começar" ou apertar Enter com nome válido desabilita campo e botão, troca o texto do botão para "Criando…" e chama `Session.create_player(nome)`. Sucesso: abre a escolha do inicial (nesta fase, `Router.go_to(&"placeholder", {"title": "Escolha do inicial"})`; a fase 02 troca por `&"starter_select"`). Falha: a mensagem do `Result` aparece no lugar da dica, na cor de perigo, e campo e botão voltam a funcionar.
- **RF-13:** No celular, o teclado virtual abre ao tocar no campo e a tela não fica coberta por ele (o conteúdo fica na metade de cima o suficiente para o campo e o botão continuarem visíveis, ou a tela sobe com o teclado).

## Critérios de aceite

- [x] Apagar `%APPDATA%\Godot\app_userdata\Ecobeast\save.json` (se existir) e dar F5 abre a tela de entrada.
- [x] "Começar" desabilitado com campo vazio, com "A", com "  " e com "@@"; habilitado com "Ana", "Jo 2" e "Ágatha".
- [x] "  Ana   Maria  " vira "Ana Maria" no save.
- [x] Depois de "Começar", aparece o placeholder "Escolha do inicial", e `save.json` tem o jogador com nível 1, 1000 moedas e `party` vazio.
- [x] Fechar e dar F5 de novo abre direto o placeholder "Escolha do inicial".
- [x] Trocar o conteúdo de `save.json` por `abc` e dar F5: abre a tela de entrada e existe `save.corrupted.json`.
- [x] Esc na tela de entrada não faz nada (não há tela anterior).

Conferidos por uma cena temporária (já apagada). Ela abriu o jogo numa janela, digitou os nomes, apertou os botões, simulou a reabertura chamando o boot de novo, gravou `abc` no save e salvou capturas de tela. Também conferiu a ida e volta de `Player.to_dict`/`from_dict` com uma criatura na equipe (RF-06) e o formato do UUID. O RF-13 fica para o dono, no aparelho: no PC não há teclado virtual. A tela já deixa o conteúdo na parte de cima, e um espaço do tamanho do teclado no fim da coluna sobe o conteúdo quando o teclado abre. O "Tentar de novo" do boot (RF-08) não foi exercitado, porque falhar a leitura do save exige um erro de disco.

**Decisões da implementação**

- A regra do nome (normalizar e validar) fica em `Player.normalize_name()` e `Player.is_valid_name()`. O `LocalGameService` valida com ela, e a tela de entrada usa a mesma regra só para habilitar o botão, sem duplicar a expressão regular.
- O `Session.load_player()` chama `GameService.get_player()`: é o nome da tabela do contrato.
- `DictFields` (`res://domain/models/dict_fields.gd`) lê campos de JSON com padrão para ausente ou `null`, e é usado pelos `from_dict`.
- Os `await` do `Session` têm `@warning_ignore("redundant_await")`: os métodos do `GameService` são `@abstract`, e o Godot não sabe que as implementações são assíncronas.
- Os avisos de script foram conferidos pelo servidor de linguagem do editor. A conferência achou parâmetros com o mesmo nome do campo em `LearnsetEntry.create` (da [game-data/01](../game-data/01-data-layer.md)), que foram renomeados.

## Desenho técnico

**Criar**

- `res://core/services/result.gd`, `game_service.gd`, `local_game_service.gd`, `player_repository.gd`, `local_player_repository.gd`.
- `res://core/util/uuid.gd`.
- `res://domain/models/player.gd`, `creature_instance.gd`, `skill_slot.gd`, `dict_fields.gd`.
- `res://core/autoload/session.gd` e o autoload `Session` (depois de `Router`).
- `res://screens/title/title_screen.tscn` e `title_screen.gd`.

**Alterar**

- `res://screens/main/main.gd`: boot de verdade (RF-07, RF-08).
- `res://core/autoload/router.gd`: registrar `&"title"`.
- `res://core/autoload/game_data.gd`: expor `catalog: Catalog` (o `LocalGameService` recebe o catálogo pelo construtor).
- `project.godot`: autoload `Session`.
- `CLAUDE.md`: regra "telas só falam com `Session`; serviços sempre com `await` e `Result`".

**Reaproveitar**

- `SafeArea`, tema e `UiPalette` ([foundation/02](../foundation/02-ui-shell.md)); `Router`.

## Verificação

```bash
godot --headless --path client --script res://tools/validate_data.gd
```

No editor: percorrer os critérios de aceite. No celular: fica para quando houver export (`release-pipeline`); RF-13 é conferido com a janela do editor no formato de celular e, se possível, no aparelho.

## Tarefas

- [x] Modelos `Player`, `CreatureInstance`, `SkillSlot` com `to_dict`/`from_dict`.
- [x] `Result`, `Uuid`, `PlayerRepository` e `LocalPlayerRepository`.
- [x] `GameService` e `LocalGameService` (sem `choose_starter`).
- [x] `Session` e o autoload.
- [x] Boot em `main.gd`.
- [x] Tela de entrada.
- [x] Atualizar o `CLAUDE.md`.
- [x] Marcar esta spec e as tabelas como `concluída`; commit `feat: tela de entrada e estado do jogador`.

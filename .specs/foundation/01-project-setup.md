# 01. Configuração do projeto

- **Status:** rascunho
- **Depende de:** Godot 4.7 instalado; repositório git criado (feito no commit das specs)

## Contexto

O `project.godot` atual só tem o nome, o renderer Mobile e o esticamento `canvas_items` + `expand`. Não há cena principal, a orientação não está definida e o `CLAUDE.md` ainda descreve o projeto como Unity/C#. Esta fase deixa o projeto pronto para receber código: configurações de celular em retrato, cena raiz vazia e documentos alinhados com Godot.

## Escopo

- Configurações de exibição, orientação, voltar do Android e tipagem em `project.godot`.
- Cena raiz `res://screens/main/main.tscn`, ainda sem navegação.
- `CLAUDE.md` reescrito para Godot; `GDD.md` ajustado onde fala de Unity e de save local.

## Fora do escopo

- Autoloads, tema e navegação (entram nas fases que os criam).
- Export para Android/iOS.

## Requisitos

- **RF-01:** O projeto roda em retrato com área base de 720×1280 (`display/window/size/viewport_width = 720`, `viewport_height = 1280`, `display/window/handheld/orientation = 1`), mantendo `stretch/mode = canvas_items` e `stretch/aspect = expand`.
- **RF-02:** No editor, a janela do jogo abre com 405×720 (`window_width_override` e `window_height_override`).
- **RF-03:** A cena principal é `res://screens/main/main.tscn` (`application/run/main_scene`).
- **RF-04:** O botão voltar do Android não fecha o jogo (`application/config/quit_on_go_back = false`).
- **RF-05:** Declaração sem tipo é erro de script (`debug/gdscript/warnings/untyped_declaration = 2`).
- **RF-06:** `main.tscn` é um `Control` de tela cheia (âncoras "Full Rect") com um filho `Control` chamado `ScreenHost` (unique name, tela cheia) e um `Label` centralizado "Ecobeast", que será removido em [02-ui-shell](02-ui-shell.md).
- **RF-07:** O `CLAUDE.md` descreve o projeto como Godot 4.7 + GDScript e contém: resumo do jogo, link para `.specs/README.md` como ponto de partida, a árvore de pastas resumida de [architecture.md](architecture.md), as regras de camadas, o vocabulário (link para `.specs/glossary.md`), a regra "nunca termos do Pokémon", o comando do validador e o escopo do MVP atual (entrada, escolha do inicial, Hub). Nenhuma menção a Unity, C#, ScriptableObject, Addressables ou MonoBehaviour.
- **RF-08:** No `GDD.md`: o título passa a "GDD — Jogo de Criaturas Mobile (Godot)"; a seção "Arquitetura no Unity" passa a "Arquitetura" com um parágrafo apontando para `.specs/foundation/architecture.md` e `.specs/game-data/architecture.md` (o bloco de C# sai); "Save local (JSON criptografado) + backup na nuvem opcional" passa a "Jogo online; estado do jogador no servidor"; nas tabelas de espécie e técnica, `ScriptableObject` vira "linha do catálogo" e "Addressables" vira "arquivo em `res://assets/`". O resto do GDD não muda.

## Critérios de aceite

- [ ] F5 no editor abre uma janela em pé (mais alta que larga) com "Ecobeast" no centro, sem erros no painel de Saída.
- [ ] Redimensionar a janela para mais alta mantém o texto centralizado, sem barras pretas.
- [ ] Um script de teste com `var x = 1` (sem tipo) aparece com erro no editor; com `var x: int = 1`, não. (Apagar o script depois.)
- [ ] `CLAUDE.md` não contém "Unity", "C#", "ScriptableObject", "Addressables" nem "MonoBehaviour".
- [ ] `GDD.md` não contém "Unity" e a seção de arquitetura aponta para as specs.

## Desenho técnico

**Criar**

- `res://screens/main/main.tscn` e `res://screens/main/main.gd` (`extends Control`, por enquanto só `_ready()` vazio com `pass`).

**Alterar**

- `project.godot`: as chaves dos RF-01 a RF-05. Prefira editar pelo menu Projeto > Configurações do Projeto (com "Configurações avançadas" ligado); o arquivo resultante deve conter as chaves com os valores acima.
- `CLAUDE.md`: reescrito (RF-07).
- `GDD.md`: ajustes pontuais (RF-08).

**Reaproveitar sem alterar**

- `.gitignore` (já ignora `.godot/`), `.gitattributes`, `.editorconfig`, `icon.svg`.

## Verificação

```bash
git status            # só os arquivos desta fase
grep -nE "Unity|C#|ScriptableObject|Addressables|MonoBehaviour" CLAUDE.md   # nada
grep -n "Unity" GDD.md                                                       # nada
```

No editor: percorrer os critérios de aceite.

## Tarefas

- [ ] Configurações de `project.godot` (RF-01 a RF-05).
- [ ] `main.tscn` + `main.gd` e definir como cena principal.
- [ ] Reescrever o `CLAUDE.md`.
- [ ] Ajustar o `GDD.md`.
- [ ] Marcar esta spec, a tabela da iniciativa e a do `.specs/README.md` como `concluída`; commit `feat: configuração inicial do projeto Godot`.

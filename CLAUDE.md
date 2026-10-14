# Ecobeast — contexto do projeto

Jogo mobile (Android/iOS, retrato) feito em **Godot 4.7 com GDScript**, inspirado no Pokémon Simulator 4.5 (Birdiesoft, 2004): capturar, treinar e batalhar criaturas por menus e batalhas por turnos, sem mundo aberto. O jogo será **só online**, com o servidor decidindo as regras; no MVP ainda não há servidor, e tudo roda no cliente atrás de serviços.

O dono do projeto é iniciante em Godot: explique conceitos do motor (cenas, nós, autoloads, `class_name`, sinais) quando aparecerem pela primeira vez.

## Comece pelas specs

Toda entrega nasce de uma spec em `.specs/`. Antes de implementar, leia:

1. `.specs/README.md` — convenção, regras e a ordem das fases do MVP.
2. O `README.md` e o `architecture.md` da iniciativa.
3. A spec da fase (`NN-assunto.md`).

A spec é a fonte da verdade. Se a implementação precisar divergir, atualize a spec no mesmo commit e diga o motivo. Documentos de design: `GDD.md` (regras, fórmulas, conteúdo) e `TELAS.md` (as 16 telas do protótipo).

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

## Regras do projeto

- **Nunca** usar nomes, termos ou visuais do Pokémon no jogo. Use o vocabulário de `.specs/glossary.md`: Ecobeast, Domador, Esfera de Vínculo, Bestiário, Elemento, Técnica, Traço, Temperamento, Genes, Treino, Santuário, Arena, Prismático, Ancestral, Ascensão, Refúgio.
- **Camadas:** `domain/` não usa Node, autoload, arquivo nem `get_tree()` — recebe tudo por parâmetro, porque será reescrito no servidor. Telas leem o catálogo pelo `GameData` e o estado do jogador pelo `Session`; nunca abrem JSON nem `user://`.
- **Telas não calculam regras.** HP máximo, técnicas, recompensas vêm prontos dos serviços.
- **Serviços** são chamados com `await` e devolvem `Result` (`ok`, `data`, `error`).
- **Dados de design** são tabelas relacionais em `res://data/<tabela>.json` (ids estáveis, FKs `<singular>_id`), descritas em `.specs/game-data/architecture.md` e espelhadas em `core/data/catalog_schema.gd`. Salve só ids no estado do jogador.
- **GDScript tipado:** declaração sem tipo é erro de script no projeto. Arquivos em `snake_case`, classes em `PascalCase`, nós acessados por `%NomeUnico`.
- Textos do jogador em pt-BR, direto nas cenas e scripts.
- Versione os arquivos `.uid` que o Godot cria ao lado dos scripts; `.godot/` fica fora do git.

## Comandos

O executável do Godot está em `C:\Godot\` (use a versão `_console` na linha de comando).

```bash
# rodar o jogo sem janela por alguns frames (confere erros de script)
godot --headless --path . --quit-after 30

# validar o catálogo (a partir da fase game-data/01)
godot --headless --path . --script res://tools/validate_data.gd
```

## Escopo atual (MVP de estrutura)

Tela de entrada com o nome do Domador, escolha de 1 entre 3 Ecobeasts iniciais (Fogo, Água, Flora) e Hub com todas as features abrindo telas placeholder. O resto está em `.specs/roadmap.md`.

# Specs

Entregas grandes começam por uma spec escrita aqui, antes do código. A spec é o que a pessoa (ou a IA) que vai implementar lê para saber o que fazer, onde e como conferir que ficou pronto.

O Ecobeast é um jogo mobile (Android/iOS, retrato): o cliente em **Godot 4.7 com GDScript** (`client/`) e a API em NestJS (`server/`), no mesmo repositório. O design do jogo está em `GDD.md` e a lista de telas em `TELAS.md`, na raiz do repositório. As specs transformam esses documentos em entregas implementáveis; quando uma spec e o GDD divergem, vale a spec (e o GDD é atualizado).

## Organização

- Uma pasta por iniciativa, com nome em inglês e kebab-case: `.specs/<iniciativa>/`.
- `README.md` da iniciativa: contexto, objetivos, decisões, fora do escopo, pré-requisitos e a tabela de fases com o status de cada uma.
- `architecture.md` (opcional): o desenho técnico que mais de uma fase compartilha.
- Uma spec por fase, numerada na ordem de implementação: `01-<assunto>.md`, `02-<assunto>.md`. Cada fase tem o tamanho de uma entrega que dá para commitar e validar sozinha.
- Arquivos da raiz: este `README.md`, o [glossary.md](glossary.md) (vocabulário do jogo e nomes no código) e o [roadmap.md](roadmap.md) (iniciativas futuras e dúvidas globais).

## Iniciativas

| Iniciativa                  | Assunto                                                                                  |
| --------------------------- | ---------------------------------------------------------------------------------------- |
| [foundation](foundation/)   | Esqueleto do projeto Godot: pastas, camadas, configurações, tema, navegação e componentes |
| [game-data](game-data/)     | Modelo relacional do catálogo em JSON estático, camada de dados e conteúdo inicial        |
| [onboarding](onboarding/)   | Tela de entrada com o nome do Domador e escolha do Ecobeast inicial                      |
| [hub](hub/)                 | Tela principal com a equipe e o acesso a todas as features do jogo                       |
| [backend-api](backend-api/) | Servidor: banco no Supabase, API NestJS do catálogo e o jogo lendo o catálogo dela        |

As próximas iniciativas estão no [roadmap.md](roadmap.md).

## Ordem de implementação do MVP

As fases dependem umas das outras nesta ordem:

| #   | Fase                                                                       | Status   |
| --- | -------------------------------------------------------------------------- | -------- |
| 1   | [foundation/01-project-setup](foundation/01-project-setup.md)              | concluída |
| 2   | [game-data/01-data-layer](game-data/01-data-layer.md)                      | concluída |
| 3   | [game-data/02-core-tables](game-data/02-core-tables.md)                    | concluída |
| 4   | [game-data/03-starter-content](game-data/03-starter-content.md)            | concluída |
| 5   | [foundation/02-ui-shell](foundation/02-ui-shell.md)                        | concluída |
| 6   | [onboarding/01-title-and-tamer-name](onboarding/01-title-and-tamer-name.md) | concluída |
| 7   | [onboarding/02-starter-selection](onboarding/02-starter-selection.md)      | concluída |
| 8   | [hub/01-hub-screen](hub/01-hub-screen.md)                                  | concluída |

Com as 8 fases concluídas, o MVP de estrutura está pronto. As próximas iniciativas, na ordem sugerida, estão no [roadmap.md](roadmap.md).

## Modelo de spec

```markdown
# NN. Título

- **Status:** rascunho | aprovada | em andamento | concluída
- **Depende de:** specs ou pré-requisitos

## Contexto

Por que esta fase existe e o que já está pronto antes dela.

## Escopo

O que entra.

## Fora do escopo

O que não entra, mesmo parecendo relacionado.

## Requisitos

- **RF-01:** uma frase, um comportamento.

## Critérios de aceite

- [ ] Verificável por alguém que não escreveu o código.

## Desenho técnico

Arquivos a criar e a alterar, com caminho, e o que reutilizar do que já existe.

## Verificação

Comandos e passos manuais para conferir a entrega.

## Tarefas

- [ ] Passos de implementação, na ordem.

## Dúvidas em aberto

Só quando houver. Sem dúvidas, a seção não existe.
```

## Regras

- **A spec é a fonte da verdade.** Leia o `README.md` da iniciativa, o `architecture.md` e a spec da fase antes de implementar. Se a implementação precisar divergir, atualize a spec no mesmo commit e diga o motivo.
- **Cada spec se explica sozinha.** Quem lê não tem o histórico da conversa em que ela nasceu. Cite arquivos pelo caminho (`res://...` para arquivos do jogo) e escreva as decisões com o motivo.
- **Nada implícito.** O que não foi decidido vai em "Dúvidas em aberto" e é resolvido com o dono do projeto antes de virar código. Não invente requisito para fechar lacuna.
- **Propostas a revisar.** Conteúdo criado no planejamento sem aprovação do dono (nomes, números, cores) fica marcado como _a revisar_. Pode ser implementado, mas muda sem cerimônia se o dono pedir.
- **Requisitos numerados e critérios verificáveis.** "A tela abre rápido" não serve; "o botão Começar fica desabilitado com menos de 2 caracteres" serve.
- **Uma fase por vez.** Implemente e valide: o projeto abre no editor sem erros nem avisos de script, `tools/validate_data.gd` passa (a partir de [game-data/01](game-data/01-data-layer.md)) e os passos manuais da spec foram feitos. Marque as tarefas e mude o status da spec e das tabelas (iniciativa e esta) para `concluída` no mesmo commit.
- **O cliente Godot não tem framework de testes** (decisão do dono; o servidor terá, ver [roadmap.md](roadmap.md#decisões-globais-já-tomadas)). A verificação de cada fase é feita pelo validador de dados e por passos manuais no editor (F5) e, quando fizer sentido, no aparelho; quem implementa diz quais passos fez e quais ficaram para o dono.
- **Nunca usar nomes, termos ou visuais do Pokémon no jogo.** Use o vocabulário do [glossary.md](glossary.md). Nas specs, o nome original só aparece na coluna "Referência" do glossário, nas próprias regras de não usá-lo e na citação da PokeAPI como referência técnica de modelo de dados; nunca em conteúdo do jogo (espécies, técnicas, textos, telas).
- **Sem segredos.** Nada de chaves, senhas ou dados reais de jogadores nas specs.
- Specs são escritas em português. Commits que só mexem em specs usam o prefixo `chore`; os de implementação, `feat` ou `fix`.

## Como rodar o validador

O executável do Godot no Windows tem um nome como `Godot_v4.7.2-stable_win64.exe` (nesta máquina, em `C:\Godot\`; para o terminal, use a versão `_console`). Para os comandos das specs funcionarem como estão escritos, deixe-o acessível como `godot` (renomeie uma cópia ou crie um alias no terminal). Na raiz do repositório (o projeto Godot fica em `client/`):

```bash
godot --headless --path client --script res://tools/validate_data.gd
```

Saída `0` quando o catálogo está íntegro; diferente de `0`, com a lista de erros, quando não está.

# Foundation

O esqueleto do projeto Godot onde todas as telas e regras do Ecobeast vão se encaixar: pastas, camadas, configurações de projeto, navegação entre telas, tema visual e os componentes que mais de uma tela usa.

## Contexto

A pasta do projeto tem um `project.godot` recém-criado (Godot 4.7, renderer Mobile, sem cena principal) e os documentos de design `GDD.md`, `TELAS.md` e `CLAUDE.md`. Esses documentos foram escritos pensando em Unity/C#; o dono decidiu usar Godot com GDScript, e é iniciante na ferramenta. Esta iniciativa define como o código é organizado antes de qualquer tela existir, para que as próximas iniciativas só acrescentem peças.

## Objetivos

1. Quem abre o projeto entende onde cada coisa fica e por quê, lendo [architecture.md](architecture.md).
2. As regras do jogo ficam separadas das telas, prontas para migrar para o servidor.
3. Toda tela nova se encaixa na navegação e no tema sem código repetido.
4. O jogo roda em retrato, no tamanho de celular, no editor e no aparelho.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                     | Motivo                                                                               |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Godot 4.7 com GDScript e tipagem estática                   | Melhor material para quem está começando; export mobile simples; sem build .NET       |
| O jogo será só online; o servidor decide as regras          | Anti-trapaça, PvP e trocas. No MVP as regras rodam no cliente atrás de serviços      |
| Repositório git com um commit por fase                      | Cada fase é validada e registrada sozinha                                            |
| Monorepo: o jogo em `client/` e a API em `server/`          | Quem trabalha sozinho muda o contrato da API e o cliente no mesmo commit; as specs ficam num lugar só |
| Tema visual próprio e cores dos 14 elementos já no MVP       | O jogo já nasce com a sua cara; sprites ficam como placeholder até ter arte          |
| Sem framework de testes e sem sistema de tradução no MVP    | Escopo menor; validação por ferramenta de dados e passos manuais; textos em pt-BR     |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                         | Motivo                                                                                       |
| ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Três camadas: `domain` (regras puras), `core` (dados e serviços), `screens`/`ui` | As regras não dependem de cena nem de Node, então podem ser reescritas no servidor 1:1        |
| Uma cena raiz (`main.tscn`) que troca as telas dentro dela, em pilha            | "Voltar" devolve a tela anterior como estava, sem recarregar                                 |
| Toda chamada de serviço usa `await` e devolve um `Result`                        | Quando virar chamada de rede, nenhuma tela muda                                               |
| Declaração sem tipo vira erro (`untyped_declaration = Error`)                   | Autocompletar e erros no editor ajudam muito quem está aprendendo GDScript                   |
| Tela base de 720×1280, `canvas_items` + `expand`, retrato                       | Proporção de celular comum; `expand` aproveita telas mais altas sem barras pretas            |
| Janela do editor reduzida para 405×720                                          | Cabe no monitor durante o desenvolvimento, mantendo a proporção                               |
| Fonte Nunito (licença OFL) no tema                                              | Arredondada e amigável, combina com "fantasia leve"; livre para jogos comerciais              |
| Sprites por convenção de caminho, com placeholder quando o arquivo não existe   | As telas ficam prontas antes da arte; quando a arte chegar, basta colocar o arquivo           |

## Fora do escopo

- Login, contas e qualquer chamada de rede (ver [roadmap.md](../roadmap.md)).
- Framework de testes automatizados e tradução.
- Arte final, sons e música.
- Configurar export para Android/iOS (iniciativa `release-pipeline` do roadmap). Até lá, tudo é validado no editor.

## Pré-requisitos

- Godot 4.7 instalado no Windows e acessível como `godot` no terminal (ver [README das specs](../README.md#como-rodar-o-jogo-e-os-testes)).

## Fases

| Fase                                      | Entrega                                                                  | Status   |
| ----------------------------------------- | ------------------------------------------------------------------------ | -------- |
| [01-project-setup](01-project-setup.md)   | Configurações do projeto, cena raiz vazia, `CLAUDE.md` e `GDD.md` para Godot | concluída |
| [02-ui-shell](02-ui-shell.md)             | Tema, navegação em pilha, safe area, componentes base e tela placeholder | concluída |

A fase 02 vem depois de [game-data](../game-data/), porque os componentes leem nomes e cores do catálogo. A ordem completa está no [README das specs](../README.md#ordem-de-implementação-do-mvp).

O desenho compartilhado está em [architecture.md](architecture.md).

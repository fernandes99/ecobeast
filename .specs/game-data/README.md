# Game data

O catálogo do jogo — elementos, espécies, técnicas, traços, temperamentos e tudo que é igual para todos os jogadores — modelado como **tabelas relacionais**, guardado por enquanto em **JSON estático** (um arquivo por tabela em `res://data/`) e lido pelo jogo através de uma camada de dados que depois vai buscar as mesmas tabelas na API.

## Contexto

O GDD descreve os dados como ScriptableObjects do Unity. Com a mudança para Godot e a decisão de que o jogo será online, os dados de design vão morar num banco relacional do backend, servidos por uma API (como a PokeAPI faz com os CSVs que alimentam o banco dela). Ainda não há backend. Esta iniciativa define o modelo agora, para o backend nascer copiando as tabelas, e entrega o conteúdo mínimo para o MVP: as 3 linhas evolutivas iniciais.

## Quem usa

- As telas e serviços do jogo, pelo autoload `GameData`.
- Quem edita os dados (o dono, a IA), direto nos arquivos `res://data/*.json`, conferindo com o validador.
- No futuro, o backend: as tabelas daqui viram as tabelas do banco.

## Objetivos

1. Cada arquivo JSON é uma tabela: linhas com colunas fixas, chave primária e chaves estrangeiras por id.
2. Um erro nos dados (id repetido, FK inexistente, coluna faltando) é encontrado antes de rodar o jogo, com arquivo, linha e motivo.
3. Trocar o JSON estático pela API muda uma classe só (`DataSource`), nenhuma tela.
4. As 3 linhas iniciais existem completas: espécies, stats, elementos, traços, técnicas com efeitos, learnset até o nível 55 e Ascensões por nível.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                              | Motivo                                                              |
| -------------------------------------------------------------------- | ------------------------------------------------------------------- |
| JSON estático agora, banco relacional + API depois                   | Começar simples sem refazer o modelo                                |
| Um arquivo por tabela, com ids e FKs (no estilo da PokeAPI)          | Vira migração SQL quase 1:1                                         |
| As 3 linhas iniciais completas (9 espécies)                          | Valida Ascensão e learnset no modelo desde já                       |
| Linha de Fogo do GDD; linhas de Água e Flora propostas no planejamento | O dono revisa nomes e números (marcados _a revisar_)               |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                        | Motivo                                                                                       |
| ------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- |
| Listas fixas (elementos, stats, categorias, gatilhos…) também são tabelas       | O banco ganha FKs de verdade; nada de enum duplicado entre cliente e servidor                |
| Ids inteiros estáveis; `slug` em inglês para código; `name` em pt-BR para a tela | Código não depende de texto traduzível; ids nunca são reaproveitados                         |
| `element_efficacy` guarda só multiplicadores diferentes de 1                    | Tabela pequena e legível; o padrão 1 é aplicado ao montar a matriz                            |
| Efeitos de técnica em uma tabela com colunas tipadas e anuláveis                | Relacional de verdade (FK para status e stat) sem uma tabela por tipo de efeito              |
| O schema vive no código (`catalog_schema.gd`) e o validador confere tudo contra ele | Uma fonte só para "quais colunas existem"; o mesmo schema guiará a migração do banco      |
| O catálogo é carregado inteiro na abertura do jogo                              | São poucos KB; depois disso nenhuma consulta espera disco ou rede                            |
| Tabelas futuras (itens, zonas, NPCs, arenas) só documentadas, sem arquivo       | Não criar dados que nenhuma tela usa ainda                                                   |

## Fora do escopo

- Banco de dados, API e download do catálogo (iniciativa `backend-api` do [roadmap](../roadmap.md)).
- Estado do jogador (está em [onboarding/architecture.md](../onboarding/architecture.md)).
- Espécies além das 3 linhas iniciais, itens, zonas e Domadores NPC.
- Editor visual de dados ou importação de planilha.

## Pré-requisitos

- [foundation/01-project-setup](../foundation/01-project-setup.md) concluída.

## Fases

| Fase                                          | Entrega                                                                    | Status   |
| --------------------------------------------- | -------------------------------------------------------------------------- | -------- |
| [01-data-layer](01-data-layer.md)             | Schema em código, leitura dos JSON, validador, `GameData` e modelos        | concluída |
| [02-core-tables](02-core-tables.md)           | Tabelas de referência: elementos e efetividade, stats, temperamentos etc.  | concluída |
| [03-starter-content](03-starter-content.md)   | As 3 linhas iniciais: espécies, traços, técnicas, learnsets e Ascensões    | concluída |

O schema completo está em [architecture.md](architecture.md).

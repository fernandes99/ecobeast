# Backend API

O primeiro passo do servidor: o banco do Ecobeast no Supabase, com todas as tabelas descritas num único `schema.prisma`, uma API NestJS de leitura do catálogo no estilo da PokeAPI, com documentação navegável, e o jogo passando a ler o catálogo dessa API.

## Contexto

O MVP de estrutura está pronto, mas tudo roda no cliente: o catálogo (espécies, Técnicas, Elementos…) mora em `client/data/*.json`, e o jogador em `user://save.json`. O jogo será só online, com o servidor como autoridade das regras. A stack já foi escolhida ([roadmap](../roadmap.md#decisões-globais-já-tomadas)): NestJS + Prisma sobre o Supabase (Postgres, Auth, Storage), em `server/` neste monorepo, com o Godot falando só com o NestJS.

Esta iniciativa cria o banco e o servidor e muda o dono do catálogo: **o banco passa a ser a fonte da verdade.** Os JSON de `client/data/` são temporários: servem para a carga inicial do banco e mantêm o jogo funcionando até a última fase, quando o Godot passa a baixar o catálogo da API e eles saem do cliente.

## Quem usa

- **O jogo** (cliente Godot): é o único consumidor da API. Ninguém de fora, por enquanto.
- **O dono do projeto**: muda valores do catálogo direto no banco (pelo painel do Supabase) e explora a API pela documentação em `/docs`.

## Objetivos

1. Todas as tabelas do jogo (catálogo e estado do jogador) num banco organizado, criado e alterado só por migrations geradas do `schema.prisma`.
2. Mudar um valor no banco (o poder de uma Técnica, por exemplo) muda o que a API devolve na hora, para todos.
3. Endpoints de leitura de todo o catálogo, no formato da PokeAPI: lista paginada, detalhe por id ou slug, sub-recursos (as Técnicas de uma espécie, a linha de Ascensão) e referências entre recursos.
4. Documentação da API navegável e testável no navegador (Scalar).
5. O jogo abre e mostra Fagulho, Gotículo e Brotelho vindos do banco, sem os JSON locais.

## Decisões

Tomadas com o dono do projeto:

| Decisão                                                                                       | Motivo                                                                                   |
| --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| Um único `server/prisma/schema.prisma`: toda tabela do banco nasce e muda nele                 | Um lugar só para entender e alterar o banco                                              |
| O banco tem todas as tabelas: catálogo (as 23 de [game-data](../game-data/architecture.md)) e estado do jogador | O banco nasce completo e organizado; a API do jogador vem depois sobre as mesmas tabelas |
| O banco é o dono do catálogo; mudanças de valor são feitas direto nele                        | Uma mudança vale na hora para todos, sem publicar versão do jogo                         |
| Os JSON de `client/data/` são temporários: fonte da carga inicial e do jogo até a fase 07      | Evita digitar o catálogo de novo; o jogo não para enquanto a API não existe              |
| Endpoints de leitura do catálogo no estilo da PokeAPI                                          | Formato conhecido: lista, detalhe e sub-recursos com referências                         |
| A API é usada só pelo jogo, por enquanto                                                       | Escopo menor; nada de chaves para terceiros nem documentação pública                     |
| Documentação com Scalar em `/docs`                                                             | A mais agradável de navegar e testa as rotas; lê o OpenAPI gerado pelo NestJS            |
| Usa o projeto Supabase que o dono já tem; as chaves ficam no `server/.env`, e o `server/.env.example` (versionado) tem só os nomes das variáveis | Sem segredos no repositório                                    |
| A troca do Godot para o catálogo da API é a última fase desta iniciativa                        | Prova a API de ponta a ponta                                                             |
| As faixas de valor viram `CHECK` no banco, escritos à mão no SQL da migration e comentados no `schema.prisma` | O banco recusa valor errado mesmo editado à mão; o Prisma não descreve `CHECK`, então essa é a única exceção ao arquivo único |

Tomadas no planejamento (corrigíveis; ao mudar uma, atualize aqui e nas specs afetadas):

| Decisão                                                                                   | Motivo                                                                                           |
| ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| As tabelas ficam no schema Postgres `ecobeasts`, e não no `public`                         | Agrupa o jogo, e a API automática do Supabase (que publica só o `public`) não enxerga as tabelas |
| Desenvolvimento direto contra o projeto Supabase na nuvem, sem banco local                 | Não há Docker na máquina; as migrations rodam igual em qualquer projeto                          |
| Rotas de leitura do catálogo abertas, sem login, com limite de chamadas por IP             | O catálogo não é secreto e o login ainda não existe; o limite evita abuso                        |
| Rotas em inglês com o nome das tabelas (`/v1/species`, `/v1/skills`)                       | Casa com o banco e o código, como o resto dos nomes técnicos                                     |
| `GET /v1/catalog` devolve o catálogo inteiro com uma versão                               | O jogo baixa tudo numa chamada ao abrir e só baixa de novo quando a versão muda                  |
| A carga inicial só roda em banco vazio e nunca sobrescreve                                 | Mudanças feitas à mão no banco não se perdem                                                     |
| Testes automáticos no servidor (Vitest + supertest)                                        | Fórmula ou formato errado no servidor vira bug para todos ([roadmap](../roadmap.md#decisões-globais-já-tomadas)) |
| Gerenciador de pacotes npm, Node 24                                                        | Já instalados na máquina                                                                         |

## Fora do escopo

- Rotas do jogador (criar Domador, escolher inicial, ler o jogador): precisam do login, e entram em `auth-google`. Até lá o jogador continua em `user://save.json`. As tabelas do jogador já são criadas aqui.
- Login (Supabase Auth) e Storage (sprites): entram nas iniciativas que os usam.
- Deploy no Render e o projeto Supabase de produção: o servidor roda na máquina do dono nesta iniciativa.
- Regras de jogo no servidor (stats, dano, captura): nascem em `battle-core` e nas seguintes.
- Painel de administração do catálogo e histórico de alterações dos dados.
- Tabelas futuras do catálogo (itens, zonas, Domadores NPC, Arenas).

## Pré-requisitos

- MVP de estrutura concluído (as 8 fases do [README das specs](../README.md#ordem-de-implementação-do-mvp)).
- O projeto Supabase do dono, com a senha do banco em mãos.
- Node 24 e npm instalados.

## Fases

Cada fase tem a sua spec, com requisitos, critérios de aceite e tarefas.

| Fase                          | Entrega                                                                                       | Status   |
| ----------------------------- | --------------------------------------------------------------------------------------------- | -------- |
| [01-server-setup](01-server-setup.md)               | Projeto NestJS em `server/`, `.env`, Prisma ligado ao Supabase, `/health`, Scalar em `/docs`, testes rodando | concluída |
| [02-database-schema](02-database-schema.md)            | `schema.prisma` com todas as tabelas (catálogo e jogador), restrições e a primeira migration   | concluída |
| [03-catalog-seed](03-catalog-seed.md)               | Carga inicial do catálogo a partir de `client/data/*.json`                                     | rascunho |
| [04-species-api](04-species-api.md)                | O padrão dos recursos (lista, detalhe, referências, erros) e as rotas de espécies              | rascunho |
| [05-catalog-api](05-catalog-api.md)                | As rotas dos demais recursos do catálogo e dos iniciais                                         | rascunho |
| [06-catalog-bundle](06-catalog-bundle.md)             | `GET /v1/catalog`: o catálogo inteiro com versão, para o jogo                                  | rascunho |
| [07-client-remote-catalog](07-client-remote-catalog.md)      | O Godot baixa o catálogo da API; `client/data/` vai para `server/prisma/seed-data/`            | rascunho |

O desenho compartilhado está em [architecture.md](architecture.md).

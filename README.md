# Ecobeast

![Status: em desenvolvimento](https://img.shields.io/badge/status-em%20desenvolvimento-orange)
![Godot 4.7](https://img.shields.io/badge/Godot-4.7-478CBF?logo=godotengine&logoColor=white)
![NestJS](https://img.shields.io/badge/NestJS-API-E0234E?logo=nestjs&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-Postgres-3FCF8E?logo=supabase&logoColor=white)

Jogo mobile (Android e iOS, em retrato) de **capturar, treinar e batalhar criaturas**, os Ecobeasts. Tudo acontece por menus e batalhas por turnos, sem mundo aberto: você escolhe um Ecobeast inicial, monta uma equipe de até seis, enfrenta Ecobeasts selvagens e outros Domadores, e avança pelas Arenas.

> [!WARNING]
> **Projeto em andamento.** O que existe hoje é a estrutura do jogo e o servidor do catálogo. Ainda não dá para batalhar nem capturar, e as telas além da entrada, da escolha do inicial e do Hub são placeholders. Nomes, valores e telas podem mudar a qualquer momento.

## Sumário

- [O jogo](#o-jogo)
- [Status](#status)
- [Stack](#stack)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Como rodar](#como-rodar)
- [Testes](#testes)
- [Documentação](#documentação)
- [Como o projeto é desenvolvido](#como-o-projeto-é-desenvolvido)
- [Licença](#licença)

## O jogo

- **Domador:** o jogador. Começa com um nome e um Ecobeast inicial.
- **Ecobeasts:** cada um tem um ou dois dos **14 Elementos**, Técnicas, um Traço, um Temperamento e Genes próprios, e pode passar por **Ascensões** ao subir de nível.
- **Os iniciais:** três linhas evolutivas para escolher no começo: Fagulho (Fogo), Gotículo (Água) e Brotelho (Flora).
- **Só online:** o servidor decide as regras (stats, dano, captura, recompensas), e o aparelho só mostra o resultado. Isso evita trapaças e prepara o terreno para PvP e trocas.

As regras, as fórmulas e o conteúdo estão no [GDD](GDD.md); as 16 telas do protótipo, em [TELAS.md](TELAS.md).

## Status

| Etapa                                  | Situação         | O que entrega                                                                                       |
| -------------------------------------- | ---------------- | --------------------------------------------------------------------------------------------------- |
| MVP de estrutura                       | ✅ concluído     | Entrada com o nome do Domador, escolha do inicial e Hub com todas as features (as ainda não feitas abrem telas placeholder) |
| [Backend e API do catálogo](.specs/backend-api/) | ✅ concluído     | Banco no Supabase, API NestJS de leitura do catálogo com documentação, e o jogo baixando o catálogo dela |
| Login com Google                       | ⏳ próximo       | Conta do jogador no servidor, no lugar do nome digitado                                             |
| Batalha, captura e progressão          | 📋 planejado     | O núcleo do jogo, decidido pelo servidor                                                            |
| Equipe, Santuário, Loja, Bestiário, Arenas… | 📋 planejado | As demais telas do Hub                                                                              |
| Publicação nas lojas                   | 📋 planejado     | Export Android e iOS                                                                                |

O roadmap completo, com a ordem e as dependências, está em [.specs/roadmap.md](.specs/roadmap.md).

## Stack

| Parte    | Tecnologia                                                                                         |
| -------- | -------------------------------------------------------------------------------------------------- |
| Jogo     | [Godot 4.7](https://godotengine.org/) com GDScript tipado, renderer Mobile                          |
| API      | [NestJS](https://nestjs.com/) + [Prisma](https://www.prisma.io/), em TypeScript (Node 24)           |
| Banco    | Postgres do [Supabase](https://supabase.com/), com Auth e Storage previstos                         |
| Docs     | OpenAPI exibido pela [Scalar](https://scalar.com/) em `/docs`                                        |
| Testes   | Vitest + supertest no servidor                                                                      |

O jogo fala **só com a API**, nunca com o banco nem com a API automática do Supabase.

## Estrutura do repositório

```
.specs/     especificações de todo o projeto, por iniciativa e fase
client/     o jogo (projeto Godot)
server/     a API (NestJS + Prisma)
GDD.md      regras, fórmulas e conteúdo do jogo
TELAS.md    as 16 telas do protótipo
```

## Como rodar

### O que precisa

- [Godot 4.7.2](https://godotengine.org/download/) (a versão padrão, sem .NET).
- [Node.js 24](https://nodejs.org/) e npm.
- Um projeto no [Supabase](https://supabase.com/) (o plano grátis serve).

### 1. Servidor

```bash
cd server
npm install                 # também gera o cliente do Prisma
cp .env.example .env        # preencha DATABASE_URL e DIRECT_URL
npx prisma migrate deploy   # cria as tabelas no schema "ecobeasts"
npm run db:seed             # carrega o catálogo inicial (só em banco vazio)
npm run start:dev           # API em http://localhost:3100
```

As duas URLs do `.env` ficam no painel do Supabase, em **Connect > ORMs > Prisma**. O `.env` nunca vai para o git. Deixe o schema `ecobeasts` **fora** dos "Exposed schemas" do Supabase: o banco só deve ser acessado pela API.

Com o servidor no ar:

- `http://localhost:3100/docs`: a documentação da API, onde dá para testar as rotas;
- `http://localhost:3100/health`: confere o servidor e o banco.

Mais detalhes em [server/README.md](server/README.md).

### 2. Jogo

1. Abra o Godot e importe `client/project.godot`.
2. Com o servidor rodando, aperte **F5**.

O jogo baixa o catálogo da API ao abrir; sem o servidor, mostra "Não foi possível conectar ao servidor" e um botão para tentar de novo. O endereço da API é a configuração `ecobeast/api/base_url` do projeto (padrão `http://localhost:3100`).

## Testes

```bash
cd server
npm run lint
npm run typecheck
npm test            # testes de unidade
npm run test:e2e    # sobem a API e chamam as rotas contra o banco do .env
```

O cliente não tem testes automáticos. Cada fase é conferida rodando o jogo no editor e, quando faz sentido, no aparelho.

## Documentação

| Onde                                   | O quê                                                             |
| -------------------------------------- | ----------------------------------------------------------------- |
| [.specs/README.md](.specs/README.md)   | Como as specs são escritas e a ordem das fases                    |
| [.specs/roadmap.md](.specs/roadmap.md) | As próximas iniciativas e as decisões de stack                    |
| [.specs/glossary.md](.specs/glossary.md) | O vocabulário do jogo e o nome de cada conceito no código       |
| [GDD.md](GDD.md)                       | Regras, fórmulas e conteúdo                                       |
| [TELAS.md](TELAS.md)                   | As telas do protótipo                                             |
| `/docs` na API                         | As rotas, com exemplos reais do catálogo                          |

## Como o projeto é desenvolvido

- **Specs primeiro.** Toda entrega nasce de uma spec em `.specs/`, dividida em fases. Quando a implementação diverge, a spec muda no mesmo commit.
- **Uma fase por vez**, com um commit por fase: `feat` ou `fix` para implementação, `chore` para specs e configuração.
- **O banco é o dono do catálogo.** Valores (o poder de uma Técnica, os stats de uma espécie) se editam no banco e chegam ao jogo na próxima abertura; tabelas e colunas mudam só por migration.

## Licença

Ainda não há uma licença definida. Até lá, todos os direitos são reservados ao autor.

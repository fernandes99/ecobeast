# 07. Jogo lendo o catálogo da API

- **Status:** rascunho
- **Depende de:** [06-catalog-bundle](06-catalog-bundle.md)

## Contexto

O servidor devolve o catálogo inteiro em `GET /v1/catalog`, no mesmo formato dos arquivos `client/data/*.json` ([06](06-catalog-bundle.md)). O jogo ainda lê esses arquivos pela `StaticJsonDataSource` ([game-data/01](../game-data/01-data-layer.md)). Esta fase troca a fonte por uma `HttpDataSource`, que baixa o catálogo e guarda uma cópia no aparelho. Os JSON saem do cliente e vão para o servidor, como foto inicial para o seed. É a fase que prova a API de ponta a ponta: o jogo abre e mostra os iniciais vindos do banco.

Godot: o download usa o nó `HTTPRequest`, que faz a requisição em segundo plano e emite o sinal `request_completed` com o código e o corpo. Por isso o carregamento do catálogo passa a ser assíncrono (`await`).

## Escopo

- `HttpDataSource` com cache em `user://catalog_cache.json`.
- `GameData.load_catalog()` assíncrono, com três resultados.
- Boot com a tela de "sem conexão" e "Tentar de novo".
- Mover os JSON para `server/prisma/seed-data/` e remover a leitura local e o validador de linha de comando.

## Fora do escopo

- Jogador pela API (`auth-google`).
- Endereço da API de produção, HTTPS e a permissão de internet do Android (entram com o deploy e o `release-pipeline`). Nesta fase, o jogo é testado no PC contra o servidor local.

## Requisitos

- **RF-01:** `project.godot` ganha a configuração `ecobeast/api/base_url`, com o valor `http://localhost:3000`. O código lê com `ProjectSettings.get_setting`.
- **RF-02:** `res://core/data/http_data_source.gd` (`class_name HttpDataSource`, estende `DataSource`):
  - `_init(base_url: String, cache_path: String = "user://catalog_cache.json")`;
  - `fetch(host: Node) -> bool`, assíncrono: cria um `HTTPRequest` filho de `host` (com `timeout` de 10 segundos), baixa o catálogo e remove o nó no fim;
  - `load_tables(names: PackedStringArray) -> Dictionary` devolve as tabelas obtidas;
  - `get_errors() -> Array[String]`;
  - `used_cache: bool` diz se as tabelas vieram do cache.
- **RF-03:** O `fetch`:
  1. Lê o cache. Um cache ilegível, ou sem `version` (String) e `tables` (Dictionary), conta como ausente.
  2. Faz `GET <base_url>/v1/catalog`, com `If-None-Match: "<versão do cache>"` quando há cache.
  3. Com `200` e corpo válido (`version` String e `tables` Dictionary), usa o corpo e grava no cache. A gravação vai para `catalog_cache.tmp.json` e depois é renomeada, como o save.
  4. Com `304`, usa o cache.
  5. Com outro código, timeout, falha de conexão ou corpo inválido, usa o cache se houver, com `used_cache = true`.
  6. Sem cache, devolve `false`, com o erro "Não foi possível baixar o catálogo do servidor.".
- **RF-04:** `GameData.load_catalog()` passa a ser assíncrono e devolve uma das constantes `LOAD_OK`, `LOAD_OFFLINE` ou `LOAD_INVALID`:
  - cria a `HttpDataSource` com o endereço do RF-01;
  - `fetch(self)` falso → `LOAD_OFFLINE`;
  - senão, `catalog.load_from(source)`: com erros, `LOAD_INVALID` e os erros em `errors`; sem erros, `LOAD_OK`.
  
  O `CatalogValidator` continua conferindo tudo o que chega.
- **RF-05:** O boot (`res://screens/main/main.gd`) espera o `load_catalog()`:
  - `LOAD_INVALID` mostra o `ErrorView` com a lista, como hoje.
  - `LOAD_OFFLINE` mostra o `LoadErrorView` com "Não foi possível conectar ao servidor. Confira sua internet e tente de novo.".
  - O "Tentar de novo" refaz só a etapa que falhou: o catálogo, se ele falhou; o jogador, se o catálogo já carregou.
- **RF-06:** `client/data/` é movido para `server/prisma/seed-data/` com `git mv`. `SEED_DATA_DIR` (`server/src/catalog/catalog-tables.ts`) passa a apontar para lá. O seed e os testes do servidor continuam passando.
- **RF-07:** Saem do cliente `res://core/data/static_json_data_source.gd` e `res://tools/validate_data.gd` (com os `.uid`). `CatalogSchema` e `CatalogValidator` ficam.
- **RF-08:** Documentos atualizados:
  - `client/CLAUDE.md`: estrutura, comandos e a seção do catálogo, que passa a dizer que o catálogo mora no banco e se edita pelo painel do Supabase;
  - `CLAUDE.md` da raiz;
  - `.specs/README.md`: as regras de validação de fase e a seção "Como rodar o validador", que passa a usar os testes do servidor e o boot do jogo;
  - `.specs/game-data/architecture.md` ("Como o jogo lê o catálogo");
  - `.specs/foundation/architecture.md` (a árvore do cliente, sem `data/` e `tools/`).

## Critérios de aceite

- [ ] Com o servidor rodando (`npm run start:dev`) e o cache apagado, F5 no Godot abre o jogo normalmente: entrada, escolha com Fagulho, Gotículo e Brotelho, e Hub. O arquivo `catalog_cache.json` aparece em `%APPDATA%\Godot\app_userdata\Ecobeast\`.
- [ ] Mudar no painel o `name` de Gotículo para "Gotículo Teste", esperar 1 minuto e reabrir o jogo mostra o nome novo na escolha do inicial. (Desfazer depois.)
- [ ] Com o servidor parado e o cache presente, o jogo abre normalmente com o cache.
- [ ] Com o servidor parado e sem cache, aparece "Não foi possível conectar ao servidor…". Depois de subir o servidor, "Tentar de novo" abre o jogo.
- [ ] `client/data/` não existe mais. `server/prisma/seed-data/` tem os 23 arquivos com o histórico preservado (`git log --follow`).
- [ ] No servidor, `npm run db:seed` imprime "Banco já tem catálogo; nada foi feito.", e `npm test` e `npm run test:e2e` passam.
- [ ] O jogo roda sem erros de script (`godot --headless --path client --quit-after 30`, com o servidor no ar), e o editor não mostra avisos.

## Desenho técnico

**Criar**

- `res://core/data/http_data_source.gd`.

**Alterar**

- `res://core/autoload/game_data.gd`: RF-04.
- `res://screens/main/main.gd`: RF-05.
- `client/project.godot`: RF-01.
- `server/src/catalog/catalog-tables.ts`: RF-06.
- Os documentos do RF-08.

**Mover e remover**

- `client/data/` → `server/prisma/seed-data/` (RF-06).
- `res://core/data/static_json_data_source.gd` e `res://tools/validate_data.gd` (RF-07).

**Reaproveitar**

- `DataSource`, `Catalog`, `CatalogValidator`; o `LoadErrorView` e o `ErrorView` de `main.tscn`; a gravação atômica de `local_player_repository.gd` como modelo.

## Verificação

Com o servidor rodando (`cd server && npm run start:dev`):

```bash
godot --headless --path client --quit-after 30
```

E no editor (F5), os quatro cenários dos critérios: com servidor, com o nome mudado, sem servidor com cache e sem servidor sem cache. O cliente não tem testes automáticos (decisão do MVP); os do servidor rodam com `npm test` e `npm run test:e2e`.

## Tarefas

- [ ] `ecobeast/api/base_url` no `project.godot` (RF-01).
- [ ] `HttpDataSource` (RF-02, RF-03).
- [ ] `GameData.load_catalog()` assíncrono (RF-04) e o boot (RF-05).
- [ ] Conferir os quatro cenários dos critérios com uma cena temporária (como nas fases do MVP) e no F5; apagar a cena depois.
- [ ] `git mv client/data server/prisma/seed-data`; `SEED_DATA_DIR`; rodar o seed e os testes do servidor (RF-06).
- [ ] Remover `static_json_data_source.gd` e `validate_data.gd` (RF-07); conferir os avisos pelo editor.
- [ ] Documentos (RF-08).
- [ ] Marcar esta spec, a tabela do README e o `backend-api` no roadmap como `concluída`; commit `feat: jogo lê o catálogo da API`.

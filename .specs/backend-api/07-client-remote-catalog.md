# 07. Jogo lendo o catálogo da API

- **Status:** concluída
- **Depende de:** [06-catalog-bundle](06-catalog-bundle.md)

## Contexto

O servidor devolve o catálogo inteiro em `GET /v1/catalog`, no mesmo formato dos arquivos `client/data/*.json` ([06](06-catalog-bundle.md)). O jogo ainda lê esses arquivos pela `StaticJsonDataSource` ([game-data/01](../game-data/01-data-layer.md)). Esta fase troca a fonte por uma `HttpDataSource`, que baixa o catálogo e guarda uma cópia no aparelho. Os JSON saem do cliente e vão para o servidor, como foto inicial para o seed. É a fase que prova a API de ponta a ponta: o jogo abre e mostra os iniciais vindos do banco.

**O jogo é só online** (decisão do dono, contra trapaça). Sem resposta do servidor, o jogo não entra, mesmo com uma cópia guardada. A cópia serve só para não baixar de novo o que não mudou: o jogo manda a versão que tem, e o servidor responde `304` quando nada mudou. A cópia não é protegida contra edição e não precisa ser: o catálogo é público, e as regras que importam (batalha, captura, recompensas) vão ser decididas pelo servidor com o banco dele. Assim o jogo não ganha um modo sem rede que depois teria de ser retirado.

Godot: o download usa o nó `HTTPRequest`, que faz a requisição em segundo plano e emite o sinal `request_completed` com o código e o corpo. Por isso o carregamento do catálogo passa a ser assíncrono (`await`).

## Escopo

- `HttpDataSource` com cache em `user://catalog_cache.json`.
- `GameData.load_catalog()` assíncrono, com três resultados.
- Boot com "Conectando ao servidor…", a tela de "sem conexão" e "Tentar de novo".
- Porta padrão do servidor em desenvolvimento: 3100.
- Mover os JSON para `server/prisma/seed-data/` e remover a leitura local e o validador de linha de comando.

## Fora do escopo

- Jogar sem conexão.
- Jogador pela API (`auth-google`).
- Endereço da API de produção, HTTPS e a permissão de internet do Android (entram com o deploy e o `release-pipeline`). Nesta fase, o jogo é testado no PC contra o servidor local. Para testar no celular antes do deploy, ele precisaria alcançar o PC pela rede Wi-Fi (o IP do PC no lugar de `localhost`).

## Requisitos

- **RF-01:** `project.godot` ganha a configuração `ecobeast/api/base_url`, com o valor `http://localhost:3100`. O código lê com `ProjectSettings.get_setting`.
- **RF-02:** O servidor passa a usar a porta `3100` por padrão (`PORT` em `server/src/config/env.ts` e em `server/.env.example`), porque a 3000 costuma estar ocupada por outros projetos de desenvolvimento. Os documentos que citam a porta 3000 passam a citar a 3100.
- **RF-03:** `res://core/data/http_data_source.gd` (`class_name HttpDataSource`, estende `DataSource`):
  - `_init(base_url: String, cache_path: String = "user://catalog_cache.json")`;
  - `fetch(host: Node) -> bool`, assíncrono: cria um `HTTPRequest` filho de `host` (com `timeout` de 10 segundos), baixa o catálogo e remove o nó no fim;
  - `load_tables(names: PackedStringArray) -> Dictionary` devolve as tabelas obtidas;
  - `get_errors() -> Array[String]`;
  - `used_cache: bool` diz se as tabelas vieram do cache (o servidor respondeu `304`);
  - `clear_cache()` apaga a cópia guardada.
- **RF-04:** O `fetch`:
  1. Lê o cache. Um cache ilegível, ou sem `version` (String) e `tables` (Dictionary), conta como ausente.
  2. Faz `GET <base_url>/v1/catalog`, com `If-None-Match: "<versão do cache>"` quando há cache.
  3. Com `200` e corpo válido (`version` String e `tables` Dictionary), usa o corpo e grava no cache. A gravação vai para `catalog_cache.tmp.json` e depois é renomeada, como o save.
  4. Com `304` e cache, usa o cache, com `used_cache = true`.
  5. Com qualquer outro resultado (outro código, timeout, falha de conexão, corpo inválido), devolve `false`, com o erro "Não foi possível baixar o catálogo do servidor.". O cache fica no disco, mas não é usado.
- **RF-05:** `GameData.load_catalog()` passa a ser assíncrono e devolve uma das constantes `LOAD_OK`, `LOAD_OFFLINE` ou `LOAD_INVALID`:
  - cria a `HttpDataSource` com o endereço do RF-01;
  - `fetch(self)` falso → `LOAD_OFFLINE`;
  - senão, `catalog.load_from(source)`: com erros, `LOAD_INVALID` e os erros em `errors`; sem erros, `LOAD_OK`.
  - Se os erros vieram do cache (`used_cache`), a cópia guardada está estragada e o servidor continuaria respondendo `304` para ela. Nesse caso, `clear_cache()` e um novo `fetch`, uma vez só, antes de decidir o resultado.

  O `CatalogValidator` continua conferindo tudo o que chega.
- **RF-06:** O boot (`res://screens/main/main.gd`) espera o `load_catalog()`:
  - Enquanto o catálogo carrega, a tela mostra "Conectando ao servidor…".
  - `LOAD_INVALID` mostra o `ErrorView` com a lista, como hoje.
  - `LOAD_OFFLINE` mostra o `LoadErrorView` com "Não foi possível conectar ao servidor. Confira sua internet e tente de novo.".
  - O "Tentar de novo" refaz só a etapa que falhou: o catálogo, se ele falhou; o jogador, se o catálogo já carregou.
- **RF-07:** `client/data/` é movido para `server/prisma/seed-data/` com `git mv`. `SEED_DATA_DIR` (`server/src/catalog/catalog-tables.ts`) passa a apontar para lá. O seed e os testes do servidor continuam passando.
- **RF-08:** Saem do cliente `res://core/data/static_json_data_source.gd` e `res://tools/validate_data.gd` (com os `.uid`). `CatalogSchema` e `CatalogValidator` ficam.
- **RF-09:** Documentos atualizados:
  - `client/CLAUDE.md`: estrutura, comandos e a seção do catálogo, que passa a dizer que o catálogo mora no banco e se edita pelo painel do Supabase;
  - `CLAUDE.md` da raiz;
  - `.specs/README.md`: as regras de validação de fase e a seção "Como rodar o validador", que passa a usar os testes do servidor e o boot do jogo;
  - `.specs/game-data/README.md` e `.specs/game-data/architecture.md` ("Como o jogo lê o catálogo");
  - `.specs/foundation/architecture.md` (a árvore do cliente, sem `data/` e `tools/`);
  - `.specs/backend-api/architecture.md` ("Cliente (fase 07)").

## Critérios de aceite

- [x] Com o servidor rodando (`npm run start:dev`) e o cache apagado, F5 no Godot abre o jogo normalmente: entrada, escolha com Fagulho, Gotículo e Brotelho, e Hub. O arquivo `catalog_cache.json` aparece em `%APPDATA%\Godot\app_userdata\Ecobeast\`.
- [x] Reabrir o jogo sem mudança no catálogo usa a cópia guardada: o servidor responde `304`.
- [ ] Mudar no painel o `name` de Gotículo para "Gotículo Teste", esperar 1 minuto e reabrir o jogo mostra o nome novo na escolha do inicial. (Passo do dono; desfazer depois.)
- [ ] Com o servidor parado, com ou sem cache, aparece "Não foi possível conectar ao servidor…". Depois de subir o servidor, "Tentar de novo" abre o jogo. (O `LOAD_OFFLINE` com e sem cache foi conferido pelo script; a tela e o botão ficam para o F5 do dono.)
- [x] Uma cópia guardada com a versão certa e as tabelas estragadas não trava o jogo: ele baixa tudo de novo e abre normalmente.
- [x] `client/data/` não existe mais. `server/prisma/seed-data/` tem os 23 arquivos com o histórico preservado (`git log --follow`).
- [x] No servidor, `npm run db:seed` imprime "Banco já tem catálogo; nada foi feito.", e `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.
- [x] O jogo roda sem erros de script (`godot --headless --path client --quit-after 30`, com o servidor no ar), e o editor não mostra avisos.

## Desenho técnico

**Criar**

- `res://core/data/http_data_source.gd`.

**Alterar**

- `res://core/autoload/game_data.gd`: RF-05.
- `res://screens/main/main.gd` e `main.tscn`: RF-06.
- `client/project.godot`: RF-01.
- `server/src/config/env.ts`, `env.spec.ts` e `server/.env.example`: RF-02.
- `server/src/catalog/catalog-tables.ts`: RF-07.
- Os documentos do RF-02 e do RF-09.

**Mover e remover**

- `client/data/` → `server/prisma/seed-data/` (RF-07).
- `res://core/data/static_json_data_source.gd` e `res://tools/validate_data.gd` (RF-08).

**Reaproveitar**

- `DataSource`, `Catalog`, `CatalogValidator`; o `LoadErrorView` e o `ErrorView` de `main.tscn`; a gravação atômica de `local_player_repository.gd` como modelo.

## Verificação

Com o servidor rodando (`cd server && npm run start:dev`):

```bash
godot --headless --path client --quit-after 30
```

E no editor (F5), os cenários dos critérios: com servidor, reaberto sem mudança, com o nome mudado, sem servidor (com e sem cache) e com a cópia estragada. O cliente não tem testes automáticos (decisão do MVP); os do servidor rodam com `npm test` e `npm run test:e2e`.

## Tarefas

- [x] Porta 3100 no servidor e nos documentos (RF-02).
- [x] `ecobeast/api/base_url` no `project.godot` (RF-01).
- [x] `HttpDataSource` (RF-03, RF-04).
- [x] `GameData.load_catalog()` assíncrono (RF-05) e o boot (RF-06).
- [x] Conferir os cenários dos critérios com um script temporário (como nas fases do MVP) e no F5; apagar o script depois.
- [x] `git mv client/data server/prisma/seed-data`; `SEED_DATA_DIR`; rodar o seed e os testes do servidor (RF-07).
- [x] Remover `static_json_data_source.gd` e `validate_data.gd` (RF-08); conferir os avisos pelo editor.
- [x] Documentos (RF-09).
- [x] Marcar esta spec, a tabela do README e o `backend-api` no roadmap como `concluída`; commit `feat: jogo lê o catálogo da API`.

## Decisões da implementação

- **"Conectando ao servidor…"**: um `LoadingLabel` em `main.tscn` aparece enquanto o catálogo carrega. Sem ele, a tela ficaria vazia até o limite de 10 segundos.
- **Servidor parado no PC:** com o servidor fora do ar em `localhost`, o Windows não recusa a conexão na hora, e o pedido termina pelo limite de 10 segundos (resultado `RESULT_TIMEOUT`). Num celular sem rede, o endereço nem é encontrado, e a falha é rápida.
- **A cópia guardada é o texto da resposta**, gravado como chegou, sem passar de novo pelo `JSON.stringify` do Godot.
- **Avisos para quem desenvolve:** uma falha do download faz `push_warning` com o endereço, o resultado do `HTTPRequest` e o código HTTP. Uma cópia estragada também avisa antes de ser baixada de novo.
- **Conferência:** um script temporário (`tmp_check/check_catalog.gd`, apagado depois) passou por 21 verificações contra o servidor real na porta 3100:
  - sem cache, com cache (`304`) e com cache ilegível;
  - servidor parado, com e sem cache;
  - `clear_cache`, a barra no fim do endereço e a remoção do `HTTPRequest`;
  - o `GameData` com servidor, com a cópia estragada e sem servidor.

  O boot headless rodou sem erros de script com o servidor no ar e fora dele, e o editor não mostra avisos nos 46 scripts.
- **A `.env` de cada máquina** precisa ter `PORT=3100`, ou nenhuma linha `PORT`, para o jogo achar o servidor. O `.env.example` já traz o valor novo.

# Arquitetura

O desenho que as fases da [map-editor](README.md) compartilham. As decisões e o motivo de cada uma estão no README.

## Fluxo

```text
F2 (jogo rodando pelo editor)  →  a janela do editor abre e pede GET /v1/editor/islands

Ilha nova, do zero             →  o editor monta um hexágono de raio N, todo temperate flat
Ilha nova, pelo gerador        →  POST /v1/editor/map-generator {seed, config}
                                  devolve os hexágonos e a chegada; gerar de novo até gostar
                                  →  POST /v1/editor/islands {o rascunho inteiro}

Abrir uma ilha                 →  GET /v1/editor/islands/:id  (o rascunho)
Salvar                         →  PUT /v1/editor/islands/:id/draft {o rascunho inteiro}
Publicar                       →  POST /v1/editor/islands/:id/publish
                                  o servidor confere o rascunho e o copia para a publicada
```

O jogador não lê nada disto nesta iniciativa. A rota do jogador, que lê só as publicadas, nasce na `islands`.

## Tabelas

Todas no schema `ecobeasts`. `building_types` é catálogo, editado pelo painel do Supabase e enviado pelo `GET /v1/catalog`. As outras são conteúdo do editor: só as rotas do editor as escrevem.

### `building_types` (catálogo)

| Coluna | Tipo | O que é |
| --- | --- | --- |
| `id` | int | |
| `slug` | text, único | `refuge`, `shop`, `arena`, `house`. `CHECK ^[a-z0-9_]+$` |
| `name` | text | Refúgio, Loja, Arena, Casa |
| `color_hex` | text | A cor dos hexágonos dela no editor, `#RRGGBB` (`CHECK`), como a dos Elementos |

A tela que cada tipo abre não fica no banco: é a `islands` que liga o `slug` à tela do jogo (`refuge` → `heal_station`, `shop` → `shop`). Arena e Casa não abrem nada por enquanto. Os nomes e as cores são _a revisar_.

### `islands`

| Coluna | Tipo | O que é |
| --- | --- | --- |
| `id` | int | |
| `created_at` | timestamptz | |
| `published_at` | timestamptz, nulo | A última publicação; nulo se nunca foi publicada |

### `island_maps`: as duas versões

| Coluna | Tipo | O que é |
| --- | --- | --- |
| `id` | int | |
| `island_id` | int, FK `islands` (`CASCADE`) | |
| `kind` | text | `draft` ou `published` (`CHECK`) |
| `name` | text | O nome da ilha nesta versão, de 1 a 40 caracteres (`CHECK`) |
| `start_q`, `start_r` | int | A chegada |
| `content_hash` | text | O sha-256 desta versão em JSON canônico, para o `status` (veja "Rotas") |
| `updated_at` | timestamptz | |

Único `(island_id, kind)`. Uma ilha sempre tem o rascunho, e tem a publicada depois da primeira publicação. O nome fica na versão: renomear só chega ao jogador ao publicar.

### Os hexágonos, as construções e as áreas de uma versão

| Tabela | Colunas | Observações |
| --- | --- | --- |
| `island_tiles` | `island_map_id` (FK `CASCADE`), `q`, `r`, `biome_id` (FK `biomes`, `RESTRICT`), `height`, `variant`, `area_id` (FK `island_areas`, nulo, `SET NULL`) | Chave `(island_map_id, q, r)`. `height` de 0 a 4 e `variant` de 1 a 6 (`CHECK`). O bioma é um dos 7, e a variante de 1 a 3 em `hill` e `mountain` é conferida na rota. Até a [terrain-height](../terrain-height/README.md), a coluna era `shape` (`flat`, `hill`, `mont`), e o bioma era um dos 5 de terreno |
| `island_buildings` | `id`, `island_map_id` (FK `CASCADE`), `building_type_id` (FK `RESTRICT`) | |
| `island_building_tiles` | `building_id` (FK `CASCADE`), `island_map_id`, `q`, `r` | Chave `(building_id, q, r)` e único `(island_map_id, q, r)`: dois prédios nunca dividem um hexágono |
| `island_areas` | `id`, `island_map_id` (FK `CASCADE`), `name` (1 a 40), `color_hex` (`#RRGGBB`), `spawn_count` (1 a 200, padrão 10) | A cor serve só ao editor. `spawn_count` é quantos Ecobeasts nascem na área a cada entrada ([islands/01](../islands/01-area-spawn-count.md)) |
| `island_area_species` | `area_id` (FK `CASCADE`), `species_id` (FK `RESTRICT`), `weight` (> 0), `min_level`, `max_level` (1 a 100, `min_level <= max_level`) | Chave `(area_id, species_id)` |

Um hexágono sem área não tem Ecobeasts selvagens. Salvar apaga as linhas do rascunho e grava de novo, numa transação só. Publicar faz o mesmo com a versão publicada, copiando do rascunho, e grava `published_at`.

## Quem edita

- **`MAP_EDITOR_USER_IDS`:** uma lista de ids de usuário do Supabase Auth (o `sub` do token), separados por vírgula, no `.env` do servidor. O `.env.example` traz o nome vazio. Vazia ou ausente, todas as rotas do editor respondem `404` "Rota não encontrada.", como as de depuração.
- **`EditorGuard`:** depois do `AuthGuard`, confere se o `sub` está na lista. Fora dela, `403` "Só quem edita o mapa pode usar esta rota.".
- O servidor de produção (Render) fica com a variável vazia, a não ser que o dono queira. O dono edita com o servidor local (`npm run start:dev`), que grava no mesmo banco do Supabase.

## Contrato

Todas as rotas sob `/v1/editor`, com `@UseGuards(AuthGuard, EditorGuard)`, documentadas no OpenAPI. As rotas do editor aceitam corpo de até 5 MB (uma ilha de 20.000 hexágonos passa de 1 MB em JSON, e o limite padrão do Nest é 100 KB). As outras rotas ficam com o limite de hoje.

### O rascunho

O mesmo formato vai e volta (ler, criar, salvar):

```json
{
  "name": "Ilha das Brumas",
  "start": { "q": 0, "r": 0 },
  "tiles": [{ "q": 0, "r": 0, "biome": "temperate", "height": 1, "variant": 2, "area": 1 }],
  "buildings": [{ "building_type_id": 1, "tiles": [{ "q": 3, "r": -1 }, { "q": 4, "r": -1 }] }],
  "areas": [
    {
      "key": 1,
      "name": "Bosque do norte",
      "color_hex": "#5B8C3A",
      "spawn_count": 10,
      "species": [{ "species_id": 4, "weight": 60, "min_level": 3, "max_level": 6 }]
    }
  ]
}
```

- `area` no hexágono e `key` na área são números do próprio rascunho, de 1 em diante, só para ligar um ao outro. O servidor não os guarda como id: ao ler, devolve as áreas numeradas de novo, na ordem do `id`.
- `area` é opcional; sem ele, o hexágono não tem área.

### Conferências ao salvar (`400`, mensagem em pt-BR)

1. Nome de 1 a 40 caracteres.
2. De 1 a 20.000 hexágonos, sem `(q, r)` repetido. `biome`, `height` e `variant` válidos.
3. A chegada é um hexágono da ilha.
4. Cada construção tem um tipo que existe e pelo menos 1 hexágono. Todos os hexágonos dela existem na ilha, e nenhum é de outra construção.
5. `key` sem repetição; todo `area` de hexágono aponta para uma `key` que existe. `spawn_count` de 1 a 200 ([islands/01](../islands/01-area-spawn-count.md)). Espécies que existem, sem repetir na mesma área, com peso inteiro maior que 0 e níveis de 1 a 100, mínimo até o máximo.

Uma ilha pela metade pode ser salva: as conferências acima só garantem que os dados fazem sentido.

### Conferências ao publicar (`409`, mensagem em pt-BR)

Tudo de salvar, mais:

1. A chegada não é água (`wshallow`, `wdeep`) nem hexágono de construção.
2. Toda área tem pelo menos 1 espécie.

A lista é _a revisar_: a `islands` pode acrescentar regras quando o jogo passar a andar nas ilhas.

### Rotas

| Rota | O que faz | Resposta |
| --- | --- | --- |
| `GET /v1/editor/islands` | Lista as ilhas | `200 {islands: [{id, name, status, updated_at, published_at}]}`. `name` é o do rascunho. `status`: `draft` (nunca publicada), `published` (o rascunho é igual à publicada) ou `changed` (há mudanças não publicadas) |
| `POST /v1/editor/islands` | Cria uma ilha com o rascunho do corpo | `201 {id}` |
| `GET /v1/editor/islands/:id` | O rascunho | `200`, no formato acima, mais `id` e `status`. `404` "Ilha não encontrada." |
| `PUT /v1/editor/islands/:id/draft` | Troca o rascunho inteiro | `200 {status, updated_at}` |
| `POST /v1/editor/islands/:id/publish` | Confere e copia o rascunho para a publicada | `200 {status, published_at}` |
| `DELETE /v1/editor/islands/:id` | Apaga uma ilha que nunca foi publicada | `204`. `409` "Uma ilha publicada não pode ser apagada." |
| `GET /v1/editor/map-generator` | Os parâmetros do gerador | `200 {defaults, ranges}`: o `DEFAULT_MAP_CONFIG` e, para cada campo, `{min, max}`. O editor monta o formulário com eles |
| `POST /v1/editor/map-generator` | Roda o gerador, sem gravar nada | `200 {start, tiles}` |

- **`status` igual ou mudado:** o servidor guarda, em `island_maps`, um `content_hash` (sha-256 do rascunho em JSON canônico) a cada salvar e publicar, e compara os dois. É mais simples que comparar as tabelas.
- **O gerador:** o corpo é `{seed, config}`. `seed` é um inteiro de 0 a 2³² − 1. `config` traz qualquer campo de `MapConfig`, e o que faltar vem de `DEFAULT_MAP_CONFIG`. Faixas aceitas, _a revisar_: `tileCount` de 100 a 20.000; `edgeRoughness` de 0 a 500; `noiseScale` de 0,005 a 0,5; as frações e limites (`waterFraction`, `deepFraction`, `wetLimit`, `stoneFraction`, `hillFrom`, `mountainFrom`, `islandChance`, `detailChance`) de 0 a 1; `cleanupPasses` de 0 a 10. A resposta não traz Ecobeasts nem Domadores.

## Servidor

```
server/src/editor/
  editor.module.ts
  editor.guard.ts              EditorGuard e a leitura de MAP_EDITOR_USER_IDS
  islands-editor.controller.ts
  islands-editor.service.ts    ler, criar, salvar, publicar, apagar, status
  islands-editor.dto.ts
  map-generator.controller.ts  POST /v1/editor/map-generator
server/src/domain/islands/
  island-draft.ts              as conferências de salvar e de publicar, puras, com testes
```

O `building_types` entra no catálogo como os outros recursos (`server/src/catalog/`, `GET /v1/catalog`) e no `CatalogValidator` do jogo.

## Jogo

```
res://tools/map_editor/
  map_editor.gd            a janela: barra de cima, painéis, atalhos, aviso de não salvo
  island_list.gd           a lista de ilhas, ilha nova, apagar
  new_island_dialog.gd     do zero (nome e raio) ou pelo gerador (nome, seed, parâmetros, gerar de novo)
  island_draft.gd          IslandDraft: o rascunho em memória, de/para o JSON do contrato
  editor_canvas.gd         o HexMapView com zoom, arrastar e as camadas por cima
  editor_tools.gd          os pincéis e o que cada um muda no rascunho
  editor_history.gd        desfazer e refazer, sobre o UndoRedo do Godot
```

- **A janela:** como a do content-viewer. A cena raiz (`res://screens/main/main.gd`) trata o F2 só com `OS.has_feature("editor")`, e `MapEditor` estende `Window` com `force_native = true`, 1600×900 de início, redimensionável, título "Ecobeast: editor de ilhas". O jogo atrás continua rodando.
- **Sem login ou sem permissão:** sem sessão, a janela mostra "Entre no jogo para usar o editor." Com `404` ou `403` das rotas, mostra "O editor está desligado neste servidor." e o que falta (a variável `MAP_EDITOR_USER_IDS`).
- **As chamadas:** pelo `Api` autoload, como os serviços do jogo, num serviço só do editor (`res://tools/map_editor/editor_api.gd`). Nenhuma tela do jogo depende de `res://tools/map_editor/`.
- **O desenho:** o `IslandDraft` monta um `ExplorationMap` para o `HexMapView`. Pintar muda o rascunho e manda o `HexMapView` refazer só as linhas de hexágonos tocadas (um método novo, `update_tiles(coords)`), para o pincel não esperar a ilha inteira. Por cima dele, numa camada do editor: a cor das construções com o nome, a cor das áreas (que liga e desliga), a bandeira da chegada e o contorno do pincel.
- **Zoom e arrastar:** roda do mouse para o zoom, centrado no ponteiro. Botão do meio, ou espaço com o botão esquerdo, para arrastar.
- **A visão de cima:** o `HexMapView` monta só as linhas perto da tela, porque montar o mapa inteiro trava o jogo ([wild-battle](../wild-battle/architecture.md)). Para ver e pintar a ilha inteira, abaixo de um zoom o editor troca o `HexMapView` por uma visão plana: uma textura com um hexágono de cor chapada por hexágono da ilha, na cor média da textura do bioma, sem a altura, com as mesmas camadas por cima. Os pincéis funcionam nas duas visões. A tecla Tab alterna à mão.
- **Os pincéis:** bioma, altura, pôr hexágono, tirar hexágono, construção, área e chegada ([terrain-height](../terrain-height/01-terrain-height.md)). O tamanho é um raio de 0 a 10 hexágonos. Pôr hexágono sorteia a variante como o gerador (`detailChance`) nos biomas de 6 variantes, e de 1 a 3 em `hill` e `mountain`; trocar o bioma só sorteia de novo se a variante passar do máximo dele.
- **Desfazer:** cada pincelada, do apertar ao soltar do botão, é um passo do `UndoRedo`. Ctrl+Z desfaz, Ctrl+Y refaz. Salvar não apaga o histórico; trocar de ilha apaga.
- **Não salvo:** o título da janela ganha um `*`. Trocar de ilha ou fechar a janela com mudanças pergunta "Salvar as mudanças?" (Salvar, Descartar, Cancelar). Ctrl+S salva.

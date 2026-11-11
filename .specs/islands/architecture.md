# Arquitetura

O desenho que as fases da [islands](README.md) compartilham. As decisões e o motivo de cada uma estão no README.

## Fluxo

```text
Hub, "Ilhas"           →  GET /v1/me/islands
                          as ilhas publicadas: id e nome

Tocar numa ilha        →  tela de Explorar zona com { island_id }
                          POST /v1/me/exploration { island_id }
                          o servidor lê a versão publicada, sorteia os Ecobeasts pelas
                          áreas e guarda a exploração na memória, como hoje
                          devolve o mapa da ilha, os Ecobeasts e as construções

Andar                  →  nada vai para o servidor, como hoje
Pisar numa construção  →  o jogo abre a tela do tipo (Refúgio, Loja); Arena e Casa, nada
Procurar               →  POST /v1/me/board-battle/wild { q, r }, sem mudança
```

## A quantidade de cada área ([01](01-area-spawn-count.md))

- **Banco:** `island_areas` ganha `spawn_count` (int, `CHECK` de 1 a 200, padrão 10, _a revisar_). A migração dá 10 às áreas que já existem.
- **Contrato do editor:** cada área do rascunho ([map-editor](../map-editor/architecture.md#o-rascunho)) ganha `spawn_count`. Salvar recusa fora da faixa (400, "Na área N, a quantidade de Ecobeasts precisa ir de 1 a 200."). O JSON canônico do `content_hash` passa a ter o campo: uma ilha publicada antes desta fase aparece como "Publicada, com mudanças" na primeira vez que for salva, até ser publicada de novo.
- **Editor:** o painel da área ganha "Ecobeasts nesta área", um campo de número logo abaixo do nome. Uma área nova começa com 10.

## Rotas do jogador ([02](02-island-exploration.md))

### `GET /v1/me/islands`

`200 {islands: [{id, name}]}`, as publicadas, em ordem de `id`, com o nome da versão publicada. Com `AuthGuard`, como as outras rotas do jogador. Fica em `/me` porque a liberação por jogador virá depois.

### `POST /v1/me/exploration`

O corpo passa a ser opcional:

- **Sem corpo:** o mapa sorteado de hoje, sem mudança.
- **Com `{island_id}`:** a versão publicada da ilha. `404` "Ilha não encontrada." se ela não existe ou nunca foi publicada. `409` "Crie seu Domador primeiro." como hoje.

A resposta é a mesma de hoje, com dois campos a mais no `map`:

```json
{
  "map": {
    "seed": 7,
    "start": { "q": 0, "r": 0 },
    "tiles": [{ "q": 0, "r": 0, "biome": "temperate", "shape": "flat", "variant": 2 }],
    "creatures": [{ "id": 1, "species_id": 4, "q": 3, "r": -1 }],
    "tamers": [],
    "island": { "id": 7, "name": "Ilha das Brumas" },
    "buildings": [{ "building_type_id": 1, "tiles": [{ "q": 2, "r": 0 }] }]
  }
}
```

- `seed` é o id da ilha: no desenho, ele escolhe as decorações e os escorridos dos paredões, e o editor usa o mesmo id, então a ilha fica igual à do editor.
- `island` e `buildings` só vêm numa ilha; no mapa sorteado, `island` é `null` e `buildings` é `[]`.
- `tamers` vem vazio numa ilha.

### Os Ecobeasts de uma ilha

Uma função pura nova, `rollAreaSpawns(areas, random)`, em `server/src/domain/islands/`:

- Recebe cada área com os hexágonos dela, a quantidade e as espécies (id, peso, nível mínimo e máximo).
- Os hexágonos de cada área chegam já sem os de construção (`spawnAreas(draft)`, outra função pura do mesmo arquivo).
- Para cada área com hexágono e espécie, sorteia `spawn_count` Ecobeasts:
  - cada um num hexágono da área, escolhido de forma uniforme, e podendo repetir. Hexágonos de construção ficam de fora: um selvagem no Refúgio não faz sentido. A área cujos hexágonos são todos de construção não sorteia nada;
  - a espécie sorteada pelo peso;
  - o nível sorteado de forma uniforme entre o mínimo e o máximo dela.
- Devolve `MapSpawn`s, como o `rollSpawns`, com ids de 1 em diante.

A luta usa esses `MapSpawn`s sem mudança: `takeSpawn` confere a posição e tira o Ecobeast do mapa, e `createEnemy` usa a espécie e o nível dele.

### Ler a ilha publicada

A leitura de uma versão (`readVersion`, hoje no `IslandsEditorService`) passa para um serviço compartilhado, `IslandsService`, em `server/src/islands/`. O editor e a exploração usam o mesmo. O módulo dele também tem o controller de `GET /v1/me/islands`.

## Jogo ([03](03-island-screens.md))

- **Hub:** a ação Ilhas, depois de Explorar zona, com o subtítulo "Visite as ilhas do mundo." e a cor em `UiPalette.ACTION_COLORS` (`&"islands"`, _a revisar_). A arte é a de Explorar zona até haver uma própria.
- **Tela `islands`:** a lista das ilhas, cada uma com o nome, num cartão tocável, e "Nenhuma ilha publicada ainda." sem nenhuma. Tocar abre `exploration` com `{"island_id": id}`, e voltar leva ao Hub.
- **Tela `exploration` numa ilha:** o mesmo fluxo, com `Session.start_exploration(island_id)`. Muda só o que segue:
  - O título é o nome da ilha.
  - As construções aparecem na cor do tipo, por cima do terreno e por baixo do Domador e dos Ecobeasts, com o nome por cima de tudo. A `HexTintLayer` sai de `res://tools/map_editor/` para `res://ui/components/`, porque uma tela do jogo não pode depender da pasta do editor.
  - Entrar numa construção abre a tela do tipo, pelo `slug` do catálogo: `refuge` abre `heal_station` e `shop` abre `shop`. "Entrar" é terminar um passo num hexágono dela vindo de fora dela; andar entre hexágonos da mesma construção não abre de novo. Fechar volta para o mapa, no mesmo hexágono (a tela da ilha fica embaixo, na pilha do `Router`).
  - O menu de depuração fica como está.
- **Modelos:** o `ExplorationMap` ganha `island_id`, `island_name` e `buildings` (os hexágonos e o tipo de cada construção). Num mapa sorteado, os três ficam vazios.

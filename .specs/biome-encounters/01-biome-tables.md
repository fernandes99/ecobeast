# 01. Tabelas de biomas e taxas

- **Status:** concluída
- **Depende de:** nenhuma outra fase da iniciativa

## Contexto

Os biomas existem só como texto no gerador do mapa, e nenhum dado diz onde cada espécie aparece. Esta fase cria as duas tabelas, com a carga inicial, sem mudar o que acontece no jogo.

## Escopo

- Tabelas `biomes` e `species_biomes`, com migration.
- Carga inicial com os 7 biomas e as taxas dos 9 Ecobeasts.
- As duas tabelas no catálogo (`GET /v1/catalog`) e no `CatalogValidator`.

## Fora do escopo

- Usar as taxas: isso começa na [fase 02](02-spawn-rules.md).
- Mostrar o bioma em alguma tela.
- Mudar o gerador do mapa.

## Requisitos

- **RF-01:** `biomes` tem `id`, `slug`, `name` e `description`, no padrão de `elements` e `rarities`, com os 7 biomas da [arquitetura](architecture.md#biomas-de-encontro).
- **RF-02:** `species_biomes` tem `species_id`, `biome_id` e `rate`, com chave nos dois primeiros e FK para `species` e `biomes`.
- **RF-03:** `rate` é um inteiro de 0 a 100, garantido por um `CHECK` no banco.
- **RF-04:** Uma espécie sem linha para um bioma não nasce nele. A carga inicial não grava taxa 0, mas o painel aceita 0.
- **RF-05:** As duas tabelas aparecem em `GET /v1/catalog`.
- **RF-06:** O jogo abre com o catálogo novo, e o `CatalogValidator` confere as duas tabelas e as FKs delas.

## Critérios de aceite

- [x] No painel do Supabase, `biomes` tem 7 linhas, e `species_biomes` tem as taxas abaixo.
- [x] Gravar `rate` 101 ou -1 falha no banco.
- [ ] Mudar o `name` de um bioma no painel aparece no `GET /v1/catalog`. Falta do dono: o catálogo já lê do banco, com cache de 60 s, mas nada foi editado no painel.
- [x] O Elu tem linha em boreal e em montanha, com a taxa de montanha bem menor, e nenhuma linha de água.
- [x] O jogo abre sem erro nos dados.

## Desenho técnico

### Biomas

Nomes e descrições _a revisar_. O `slug` é usado no código e não muda.

| id | slug | name | description |
| ---: | --- | --- | --- |
| 1 | `temperate` | Planície | Campos abertos e bosques de folhas largas. |
| 2 | `boreal` | Boreal | Pinheiros fechados, frio e chão úmido. |
| 3 | `stone` | Pedra | Chão de rocha exposta, com pouca vegetação. |
| 4 | `hill` | Colina | Encostas onde o terreno começa a subir. |
| 5 | `mountain` | Montanha | Picos altos, de ar rarefeito e pouca comida. |
| 6 | `wshallow` | Água rasa | Margens e poças, onde a maré vai e volta. |
| 7 | `wdeep` | Água profunda | Longe da margem, onde a luz quase não chega. |

### Taxas iniciais

_A revisar._ Saem das descrições de `species.json`. Um traço significa que a espécie não tem linha naquele bioma. Hushling e Echofrost ficam sem linhas até terem folhas:

| Espécie | Planície | Boreal | Pedra | Colina | Montanha | Água rasa | Água profunda |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Ruvo | 60 | 10 | 30 | 50 | 20 | — | — |
| Ruvak | 20 | 5 | 30 | 40 | 40 | — | — |
| Ruvaroth | 3 | — | 15 | 10 | 20 | — | — |
| Nilu | 5 | 5 | — | — | — | 100 | 30 |
| Nilgar | 3 | 3 | — | — | — | 60 | 40 |
| Nilgorr | — | — | — | — | — | 10 | 30 |
| Elu | 50 | 100 | 5 | 15 | 5 | — | — |
| Eluvin | 20 | 50 | 3 | 10 | 3 | — | — |
| Eluvara | 5 | 25 | — | 3 | 1 | — | — |

### Arquivos

- `server/prisma/schema.prisma`: modelos `Biome` e `SpeciesBiome`, no schema `ecobeasts`.
- `server/prisma/migrations/`: migration com as tabelas e o `CHECK`.
- `server/prisma/seed-data/biomes.json` e `species_biomes.json`.
- `server/src/catalog/catalog-tables.ts`: entradas `biomes` (depois de `rarities`) e `species_biomes` (depois de `species`, antes de `starter_options`), e o comentário das 25 tabelas passa para 27.
- `client/core/data/catalog_schema.gd`: colunas e FKs das duas tabelas.
- `.specs/game-data/architecture.md`: documenta as tabelas e troca a nota de `zones` e `zone_encounters`, que `biomes` e `species_biomes` substituem.
- `GDD.md`: `habitatZones` e `spawnWeight` passam a apontar para `species_biomes`.
- `.specs/glossary.md`: a entrada **Bioma** ganha a tabela e os biomas de encontro.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

Os testes de `catalog-tables`, `seed.e2e-spec.ts` e `bundle.e2e-spec.ts` já percorrem todas as tabelas de `CATALOG_TABLES`.

A carga inicial (`npm run db:seed`) só preenche tabelas vazias. Ela leva as duas tabelas novas ao banco atual sem tocar nas outras, nem em Hushling e Echofrost, que não estão em `seed-data/`.

## Tarefas

- [x] Escrever o teste do `CHECK` e dos 7 slugs, e ver falhar.
- [x] Criar modelos, migration e carga inicial.
- [x] Incluir as tabelas no catálogo e no `catalog_schema.gd`.
- [x] Atualizar `game-data/architecture.md`, `GDD.md` e `glossary.md`.
- [x] Rodar a verificação e abrir o jogo.

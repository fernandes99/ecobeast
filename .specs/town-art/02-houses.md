# 02. As casas da cidade

- **Status:** rascunho
- **Depende de:** [01-key-buildings](01-key-buildings.md)

## Contexto

As casas de hoje (Casa, Casa média e Casa grande) vêm do pacote Sunnyside, de traço terroso, e ficam diferentes das construções-chave da [01](01-key-buildings.md). Esta fase cria três tipos novos de casa, no estilo do [guia](style-guide.md), ao lado dos de hoje. Por pedido do dono, nada do que existe é apagado nem trocado: as casas de hoje e as ilhas que as usam continuam iguais.

## Escopo

- Três tipos de objeto novos no catálogo, com a arte gerada pelo `make_town.gd`.

## Fora do escopo

- Mudar, apagar ou redesenhar `house` (1), `house_medium` (18) e `house_large` (19), ou o `make_objects.gd`.
- Trocar as casas das ilhas que já existem.
- O moinho e os outros objetos da vila (a [03](03-village-objects.md)).

## Requisitos

- **RF-01:** O catálogo ganha os tipos abaixo, com os mesmos formatos e bloqueios dos tipos de hoje (todos os hexágonos bloqueiam). _Os nomes, os modelos e as cores estão a revisar:_

  | id | slug | name | Formato | Variantes | Modelos | Telhados, na ordem |
  | --- | --- | --- | --- | --- | --- | --- |
  | 24 | `town_house` | Casa (cidade) | um | 9 | chalé, casa com chaminé, casa com varanda | laranja, verde, roxo |
  | 25 | `town_house_medium` | Casa média (cidade) | par | 12 | casa comprida, sobrado, casa com oficina | laranja, marrom, verde, turquesa |
  | 26 | `town_house_large` | Casa grande (cidade) | triângulo | 10 | casarão com torre, sobrado de dois andares | laranja, marrom, mostarda, roxo, turquesa |

- **RF-02:** A variante `v` é o modelo `(v - 1) % modelos` com o telhado `(v - 1) / modelos` da lista, contando de 0. Os telhados são só os das casas no guia: nunca vermelho, azul nem ardósia.
- **RF-03:** As casas seguem o guia e ficam menos chamativas que as construções-chave: sem emblema, sem faixa colorida na parede, e com detalhes de casa (chaminé, varanda, floreira, cortina).
- **RF-04:** A largura cabe no formato, como diz o guia, e a Casa de 1 hexágono não passa de 80 px de altura.

## Critérios de aceite

- [ ] O gerador grava as 9, 12 e 10 variantes, e os PNGs de `house`, `house_medium` e `house_large` não mudam.
- [ ] Numa imagem com todas as variantes lado a lado, nenhuma tem telhado vermelho, azul ou ardósia, e nenhuma tem emblema.
- [ ] Numa imagem do mapa com uma casa de cada tipo ao lado do Refúgio, da Loja e do Domador, as construções-chave se destacam e a porta cabe no Domador.
- [ ] O catálogo traz os três tipos, e o editor os põe (com o dono, no F2).

## Desenho técnico

- **Servidor:** a migração `server/prisma/migrations/20261116000000_town_houses/migration.sql`, no formato da [01](01-key-buildings.md), e as linhas em `server/prisma/seed-data/map_object_types.json` e `map_object_type_tiles.json`. O teste da carga (`src/catalog/catalog-tables.spec.ts`) passa a contar 21 objetos.
- **`make_town.gd`:** os três tipos no `TYPES`, uma função por modelo e a tabela de telhados.
- **Specs:** a tabela de tipos e a de tamanhos do [architecture.md da island-villages](../island-villages/architecture.md#os-tipos-de-objeto).

## Verificação

```bash
godot --headless -s res://assets/map_objects/make_town.gd -- town_house town_house_medium town_house_large
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Uma cena temporária com todas as variantes e outra com uma casa de cada tipo ao lado do Refúgio, da Loja e do Domador, conferidas pelo guia.

## Tarefas

- [ ] A migração, a carga inicial e o teste da carga.
- [ ] Os modelos e a tabela de telhados no `make_town.gd`.
- [ ] Conferir nas imagens e atualizar o `architecture.md` da island-villages e o `client/CLAUDE.md`.

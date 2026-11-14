# 01. A limpeza dos objetos

- **Status:** concluída (falta o dono abrir a ilha dele)
- **Depende de:** [free-trails](../free-trails/README.md) (concluída)

## Contexto

O dono quer só 6 objetos de grade e o resto fora do projeto ([README](README.md#contexto)). Hoje o catálogo tem 31. Além deles, saem os 3 carimbos de `client/tools/map_editor/stamps/`, porque o dono pediu ("Apague todos os carimbos"). Isso inclui o `teste.json`, que nunca entrou no git.

## Escopo

- A migration que apaga os 25 tipos e os objetos deles nas ilhas.
- Os dados de `seed-data` e os testes do servidor.
- A arte, os geradores e o código do cliente que só serviam aos tipos apagados.
- Os carimbos.

## Fora do escopo

- As peças soltas e as decorações naturais.
- A ferramenta Carimbo, que continua funcionando, só que sem nenhum carimbo pronto.
- As ações das ilhas, que continuam nos hexágonos delas.

## Requisitos

- **RF-01:** A migration `vegetation_brush_object_cleanup`:
  - apaga de `island_objects` os objetos de tipo fora da lista (21, 22, 24, 25, 26 e 29), o que leva os `island_object_tiles` deles junto;
  - apaga de `map_object_types` os mesmos tipos, o que leva os `map_object_type_tiles` deles junto.
- **RF-02:** O `seed-data` (`map_object_types.json` e `map_object_type_tiles.json`) fica só com os 6 tipos, igual ao banco.
- **RF-03:** O catálogo (`GET /v1/catalog`) manda só os 6 tipos. O editor (ferramenta Peças) e o jogo mostram os objetos que sobraram como antes.
- **RF-04:** No cliente, saem:
  - as pastas de arte dos 25 tipos em `assets/map_objects/`;
  - o `make_objects.gd` inteiro e, no `make_town.gd`, os tipos apagados e a arte que só eles usavam;
  - o objeto Vegetação: `HexDecorations.PLANTS_SLUG`, `PLANT_RECIPES` e `decorations_of_object`, e o caminho dele no `HexMapView`;
  - no `MapObjectSprite`, os quadros por segundo dos tipos apagados;
  - no `HexFences`, a cerca antiga (`fence`) e a arte dela.
- **RF-05:** Os 3 carimbos de `tools/map_editor/stamps/` são apagados. A ferramenta Carimbo abre sem carimbos e continua guardando e pondo os novos.
- **RF-06:** Nada que fica muda: as casas, os prédios e a cerca da cidade aparecem e bloqueiam como antes.

## Critérios de aceite

- [x] O banco e o `seed-data` têm os mesmos 6 tipos, e os testes do servidor passam.
- [ ] A ilha do dono abre no editor e no jogo sem os 5 objetos que saíram, com o resto igual.
- [x] Nenhum arquivo do cliente cita um slug apagado, fora as specs.
- [x] O jogo sem janela abre sem erros de script, com os mesmos avisos de antes.
- [x] A ferramenta Carimbo abre sem carimbos, sem erro.

## Desenho técnico

- **Servidor:**
  - `server/prisma/migrations/20261125000000_vegetation_brush_object_cleanup/migration.sql`, escrita à mão com o prefixo `"ecobeasts".`;
  - o `seed-data`;
  - os testes que citam os tipos apagados (`catalog-tables.spec.ts`, `database.e2e-spec.ts`, `islands-editor.e2e-spec.ts` e `islands.e2e-spec.ts`) passam a usar os que ficam.
- **Cliente:** os arquivos do RF-04, e o `client/CLAUDE.md` onde ele cita os objetos apagados.

## Verificação

- **Servidor:** os testes de unidade, o lint, o typecheck e a suíte e2e inteira, porque o `server/` muda.
- **Banco:** depois do `migrate deploy`, uma consulta mostra os 6 tipos e nenhum objeto de ilha de outro tipo; o `migrate diff` sai vazio.
- **Cliente:** uma busca pelos slugs apagados no `client/` não acha nada; o jogo sem janela abre sem erros de script.
- **Print:** a ilha do dono no editor.

## Tarefas

- [x] Migration, `seed-data` e testes do servidor.
- [x] A arte, os geradores e o código do cliente.
- [x] Os carimbos.
- [x] Verificação e documentação.

## Resultado da verificação

Em 2026-11-14:

- **Banco:** depois do `migrate deploy`, `map_object_types` tem os 6 tipos, as ilhas têm só objetos deles (34, nas duas versões), e nenhum `island_object_tiles` ficou sem objeto. O `migrate diff` saiu vazio.
- **Servidor:** lint e typecheck limpos, 812 testes de unidade (2 a menos: os 4 testes dos objetos antigos, com a Fonte e a Vegetação, viraram 2) e 503 e2e passando.
- **Cliente:**
  - a busca pelos slugs apagados no `client/` não acha nada;
  - o `make_town.gd`, sem os tipos apagados nem as funções e cores que só eles usavam, refez a arte dos 6 objetos e das 4 peças de rua sem mudar nenhum PNG;
  - o jogo sem janela abre com os mesmos 9 avisos de antes.
- **Carimbos:** os 3 foram apagados, e o `Stamp.list` passou a aceitar a pasta que não existe (o git não guarda pasta vazia).
- **Falta o dono:** abrir a ilha dele no editor e no jogo. A print da ilha ficou para ele, porque o editor precisa da sessão do jogo.

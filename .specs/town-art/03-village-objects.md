# 03. Os objetos de vila da cidade

- **Status:** concluída
- **Depende de:** [02-houses](02-houses.md)

## Contexto

Depois das casas, os objetos de vila no estilo novo. Como na [02](02-houses.md), eles entram como tipos novos, ao lado dos de hoje, e nada do que existe é apagado nem trocado. A árvore, a pedra e a Vegetação são do ambiente e não ganham versão nova.

## Escopo

Os tipos novos, cada um com o formato, o bloqueio e o número de variantes do tipo de hoje com o mesmo nome:

| id | slug | name | Formato | Variantes | Como fica (_a revisar_) |
| --- | --- | --- | --- | --- | --- |
| 27 | `town_windmill` | Moinho (cidade) | par | 3, com 9 quadros | torre de pedra e madeira com pás girando; telhado laranja, verde e marrom |
| 28 | `town_garden` | Horta (cidade) | um | 6 | canteiro com borda de madeira: abóbora, raízes, trigo, girassol, tubérculos e um em crescimento |
| 29 | `town_fence` | Cerca (cidade) | um | 2 | madeira e pedra, ligando-se às vizinhas |
| 30 | `town_well` | Poço (cidade) | um | 1 | poço de pedra com telhadinho de madeira e balde |
| 31 | `town_market_stall` | Barraca de feira (cidade) | um | 3 | barraca de madeira com toldo listrado laranja, verde e roxo, com frutas |
| 32 | `town_cart` | Carroça (cidade) | um | 1 | carroça de madeira com caixotes |
| 33 | `town_beast_stable` | Estábulo de Ecobeasts (cidade) | par | 2 | estábulo de madeira e de pedra, com feno |
| 34 | `town_trough` | Bebedouro (cidade) | um | 1 | cocho de madeira com água |
| 35 | `town_rune_shrine` | Santuário de runas (cidade) | um | 4, com 16 quadros | pilar de pedra com o minério azul, de ouro, de prata e de carvão, com o brilho |

## Fora do escopo

- Mudar, apagar ou redesenhar os tipos de hoje, o `make_objects.gd` ou as ilhas que existem.
- Árvore, pedra e Vegetação no estilo novo.

## Requisitos

- **RF-01:** O catálogo ganha os tipos da tabela, e o `make_town.gd` os desenha seguindo o guia.
- **RF-02:** O moinho e a barraca não usam vermelho nem azul no telhado e no toldo, que são do Refúgio e da Loja.
- **RF-03:** A Cerca da cidade se liga sozinha como a de hoje ([island-villages 05](../island-villages/05-connected-fences.md)), com a folha de peças em `town_fence/parts_<variante>.png` no mesmo formato (7 células de 96×72, com o centro em (48, 43)). Ela se liga só a outra Cerca da cidade, e a de hoje só à de hoje, porque os dois traços juntos não emendam bem.
- **RF-04:** Os animados têm os quadros lado a lado, cortados no mesmo topo e com o pé no mesmo lugar. O moinho anda a 10 quadros por segundo e o santuário a 8, como os de hoje.

## Critérios de aceite

- [x] O gerador grava todos os tipos da tabela, com as variantes e os quadros, e os PNGs dos tipos de hoje não mudam.
- [x] Numa imagem com todos lado a lado e o Domador, o traço é o mesmo das casas e das construções-chave da cidade.
- [x] Uma fileira e um anel de Cercas da cidade, de madeira e de pedra, se emendam; uma Cerca da cidade ao lado de uma de hoje não se liga a ela.
- [ ] As pás do moinho giram e o santuário brilha no jogo, sem pulo entre os quadros.
- [ ] O catálogo traz os tipos, e o editor os põe (com o dono, no F2).

## Desenho técnico

- **Servidor:** a migração `server/prisma/migrations/20261117000000_town_village_objects/migration.sql`, a carga inicial e o teste da carga (30 objetos).
- **`make_town.gd`:** os tipos no `TYPES`, uma função `_draw_<slug>` para cada um, e a folha de peças da Cerca da cidade, desenhada no estilo do guia.
- **`HexFences`** (`res://ui/components/hex_fences.gd`): passa a conhecer os dois slugs de cerca, cada um com o caminho da folha dele, e guarda as artes montadas por slug, variante e lados. O `links` já liga só o mesmo `object_type_id`.
- **`HexMapView`:** monta pelo `HexFences` as cercas dos dois slugs.
- **`MapObjectSprite`:** `FRAME_RATES` ganha `town_windmill` (10) e `town_rune_shrine` (8).
- **Specs:** a tabela de tipos e a de tamanhos do [architecture.md da island-villages](../island-villages/architecture.md#os-tipos-de-objeto) e o parágrafo da Cerca.

## Verificação

```bash
godot --headless -s res://assets/map_objects/make_town.gd
godot --headless --path client --editor --quit
godot --headless -d --path client --quit-after 60
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

Uma cena temporária com todos os objetos, uma fileira e um anel de cercas das duas versões lado a lado e o Domador, e um olhar no jogo para as animações.

Feita em 2026-11-12:
- **Arte:** o `make_town.gd` gravou os 9 tipos, com as variantes, os 9 quadros do moinho, os 16 do santuário e as folhas `town_fence/parts_1.png` e `parts_2.png` (672×72). A horta usa a paleta nova Terra de canteiro, posta antes no guia. Os PNGs dos tipos de antes não mudaram.
- **Imagens:** numa folha com todos, e num pedaço de ilha com o Domador (cena temporária, já apagada), o traço é o das casas da cidade. Um anel de 6 Cercas da cidade (3 de madeira e 3 de pedra) fechou o cercado, uma fileira reta e uma diagonal emendaram, e duas Cercas de antes ao lado da fileira ficaram ligadas só entre si. Os quadros do moinho giram as pás um quarto de volta, e o 9º emenda no 1º.
- **Servidor:** a migração foi aplicada, a carga inicial ganhou os 9 tipos e o teste da carga conta 30 objetos. `lint`, `typecheck`, `npm test` e `npm run test:e2e` passam.
- **Projeto:** abre sem erro de script.
- **Falta o dono:** ver as pás girando e o brilho no jogo, e pôr os objetos no F2.

## Tarefas

- [x] A migração, a carga inicial e o teste da carga.
- [x] Moinho, horta, poço, barraca, carroça, estábulo, bebedouro e santuário.
- [x] A Cerca da cidade: a folha de peças, o `HexFences` e o `HexMapView`.
- [x] As velocidades no `MapObjectSprite`.
- [x] Conferir nas imagens e no jogo, e atualizar o `architecture.md` da island-villages e o `client/CLAUDE.md`.

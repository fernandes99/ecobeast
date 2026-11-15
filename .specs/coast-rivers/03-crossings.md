# 03. Os rios que atravessam, o vau e as pontes

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [02](02-lakes-and-rivers.md)

## Contexto

Um rio que vem de fora do mapa e desce até o mar corta a terra em dois. Esta fase cria esses rios, numa quantidade controlada, e põe as travessias, como nos passos 7 e 10 do [desenho](architecture.md#o-gerador). O vau é o que o dono aprovou na prévia: água rasa a 45% sobre cascalho.

## Requisitos

- **RF-01:** Cada rio, com a chance `throughRiverChance`, nasce na borda do mapa, do lado oposto ao mar.
- **RF-02:** As travessias, com `crossingSpacing` e `fordShare`, e a busca que fecha os pedaços de fora, como no passo 10.
- **RF-03:** `GeneratedMap` e `ShapedMap` ganham `bridges`. A exploração no mapa sorteado manda as pontes, e a ilha nova pelo gerador as salva em `island_bridges`.
- **RF-04:** No jogo, o vau é desenhado como no [desenho](architecture.md#o-vau-no-jogo), e o Domador anda nele. Um NPC não pode ficar parado num vau (o servidor o trata como água), mas pode passar por ele.
- **RF-05:** O editor mostra o Vau no bloco Bioma, depois da Água rasa, e o gerador ganha "Chance de rio que atravessa", "Hexágonos entre travessias" e "Parte de vau nas travessias".

## Critérios de aceite

- [x] Em 60 mapas, toda terra de 3 hexágonos ou mais encostada num rio é alcançável da chegada por terra, vau ou ponte.
- [x] Cada ponte vai do centro de um hexágono de terra ao do lado oposto, por cima de um hexágono de rio.
- [x] Com `throughRiverChance` 0, nenhum mapa tem vau nem ponte; com 1, todo rio nasce na borda.
- [x] Com `fordShare` 1, as travessias são só vaus; com 0, são pontes onde as margens deixam (frente a frente, na mesma altura e sem montanha), e vau no resto.
- [x] Sem janela: a busca de caminho atravessa o vau e a ponte do mapa sorteado.
- [x] Uma cena temporária mostra um rio que atravessa com vaus e pontes, e a captura é revisada.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam, e o jogo e o editor compilam sem avisos novos.

## Tarefas

- [x] Os rios que atravessam, as travessias e os testes.
- [x] As pontes na exploração e na ilha nova.
- [x] O vau no desenho e no andar, e o editor.

## Resultado da verificação

Em 2026-11-15:

- **O servidor:** `placeRivers` sorteia o rio que atravessa a partir da borda que `placeSea` devolve (a do lado oposto ao mar, ou a borda toda sem mar), e `placeCrossings` põe as travessias e fecha os pedaços de fora. A ponte só sai quando as margens ficam frente a frente, na mesma altura e sem montanha; senão é vau. A exploração no mapa sorteado e a rota do gerador do editor mandam as pontes.
- **O jogo:** `HexTile.FORD` e `blocks_walking()`; `ExplorationMap.is_water_hex` virou `is_blocked_hex`, que deixa passar o vau; o `HexMapView` desenha o cascalho e a água a 45% por cima; o editor pinta o Vau, com a amostra parada `surfaces/wford.png` gerada pelo `make_beach.py`; e `IslandDraft.generated` lê as pontes do gerador.
- **Um erro antigo das pontes:** o primeiro desenho de um mapa gerado com ponte deu `Index p_y = 31 is out of bounds` em `HexBridges._deck`. Numa ponte de comprimento quebrado (105,6 px), o último pixel pedia a linha 105 de uma arte de 105 linhas. A linha agora fica na última; o erro também podia aparecer nas pontes postas no editor.
- **Testes do gerador** (60 mapas de 900 hexágonos, com a chance de 0,6): há rios que atravessam, vaus e pontes; toda terra de 3 hexágonos ou mais encostada num rio chega à chegada por terra, vau ou ponte; cada ponte liga duas margens de terra a 2 hexágonos, por cima de um rio; o vau fica no rio, com a variante de 1 a 3; e os limites de `throughRiverChance` e de `fordShare`.
- **Sem janela, num mapa tirado do gerador:** a busca de caminho cruza cada um dos 3 vaus num passo, e cada uma das 2 pontes num passo, contra 13 sem a ponte; e a ilha nova pelo gerador recebe as 2 pontes.
- **Uma cena temporária** (apagada) desenhou o mesmo mapa, e a captura foi revisada: as pontes de madeira e os vaus de cascalho sob a água, como na prévia aprovada.
- **Dois testes que já existiam:** o e2e da exploração sem ilha esperava `bridges: []` e agora aceita só pontes de madeira de 28 px; e o de `tamers.spec.ts` que gera 20 mapas inteiros ganhou 20 s de limite, porque o gerador ficou mais lento e ele passava dos 5 s com a suíte em paralelo.
- `npm run lint`, `npm run typecheck`, `npm test` (939 testes) e a suíte e2e (582 testes) passam, e o jogo e os scripts do editor compilam sem avisos novos.
- **Não conferido:** o mapa sorteado, o andar pelo vau e pela ponte e o bloco Bioma com o jogo e o editor abertos.

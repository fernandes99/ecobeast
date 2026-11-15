# 01. O mar e a Praia

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [desert-snow](../desert-snow/), [nature-variety](../nature-variety/)

## Contexto

O mapa sorteado põe água nos hexágonos mais baixos de um ruído de altitude. Esta fase troca essa água por um mar num lado do mapa e põe a Praia na beira dele, como no [desenho](architecture.md#o-gerador) (passos 2, 3, 8 e 9).

## Requisitos

- **RF-01:** A migration `beach_ford` insere os biomas 10 (`beach`) e 11 (`wford`), com os textos do [desenho](architecture.md#o-catálogo), e as taxas da Praia do [README](README.md#decisões), cada uma só se a espécie existir. A carga inicial leva as duas linhas e as taxas.
- **RF-02:** `BIOMES` e `SHAPED_BIOMES` ganham `beach` e `wford`. `isWater` vale para `wshallow`, `wdeep` e `wford`; `blocksWalking` vale para `wshallow` e `wdeep`. `terrainOf` dá a altura 1 à Praia plana, 2 à de colina e 0 ao Vau. A Praia tem as variantes de 1 a 6, e o Vau, de 1 a 3.
- **RF-03:** O mar, com `seaFraction`, `coastRoughness` e `shallowWidth`, como no passo 3 do desenho. `waterFraction` e `deepFraction` saem de `MapConfig`, das faixas e do bloco do gerador no editor.
- **RF-04:** A Praia, como no passo 8. As ilhotas e o `islandChance` saem: a água fica sempre plana.
- **RF-05:** A chegada continua a de hoje: a terra plana mais perto do centro do mapa. Como o mar fica num lado, o centro é terra.
- **RF-06:** `make_beach.py` gera a arte do [desenho](architecture.md#a-arte-da-praia). `HexTransitions` põe a Praia antes do Deserto na ordem, com as linhas dela, e `HexDecorations` ganha os 4 tipos e a receita.
- **RF-07:** A migration insere os tipos de peça 91 (`shells`, "Conchas"), 92 (`starfish`, "Estrela-do-mar"), 93 (`driftwood`, "Tronco à deriva") e 94 (`beach_rock`, "Pedra de praia"), com 4 variantes. O pincel Vegetação os põe nos grupos Flores, Flores, Galhos e troncos e Pedras médias, começando desligados.
- **RF-08:** O editor mostra a Praia no bloco Bioma (o Vau entra na [03](03-crossings.md), com o desenho dele), e o gerador da ilha nova ganha "Parte de mar", "Recorte da costa" e "Largura da água rasa".

## Critérios de aceite

- [x] Em 200 mapas, o mar fica perto de `seaFraction` dos hexágonos, ligado à borda, e de um lado só (o centro de massa dele fica a mais de um terço do raio do centro do mapa).
- [x] A água rasa do mar encosta na terra, e a funda fica a mais de `shallowWidth` hexágonos dela.
- [x] Toda terra encostada no mar é Praia ou Montanha, e nenhuma Praia fica a mais de 2 hexágonos do mar.
- [x] Com `seaFraction` 0, o mapa não tem água.
- [x] Uma cena temporária mostra a costa com a Praia e as decorações, e a captura é revisada.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam, e o jogo e o editor compilam sem avisos novos.

## Tarefas

- [x] A migration, a carga inicial e os testes do catálogo.
- [x] O mar, a Praia, os parâmetros e os testes do gerador.
- [x] A arte, `HexTransitions`, `HexDecorations` e o editor.

## Resultado da verificação

Em 2026-11-15:

- **O mar:** a primeira versão cortava o mar por uma reta. No mapa padrão, de recorte com lóbulos, o mar caía num lóbulo que só encostava na terra por um estreito: 2 hexágonos de água rasa e 1 de Praia num mapa de 1.800. O mar passou a crescer a partir da borda, pelos vizinhos, como no [desenho](architecture.md#o-gerador). No mapa padrão (10.000 hexágonos, 5 seeds), ele fica com 30% do mapa, a água rasa com 4 a 6% e a Praia com 2,5 a 4%, em uns 100 ms.
- **As ilhotas:** com o mar fundo grande, a chance de 0,05 dava dezenas de pilares de terra no mar; o padrão caiu para 0,01, e depois o dono pediu para tirar a chance de vez ("remova a chance de ilhota na ilha no gerador").
- **Testes do gerador** (`map-generator.spec.ts`, 200 mapas): o mar perto de `seaFraction`, um só, ligado à borda e com o centro a mais de um terço do raio do centro do mapa; a água rasa a até `shallowWidth` da terra e a funda além; a terra encostada no mar é Praia ou montanha, e nenhuma Praia fica a mais de 2 do mar; sem mar, nem água nem Praia.
- **A migration** foi aplicada no banco: os biomas 10 e 11, as 5 taxas da Praia e os tipos de peça 91 a 94.
- **A arte:** as linhas de antes das três folhas ficaram iguais, pixel a pixel, e rodar o `make_beach.py` e o `make_nature.py` de novo, em qualquer ordem, dá os mesmos arquivos (o `make_nature.py` passou a guardar as linhas depois das dele).
- **Duas cenas temporárias** (apagadas) desenharam mapas tirados do gerador do servidor, um de 2.500 hexágonos inteiro e um de 260 de perto, e as capturas foram revisadas: a costa toda de Praia, a faixa de água rasa, o mar fundo e uma ilha de terra no mar com a Praia dela.
- `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam, e o jogo e os scripts do editor compilam sem avisos novos.
- **Não conferido:** o mapa sorteado e a luta na Praia com o jogo aberto, e o bloco Bioma e o gerador da ilha nova no editor aberto.

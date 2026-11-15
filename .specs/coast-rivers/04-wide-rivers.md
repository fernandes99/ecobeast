# 04. Sem ilhotas, a Praia larga, os rios largos e os lagos redondos

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [03](03-crossings.md)

## Contexto

Depois de ver os mapas das fases 1 a 3, o dono pediu, em 2026-11-15: "remova a chance de ilhota na ilha no gerador"; e, olhando um mapa com o rio correndo atrás da Praia: "quando o rio se encontrar com o mar, remova a faixa de areia... a faixa de areia está curta, pode ser entre 2 a 4. os rios trambém estão sendo gerados com uma largura de apenas 1 hex, pode aumentar para que normalmente vemos de 2 a 4 de largura (a grossura do rio podemos ter esse controle no gerador?)".

## Requisitos

- **RF-01:** O `islandChance` sai de `MapConfig`, das faixas e do bloco do gerador no editor. A água fica sempre plana.
- **RF-02:** A Praia vai de `beachMinWidth` a `beachMaxWidth` hexágonos do mar (padrão 2 a 4), como no [desenho](architecture.md#o-gerador) (passo 8), e não fica em terra que encosta num rio.
- **RF-03:** O rio ganha largura de `riverMinWidth` a `riverMaxWidth` (padrão 2 a 4), como em [A largura do rio](architecture.md#o-gerador). `ShapedMap.rivers` ganha `path`, a linha do meio.
- **RF-04:** A travessia vira a linha reta de margem a margem, como em [A linha da travessia](architecture.md#o-gerador).
- **RF-06:** Os lagos ficam redondos, como no passo 5 do [desenho](architecture.md#o-gerador), com `lakeMinWidth` e `lakeMaxWidth` (padrão 6 a 12, mínimo 6) no lugar de `lakeMinSize` e `lakeMaxSize`. O lago da nascente também é um disco da largura mínima, numa nascente da metade mais alta da terra onde ele cabe inteiro.
- **RF-07:** Para fechar um canto entre um rio e um lago, a travessia que liga a terra de fora também pode passar pela beira do lago. Um pedaço de terra de menos de 3 hexágonos que fica sem caminho, entre um rio e a borda do mapa, vira parte do rio.
- **RF-05:** O editor ganha "Largura mínima da Praia", "Largura máxima da Praia", "Largura do rio na nascente" e "Largura do rio na foz", e perde "Chance de ilhota na água"; "Tamanho mínimo/máximo do lago" viram "Largura mínima/máxima do lago".

## Critérios de aceite

- [x] Nenhum mapa tem água com forma de colina ou montanha.
- [x] Com a Praia de 2 a 4, aparecem Praias a 1, 2, 3 e 4 hexágonos do mar, e nenhuma encosta num rio.
- [x] Com a largura 1, o rio é só a linha do meio; com 2 a 4, ele tem em média mais de 2 hexágonos por hexágono da linha.
- [x] Cada ponte é uma reta num eixo do hexágono, de margem a margem, por cima só de rio, e toda terra encostada num rio continua chegando à chegada.
- [x] Todo lago tem pelo menos 6 hexágonos de largura nos 3 eixos, pelo hexágono do meio.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam, e o editor compila.

## Resultado da verificação

Em 2026-11-15:

- **Testes do gerador:** os mapas pequenos dos testes gerais (300 hexágonos) ficam com a Praia e o rio de 1 a 2, para as frações de bioma e de água continuarem nas faixas; os testes dos lagos, dos rios e das travessias (900 hexágonos) usam a Praia e o rio de 2 a 4. Os testes que olhavam o rio como uma linha passaram a olhar o `path`, o da ponte aceita de 1 a 6 hexágonos de rio no meio, e o do `fordShare` conta pontes e vaus.
- **Duas cenas temporárias** (apagadas) desenharam mapas tirados do gerador, um de 900 hexágonos com 3 rios que atravessam e um de 3.500 com o padrão, e as capturas foram revisadas: os rios de 2 a 4, os vaus como faixas de cascalho de margem a margem, as pontes longas por cima do rio largo, a Praia mais larga e a terra sem areia na beira do rio.
- **Os lagos redondos** (pedido depois, "Quando for lago, ele precisa ser mais redondo (no minimo um 6x6 caso exista algum)"): um teste confere a largura de cada lago nos 3 eixos. O lago maior trouxe três ajustes: os mapas pequenos dos testes gerais ficaram sem lago e sem lago de nascente (eles têm o bloco deles); o teste da água funda passou a olhar só o mar, porque o meio de um lago redondo é fundo; e um pedaço de 2 hexágonos entre um rio vindo da borda e a borda ficava sem caminho, sem linha reta para uma travessia, e agora vira rio.
- **No mapa padrão** (10.000 hexágonos), o gerador leva uns 210 ms.
- `npm run lint`, `npm run typecheck`, `npm test` (942 testes) e a suíte e2e (582 testes) passam, e o bloco do gerador do editor compila.
- **Não conferido:** o mapa sorteado e o gerador da ilha nova com o jogo e o editor abertos.

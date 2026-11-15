# desert-snow

Dois biomas novos, o Deserto e a Neve, no catálogo, no mapa sorteado de Explorar zona, nas ilhas do editor e na luta, com o chão, os arremates, o escorrido e as decorações de cada um.

## Contexto

Em 2026-11-15, o dono pediu: "crie 2 biomas, siga como é feito hoje. os dois são: bioma de deserto e o bioma de neve". Perguntado se eles aparecem também no mapa sorteado ou só nas ilhas, respondeu "Também no sorteado".

Um bioma hoje é:

- uma linha em `biomes`, com as taxas de quem nasce nele em `species_biomes`;
- um slug em `BIOMES` do gerador, aceito pelas rotas do mapa, das ilhas e do editor;
- no jogo, a textura `assets/terrain/surfaces/<slug>.png`, as linhas dele em `transitions.png` e `drips.png` e a receita de decorações em `HexDecorations.RECIPES`;
- no editor, uma amostra no bloco Bioma.

O gerador escolhe a terra comum pela umidade (Planície ou Boreal) e a Pedra por um ruído próprio. Colina e Montanha saem da crista, em qualquer bioma.

## Objetivos

1. O Deserto e a Neve existem no catálogo, com ids 8 e 9, e cada um tem quem nasça nele.
2. O mapa sorteado tem regiões de deserto e de neve, uma do lado quente e outra do lado frio do mapa.
3. O editor pinta os dois, e uma ilha salva com eles aparece igual em Ilhas.
4. A luta aberta em cima de um deles usa o chão dele.

## Anti-objetivos

- Fora do deserto e da neve, um mapa de uma mesma seed fica como antes: a água, a pedra, as colinas, as montanhas e as variantes.
- Nenhuma regra nova de bioma (calor, frio, dano): só a aparência e quem nasce.
- Nenhuma arte de terceiros.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| Os dois biomas seguem o caminho dos de hoje | "siga como é feito hoje" |
| Aparecem também no mapa sorteado | "Também no sorteado" |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| O gerador ganha um ruído de temperatura, com o deserto na ponta quente e a neve na fria | Os dois ficam em lados opostos do mapa, sem deserto encostado em neve |
| O ruído de temperatura vem de um sorteio separado, a partir da seed | Os ruídos e as variantes de hoje continuam iguais para a mesma seed |
| `desertFraction` e `snowFraction`, de 0,12 cada, entre os parâmetros do gerador | Cada um fica com perto de 12% da terra, como a Pedra com os 15% dela |
| A Pedra continua vindo antes: um hexágono de pedra no lado quente continua Pedra | A Pedra tem o ruído próprio, e assim a fração dela não muda |
| A colina do deserto e da neve fica no próprio bioma, na altura 2; a montanha continua Montanha | Uma colina verde no meio da neve ficaria estranha, e a Montanha já é rocha nua |
| Taxas do Deserto: Clod 50, Ruvo 40, Ruvak 30, Crag 30, Ruvaroth 10, Ingot 5, Elu 5 | Terra e Fogo combinam com areia e calor |
| Taxas da Neve: Hushling 100, Echofrost 30, Nilu 10, Nilgar 5 | Os dois de Gelo, mais um pouco de Água |
| As taxas dos Ecobeasts que não estão na carga inicial entram só se a espécie existir | A carga inicial tem os 9 primeiros, e o banco tem mais |
| A arte é provisória, gerada por um script Python versionado (`assets/terrain/make_desert_snow.py`) | As texturas de hoje também são provisórias, feitas por script, sem imagem de terceiros; versionado, o script pode ser rodado de novo |
| No arremate, o Deserto é o primeiro da ordem e a Neve fica entre a Colina e a Pedra | A grama avança sobre a areia, e a neve cobre a grama, mas não a rocha |
| Decorações novas: cacto e pedra de arenito no Deserto; pinheiro nevado, pedra com neve, arbusto nevado e capim com geada na Neve | O Deserto também usa o arbusto seco e o capim seco da Colina |
| O paredão dos dois é o `side.png`, de terra | A regra do paredão (`cliff.png` só na Pedra e na Montanha) não muda |

## Fora do escopo

- Tipos de peça solta e grupos do pincel Vegetação com os cactos e os pinheiros nevados.
- Neve caindo, areia voando e qualquer outra animação.
- Ecobeasts novos para os dois biomas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-biome-records](01-biome-records.md) | O catálogo, as taxas e o gerador | concluída |
| 2 | [02-biome-art](02-biome-art.md) | O chão, os arremates, as decorações e o editor | concluída (falta o dono conferir) |

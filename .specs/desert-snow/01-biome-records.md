# 01. O catálogo, as taxas e o gerador

- **Status:** concluída
- **Depende de:** [terrain-height](../terrain-height/), [biome-encounters](../biome-encounters/)

## Contexto

Os biomas moram na tabela `biomes`, e o gerador do servidor só conhece os 7 slugs de `BIOMES`. Esta fase põe o Deserto e a Neve no banco e no gerador, como no [README](README.md#decisões).

## Requisitos

- **RF-01:** A migration `desert_snow` insere os biomas 8 (`desert`, "Deserto", "Areia solta, sol forte e pouca sombra.") e 9 (`snow`, "Neve", "Chão coberto de neve, frio o ano inteiro."). A carga inicial (`biomes.json`) leva as duas linhas.
- **RF-02:** A mesma migration insere as taxas do [README](README.md#decisões) em `species_biomes`, cada uma só se a espécie existir. A carga inicial leva as das espécies 1 a 9.
- **RF-03:** `BIOMES` passa a ter `desert` e `snow`, e as rotas do mapa, das ilhas e do editor aceitam os dois. A variante vai de 1 a 6 nos dois, como na Planície.
- **RF-04:** O gerador sorteia o campo de temperatura com um ruído próprio, de um sorteio separado tirado da seed, para que os outros ruídos, as formas e as variantes sejam os mesmos de antes.
- **RF-05:** Na terra, a Pedra vem primeiro, como hoje. Depois, um hexágono com a temperatura acima de `1 - desertFraction` é Deserto, e um abaixo de `snowFraction` é Neve. Os outros seguem a umidade, como hoje.
- **RF-06:** `desertFraction` e `snowFraction` (padrão 0,12, de 0 a 1) entram nos parâmetros do gerador e na rota do editor, em `snake_case` (`desert_fraction`, `snow_fraction`).
- **RF-07:** Uma colina num hexágono de Deserto ou de Neve fica no próprio bioma, na altura 2. A montanha continua Montanha, na altura 4.
- **RF-08:** A chegada pode ser num hexágono plano de Deserto ou de Neve, como em qualquer terra plana.

## Critérios de aceite

- [x] O mapa padrão tem Deserto e Neve, cada um perto de `desertFraction` e `snowFraction` da terra, e nenhum hexágono de Deserto encosta num de Neve.
- [x] Com as duas frações em 0, o mapa de uma seed é igual ao de antes, hexágono por hexágono.
- [x] O Deserto e a Neve ficam na altura 1 ou 2, com a variante de 1 a 6.
- [x] As rotas do editor aceitam uma ilha com os dois biomas.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [x] A migration e a carga inicial.
- [x] O gerador, os parâmetros e os testes.

## Resultado da verificação

Em 2026-11-15:

- **Testes de unidade** (`map-generator.spec.ts`), em 200 mapas: o Deserto e a Neve ficam a até 6 pontos da fração de cada um na terra, nenhum Deserto encosta numa Neve, os dois ficam nas alturas 1 e 2, a chegada pode ser neles, e com as duas frações em 0 a água, as formas e as variantes são as mesmas do mapa com elas.
- **Contra o código de antes:** com as duas frações em 0, o mapa padrão de 5 seeds deu o mesmo hash com o gerador novo e com o de antes.
- **A migration** foi aplicada no banco: os biomas 8 e 9 e as 11 taxas, com as espécies 10 a 14 que só existem no banco.
- `npm run lint`, `npm run typecheck`, `npm test` (913 testes) e a suíte e2e (582 testes) passam.
- **A rota do editor** aceita os dois biomas e os dois parâmetros novos pelo `BIOMES` e pelo `MAP_CONFIG_RANGES`, sem código próprio; nenhum e2e novo foi escrito para isso.

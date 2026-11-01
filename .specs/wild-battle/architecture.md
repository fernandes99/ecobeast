# Arquitetura do mapa

## Sprites

Cada PNG tem 32×48 px, com o hexágono de ponta para cima. Os valores abaixo foram medidos nos arquivos, e o espaçamento foi conferido montando grades de teste: com 21 px a superfície fica contínua, com 22 aparece uma linha entre as fileiras, e com 20 as peças se sobrepõem.

| Medida                     | Valor                                   |
| -------------------------- | --------------------------------------- |
| Superfície                 | y de 6 a 34 (29 px)                     |
| Inclinação de cima         | y de 6 a 13 (8 px)                      |
| Borda vertical             | y de 14 a 26 (13 px)                    |
| Lateral do bloco           | y de 35 a 47 (13 px)                    |
| Centro da superfície       | (16, 20)                                |
| Passo horizontal           | 32 px                                   |
| Passo vertical             | 21 px                                   |
| Deslocamento de cada linha | 16 px                                   |

`snow` começa em y=5, e `temperate_mont` e `boreal_mont`, em y=4. O excesso cai sobre o tile de cima, o que a ordem de desenho resolve: de cima para baixo, quem está mais abaixo cobre a lateral de quem está acima. Todos os tiles usam a mesma origem.

**Biomas:** `temperate`, `warm`, `boreal`, `swamp`, `desert`, `snow`, `stone`, `wshallow` e `wdeep`. **Formas:** `flat`, `hill` e `mont`.

No jogo, os arquivos ficam em `res://assets/terrain/<biome>_<shape>_<NN>.png`. `hexset_grid_<biome>_flat_01..03` viram `flat_01..03`, `hexset_grid_<biome>_O_flat_01..03` viram `flat_04..06`, e os de `hill` e `mont` mantêm `01..03`. Assim o `O_flat` é só uma variante do plano, e o código não precisa conhecê-lo.

## Coordenadas

Coordenadas axiais `(q, r)`. Os seis vizinhos de uma posição são `(q+1, r)`, `(q-1, r)`, `(q, r+1)`, `(q, r-1)`, `(q+1, r-1)` e `(q-1, r+1)`.

O canto do sprite, em pixels da arte, fica em `x = 32 * q + 16 * r` e `y = 21 * r`. O resultado é sempre inteiro. O centro da superfície soma `(16, 20)`.

## Contrato

`POST /v1/me/exploration`, sem corpo, responde `201`:

```json
{
  "map": {
    "seed": 1234567,
    "start": { "q": 0, "r": 1 },
    "tiles": [{ "q": 0, "r": 0, "biome": "temperate", "shape": "flat", "variant": 4 }]
  }
}
```

`variant` vai de 1 a 6 em `flat` e de 1 a 3 nas outras formas. Falha: `409` "Crie seu Domador primeiro."

## Gerador

Uma função pura em `server/src/domain/exploration/`: `generateMap(seed, config)`. Toda a aleatoriedade vem de um gerador com seed, nesta ordem fixa:

1. **Recorte.** A região cresce a partir de `(0, 0)`: entre as posições vizinhas à região, entra a de menor `distância + ruído × edgeRoughness`, até `tileCount`. O resultado é conectado, sem posições repetidas, com a quantidade exata e borda irregular.
2. **Campos.** Três ruídos independentes dão elevação, umidade e temperatura. Cada um vira percentil dentro do mapa, de 0 a 1, para a proporção dos terrenos não depender da sorte. A temperatura recebe um desvio sorteado por mapa, de até `climateShift`, para alguns mapas saírem mais frios ou mais quentes.
3. **Água.** Elevação abaixo de `waterFraction` é água; a parte mais baixa dela, `deepFraction`, é `wdeep`, e o resto é `wshallow`. `wdeep` encostado em terra vira `wshallow`.
4. **Terra.** Na ordem, a primeira regra que valer:

| Condição                                                     | Bioma       |
| ------------------------------------------------------------ | ----------- |
| temperatura abaixo de `coldLimit`                            | `snow`      |
| elevação acima de `stoneFrom`                                | `stone`     |
| elevação até `swampBand` acima da água e umidade acima de `wetLimit` | `swamp` |
| temperatura acima de `hotLimit` e umidade abaixo de `dryLimit` | `desert`  |
| temperatura acima de `hotLimit`                              | `warm`      |
| umidade acima de `wetLimit`                                  | `boreal`    |
| resto                                                        | `temperate` |

5. **Forma.** Na terra, elevação acima de `mountainFrom` é `mont`, acima de `hillFrom` é `hill`, e o resto é `flat`. Na água, `islandChance` dá `hill` ou `mont`; o resto é `flat`.
6. **Limpeza.** `mont` de terra sem vizinho `mont` vira `hill`, até não sobrar nenhum. Depois, por `cleanupPasses` vezes, um bioma de terra sem vizinho igual assume o bioma de terra mais comum entre os vizinhos. Por fim, em qualquer par proibido, o bioma que não é o mais comum do mapa vira `temperate`.
7. **Variante.** Em `flat`, `detailChance` escolhe entre 4 e 6, e o resto entre 1 e 3. Nas outras formas, entre 1 e 3.
8. **Início.** A posição de terra plana mais perto de `(0, 0)`.

**Pares proibidos:** `desert`–`snow`, `desert`–`swamp`, `desert`–`boreal`, `snow`–`swamp` e `snow`–`warm`.

Os parâmetros ficam juntos em `DEFAULT_MAP_CONFIG`. Valores iniciais, _a revisar_, ajustados olhando mapas gerados:

| Parâmetro       | Valor | Parâmetro      | Valor |
| --------------- | ----- | -------------- | ----- |
| `tileCount`     | 300   | `dryLimit`     | 0,45  |
| `edgeRoughness` | 3     | `wetLimit`     | 0,62  |
| `waterFraction` | 0,22  | `stoneFrom`    | 0,86  |
| `deepFraction`  | 0,4   | `swampBand`    | 0,06  |
| `climateShift`  | 0,2   | `hillFrom`     | 0,78  |
| `coldLimit`     | 0,18  | `mountainFrom` | 0,9   |
| `hotLimit`      | 0,75  | `islandChance` | 0,04  |
| `detailChance`  | 0,2   | `cleanupPasses`| 3     |

## Pixels inteiros

A tela lógica do jogo tem 720×1280 e é escalada para a janela por `canvas_items`, em geral por um número quebrado. O mapa compensa isso: `pixels = max(1, round(escala_da_janela × ART_SCALE))` é quantos pixels reais cada pixel da arte ocupa, e o nó do mapa recebe a escala `pixels / escala_da_janela`, **calculada em cada eixo**. A tela lógica tem tamanho inteiro, então a escala da janela difere um pouco entre X e Y (0,8295 e 0,8289 numa janela de 720×1061), e a diferença se acumula ao longo do mapa. `ART_SCALE` é 3, _a revisar_. O nó usa filtro `NEAREST`, e a posição dele é sempre arredondada para um pixel real, inclusive durante o passo.

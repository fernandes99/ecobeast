# Arquitetura

O desenho técnico que as fases da [biome-encounters](README.md) compartilham.

## Fluxo

```text
Entrar em Explorar  →  POST /v1/me/exploration
                       gera o mapa, sorteia 500 Ecobeasts, guarda na memória
                       devolve o mapa e, de cada Ecobeast, só id, espécie e hexágono

Andar pelo mapa     →  nada vai para o servidor

Procurar            →  hexágono sem Ecobeast: o cliente avisa "Nada por aqui."
                       hexágono com Ecobeast: POST /v1/me/battle/wild { q, r }
                       o servidor confere, tira um Ecobeast do mapa e abre a luta

Voltar da luta      →  o cliente tira do mapa o Ecobeast enfrentado
```

## Biomas de encontro

As taxas usam 7 biomas. Desde a [terrain-height](../terrain-height/README.md), o hexágono já tem um desses 7 biomas, e o bioma de encontro é o próprio `biome`, em qualquer altura. Antes dela, uma função traduzia a forma do hexágono, como na tabela abaixo; o gerador converte a forma do mesmo jeito, então as taxas não mudaram:

| Forma do hexágono | Bioma de encontro |
| --- | --- |
| `hill`, em qualquer bioma | `hill` |
| `mont`, em qualquer bioma | `mountain` |
| `flat` | o próprio `biome`: `temperate`, `boreal`, `stone`, `wshallow` ou `wdeep` |

Uma ilha com forma `hill` na água conta como colina. Em 12 mapas reais, a média foi esta:

| Bioma | Hexágonos | Parte do mapa |
| --- | ---: | ---: |
| `hill` | 2.853 | 28,5% |
| `temperate` | 2.072 | 20,7% |
| `boreal` | 2.023 | 20,2% |
| `wshallow` | 950 | 9,5% |
| `wdeep` | 949 | 9,5% |
| `stone` | 759 | 7,6% |
| `mountain` | 394 | 3,9% |

A colina é o maior bioma, porque `hillFrom` deixa cerca de 40% da terra como colina ou montanha. Quem mudar `hillFrom` muda o peso dela nas taxas.

## Sorteio do mapa

Com `T` = média dos níveis da equipe principal e `N` = nível natural da espécie:

```text
peso(espécie, bioma) = taxa                 se T ≥ N
peso(espécie, bioma) = taxa × 0,5^(N − T)   se T < N
```

O nível natural é o `min_level` da linha de `evolutions` em que a espécie é `evolved_species_id`. Sem essa linha, ele é 1. Com `min_level` nulo, como na Ascensão por Vínculo do Echofrost, ele é o nível natural da espécie anterior mais `unleveledEvolutionGap`.

`count` vezes, sempre com os pesos acima:

1. Escolhe o bioma, com chance proporcional a `hexágonos do bioma × soma dos pesos no bioma`.
2. Escolhe a espécie, com chance proporcional ao peso dela nesse bioma.
3. Escolhe um hexágono ao acaso dentro do bioma, e sorteia o nível.

Como a chance de cada par (espécie, hexágono) só depende do peso, um mesmo Ecobeast aparece 10 vezes mais em um bioma com peso 100 do que em um com peso 10, seja qual for a concorrência em cada um. Um bioma com soma de pesos maior fica mais povoado. Dois Ecobeasts podem cair no mesmo hexágono, e isso não precisa de regra própria. Sem nenhum peso acima de zero, o mapa nasce sem Ecobeasts.

O sorteio usa `secureRandom`, e não a seed do mapa: a seed vai para o cliente e só reproduz o terreno.

## Nível do selvagem

```text
centro = N − (N − T) × ¼    se T < N
centro = N + (T − N) × ¾    se T ≥ N
nível  = um inteiro entre round(centro) − 5 e round(centro) + 5, com a mesma chance,
         limitado a 1 e ao MAX_LEVEL
```

| Espécie | T | Centro | Nível |
| --- | ---: | ---: | ---: |
| Ruvak (N 16) | 10 | 15 | 10 a 20 |
| Ruvak | 20 | 19 | 14 a 24 |
| Ruvak | 40 | 34 | 29 a 39 |
| Ruvo (N 1) | 5 | 4 | 1 a 9 |
| Ruvo | 40 | 30 | 25 a 35 |
| Ruvaroth (N 36) | 30 | 35 | 30 a 40 |
| Ruvaroth | 40 | 39 | 34 a 44 |

O nível é sorteado quando o Ecobeast nasce, e o resto dele (Genes, Temperamento, Traço) quando a luta começa, como já é hoje.

## Constantes

Ficam juntas em `DEFAULT_SPAWN_CONFIG`, em `server/src/domain/exploration/spawn-config.ts`, para o dono ajustar, _a revisar_:

| Parâmetro | Valor | O que faz |
| --- | ---: | --- |
| `count` | 500 | Ecobeasts por mapa |
| `missingLevelFactor` | 0,5 | Quanto a taxa cai a cada nível que falta |
| `pullBelow` | 0,25 | Quanto o time puxa o centro quando está abaixo do nível natural |
| `pullAbove` | 0,75 | Quanto o time puxa o centro quando está no nível natural ou acima |
| `levelSpread` | 5 | Quantos níveis o sorteio varia para cada lado |
| `unleveledEvolutionGap` | 20 | Quanto soma ao nível natural de uma evolução sem `min_level` |

Os testes das regras têm uma configuração própria, fixa, para esses ajustes não os reprovarem.

## Resultado esperado

Simulação com as taxas da [fase 01](01-biome-tables.md), a média dos 12 mapas e 500 Ecobeasts. Cada célula é quantos daquela espécie nascem em um mapa, em média:

| Média do time | Ruvo | Ruvak | Ruvaroth | Nilu | Nilgar | Nilgorr | Elu | Eluvin | Eluvara |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 | 195 | 0,06 | 0 | 88 | 0,03 | 0 | 217 | 0,05 | 0 |
| 10 | 193 | 1,9 | 0 | 87 | 1,0 | 0 | 215 | 1,7 | 0 |
| 14 | 169 | 27 | 0 | 77 | 14 | 0 | 189 | 23 | 0 |
| 20 | 122 | 78 | 0 | 55 | 41 | 0 | 136 | 67 | 0 |
| 30 | 122 | 78 | 0,3 | 55 | 41 | 0,2 | 136 | 67 | 0,4 |
| 40 | 109 | 70 | 18 | 49 | 37 | 13 | 121 | 60 | 24 |

Uma tela mostra cerca de 60 hexágonos, conta aproximada. Com média 10, isso dá cerca de 4 Ecobeasts em uma tela de temperado ou boreal, 2,4 em colina, 1,3 em pedra e 0,9 em montanha.

## Exploração no servidor

`ExplorationStore`, em `server/src/exploration/exploration.store.ts`, segue o `BattleStore`: uma entrada por jogador, na memória do processo, com o relógio injetado. Uma exploração nova substitui a anterior, e uma entrada sem uso por 2 horas sai.

```ts
interface StoredExploration {
  /** Por id. Sai daqui quando a luta começa. */
  spawns: Map<number, MapSpawn>;
  /** Os Domadores NPC (npc-tamers/03). Também saem quando a luta começa. */
  tamers: Map<number, MapTamer>;
  /** A última posição confirmada, e quando. */
  position: HexCoord;
  positionAt: number;
}
```

Os hexágonos do mapa não ficam guardados: um pedido só passa se houver Ecobeast no hexágono, então ele existe.

## Conferir a posição

O Domador anda sem falar com o servidor, e informa onde está só ao Procurar. O servidor aceita se ele poderia ter chegado até ali andando:

```text
distância(posição confirmada, posição informada) × 300 ms ≤ tempo desde a confirmação
```

A distância é a de hexágonos em coordenadas axiais, `(|Δq| + |Δr| + |Δq + Δr|) / 2`. Um passo do cliente leva 360 ms (`STEP_SECONDS`), e os 300 ms (`MIN_STEP_MS`) dão uma folga para o relógio. Quem aceita a posição grava a nova posição e o novo horário.

Quem altera o cliente consegue saber onde estão os 500 Ecobeasts, mas continua chegando neles só na velocidade de quem anda. Isso é aceito por enquanto.

## Contrato

`POST /v1/me/exploration`, sem corpo, responde `201`. O `map` ganha `creatures`, sem nível nem nome:

```json
{
  "map": {
    "seed": 1234567,
    "start": { "q": 0, "r": 1 },
    "tiles": [{ "q": 0, "r": 0, "biome": "temperate", "height": 1, "variant": 4 }],
    "creatures": [{ "id": 1, "species_id": 7, "q": 3, "r": -2 }]
  }
}
```

`POST /v1/me/battle/wild` passa a exigir `{ "q": 3, "r": -2 }` e responde `201`. A resposta é a mesma de hoje, com `spawn_id`, o Ecobeast que saiu do mapa. As outras respostas de batalha trazem `spawn_id: null`.

| Falha | Status | Mensagem |
| --- | --- | --- |
| Corpo inválido | 400 | "Posição inválida." |
| Sem exploração guardada | 404 | "Essa exploração acabou. Saia e entre de novo." |
| Posição impossível | 409 | "Você não chegou até aí." |
| Nenhum Ecobeast no hexágono | 409 | "Nada por aqui." |
| Sem Domador, ou equipe sem HP | 409 | As mensagens de hoje |

## Mudança de plano

O `rollEncounter` e o `encounter.ts` saem, porque o sorteio de espécie e de nível agora acontece na exploração. A rota de teste `POST /v1/me/battle`, ligada por `ENABLE_TEST_BATTLE`, continua igual.

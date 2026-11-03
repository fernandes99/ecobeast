# 02. Regras do spawn

- **Status:** concluída
- **Depende de:** [01-biome-tables](01-biome-tables.md), para os slugs dos biomas

## Contexto

Com as taxas no banco, falta a conta que transforma taxas, mapa e nível do time em uma lista de Ecobeasts. Esta fase escreve essa conta como funções puras, sem Nest, sem banco e sem mudar nenhuma rota, como o resto de `server/src/domain/`.

## Escopo

- Tradução de hexágono para bioma de encontro.
- Peso por nível, nível natural e nível do selvagem.
- Sorteio dos Ecobeasts de um mapa.
- As constantes em `DEFAULT_SPAWN_CONFIG`.

## Fora do escopo

- Ler do banco e guardar a exploração ([fase 03](03-exploration-session.md)).
- Qualquer mudança no cliente.

## Requisitos

- **RF-01:** `encounterBiome` devolve `hill` ou `mountain` para as formas `hill` e `mont`, em qualquer bioma, e o próprio bioma para `flat`.
- **RF-02:** `naturalLevel` devolve o `min_level` da evolução que gera a espécie, 1 sem evolução e, com `min_level` nulo, o nível natural da espécie anterior mais `unleveledEvolutionGap`.
- **RF-03:** Com o time no nível natural ou acima, o peso é a própria taxa.
- **RF-04:** Com o time abaixo, o peso é `taxa × missingLevelFactor^(N − T)`, nunca zero enquanto a taxa for maior que zero.
- **RF-05:** `wildLevel` sorteia um inteiro entre `round(centro) − levelSpread` e `round(centro) + levelSpread`, com o centro da [arquitetura](architecture.md#nível-do-selvagem), limitado a 1 e a `MAX_LEVEL`.
- **RF-06:** `rollSpawns` devolve exatamente `count` Ecobeasts, com ids de 1 a `count`, ou nenhum se não houver peso acima de zero.
- **RF-07:** Nenhum Ecobeast nasce em um bioma onde a espécie tem taxa 0 ou nenhuma taxa.
- **RF-08:** A chance de cada par (espécie, hexágono) é proporcional ao peso dela naquele bioma, como na [arquitetura](architecture.md#sorteio-do-mapa).

## Critérios de aceite

- [x] Uma colina do bioma boreal conta como `hill`, e uma ilha `mont` na água conta como `mountain`.
- [x] O nível natural do Ruvo é 1, o do Ruvak é 16, o do Ruvaroth é 36 e o do Echofrost é 21.
- [x] Com média 10, o peso do Ruvak com taxa 40 é 0,625; com média 16 ou 20, é 40.
- [x] Com média 10 e `random` nos extremos, o Ruvak vem no nível 10 e no 20.
- [x] Com média 40, o Ruvak vem entre 29 e 39.
- [x] Com média 5, o Ruvo nunca vem abaixo do nível 1 nem acima do 9.
- [x] Em um mapa de teste com taxas 100 e 10 para a mesma espécie em dois biomas do mesmo tamanho, ela aparece perto de 10 vezes mais no primeiro, em uma amostra grande.
- [x] Nenhum Elu nasce em `wshallow` ou `wdeep`, em uma amostra grande sobre um mapa gerado.
- [x] Um mapa sem nenhuma taxa devolve lista vazia.

## Desenho técnico

Arquivos novos em `server/src/domain/exploration/`, com a mesma forma de `map-config.ts` e `map-generator.ts`:

```ts
// spawn-config.ts
export interface SpawnConfig {
  count: number;
  missingLevelFactor: number;
  pullBelow: number;
  pullAbove: number;
  levelSpread: number;
  unleveledEvolutionGap: number;
}
export const DEFAULT_SPAWN_CONFIG: SpawnConfig;

// spawns.ts
export const ENCOUNTER_BIOMES = ['temperate', 'boreal', 'stone', 'hill', 'mountain', 'wshallow', 'wdeep'] as const;
export type EncounterBiome = (typeof ENCOUNTER_BIOMES)[number];

export interface SpawnSpecies {
  speciesId: number;
  naturalLevel: number;
  rates: Partial<Record<EncounterBiome, number>>;
}

export interface MapSpawn extends HexCoord {
  id: number;
  speciesId: number;
  level: number;
}

export function encounterBiome(tile: Pick<MapTile, 'biome' | 'shape'>): EncounterBiome;
export function naturalLevel(speciesId: number, evolutions: EvolutionLevel[], config: SpawnConfig): number;
export function spawnWeight(rate: number, natural: number, teamAverage: number, config: SpawnConfig): number;
export function wildLevel(natural: number, teamAverage: number, config: SpawnConfig, random: Random): number;
export function rollSpawns(tiles: MapTile[], species: SpawnSpecies[], teamAverage: number, random: Random, config?: SpawnConfig): MapSpawn[];
```

`EvolutionLevel` é `{ speciesId: number; evolvedSpeciesId: number; minLevel: number | null }`. `Random` é o de `domain/battle/types.ts`, e `HexCoord` é o de `domain/exploration/hex.ts`.

O `rollSpawns` monta uma vez, por bioma, a lista de hexágonos e os pesos, e depois faz os `count` sorteios. Com 7 biomas e poucas espécies, percorrer as listas basta, sem estrutura especial.

O teste de spawn usa uma configuração própria e fixa, como os testes do gerador.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test
```

## Tarefas

- [x] Escrever os testes de `encounterBiome`, `naturalLevel`, `spawnWeight` e `wildLevel`, e ver falhar.
- [x] Implementar `spawn-config.ts` e as quatro funções.
- [x] Escrever os testes de `rollSpawns`, inclusive o da proporção, e ver falhar.
- [x] Implementar `rollSpawns`.
- [x] Rodar a verificação.

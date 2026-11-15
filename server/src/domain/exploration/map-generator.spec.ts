import { flatCenter, gridCoord } from '../islands/hex-pixels.js';
import { hexDistance, hexKey, hexNeighbors } from './hex.js';
import { DEFAULT_MAP_CONFIG, MapConfig } from './map-config.js';
import {
  BIOMES,
  blocksWalking,
  generateMap,
  generateShapedMap,
  isWater,
  MAX_HEIGHT,
  maxVariant,
  SHAPED_BIOMES,
  ShapedBiome,
  ShapedMap,
  ShapedTile,
  startOf,
  TERRAIN_SHAPES,
  terrainOf,
} from './map-generator.js';

const SEEDS = Array.from({ length: 200 }, (_, index) => index * 7919 + 1);
const MAX_LONELY_LAND = 0.05;
/** A grama é a base da região; nenhum bioma deve ir além disto. */
const MAX_BIOME_SHARE = 0.6;
const CONFIG: MapConfig = {
  tileCount: 300,
  edgeRoughness: 7,
  noiseScale: 0.14,
  seaFraction: 0.3,
  coastRoughness: 0.25,
  shallowWidth: 2,
  beachMinWidth: 1,
  beachMaxWidth: 2,
  lakeCount: 0,
  lakeMinWidth: 6,
  lakeMaxWidth: 6,
  riverCount: 2,
  riverMinWidth: 1,
  riverMaxWidth: 2,
  springLakeChance: 0,
  throughRiverChance: 0.3,
  crossingSpacing: 14,
  fordShare: 0.5,
  wetLimit: 0.6,
  stoneFraction: 0.15,
  desertFraction: 0.12,
  snowFraction: 0.12,
  hillFrom: 0.8,
  mountainFrom: 0.9,
  detailChance: 0.2,
  cleanupPasses: 3,
};

function indexed(map: ShapedMap): Map<string, ShapedTile> {
  return new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
}

function neighborsOf(
  tile: ShapedTile,
  byKey: Map<string, ShapedTile>,
): ShapedTile[] {
  return hexNeighbors(tile).flatMap((coord) => {
    const neighbor = byKey.get(hexKey(coord));
    return neighbor ? [neighbor] : [];
  });
}

function reachableFrom(map: ShapedMap): number {
  const byKey = indexed(map);
  const seen = new Set([hexKey(map.tiles[0]!)]);
  const pending = [map.tiles[0]!];
  while (pending.length > 0) {
    for (const neighbor of neighborsOf(pending.pop()!, byKey)) {
      if (!seen.has(hexKey(neighbor))) {
        seen.add(hexKey(neighbor));
        pending.push(neighbor);
      }
    }
  }
  return seen.size;
}

const waterShare = (map: ShapedMap) =>
  map.tiles.filter((tile) => isWater(tile.biome)).length / map.tiles.length;

/** A água que não é lago nem rio. */
function seaOf(map: ShapedMap): Set<string> {
  const inland = new Set(
    [...map.lakes, ...map.rivers.map(({ cells }) => cells)].flat().map(hexKey),
  );
  return new Set(
    map.tiles
      .filter((tile) => isWater(tile.biome) && !inland.has(hexKey(tile)))
      .map(hexKey),
  );
}

const seaShare = (map: ShapedMap) => seaOf(map).size / map.tiles.length;

/** A distância de cada hexágono até o mais perto que `from` aceita. */
function distanceTo(
  map: ShapedMap,
  from: (tile: ShapedTile) => boolean,
): Map<string, number> {
  const byKey = indexed(map);
  const result = new Map<string, number>();
  let ring = map.tiles.filter(from);
  for (const tile of ring) result.set(hexKey(tile), 0);
  for (let step = 1; ring.length > 0; step += 1) {
    const next: ShapedTile[] = [];
    for (const tile of ring) {
      for (const neighbor of neighborsOf(tile, byKey)) {
        if (!result.has(hexKey(neighbor))) {
          result.set(hexKey(neighbor), step);
          next.push(neighbor);
        }
      }
    }
    ring = next;
  }
  return result;
}

const point = ({ q, r }: ShapedTile): [number, number] => [
  q + r / 2,
  (r * Math.sqrt(3)) / 2,
];

function centerOf(tiles: ShapedTile[]): [number, number] {
  const sum = tiles
    .map(point)
    .reduce(([x, y], [a, b]) => [x + a, y + b], [0, 0]);
  return [sum[0] / tiles.length, sum[1] / tiles.length];
}

describe('generateShapedMap', () => {
  let maps: ShapedMap[];

  beforeAll(() => {
    maps = SEEDS.map((seed) => generateShapedMap(seed, CONFIG));
  });

  it('só existem as nove regiões', () => {
    expect([...SHAPED_BIOMES].sort()).toEqual(
      [
        'beach',
        'boreal',
        'desert',
        'snow',
        'stone',
        'temperate',
        'wdeep',
        'wford',
        'wshallow',
      ].sort(),
    );
  });

  it('o deserto e a neve ficam perto da fração deles na terra (desert-snow/01)', () => {
    const land = maps.flatMap(({ tiles }) =>
      tiles.filter(({ biome }) => !isWater(biome)),
    );
    for (const [biome, share] of [
      ['desert', CONFIG.desertFraction],
      ['snow', CONFIG.snowFraction],
    ] as const) {
      const count = land.filter((tile) => tile.biome === biome).length;
      expect(count / land.length).toBeGreaterThan(share - 0.06);
      expect(count / land.length).toBeLessThan(share + 0.06);
    }
  });

  it('nenhum deserto encosta na neve', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const touching = map.tiles.filter(
        (tile) =>
          tile.biome === 'desert' &&
          neighborsOf(tile, byKey).some(({ biome }) => biome === 'snow'),
      );
      expect(touching).toEqual([]);
    }
  });

  it('o deserto e a neve não mudam a água, as formas nem as variantes', () => {
    const none = { ...CONFIG, desertFraction: 0, snowFraction: 0 };
    for (const seed of SEEDS.slice(0, 20)) {
      const plain = generateShapedMap(seed, none);
      const map = generateShapedMap(seed, CONFIG);
      expect(
        plain.tiles.some(({ biome }) => biome === 'desert' || biome === 'snow'),
      ).toBe(false);
      expect(
        map.tiles.map(({ q, r, shape, variant, biome }) => [
          q,
          r,
          shape,
          variant,
          isWater(biome),
        ]),
      ).toEqual(
        plain.tiles.map(({ q, r, shape, variant, biome }) => [
          q,
          r,
          shape,
          variant,
          isWater(biome),
        ]),
      );
    }
  });

  it('a configuração do jogo gera um mapa válido', () => {
    const map = generateShapedMap(1);
    expect(map.tiles).toHaveLength(DEFAULT_MAP_CONFIG.tileCount);
    expect(new Set(map.tiles.map(hexKey)).size).toBe(map.tiles.length);
    for (const tile of map.tiles) {
      expect(SHAPED_BIOMES).toContain(tile.biome);
      expect(TERRAIN_SHAPES).toContain(tile.shape);
    }
    const start = indexed(map).get(hexKey(map.start));
    expect(isWater(start!.biome)).toBe(false);
    expect(start!.shape).toBe('flat');
  });

  it('devolve a seed recebida', () => {
    expect(generateShapedMap(123, CONFIG).seed).toBe(123);
  });

  it('a mesma seed dá o mesmo mapa', () => {
    expect(generateShapedMap(555, CONFIG)).toEqual(
      generateShapedMap(555, CONFIG),
    );
  });

  it('seeds diferentes dão mapas diferentes', () => {
    expect(generateShapedMap(555, CONFIG).tiles).not.toEqual(
      generateShapedMap(556, CONFIG).tiles,
    );
  });

  it('o recorte do mapa muda com a seed', () => {
    const shape = (map: ShapedMap) => map.tiles.map(hexKey).sort().join('|');
    expect(new Set(maps.map(shape)).size).toBeGreaterThan(190);
  });

  it('tem a quantidade pedida, sem posições repetidas', () => {
    for (const map of maps) {
      expect(map.tiles).toHaveLength(CONFIG.tileCount);
      expect(new Set(map.tiles.map(hexKey)).size).toBe(map.tiles.length);
    }
  });

  it('muda de tamanho com `tileCount`', () => {
    const config = { ...CONFIG, tileCount: 120 };
    expect(generateShapedMap(9, config).tiles).toHaveLength(120);
  });

  it('todas as posições são alcançáveis', () => {
    for (const map of maps) {
      expect(reachableFrom(map)).toBe(map.tiles.length);
    }
  });

  it('só usa biomas, formas e variantes que têm sprite', () => {
    // Um `expect` por tile estoura o tempo do teste: são milhares em cada mapa.
    const withoutSprite = maps
      .flatMap(({ tiles }) => tiles)
      .filter(
        ({ biome, shape, variant }) =>
          !SHAPED_BIOMES.includes(biome) ||
          !TERRAIN_SHAPES.includes(shape) ||
          variant < 1 ||
          variant > (shape === 'flat' ? 6 : 3),
      );
    expect(withoutSprite).toEqual([]);
  });

  it('água funda só encosta em água', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      for (const tile of map.tiles.filter(({ biome }) => biome === 'wdeep')) {
        for (const neighbor of neighborsOf(tile, byKey)) {
          expect(isWater(neighbor.biome)).toBe(true);
        }
      }
    }
  });

  it('os biomas de terra formam grupos', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const land = map.tiles.filter((tile) => !isWater(tile.biome));
      const lonely = land.filter(
        (tile) =>
          !neighborsOf(tile, byKey).some(({ biome }) => biome === tile.biome),
      );
      expect(lonely.length / land.length).toBeLessThan(MAX_LONELY_LAND);
    }
  });

  it('as montanhas de terra formam conjuntos', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const mountains = map.tiles.filter(
        (tile) => tile.shape === 'mont' && !isWater(tile.biome),
      );
      for (const tile of mountains) {
        expect(
          neighborsOf(tile, byKey).some(({ shape }) => shape === 'mont'),
        ).toBe(true);
      }
    }
  });

  it('começa em terra plana, dentro do mapa', () => {
    for (const map of maps) {
      const start = indexed(map).get(hexKey(map.start));
      expect(start).toBeDefined();
      expect(isWater(start!.biome)).toBe(false);
      expect(start!.shape).toBe('flat');
    }
  });

  it('a terra é a maior parte de todo mapa', () => {
    for (const map of maps) {
      expect(waterShare(map)).toBeLessThan(0.5);
    }
  });

  it('o mar fica perto de `seaFraction` (coast-rivers/01)', () => {
    const mean =
      maps.map(seaShare).reduce((sum, share) => sum + share) / maps.length;
    expect(mean).toBeGreaterThan(CONFIG.seaFraction - 0.05);
    expect(mean).toBeLessThan(CONFIG.seaFraction + 0.03);
  });

  it('o mar é um só, ligado à borda e de um lado do mapa', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const sea = seaOf(map);
      const water = map.tiles.filter((tile) => sea.has(hexKey(tile)));
      const seen = new Set([hexKey(water[0]!)]);
      const pending = [water[0]!];
      while (pending.length > 0) {
        for (const neighbor of neighborsOf(pending.pop()!, byKey)) {
          if (sea.has(hexKey(neighbor)) && !seen.has(hexKey(neighbor))) {
            seen.add(hexKey(neighbor));
            pending.push(neighbor);
          }
        }
      }
      expect(seen.size).toBe(water.length);
      expect(water.some((tile) => neighborsOf(tile, byKey).length < 6)).toBe(
        true,
      );
      const [mx, my] = centerOf(map.tiles);
      const [sx, sy] = centerOf(water);
      const reach = Math.max(
        ...map.tiles.map((tile) =>
          Math.hypot(point(tile)[0] - mx, point(tile)[1] - my),
        ),
      );
      expect(Math.hypot(sx - mx, sy - my)).toBeGreaterThan(reach / 3);
    }
  });

  it('a água rasa encosta na terra, e a funda fica longe dela', () => {
    for (const map of maps) {
      const sea = seaOf(map);
      const fromLand = distanceTo(map, (tile) => !sea.has(hexKey(tile)));
      const wrong = map.tiles.filter((tile) => {
        const distance = fromLand.get(hexKey(tile))!;
        return (
          (sea.has(hexKey(tile)) &&
            tile.biome === 'wshallow' &&
            distance > CONFIG.shallowWidth) ||
          (sea.has(hexKey(tile)) &&
            tile.biome === 'wdeep' &&
            distance <= CONFIG.shallowWidth)
        );
      });
      expect(wrong).toEqual([]);
    }
  });

  it('a terra encostada no mar é Praia, menos a montanha e a beira do rio, e a Praia não passa da largura', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const sea = seaOf(map);
      const river = new Set(
        map.rivers.flatMap(({ cells }) => cells).map(hexKey),
      );
      const fromSea = distanceTo(map, (tile) => sea.has(hexKey(tile)));
      const wrong = map.tiles.filter((tile) => {
        const distance = fromSea.get(hexKey(tile))!;
        const byRiver = neighborsOf(tile, byKey).some((n) =>
          river.has(hexKey(n)),
        );
        return (
          (distance === 1 &&
            !isWater(tile.biome) &&
            tile.shape !== 'mont' &&
            !byRiver &&
            tile.biome !== 'beach') ||
          (tile.biome === 'beach' &&
            (distance > CONFIG.beachMaxWidth || byRiver))
        );
      });
      expect(wrong).toEqual([]);
    }
  });

  it('sem mar, o mapa não tem mar nem Praia', () => {
    const dry = { ...CONFIG, seaFraction: 0 };
    for (const seed of SEEDS.slice(0, 20)) {
      const map = generateShapedMap(seed, dry);
      expect(seaOf(map).size).toBe(0);
      expect(map.tiles.some(({ biome }) => biome === 'beach')).toBe(false);
    }
  });

  it('sem mar, lago nem rio, o mapa não tem água', () => {
    const dry = { ...CONFIG, seaFraction: 0, lakeCount: 0, riverCount: 0 };
    for (const seed of SEEDS.slice(0, 20)) {
      expect(waterShare(generateShapedMap(seed, dry))).toBe(0);
    }
  });

  it('aparecem todos os biomas ao longo das seeds', () => {
    const seen = new Set<ShapedBiome>(
      maps.flatMap(({ tiles }) => tiles.map((tile) => tile.biome)),
    );
    expect([...seen].sort()).toEqual([...SHAPED_BIOMES].sort());
  });

  it('nenhum bioma de terra é raridade ao longo das seeds', () => {
    for (const biome of SHAPED_BIOMES.filter((slug) => !isWater(slug))) {
      const containing = maps.filter(({ tiles }) =>
        tiles.some((tile) => tile.biome === biome),
      );
      expect(containing.length / maps.length).toBeGreaterThan(0.25);
    }
  });

  it('nenhum bioma domina os mapas', () => {
    for (const biome of SHAPED_BIOMES) {
      const tiles = maps.flatMap((map) => map.tiles);
      const share = tiles.filter((tile) => tile.biome === biome).length;
      expect(share / tiles.length).toBeLessThan(MAX_BIOME_SHARE);
    }
  });

  it('a pedra é uma região, com plano, colina e montanha', () => {
    const shapes = new Set(
      maps.flatMap(({ tiles }) =>
        tiles
          .filter(({ biome }) => biome === 'stone')
          .map((tile) => tile.shape),
      ),
    );
    expect([...shapes].sort()).toEqual([...TERRAIN_SHAPES].sort());
  });

  it('a pedra é principalmente chão plano', () => {
    const stone = maps.flatMap(({ tiles }) =>
      tiles.filter(({ biome }) => biome === 'stone'),
    );
    const flat = stone.filter(({ shape }) => shape === 'flat');
    expect(flat.length / stone.length).toBeGreaterThan(0.5);
  });

  it('a pedra fica perto de `stoneFraction` da terra', () => {
    const land = maps.flatMap(({ tiles }) =>
      tiles.filter(({ biome }) => !isWater(biome)),
    );
    const stone = land.filter(({ biome }) => biome === 'stone');
    expect(stone.length / land.length).toBeGreaterThan(
      CONFIG.stoneFraction - 0.05,
    );
    expect(stone.length / land.length).toBeLessThan(
      CONFIG.stoneFraction + 0.05,
    );
  });

  it('mais `stoneFraction` dá mais pedra', () => {
    const stoneCount = (config: MapConfig) =>
      generateShapedMap(9, config).tiles.filter(
        ({ biome }) => biome === 'stone',
      ).length;
    expect(stoneCount({ ...CONFIG, stoneFraction: 0.4 })).toBeGreaterThan(
      stoneCount(CONFIG),
    );
  });

  it('há montanhas em vários biomas de terra', () => {
    const biomes = new Set(
      maps.flatMap(({ tiles }) =>
        tiles
          .filter(({ shape, biome }) => shape === 'mont' && !isWater(biome))
          .map((tile) => tile.biome),
      ),
    );
    expect(biomes.size).toBe(5);
  });

  it('a água é sempre plana, sem ilhotas', () => {
    const shaped = maps.flatMap(({ tiles }) =>
      tiles.filter((tile) => isWater(tile.biome) && tile.shape !== 'flat'),
    );
    expect(shaped).toEqual([]);
  });

  it('mais `seaFraction` dá mais mar', () => {
    const wetter: MapConfig = { ...CONFIG, seaFraction: 0.5 };
    expect(seaShare(generateShapedMap(9, wetter))).toBeGreaterThan(
      seaShare(generateShapedMap(9, CONFIG)),
    );
  });
});

describe('os lagos e os rios (coast-rivers/02)', () => {
  const WATERY: MapConfig = {
    ...CONFIG,
    tileCount: 900,
    lakeCount: 3,
    lakeMinWidth: 6,
    lakeMaxWidth: 10,
    riverCount: 4,
    springLakeChance: 0.8,
    riverMinWidth: 2,
    riverMaxWidth: 4,
    beachMinWidth: 2,
    beachMaxWidth: 4,
  };
  let maps: ShapedMap[];

  beforeAll(() => {
    maps = SEEDS.slice(0, 60).map((seed) => generateShapedMap(seed, WATERY));
  });

  it('cada rio é uma linha de vizinhos, sem voltar, que termina encostado em outra água', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      map.rivers.forEach((river, index) => {
        const keys = river.path.map(hexKey);
        expect(new Set(keys).size).toBe(keys.length);
        for (let step = 1; step < river.path.length; step += 1) {
          expect(hexNeighbors(river.path[step - 1]!).map(hexKey)).toContain(
            keys[step],
          );
        }
        const own = new Set(river.cells.map(hexKey));
        for (const key of keys) expect(own.has(key)).toBe(true);
        const pond =
          river.source === 'lake'
            ? new Set(
                map.lakes
                  .filter((lake) =>
                    lake.some((cell) =>
                      hexNeighbors(river.path[0]!)
                        .map(hexKey)
                        .includes(hexKey(cell)),
                    ),
                  )
                  .flat()
                  .map(hexKey),
              )
            : new Set<string>();
        const last = byKey.get(keys.at(-1)!)!;
        const outside = neighborsOf(last, byKey).filter(
          (neighbor) =>
            isWater(neighbor.biome) &&
            !own.has(hexKey(neighbor)) &&
            !pond.has(hexKey(neighbor)),
        );
        expect(outside.length, `rio ${index}`).toBeGreaterThan(0);
        for (const cell of river.cells) {
          expect(['wshallow', 'wford']).toContain(
            byKey.get(hexKey(cell))!.biome,
          );
        }
      });
    }
  });

  it('os lagos e os rios não passam do pedido', () => {
    for (const map of maps) {
      expect(map.rivers.length).toBeLessThanOrEqual(WATERY.riverCount);
      const ponds = map.rivers.filter(({ source }) => source === 'lake').length;
      expect(map.lakes.length).toBeLessThanOrEqual(WATERY.lakeCount + ponds);
    }
  });

  it('há lagos sem rio e rios que nascem num lago pequeno', () => {
    const touches = (lake: HexCoordList, river: HexCoordList) => {
      const near = new Set(
        lake.flatMap((cell) => hexNeighbors(cell).map(hexKey)),
      );
      return river.some((cell) => near.has(hexKey(cell)));
    };
    const lonely = maps.flatMap((map) =>
      map.lakes.filter(
        (lake) => !map.rivers.some(({ cells }) => touches(lake, cells)),
      ),
    );
    expect(lonely.length).toBeGreaterThan(0);
    expect(
      maps.some((map) => map.rivers.some(({ source }) => source === 'lake')),
    ).toBe(true);
    expect(
      maps.some((map) => map.rivers.some(({ source }) => source === 'spring')),
    ).toBe(true);
  });

  it('toda terra que um rio toca continua ligada à chegada, por terra, vau ou ponte', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const river = new Set(
        map.rivers.flatMap(({ cells }) => cells).map(hexKey),
      );
      const seen = reachable(map);
      const cutOff = map.tiles.filter(
        (tile) =>
          !isWater(tile.biome) &&
          !seen.has(hexKey(tile)) &&
          neighborsOf(tile, byKey).some((neighbor) =>
            river.has(hexKey(neighbor)),
          ),
      );
      expect(cutOff).toEqual([]);
    }
  });

  it('todo lago é redondo, com pelo menos 6 hexágonos de largura nos 3 eixos', () => {
    let lakes = 0;
    for (const map of maps) {
      for (const lake of map.lakes) {
        lakes += 1;
        const inside = new Set(lake.map(hexKey));
        const [mx, my] = centerOf(lake as ShapedTile[]);
        const center = lake.reduce((best, cell) =>
          Math.hypot(
            point(cell as ShapedTile)[0] - mx,
            point(cell as ShapedTile)[1] - my,
          ) <
          Math.hypot(
            point(best as ShapedTile)[0] - mx,
            point(best as ShapedTile)[1] - my,
          )
            ? cell
            : best,
        );
        for (const [dq, dr] of [
          [1, 0],
          [0, 1],
          [1, -1],
        ] as const) {
          let across = 1;
          for (const sign of [1, -1]) {
            let step = 1;
            while (
              inside.has(
                hexKey({
                  q: center.q + dq * sign * step,
                  r: center.r + dr * sign * step,
                }),
              )
            ) {
              across += 1;
              step += 1;
            }
          }
          expect(across).toBeGreaterThanOrEqual(6);
        }
      }
    }
    expect(lakes).toBeGreaterThan(0);
  });

  it('o rio fica com a largura pedida, de 1 a 4 hexágonos', () => {
    let thin = 0;
    let wide = 0;
    let path = 0;
    for (const seed of SEEDS.slice(0, 20)) {
      for (const river of generateShapedMap(seed, {
        ...WATERY,
        riverMinWidth: 1,
        riverMaxWidth: 1,
      }).rivers) {
        expect(river.cells).toHaveLength(river.path.length);
        thin += 1;
      }
      for (const river of generateShapedMap(seed, {
        ...WATERY,
        riverMinWidth: 2,
        riverMaxWidth: 4,
      }).rivers) {
        wide += river.cells.length;
        path += river.path.length;
      }
    }
    expect(thin).toBeGreaterThan(0);
    expect(wide / path).toBeGreaterThan(2);
  });

  it('a Praia vai de `beachMinWidth` a `beachMaxWidth` hexágonos do mar', () => {
    const wideBeach = { ...WATERY, beachMinWidth: 2, beachMaxWidth: 4 };
    const reached = new Set<number>();
    for (const seed of SEEDS.slice(0, 20)) {
      const map = generateShapedMap(seed, wideBeach);
      const sea = seaOf(map);
      const fromSea = distanceTo(map, (tile) => sea.has(hexKey(tile)));
      for (const tile of map.tiles.filter(({ biome }) => biome === 'beach')) {
        reached.add(fromSea.get(hexKey(tile))!);
      }
    }
    expect([...reached].sort()).toEqual([1, 2, 3, 4]);
  });

  it('sem lagos e sem rios, eles não aparecem', () => {
    const none = { ...WATERY, lakeCount: 0, riverCount: 0 };
    for (const seed of SEEDS.slice(0, 10)) {
      const map = generateShapedMap(seed, none);
      expect(map.lakes).toEqual([]);
      expect(map.rivers).toEqual([]);
    }
  });
});

type HexCoordList = { q: number; r: number }[];

/** As duas pontas de uma ponte, como hexágonos. */
function bridgeEnds(points: number[]): [string, string] {
  const origin = flatCenter({ q: 0, r: 0 });
  const at = (x: number, y: number) =>
    hexKey(gridCoord({ x: origin.x + x, y: origin.y + y }));
  return [at(points[0]!, points[1]!), at(points[2]!, points[3]!)];
}

/** A terra que se alcança da chegada andando, pelos vaus e pelas pontes. */
function reachable(map: ShapedMap): Set<string> {
  const byKey = indexed(map);
  const links = new Map<string, string[]>();
  for (const { points } of map.bridges) {
    const [a, b] = bridgeEnds(points);
    links.set(a, [...(links.get(a) ?? []), b]);
    links.set(b, [...(links.get(b) ?? []), a]);
  }
  const seen = new Set([hexKey(map.start)]);
  const pending = [hexKey(map.start)];
  while (pending.length > 0) {
    const key = pending.pop()!;
    const next = [
      ...neighborsOf(byKey.get(key)!, byKey).map(hexKey),
      ...(links.get(key) ?? []),
    ];
    for (const other of next) {
      const tile = byKey.get(other)!;
      if (seen.has(other) || blocksWalking(tile.biome)) continue;
      seen.add(other);
      pending.push(other);
    }
  }
  return seen;
}

describe('os rios que atravessam e as travessias (coast-rivers/03)', () => {
  const CROSSING: MapConfig = {
    ...CONFIG,
    tileCount: 900,
    lakeCount: 2,
    lakeMinWidth: 6,
    lakeMaxWidth: 8,
    riverCount: 4,
    throughRiverChance: 0.6,
    crossingSpacing: 8,
    riverMinWidth: 2,
    riverMaxWidth: 4,
    beachMinWidth: 2,
    beachMaxWidth: 4,
  };
  let maps: ShapedMap[];

  beforeAll(() => {
    maps = SEEDS.slice(0, 60).map((seed) => generateShapedMap(seed, CROSSING));
  });

  it('há rios que atravessam, vaus e pontes ao longo das seeds', () => {
    expect(
      maps.some((map) => map.rivers.some(({ source }) => source === 'edge')),
    ).toBe(true);
    expect(
      maps.some((map) => map.tiles.some(({ biome }) => biome === 'wford')),
    ).toBe(true);
    expect(maps.some((map) => map.bridges.length > 0)).toBe(true);
  });

  it('toda terra de 3 hexágonos ou mais encostada num rio chega à chegada', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const river = new Set(
        map.rivers.flatMap(({ cells }) => cells).map(hexKey),
      );
      const seen = reachable(map);
      const pieces = new Map<string, number>();
      for (const tile of map.tiles) {
        if (
          isWater(tile.biome) ||
          seen.has(hexKey(tile)) ||
          pieces.has(hexKey(tile))
        )
          continue;
        const piece = [hexKey(tile)];
        pieces.set(hexKey(tile), 0);
        for (let index = 0; index < piece.length; index += 1) {
          for (const neighbor of neighborsOf(
            byKey.get(piece[index]!)!,
            byKey,
          )) {
            if (!isWater(neighbor.biome) && !pieces.has(hexKey(neighbor))) {
              pieces.set(hexKey(neighbor), 0);
              piece.push(hexKey(neighbor));
            }
          }
        }
        const touchesRiver = piece.some((key) =>
          neighborsOf(byKey.get(key)!, byKey).some((n) => river.has(hexKey(n))),
        );
        if (piece.length >= 3) expect(touchesRiver).toBe(false);
      }
    }
  });

  it('cada ponte é uma reta de margem a margem, por cima só de rio ou da beira de um lago', () => {
    for (const map of maps) {
      const byKey = indexed(map);
      const river = new Set(
        map.rivers.flatMap(({ cells }) => cells).map(hexKey),
      );
      for (const { type, points, width } of map.bridges) {
        expect(type).toBe('wood_bridge');
        expect(width).toBe(28);
        const [a, b] = bridgeEnds(points).map((key) => byKey.get(key)!);
        expect(isWater(a!.biome)).toBe(false);
        expect(isWater(b!.biome)).toBe(false);
        const steps = hexDistance(a!, b!);
        expect(steps).toBeGreaterThanOrEqual(2);
        expect(steps).toBeLessThanOrEqual(7);
        const dq = (b!.q - a!.q) / steps;
        const dr = (b!.r - a!.r) / steps;
        expect(Number.isInteger(dq) && Number.isInteger(dr)).toBe(true);
        const inland = new Set([...river, ...map.lakes.flat().map(hexKey)]);
        for (let step = 1; step < steps; step += 1) {
          const key = hexKey({ q: a!.q + dq * step, r: a!.r + dr * step });
          expect(inland.has(key)).toBe(true);
          expect(blocksWalking(byKey.get(key)!.biome)).toBe(true);
        }
      }
    }
  });

  it('o vau fica no rio e tem a variante de 1 a 3', () => {
    for (const map of maps) {
      const river = new Set(
        map.rivers.flatMap(({ cells }) => cells).map(hexKey),
      );
      const inland = new Set([...river, ...map.lakes.flat().map(hexKey)]);
      for (const tile of map.tiles.filter(({ biome }) => biome === 'wford')) {
        expect(inland.has(hexKey(tile))).toBe(true);
        expect(tile.variant).toBeLessThanOrEqual(3);
      }
    }
  });

  it('sem rio que atravessa, não há vau nem ponte; com 1, todo rio vem da borda', () => {
    for (const seed of SEEDS.slice(0, 20)) {
      const none = generateShapedMap(seed, {
        ...CROSSING,
        throughRiverChance: 0,
      });
      expect(none.bridges).toEqual([]);
      expect(none.tiles.some(({ biome }) => biome === 'wford')).toBe(false);
      expect(none.rivers.some(({ source }) => source === 'edge')).toBe(false);
      const all = generateShapedMap(seed, {
        ...CROSSING,
        throughRiverChance: 1,
      });
      expect(all.rivers.every(({ source }) => source === 'edge')).toBe(true);
    }
  });

  it('com `fordShare` 1, as travessias são só vaus; com 0, há mais pontes e menos vau', () => {
    let fewBridges = 0;
    let manyBridges = 0;
    let fewFords = 0;
    let manyFords = 0;
    const fords = (map: ShapedMap) =>
      map.tiles.filter(({ biome }) => biome === 'wford').length;
    for (const seed of SEEDS.slice(0, 30)) {
      const onlyFords = generateShapedMap(seed, { ...CROSSING, fordShare: 1 });
      expect(onlyFords.bridges).toEqual([]);
      manyFords += fords(onlyFords);
      const mostlyBridges = generateShapedMap(seed, {
        ...CROSSING,
        fordShare: 0,
      });
      manyBridges += mostlyBridges.bridges.length;
      fewFords += fords(mostlyBridges);
      fewBridges += onlyFords.bridges.length;
    }
    expect(manyBridges).toBeGreaterThan(fewBridges);
    expect(fewFords).toBeLessThan(manyFords);
  });
});

describe('startOf (bridges/04)', () => {
  it('prefere a terra plana mais perto da origem', () => {
    expect(
      startOf([
        { q: 0, r: 0, biome: 'wshallow', shape: 'flat' },
        { q: 1, r: 0, biome: 'stone', shape: 'hill' },
        { q: 3, r: 0, biome: 'temperate', shape: 'flat' },
      ]),
    ).toEqual({ q: 3, r: 0 });
  });

  it('sem terra plana, vai para a terra mais perto, nunca para a água', () => {
    expect(
      startOf([
        { q: 0, r: 0, biome: 'wdeep', shape: 'flat' },
        { q: 1, r: 0, biome: 'wshallow', shape: 'flat' },
        { q: 2, r: 0, biome: 'stone', shape: 'mont' },
        { q: 3, r: 0, biome: 'boreal', shape: 'hill' },
      ]),
    ).toEqual({ q: 2, r: 0 });
  });

  it('só sem terra nenhuma cai na água mais perto', () => {
    expect(
      startOf([
        { q: 2, r: 0, biome: 'wdeep', shape: 'flat' },
        { q: 0, r: 1, biome: 'wshallow', shape: 'flat' },
      ]),
    ).toEqual({ q: 0, r: 1 });
  });
});

describe('terrainOf', () => {
  it.each([
    ['temperate', 'flat', 'temperate', 1],
    ['boreal', 'flat', 'boreal', 1],
    ['stone', 'flat', 'stone', 3],
    ['wshallow', 'flat', 'wshallow', 0],
    ['wdeep', 'flat', 'wdeep', 0],
    ['temperate', 'hill', 'hill', 2],
    ['boreal', 'hill', 'hill', 2],
    ['stone', 'hill', 'hill', 3],
    ['wshallow', 'hill', 'hill', 2],
    ['desert', 'flat', 'desert', 1],
    ['snow', 'flat', 'snow', 1],
    ['desert', 'hill', 'desert', 2],
    ['snow', 'hill', 'snow', 2],
    ['desert', 'mont', 'mountain', 4],
    ['snow', 'mont', 'mountain', 4],
    ['temperate', 'mont', 'mountain', 4],
    ['stone', 'mont', 'mountain', 4],
    ['wdeep', 'mont', 'mountain', 4],
    ['beach', 'flat', 'beach', 1],
    ['beach', 'hill', 'beach', 2],
    ['beach', 'mont', 'mountain', 4],
    ['wford', 'flat', 'wford', 0],
  ] as const)('%s com %s vira %s na altura %d', (biome, shape, to, height) => {
    expect(terrainOf(biome, shape)).toEqual({ biome: to, height });
  });
});

describe('generateMap', () => {
  let maps: ReturnType<typeof generateMap>[];

  beforeAll(() => {
    maps = SEEDS.slice(0, 40).map((seed) => generateMap(seed, CONFIG));
  });

  it('são os 11 biomas do catálogo', () => {
    expect([...BIOMES].sort()).toEqual(
      [
        'beach',
        'boreal',
        'desert',
        'snow',
        'hill',
        'mountain',
        'stone',
        'temperate',
        'wdeep',
        'wford',
        'wshallow',
      ].sort(),
    );
  });

  it('é o mapa com forma convertido, hexágono por hexágono', () => {
    const shaped = generateShapedMap(77, CONFIG);
    const map = generateMap(77, CONFIG);
    expect(map.seed).toBe(shaped.seed);
    expect(map.start).toEqual(shaped.start);
    expect(map.tiles).toEqual(
      shaped.tiles.map(({ q, r, biome, shape, variant }) => ({
        q,
        r,
        ...terrainOf(biome, shape),
        variant,
      })),
    );
  });

  it('todo hexágono tem bioma, altura e variante válidos', () => {
    const invalid = maps
      .flatMap(({ tiles }) => tiles)
      .filter(
        ({ biome, height, variant }) =>
          !BIOMES.includes(biome) ||
          !Number.isInteger(height) ||
          height < 0 ||
          height > MAX_HEIGHT ||
          variant < 1 ||
          variant > maxVariant(biome),
      );
    expect(invalid).toEqual([]);
  });

  it('cada bioma fica na altura de antes', () => {
    const heights = new Map<string, Set<number>>();
    for (const { biome, height } of maps.flatMap(({ tiles }) => tiles)) {
      heights.set(biome, (heights.get(biome) ?? new Set()).add(height));
    }
    const sorted = (biome: string) => [...(heights.get(biome) ?? [])].sort();
    expect(sorted('mountain')).toEqual([4]);
    expect(sorted('stone')).toEqual([3]);
    expect(sorted('hill')).toEqual([2, 3]);
    expect(sorted('temperate')).toEqual([1]);
    expect(sorted('boreal')).toEqual([1]);
    expect(sorted('desert')).toEqual([1, 2]);
    expect(sorted('snow')).toEqual([1, 2]);
    expect(sorted('beach')).toEqual([1, 2]);
    expect(sorted('wshallow')).toEqual([0]);
    expect(sorted('wdeep')).toEqual([0]);
  });

  it('começa em terra plana', () => {
    for (const map of maps) {
      const start = map.tiles.find(
        ({ q, r }) => q === map.start.q && r === map.start.r,
      );
      expect([
        'temperate',
        'boreal',
        'stone',
        'desert',
        'snow',
        'beach',
      ]).toContain(start!.biome);
    }
  });
});

import { beforeAll, describe, expect, it } from 'vitest';
import { hexKey, hexNeighbors } from './hex.js';
import { DEFAULT_MAP_CONFIG } from './map-config.js';
import { generateShapedMap, type ShapedMap } from './map-generator.js';
import {
  bridgeLinks,
  reachable,
  rockHexes,
  SNOWY_ROCK_TYPES,
} from './map-rocks.js';

const SEEDS = Array.from({ length: 24 }, (_, index) => index * 7919 + 13);

describe('as pedras gigantes no mapa sorteado (giant-rocks/02)', () => {
  let maps: ShapedMap[];

  beforeAll(() => {
    // Só as pedras da Montanha; as de gelo ficam no map-glacier.spec.ts.
    const config = { ...DEFAULT_MAP_CONFIG, glacierChance: 0 };
    maps = SEEDS.map((seed) => generateShapedMap(seed, config));
  }, 60_000);

  it('há pedras ao longo das seeds, de todos os tipos', () => {
    const types = new Set(
      maps.flatMap(({ props }) => props.map(({ propTypeId }) => propTypeId)),
    );
    expect([...types].sort()).toEqual([131, 132, 133, 134, 135, 136, 137, 138]);
    const total = maps.reduce((sum, { props }) => sum + props.length, 0);
    expect(total / maps.length).toBeGreaterThan(2);
  });

  it('cada pedra fecha só Montanha, fora da chegada e sem encostar em outra', () => {
    for (const map of maps) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      const owner = new Map<string, number>();
      map.props.forEach((prop, index) => {
        const hexes = rockHexes(prop);
        expect(hexes.size).toBe(prop.propTypeId === 135 ? 2 : 1);
        for (const key of hexes) {
          expect(byKey.get(key)?.shape).toBe('mont');
          expect(key).not.toBe(hexKey(map.start));
          expect(owner.has(key)).toBe(false);
          owner.set(key, index);
        }
      });
      for (const [key, index] of owner) {
        for (const next of hexNeighbors(byKey.get(key)!)) {
          const other = owner.get(hexKey(next));
          expect(other === undefined || other === index).toBe(true);
        }
      }
    }
  });

  it('as de neve só ficam na Montanha de Neve, e as outras fora dela', () => {
    for (const map of maps) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      for (const prop of map.props) {
        const snowy = SNOWY_ROCK_TYPES.includes(prop.propTypeId);
        expect(byKey.get(hexKey(prop))!.biome === 'snow').toBe(snowy);
      }
    }
  });

  it('a terra alcançável da chegada é a de antes, menos os hexágonos das pedras', () => {
    for (const map of maps) {
      const byKey = new Map(map.tiles.map((tile) => [hexKey(tile), tile]));
      const links = bridgeLinks(map.bridges);
      const start = hexKey(map.start);
      const blocked = new Set(
        map.props.flatMap((prop) => [...rockHexes(prop)]),
      );
      const before = reachable(byKey, links, start, new Set());
      const flat = new Map(
        [...byKey].map(([key, tile]) => [key, { ...tile, height: 0 }]),
      );
      expect(before.size).toBe(reachable(flat, links, start, new Set()).size);
      const after = reachable(byKey, links, start, blocked);
      expect([...before].filter((key) => !blocked.has(key)).sort()).toEqual(
        [...after].sort(),
      );
    }
  });

  it('a mesma seed dá as mesmas pedras', () => {
    expect(generateShapedMap(SEEDS[3]!).props).toEqual(maps[3]!.props);
  });
});

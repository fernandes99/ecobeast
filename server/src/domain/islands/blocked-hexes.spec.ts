import { describe, expect, it } from 'vitest';
import {
  blockLineError,
  lineBlockedKeys,
  worldLines,
} from './blocked-hexes.js';
import { flatCenter } from './hex-pixels.js';

const prop = (overrides = {}) => ({
  propTypeId: 1,
  q: 0,
  r: 0,
  dx: 0,
  dy: 0,
  mirrored: false,
  ...overrides,
});
const keysOf = (set: Set<string>) => [...set].sort();
const NONE = new Map();

describe('lineBlockedKeys', () => {
  it('uma linha curta dentro de um hexágono só bloqueia ele', () => {
    const line = { closed: false, points: [-5, 0, 5, 0] };
    expect(
      keysOf(lineBlockedKeys([prop({ block: [line] })], [], NONE)),
    ).toEqual(['0,0']);
  });

  it('uma linha que passa do centro de (0, 0) ao de (1, 0) bloqueia os dois', () => {
    const line = { closed: false, points: [0, 0, 64, 0] };
    expect(
      keysOf(lineBlockedKeys([prop({ block: [line] })], [], NONE)),
    ).toEqual(['0,0', '1,0']);
  });

  it('uma linha fechada bloqueia os hexágonos de centro dentro dela', () => {
    const ring = {
      closed: true,
      points: [-100, -70, 100, -70, 100, 70, -100, 70],
    };
    const keys = lineBlockedKeys([prop({ block: [ring] })], [], NONE);
    expect(keys.has('0,0')).toBe(true);
    expect(keys.has('1,0')).toBe(true);
    expect(keys.has('-1,0')).toBe(true);
    const open = lineBlockedKeys(
      [prop({ block: [{ ...ring, closed: false }] })],
      [],
      NONE,
    );
    expect(open.has('0,0')).toBe(false);
  });

  it('usa as linhas do tipo quando a peça não tem as próprias', () => {
    const types = new Map([[1, [{ closed: false, points: [0, 0, 64, 0] }]]]);
    expect(keysOf(lineBlockedKeys([prop()], [], types))).toEqual([
      '0,0',
      '1,0',
    ]);
    expect(lineBlockedKeys([prop({ block: [] })], [], types).size).toBe(0);
  });

  it('espelha o x das linhas na peça espelhada', () => {
    const line = { closed: false, points: [0, 0, 64, 0] };
    expect(
      keysOf(
        lineBlockedKeys([prop({ block: [line], mirrored: true })], [], NONE),
      ),
    ).toEqual(['-1,0', '0,0']);
    const [world] = worldLines(
      prop({ block: [line], mirrored: true, dx: 3 }),
      NONE,
    );
    const center = flatCenter({ q: 0, r: 0 });
    expect(world!.points[1]).toEqual({ x: center.x + 3 - 64, y: center.y });
  });

  it('conta as paredes, a partir do centro plano de (0, 0)', () => {
    expect(
      keysOf(lineBlockedKeys([], [{ points: [0, 0, 64, 0] }], NONE)),
    ).toEqual(['0,0', '1,0']);
  });

  it('roda numa ilha cheia, com 2.000 peças e 2.000 paredes, em pouco tempo', () => {
    const ring = { closed: true, points: [-40, -10, 40, -10, 40, 12, -40, 12] };
    const props = Array.from({ length: 2000 }, (_, index) =>
      prop({ q: index % 100, r: Math.floor(index / 100), block: [ring] }),
    );
    const walls = Array.from({ length: 2000 }, (_, index) => ({
      points: [
        64 * (index % 100),
        42 * Math.floor(index / 100),
        64 * (index % 100) + 60,
        42 * Math.floor(index / 100) + 20,
      ],
    }));
    const started = performance.now();
    lineBlockedKeys(props, walls, NONE);
    const elapsed = performance.now() - started;
    console.log(`blockedKeys numa ilha cheia: ${elapsed.toFixed(1)} ms`);
    expect(elapsed).toBeLessThan(2000);
  });
});

describe('blockLineError', () => {
  it('aceita 2 pontos abertos e 3 fechados', () => {
    expect(blockLineError({ closed: false, points: [0, 0, 1, 1] })).toBeNull();
    expect(
      blockLineError({ closed: true, points: [0, 0, 1, 1, 2, 0] }),
    ).toBeNull();
  });
});

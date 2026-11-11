import {
  DEFAULT_MAP_CONFIG,
  MAP_CONFIG_RANGES,
  mapConfigError,
  withDefaults,
} from './map-config.js';

describe('MAP_CONFIG_RANGES (map-editor/01)', () => {
  it('tem uma faixa para cada parâmetro, com o padrão dentro dela', () => {
    expect(Object.keys(MAP_CONFIG_RANGES).sort()).toEqual(
      Object.keys(DEFAULT_MAP_CONFIG).sort(),
    );
    for (const [field, { min, max }] of Object.entries(MAP_CONFIG_RANGES)) {
      const value =
        DEFAULT_MAP_CONFIG[field as keyof typeof DEFAULT_MAP_CONFIG];
      expect(value, field).toBeGreaterThanOrEqual(min);
      expect(value, field).toBeLessThanOrEqual(max);
    }
  });
});

describe('mapConfigError', () => {
  it('aceita a configuração vazia e a padrão', () => {
    expect(mapConfigError({})).toBeNull();
    expect(mapConfigError({ ...DEFAULT_MAP_CONFIG })).toBeNull();
  });

  it('aceita os limites das faixas', () => {
    expect(mapConfigError({ tileCount: 100, waterFraction: 1 })).toBeNull();
    expect(mapConfigError({ tileCount: 20_000, waterFraction: 0 })).toBeNull();
  });

  it.each([
    [{ tileCount: 99 }, 'tileCount precisa ficar entre 100 e 20000.'],
    [{ waterFraction: 1.2 }, 'waterFraction precisa ficar entre 0 e 1.'],
    [{ noiseScale: 0 }, 'noiseScale precisa ficar entre 0.005 e 0.5.'],
    [{ cleanupPasses: 11 }, 'cleanupPasses precisa ficar entre 0 e 10.'],
  ])('recusa %o', (config, message) => {
    expect(mapConfigError(config)).toBe(message);
  });

  it.each([{ tileCount: 150.5 }, { cleanupPasses: 2.5 }])(
    'recusa número quebrado em %o',
    (config) => {
      expect(mapConfigError(config)).toMatch(/precisa ser um número inteiro/);
    },
  );
});

describe('withDefaults', () => {
  it('completa o que falta com o padrão', () => {
    expect(withDefaults({ waterFraction: 0.5 })).toEqual({
      ...DEFAULT_MAP_CONFIG,
      waterFraction: 0.5,
    });
  });
});

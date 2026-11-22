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
    expect(mapConfigError({ tileCount: 100, coastRoughness: 1 })).toBeNull();
    expect(mapConfigError({ tileCount: 20_000, coastRoughness: 0 })).toBeNull();
  });

  it.each([
    [{ tileCount: 99 }, 'tileCount precisa ficar entre 100 e 20000.'],
    [{ coastRoughness: 1.2 }, 'coastRoughness precisa ficar entre 0 e 1.'],
    [{ noiseScale: 0 }, 'noiseScale precisa ficar entre 0.005 e 0.5.'],
    [{ cleanupPasses: 11 }, 'cleanupPasses precisa ficar entre 0 e 10.'],
    [{ hillFraction: 1.2 }, 'hillFraction precisa ficar entre 0 e 1.'],
    [{ foothillChance: -0.1 }, 'foothillChance precisa ficar entre 0 e 1.'],
    [{ glacierChance: 1.5 }, 'glacierChance precisa ficar entre 0 e 1.'],
    [{ glacierMin: 4 }, 'glacierMin precisa ficar entre 5 e 100.'],
    [{ glacierMax: 201 }, 'glacierMax precisa ficar entre 5 e 200.'],
    [{ glacierLakeChance: -1 }, 'glacierLakeChance precisa ficar entre 0 e 1.'],
  ])('recusa %o', (config, message) => {
    expect(mapConfigError(config)).toBe(message);
  });

  it('recusa o patamar 4 começando depois do 7 (terrain-plateaus/02)', () => {
    expect(mapConfigError({ terraceLow: 0.8, terraceHigh: 0.7 })).toBe(
      'terraceLow precisa ser menor que terraceHigh.',
    );
    expect(mapConfigError({ terraceLow: 0.8 })).toBe(
      'terraceLow precisa ser menor que terraceHigh.',
    );
    expect(mapConfigError({ terraceLow: 0.3, terraceHigh: 0.6 })).toBeNull();
  });

  it('recusa a Geleira mínima maior que a máxima (glacier/04)', () => {
    expect(mapConfigError({ glacierMin: 70 })).toBe(
      'glacierMin não pode passar de glacierMax.',
    );
    expect(mapConfigError({ glacierMin: 30, glacierMax: 30 })).toBeNull();
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
    expect(withDefaults({ seaFraction: 0.5 })).toEqual({
      ...DEFAULT_MAP_CONFIG,
      seaFraction: 0.5,
    });
  });
});

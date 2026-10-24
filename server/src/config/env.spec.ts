import { validateEnv } from './env.js';

const urls = {
  DATABASE_URL: 'postgresql://user:pass@host:6543/postgres',
  DIRECT_URL: 'postgresql://user:pass@host:5432/postgres',
};

describe('validateEnv', () => {
  it('recusa a falta de DATABASE_URL citando a variável', () => {
    expect(() => validateEnv({ DIRECT_URL: urls.DIRECT_URL })).toThrow(
      /DATABASE_URL/,
    );
  });

  it('recusa a falta de DIRECT_URL citando a variável', () => {
    expect(() => validateEnv({ DATABASE_URL: urls.DATABASE_URL })).toThrow(
      /DIRECT_URL/,
    );
  });

  it('usa os padrões de PORT e THROTTLE_LIMIT', () => {
    const env = validateEnv({ ...urls });
    expect(env.PORT).toBe(3100);
    expect(env.THROTTLE_LIMIT).toBe(100);
  });

  it('converte PORT e THROTTLE_LIMIT de texto para número', () => {
    const env = validateEnv({ ...urls, PORT: '4000', THROTTLE_LIMIT: '5' });
    expect(env.PORT).toBe(4000);
    expect(env.THROTTLE_LIMIT).toBe(5);
  });
});

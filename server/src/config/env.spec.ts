import { validateEnv } from './env.js';

const urls = {
  DATABASE_URL: 'postgresql://user:pass@host:6543/postgres',
  DIRECT_URL: 'postgresql://user:pass@host:5432/postgres',
  SUPABASE_URL: 'https://projeto.supabase.co',
  SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_exemplo',
};

describe('validateEnv', () => {
  it('recusa a falta de DATABASE_URL citando a variável', () => {
    expect(() => validateEnv({ ...urls, DATABASE_URL: undefined })).toThrow(
      /DATABASE_URL/,
    );
  });

  it('recusa a falta de DIRECT_URL citando a variável', () => {
    expect(() => validateEnv({ ...urls, DIRECT_URL: undefined })).toThrow(
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

  it('recusa a falta de SUPABASE_URL citando a variável', () => {
    expect(() => validateEnv({ ...urls, SUPABASE_URL: undefined })).toThrow(
      /SUPABASE_URL/,
    );
  });

  it('recusa SUPABASE_URL que não é um endereço', () => {
    expect(() => validateEnv({ ...urls, SUPABASE_URL: 'projeto' })).toThrow(
      /SUPABASE_URL/,
    );
  });

  it('recusa a falta de SUPABASE_PUBLISHABLE_KEY citando a variável', () => {
    expect(() =>
      validateEnv({ ...urls, SUPABASE_PUBLISHABLE_KEY: undefined }),
    ).toThrow(/SUPABASE_PUBLISHABLE_KEY/);
  });

  it('usa http://localhost:<PORT> como PUBLIC_BASE_URL padrão', () => {
    expect(validateEnv({ ...urls }).PUBLIC_BASE_URL).toBe(
      'http://localhost:3100',
    );
    expect(validateEnv({ ...urls, PORT: '4000' }).PUBLIC_BASE_URL).toBe(
      'http://localhost:4000',
    );
  });

  it('aceita PUBLIC_BASE_URL e tira a barra do fim dos endereços', () => {
    const env = validateEnv({
      ...urls,
      SUPABASE_URL: 'https://projeto.supabase.co/',
      PUBLIC_BASE_URL: 'http://192.168.0.10:3100/',
    });
    expect(env.SUPABASE_URL).toBe('https://projeto.supabase.co');
    expect(env.PUBLIC_BASE_URL).toBe('http://192.168.0.10:3100');
  });

  it('recusa PUBLIC_BASE_URL que não é um endereço', () => {
    expect(() =>
      validateEnv({ ...urls, PUBLIC_BASE_URL: 'localhost' }),
    ).toThrow(/PUBLIC_BASE_URL/);
  });
});

describe('ENABLE_TEST_BATTLE', () => {
  it('é falsa por padrão', () => {
    expect(validateEnv({ ...urls }).ENABLE_TEST_BATTLE).toBe(false);
  });

  it('liga com "true"', () => {
    const env = validateEnv({ ...urls, ENABLE_TEST_BATTLE: 'true' });
    expect(env.ENABLE_TEST_BATTLE).toBe(true);
  });

  it('"false" desliga', () => {
    const env = validateEnv({ ...urls, ENABLE_TEST_BATTLE: 'false' });
    expect(env.ENABLE_TEST_BATTLE).toBe(false);
  });

  it('recusa outro valor citando a variável', () => {
    expect(() =>
      validateEnv({ ...urls, ENABLE_TEST_BATTLE: 'talvez' }),
    ).toThrow(/ENABLE_TEST_BATTLE/);
  });
});

describe('MAP_EDITOR_USER_IDS (map-editor/01)', () => {
  const A = '11111111-1111-4111-8111-111111111111';
  const B = '22222222-2222-4222-8222-222222222222';

  it('é uma lista vazia por padrão', () => {
    expect(validateEnv({ ...urls }).MAP_EDITOR_USER_IDS).toEqual([]);
  });

  it('vazia continua vazia', () => {
    expect(
      validateEnv({ ...urls, MAP_EDITOR_USER_IDS: '' }).MAP_EDITOR_USER_IDS,
    ).toEqual([]);
  });

  it('separa por vírgula e ignora os espaços em volta', () => {
    expect(
      validateEnv({ ...urls, MAP_EDITOR_USER_IDS: ` ${A} , ${B} ` })
        .MAP_EDITOR_USER_IDS,
    ).toEqual([A, B]);
  });

  it('recusa um id que não é uuid, citando a variável', () => {
    expect(() =>
      validateEnv({ ...urls, MAP_EDITOR_USER_IDS: `${A},fulano` }),
    ).toThrow(/MAP_EDITOR_USER_IDS/);
  });
});

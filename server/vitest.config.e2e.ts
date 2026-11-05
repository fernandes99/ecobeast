import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

/**
 * Os e2e da luta antiga, que nenhuma tela abre mais (board-battle/05, RF-08).
 * Ficam fora do `test:e2e` e rodam com `npm run test:e2e:legacy`, para quem
 * mexer no código dela.
 */
export const LEGACY_E2E = [
  'test/battle.e2e-spec.ts',
  'test/battle-items.e2e-spec.ts',
  'test/capture.e2e-spec.ts',
  'test/progression.e2e-spec.ts',
];

export function e2eConfig(include: string[], exclude: string[] = []) {
  return defineConfig({
    plugins: [tsconfigPaths()],
    test: {
      globals: true,
      root: './',
      include,
      exclude,
      // Limite de chamadas alto para os e2e; o teste do próprio limite baixa para 3.
      env: {
        THROTTLE_LIMIT: '10000',
        // O Supabase Auth dos e2e é sempre um dublê: nada sai para o de verdade.
        SUPABASE_URL: 'https://ecobeast-teste.supabase.co',
        SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_teste',
        PUBLIC_BASE_URL: 'http://localhost:3100',
        ENABLE_TEST_BATTLE: 'true',
      },
      // Os e2e falam com o Supabase pela rede.
      testTimeout: 30_000,
      hookTimeout: 30_000,
    },
  });
}

export default e2eConfig(['test/**/*.e2e-spec.ts'], LEGACY_E2E);

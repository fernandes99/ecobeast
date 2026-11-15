import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

const CATALOG_WRITERS = 'test/skills-editor.e2e-spec.ts';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    root: './',
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
    // O editor de Técnicas grava no catálogo: roda depois dos que o leem.
    projects: [
      {
        extends: true,
        test: {
          name: 'e2e',
          include: ['test/**/*.e2e-spec.ts'],
          exclude: [CATALOG_WRITERS],
          sequence: { groupOrder: 0 },
        },
      },
      {
        extends: true,
        test: {
          name: 'e2e-catalog-writers',
          include: [CATALOG_WRITERS],
          sequence: { groupOrder: 1 },
        },
      },
    ],
  },
});

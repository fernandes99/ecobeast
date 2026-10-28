import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    root: './',
    include: ['test/**/*.e2e-spec.ts'],
    // Limite de chamadas alto para os e2e; o teste do próprio limite baixa para 3.
    env: {
      THROTTLE_LIMIT: '10000',
      // O Supabase Auth dos e2e é sempre um dublê: nada sai para o de verdade.
      SUPABASE_URL: 'https://ecobeast-teste.supabase.co',
      SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_teste',
      PUBLIC_BASE_URL: 'http://localhost:3100',
    },
    // Os e2e falam com o Supabase pela rede.
    testTimeout: 30_000,
    hookTimeout: 30_000,
  },
});

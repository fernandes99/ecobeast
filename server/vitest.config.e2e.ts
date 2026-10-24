import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    root: './',
    include: ['test/**/*.e2e-spec.ts'],
    // Limite de chamadas alto para os e2e; o teste do próprio limite baixa para 3.
    env: { THROTTLE_LIMIT: '10000' },
    // Os e2e falam com o Supabase pela rede.
    testTimeout: 30_000,
    hookTimeout: 30_000,
  },
});

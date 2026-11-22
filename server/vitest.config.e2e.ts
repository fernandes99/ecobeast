import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

const CATALOG_WRITERS = [
  'test/skills-editor.e2e-spec.ts',
  'test/prop-types-editor.e2e-spec.ts',
  'test/day-phase-spawns.e2e-spec.ts',
  'test/npcs-editor.e2e-spec.ts',
  'test/npc-voice.e2e-spec.ts',
  // Liga e desliga a ilha casa, que é uma só para o banco inteiro.
  'test/home-island.e2e-spec.ts',
  // Cria e apaga salas e uma ilha de teste.
  'test/interiors.e2e-spec.ts',
  // Cria e apaga um NPC e os Domadores das ilhas de teste.
  'test/island-tamers.e2e-spec.ts',
  // Cria e apaga NPCs, salas e as Arenas das ilhas de teste.
  'test/arenas.e2e-spec.ts',
  // Cria e apaga NPCs, as ilhas de teste e as missões delas.
  'test/island-quests.e2e-spec.ts',
];

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
    // Os editores de Técnicas e de tipos de peça e o teste das partes do dia gravam no catálogo, e o da casa troca a ilha casa: rodam depois dos que leem.
    projects: [
      {
        extends: true,
        test: {
          name: 'e2e',
          include: ['test/**/*.e2e-spec.ts'],
          exclude: CATALOG_WRITERS,
          sequence: { groupOrder: 0 },
        },
      },
      {
        extends: true,
        test: {
          name: 'e2e-catalog-writers',
          include: CATALOG_WRITERS,
          sequence: { groupOrder: 1 },
        },
      },
    ],
  },
});

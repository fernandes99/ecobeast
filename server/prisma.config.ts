// Configuração da CLI do Prisma (migrations e seed). As tabelas ficam só em
// prisma/schema.prisma; aqui só o caminho dele e a URL que a CLI usa.
import 'dotenv/config';
import { defineConfig } from 'prisma/config';

/**
 * A CLI guarda o histórico de migrations (_prisma_migrations) no schema da URL,
 * que por padrão é o "public" — publicado pela API automática do Supabase.
 * Forçar "ecobeasts" mantém tudo do jogo fora do "public".
 */
function inEcobeastsSchema(url: string | undefined): string | undefined {
  if (!url) return url;
  const parsed = new URL(url);
  parsed.searchParams.set('schema', 'ecobeasts');
  return parsed.toString();
}

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'tsx prisma/seed.ts',
  },
  datasource: {
    // Migrations usam a conexão direta; o servidor usa DATABASE_URL (pooler).
    url: inEcobeastsSchema(process.env['DIRECT_URL']),
  },
});

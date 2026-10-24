// Configuração da CLI do Prisma (migrations e seed). As tabelas ficam só em
// prisma/schema.prisma; aqui só o caminho dele e a URL que a CLI usa.
import 'dotenv/config';
import { defineConfig } from 'prisma/config';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    // Migrations usam a conexão direta; o servidor usa DATABASE_URL (pooler).
    url: process.env['DIRECT_URL'],
  },
});

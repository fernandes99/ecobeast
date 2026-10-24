import { z } from 'zod';

/** Variáveis do .env (.specs/backend-api/01-server-setup.md, RF-02). */
const envSchema = z.object({
  /** Pooler do Supabase: usada pelo servidor. */
  DATABASE_URL: z.string().min(1),
  /** Conexão direta: usada pelas migrations. */
  DIRECT_URL: z.string().min(1),
  PORT: z.coerce.number().int().positive().default(3100),
  /** Chamadas por IP a cada 60 s (backend-api/04). */
  THROTTLE_LIMIT: z.coerce.number().int().positive().default(100),
});

export type Env = z.infer<typeof envSchema>;

/** Valida o .env na partida; uma variável faltando derruba o servidor com o nome dela. */
export function validateEnv(raw: Record<string, unknown>): Env {
  const result = envSchema.safeParse(raw);
  if (!result.success) {
    const problems = result.error.issues
      .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
      .join('; ');
    throw new Error(`Configuração inválida no .env — ${problems}`);
  }
  return result.data;
}

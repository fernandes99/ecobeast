import { z } from 'zod';

/** Endereço http(s); a barra do fim sai, para montar caminhos com `${url}/...`. */
const httpUrl = z
  .url({ protocol: /^https?$/ })
  .transform((url) => url.replace(/\/+$/, ''));

/**
 * Variáveis do .env (.specs/backend-api/01-server-setup.md, RF-02, e
 * .specs/auth-google/01-auth-server.md, RF-01).
 */
const envSchema = z.object({
  /** Pooler do Supabase: usada pelo servidor. */
  DATABASE_URL: z.string().min(1),
  /** Conexão direta: usada pelas migrations. */
  DIRECT_URL: z.string().min(1),
  PORT: z.coerce.number().int().positive().default(3100),
  /** Chamadas por IP a cada 60 s (backend-api/04). */
  THROTTLE_LIMIT: z.coerce.number().int().positive().default(100),
  /** https://<projeto>.supabase.co: o Supabase Auth e as chaves públicas. */
  SUPABASE_URL: httpUrl,
  /** A chave pública do projeto (antiga "anon"), exigida pelo Supabase Auth. */
  SUPABASE_PUBLISHABLE_KEY: z.string().min(1),
  /** O endereço deste servidor visto pelo navegador; padrão http://localhost:<PORT>. */
  PUBLIC_BASE_URL: httpUrl.optional(),
});

export type Env = Omit<z.infer<typeof envSchema>, 'PUBLIC_BASE_URL'> & {
  PUBLIC_BASE_URL: string;
};

/** Valida o .env na partida; uma variável faltando derruba o servidor com o nome dela. */
export function validateEnv(raw: Record<string, unknown>): Env {
  const result = envSchema.safeParse(raw);
  if (!result.success) {
    const problems = result.error.issues
      .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
      .join('; ');
    throw new Error(`Configuração inválida no .env — ${problems}`);
  }
  return {
    ...result.data,
    PUBLIC_BASE_URL:
      result.data.PUBLIC_BASE_URL ?? `http://localhost:${result.data.PORT}`,
  };
}

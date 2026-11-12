import { z } from 'zod';

const httpUrl = z
  .url({ protocol: /^https?$/ })
  .transform((url) => url.replace(/\/+$/, ''));

const envSchema = z.object({
  DATABASE_URL: z.string().min(1),
  DIRECT_URL: z.string().min(1),
  PORT: z.coerce.number().int().positive().default(3100),
  THROTTLE_LIMIT: z.coerce.number().int().positive().default(100),
  SUPABASE_URL: httpUrl,
  SUPABASE_PUBLISHABLE_KEY: z.string().min(1),
  PUBLIC_BASE_URL: httpUrl.optional(),
  ENABLE_TEST_BATTLE: z.stringbool().default(false),
  MAP_EDITOR_USER_IDS: z
    .string()
    .default('')
    .transform((raw) =>
      raw
        .split(',')
        .map((id) => id.trim())
        .filter((id) => id !== ''),
    )
    .pipe(z.array(z.uuid())),
});

export type Env = Omit<z.infer<typeof envSchema>, 'PUBLIC_BASE_URL'> & {
  PUBLIC_BASE_URL: string;
};

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

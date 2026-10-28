import { GoneException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.js';
import { PrismaService } from '../prisma/prisma.service.js';
import {
  codeChallenge,
  LOGIN_TTL_MS,
  LoginSessionsService,
  LoginUnavailableError,
  sha256Base64url,
} from './login-sessions.service.js';
import {
  AuthTokens,
  SupabaseAuthClient,
  SupabaseAuthError,
} from './supabase-auth.client.js';

const PUBLIC_BASE_URL = 'http://localhost:3100';
const TOKENS: AuthTokens = {
  access_token: 'access',
  refresh_token: 'refresh',
  expires_in: 3600,
};

interface Row {
  id: string;
  pollSecretHash: string;
  codeVerifier: string;
  status: 'pending' | 'complete' | 'failed';
  opened: boolean;
  accessToken: string | null;
  refreshToken: string | null;
  expiresIn: number | null;
  expiresAt: Date;
  createdAt: Date;
}

type Where = {
  id?: string;
  status?: Row['status'];
  opened?: boolean;
  expiresAt?: { lt?: Date; gt?: Date };
};

/** O pedaço do Prisma que o serviço usa, em memória. */
function fakePrisma() {
  const rows = new Map<string, Row>();
  let counter = 0;
  const matches = (row: Row, where: Where) =>
    (where.id === undefined || row.id === where.id) &&
    (where.status === undefined || row.status === where.status) &&
    (where.opened === undefined || row.opened === where.opened) &&
    (where.expiresAt?.lt === undefined || row.expiresAt < where.expiresAt.lt) &&
    (where.expiresAt?.gt === undefined || row.expiresAt > where.expiresAt.gt);
  const authLoginSession = {
    create: ({ data }: { data: Partial<Row> }) => {
      counter += 1;
      const row: Row = {
        id: `00000000-0000-4000-8000-${String(counter).padStart(12, '0')}`,
        pollSecretHash: '',
        codeVerifier: '',
        status: 'pending',
        opened: false,
        accessToken: null,
        refreshToken: null,
        expiresIn: null,
        expiresAt: new Date(),
        createdAt: new Date(),
        ...data,
      };
      rows.set(row.id, row);
      return Promise.resolve({ ...row });
    },
    findUnique: ({ where }: { where: { id: string } }) => {
      const row = rows.get(where.id);
      return Promise.resolve(row ? { ...row } : null);
    },
    updateMany: ({ where, data }: { where: Where; data: Partial<Row> }) => {
      let count = 0;
      for (const row of rows.values()) {
        if (matches(row, where)) {
          Object.assign(row, data);
          count += 1;
        }
      }
      return Promise.resolve({ count });
    },
    deleteMany: ({ where }: { where: Where }) => {
      let count = 0;
      for (const row of rows.values()) {
        if (matches(row, where)) {
          rows.delete(row.id);
          count += 1;
        }
      }
      return Promise.resolve({ count });
    },
  };
  return { rows, prisma: { authLoginSession } };
}

function setup() {
  const { rows, prisma } = fakePrisma();
  const supabase = {
    authorizeUrl: vi.fn(
      (redirectTo: string, challenge: string) =>
        `https://projeto.supabase.co/auth/v1/authorize?redirect_to=${encodeURIComponent(redirectTo)}&code_challenge=${challenge}`,
    ),
    exchangeCode: vi.fn(() => Promise.resolve(TOKENS)),
  };
  const config = {
    get: (key: keyof Env) => ({ PUBLIC_BASE_URL })[key as 'PUBLIC_BASE_URL'],
  } as unknown as ConfigService<Env, true>;
  const service = new LoginSessionsService(
    prisma as unknown as PrismaService,
    supabase as unknown as SupabaseAuthClient,
    config,
  );
  return { rows, supabase, service };
}

describe('codeChallenge', () => {
  it('segue o exemplo da RFC 7636 (S256)', () => {
    expect(codeChallenge('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk')).toBe(
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });
});

describe('LoginSessionsService', () => {
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(new Date('2026-10-28T12:00:00Z'));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  describe('start', () => {
    it('cria um login pendente de 10 minutos e devolve a url de ida', async () => {
      const { rows, service } = setup();
      const start = await service.start();

      const row = rows.get(start.login_id)!;
      expect(row.status).toBe('pending');
      expect(row.opened).toBe(false);
      expect(row.expiresAt.getTime()).toBe(Date.now() + LOGIN_TTL_MS);
      expect(LOGIN_TTL_MS).toBe(600_000);
      expect(start.url).toBe(
        `${PUBLIC_BASE_URL}/auth/google/go?login=${start.login_id}`,
      );
    });

    it('guarda só o hash do segredo, e segredo e verificador têm 32 bytes em base64url', async () => {
      const { rows, service } = setup();
      const start = await service.start();
      const row = rows.get(start.login_id)!;

      expect(start.poll_secret).toMatch(/^[A-Za-z0-9_-]{43}$/);
      expect(row.codeVerifier).toMatch(/^[A-Za-z0-9_-]{43}$/);
      expect(row.pollSecretHash).toBe(sha256Base64url(start.poll_secret));
      expect(row.pollSecretHash).not.toBe(start.poll_secret);
    });

    it('cada login tem segredo e verificador próprios', async () => {
      const { rows, service } = setup();
      const a = await service.start();
      const b = await service.start();
      expect(a.poll_secret).not.toBe(b.poll_secret);
      expect(rows.get(a.login_id)!.codeVerifier).not.toBe(
        rows.get(b.login_id)!.codeVerifier,
      );
    });

    it('apaga os logins vencidos', async () => {
      const { rows, service } = setup();
      const old = await service.start();
      vi.setSystemTime(Date.now() + LOGIN_TTL_MS + 1);
      await service.start();
      expect(rows.has(old.login_id)).toBe(false);
      expect(rows.size).toBe(1);
    });
  });

  describe('go', () => {
    it('marca como aberto e devolve a autorização com o desafio do verificador', async () => {
      const { rows, supabase, service } = setup();
      const { login_id } = await service.start();

      const url = await service.go(login_id);

      const row = rows.get(login_id)!;
      expect(row.opened).toBe(true);
      expect(supabase.authorizeUrl).toHaveBeenCalledWith(
        `${PUBLIC_BASE_URL}/auth/google/callback?login=${login_id}`,
        codeChallenge(row.codeVerifier),
      );
      expect(url).toContain('code_challenge=');
    });

    it('só funciona uma vez', async () => {
      const { service } = setup();
      const { login_id } = await service.start();
      await service.go(login_id);
      await expect(service.go(login_id)).rejects.toBeInstanceOf(
        LoginUnavailableError,
      );
    });

    it('recusa login vencido, inexistente ou com id inválido', async () => {
      const { service } = setup();
      const { login_id } = await service.start();
      vi.setSystemTime(Date.now() + LOGIN_TTL_MS + 1);
      await expect(service.go(login_id)).rejects.toBeInstanceOf(
        LoginUnavailableError,
      );
      await expect(
        service.go('00000000-0000-4000-8000-999999999999'),
      ).rejects.toBeInstanceOf(LoginUnavailableError);
      await expect(service.go('nao-e-uuid')).rejects.toBeInstanceOf(
        LoginUnavailableError,
      );
    });
  });

  describe('complete', () => {
    it('troca o código, guarda os tokens e marca como completo', async () => {
      const { rows, supabase, service } = setup();
      const { login_id } = await service.start();
      await service.go(login_id);

      await service.complete(login_id, 'codigo');

      const row = rows.get(login_id)!;
      expect(supabase.exchangeCode).toHaveBeenCalledWith(
        'codigo',
        row.codeVerifier,
      );
      expect(row.status).toBe('complete');
      expect(row.accessToken).toBe('access');
      expect(row.refreshToken).toBe('refresh');
      expect(row.expiresIn).toBe(3600);
    });

    it('recusa login que não passou pela ida', async () => {
      const { supabase, service } = setup();
      const { login_id } = await service.start();
      await expect(service.complete(login_id, 'codigo')).rejects.toBeInstanceOf(
        LoginUnavailableError,
      );
      expect(supabase.exchangeCode).not.toHaveBeenCalled();
    });

    it('recusa login vencido ou já completo', async () => {
      const { service } = setup();
      const { login_id } = await service.start();
      await service.go(login_id);
      await service.complete(login_id, 'codigo');
      await expect(service.complete(login_id, 'codigo')).rejects.toBeInstanceOf(
        LoginUnavailableError,
      );

      const other = await service.start();
      await service.go(other.login_id);
      vi.setSystemTime(Date.now() + LOGIN_TTL_MS + 1);
      await expect(
        service.complete(other.login_id, 'codigo'),
      ).rejects.toBeInstanceOf(LoginUnavailableError);
    });

    it('marca como falho e relança quando a troca falha', async () => {
      const { rows, supabase, service } = setup();
      const { login_id } = await service.start();
      await service.go(login_id);
      supabase.exchangeCode.mockRejectedValueOnce(
        new SupabaseAuthError(400, 'pkce recusado'),
      );

      await expect(service.complete(login_id, 'codigo')).rejects.toBeInstanceOf(
        SupabaseAuthError,
      );
      expect(rows.get(login_id)!.status).toBe('failed');
    });
  });

  describe('fail', () => {
    it('marca um login pendente como falho', async () => {
      const { rows, service } = setup();
      const { login_id } = await service.start();
      await service.fail(login_id);
      expect(rows.get(login_id)!.status).toBe('failed');
    });

    it('ignora id inválido', async () => {
      const { service } = setup();
      await expect(service.fail('nao-e-uuid')).resolves.toBeUndefined();
    });
  });

  describe('poll', () => {
    it('responde pendente enquanto o login não terminou', async () => {
      const { service } = setup();
      const { login_id, poll_secret } = await service.start();
      await expect(service.poll(login_id, poll_secret)).resolves.toEqual({
        status: 'pending',
      });
    });

    it('entrega os tokens uma vez só e apaga o login', async () => {
      const { rows, service } = setup();
      const { login_id, poll_secret } = await service.start();
      await service.go(login_id);
      await service.complete(login_id, 'codigo');

      await expect(service.poll(login_id, poll_secret)).resolves.toEqual({
        status: 'complete',
        tokens: TOKENS,
      });
      expect(rows.has(login_id)).toBe(false);
      await expect(service.poll(login_id, poll_secret)).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('dá 404 para segredo errado, id inexistente ou inválido', async () => {
      const { service } = setup();
      const { login_id } = await service.start();
      const notFound = { response: { message: 'Login não encontrado.' } };
      await expect(service.poll(login_id, 'errado')).rejects.toMatchObject(
        notFound,
      );
      await expect(
        service.poll('00000000-0000-4000-8000-999999999999', 'x'),
      ).rejects.toBeInstanceOf(NotFoundException);
      await expect(service.poll('nao-e-uuid', 'x')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });

    it('dá 410 e apaga o login vencido', async () => {
      const { rows, service } = setup();
      const { login_id, poll_secret } = await service.start();
      vi.setSystemTime(Date.now() + LOGIN_TTL_MS + 1);

      await expect(service.poll(login_id, poll_secret)).rejects.toMatchObject({
        response: { message: 'Login expirado. Tente de novo.' },
      });
      expect(rows.has(login_id)).toBe(false);
    });

    it('dá 410 e apaga o login falho', async () => {
      const { rows, service } = setup();
      const { login_id, poll_secret } = await service.start();
      await service.fail(login_id);

      await expect(service.poll(login_id, poll_secret)).rejects.toBeInstanceOf(
        GoneException,
      );
      expect(rows.has(login_id)).toBe(false);
    });
  });
});

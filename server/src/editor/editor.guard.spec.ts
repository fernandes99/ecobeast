import {
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';
import type { AuthenticatedRequest } from '../auth/auth.guard.js';
import type { Env } from '../config/env.js';
import { EditorGuard, NOT_AN_EDITOR } from './editor.guard.js';

const OWNER = '11111111-1111-4111-8111-111111111111';
const OTHER = '22222222-2222-4222-8222-222222222222';

function context(userId: string): ExecutionContext {
  const request: Partial<AuthenticatedRequest> = { userId };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

function guard(ids: string[]): EditorGuard {
  const config = { get: () => ids } as unknown as ConfigService<Env, true>;
  return new EditorGuard(config);
}

describe('EditorGuard', () => {
  it('deixa passar quem está em MAP_EDITOR_USER_IDS', () => {
    expect(guard([OTHER, OWNER]).canActivate(context(OWNER))).toBe(true);
  });

  it('responde 403 a quem não está na lista', () => {
    expect(() => guard([OWNER]).canActivate(context(OTHER))).toThrow(
      ForbiddenException,
    );
    expect(() => guard([OWNER]).canActivate(context(OTHER))).toThrow(
      NOT_AN_EDITOR,
    );
  });

  it('responde 404, como rota que não existe, com a lista vazia', () => {
    expect(() => guard([]).canActivate(context(OWNER))).toThrow(
      NotFoundException,
    );
    expect(() => guard([]).canActivate(context(OWNER))).toThrow(
      'Rota não encontrada.',
    );
  });
});

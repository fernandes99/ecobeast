import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { AuthenticatedRequest } from '../auth/auth.guard.js';
import type { Env } from '../config/env.js';

export const NOT_AN_EDITOR = 'Só quem edita o mapa pode usar esta rota.';

/**
 * As rotas do editor de ilhas só aceitam quem está em MAP_EDITOR_USER_IDS
 * (.specs/map-editor/architecture.md, "Quem edita"). Com a lista vazia, elas
 * respondem como uma rota que não existe. Roda depois do AuthGuard.
 */
@Injectable()
export class EditorGuard implements CanActivate {
  constructor(private readonly config: ConfigService<Env, true>) {}

  canActivate(context: ExecutionContext): boolean {
    const editors = this.config.get('MAP_EDITOR_USER_IDS', { infer: true });
    if (editors.length === 0) {
      throw new NotFoundException('Rota não encontrada.');
    }
    const { userId } = context
      .switchToHttp()
      .getRequest<AuthenticatedRequest>();
    if (!editors.includes(userId)) throw new ForbiddenException(NOT_AN_EDITOR);
    return true;
  }
}

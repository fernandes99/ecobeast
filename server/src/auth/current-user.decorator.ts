import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import type { AuthenticatedRequest } from './auth.guard.js';

/** O id do usuário do token (o `sub`), em rotas protegidas pelo AuthGuard. */
export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext): string =>
    context.switchToHttp().getRequest<AuthenticatedRequest>().userId,
);

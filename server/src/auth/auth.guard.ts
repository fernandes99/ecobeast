import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { TokenVerifier } from './token-verifier.js';

export interface AuthenticatedRequest extends Request {
  userId: string;
}

const BEARER = /^Bearer (\S+)$/;

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly verifier: TokenVerifier) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = BEARER.exec(request.headers.authorization ?? '')?.[1];
    try {
      if (!token) throw new Error('sem token');
      request.userId = (await this.verifier.verify(token)).userId;
    } catch {
      throw new UnauthorizedException('Sessão inválida. Entre de novo.');
    }
    return true;
  }
}

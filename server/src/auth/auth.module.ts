import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Env } from '../config/env.js';
import { AuthController } from './auth.controller.js';
import { AuthGuard } from './auth.guard.js';
import { GoogleRedirectController } from './google-redirect.controller.js';
import { LoginSessionsService } from './login-sessions.service.js';
import { SupabaseAuthClient } from './supabase-auth.client.js';
import { TokenVerifier } from './token-verifier.js';

/** Login com Google pelo Supabase Auth e a guarda das rotas do jogador. */
@Module({
  controllers: [AuthController, GoogleRedirectController],
  providers: [
    SupabaseAuthClient,
    LoginSessionsService,
    AuthGuard,
    {
      provide: TokenVerifier,
      inject: [ConfigService],
      useFactory: (config: ConfigService<Env, true>) =>
        TokenVerifier.forSupabase(config.get('SUPABASE_URL', { infer: true })),
    },
  ],
  exports: [AuthGuard, TokenVerifier],
})
export class AuthModule {}

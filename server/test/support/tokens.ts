import {
  createLocalJWKSet,
  exportJWK,
  generateKeyPair,
  type JWTPayload,
  SignJWT,
} from 'jose';
import { TokenVerifier } from '../../src/auth/token-verifier.js';

const KID = 'chave-de-teste';

export interface TestTokens {
  /** Confere tokens desta chave, com o emissor do SUPABASE_URL dos e2e. */
  verifier: TokenVerifier;
  /** Um access token válido por 1 hora para `sub`. */
  sign(sub: string, claims?: JWTPayload): Promise<string>;
}

/**
 * Par de chaves gerado na hora: os e2e assinam tokens como o Supabase Auth
 * assinaria, sem Google nem Supabase de verdade.
 */
export async function createTestTokens(): Promise<TestTokens> {
  const issuer = `${process.env['SUPABASE_URL']}/auth/v1`;
  const { publicKey, privateKey } = await generateKeyPair('ES256');
  const jwk = { ...(await exportJWK(publicKey)), kid: KID, alg: 'ES256' };
  return {
    verifier: new TokenVerifier(createLocalJWKSet({ keys: [jwk] }), issuer),
    sign: (sub, claims = {}) =>
      new SignJWT({ aud: 'authenticated', iss: issuer, sub, ...claims })
        .setProtectedHeader({ alg: 'ES256', kid: KID })
        .setIssuedAt()
        .setExpirationTime('1h')
        .sign(privateKey),
  };
}

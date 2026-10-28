import {
  createLocalJWKSet,
  exportJWK,
  generateKeyPair,
  type CryptoKey,
  type JWTPayload,
  SignJWT,
} from 'jose';
import { TokenVerifier } from './token-verifier.js';

const ISSUER = 'https://projeto.supabase.co/auth/v1';
const KID = 'chave-1';

let privateKey: CryptoKey;
let otherKey: CryptoKey;
let verifier: TokenVerifier;

beforeAll(async () => {
  const pair = await generateKeyPair('ES256');
  privateKey = pair.privateKey;
  otherKey = (await generateKeyPair('ES256')).privateKey;
  const jwk = { ...(await exportJWK(pair.publicKey)), kid: KID, alg: 'ES256' };
  verifier = new TokenVerifier(createLocalJWKSet({ keys: [jwk] }), ISSUER);
});

function sign(
  claims: JWTPayload,
  options: { key?: CryptoKey; expiresIn?: string | number } = {},
): Promise<string> {
  return new SignJWT({ aud: 'authenticated', iss: ISSUER, ...claims })
    .setProtectedHeader({ alg: 'ES256', kid: KID })
    .setIssuedAt()
    .setExpirationTime(options.expiresIn ?? '1h')
    .sign(options.key ?? privateKey);
}

describe('TokenVerifier', () => {
  it('aceita um token assinado pela chave do JWKS e devolve o sub', async () => {
    const token = await sign({ sub: '5b1d2c9e-1111-4222-8333-444455556666' });
    await expect(verifier.verify(token)).resolves.toEqual({
      userId: '5b1d2c9e-1111-4222-8333-444455556666',
    });
  });

  it('recusa um token vencido', async () => {
    const token = await sign(
      { sub: 'u1' },
      { expiresIn: Math.floor(Date.now() / 1000) - 60 },
    );
    await expect(verifier.verify(token)).rejects.toThrow();
  });

  it('recusa um token de outro emissor', async () => {
    const token = await sign({
      sub: 'u1',
      iss: 'https://outro.supabase.co/auth/v1',
    });
    await expect(verifier.verify(token)).rejects.toThrow();
  });

  it('recusa um token de outra audiência', async () => {
    const token = await sign({ sub: 'u1', aud: 'anon' });
    await expect(verifier.verify(token)).rejects.toThrow();
  });

  it('recusa um token assinado por outra chave', async () => {
    const token = await sign({ sub: 'u1' }, { key: otherKey });
    await expect(verifier.verify(token)).rejects.toThrow();
  });

  it('recusa um token sem sub', async () => {
    const token = await sign({});
    await expect(verifier.verify(token)).rejects.toThrow();
  });

  it('recusa texto que não é JWT', async () => {
    await expect(verifier.verify('isto-nao-e-um-token')).rejects.toThrow();
  });

  it('forSupabase usa o JWKS e o emissor do projeto', () => {
    const fromUrl = TokenVerifier.forSupabase('https://projeto.supabase.co');
    expect(fromUrl.issuer).toBe(ISSUER);
  });
});

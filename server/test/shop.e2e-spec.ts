import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { Item, PrismaClient } from '../src/generated/prisma/client.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// Os testes não conferem preços: leem o preço do banco, que o dono muda no painel.

const FAGULHO = 1;
const BUY_PATH = '/v1/me/shop/buy';
const NO_PLAYER = 'Crie seu Domador primeiro.';
const NOT_ENOUGH_COINS = 'Moedas insuficientes.';
const INVALID_ITEM = 'Esse item não existe.';

describe('Rota de compra (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let item: Item;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    item = await prisma.item.findFirstOrThrow({ orderBy: { id: 'asc' } });
  });

  afterAll(async () => {
    await prisma.player.deleteMany({ where: { id: { in: users } } });
    await prisma.$disconnect();
    await app.close();
  });

  async function newUser() {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    return {
      id,
      create: () => http().post('/v1/me').set(auth).send({ name: 'Ana' }),
      starter: () =>
        http().post('/v1/me/starter').set(auth).send({ species_id: FAGULHO }),
      read: () => http().get('/v1/me').set(auth),
      buy: (body: object = { item_id: item.id }) =>
        http().post(BUY_PATH).set(auth).send(body),
    };
  }

  type User = Awaited<ReturnType<typeof newUser>>;

  /** Um usuário com inicial e exatamente estas moedas. */
  async function userWithCoins(coins: number): Promise<User> {
    const user = await newUser();
    await user.create().expect(201);
    await user.starter().expect(200);
    await prisma.player.update({ where: { id: user.id }, data: { coins } });
    return user;
  }

  async function stateOf(user: User) {
    const { coins } = await prisma.player.findUniqueOrThrow({
      where: { id: user.id },
    });
    const rows = await prisma.inventoryItem.findMany({
      where: { playerId: user.id },
    });
    return { coins, quantities: rows.map((row) => row.quantity) };
  }

  it('sem token, dá 401', async () => {
    await request(app.getHttpServer())
      .post(BUY_PATH)
      .send({ item_id: item.id })
      .expect(401);
  });

  it('sem Domador, dá 409', async () => {
    const user = await newUser();
    const res = await user.buy().expect(409);
    expect(res.body.message).toBe(NO_PLAYER);
  });

  it('sem equipe, dá 409', async () => {
    const user = await newUser();
    await user.create().expect(201);
    const res = await user.buy().expect(409);
    expect(res.body.message).toBe(NO_PLAYER);
  });

  it('desconta o preço do banco, e a resposta já traz a Mochila', async () => {
    const user = await userWithCoins(item.price + 7);
    const res = await user.buy().expect(200);
    expect(res.body.player.coins).toBe(7);
    expect(res.body.player.inventory).toEqual([
      { item_id: item.id, quantity: 1 },
    ]);
  });

  it('ignora um preço mandado no pedido', async () => {
    const user = await userWithCoins(item.price);
    const res = await user.buy({ item_id: item.id, price: 1 }).expect(200);
    expect(res.body.player.coins).toBe(0);
  });

  it('comprar de novo soma, sem criar outra linha', async () => {
    const user = await userWithCoins(item.price * 2);
    await user.buy().expect(200);
    await user.buy().expect(200);
    expect(await stateOf(user)).toEqual({ coins: 0, quantities: [2] });
  });

  it('com uma moeda a menos que o preço, dá 409 e nada muda', async () => {
    const user = await userWithCoins(item.price - 1);
    const res = await user.buy().expect(409);
    expect(res.body.message).toBe(NOT_ENOUGH_COINS);
    expect(await stateOf(user)).toEqual({
      coins: item.price - 1,
      quantities: [],
    });
  });

  it.each([
    ['inexistente', { item_id: 2_000_000_000 }],
    ['maior que o banco aceita', { item_id: 2 ** 40 }],
    ['em texto', { item_id: 'tonico' }],
    ['ausente', {}],
  ])('com item %s, dá 400', async (_name, body) => {
    const user = await userWithCoins(item.price);
    const res = await user.buy(body).expect(400);
    expect(res.body.message).toBe(INVALID_ITEM);
    expect(await stateOf(user)).toEqual({ coins: item.price, quantities: [] });
  });

  it('duas compras ao mesmo tempo, com moedas para uma, viram uma só', async () => {
    const user = await userWithCoins(item.price);
    const results = await Promise.all([user.buy(), user.buy()]);
    expect(results.map((res) => res.status).sort()).toEqual([200, 409]);
    expect(await stateOf(user)).toEqual({ coins: 0, quantities: [1] });
  });

  it('duas compras ao mesmo tempo, com moedas para as duas, somam', async () => {
    const user = await userWithCoins(item.price * 2);
    await Promise.all([user.buy().expect(200), user.buy().expect(200)]);
    expect(await stateOf(user)).toEqual({ coins: 0, quantities: [2] });
  });

  it('com uma falha ao gravar a Mochila, as moedas voltam', async () => {
    const user = await userWithCoins(item.price);
    const service = app.get(PrismaService);
    const transaction = service.$transaction.bind(service) as (
      work: (tx: object) => Promise<unknown>,
    ) => Promise<unknown>;
    const failure = vi.spyOn(service, '$transaction').mockImplementationOnce(((
      work: (tx: object) => Promise<unknown>,
    ) =>
      transaction((tx) =>
        work(
          new Proxy(tx, {
            get: (target, key) =>
              key === 'inventoryItem'
                ? { upsert: () => Promise.reject(new Error('falha simulada')) }
                : Reflect.get(target, key),
          }),
        ),
      )) as never);

    await user.buy().expect(500);
    failure.mockRestore();

    expect(await stateOf(user)).toEqual({ coins: item.price, quantities: [] });
  });

  it('a rota aparece no OpenAPI, com o cadeado', async () => {
    const res = await request(app.getHttpServer())
      .get('/docs/openapi.json')
      .expect(200);
    const route = (
      res.body as {
        paths: Record<
          string,
          { post: { tags: string[]; security: unknown[] } }
        >;
      }
    ).paths[BUY_PATH]!.post;
    expect(route.tags).toEqual(['Mochila e Loja']);
    expect(route.security).toEqual([{ bearer: [] }]);
  });
});

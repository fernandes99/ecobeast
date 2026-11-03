import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { Item, PrismaClient } from '../src/generated/prisma/client.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

// Os testes não conferem os valores dos itens: leem do banco, que o dono muda
// no painel.

const RUVO = 1;
const USE_PATH = '/v1/me/items/use';
const FLEE = { type: 'flee' };
const NO_PLAYER = 'Crie seu Domador primeiro.';
const NO_ITEM = 'Você não tem esse item.';
const INVALID_ITEM = 'Esse item não existe.';
const NOT_FOUND = 'Ecobeast não encontrado.';
const CANNOT_USE = 'Esse item não pode ser usado agora.';
const CANNOT_REVIVE = 'Só o Refúgio recupera um Ecobeast sem HP.';
const NO_EFFECT = 'Não teria efeito.';
const NO_BATTLE = 'Nenhuma batalha em andamento.';

interface Party {
  uid: string;
  current_hp: number;
  stats: { hp: number };
  status_condition_id: number | null;
}

describe('Rota de uso de item (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let tonic: Item;
  let balm: Item;
  let sphere: Item;
  let statusId: number;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
    tonic = await prisma.item.findFirstOrThrow({
      where: { healAmount: { not: null }, curesStatus: false },
    });
    balm = await prisma.item.findFirstOrThrow({
      where: { healAmount: null, curesStatus: true },
    });
    sphere = await prisma.item.findFirstOrThrow({
      where: { healAmount: null, curesStatus: false },
    });
    statusId = (await prisma.statusCondition.findFirstOrThrow()).id;
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
        http().post('/v1/me/starter').set(auth).send({ species_id: RUVO }),
      read: () => http().get('/v1/me').set(auth),
      use: (body: object) => http().post(USE_PATH).set(auth).send(body),
      wild: () => {
        placeWild(app, id);
        return http().post('/v1/me/battle/wild').set(auth).send(HERE);
      },
      act: (body: object) =>
        http().post('/v1/me/battle/action').set(auth).send(body),
    };
  }

  type User = Awaited<ReturnType<typeof newUser>>;

  /** Um usuário com inicial; devolve a criatura como a API a mostra. */
  async function userWithStarter() {
    const user = await newUser();
    await user.create().expect(201);
    const res = await user.starter().expect(200);
    return { user, creature: res.body.player.party[0] as Party };
  }

  async function give(user: User, item: Item, quantity: number) {
    await prisma.inventoryItem.create({
      data: { playerId: user.id, itemId: item.id, quantity },
    });
  }

  async function setCreature(
    user: User,
    data: { currentHp?: number; statusConditionId?: number },
  ) {
    await prisma.creatureInstance.updateMany({
      where: { playerId: user.id },
      data,
    });
  }

  async function quantityOf(user: User, item: Item) {
    const row = await prisma.inventoryItem.findUnique({
      where: { playerId_itemId: { playerId: user.id, itemId: item.id } },
    });
    return row?.quantity ?? 0;
  }

  async function currentHp(user: User) {
    const row = await prisma.creatureInstance.findFirstOrThrow({
      where: { playerId: user.id },
    });
    return row.currentHp;
  }

  /** Um segundo Ecobeast do jogador, no Santuário. */
  async function addToStorage(user: User) {
    const row = await prisma.creatureInstance.findFirstOrThrow({
      where: { playerId: user.id },
      include: { stats: true },
    });
    return prisma.creatureInstance.create({
      data: {
        playerId: user.id,
        speciesId: row.speciesId,
        level: row.level,
        currentXp: row.currentXp,
        currentHp: 1,
        temperamentId: row.temperamentId,
        traitId: row.traitId,
        gender: row.gender,
        bond: row.bond,
        originalPlayerId: user.id,
        caughtAt: row.caughtAt,
        location: 'storage',
        partySlot: null,
        stats: {
          create: row.stats.map(({ statId, genes, trainingPoints }) => ({
            statId,
            genes,
            trainingPoints,
          })),
        },
      },
    });
  }

  it('sem token, dá 401', async () => {
    await request(app.getHttpServer())
      .post(USE_PATH)
      .send({ item_id: tonic.id, creature_uid: randomUUID() })
      .expect(401);
  });

  it('sem Domador, dá 409', async () => {
    const user = await newUser();
    const res = await user
      .use({ item_id: tonic.id, creature_uid: randomUUID() })
      .expect(409);
    expect(res.body.message).toBe(NO_PLAYER);
  });

  it('um Tônico cura e gasta uma unidade', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 2);
    await setCreature(user, { currentHp: 1 });

    const res = await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(200);

    const healed = Math.min(1 + tonic.healAmount!, creature.stats.hp);
    expect((res.body.player.party[0] as Party).current_hp).toBe(healed);
    expect(res.body.player.inventory).toEqual([
      { item_id: tonic.id, quantity: 1 },
    ]);
    expect(await currentHp(user)).toBe(healed);
  });

  it('o HP nunca passa do máximo', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 1);
    await setCreature(user, { currentHp: creature.stats.hp - 1 });

    await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(200);

    expect(await currentHp(user)).toBe(creature.stats.hp);
  });

  it('o Bálsamo remove o status e gasta uma unidade', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, balm, 2);
    await setCreature(user, { statusConditionId: statusId });

    const res = await user
      .use({ item_id: balm.id, creature_uid: creature.uid })
      .expect(200);

    expect((res.body.player.party[0] as Party).status_condition_id).toBeNull();
    expect(await quantityOf(user, balm)).toBe(1);
  });

  it('a última unidade apaga a linha, e o item some da Mochila', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 1);
    await setCreature(user, { currentHp: 1 });

    const res = await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(200);

    expect(res.body.player.inventory).toEqual([]);
    expect(await quantityOf(user, tonic)).toBe(0);
  });

  it('com HP cheio, dá 409 e não gasta o item', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 1);
    const res = await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(409);
    expect(res.body.message).toBe(NO_EFFECT);
    expect(await quantityOf(user, tonic)).toBe(1);
  });

  it('com 0 HP, dá 409 e não gasta o item', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 1);
    await setCreature(user, { currentHp: 0 });
    const res = await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(409);
    expect(res.body.message).toBe(CANNOT_REVIVE);
    expect(await quantityOf(user, tonic)).toBe(1);
    expect(await currentHp(user)).toBe(0);
  });

  it('uma Esfera não pode ser usada', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, sphere, 1);
    const res = await user
      .use({ item_id: sphere.id, creature_uid: creature.uid })
      .expect(409);
    expect(res.body.message).toBe(CANNOT_USE);
    expect(await quantityOf(user, sphere)).toBe(1);
  });

  it('sem o item, dá 409', async () => {
    const { user, creature } = await userWithStarter();
    await setCreature(user, { currentHp: 1 });
    const res = await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(409);
    expect(res.body.message).toBe(NO_ITEM);
  });

  it.each([
    ['inexistente', 2_000_000_000],
    ['maior que o banco aceita', 2 ** 40],
    ['em texto', 'tonico'],
  ])('com item %s, dá 400', async (_name, itemId) => {
    const { user, creature } = await userWithStarter();
    const res = await user
      .use({ item_id: itemId, creature_uid: creature.uid })
      .expect(400);
    expect(res.body.message).toBe(INVALID_ITEM);
  });

  it('um Ecobeast de outro Domador dá 404', async () => {
    const { user } = await userWithStarter();
    const { creature: other } = await userWithStarter();
    await give(user, tonic, 1);
    const res = await user
      .use({ item_id: tonic.id, creature_uid: other.uid })
      .expect(404);
    expect(res.body.message).toBe(NOT_FOUND);
    expect(await quantityOf(user, tonic)).toBe(1);
  });

  it('um Ecobeast do Santuário dá 404, sem curar', async () => {
    const { user } = await userWithStarter();
    const stored = await addToStorage(user);
    await give(user, tonic, 1);
    await user.use({ item_id: tonic.id, creature_uid: stored.uid }).expect(404);
    const row = await prisma.creatureInstance.findUniqueOrThrow({
      where: { uid: stored.uid },
    });
    expect(row.currentHp).toBe(1);
  });

  it.each([
    ['em branco', ''],
    ['ausente', undefined],
    ['que não é um uuid', 'ruvo'],
  ])('com creature_uid %s, dá 404', async (_name, creatureUid) => {
    const { user } = await userWithStarter();
    await give(user, tonic, 1);
    await user
      .use({ item_id: tonic.id, creature_uid: creatureUid })
      .expect(404);
  });

  it('usar um item descarta a batalha aberta', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 1);
    await setCreature(user, { currentHp: 1 });
    await user.wild().expect(201);

    await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(200);

    const res = await user.act(FLEE).expect(404);
    expect(res.body.message).toBe(NO_BATTLE);
  });

  it('um item recusado mantém a batalha aberta', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 1);
    await user.wild().expect(201);

    await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(409);

    await user.act(FLEE).expect(200);
  });

  it('dois usos ao mesmo tempo da última unidade gastam uma só', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 1);
    await setCreature(user, { currentHp: 1 });
    const body = { item_id: tonic.id, creature_uid: creature.uid };

    const results = await Promise.all([user.use(body), user.use(body)]);

    expect(results.map((res) => res.status).sort()).toEqual([200, 409]);
    expect(await quantityOf(user, tonic)).toBe(0);
    expect(await currentHp(user)).toBe(
      Math.min(1 + tonic.healAmount!, creature.stats.hp),
    );
  });

  it('com uma falha ao gravar o HP, o item volta', async () => {
    const { user, creature } = await userWithStarter();
    await give(user, tonic, 2);
    await setCreature(user, { currentHp: 1 });
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
              key === 'creatureInstance'
                ? {
                    updateMany: () =>
                      Promise.reject(new Error('falha simulada')),
                  }
                : Reflect.get(target, key),
          }),
        ),
      )) as never);

    await user
      .use({ item_id: tonic.id, creature_uid: creature.uid })
      .expect(500);
    failure.mockRestore();

    expect(await quantityOf(user, tonic)).toBe(2);
    expect(await currentHp(user)).toBe(1);
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
    ).paths[USE_PATH]!.post;
    expect(route.tags).toEqual(['Mochila e Loja']);
    expect(route.security).toEqual([{ bearer: [] }]);
  });
});

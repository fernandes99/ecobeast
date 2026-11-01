import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { BattleStore } from '../src/battle/battle.store.js';
import { Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

const FAGULHO = 1;
const WEAK_ENEMY = { species_id: FAGULHO, level: 1 };
const NO_PLAYER = 'Crie seu Domador primeiro.';
const NOT_FOUND = 'Ecobeast não encontrado.';
const INVALID_ORDER = 'Ordem inválida.';
const ALREADY_IN_TEAM = 'Esse Ecobeast já está na equipe.';
const ALREADY_STORED = 'Esse Ecobeast já está no Santuário.';
const TEAM_FULL = 'A equipe está cheia.';
const LAST_CREATURE = 'A equipe precisa de ao menos 1 Ecobeast.';

interface Creature {
  uid: string;
}

type Place =
  | { location: 'party'; partySlot: number }
  | { location: 'storage'; partySlot: null };

const party = (partySlot: number): Place => ({ location: 'party', partySlot });
const STORAGE: Place = { location: 'storage', partySlot: null };

describe('Equipe e Santuário (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  const users: string[] = [];

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({ tokenVerifier: tokens.verifier });
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
      storage: () => http().get('/v1/me/storage').set(auth),
      order: (body: object) =>
        http().post('/v1/me/team/order').set(auth).send(body),
      bring: (body: object) =>
        http().post('/v1/me/team/bring').set(auth).send(body),
      store: (body: object) =>
        http().post('/v1/me/team/store').set(auth).send(body),
      start: () => http().post('/v1/me/battle').set(auth).send(WEAK_ENEMY),
    };
  }

  type User = Awaited<ReturnType<typeof newUser>>;

  async function userWithStarter(): Promise<User> {
    const user = await newUser();
    await user.create().expect(201);
    await user.starter().expect(200);
    return user;
  }

  /** Uma cópia do inicial no lugar pedido; devolve o `uid`. */
  async function addCreature(
    user: User,
    place: Place,
    data: Partial<Prisma.CreatureInstanceUncheckedCreateInput> = {},
  ): Promise<string> {
    const row = await prisma.creatureInstance.findFirstOrThrow({
      where: { playerId: user.id },
      orderBy: { caughtAt: 'asc' },
      include: { stats: true, skills: true },
    });
    const created = await prisma.creatureInstance.create({
      data: {
        playerId: user.id,
        speciesId: row.speciesId,
        level: row.level,
        currentXp: row.currentXp,
        currentHp: row.currentHp,
        temperamentId: row.temperamentId,
        traitId: row.traitId,
        gender: row.gender,
        bond: row.bond,
        originalPlayerId: user.id,
        caughtAt: row.caughtAt,
        ...place,
        stats: {
          create: row.stats.map(({ statId, genes, trainingPoints }) => ({
            statId,
            genes,
            trainingPoints,
          })),
        },
        skills: {
          create: row.skills.map(({ slot, skillId, currentPp }) => ({
            slot,
            skillId,
            currentPp,
          })),
        },
        ...data,
      },
    });
    return created.uid;
  }

  async function fullTeam(user: User): Promise<string[]> {
    const uids = [await starterUid(user)];
    for (const slot of [2, 3, 4, 5, 6]) {
      uids.push(await addCreature(user, party(slot)));
    }
    return uids;
  }

  async function starterUid(user: User): Promise<string> {
    const [first] = await teamUids(user);
    return first!;
  }

  async function teamUids(user: User): Promise<string[]> {
    const res = await user.read().expect(200);
    return (res.body.player.party as Creature[]).map(({ uid }) => uid);
  }

  async function storageUids(user: User): Promise<string[]> {
    const res = await user.storage().expect(200);
    return (res.body.creatures as Creature[]).map(({ uid }) => uid);
  }

  function place(uid: string) {
    return prisma.creatureInstance.findUniqueOrThrow({
      where: { uid },
      select: { location: true, partySlot: true },
    });
  }

  function snapshot(user: User) {
    return prisma.creatureInstance.findMany({
      where: { playerId: user.id },
      orderBy: { uid: 'asc' },
      select: { uid: true, location: true, partySlot: true },
    });
  }

  describe('sem Domador', () => {
    it.each([
      ['storage', (user: User) => user.storage()],
      ['order', (user: User) => user.order({ uids: [] })],
      ['bring', (user: User) => user.bring({ uid: randomUUID() })],
      ['store', (user: User) => user.store({ uid: randomUUID() })],
    ])('%s dá 409', async (_name, call) => {
      const user = await newUser();
      const res = await call(user).expect(409);
      expect(res.body.message).toBe(NO_PLAYER);
    });

    it('sem inicial, reordenar também dá 409', async () => {
      const user = await newUser();
      await user.create().expect(201);
      const res = await user.order({ uids: [] }).expect(409);
      expect(res.body.message).toBe(NO_PLAYER);
    });
  });

  describe('GET /v1/me/storage', () => {
    it('um Domador novo tem o Santuário vazio', async () => {
      const user = await userWithStarter();
      const res = await user.storage().expect(200);
      expect(res.body).toEqual({ creatures: [] });
    });

    it('não traz quem está na equipe', async () => {
      const user = await userWithStarter();
      const stored = await addCreature(user, STORAGE);
      await addCreature(user, party(2));

      expect(await storageUids(user)).toEqual([stored]);
    });

    it('traz os mesmos campos da equipe', async () => {
      const user = await userWithStarter();
      await addCreature(user, STORAGE);

      const [member] = (await user.read().expect(200)).body.player.party;
      const [stored] = (await user.storage().expect(200)).body.creatures;

      expect(Object.keys(stored).sort()).toEqual(Object.keys(member).sort());
    });

    it('os capturados mais recentes vêm primeiro', async () => {
      const user = await userWithStarter();
      const older = await addCreature(user, STORAGE, {
        caughtAt: new Date('2026-01-01'),
      });
      const newer = await addCreature(user, STORAGE, {
        caughtAt: new Date('2026-06-01'),
      });

      expect(await storageUids(user)).toEqual([newer, older]);
    });

    it('não traz o Ecobeast de outro Domador', async () => {
      const owner = await userWithStarter();
      await addCreature(owner, STORAGE);
      const other = await userWithStarter();

      expect(await storageUids(other)).toEqual([]);
    });
  });

  describe('POST /v1/me/team/order', () => {
    it('muda a ordem da equipe', async () => {
      const user = await userWithStarter();
      const first = await starterUid(user);
      const second = await addCreature(user, party(2));
      const third = await addCreature(user, party(3));

      const res = await user
        .order({ uids: [third, first, second] })
        .expect(200);

      const uids = (res.body.player.party as Creature[]).map(({ uid }) => uid);
      expect(uids).toEqual([third, first, second]);
      expect(await teamUids(user)).toEqual([third, first, second]);
    });

    it('fecha as vagas do meio', async () => {
      const user = await userWithStarter();
      const first = await starterUid(user);
      const second = await addCreature(user, party(3));
      const third = await addCreature(user, party(5));

      await user.order({ uids: [first, second, third] }).expect(200);

      expect((await place(second)).partySlot).toBe(2);
      expect((await place(third)).partySlot).toBe(3);
    });

    it('com a equipe cheia, inverte todos', async () => {
      const user = await userWithStarter();
      const uids = await fullTeam(user);
      const reversed = [...uids].reverse();

      await user.order({ uids: reversed }).expect(200);

      expect(await teamUids(user)).toEqual(reversed);
    });

    it('recusa quem está no Santuário', async () => {
      const user = await userWithStarter();
      const first = await starterUid(user);
      const stored = await addCreature(user, STORAGE);
      const before = await snapshot(user);

      const res = await user.order({ uids: [stored, first] }).expect(400);

      expect(res.body.message).toBe(INVALID_ORDER);
      expect(await snapshot(user)).toEqual(before);
    });

    it.each([
      ['faltando alguém', (uids: string[]) => uids.slice(1)],
      ['sobrando alguém', (uids: string[]) => [...uids, randomUUID()]],
      ['repetido', (uids: string[]) => [uids[0]!, uids[0]!]],
      ['em texto', () => 'x'],
      ['sem uids', () => undefined],
    ])('recusa a lista %s, sem mudar nada', async (_name, build) => {
      const user = await userWithStarter();
      await addCreature(user, party(2));
      const before = await snapshot(user);

      const res = await user
        .order({ uids: build(await teamUids(user)) })
        .expect(400);

      expect(res.body.message).toContain(INVALID_ORDER);
      expect(await snapshot(user)).toEqual(before);
    });

    it('uma falha no meio não muda a equipe', async () => {
      const user = await userWithStarter();
      const first = await starterUid(user);
      const second = await addCreature(user, party(2));
      const before = await snapshot(user);
      failOnSecondUpdate();

      await user.order({ uids: [second, first] }).expect(500);

      expect(await snapshot(user)).toEqual(before);
    });

    /** O segundo `update` dentro da transação falha, e ela volta de verdade. */
    function failOnSecondUpdate() {
      const service = app.get(PrismaService);
      const original = service.$transaction.bind(service) as (
        ...args: unknown[]
      ) => Promise<unknown>;
      vi.spyOn(service, '$transaction').mockImplementationOnce(((
        work: (tx: Prisma.TransactionClient) => Promise<unknown>,
        options: unknown,
      ) =>
        original(
          (tx: Prisma.TransactionClient) => work(failingTx(tx)),
          options,
        )) as never);
    }

    function failingTx(tx: Prisma.TransactionClient) {
      let updates = 0;
      const creatures = new Proxy(tx.creatureInstance, {
        get(target, property, receiver) {
          if (property !== 'update') {
            return Reflect.get(target, property, receiver);
          }
          return (args: never) => {
            updates += 1;
            if (updates === 2) throw new Error('Falha simulada.');
            return target.update(args);
          };
        },
      });
      return new Proxy(tx, {
        get: (target, property, receiver) =>
          property === 'creatureInstance'
            ? creatures
            : Reflect.get(target, property, receiver),
      });
    }
  });

  describe('POST /v1/me/team/bring', () => {
    it('com vaga, entra na primeira vaga livre', async () => {
      const user = await userWithStarter();
      await addCreature(user, party(3));
      const stored = await addCreature(user, STORAGE);

      const res = await user.bring({ uid: stored }).expect(200);

      expect(await place(stored)).toEqual({
        location: 'party',
        partySlot: 2,
      });
      expect(res.body.player.party).toHaveLength(3);
      expect(await storageUids(user)).toEqual([]);
    });

    it('com a equipe cheia e sem troca, dá 409', async () => {
      const user = await userWithStarter();
      await fullTeam(user);
      const stored = await addCreature(user, STORAGE);
      const before = await snapshot(user);

      const res = await user.bring({ uid: stored }).expect(409);

      expect(res.body.message).toBe(TEAM_FULL);
      expect(await snapshot(user)).toEqual(before);
    });

    it('com troca, os dois trocam de lugar', async () => {
      const user = await userWithStarter();
      const uids = await fullTeam(user);
      const stored = await addCreature(user, STORAGE);
      const leaving = uids[3]!;

      await user.bring({ uid: stored, replace_uid: leaving }).expect(200);

      expect(await place(stored)).toEqual({
        location: 'party',
        partySlot: 4,
      });
      expect(await place(leaving)).toEqual({
        location: 'storage',
        partySlot: null,
      });
      expect(await teamUids(user)).toHaveLength(6);
    });

    it('com troca e vaga sobrando, usa a vaga de quem saiu', async () => {
      const user = await userWithStarter();
      const first = await starterUid(user);
      const stored = await addCreature(user, STORAGE);

      await user.bring({ uid: stored, replace_uid: first }).expect(200);

      expect((await place(stored)).partySlot).toBe(1);
    });

    it('quem já está na equipe dá 400', async () => {
      const user = await userWithStarter();
      const res = await user.bring({ uid: await starterUid(user) }).expect(400);
      expect(res.body.message).toBe(ALREADY_IN_TEAM);
    });

    it('um replace_uid do Santuário dá 404, sem mudar nada', async () => {
      const user = await userWithStarter();
      const stored = await addCreature(user, STORAGE);
      const other = await addCreature(user, STORAGE);
      const before = await snapshot(user);

      const res = await user
        .bring({ uid: stored, replace_uid: other })
        .expect(404);

      expect(res.body.message).toBe(NOT_FOUND);
      expect(await snapshot(user)).toEqual(before);
    });

    it('um replace_uid de outro Domador dá 404', async () => {
      const user = await userWithStarter();
      const stored = await addCreature(user, STORAGE);
      const other = await userWithStarter();

      const res = await user
        .bring({ uid: stored, replace_uid: await starterUid(other) })
        .expect(404);

      expect(res.body.message).toBe(NOT_FOUND);
    });

    it('um Ecobeast de outro Domador dá 404', async () => {
      const owner = await userWithStarter();
      const stored = await addCreature(owner, STORAGE);
      const thief = await userWithStarter();

      const res = await thief.bring({ uid: stored }).expect(404);

      expect(res.body.message).toBe(NOT_FOUND);
      expect((await place(stored)).location).toBe('storage');
    });

    it.each([
      ['malformado', 'x'],
      ['sem texto', 1],
      ['ausente', undefined],
    ])('um uid %s dá 404', async (_name, uid) => {
      const user = await userWithStarter();
      const res = await user.bring({ uid }).expect(404);
      expect(res.body.message).toBe(NOT_FOUND);
    });

    it('dois pedidos pela última vaga deixam 6 na equipe', async () => {
      const user = await userWithStarter();
      for (const slot of [2, 3, 4, 5]) await addCreature(user, party(slot));
      const first = await addCreature(user, STORAGE);
      const second = await addCreature(user, STORAGE);

      const answers = await Promise.all([
        user.bring({ uid: first }),
        user.bring({ uid: second }),
      ]);

      expect(answers.map((res) => res.status).sort()).toEqual([200, 409]);
      expect(await teamUids(user)).toHaveLength(6);
      expect(await storageUids(user)).toHaveLength(1);
    });
  });

  describe('POST /v1/me/team/store', () => {
    it('manda o Ecobeast para o Santuário', async () => {
      const user = await userWithStarter();
      const second = await addCreature(user, party(2));

      const res = await user.store({ uid: second }).expect(200);

      expect(res.body.player.party).toHaveLength(1);
      expect(await place(second)).toEqual({
        location: 'storage',
        partySlot: null,
      });
      expect(await storageUids(user)).toEqual([second]);
    });

    it('o último da equipe fica', async () => {
      const user = await userWithStarter();
      const first = await starterUid(user);

      const res = await user.store({ uid: first }).expect(400);

      expect(res.body.message).toBe(LAST_CREATURE);
      expect((await place(first)).location).toBe('party');
    });

    it('quem já está no Santuário dá 400', async () => {
      const user = await userWithStarter();
      const stored = await addCreature(user, STORAGE);
      const res = await user.store({ uid: stored }).expect(400);
      expect(res.body.message).toBe(ALREADY_STORED);
    });

    it('um Ecobeast de outro Domador dá 404', async () => {
      const owner = await userWithStarter();
      const second = await addCreature(owner, party(2));
      const thief = await userWithStarter();

      const res = await thief.store({ uid: second }).expect(404);

      expect(res.body.message).toBe(NOT_FOUND);
    });

    it('um uid malformado dá 404', async () => {
      const user = await userWithStarter();
      const res = await user.store({ uid: 'x' }).expect(404);
      expect(res.body.message).toBe(NOT_FOUND);
    });

    it('dois pedidos ao mesmo tempo deixam 1 na equipe', async () => {
      const user = await userWithStarter();
      const first = await starterUid(user);
      const second = await addCreature(user, party(2));

      const answers = await Promise.all([
        user.store({ uid: first }),
        user.store({ uid: second }),
      ]);

      expect(answers.map((res) => res.status).sort()).toEqual([200, 400]);
      expect(await teamUids(user)).toHaveLength(1);
    });
  });

  it('mover não muda HP, status, PP, Genes, Treino nem apelido', async () => {
    const user = await userWithStarter();
    const status = await prisma.statusCondition.findFirstOrThrow();
    const stored = await addCreature(user, STORAGE, {
      currentHp: 3,
      statusConditionId: status.id,
      nickname: 'Brasa',
    });
    await prisma.creatureInstanceSkill.updateMany({
      where: { creatureUid: stored },
      data: { currentPp: 2 },
    });
    const read = () =>
      prisma.creatureInstance.findUniqueOrThrow({
        where: { uid: stored },
        omit: { location: true, partySlot: true },
        include: { stats: true, skills: true },
      });
    const before = await read();

    await user.bring({ uid: stored }).expect(200);
    await user.order({ uids: [stored, await starterUid(user)] }).expect(200);
    await user.store({ uid: stored }).expect(200);

    expect(await read()).toEqual(before);
  });

  describe('a batalha aberta', () => {
    const hasBattle = (user: User) =>
      Boolean(app.get(BattleStore).get(user.id));

    it('some ao reordenar', async () => {
      const user = await userWithStarter();
      const first = await starterUid(user);
      const second = await addCreature(user, party(2));
      await user.start().expect(201);

      await user.order({ uids: [second, first] }).expect(200);

      expect(hasBattle(user)).toBe(false);
    });

    it('some ao trazer um Ecobeast', async () => {
      const user = await userWithStarter();
      const stored = await addCreature(user, STORAGE);
      await user.start().expect(201);

      await user.bring({ uid: stored }).expect(200);

      expect(hasBattle(user)).toBe(false);
    });

    it('some ao mandar para o Santuário', async () => {
      const user = await userWithStarter();
      const second = await addCreature(user, party(2));
      await user.start().expect(201);

      await user.store({ uid: second }).expect(200);

      expect(hasBattle(user)).toBe(false);
    });

    it('fica quando o pedido é recusado', async () => {
      const user = await userWithStarter();
      await user.start().expect(201);

      await user.store({ uid: await starterUid(user) }).expect(400);

      expect(hasBattle(user)).toBe(true);
    });

    it('fica ao só listar o Santuário', async () => {
      const user = await userWithStarter();
      await user.start().expect(201);

      await user.storage().expect(200);

      expect(hasBattle(user)).toBe(true);
    });
  });
});

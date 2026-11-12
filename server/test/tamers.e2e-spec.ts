import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { ExplorationStore } from '../src/exploration/exploration.store.js';
import { Prisma, PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { type PlayableBattle, playOut, waitVez } from './support/board-play.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';
import { HERE, placeWild } from './support/wild.js';

const RUVO = 1;
const NO_TAMER_HERE = 'Nenhum Domador por aqui.';
const TAMER_WAITING = 'Um Domador está esperando você aqui.';
const NO_EXPLORATION = 'Essa exploração acabou. Saia e entre de novo.';
const TAMER_CREATURE = 'Não dá para capturar o Ecobeast de outro Domador.';

interface TamerBody {
  battle: PlayableBattle & {
    result: string | null;
    can_flee: boolean;
    tamer: { name_id: number; source: string } | null;
  };
  events: { type: string }[];
  tamer_id: number | null;
  spawn_id: number | null;
}

describe('Domadores NPC (e2e)', () => {
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

  async function userWithStarter(
    data: Prisma.CreatureInstanceUncheckedUpdateManyInput = {},
  ) {
    const id = randomUUID();
    users.push(id);
    const auth = { Authorization: `Bearer ${await tokens.sign(id)}` };
    const http = () => request(app.getHttpServer());
    await http().post('/v1/me').set(auth).send({ name: 'Ana' }).expect(201);
    await http()
      .post('/v1/me/starter')
      .set(auth)
      .send({ species_id: RUVO })
      .expect(200);
    await prisma.creatureInstance.updateMany({ where: { playerId: id }, data });
    return {
      id,
      explore: () => http().post('/v1/me/exploration').set(auth),
      tamer: (body: object = HERE) =>
        http().post('/v1/me/board-battle/tamer').set(auth).send(body),
      challenge: () => http().post('/v1/me/board-battle/challenge').set(auth),
      wild: (body: object = HERE) =>
        http().post('/v1/me/board-battle/wild').set(auth).send(body),
      act: async (body: object) =>
        (
          await http()
            .post('/v1/me/board-battle/action')
            .set(auth)
            .send(body)
            .expect(200)
        ).body as TamerBody,
      actRaw: (body: object) =>
        http().post('/v1/me/board-battle/action').set(auth).send(body),
      debugTamer: (body: object) =>
        http().post('/v1/me/exploration/tamers').set(auth).send(body),
      debugClear: () => http().delete('/v1/me/exploration/spawns').set(auth),
    };
  }

  /** Nível 100: joga antes de um Ecobeast de nível 1 e aguenta qualquer golpe dele. */
  const strongUser = () => userWithStarter({ level: 100, currentHp: 150 });
  const exploration = (userId: string) => app.get(ExplorationStore).get(userId);

  it('o mapa traz os Domadores, sem tamanho nem equipe', async () => {
    const user = await userWithStarter();
    const { body } = await user.explore().expect(201);
    const tamers = body.map.tamers as Record<string, unknown>[];
    expect(tamers.length).toBeGreaterThan(0);
    for (const tamer of tamers) {
      expect(Object.keys(tamer).sort()).toEqual(
        ['greeting_id', 'id', 'name_id', 'q', 'r'].sort(),
      );
    }
    expect(exploration(user.id)!.tamers.size).toBe(tamers.length);
  });

  it('a luta contra o Domador do hexágono não tem fuga e diz de onde ele veio', async () => {
    const user = await userWithStarter();
    placeWild(
      app,
      user.id,
      [],
      [
        {
          size: 3,
          team: [
            { speciesId: RUVO, level: 5 },
            { speciesId: RUVO, level: 5 },
            { speciesId: RUVO, level: 5 },
          ],
        },
      ],
    );
    const { body } = (await user.tamer().expect(201)) as { body: TamerBody };
    expect(body.tamer_id).toBe(1);
    expect(body.spawn_id).toBeNull();
    expect(body.battle.can_flee).toBe(false);
    expect(body.battle.tamer).toEqual({ name_id: 1, source: 'map' });
    expect(
      body.battle.enemy.cells.filter((cell) => cell !== null),
    ).toHaveLength(3);
    // Só o inicial de pé: 1 vaga do lado do jogador.
    expect(body.battle.player.cells).toHaveLength(1);
    expect(exploration(user.id)!.tamers.size).toBe(0);
  });

  it('a segunda luta no mesmo hexágono não encontra mais o Domador', async () => {
    const user = await userWithStarter();
    placeWild(app, user.id, [], [{}]);
    await user.tamer().expect(201);
    const { body } = await user.tamer().expect(409);
    expect(body.message).toBe(NO_TAMER_HERE);
  });

  it('a Esfera é recusada, e as respostas da vez repetem o Domador', async () => {
    const user = await userWithStarter();
    placeWild(app, user.id, [], [{ nameId: 2 }]);
    const { body } = (await user.tamer().expect(201)) as { body: TamerBody };
    const position = body.battle.queue[0]!.position;
    const sphere = await prisma.item.findFirstOrThrow({
      where: { captureBonus: { not: null } },
    });
    const refused = await user
      .actRaw({
        position,
        action: {
          type: 'capture',
          item_id: sphere.id,
          target: body.battle.enemy.cells[0],
        },
      })
      .expect(400);
    expect(refused.body.message).toBe(TAMER_CREATURE);
    const next = await user.act(waitVez(body.battle));
    expect(next.battle.tamer).toEqual({ name_id: 2, source: 'map' });
  });

  it('Procurar num hexágono com Domador é recusado, e o selvagem fica', async () => {
    const user = await userWithStarter();
    placeWild(app, user.id, [{}], [{}]);
    const { body } = await user.wild().expect(409);
    expect(body.message).toBe(TAMER_WAITING);
    expect(exploration(user.id)!.spawns.size).toBe(1);
  });

  it('vencer o Domador do mapa mantém a exploração, e Procurar volta a valer', async () => {
    const user = await strongUser();
    placeWild(app, user.id, [{}], [{ team: [{ speciesId: RUVO, level: 1 }] }]);
    const first = (await user.tamer().expect(201)).body as TamerBody;
    const last = await playOut(user.act, first);
    expect(last.battle.result).toBe('victory');
    expect(last.events.map(({ type }) => type)).toContain('coins_gained');
    expect(exploration(user.id)).toBeDefined();
    await user.wild().expect(201);
  });

  it('perder para o Domador do mapa encerra a exploração', async () => {
    const user = await userWithStarter({ currentHp: 1 });
    placeWild(app, user.id, [{}], [{ team: [{ speciesId: RUVO, level: 50 }] }]);
    const first = (await user.tamer().expect(201)).body as TamerBody;
    const last = await playOut(user.act, first, waitVez);
    expect(last.battle.result).toBe('defeat');
    expect(exploration(user.id)).toBeUndefined();
    // Curada, a equipe passa da conferência de HP e chega à da exploração.
    await prisma.creatureInstance.updateMany({
      where: { playerId: user.id },
      data: { currentHp: 20 },
    });
    const { body } = await user.wild().expect(404);
    expect(body.message).toBe(NO_EXPLORATION);
  });

  it('o Desafiar abre uma luta sem exploração, sem tamer_id', async () => {
    const user = await userWithStarter();
    const { body } = (await user.challenge().expect(201)) as {
      body: TamerBody;
    };
    expect(body.tamer_id).toBeNull();
    expect(body.battle.can_flee).toBe(false);
    expect(body.battle.tamer?.source).toBe('challenge');
    expect(body.battle.tamer?.name_id).toEqual(expect.any(Number));
  });

  it('perder no Desafiar não mexe na exploração', async () => {
    const user = await userWithStarter({ currentHp: 1 });
    placeWild(app, user.id);
    const first = (await user.challenge().expect(201)).body as TamerBody;
    const last = await playOut(user.act, first, waitVez);
    expect(last.battle.result).toBe('defeat');
    expect(exploration(user.id)).toBeDefined();
  });

  describe('depuração', () => {
    it('põe um Domador do tamanho pedido no hexágono, substituindo o que havia', async () => {
      const user = await userWithStarter();
      placeWild(app, user.id, [], [{}]);
      const { body } = await user.debugTamer({ ...HERE, size: 2 }).expect(201);
      expect(Object.keys(body.tamer).sort()).toEqual(
        ['greeting_id', 'id', 'name_id', 'q', 'r'].sort(),
      );
      const tamers = [...exploration(user.id)!.tamers.values()];
      expect(tamers).toHaveLength(1);
      expect(tamers[0]).toMatchObject({ ...HERE, size: 2, debug: true });
      expect(tamers[0]!.team).toHaveLength(2);
    });

    it('tamanho fora de 1 a 3 dá 400, e sem exploração dá 404', async () => {
      const user = await userWithStarter();
      await user.debugTamer({ ...HERE, size: 2 }).expect(404);
      placeWild(app, user.id);
      await user.debugTamer({ ...HERE, size: 4 }).expect(400);
    });

    it('limpar o spawn tira também os Domadores da depuração', async () => {
      const user = await userWithStarter();
      placeWild(app, user.id, [], [{ q: 5, r: 5 }]);
      const added = (await user.debugTamer({ ...HERE, size: 1 }).expect(201))
        .body.tamer.id as number;
      const { body } = await user.debugClear().expect(200);
      expect(body.removed_tamer_ids).toEqual([added]);
      expect([...exploration(user.id)!.tamers.keys()]).toEqual([1]);
    });

    it('com ENABLE_TEST_BATTLE desligada, a rota não existe', async () => {
      const closed = await createTestApp({
        tokenVerifier: tokens.verifier,
        env: { ENABLE_TEST_BATTLE: false },
      });
      const id = randomUUID();
      await request(closed.getHttpServer())
        .post('/v1/me/exploration/tamers')
        .set({ Authorization: `Bearer ${await tokens.sign(id)}` })
        .send({ ...HERE, size: 1 })
        .expect(404);
      await closed.close();
    });
  });
});

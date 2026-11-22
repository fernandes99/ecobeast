import { INestApplication } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import request from 'supertest';
import type { App } from 'supertest/types.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { createTestApp } from './support/app.js';
import { createTestPrisma } from './support/db.js';
import { createTestTokens, TestTokens } from './support/tokens.js';

// A ferramenta Missões do F2 (auralis/07).

const RUVO = 1;

interface QuestRow {
  id: number;
  npc_id: number;
  position: number;
  quest_type_id: number;
  amount: number | null;
  species_id: number | null;
  place_name: string | null;
  tiles: { q: number; r: number }[];
  display_title: string;
}

interface ListBody {
  required_quests: number | null;
  types: { id: number; slug: string }[];
  quests: QuestRow[];
}

describe('O editor de missões (e2e)', () => {
  let app: INestApplication<App>;
  let prisma: PrismaClient;
  let tokens: TestTokens;
  let owner: string;
  let stranger: string;
  const editor = randomUUID();
  const islands: number[] = [];
  const npcs: number[] = [];

  const call = (
    method: 'get' | 'post' | 'put' | 'delete',
    path: string,
    token = owner,
  ) =>
    request(app.getHttpServer())
      [method](`/v1/editor${path}`)
      .set('Authorization', `Bearer ${token}`);

  async function npc(name: string): Promise<number> {
    const { id } = await prisma.npc.create({
      data: {
        slug: `zz_test_qedit_${randomUUID().slice(0, 8)}`,
        name,
        description: 'Teste.',
        sprite: 'ruvo',
      },
    });
    npcs.push(id);
    return id;
  }

  async function island(name: string): Promise<number> {
    const tiles = [];
    for (let q = -2; q <= 2; q++) {
      for (let r = -2; r <= 2; r++) {
        if (Math.abs(q + r) <= 2) {
          tiles.push({ q, r, biome: 'temperate', height: 1, variant: 1 });
        }
      }
    }
    const response = await call('post', '/islands')
      .send({ name, start: { q: 0, r: 0 }, tiles, actions: [], areas: [] })
      .expect(201);
    const id = (response.body as { id: number }).id;
    islands.push(id);
    return id;
  }

  beforeAll(async () => {
    prisma = createTestPrisma();
    tokens = await createTestTokens();
    app = await createTestApp({
      tokenVerifier: tokens.verifier,
      env: { MAP_EDITOR_USER_IDS: [editor] },
    });
    owner = await tokens.sign(editor);
    stranger = await tokens.sign(randomUUID());
  });

  afterAll(async () => {
    await prisma.island.deleteMany({ where: { id: { in: islands } } });
    await prisma.tamer.deleteMany({ where: { npcId: { in: npcs } } });
    await prisma.npc.deleteMany({ where: { id: { in: npcs } } });
    await prisma.$disconnect();
    await app.close();
  });

  it('cria, lista em ordem, sobe, troca o NPC e apaga', async () => {
    const id = await island('Editor de missões A');
    const giver = await npc('Vovó');
    const other = await npc('Téo');
    await call('get', `/islands/${id}/quests`, stranger).expect(403);

    const empty = (await call('get', `/islands/${id}/quests`).expect(200))
      .body as ListBody;
    expect(empty.required_quests).toBeNull();
    expect(empty.types.map(({ slug }) => slug)).toEqual([
      'capture_any',
      'defeat_any',
      'explore_percent',
      'reach_place',
      'talk_npc',
      'stay_minutes',
      'find_species',
      'defeat_species',
      'defeat_tamer',
      'find_item',
    ]);
    expect(empty.quests).toEqual([]);

    await call('post', `/islands/${id}/quests`)
      .send({
        npc_id: giver,
        quest_type_id: 1,
        amount: 3,
        species_id: RUVO,
        coins: 50,
      })
      .expect(201);
    const created = (
      await call('post', `/islands/${id}/quests`)
        .send({
          npc_id: giver,
          quest_type_id: 4,
          place_name: ' o Farol ',
          tiles: [
            { q: 1, r: 0 },
            { q: 1, r: 0 },
            { q: 2, r: -1 },
          ],
        })
        .expect(201)
    ).body as ListBody;
    expect(
      created.quests.map(({ position, display_title, species_id }) => ({
        position,
        display_title,
        species_id,
      })),
    ).toEqual([
      { position: 1, display_title: 'Capture 3 Ecobeasts', species_id: null },
      { position: 2, display_title: 'Vá até o Farol', species_id: null },
    ]);
    expect(created.quests[1]!.tiles).toEqual([
      { q: 1, r: 0 },
      { q: 2, r: -1 },
    ]);

    const farol = created.quests[1]!;
    const moved = (
      await call('post', `/quests/${farol.id}/move`)
        .send({ direction: 'up' })
        .expect(200)
    ).body as ListBody;
    expect(moved.quests.map(({ display_title }) => display_title)).toEqual([
      'Vá até o Farol',
      'Capture 3 Ecobeasts',
    ]);
    await call('post', `/quests/${farol.id}/move`)
      .send({ direction: 'up' })
      .expect(200);
    await call('post', `/quests/${farol.id}/move`)
      .send({ direction: 'left' })
      .expect(400);

    const changed = (
      await call('put', `/quests/${farol.id}`)
        .send({ npc_id: other, quest_type_id: 7, species_id: RUVO, amount: 2 })
        .expect(200)
    ).body as ListBody;
    const found = changed.quests.find(
      ({ id: questId }) => questId === farol.id,
    )!;
    expect(found).toMatchObject({
      npc_id: other,
      position: 1,
      place_name: null,
      tiles: [],
    });
    expect(found.display_title).toMatch(/^Encontre 2 /);

    const left = (await call('delete', `/quests/${farol.id}`).expect(200))
      .body as ListBody;
    expect(left.quests).toHaveLength(1);
    await call('delete', `/quests/${farol.id}`).expect(404);

    const required = (
      await call('put', `/islands/${id}/required-quests`)
        .send({ required_quests: 1 })
        .expect(200)
    ).body as ListBody;
    expect(required.required_quests).toBe(1);
    await call('put', `/islands/${id}/required-quests`)
      .send({ required_quests: 0 })
      .expect(400);
  }, 60_000);

  it('recusa o que falta ou não existe', async () => {
    const id = await island('Editor de missões B');
    const giver = await npc('Lia');
    const notTamer = await npc('Rui');
    const post = (body: object) =>
      call('post', `/islands/${id}/quests`).send({ npc_id: giver, ...body });
    const messageOf = async (body: object) =>
      ((await post(body).expect(400)).body as { message: string }).message;

    expect(await messageOf({ quest_type_id: 2 })).toBe(
      'A quantidade vai de 1 a 9999.',
    );
    expect(await messageOf({ quest_type_id: 3, amount: 120 })).toBe(
      'A porcentagem vai de 1 a 100.',
    );
    expect(
      await messageOf({
        quest_type_id: 4,
        place_name: 'Longe',
        tiles: [{ q: 30, r: 30 }],
      }),
    ).toBe('Um hexágono do lugar está fora da ilha.');
    expect(await messageOf({ quest_type_id: 9, target_npc_id: notTamer })).toBe(
      'Esse NPC não é um Domador desta ilha.',
    );
    expect(
      await messageOf({ quest_type_id: 7, species_id: 2_000_000_000 }),
    ).toBe('Essa espécie não existe.');
    expect(
      await messageOf({ quest_type_id: 1, amount: 1, item_id: 2_000_000_000 }),
    ).toBe('Esse item não existe.');
    expect(
      await messageOf({ quest_type_id: 10, target_item_id: 2_000_000_000 }),
    ).toBe('Esse item não existe.');
    expect(
      (
        (
          await call('post', `/islands/${id}/quests`)
            .send({ npc_id: 2_000_000_000, quest_type_id: 1, amount: 1 })
            .expect(400)
        ).body as { message: string }
      ).message,
    ).toBe('Escolha o NPC que dá a missão.');

    await prisma.tamer.create({
      data: {
        npcId: notTamer,
        islandId: id,
        creatures: { create: [{ position: 1, speciesId: RUVO, level: 2 }] },
      },
    });
    await post({ quest_type_id: 9, target_npc_id: notTamer }).expect(201);
    await call('get', '/islands/2000000000/quests').expect(404);
  }, 60_000);

  it('grava, relê e troca as conversas e a cena do início (auralis/10)', async () => {
    const id = await island('Editor de missões C');
    const giver = await npc('Bia');
    const dialogues = {
      offer: [
        { type: 'say', speaker: 'npc', text: 'Pode me ajudar?' },
        {
          type: 'choice',
          options: [
            { text: 'Claro', outcome: 'accept', steps: [] },
            {
              text: 'Agora não',
              outcome: 'decline',
              steps: [{ type: 'say', speaker: 'npc', text: 'Tudo bem.' }],
            },
          ],
        },
      ],
      ongoing: [
        { type: 'say', speaker: 'npc', text: 'Encontrou o que eu precisava?' },
        {
          type: 'choice',
          options: [
            {
              text: 'Sim',
              outcome: null,
              steps: [
                { type: 'say', speaker: 'npc', text: 'Não é isso.' },
                { type: 'say', speaker: 'tamer', text: 'Hum.' },
              ],
            },
            { text: 'Ainda não', outcome: null, steps: [] },
          ],
        },
      ],
      done: [{ type: 'say', speaker: 'narration', text: 'Ele sorri.' }],
    };
    const created = (
      await call('post', `/islands/${id}/quests`)
        .send({ npc_id: giver, quest_type_id: 1, amount: 2, dialogues })
        .expect(201)
    ).body as {
      quests: (QuestRow & { dialogues: unknown; offer_scene: string | null })[];
    };
    expect(created.quests[0].dialogues).toEqual(dialogues);
    expect(created.quests[0].offer_scene).toBeNull();

    const questId = created.quests[0].id;
    const saved = (
      await call('put', `/quests/${questId}`)
        .send({
          npc_id: giver,
          quest_type_id: 1,
          amount: 2,
          offer_scene: 'bia_pede_ajuda',
          dialogues: { ongoing: dialogues.ongoing.slice(0, 1) },
        })
        .expect(200)
    ).body as { quests: { dialogues: unknown; offer_scene: string | null }[] };
    expect(saved.quests[0].dialogues).toEqual({
      offer: [],
      ongoing: dialogues.ongoing.slice(0, 1),
      done: [],
    });
    expect(saved.quests[0].offer_scene).toBe('bia_pede_ajuda');
    expect(await prisma.questDialogueStep.count({ where: { questId } })).toBe(
      1,
    );

    const messageOf = async (body: object) =>
      (
        (
          await call('put', `/quests/${questId}`)
            .send({ npc_id: giver, quest_type_id: 1, amount: 2, ...body })
            .expect(400)
        ).body as { message: string }
      ).message;
    expect(
      await messageOf({
        dialogues: {
          done: [
            {
              type: 'choice',
              options: [
                { text: 'a', outcome: 'accept', steps: [] },
                { text: 'b', steps: [] },
              ],
            },
          ],
        },
      }),
    ).toBe('Só a conversa de início aceita ou recusa a missão.');
    expect(await messageOf({ offer_scene: 'Cena Ruim' })).toBe(
      'A cena do início é inválida.',
    );
  }, 60_000);
});

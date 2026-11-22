import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { CATALOG_TABLES, SEED_DATA_DIR } from './catalog-tables.js';

describe('CATALOG_TABLES', () => {
  const names = CATALOG_TABLES.map((table) => table.name);

  it('tem as 54 tabelas, sem repetição', () => {
    expect(names).toHaveLength(54);
    expect(new Set(names).size).toBe(54);
  });

  it('casa com os arquivos .json da pasta de dados do seed', () => {
    const files = readdirSync(SEED_DATA_DIR)
      .filter((file) => file.endsWith('.json'))
      .map((file) => file.replace(/\.json$/, ''));
    expect([...names].sort()).toEqual(files.sort());
  });

  it('começa pelas referências e termina nos iniciais (ordem de dependência)', () => {
    expect(names[0]).toBe('elements');
    expect(names.indexOf('species')).toBeLessThan(
      names.indexOf('species_elements'),
    );
    expect(names.indexOf('skills')).toBeLessThan(
      names.indexOf('species_skills'),
    );
    expect(names.indexOf('item_categories')).toBeLessThan(
      names.indexOf('items'),
    );
    expect(names.indexOf('biomes')).toBeLessThan(
      names.indexOf('species_biomes'),
    );
    expect(names.indexOf('species')).toBeLessThan(
      names.indexOf('species_biomes'),
    );
    expect(names.indexOf('biome_zones')).toBeLessThan(
      names.indexOf('species_biome_zones'),
    );
    expect(names.indexOf('day_phases')).toBeLessThan(
      names.indexOf('species_day_phases'),
    );
    expect(names.indexOf('species')).toBeLessThan(
      names.indexOf('species_day_phases'),
    );
    expect(names.indexOf('area_shapes')).toBeLessThan(names.indexOf('skills'));
    expect(names.indexOf('status_conditions')).toBeLessThan(
      names.indexOf('ground_effects'),
    );
    expect(names.indexOf('ground_effects')).toBeLessThan(
      names.indexOf('skills'),
    );
    expect(names.indexOf('ground_effects')).toBeLessThan(
      names.indexOf('ground_effect_stats'),
    );
    expect(names.indexOf('voices')).toBeLessThan(names.indexOf('npcs'));
    expect(names.indexOf('items')).toBeLessThan(names.indexOf('tamer_levels'));
    expect(names.indexOf('prop_categories')).toBeLessThan(
      names.indexOf('prop_types'),
    );
    expect(names.at(-1)).toBe('starter_options');
  });

  it('guarda o delegate do Prisma e a chave em snake_case', () => {
    const efficacy = CATALOG_TABLES.find(
      (table) => table.name === 'element_efficacy',
    );
    expect(efficacy).toEqual({
      name: 'element_efficacy',
      model: 'elementEfficacy',
      key: ['attacker_element_id', 'defender_element_id'],
    });
  });
});

describe('carga inicial dos biomas (biome-encounters/01)', () => {
  const read = <T>(name: string) =>
    JSON.parse(
      readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
    ) as T[];
  const biomes = read<{ id: number; slug: string }>('biomes');
  const rates = read<{ species_id: number; biome_id: number; rate: number }>(
    'species_biomes',
  );
  const biomeId = (slug: string) => biomes.find((b) => b.slug === slug)!.id;
  const SEEDLET = 7;

  it('tem os 10 biomas de encontro', () => {
    expect(biomes.map(({ slug }) => slug).sort()).toEqual(
      [
        'beach',
        'boreal',
        'desert',
        'snow',
        'hill',
        'mountain',
        'stone',
        'temperate',
        'wdeep',
        'wshallow',
      ].sort(),
    );
  });

  it('não grava taxa 0: sem linha, a espécie não nasce no bioma', () => {
    expect(rates.every(({ rate }) => rate >= 1 && rate <= 100)).toBe(true);
  });

  it('dá taxas aos 9 Ecobeasts, sem pares repetidos', () => {
    const species = new Set(rates.map(({ species_id }) => species_id));
    expect([...species].sort((a, b) => a - b)).toEqual([
      1, 2, 3, 4, 5, 6, 7, 8, 9,
    ]);
    const pairs = rates.map((row) => `${row.species_id}|${row.biome_id}`);
    expect(new Set(pairs).size).toBe(pairs.length);
  });

  it('o Seedlet é bem mais comum no boreal que na montanha, e não está na água', () => {
    const rate = (slug: string) =>
      rates.find(
        (row) => row.species_id === SEEDLET && row.biome_id === biomeId(slug),
      )?.rate;
    expect(rate('boreal')).toBeGreaterThan(rate('mountain')! * 10);
    expect(rate('wshallow')).toBeUndefined();
    expect(rate('wdeep')).toBeUndefined();
  });
});

describe('carga inicial das Técnicas no tabuleiro (board-battle/01)', () => {
  const read = <T>(name: string) =>
    JSON.parse(
      readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
    ) as T[];
  interface SkillRow {
    slug: string;
    area_shape_id: number;
    range: number;
    pierces: boolean;
    ground_effect_id: number | null;
    ground_turns: number | null;
  }
  const shapes = read<{ id: number; slug: string }>('area_shapes');
  const grounds = read<{
    id: number;
    slug: string;
    damage_percent: number | null;
    status_condition_id: number | null;
  }>('ground_effects');
  const skills = read<SkillRow>('skills');
  const shapeId = (slug: string) => shapes.find((s) => s.slug === slug)!.id;
  const FIRE = grounds.find((g) => g.slug === 'fire')!;
  const SPECIAL = ['faisca_rapida', 'chama_espiral'];

  const board = (row: SkillRow) => ({
    area_shape_id: row.area_shape_id,
    range: row.range,
    pierces: row.pierces,
    ground_effect_id: row.ground_effect_id,
    ground_turns: row.ground_turns,
  });
  const skill = (slug: string) => skills.find((row) => row.slug === slug)!;

  it('tem as formas single, line e triangle (board-battle/33), e o chão em chamas', () => {
    expect(shapes.map(({ slug }) => slug)).toEqual([
      'single',
      'line',
      'triangle',
    ]);
    expect(FIRE).toMatchObject({
      damage_percent: 6,
      status_condition_id: null,
    });
  });

  it('deixa as outras 36 Técnicas no corpo a corpo, com alcance 1', () => {
    const others = skills.filter((row) => !SPECIAL.includes(row.slug));
    expect(others).toHaveLength(36);
    for (const row of others) {
      expect(board(row), row.slug).toEqual({
        area_shape_id: shapeId('single'),
        range: 1,
        pierces: false,
        ground_effect_id: null,
        ground_turns: null,
      });
    }
  });

  it('Faísca Rápida anda em linha reta por 3, sem atravessar', () => {
    expect(board(skill('faisca_rapida'))).toEqual({
      area_shape_id: shapeId('line'),
      range: 3,
      pierces: false,
      ground_effect_id: null,
      ground_turns: null,
    });
  });

  it('Chama Espiral acerta um triângulo a até 3 e deixa o chão em chamas por 6 vezes', () => {
    expect(board(skill('chama_espiral'))).toEqual({
      area_shape_id: shapeId('triangle'),
      range: 3,
      pierces: false,
      ground_effect_id: FIRE.id,
      ground_turns: 6,
    });
  });
});

describe('CATALOG_TABLES e o cliente do Prisma', () => {
  it('cada model é um delegate do cliente (nome do modelo, no singular)', async () => {
    const { PrismaClient } = await import('../generated/prisma/client.js');
    const { PrismaPg } = await import('@prisma/adapter-pg');
    // Não conecta: só cria o cliente para ver os delegates.
    const client = new PrismaClient({
      adapter: new PrismaPg({
        connectionString: 'postgresql://x@localhost:1/x',
      }),
    });
    const missing = CATALOG_TABLES.filter(
      (table) =>
        typeof (client as unknown as Record<string, { findMany?: unknown }>)[
          table.model
        ]?.findMany !== 'function',
    ).map((table) => `${table.name} → ${table.model}`);
    expect(missing).toEqual([]);
  });
});

describe('carga inicial dos nomes e falas dos Domadores (npc-tamers/01)', () => {
  const read = <T>(name: string) =>
    JSON.parse(
      readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
    ) as T[];
  const names = read<{ id: number; name: string }>('npc_tamer_names');
  const greetings = read<{ id: number; text: string }>('npc_tamer_greetings');

  it('tem 12 nomes, de 1 a 20 caracteres, começando por Lia', () => {
    expect(names).toHaveLength(12);
    expect(names[0]).toEqual({ id: 1, name: 'Lia' });
    expect(
      names.every(({ name }) => name.length >= 1 && name.length <= 20),
    ).toBe(true);
  });

  it('tem as 3 falas, de 1 a 120 caracteres, sem o nome na frente', () => {
    expect(greetings.map(({ id }) => id)).toEqual([1, 2, 3]);
    expect(greetings[0]!.text).toBe(
      'O que está fazendo aqui? Vamos nos enfrentar!',
    );
    expect(
      greetings.every(({ text }) => text.length >= 1 && text.length <= 120),
    ).toBe(true);
  });
});

describe('carga inicial dos tipos de ação (island-villages/01)', () => {
  const types = JSON.parse(
    readFileSync(join(SEED_DATA_DIR, 'action_types.json'), 'utf8'),
  ) as {
    id: number;
    slug: string;
    name: string;
    color_hex: string;
    kind: string;
  }[];

  it('todos abrem uma tela', () => {
    expect(types.every(({ kind }) => kind === 'open_screen')).toBe(true);
  });

  it('tem Refúgio, Loja, Arena, Casa e Viagem, nessa ordem', () => {
    expect(types.map(({ slug, name }) => [slug, name])).toEqual([
      ['refuge', 'Refúgio'],
      ['shop', 'Loja'],
      ['arena', 'Arena'],
      ['house', 'Casa'],
      ['travel', 'Viagem'],
    ]);
  });

  it('cada um tem uma cor #RRGGBB', () => {
    for (const { color_hex } of types) {
      expect(color_hex).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });
});

describe('carga inicial dos tipos de parede (free-fences/01)', () => {
  const walls = JSON.parse(
    readFileSync(join(SEED_DATA_DIR, 'wall_types.json'), 'utf8'),
  ) as { id: number; slug: string; name: string; visible: boolean }[];

  it('tem a cerca de madeira, o muro de pedra, a parede invisível e a cerca de estacas, com ids estáveis', () => {
    expect(walls.map(({ id, slug, visible }) => [id, slug, visible])).toEqual([
      [1, 'wood_fence', true],
      [2, 'stone_fence', true],
      [3, 'invisible_wall', false],
      [4, 'picket_fence', true],
    ]);
  });
});

describe('carga inicial dos estilos de ponte (bridges/01)', () => {
  const bridges = JSON.parse(
    readFileSync(join(SEED_DATA_DIR, 'bridge_types.json'), 'utf8'),
  ) as { id: number; slug: string; name: string }[];

  it('tem a ponte de corda e a de madeira, com ids estáveis', () => {
    expect(bridges.map(({ id, slug }) => [id, slug])).toEqual([
      [4, 'rope_bridge'],
      [5, 'wood_bridge'],
    ]);
  });
});

describe('carga inicial do chão (island-villages/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const grounds =
    read<{ slug: string; kind: string; hardness: number }[]>(
      'ground_types.json',
    );

  it('tem 21 trilhas e 9 pisos, cada um com a dureza (free-trails/01 e ground-variety/01 a 03)', () => {
    expect(grounds.map(({ kind }) => kind)).toEqual([
      'trail',
      'trail',
      'floor',
      'floor',
      'trail',
      'trail',
      'trail',
      'trail',
      'floor',
      'floor',
      'floor',
      'floor',
      'trail',
      'floor',
      'trail',
      'floor',
      'floor',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
      'trail',
    ]);
    for (const { hardness } of grounds) {
      expect(hardness).toBeGreaterThanOrEqual(1);
      expect(hardness).toBeLessThanOrEqual(3);
    }
  });
});

describe('carga inicial das peças soltas (free-props/01, free-objects/04, vegetation-packs/01, nature-variety/02, home-pack/01 e 03, coast-rivers/01, timber-house/01, stone-cottage/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const props =
    read<{ id: number; slug: string; variants: number }[]>('prop_types.json');
  const blocks = read<
    {
      prop_type_id: number;
      variant: number;
      position: number;
      closed: boolean;
      points: number[];
    }[]
  >('prop_type_blocks.json');

  const removed = [18, 19, 23, 24, 25, 26, 27];
  const between = (first: number, last: number) =>
    props.filter(({ id }) => id >= first && id <= last);

  it('tem os tipos de 1 a 100, menos os 7 que saíram (prop-cleanup/01), com pelo menos 1 variante', () => {
    expect(props.map(({ id }) => id)).toEqual(
      Array.from({ length: 100 }, (_, index) => index + 1).filter(
        (id) => !removed.includes(id),
      ),
    );
    for (const { variants } of props)
      expect(variants).toBeGreaterThanOrEqual(1);
  });

  it('das decorações de rua e dos prédios da cidade, ficam o canteiro, o banco e o Refúgio (prop-cleanup/01)', () => {
    expect(between(18, 27).map(({ slug }) => slug)).toEqual([
      'flower_bed',
      'bench',
      'refuge_building',
    ]);
  });

  it('os pacotes têm 12 árvores, 13 arbustos e 8 pedras de 5 tamanhos', () => {
    const packs = between(28, 60);
    expect(packs.map(({ slug }) => slug).slice(0, 2)).toEqual([
      'leafy_tree',
      'moss_tree',
    ]);
    expect(packs).toHaveLength(33);
    expect(packs.slice(25).every(({ variants }) => variants === 5)).toBe(true);
  });

  it('as decorações do Deserto, da Neve e da nature-variety são peças de 4 variantes', () => {
    const nature = between(61, 90);
    expect(nature.map(({ slug }) => slug).slice(0, 7)).toEqual([
      'cactus',
      'sand_rock',
      'snow_pine',
      'snow_rock',
      'snow_bush',
      'snow_tuft',
      'birch',
    ]);
    expect(nature.at(-1)?.slug).toBe('snow_log');
    expect(nature.every(({ variants }) => variants === 4)).toBe(true);
  });

  it('as decorações da Praia são as peças 91 a 94', () => {
    expect(between(91, 94).map(({ slug }) => slug)).toEqual([
      'shells',
      'starfish',
      'driftwood',
      'beach_rock',
    ]);
  });

  it('as casas do pacote Main Characters Home são as peças 95 a 97, em 8 cores (home-pack/01 e 03)', () => {
    expect(
      between(95, 97).map(({ id, slug, variants }) => [id, slug, variants]),
    ).toEqual([
      [95, 'big_house', 8],
      [96, 'small_house', 8],
      [97, 'small_townhouse', 8],
    ]);
  });

  it("a casa enxaimel do pacote Glassblower's Workshop é a peça 98, em 8 cores (timber-house/01)", () => {
    expect(props.find(({ id }) => id === 98)).toEqual({
      id: 98,
      slug: 'timber_house',
      name: 'Casa enxaimel',
      variants: 8,
      prop_category_id: 1,
    });
  });

  it('a casinha de pedra da imagem do dono é a peça 99, em 8 cores (stone-cottage/01)', () => {
    expect(props.find(({ id }) => id === 99)).toEqual({
      id: 99,
      slug: 'stone_cottage',
      name: 'Casinha de pedra',
      variants: 8,
      prop_category_id: 1,
    });
  });

  it('a casinha enxaimel da imagem do dono é a peça 100, em 8 cores (timber-cottage/01)', () => {
    expect(props.find(({ id }) => id === 100)).toEqual({
      id: 100,
      slug: 'timber_cottage',
      name: 'Casinha enxaimel',
      variants: 8,
      prop_category_id: 1,
    });
  });

  it('os prédios bloqueiam em todas as variantes, e as pedras e árvores grandes dos pacotes nas variantes 1 e 2', () => {
    const all = blocks.filter(({ variant }) => variant === 0);
    expect(all.map(({ prop_type_id }) => prop_type_id)).toEqual([
      22, 95, 96, 97, 98, 99, 100,
    ]);
    const packs = blocks.filter(({ variant }) => variant > 0);
    const large = [
      ...Array.from({ length: 11 }, (_, index) => 28 + index),
      ...Array.from({ length: 8 }, (_, index) => 53 + index),
    ];
    expect(
      packs.map(({ prop_type_id, variant }) => `${prop_type_id}:${variant}`),
    ).toEqual(large.flatMap((id) => [`${id}:1`, `${id}:2`]));
    for (const { closed, points } of blocks) {
      expect(closed).toBe(true);
      expect(points.length % 2).toBe(0);
      expect(points.length).toBeGreaterThanOrEqual(6);
    }
  });
});

describe('carga inicial dos NPCs (island-npcs/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const npcs = read<
    {
      id: number;
      slug: string;
      sprite: string | null;
      body_type_id: number | null;
      skin_palette_id: number | null;
    }[]
  >('npcs.json');
  // As folhas de explorar do jogo: o species.json só tem a carga inicial.
  const sheets = (sprite: string) =>
    existsSync(
      join(
        SEED_DATA_DIR,
        '../../../client/assets/creatures',
        sprite,
        'explore/idle.png',
      ),
    );
  const parts = read<{ npc_id: number; appearance_slot_id: number }[]>(
    'npc_appearance_parts.json',
  );

  it('tem os NPCs de Ecobeast e as 3 pessoas da introdução (liora-intro/02 e 04)', () => {
    expect(npcs.map(({ id, slug }) => [id, slug])).toEqual([
      [1, 'village_ruvo'],
      [2, 'guard_ruvak'],
      [3, 'grandpa'],
      [4, 'mira'],
      [5, 'refuge_keeper'],
      [6, 'liora_puffcoo'],
      [7, 'villager_tome'],
      [8, 'villager_baltazar'],
      [9, 'villager_caio'],
      [10, 'villager_severino'],
      [11, 'villager_joaquim'],
      [12, 'villager_lucia'],
      [13, 'villager_benedita'],
      [14, 'villager_clara'],
      [15, 'villager_rosa'],
      [16, 'villager_dalia'],
    ]);
  });

  it('os moradores têm pele de pele, cores do tipo do lugar e a fala padrão (village-crowd/01)', () => {
    const palettes = read<{ id: number; kind: string }[]>('palettes.json');
    const slots = read<{ id: number; palette_kind: string | null }[]>(
      'appearance_slots.json',
    );
    const kind = (id: number | null) =>
      palettes.find((palette) => palette.id === id)?.kind ?? null;
    const villagers = read<
      { id: number; skin_palette_id: number; default_dialogue: string }[]
    >('npcs.json').filter(({ id }) => id >= 7 && id <= 16);
    expect(villagers).toHaveLength(10);
    for (const villager of villagers) {
      expect(kind(villager.skin_palette_id), String(villager.id)).toBe('skin');
      expect(villager.default_dialogue.length).toBeGreaterThan(0);
      expect(villager.default_dialogue.length).toBeLessThanOrEqual(2000);
    }
    for (const part of read<
      {
        npc_id: number;
        appearance_slot_id: number;
        palette_id: number | null;
      }[]
    >('npc_appearance_parts.json')) {
      const slot = slots.find(({ id }) => id === part.appearance_slot_id)!;
      expect(kind(part.palette_id), `${part.npc_id}/${slot.id}`).toBe(
        slot.palette_kind,
      );
    }
  });

  it('cada NPC tem o sprite de um Ecobeast ou o corpo e a pele, nunca os dois', () => {
    for (const npc of npcs) {
      if (npc.sprite === null) {
        expect(npc.body_type_id).not.toBeNull();
        expect(npc.skin_palette_id).not.toBeNull();
      } else {
        expect(sheets(npc.sprite)).toBe(true);
        expect(npc.body_type_id).toBeNull();
        expect(npc.skin_palette_id).toBeNull();
      }
    }
  });

  it('as peças são só dos NPCs pessoas, uma por lugar, com o rosto', () => {
    const people = npcs.filter(({ sprite }) => sprite === null);
    for (const { npc_id } of parts) {
      expect(people.some(({ id }) => id === npc_id)).toBe(true);
    }
    for (const { id } of people) {
      const slots = parts
        .filter(({ npc_id }) => npc_id === id)
        .map(({ appearance_slot_id }) => appearance_slot_id);
      expect(new Set(slots).size).toBe(slots.length);
      expect(slots).toContain(1);
    }
  });
});

describe('carga inicial das vozes (dialogue-voices/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const voices = read<
    {
      id: number;
      slug: string;
      chars_per_second: number;
      letters_per_blip: number;
      pitch_variation: number;
    }[]
  >('voices.json');
  const npcs = read<{ slug: string; voice_id: number }[]>('npcs.json');

  it('tem as 6 vozes com ids estáveis, dentro dos limites', () => {
    expect(voices.map(({ id, slug }) => [id, slug])).toEqual([
      [1, 'narration'],
      [2, 'tamer'],
      [3, 'low'],
      [4, 'medium'],
      [5, 'high'],
      [6, 'chirp'],
    ]);
    for (const voice of voices) {
      expect(voice.chars_per_second).toBeGreaterThanOrEqual(20);
      expect(voice.chars_per_second).toBeLessThanOrEqual(90);
      expect(voice.letters_per_blip).toBeGreaterThanOrEqual(1);
      expect(voice.letters_per_blip).toBeLessThanOrEqual(4);
      expect(voice.pitch_variation).toBeGreaterThanOrEqual(0);
      expect(voice.pitch_variation).toBeLessThanOrEqual(25);
    }
  });

  it('cada NPC tem a voz da spec', () => {
    expect(
      Object.fromEntries(npcs.map(({ slug, voice_id }) => [slug, voice_id])),
    ).toEqual({
      village_ruvo: 6,
      guard_ruvak: 6,
      grandpa: 3,
      mira: 5,
      refuge_keeper: 4,
      liora_puffcoo: 6,
      villager_tome: 4,
      villager_baltazar: 3,
      villager_caio: 4,
      villager_severino: 3,
      villager_joaquim: 4,
      villager_lucia: 5,
      villager_benedita: 4,
      villager_clara: 5,
      villager_rosa: 4,
      villager_dalia: 5,
    });
  });

  it('cada voz tem o som no jogo', () => {
    for (const { slug } of voices) {
      expect(
        existsSync(
          join(
            SEED_DATA_DIR,
            '../../../client/assets/sounds/voices',
            `${slug}.wav`,
          ),
        ),
        slug,
      ).toBe(true);
    }
  });
});

describe('carga inicial da aparência (tamer-appearance/01)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const bodies = read<{ id: number; slug: string }[]>('body_types.json');
  const slots = read<{ id: number; slug: string; layer: number }[]>(
    'appearance_slots.json',
  );
  const palettes = read<Record<string, string | number>[]>('palettes.json');
  const parts = read<{ id: number; appearance_slot_id: number }[]>(
    'appearance_parts.json',
  );

  it('tem os 2 corpos e os 6 lugares na ordem de desenho, com ids estáveis', () => {
    expect(bodies.map(({ id, slug }) => [id, slug])).toEqual([
      [1, 'male'],
      [2, 'female'],
    ]);
    expect(slots.map(({ id, slug, layer }) => [id, slug, layer])).toEqual([
      [1, 'face', 1],
      [2, 'bottom', 2],
      [3, 'shoes', 3],
      [4, 'top', 4],
      [5, 'hair', 5],
      [6, 'headwear', 6],
    ]);
  });

  it('a aparência padrão existe: a pele 1 e o rosto 1', () => {
    expect(palettes[0]).toMatchObject({ id: 1, kind: 'skin' });
    expect(parts[0]).toEqual(
      expect.objectContaining({ id: 1, appearance_slot_id: 1 }),
    );
  });

  it('cada paleta tem 4 cores #rrggbb', () => {
    for (const palette of palettes) {
      for (const shade of [1, 2, 3, 4]) {
        expect(palette[`color${shade}_hex`]).toMatch(/^#[0-9a-f]{6}$/);
      }
    }
  });
});

describe('carga inicial do guarda-roupa (tamer-appearance/04)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const parts = read<
    {
      slug: string;
      appearance_slot_id: number;
      body_type_id: number | null;
      hair_cut: string;
    }[]
  >('appearance_parts.json');
  const palettes = read<{ kind: string }[]>('palettes.json');

  it('tem as 17 peças, só a saia presa a um corpo e só os chapéus escondendo cabelo', () => {
    expect(parts).toHaveLength(17);
    expect(parts.filter(({ body_type_id }) => body_type_id !== null)).toEqual([
      expect.objectContaining({ slug: 'skirt', body_type_id: 2 }),
    ]);
    for (const { appearance_slot_id, hair_cut } of parts) {
      if (appearance_slot_id !== 6) expect(hair_cut).toBe('none');
    }
  });

  it('tem 6 peles, 8 cores de cabelo e 10 de roupa', () => {
    const count = (kind: string) =>
      palettes.filter((palette) => palette.kind === kind).length;
    expect([count('skin'), count('hair'), count('cloth')]).toEqual([6, 8, 10]);
  });
});

describe('carga inicial do dia e da noite (day-night/01 e 03)', () => {
  const read = <T>(file: string): T =>
    JSON.parse(readFileSync(join(SEED_DATA_DIR, file), 'utf8')) as T;
  const phases =
    read<{ id: number; slug: string; start_minute: number }[]>(
      'day_phases.json',
    );
  const props = read<{ id: number; variants: number }[]>('prop_types.json');
  const lights = read<
    {
      prop_type_id: number;
      variant: number;
      position: number;
      radius: number;
      color: string;
    }[]
  >('prop_type_lights.json');

  it('todo Ecobeast nasce em alguma parte do dia (day-phase-spawns/01 e browt-line/01)', () => {
    const species = read<{ id: number }[]>('species.json');
    const born = read<{ species_id: number; day_phase_id: number }[]>(
      'species_day_phases.json',
    );
    const phaseIds = new Set(phases.map(({ id }) => id));
    const keys = born.map((row) => `${row.species_id}|${row.day_phase_id}`);
    expect(new Set(keys).size).toBe(keys.length);
    for (const { day_phase_id } of born) {
      expect(phaseIds.has(day_phase_id)).toBe(true);
    }
    for (const { id } of species) {
      expect(born.some(({ species_id }) => species_id === id)).toBe(true);
    }
  });

  it('tem as 4 partes do dia, dentro do dia', () => {
    expect(phases.map(({ slug }) => slug)).toEqual([
      'morning',
      'afternoon',
      'dusk',
      'night',
    ]);
    for (const { start_minute } of phases) {
      expect(start_minute).toBeGreaterThanOrEqual(0);
      expect(start_minute).toBeLessThan(1440);
    }
  });

  it('as luzes apontam para tipos e variantes que existem', () => {
    const variants = new Map(props.map(({ id, variants }) => [id, variants]));
    for (const light of lights) {
      expect(variants.has(light.prop_type_id)).toBe(true);
      expect(light.variant).toBeLessThanOrEqual(
        variants.get(light.prop_type_id)!,
      );
      expect(light.radius).toBeGreaterThanOrEqual(2);
      expect(light.radius).toBeLessThanOrEqual(96);
      expect(light.color).toMatch(/^[0-9a-f]{6}$/);
    }
  });

  it('as casas do pacote acendem em todas as cores', () => {
    const of = (type: number) => lights.filter((l) => l.prop_type_id === type);
    for (const type of [22, 95, 96, 97, 98, 100])
      expect(new Set(of(type).map(({ variant }) => variant))).toEqual(
        new Set([0]),
      );
  });

  it('o prédio do Refúgio tem 8 cores, 4 janelas e 2 lanternas (refuge-art/01)', () => {
    expect(props.find(({ id }) => id === 22)?.variants).toBe(8);
    const refuge = lights.filter(({ prop_type_id }) => prop_type_id === 22);
    expect(refuge.map(({ position }) => position)).toEqual([0, 1, 2, 3, 4, 5]);
    expect(refuge.filter(({ color }) => color === 'ffd890')).toHaveLength(2);
  });
});

describe('carga inicial das zonas (biome-zones/01)', () => {
  const read = <T>(name: string) =>
    JSON.parse(
      readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
    ) as T[];
  const biomes = read<{ id: number; slug: string }>('biomes');
  const zones = read<{ id: number; slug: string; biome_id: number }>(
    'biome_zones',
  );
  const exceptions = read<{ biome_zone_id: number; rate_percent: number }>(
    'species_biome_zones',
  );

  it('tem a Comum de cada bioma, com o id e o slug dele', () => {
    for (const biome of biomes) {
      expect(zones.find((zone) => zone.id === biome.id)).toMatchObject({
        slug: biome.slug,
        biome_id: biome.id,
      });
    }
  });

  it('tem as 13 zonas novas, cada uma de um bioma que existe', () => {
    const others = zones.filter(({ id }) => id > biomes.length);
    expect(others).toHaveLength(13);
    for (const zone of others) {
      expect(biomes.some(({ id }) => id === zone.biome_id)).toBe(true);
      expect(
        zone.slug.startsWith(
          `${biomes.find(({ id }) => id === zone.biome_id)!.slug}_`,
        ),
      ).toBe(true);
    }
  });

  it('as exceções apontam para zonas que existem', () => {
    for (const { biome_zone_id } of exceptions) {
      expect(zones.some(({ id }) => id === biome_zone_id)).toBe(true);
    }
  });
});

describe('carga inicial do nível do Domador (tamer-level/01)', () => {
  const read = <T>(name: string) =>
    JSON.parse(
      readFileSync(join(SEED_DATA_DIR, `${name}.json`), 'utf8'),
    ) as T[];
  const levels = read<{
    level: number;
    xp_total: number;
    reward_coins: number;
    reward_item_id: number | null;
    reward_item_quantity: number | null;
  }>('tamer_levels');
  const sources = read<{ id: number; slug: string; amount: number }>(
    'tamer_xp_sources',
  );

  it('vai do 1 ao 99, sem buraco, começando do 0 e sempre crescendo', () => {
    expect(levels.map(({ level }) => level)).toEqual(
      Array.from({ length: 99 }, (_, index) => index + 1),
    );
    expect(levels[0]).toMatchObject({ xp_total: 0, reward_coins: 0 });
    for (let index = 1; index < levels.length; index++) {
      expect(levels[index]!.xp_total).toBeGreaterThan(
        levels[index - 1]!.xp_total,
      );
    }
  });

  it('o item da recompensa vem sempre com a quantidade', () => {
    for (const row of levels) {
      expect(row.reward_item_id === null).toBe(
        row.reward_item_quantity === null,
      );
    }
  });

  it('tem as 8 fontes com ids estáveis', () => {
    expect(sources.map(({ id, slug }) => [id, slug])).toEqual([
      [1, 'battle_xp_percent'],
      [2, 'new_species'],
      [3, 'tamer_win'],
      [4, 'island_tamer_win'],
      [5, 'island_tamer_rematch'],
      [6, 'quest'],
      [7, 'arena'],
      [8, 'island_unlocked'],
    ]);
  });
});

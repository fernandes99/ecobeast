import {
  canonicalDraft,
  draftError,
  draftHash,
  type IslandDraft,
  type KnownIds,
  MAX_ISLAND_TILES,
  MAX_PROPS,
  publishError,
} from './island-draft.js';

const REFUGE = 1;
const HOUSE = 1;
const RUVO = 1;
const NILU = 4;
const FLOWERS = 6;
const BENCH = 21;
const known: KnownIds = {
  actionTypeIds: new Set([REFUGE, 2]),
  objectTypeIds: new Set([HOUSE, 2]),
  groundSlugs: new Set(['dirt_trail', 'cobble_floor']),
  speciesIds: new Set([RUVO, NILU]),
  propVariants: new Map([
    [FLOWERS, 4],
    [BENCH, 2],
  ]),
};

function island(): IslandDraft {
  return {
    name: 'Ilha das Brumas',
    start: { q: 0, r: 0 },
    tiles: [
      {
        q: 0,
        r: 0,
        biome: 'temperate',
        height: 1,
        variant: 2,
        ground: 'dirt_trail',
      },
      { q: 1, r: 0, biome: 'hill', height: 2, variant: 3, area: 1 },
      { q: 0, r: 1, biome: 'wshallow', height: 0, variant: 6 },
    ],
    actions: [{ actionTypeId: REFUGE, tiles: [{ q: 0, r: 1 }] }],
    objects: [
      {
        objectTypeId: HOUSE,
        q: 0,
        r: 1,
        variant: 2,
        mirrored: false,
        tiles: [{ q: 0, r: 1, blocks: true }],
      },
    ],
    props: [
      {
        propTypeId: FLOWERS,
        q: 1,
        r: 0,
        dx: -7,
        dy: 4,
        variant: 2,
        mirrored: false,
      },
    ],
    areas: [
      {
        key: 1,
        name: 'Bosque do norte',
        colorHex: '#5B8C3A',
        spawnCount: 10,
        species: [{ speciesId: RUVO, weight: 60, minLevel: 3, maxLevel: 6 }],
      },
    ],
  };
}

describe('draftError', () => {
  it('aceita uma ilha válida', () => {
    expect(draftError(island(), known)).toBeNull();
  });

  it('aceita uma ilha pela metade: área sem espécie e chegada na água', () => {
    const draft = island();
    draft.areas[0]!.species = [];
    draft.tiles[0]!.biome = 'wdeep';
    expect(draftError(draft, known)).toBeNull();
  });

  it.each([
    ['', 'O nome da ilha precisa ter de 1 a 40 caracteres.'],
    ['x'.repeat(41), 'O nome da ilha precisa ter de 1 a 40 caracteres.'],
  ])('recusa o nome "%s"', (name, message) => {
    expect(draftError({ ...island(), name }, known)).toBe(message);
  });

  it('recusa uma ilha sem hexágonos', () => {
    const draft = { ...island(), tiles: [], actions: [], objects: [] };
    expect(draftError(draft, known)).toBe(
      'A ilha precisa ter de 1 a 20.000 hexágonos.',
    );
  });

  it('recusa passar de 20.000 hexágonos', () => {
    const tiles = Array.from({ length: MAX_ISLAND_TILES + 1 }, (_, q) => ({
      q,
      r: 0,
      biome: 'temperate' as const,
      height: 1,
      variant: 1,
    }));
    const draft = { ...island(), tiles, actions: [], objects: [], areas: [] };
    expect(draftError(draft, known)).toBe(
      'A ilha precisa ter de 1 a 20.000 hexágonos.',
    );
  });

  it('recusa um hexágono repetido', () => {
    const draft = island();
    draft.tiles.push({ q: 1, r: 0, biome: 'stone', height: 3, variant: 1 });
    expect(draftError(draft, known)).toBe(
      'O hexágono (1, 0) aparece duas vezes.',
    );
  });

  it('recusa um bioma que não é de terreno', () => {
    const draft = island();
    (draft.tiles[0] as { biome: string }).biome = 'lava';
    expect(draftError(draft, known)).toBe(
      'O hexágono (0, 0) tem um bioma que não é de terreno.',
    );
  });

  it('aceita a Colina e a Montanha em qualquer altura', () => {
    const draft = island();
    draft.tiles[0] = { q: 0, r: 0, biome: 'mountain', height: 0, variant: 3 };
    draft.tiles[2] = { q: 0, r: 1, biome: 'wshallow', height: 4, variant: 6 };
    expect(draftError(draft, known)).toBeNull();
  });

  it('aceita a altura 10 (terrain-height/02)', () => {
    const draft = island();
    draft.tiles[0] = { q: 0, r: 0, biome: 'temperate', height: 10, variant: 1 };
    expect(draftError(draft, known)).toBeNull();
  });

  it.each([-1, 11, 1.5])('recusa a altura %d', (height) => {
    const draft = island();
    draft.tiles[0] = { q: 0, r: 0, biome: 'temperate', height, variant: 1 };
    expect(draftError(draft, known)).toBe(
      `O hexágono (0, 0) tem a altura ${height}: vai de 0 a 10.`,
    );
  });

  it.each([
    ['temperate', 7],
    ['wdeep', 0],
    ['hill', 4],
    ['mountain', 1.5],
  ] as const)('recusa a variante %s %d', (biome, variant) => {
    const draft = island();
    draft.tiles[0] = { q: 0, r: 0, biome, height: 1, variant };
    expect(draftError(draft, known)).toBe(
      `O hexágono (0, 0) tem a variante ${variant}: vai de 1 a 3 na Colina e na Montanha, e de 1 a 6 nos outros biomas.`,
    );
  });

  it('recusa a chegada fora da ilha', () => {
    const draft = { ...island(), start: { q: 9, r: 9 } };
    expect(draftError(draft, known)).toBe(
      'A chegada precisa ser um hexágono da ilha.',
    );
  });

  it('recusa um tipo de ação que não existe', () => {
    const draft = island();
    draft.actions[0]!.actionTypeId = 99;
    expect(draftError(draft, known)).toBe(
      'A ação 1 tem um tipo que não existe.',
    );
  });

  it('recusa uma ação sem hexágonos', () => {
    const draft = island();
    draft.actions[0]!.tiles = [];
    expect(draftError(draft, known)).toBe(
      'A ação 1 precisa de pelo menos 1 hexágono.',
    );
  });

  it('recusa uma ação num hexágono que não é da ilha', () => {
    const draft = island();
    draft.actions[0]!.tiles.push({ q: 5, r: 5 });
    expect(draftError(draft, known)).toBe(
      'A ação 1 ocupa (5, 5), que não é da ilha.',
    );
  });

  it('recusa duas ações no mesmo hexágono', () => {
    const draft = island();
    draft.actions.push({ actionTypeId: 2, tiles: [{ q: 0, r: 1 }] });
    expect(draftError(draft, known)).toBe('O hexágono (0, 1) é de duas ações.');
  });

  it('recusa a mesma ação duas vezes no mesmo hexágono', () => {
    const draft = island();
    draft.actions[0]!.tiles.push({ q: 0, r: 1 });
    expect(draftError(draft, known)).toBe('O hexágono (0, 1) é de duas ações.');
  });

  it('recusa um chão que não existe', () => {
    const draft = island();
    draft.tiles[1]!.ground = 'lava_trail';
    expect(draftError(draft, known)).toBe(
      'O hexágono (1, 0) tem um chão que não existe.',
    );
  });

  it('recusa um tipo de objeto que não existe', () => {
    const draft = island();
    draft.objects[0]!.objectTypeId = 99;
    expect(draftError(draft, known)).toBe(
      'O objeto 1 tem um tipo que não existe.',
    );
  });

  it.each([0, -1, 1.5])('recusa a variante de objeto %d', (variant) => {
    const draft = island();
    draft.objects[0]!.variant = variant;
    expect(draftError(draft, known)).toBe(
      `O objeto 1 tem a variante ${variant}: começa em 1.`,
    );
  });

  it('aceita qualquer variante a partir de 1, porque o painel pode diminuir as variantes', () => {
    const draft = island();
    draft.objects[0]!.variant = 40;
    expect(draftError(draft, known)).toBeNull();
  });

  it('recusa um objeto sem o hexágono de apoio', () => {
    const draft = island();
    draft.objects[0]!.tiles = [{ q: 1, r: 0, blocks: true }];
    expect(draftError(draft, known)).toBe(
      'O objeto 1 precisa ocupar o hexágono de apoio (0, 1).',
    );
  });

  it('recusa um objeto fora da ilha', () => {
    const draft = island();
    draft.objects[0]!.tiles.push({ q: 7, r: 7, blocks: false });
    expect(draftError(draft, known)).toBe(
      'O objeto 1 ocupa (7, 7), que não é da ilha.',
    );
  });

  it('recusa dois objetos no mesmo hexágono', () => {
    const draft = island();
    draft.objects.push({
      objectTypeId: 2,
      q: 1,
      r: 0,
      variant: 1,
      mirrored: true,
      tiles: [
        { q: 1, r: 0, blocks: true },
        { q: 0, r: 1, blocks: false },
      ],
    });
    expect(draftError(draft, known)).toBe(
      'O hexágono (0, 1) é de dois objetos.',
    );
  });

  it('aceita ação e objeto no mesmo hexágono', () => {
    expect(draftError(island(), known)).toBeNull();
  });

  it('recusa duas áreas com a mesma key', () => {
    const draft = island();
    draft.areas.push({ ...draft.areas[0]!, species: [] });
    expect(draftError(draft, known)).toBe('Duas áreas têm a key 1.');
  });

  it('recusa um hexágono que aponta para uma área que não existe', () => {
    const draft = island();
    draft.tiles[0]!.area = 2;
    expect(draftError(draft, known)).toBe(
      'O hexágono (0, 0) aponta para a área 2, que não existe.',
    );
  });

  it.each(['', 'y'.repeat(41)])('recusa o nome de área "%s"', (name) => {
    const draft = island();
    draft.areas[0]!.name = name;
    expect(draftError(draft, known)).toBe(
      'O nome da área 1 precisa ter de 1 a 40 caracteres.',
    );
  });

  it('recusa uma cor de área fora de #RRGGBB', () => {
    const draft = island();
    draft.areas[0]!.colorHex = 'verde';
    expect(draftError(draft, known)).toBe(
      'A cor da área 1 precisa ser #RRGGBB.',
    );
  });

  it.each([0, 201, -1, 2.5])('recusa a quantidade %d de Ecobeasts', (count) => {
    const draft = island();
    draft.areas[0]!.spawnCount = count;
    expect(draftError(draft, known)).toBe(
      'Na área 1, a quantidade de Ecobeasts precisa ir de 1 a 200.',
    );
  });

  it.each([1, 200])('aceita a quantidade %d de Ecobeasts', (count) => {
    const draft = island();
    draft.areas[0]!.spawnCount = count;
    expect(draftError(draft, known)).toBeNull();
  });

  it('recusa uma espécie que não existe', () => {
    const draft = island();
    draft.areas[0]!.species[0]!.speciesId = 999;
    expect(draftError(draft, known)).toBe(
      'A área 1 tem uma espécie que não existe (999).',
    );
  });

  it('recusa a mesma espécie duas vezes na área', () => {
    const draft = island();
    draft.areas[0]!.species.push({ ...draft.areas[0]!.species[0]! });
    expect(draftError(draft, known)).toBe('A área 1 repete a espécie 1.');
  });

  it.each([0, -3, 2.5])('recusa o peso %d', (weight) => {
    const draft = island();
    draft.areas[0]!.species[0]!.weight = weight;
    expect(draftError(draft, known)).toBe(
      'Na área 1, o peso da espécie 1 precisa ser um inteiro maior que 0.',
    );
  });

  it.each([
    [0, 5],
    [5, 101],
    [7, 6],
    [2.5, 6],
  ])('recusa os níveis %d a %d', (minLevel, maxLevel) => {
    const draft = island();
    Object.assign(draft.areas[0]!.species[0]!, { minLevel, maxLevel });
    expect(draftError(draft, known)).toBe(
      'Na área 1, os níveis da espécie 1 precisam ir de 1 a 100, com o mínimo até o máximo.',
    );
  });

  it('aceita o mesmo nível no mínimo e no máximo', () => {
    const draft = island();
    Object.assign(draft.areas[0]!.species[0]!, { minLevel: 5, maxLevel: 5 });
    expect(draftError(draft, known)).toBeNull();
  });
});

describe('publishError', () => {
  it('aceita uma ilha válida', () => {
    expect(publishError(island(), known)).toBeNull();
  });

  it('começa pelas conferências de salvar', () => {
    expect(publishError({ ...island(), name: '' }, known)).toBe(
      'O nome da ilha precisa ter de 1 a 40 caracteres.',
    );
  });

  it.each(['wshallow', 'wdeep'] as const)('recusa a chegada em %s', (biome) => {
    const draft = island();
    draft.tiles[0]!.biome = biome;
    expect(publishError(draft, known)).toBe(
      'A chegada não pode ficar na água.',
    );
  });

  it('recusa a chegada numa ação', () => {
    const draft = island();
    draft.actions[0]!.tiles = [{ q: 0, r: 0 }];
    expect(publishError(draft, known)).toBe(
      'A chegada não pode ficar numa ação.',
    );
  });

  it('recusa a chegada num hexágono bloqueado', () => {
    const draft = island();
    draft.objects[0]!.q = 0;
    draft.objects[0]!.r = 0;
    draft.objects[0]!.tiles = [{ q: 0, r: 0, blocks: true }];
    expect(publishError(draft, known)).toBe(
      'A chegada não pode ficar num hexágono bloqueado.',
    );
  });

  it('aceita a chegada num hexágono de objeto livre', () => {
    const draft = island();
    draft.objects[0]!.q = 0;
    draft.objects[0]!.r = 0;
    draft.objects[0]!.tiles = [{ q: 0, r: 0, blocks: false }];
    expect(publishError(draft, known)).toBeNull();
  });

  it('recusa uma área sem espécies', () => {
    const draft = island();
    draft.areas[0]!.species = [];
    expect(publishError(draft, known)).toBe(
      'A área "Bosque do norte" não tem nenhuma espécie.',
    );
  });
});

describe('canonicalDraft e draftHash', () => {
  it('não depende da ordem dos hexágonos nem das espécies', () => {
    const shuffled = island();
    shuffled.tiles.reverse();
    shuffled.areas[0]!.species.push({
      speciesId: NILU,
      weight: 1,
      minLevel: 1,
      maxLevel: 2,
    });
    const sorted = island();
    sorted.areas[0]!.species.unshift({
      speciesId: NILU,
      weight: 1,
      minLevel: 1,
      maxLevel: 2,
    });
    expect(canonicalDraft(shuffled)).toBe(canonicalDraft(sorted));
    expect(draftHash(shuffled)).toBe(draftHash(sorted));
  });

  it('não depende dos números das keys, só da ordem delas', () => {
    const renumbered = island();
    renumbered.areas[0]!.key = 7;
    renumbered.tiles[1]!.area = 7;
    expect(draftHash(renumbered)).toBe(draftHash(island()));
  });

  it('não depende da ordem dos objetos nem dos hexágonos deles', () => {
    const second = {
      objectTypeId: 2,
      q: 1,
      r: 0,
      variant: 1,
      mirrored: false,
      tiles: [
        { q: 1, r: 0, blocks: true },
        { q: 1, r: -1, blocks: false },
      ],
    };
    const one = island();
    one.objects.push(second);
    const other = island();
    other.objects.unshift({ ...second, tiles: [...second.tiles].reverse() });
    expect(draftHash(one)).toBe(draftHash(other));
  });

  it('muda quando o chão, o bloqueio ou o espelho mudam', () => {
    const ground = island();
    ground.tiles[0]!.ground = 'cobble_floor';
    const blocks = island();
    blocks.objects[0]!.tiles[0]!.blocks = false;
    const mirrored = island();
    mirrored.objects[0]!.mirrored = true;
    for (const changed of [ground, blocks, mirrored]) {
      expect(draftHash(changed)).not.toBe(draftHash(island()));
    }
  });

  it('muda quando o terreno muda', () => {
    const changed = island();
    changed.tiles[0]!.variant = 3;
    expect(draftHash(changed)).not.toBe(draftHash(island()));
  });

  it('muda quando a quantidade de Ecobeasts de uma área muda', () => {
    const changed = island();
    changed.areas[0]!.spawnCount = 11;
    expect(draftHash(changed)).not.toBe(draftHash(island()));
    expect(canonicalDraft(changed)).toContain('"spawnCount":11');
  });

  it('é um sha-256 em hexadecimal', () => {
    expect(draftHash(island())).toMatch(/^[0-9a-f]{64}$/);
  });
});

describe('as peças soltas no rascunho (free-props/01)', () => {
  const withProp = (change: Partial<IslandDraft['props'][number]>) => {
    const draft = island();
    draft.props.push({ ...draft.props[0]!, ...change });
    return draft;
  };

  it('aceita uma peça dentro do próprio hexágono', () => {
    expect(draftError(island(), known)).toBeNull();
  });

  it('recusa um tipo que não existe', () => {
    expect(draftError(withProp({ propTypeId: 99 }), known)).toBe(
      'A peça 2 tem um tipo que não existe.',
    );
  });

  it('recusa a variante fora de 1 até as variantes do tipo', () => {
    expect(draftError(withProp({ variant: 5 }), known)).toBe(
      'A peça 2 tem a variante 5: vai de 1 a 4.',
    );
    expect(draftError(withProp({ propTypeId: BENCH, variant: 0 }), known)).toBe(
      'A peça 2 tem a variante 0: vai de 1 a 2.',
    );
  });

  it('recusa um hexágono que não é da ilha', () => {
    expect(draftError(withProp({ q: 2, r: 1 }), known)).toBe(
      'A peça 2 fica em (2, 1), que não é da ilha.',
    );
  });

  it('recusa o pé fora do próprio hexágono', () => {
    expect(draftError(withProp({ dx: 0, dy: -30 }), known)).toBe(
      'A peça 2 tem o pé fora do hexágono (1, 0).',
    );
    expect(draftError(withProp({ dx: 1.5 }), known)).toBe(
      'A peça 2 tem o pé fora do hexágono (1, 0).',
    );
  });

  it(`recusa mais de ${MAX_PROPS} peças`, () => {
    const draft = island();
    draft.props = Array.from({ length: MAX_PROPS + 1 }, () => draft.props[0]!);
    expect(draftError(draft, known)).toBe('A ilha pode ter até 6.000 peças.');
  });

  it('o rascunho canônico ordena as peças e muda com elas', () => {
    const draft = withProp({ q: 0, r: 0, dx: 3, dy: -2, mirrored: true });
    const reversed = { ...draft, props: [...draft.props].reverse() };
    expect(canonicalDraft(reversed)).toBe(canonicalDraft(draft));
    const props = JSON.parse(canonicalDraft(draft)).props;
    expect(props[0]).toEqual({
      propTypeId: FLOWERS,
      q: 0,
      r: 0,
      dx: 3,
      dy: -2,
      variant: 2,
      mirrored: true,
    });
    expect(draftHash(withProp({ variant: 3 }))).not.toBe(draftHash(draft));
  });
});

describe('a marca sem decorações (free-props/05)', () => {
  it('aceita a marca bare verdadeira ou falsa', () => {
    const draft = island();
    draft.tiles[0]!.bare = true;
    draft.tiles[1]!.bare = false;
    expect(draftError(draft, known)).toBeNull();
  });

  it('recusa uma marca bare que não é booleana', () => {
    const draft = island();
    (draft.tiles[1] as { bare?: unknown }).bare = 'sim';
    expect(draftError(draft, known)).toBe(
      'O hexágono (1, 0) tem a marca bare que não é verdadeira nem falsa.',
    );
  });

  it('leva a marca no hash só quando ela é verdadeira', () => {
    const draft = island();
    const plain = draftHash(draft);
    draft.tiles[0]!.bare = false;
    expect(draftHash(draft)).toBe(plain);
    draft.tiles[0]!.bare = true;
    expect(draftHash(draft)).not.toBe(plain);
    expect(JSON.parse(canonicalDraft(draft)).tiles[0].bare).toBe(true);
  });
});

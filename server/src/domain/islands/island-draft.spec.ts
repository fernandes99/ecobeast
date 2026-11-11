import {
  canonicalDraft,
  draftError,
  draftHash,
  type IslandDraft,
  type KnownIds,
  MAX_ISLAND_TILES,
  publishError,
} from './island-draft.js';

const REFUGE = 1;
const RUVO = 1;
const NILU = 4;
const known: KnownIds = {
  buildingTypeIds: new Set([REFUGE, 2]),
  speciesIds: new Set([RUVO, NILU]),
};

/** Uma ilha pequena e válida: 3 hexágonos, um Refúgio e uma área. */
function island(): IslandDraft {
  return {
    name: 'Ilha das Brumas',
    start: { q: 0, r: 0 },
    tiles: [
      { q: 0, r: 0, biome: 'temperate', shape: 'flat', variant: 2 },
      { q: 1, r: 0, biome: 'boreal', shape: 'hill', variant: 3, area: 1 },
      { q: 0, r: 1, biome: 'wshallow', shape: 'flat', variant: 6 },
    ],
    buildings: [{ buildingTypeId: REFUGE, tiles: [{ q: 0, r: 1 }] }],
    areas: [
      {
        key: 1,
        name: 'Bosque do norte',
        colorHex: '#5B8C3A',
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
    const draft = { ...island(), tiles: [], buildings: [] };
    expect(draftError(draft, known)).toBe(
      'A ilha precisa ter de 1 a 20.000 hexágonos.',
    );
  });

  it('recusa passar de 20.000 hexágonos', () => {
    const tiles = Array.from({ length: MAX_ISLAND_TILES + 1 }, (_, q) => ({
      q,
      r: 0,
      biome: 'temperate' as const,
      shape: 'flat' as const,
      variant: 1,
    }));
    const draft = { ...island(), tiles, buildings: [], areas: [] };
    expect(draftError(draft, known)).toBe(
      'A ilha precisa ter de 1 a 20.000 hexágonos.',
    );
  });

  it('recusa um hexágono repetido', () => {
    const draft = island();
    draft.tiles.push({ q: 1, r: 0, biome: 'stone', shape: 'flat', variant: 1 });
    expect(draftError(draft, known)).toBe(
      'O hexágono (1, 0) aparece duas vezes.',
    );
  });

  it('recusa um bioma que não é de terreno', () => {
    const draft = island();
    (draft.tiles[0] as { biome: string }).biome = 'mountain';
    expect(draftError(draft, known)).toBe(
      'O hexágono (0, 0) tem um bioma que não é de terreno.',
    );
  });

  it('recusa uma forma desconhecida', () => {
    const draft = island();
    (draft.tiles[0] as { shape: string }).shape = 'cliff';
    expect(draftError(draft, known)).toBe(
      'O hexágono (0, 0) tem uma forma inválida.',
    );
  });

  it.each([
    ['flat', 7],
    ['flat', 0],
    ['hill', 4],
    ['mont', 1.5],
  ] as const)('recusa a variante %s %d', (shape, variant) => {
    const draft = island();
    draft.tiles[0] = { q: 0, r: 0, biome: 'temperate', shape, variant };
    expect(draftError(draft, known)).toBe(
      `O hexágono (0, 0) tem a variante ${variant}: vai de 1 a 6 no plano e de 1 a 3 nas outras formas.`,
    );
  });

  it('recusa a chegada fora da ilha', () => {
    const draft = { ...island(), start: { q: 9, r: 9 } };
    expect(draftError(draft, known)).toBe(
      'A chegada precisa ser um hexágono da ilha.',
    );
  });

  it('recusa um tipo de construção que não existe', () => {
    const draft = island();
    draft.buildings[0]!.buildingTypeId = 99;
    expect(draftError(draft, known)).toBe(
      'A construção 1 tem um tipo que não existe.',
    );
  });

  it('recusa uma construção sem hexágonos', () => {
    const draft = island();
    draft.buildings[0]!.tiles = [];
    expect(draftError(draft, known)).toBe(
      'A construção 1 precisa de pelo menos 1 hexágono.',
    );
  });

  it('recusa uma construção num hexágono que não é da ilha', () => {
    const draft = island();
    draft.buildings[0]!.tiles.push({ q: 5, r: 5 });
    expect(draftError(draft, known)).toBe(
      'A construção 1 ocupa (5, 5), que não é da ilha.',
    );
  });

  it('recusa duas construções no mesmo hexágono', () => {
    const draft = island();
    draft.buildings.push({ buildingTypeId: 2, tiles: [{ q: 0, r: 1 }] });
    expect(draftError(draft, known)).toBe(
      'O hexágono (0, 1) é de duas construções.',
    );
  });

  it('recusa a mesma construção duas vezes no mesmo hexágono', () => {
    const draft = island();
    draft.buildings[0]!.tiles.push({ q: 0, r: 1 });
    expect(draftError(draft, known)).toBe(
      'O hexágono (0, 1) é de duas construções.',
    );
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

  it('recusa a chegada numa construção', () => {
    const draft = island();
    draft.buildings[0]!.tiles = [{ q: 0, r: 0 }];
    expect(publishError(draft, known)).toBe(
      'A chegada não pode ficar numa construção.',
    );
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

  it('muda quando o terreno muda', () => {
    const changed = island();
    changed.tiles[0]!.variant = 3;
    expect(draftHash(changed)).not.toBe(draftHash(island()));
  });

  it('é um sha-256 em hexadecimal', () => {
    expect(draftHash(island())).toMatch(/^[0-9a-f]{64}$/);
  });
});

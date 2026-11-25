import { appearanceError } from '../appearance/appearance.js';
import type { AppearanceCatalog } from '../appearance/appearance.js';
import { defaultAppearance, npcSlug, npcUsageText } from './npc-catalog.js';

const catalog: AppearanceCatalog = {
  bodies: [
    { id: 1, name: 'Masculino', adultBodyTypeId: null },
    { id: 2, name: 'Feminino', adultBodyTypeId: null },
    { id: 3, name: 'Menino', adultBodyTypeId: 1 },
  ],
  slots: [
    { id: 1, name: 'rosto', paletteKind: null, required: true },
    { id: 2, name: 'cabelo', paletteKind: 'hair', required: false },
    { id: 3, name: 'camisa', paletteKind: 'cloth', required: true },
  ],
  parts: [
    { id: 10, name: 'Rosto 1', slotId: 1, bodyTypeId: null },
    { id: 21, name: 'Camisa fem', slotId: 3, bodyTypeId: 2 },
    { id: 22, name: 'Camisa masc', slotId: 3, bodyTypeId: 1 },
    { id: 30, name: 'Cabelo', slotId: 2, bodyTypeId: null },
  ],
  palettes: [
    { id: 5, kind: 'skin' },
    { id: 2, kind: 'skin' },
    { id: 7, kind: 'cloth' },
    { id: 8, kind: 'hair' },
  ],
};

describe('npcSlug', () => {
  it('tira o acento e troca o resto por _', () => {
    expect(npcSlug('Dona Zélia', new Set())).toBe('dona_zelia');
    expect(npcSlug('  Seu  João!! ', new Set())).toBe('seu_joao');
  });

  it('ganha um número quando já existe', () => {
    expect(npcSlug('Caio', new Set(['caio']))).toBe('caio_2');
    expect(npcSlug('Caio', new Set(['caio', 'caio_2']))).toBe('caio_3');
  });

  it('sem letra nem número vira npc', () => {
    expect(npcSlug('!!!', new Set())).toBe('npc');
  });
});

describe('defaultAppearance', () => {
  it('veste os lugares obrigatórios com a peça do corpo e a primeira cor', () => {
    const look = defaultAppearance(2, catalog);
    expect(look).toEqual({
      bodyTypeId: 2,
      skinPaletteId: 2,
      parts: [
        { partId: 10, paletteId: null },
        { partId: 21, paletteId: 7 },
      ],
    });
    expect(appearanceError(look!, catalog, true)).toBeNull();
  });

  it('a criança veste as peças do corpo de adulto dela', () => {
    const look = defaultAppearance(3, catalog);
    expect(look?.parts).toEqual([
      { partId: 10, paletteId: null },
      { partId: 22, paletteId: 7 },
    ]);
    expect(appearanceError(look!, catalog, true)).toBeNull();
  });

  it('corpo que não existe dá null', () => {
    expect(defaultAppearance(99, catalog)).toBeNull();
  });
});

describe('npcUsageText', () => {
  const unused = {
    islandMaps: [],
    interiors: [],
    givenQuests: 0,
    targetQuests: 0,
    tamer: false,
  };

  it('sem uso dá null', () => {
    expect(npcUsageText(unused)).toBeNull();
  });

  it('junta o rascunho e a publicada da mesma ilha e diz o resto', () => {
    expect(
      npcUsageText({
        islandMaps: [
          { islandId: 1, name: 'Liora', kind: 'published' },
          { islandId: 1, name: 'Liora', kind: 'draft' },
        ],
        interiors: ['Refúgio', 'Refúgio'],
        givenQuests: 2,
        targetQuests: 1,
        tamer: true,
      }),
    ).toBe(
      'Esse NPC está em uso: posto em Liora (rascunho e publicada); na sala Refúgio; dá 2 missões; é o alvo de 1 missão; é Domador de uma ilha. Tire-o de lá antes de excluir.',
    );
  });
});

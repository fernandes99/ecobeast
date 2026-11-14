import {
  AppearanceCatalog,
  appearanceError,
  AppearanceInput,
} from './appearance.js';

const catalog: AppearanceCatalog = {
  bodies: [
    { id: 1, name: 'Masculino' },
    { id: 2, name: 'Feminino' },
  ],
  slots: [
    { id: 1, name: 'Rosto', paletteKind: null, required: true },
    { id: 2, name: 'Parte de baixo', paletteKind: 'cloth', required: false },
    { id: 5, name: 'Cabelo', paletteKind: 'hair', required: false },
  ],
  parts: [
    { id: 1, name: 'Rosto 1', slotId: 1, bodyTypeId: null },
    { id: 2, name: 'Saia', slotId: 2, bodyTypeId: 2 },
    { id: 3, name: 'Calça', slotId: 2, bodyTypeId: null },
    { id: 4, name: 'Curto', slotId: 5, bodyTypeId: null },
  ],
  palettes: [
    { id: 1, kind: 'skin' },
    { id: 2, kind: 'hair' },
    { id: 3, kind: 'cloth' },
  ],
};

const valid = (): AppearanceInput => ({
  bodyTypeId: 1,
  skinPaletteId: 1,
  parts: [
    { partId: 1, paletteId: null },
    { partId: 3, paletteId: 3 },
    { partId: 4, paletteId: 2 },
  ],
});

describe('appearanceError', () => {
  it('aceita uma aparência certa', () => {
    expect(appearanceError(valid(), catalog)).toBeNull();
  });

  it('aceita só o rosto, sem as peças que não são obrigatórias', () => {
    const input = { ...valid(), parts: [{ partId: 1, paletteId: null }] };
    expect(appearanceError(input, catalog)).toBeNull();
  });

  it('aceita a peça de um corpo só no corpo dela', () => {
    const input = valid();
    input.bodyTypeId = 2;
    input.parts[1] = { partId: 2, paletteId: 3 };
    expect(appearanceError(input, catalog)).toBeNull();
  });

  it.each<[string, (input: AppearanceInput) => void, string]>([
    ['corpo', (i) => (i.bodyTypeId = 9), 'Esse corpo não existe.'],
    ['pele', (i) => (i.skinPaletteId = 9), 'Essa cor de pele não existe.'],
    [
      'pele que não é de pele',
      (i) => (i.skinPaletteId = 2),
      'Essa cor de pele não existe.',
    ],
    [
      'peça',
      (i) => i.parts.push({ partId: 9, paletteId: null }),
      'A peça 9 não existe.',
    ],
    [
      'peça de outro corpo',
      (i) => (i.parts[1] = { partId: 2, paletteId: 3 }),
      'A peça Saia não serve no corpo Masculino.',
    ],
    [
      'lugar repetido',
      (i) => i.parts.push({ partId: 2, paletteId: 3 }),
      'A peça Saia não serve no corpo Masculino.',
    ],
    [
      'lugar repetido no mesmo corpo',
      (i) => i.parts.push({ partId: 3, paletteId: 3 }),
      'Duas peças no mesmo lugar: Parte de baixo.',
    ],
    ['lugar obrigatório', (i) => i.parts.shift(), 'Escolha um Rosto.'],
    [
      'peça sem cor',
      (i) => (i.parts[2]!.paletteId = null),
      'Escolha uma cor para Cabelo.',
    ],
    [
      'cor de outro tipo',
      (i) => (i.parts[2]!.paletteId = 3),
      'A cor 3 não serve para Cabelo.',
    ],
    [
      'cor que não existe',
      (i) => (i.parts[2]!.paletteId = 30),
      'A cor 30 não serve para Cabelo.',
    ],
    [
      'cor em lugar de cor fixa',
      (i) => (i.parts[0]!.paletteId = 3),
      'A cor 3 não serve para Rosto.',
    ],
  ])('recusa %s', (_name, change, message) => {
    const input = valid();
    change(input);
    expect(appearanceError(input, catalog)).toBe(message);
  });
});

import { availableGroundItems, foundLine } from './ground-items.js';
import type { DraftItem } from './island-draft.js';

const item = (key: number, once: boolean): DraftItem => ({
  key,
  itemId: 1,
  q: key,
  r: 0,
  quantity: 1,
  once,
  hidden: false,
});

describe('os itens no chão que o Domador pode pegar (auralis/09)', () => {
  const items = [item(1, true), item(2, false), item(3, true)];

  it('tira o "só uma vez" já pego por ele e o que volta pego nesta entrada', () => {
    expect(
      availableGroundItems(items, new Set([1]), new Set([2])).map(
        ({ key }) => key,
      ),
    ).toEqual([3]);
  });

  it('o que volta não olha o banco, e o "só uma vez" não olha a entrada', () => {
    expect(
      availableGroundItems(items, new Set([2]), new Set([1, 3])).map(
        ({ key }) => key,
      ),
    ).toEqual([1, 2, 3]);
  });

  it('a fala diz a quantidade e o nome', () => {
    expect(foundLine(2, 'Tônico Leve')).toBe('Você encontrou 2 Tônico Leve!');
  });
});

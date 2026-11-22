import type { DraftItem } from './island-draft.js';

/**
 * Os itens do chão que o Domador ainda pode pegar (auralis/09): o "só uma vez"
 * some depois de pego por ele, e o que volta some só nesta entrada.
 */
export function availableGroundItems(
  items: readonly DraftItem[],
  pickedOnce: ReadonlySet<number>,
  pickedThisEntry: ReadonlySet<number>,
): DraftItem[] {
  return items.filter(({ key, once }) =>
    once ? !pickedOnce.has(key) : !pickedThisEntry.has(key),
  );
}

export const foundLine = (quantity: number, itemName: string): string =>
  `Você encontrou ${quantity} ${itemName}!`;

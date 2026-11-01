export const NO_ITEM = 'Você não tem esse item.';
export const CANNOT_USE = 'Esse item não pode ser usado agora.';
export const CANNOT_REVIVE = 'Só o Refúgio recupera um Ecobeast sem HP.';
export const NO_EFFECT = 'Não teria efeito.';

export interface UsableItem {
  healAmount: number | null;
  curesStatus: boolean;
}

export interface ItemTarget {
  currentHp: number;
  maxHp: number;
  hasStatus: boolean;
}

export interface ItemEffect {
  healed: number;
  curesStatus: boolean;
}

/** O que um item faz em um alvo, no mapa ou na luta. Não muda nada. */
export function resolveItem(
  item: UsableItem,
  target: ItemTarget,
): ItemEffect | { error: string } {
  if (item.healAmount === null && !item.curesStatus) {
    return { error: CANNOT_USE };
  }
  if (target.currentHp === 0) return { error: CANNOT_REVIVE };

  const healed = Math.min(
    item.healAmount ?? 0,
    target.maxHp - target.currentHp,
  );
  const curesStatus = item.curesStatus && target.hasStatus;
  if (healed === 0 && !curesStatus) return { error: NO_EFFECT };
  return { healed, curesStatus };
}

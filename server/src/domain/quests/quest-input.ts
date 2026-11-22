import { findQuestSlug } from './quests.js';

export const MAX_QUEST_TILES = 50;
export const MAX_QUEST_AMOUNT = 9999;
export const MAX_QUEST_COINS = 1_000_000;
export const MAX_ITEM_QUANTITY = 99;
export const MAX_PLACE_NAME = 40;
export const MAX_QUEST_TITLE = 60;

export const QUEST_INPUT_ERRORS = {
  type: 'Escolha o tipo da missão.',
  amount: `A quantidade vai de 1 a ${MAX_QUEST_AMOUNT}.`,
  percent: 'A porcentagem vai de 1 a 100.',
  minutes: `Os minutos vão de 1 a ${MAX_QUEST_AMOUNT}.`,
  placeName: `Informe o nome do lugar, com até ${MAX_PLACE_NAME} letras.`,
  tiles: `Escolha de 1 a ${MAX_QUEST_TILES} hexágonos no mapa.`,
  targetNpc: 'Escolha o NPC alvo.',
  species: 'Escolha a espécie.',
  targetItem: 'Escolha o item que o jogador precisa encontrar.',
  title: `O título vai até ${MAX_QUEST_TITLE} letras.`,
  coins: 'As moedas vão de 0 a 1.000.000.',
  itemQuantity: `A quantidade do item vai de 1 a ${MAX_ITEM_QUANTITY}.`,
} as const;

/** O que o editor manda; os campos que faltam chegam nulos. */
export interface QuestDraft {
  questTypeId: number;
  amount: number | null;
  speciesId: number | null;
  targetNpcId: number | null;
  targetItemId: number | null;
  placeName: string | null;
  title: string | null;
  coins: number | null;
  itemId: number | null;
  itemQuantity: number | null;
  countsForUnlock: boolean | null;
  tiles: unknown[] | null;
}

/** A missão pronta para gravar: só os parâmetros que o tipo usa. */
export interface QuestInput {
  questTypeId: number;
  amount: number | null;
  speciesId: number | null;
  targetNpcId: number | null;
  targetItemId: number | null;
  placeName: string | null;
  title: string | null;
  coins: number;
  itemId: number | null;
  itemQuantity: number | null;
  countsForUnlock: boolean;
  tiles: { q: number; r: number }[];
}

const inRange = (value: number | null, min: number, max: number) =>
  value !== null && Number.isInteger(value) && value >= min && value <= max;

function text(value: string | null): string | null {
  const trimmed = value?.trim() ?? '';
  return trimmed === '' ? null : trimmed;
}

function tilesOf(raw: unknown[] | null): { q: number; r: number }[] | null {
  const seen = new Map<string, { q: number; r: number }>();
  for (const tile of raw ?? []) {
    const { q, r } = (tile ?? {}) as { q?: unknown; r?: unknown };
    if (!Number.isInteger(q) || !Number.isInteger(r)) return null;
    seen.set(`${q},${r}`, { q: q as number, r: r as number });
  }
  return [...seen.values()];
}

/** Confere e limpa a missão do editor (auralis/07); o erro é a mensagem do 400. */
export function checkQuestDraft(
  draft: QuestDraft,
): { quest: QuestInput } | { error: string } {
  const slug = findQuestSlug(draft.questTypeId);
  if (!slug) return { error: QUEST_INPUT_ERRORS.type };
  const quest: QuestInput = {
    questTypeId: draft.questTypeId,
    amount: null,
    speciesId: null,
    targetNpcId: null,
    targetItemId: null,
    placeName: null,
    title: text(draft.title),
    coins: draft.coins ?? 0,
    itemId: draft.itemId,
    itemQuantity: draft.itemId === null ? null : (draft.itemQuantity ?? 1),
    countsForUnlock: draft.countsForUnlock ?? true,
    tiles: [],
  };
  switch (slug) {
    case 'capture_any':
    case 'defeat_any':
      if (!inRange(draft.amount, 1, MAX_QUEST_AMOUNT)) {
        return { error: QUEST_INPUT_ERRORS.amount };
      }
      quest.amount = draft.amount;
      break;
    case 'stay_minutes':
      if (!inRange(draft.amount, 1, MAX_QUEST_AMOUNT)) {
        return { error: QUEST_INPUT_ERRORS.minutes };
      }
      quest.amount = draft.amount;
      break;
    case 'explore_percent':
      if (!inRange(draft.amount, 1, 100)) {
        return { error: QUEST_INPUT_ERRORS.percent };
      }
      quest.amount = draft.amount;
      break;
    case 'reach_place': {
      const name = text(draft.placeName);
      if (name === null || name.length > MAX_PLACE_NAME) {
        return { error: QUEST_INPUT_ERRORS.placeName };
      }
      const tiles = tilesOf(draft.tiles);
      if (
        tiles === null ||
        tiles.length < 1 ||
        tiles.length > MAX_QUEST_TILES
      ) {
        return { error: QUEST_INPUT_ERRORS.tiles };
      }
      quest.placeName = name;
      quest.tiles = tiles;
      break;
    }
    case 'talk_npc':
    case 'defeat_tamer':
      if (draft.targetNpcId === null) {
        return { error: QUEST_INPUT_ERRORS.targetNpc };
      }
      quest.targetNpcId = draft.targetNpcId;
      break;
    case 'find_species':
    case 'defeat_species':
      if (draft.speciesId === null)
        return { error: QUEST_INPUT_ERRORS.species };
      if (
        draft.amount !== null &&
        !inRange(draft.amount, 1, MAX_QUEST_AMOUNT)
      ) {
        return { error: QUEST_INPUT_ERRORS.amount };
      }
      quest.speciesId = draft.speciesId;
      quest.amount = draft.amount;
      break;
    case 'find_item':
      if (draft.targetItemId === null) {
        return { error: QUEST_INPUT_ERRORS.targetItem };
      }
      if (
        draft.amount !== null &&
        !inRange(draft.amount, 1, MAX_QUEST_AMOUNT)
      ) {
        return { error: QUEST_INPUT_ERRORS.amount };
      }
      quest.targetItemId = draft.targetItemId;
      quest.amount = draft.amount;
      break;
  }
  if (quest.title !== null && quest.title.length > MAX_QUEST_TITLE) {
    return { error: QUEST_INPUT_ERRORS.title };
  }
  if (!inRange(quest.coins, 0, MAX_QUEST_COINS)) {
    return { error: QUEST_INPUT_ERRORS.coins };
  }
  if (
    quest.itemId !== null &&
    !inRange(quest.itemQuantity, 1, MAX_ITEM_QUANTITY)
  ) {
    return { error: QUEST_INPUT_ERRORS.itemQuantity };
  }
  return { quest };
}

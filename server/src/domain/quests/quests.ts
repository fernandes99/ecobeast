/** Os tipos de missão do catálogo `quest_types` (auralis/06). */
export const QUEST_TYPES = {
  capture_any: 1,
  defeat_any: 2,
  explore_percent: 3,
  reach_place: 4,
  talk_npc: 5,
  stay_minutes: 6,
  find_species: 7,
  defeat_species: 8,
  defeat_tamer: 9,
} as const;

export type QuestTypeSlug = keyof typeof QUEST_TYPES;

const SLUGS = new Map<number, QuestTypeSlug>(
  Object.entries(QUEST_TYPES).map(([slug, id]) => [id, slug as QuestTypeSlug]),
);

export function findQuestSlug(questTypeId: number): QuestTypeSlug | undefined {
  return SLUGS.get(questTypeId);
}

export function questSlug(questTypeId: number): QuestTypeSlug {
  const slug = SLUGS.get(questTypeId);
  if (!slug) throw new Error(`Tipo de missão desconhecido: ${questTypeId}`);
  return slug;
}

export interface QuestParams {
  questTypeId: number;
  amount: number | null;
  placeName: string | null;
  title: string | null;
}

export interface QuestNames {
  island: string;
  species: string | null;
  targetNpc: string | null;
}

/** O alvo do progresso: no "Fique", em segundos; no "Explore", em %. */
export function questTarget({ questTypeId, amount }: QuestParams): number {
  switch (questSlug(questTypeId)) {
    case 'capture_any':
    case 'defeat_any':
    case 'explore_percent':
      return amount!;
    case 'stay_minutes':
      return amount! * 60;
    case 'find_species':
    case 'defeat_species':
      return amount ?? 1;
    case 'reach_place':
    case 'talk_npc':
    case 'defeat_tamer':
      return 1;
  }
}

function plural(amount: number, one: string, many: string): string {
  return amount === 1 ? one : many;
}

export function questTitle(quest: QuestParams, names: QuestNames): string {
  if (quest.title) return quest.title;
  const amount = quest.amount ?? 1;
  const species = names.species ?? '?';
  switch (questSlug(quest.questTypeId)) {
    case 'capture_any':
      return `Capture ${amount} ${plural(amount, 'Ecobeast', 'Ecobeasts')}`;
    case 'defeat_any':
      return `Derrote ${amount} ${plural(amount, 'Ecobeast', 'Ecobeasts')}`;
    case 'explore_percent':
      return `Explore ${amount}% de ${names.island}`;
    case 'reach_place':
      return `Vá até ${quest.placeName}`;
    case 'talk_npc':
      return `Fale com ${names.targetNpc ?? '?'}`;
    case 'stay_minutes':
      return `Fique em ${names.island} por ${amount} ${plural(amount, 'minuto', 'minutos')}`;
    case 'find_species':
      return amount === 1
        ? `Encontre ${species}`
        : `Encontre ${amount} ${species}`;
    case 'defeat_species':
      return amount === 1
        ? `Derrote ${species}`
        : `Derrote ${amount} ${species}`;
    case 'defeat_tamer':
      return `Derrote ${names.targetNpc ?? '?'}`;
  }
}

/** O progresso na unidade da fala: % no "Explore" e minutos no "Fique". */
export function progressLine(
  quest: QuestParams,
  title: string,
  progress: number,
): string {
  const target = questTarget(quest);
  const slug = questSlug(quest.questTypeId);
  if (slug === 'explore_percent') {
    return `${title}: ${progress}% de ${target}%.`;
  }
  if (slug === 'stay_minutes') {
    return `${title}: ${Math.floor(progress / 60)} de ${target / 60} minutos.`;
  }
  return `${title}: ${progress} de ${target}.`;
}

export const acceptedLine = (title: string): string => `Nova missão: ${title}.`;
export const claimedLine = (title: string): string =>
  `Missão cumprida: ${title}!`;

export function explorePercent(discovered: number, total: number): number {
  if (total <= 0) return 0;
  return Math.min(100, Math.floor((discovered * 100) / total));
}

/** O que o fim de uma luta conta nas missões. */
export interface BattleQuestEvents {
  capturedSpeciesIds: readonly number[];
  defeatedSpeciesIds: readonly number[];
  enemySpeciesIds: readonly number[];
  /** O Domador da ilha vencido (`tamers.id`). */
  beatenTamerId: number | null;
}

export interface ActiveQuest {
  questId: number;
  questTypeId: number;
  speciesId: number | null;
  /** O Domador da ilha do NPC alvo (`tamers.id`). */
  targetTamerId: number | null;
}

export interface QuestDelta {
  questId: number;
  amount: number;
}

/** Quanto cada missão aceita soma com a luta; o teto do alvo fica com quem grava. */
export function battleQuestDeltas(
  events: BattleQuestEvents,
  quests: readonly ActiveQuest[],
): QuestDelta[] {
  const count = (list: readonly number[], speciesId: number | null) =>
    list.filter((id) => id === speciesId).length;
  return quests.flatMap((quest) => {
    let amount = 0;
    switch (SLUGS.get(quest.questTypeId)) {
      case 'capture_any':
        amount = events.capturedSpeciesIds.length;
        break;
      case 'defeat_any':
        amount = events.defeatedSpeciesIds.length;
        break;
      case 'find_species':
        amount = events.enemySpeciesIds.includes(quest.speciesId!) ? 1 : 0;
        break;
      case 'defeat_species':
        amount = count(events.defeatedSpeciesIds, quest.speciesId);
        break;
      case 'defeat_tamer':
        amount =
          events.beatenTamerId !== null &&
          events.beatenTamerId === quest.targetTamerId
            ? 1
            : 0;
        break;
      default:
        break;
    }
    return amount > 0 ? [{ questId: quest.questId, amount }] : [];
  });
}

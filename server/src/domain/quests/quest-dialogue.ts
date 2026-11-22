/** As conversas da missão (auralis/10): início, durante e fim, em falas e escolhas. */

export const MAX_DIALOGUE_TEXT = 300;
export const MAX_OPTION_TEXT = 40;
export const MIN_OPTIONS = 2;
export const MAX_OPTIONS = 4;
export const MAX_CHOICE_DEPTH = 3;
export const MAX_DIALOGUE_STEPS = 40;
export const MAX_SCENE_SLUG = 64;

export const DIALOGUE_STAGES = { offer: 1, ongoing: 2, done: 3 } as const;
export type DialogueStage = keyof typeof DIALOGUE_STAGES;
const STAGE_NAMES: Record<DialogueStage, string> = {
  offer: 'de início',
  ongoing: 'de durante',
  done: 'de fim',
};

export const SPEAKERS = { npc: 1, tamer: 2, narration: 3 } as const;
export type DialogueSpeaker = keyof typeof SPEAKERS;
export const OUTCOMES = { accept: 1, decline: 2 } as const;
export type DialogueOutcome = keyof typeof OUTCOMES;

export interface DialogueSay {
  type: 'say';
  speaker: DialogueSpeaker;
  text: string;
}
export interface DialogueOption {
  text: string;
  outcome: DialogueOutcome | null;
  steps: DialogueStep[];
}
export interface DialogueChoice {
  type: 'choice';
  options: DialogueOption[];
}
export type DialogueStep = DialogueSay | DialogueChoice;
export type QuestDialogues = Record<DialogueStage, DialogueStep[]>;

export const emptyDialogues = (): QuestDialogues => ({
  offer: [],
  ongoing: [],
  done: [],
});

export const DIALOGUE_ERRORS = {
  shape: 'A conversa da missão é inválida.',
  scene: 'A cena do início é inválida.',
} as const;

const isRecord = (value: unknown): value is Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value);

class DialogueError extends Error {}

/**
 * Lê as conversas que o editor manda, sem confiar no formato, e confere os
 * limites. Os textos saem sem os espaços das pontas.
 */
export function parseDialogues(
  raw: unknown,
): { dialogues: QuestDialogues } | { error: string } {
  if (raw === undefined || raw === null) return { dialogues: emptyDialogues() };
  if (!isRecord(raw)) return { error: DIALOGUE_ERRORS.shape };
  const dialogues = emptyDialogues();
  try {
    for (const stage of Object.keys(DIALOGUE_STAGES) as DialogueStage[]) {
      const counter = { steps: 0 };
      dialogues[stage] = parseSteps(raw[stage] ?? [], stage, 0, counter);
      if (counter.steps > MAX_DIALOGUE_STEPS) {
        throw new DialogueError(
          `A conversa ${STAGE_NAMES[stage]} pode ter até ${MAX_DIALOGUE_STEPS} passos.`,
        );
      }
    }
  } catch (error) {
    if (error instanceof DialogueError) return { error: error.message };
    throw error;
  }
  return { dialogues };
}

function parseSteps(
  raw: unknown,
  stage: DialogueStage,
  depth: number,
  counter: { steps: number },
): DialogueStep[] {
  if (!Array.isArray(raw)) throw new DialogueError(DIALOGUE_ERRORS.shape);
  const where = `Na conversa ${STAGE_NAMES[stage]}`;
  return raw.map((step): DialogueStep => {
    if (!isRecord(step)) throw new DialogueError(DIALOGUE_ERRORS.shape);
    counter.steps += 1;
    if (step.type === 'say') {
      if (
        typeof step.speaker !== 'string' ||
        !(step.speaker in SPEAKERS) ||
        typeof step.text !== 'string'
      ) {
        throw new DialogueError(DIALOGUE_ERRORS.shape);
      }
      const text = step.text.trim();
      if (text.length === 0)
        throw new DialogueError(`${where}, uma fala está vazia.`);
      if (text.length > MAX_DIALOGUE_TEXT) {
        throw new DialogueError(
          `${where}, uma fala passa de ${MAX_DIALOGUE_TEXT} letras.`,
        );
      }
      return { type: 'say', speaker: step.speaker as DialogueSpeaker, text };
    }
    if (step.type !== 'choice' || !Array.isArray(step.options)) {
      throw new DialogueError(DIALOGUE_ERRORS.shape);
    }
    if (depth >= MAX_CHOICE_DEPTH) {
      throw new DialogueError(
        `${where}, há mais de ${MAX_CHOICE_DEPTH} escolhas uma dentro da outra.`,
      );
    }
    if (
      step.options.length < MIN_OPTIONS ||
      step.options.length > MAX_OPTIONS
    ) {
      throw new DialogueError(
        `${where}, uma escolha precisa de ${MIN_OPTIONS} a ${MAX_OPTIONS} opções.`,
      );
    }
    const options = step.options.map((option): DialogueOption => {
      if (!isRecord(option) || typeof option.text !== 'string') {
        throw new DialogueError(DIALOGUE_ERRORS.shape);
      }
      counter.steps += 1;
      const text = option.text.trim();
      if (text.length === 0) {
        throw new DialogueError(`${where}, uma opção está vazia.`);
      }
      if (text.length > MAX_OPTION_TEXT) {
        throw new DialogueError(
          `${where}, uma opção passa de ${MAX_OPTION_TEXT} letras.`,
        );
      }
      const outcome = option.outcome ?? null;
      if (outcome !== null) {
        if (typeof outcome !== 'string' || !(outcome in OUTCOMES)) {
          throw new DialogueError(DIALOGUE_ERRORS.shape);
        }
        if (stage !== 'offer') {
          throw new DialogueError(
            'Só a conversa de início aceita ou recusa a missão.',
          );
        }
      }
      return {
        text,
        outcome: outcome as DialogueOutcome | null,
        steps: parseSteps(option.steps ?? [], stage, depth + 1, counter),
      };
    });
    return { type: 'choice', options };
  });
}

/** A cena do início: vazia vira nula; senão, o slug de uma cena. */
export function parseOfferScene(
  raw: unknown,
): { scene: string | null } | { error: string } {
  if (raw === undefined || raw === null || raw === '') return { scene: null };
  if (
    typeof raw !== 'string' ||
    raw.length > MAX_SCENE_SLUG ||
    !/^[a-z0-9_]+$/.test(raw)
  ) {
    return { error: DIALOGUE_ERRORS.scene };
  }
  return { scene: raw };
}

/** Uma linha de `quest_dialogue_steps`, com as opções da escolha. */
export interface DialogueStepRow {
  id: number;
  stage: number;
  optionId: number | null;
  position: number;
  kind: number;
  speaker: number | null;
  text: string | null;
}
export interface DialogueOptionRow {
  id: number;
  stepId: number;
  position: number;
  text: string;
  outcome: number | null;
}

const SPEAKER_BY_ID = Object.fromEntries(
  Object.entries(SPEAKERS).map(([slug, id]) => [id, slug]),
) as Record<number, DialogueSpeaker>;
const OUTCOME_BY_ID = Object.fromEntries(
  Object.entries(OUTCOMES).map(([slug, id]) => [id, slug]),
) as Record<number, DialogueOutcome>;

/** Monta a árvore das conversas a partir das linhas do banco. */
export function dialoguesFromRows(
  steps: DialogueStepRow[],
  options: DialogueOptionRow[],
): QuestDialogues {
  const byPosition = <T extends { position: number }>(a: T, b: T) =>
    a.position - b.position;
  const stepsUnder = new Map<number | null, DialogueStepRow[]>();
  for (const stage of Object.values(DIALOGUE_STAGES)) {
    stepsUnder.set(-stage, []);
  }
  for (const step of steps) {
    const key = step.optionId ?? -step.stage;
    stepsUnder.set(key, [...(stepsUnder.get(key) ?? []), step]);
  }
  const optionsOf = new Map<number, DialogueOptionRow[]>();
  for (const option of options) {
    optionsOf.set(option.stepId, [
      ...(optionsOf.get(option.stepId) ?? []),
      option,
    ]);
  }
  const build = (key: number): DialogueStep[] =>
    [...(stepsUnder.get(key) ?? [])].sort(byPosition).map((step) =>
      step.kind === 1
        ? {
            type: 'say',
            speaker: SPEAKER_BY_ID[step.speaker ?? SPEAKERS.npc],
            text: step.text ?? '',
          }
        : {
            type: 'choice',
            options: [...(optionsOf.get(step.id) ?? [])]
              .sort(byPosition)
              .map((option) => ({
                text: option.text,
                outcome:
                  option.outcome === null
                    ? null
                    : OUTCOME_BY_ID[option.outcome],
                steps: build(option.id),
              })),
          },
    );
  return {
    offer: build(-DIALOGUE_STAGES.offer),
    ongoing: build(-DIALOGUE_STAGES.ongoing),
    done: build(-DIALOGUE_STAGES.done),
  };
}

/** Os passos de uma conversa como linhas a gravar, de cima para baixo. */
export interface DialogueStepWrite {
  stage: number;
  position: number;
  kind: number;
  speaker: number | null;
  text: string | null;
  options: {
    position: number;
    text: string;
    outcome: number | null;
    steps: DialogueStepWrite[];
  }[];
}

export function dialogueWrites(dialogues: QuestDialogues): DialogueStepWrite[] {
  const toWrites = (
    stage: number,
    steps: DialogueStep[],
  ): DialogueStepWrite[] =>
    steps.map((step, index) =>
      step.type === 'say'
        ? {
            stage,
            position: index + 1,
            kind: 1,
            speaker: SPEAKERS[step.speaker],
            text: step.text,
            options: [],
          }
        : {
            stage,
            position: index + 1,
            kind: 2,
            speaker: null,
            text: null,
            options: step.options.map((option, at) => ({
              position: at + 1,
              text: option.text,
              outcome:
                option.outcome === null ? null : OUTCOMES[option.outcome],
              steps: toWrites(stage, option.steps),
            })),
          },
    );
  return (Object.keys(DIALOGUE_STAGES) as DialogueStage[]).flatMap((stage) =>
    toWrites(DIALOGUE_STAGES[stage], dialogues[stage]),
  );
}

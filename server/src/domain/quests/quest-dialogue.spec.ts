import { describe, expect, it } from 'vitest';
import {
  dialoguesFromRows,
  dialogueWrites,
  parseDialogues,
  parseOfferScene,
  type DialogueOptionRow,
  type DialogueStepRow,
  type DialogueStepWrite,
  type QuestDialogues,
} from './quest-dialogue.js';

const say = (text: string, speaker = 'npc') => ({ type: 'say', speaker, text });
const choice = (...options: unknown[]) => ({ type: 'choice', options });
const option = (text: string, steps: unknown[] = [], outcome?: string) => ({
  text,
  steps,
  ...(outcome ? { outcome } : {}),
});

function errorOf(raw: unknown): string {
  const result = parseDialogues(raw);
  return 'error' in result ? result.error : '';
}

describe('parseDialogues', () => {
  it('sem conversas, as três vêm vazias', () => {
    expect(parseDialogues(undefined)).toEqual({
      dialogues: { offer: [], ongoing: [], done: [] },
    });
  });

  it('lê falas e escolhas e tira os espaços das pontas', () => {
    const result = parseDialogues({
      offer: [
        say('  Pode me ajudar? '),
        choice(
          option('Claro', [], 'accept'),
          option('Agora não', [say('Tudo bem.')], 'decline'),
        ),
      ],
      ongoing: [say('Cadê meu item!!!', 'tamer')],
    });
    expect(result).toEqual({
      dialogues: {
        offer: [
          { type: 'say', speaker: 'npc', text: 'Pode me ajudar?' },
          {
            type: 'choice',
            options: [
              { text: 'Claro', outcome: 'accept', steps: [] },
              {
                text: 'Agora não',
                outcome: 'decline',
                steps: [{ type: 'say', speaker: 'npc', text: 'Tudo bem.' }],
              },
            ],
          },
        ],
        ongoing: [{ type: 'say', speaker: 'tamer', text: 'Cadê meu item!!!' }],
        done: [],
      },
    });
  });

  it('recusa fala vazia e fala longa', () => {
    expect(errorOf({ done: [say('   ')] })).toBe(
      'Na conversa de fim, uma fala está vazia.',
    );
    expect(errorOf({ done: [say('a'.repeat(301))] })).toBe(
      'Na conversa de fim, uma fala passa de 300 letras.',
    );
  });

  it('a escolha tem de 2 a 4 opções, de 1 a 40 letras', () => {
    expect(errorOf({ ongoing: [choice(option('Sim'))] })).toBe(
      'Na conversa de durante, uma escolha precisa de 2 a 4 opções.',
    );
    expect(
      errorOf({
        ongoing: [choice(...['a', 'b', 'c', 'd', 'e'].map((t) => option(t)))],
      }),
    ).toBe('Na conversa de durante, uma escolha precisa de 2 a 4 opções.');
    expect(errorOf({ ongoing: [choice(option(' '), option('Não'))] })).toBe(
      'Na conversa de durante, uma opção está vazia.',
    );
    expect(
      errorOf({ ongoing: [choice(option('a'.repeat(41)), option('Não'))] }),
    ).toBe('Na conversa de durante, uma opção passa de 40 letras.');
  });

  it('aceita 3 escolhas uma dentro da outra, não 4', () => {
    const nest = (depth: number): unknown =>
      depth === 0
        ? say('fim')
        : choice(option('a', [nest(depth - 1)]), option('b'));
    expect(errorOf({ offer: [nest(3)] })).toBe('');
    expect(errorOf({ offer: [nest(4)] })).toBe(
      'Na conversa de início, há mais de 3 escolhas uma dentro da outra.',
    );
  });

  it('conta os passos e as opções até 40', () => {
    expect(
      errorOf({ offer: Array.from({ length: 40 }, () => say('oi')) }),
    ).toBe('');
    expect(
      errorOf({ offer: Array.from({ length: 41 }, () => say('oi')) }),
    ).toBe('A conversa de início pode ter até 40 passos.');
    const withOptions = [
      ...Array.from({ length: 38 }, () => say('oi')),
      choice(option('a'), option('b')),
    ];
    expect(errorOf({ offer: withOptions })).toBe(
      'A conversa de início pode ter até 40 passos.',
    );
  });

  it('só o início aceita ou recusa', () => {
    expect(
      errorOf({ done: [choice(option('a', [], 'accept'), option('b'))] }),
    ).toBe('Só a conversa de início aceita ou recusa a missão.');
  });

  it('recusa o formato errado', () => {
    expect(errorOf([])).toBe('A conversa da missão é inválida.');
    expect(errorOf({ offer: [{ type: 'move' }] })).toBe(
      'A conversa da missão é inválida.',
    );
    expect(errorOf({ offer: [say('oi', 'mira')] })).toBe(
      'A conversa da missão é inválida.',
    );
    expect(
      errorOf({ offer: [choice(option('a', [], 'talvez'), option('b'))] }),
    ).toBe('A conversa da missão é inválida.');
  });
});

describe('parseOfferScene', () => {
  it('vazia vira nula, e o slug passa', () => {
    expect(parseOfferScene('')).toEqual({ scene: null });
    expect(parseOfferScene(null)).toEqual({ scene: null });
    expect(parseOfferScene('mira_pede_ajuda')).toEqual({
      scene: 'mira_pede_ajuda',
    });
  });

  it('recusa um slug fora de [a-z0-9_] ou longo', () => {
    expect(parseOfferScene('Mira')).toEqual({
      error: 'A cena do início é inválida.',
    });
    expect(parseOfferScene('a'.repeat(65))).toEqual({
      error: 'A cena do início é inválida.',
    });
  });
});

/** Grava as linhas como o banco faria, com ids em ordem, e lê de volta. */
function roundTrip(dialogues: QuestDialogues): QuestDialogues {
  const steps: DialogueStepRow[] = [];
  const options: DialogueOptionRow[] = [];
  const save = (writes: DialogueStepWrite[], optionId: number | null) => {
    for (const write of writes) {
      const id = steps.length + options.length + 1;
      steps.push({ id, optionId, ...write });
      for (const option of write.options) {
        const optionRowId = steps.length + options.length + 1;
        options.push({ id: optionRowId, stepId: id, ...option });
        save(option.steps, optionRowId);
      }
    }
  };
  save(dialogueWrites(dialogues), null);
  return dialoguesFromRows(steps.reverse(), options.reverse());
}

describe('dialogueWrites e dialoguesFromRows', () => {
  it('a árvore volta igual depois de virar linhas', () => {
    const parsed = parseDialogues({
      offer: [
        say('Pode me ajudar?'),
        choice(
          option('Claro', [say('Obrigado!', 'narration')], 'accept'),
          option('Talvez', [
            choice(option('Sim', [], 'accept'), option('Não', [], 'decline')),
          ]),
        ),
      ],
      ongoing: [
        say('Encontrou?'),
        choice(option('Sim', [say('Não é isso.')]), option('Não')),
      ],
      done: [say('Muito obrigado!'), say('Valeu', 'tamer')],
    });
    if (!('dialogues' in parsed)) throw new Error('inválida');
    expect(roundTrip(parsed.dialogues)).toEqual(parsed.dialogues);
  });
});

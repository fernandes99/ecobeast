import { PendingChoice, ProgressionStore } from './progression.store.js';

const TWO_HOURS = 2 * 60 * 60 * 1000;

function choice(pendingSkillIds: number[] = [5]): PendingChoice {
  return {
    evolutionSpeciesId: null,
    levelBefore: 10,
    levelAfter: 11,
    pendingSkillIds,
  };
}

describe('ProgressionStore', () => {
  let now: number;
  let store: ProgressionStore;

  beforeEach(() => {
    now = 1_000;
    store = new ProgressionStore(() => now);
  });

  it('sem escolhas, não devolve nada', () => {
    expect(store.get('ana', 'c1')).toBeUndefined();
  });

  it('guarda as escolhas de cada jogador por Ecobeast', () => {
    store.replace('ana', new Map([['c1', choice([5])]]));
    store.replace('bia', new Map([['c1', choice([6])]]));

    expect(store.get('ana', 'c1')?.pendingSkillIds).toEqual([5]);
    expect(store.get('bia', 'c1')?.pendingSkillIds).toEqual([6]);
  });

  it('uma luta nova substitui todas as escolhas do jogador', () => {
    store.replace(
      'ana',
      new Map([
        ['c1', choice()],
        ['c2', choice()],
      ]),
    );
    store.replace('ana', new Map([['c2', choice([7])]]));

    expect(store.get('ana', 'c1')).toBeUndefined();
    expect(store.get('ana', 'c2')?.pendingSkillIds).toEqual([7]);
  });

  it('uma luta sem escolhas apaga as anteriores', () => {
    store.replace('ana', new Map([['c1', choice()]]));
    store.replace('ana', new Map());

    expect(store.get('ana', 'c1')).toBeUndefined();
  });

  it('update troca a escolha de um Ecobeast, e null a apaga', () => {
    store.replace('ana', new Map([['c1', choice([5, 6])]]));
    store.update('ana', 'c1', choice([6]));
    expect(store.get('ana', 'c1')?.pendingSkillIds).toEqual([6]);

    store.update('ana', 'c1', null);
    expect(store.get('ana', 'c1')).toBeUndefined();
  });

  it('continua guardada até pouco antes de 2 horas sem uso', () => {
    store.replace('ana', new Map([['c1', choice()]]));
    now += TWO_HOURS - 1;
    expect(store.get('ana', 'c1')).toBeDefined();
  });

  it('sai depois de 2 horas sem uso', () => {
    store.replace('ana', new Map([['c1', choice()]]));
    now += TWO_HOURS;
    expect(store.get('ana', 'c1')).toBeUndefined();
  });

  it('cada uso conta de novo as 2 horas', () => {
    store.replace('ana', new Map([['c1', choice([5, 6])]]));
    now += TWO_HOURS - 1;
    store.update('ana', 'c1', choice([6]));
    now += TWO_HOURS - 1;
    expect(store.get('ana', 'c1')).toBeDefined();
  });
});

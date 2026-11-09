import { ExplorationStore, StoredExploration } from './exploration.store.js';

const TWO_HOURS = 2 * 60 * 60 * 1000;

function exploration(q = 0): StoredExploration {
  return {
    spawns: new Map(),
    tamers: new Map(),
    position: { q, r: 0 },
    positionAt: 0,
  };
}

describe('ExplorationStore', () => {
  let now: number;
  let store: ExplorationStore;

  beforeEach(() => {
    now = 1_000;
    store = new ExplorationStore(() => now);
  });

  it('sem exploração, não devolve nada', () => {
    expect(store.get('ana')).toBeUndefined();
  });

  it('guarda uma exploração por jogador', () => {
    store.set('ana', exploration(1));
    store.set('bia', exploration(2));

    expect(store.get('ana')?.position.q).toBe(1);
    expect(store.get('bia')?.position.q).toBe(2);
  });

  it('uma exploração nova substitui a anterior', () => {
    store.set('ana', exploration(1));
    store.set('ana', exploration(2));

    expect(store.get('ana')?.position.q).toBe(2);
  });

  it('continua guardada até pouco antes de 2 horas sem uso', () => {
    store.set('ana', exploration());
    now += TWO_HOURS - 1;

    expect(store.get('ana')).toBeDefined();
  });

  it('sai depois de 2 horas sem uso', () => {
    store.set('ana', exploration());
    now += TWO_HOURS;

    expect(store.get('ana')).toBeUndefined();
  });

  it('gravar de novo conta como uso', () => {
    store.set('ana', exploration());
    now += TWO_HOURS - 1;
    store.set('ana', exploration());
    now += TWO_HOURS - 1;

    expect(store.get('ana')).toBeDefined();
  });

  it('gravar de um jogador tira as vencidas dos outros', () => {
    store.set('ana', exploration());
    now += TWO_HOURS;
    store.set('bia', exploration());

    expect(store.get('ana')).toBeUndefined();
  });

  it('delete encerra a exploração do jogador, e só a dele', () => {
    store.set('ana', exploration(1));
    store.set('bia', exploration(2));
    store.delete('ana');
    expect(store.get('ana')).toBeUndefined();
    expect(store.get('bia')?.position.q).toBe(2);
  });
});

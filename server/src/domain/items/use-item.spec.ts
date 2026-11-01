import {
  CANNOT_REVIVE,
  CANNOT_USE,
  NO_EFFECT,
  resolveItem,
} from './use-item.js';

const TONIC = { healAmount: 20, curesStatus: false };
const BALM = { healAmount: null, curesStatus: true };
const FULL_RESTORE = { healAmount: 60, curesStatus: true };
const SPHERE = { healAmount: null, curesStatus: false };
const HURT = { currentHp: 10, maxHp: 50, hasStatus: false };

describe('resolveItem', () => {
  it('cura tudo o que o item promete, se couber', () => {
    expect(resolveItem(TONIC, HURT)).toEqual({
      healed: 20,
      curesStatus: false,
    });
  });

  it('não passa do HP máximo', () => {
    expect(resolveItem(TONIC, { ...HURT, currentHp: 45 })).toEqual({
      healed: 5,
      curesStatus: false,
    });
  });

  it('com HP cheio, não teria efeito', () => {
    expect(resolveItem(TONIC, { ...HURT, currentHp: 50 })).toEqual({
      error: NO_EFFECT,
    });
  });

  it('Tônico não tira status: com HP cheio e status, não teria efeito', () => {
    expect(
      resolveItem(TONIC, { ...HURT, currentHp: 50, hasStatus: true }),
    ).toEqual({ error: NO_EFFECT });
  });

  it('o Bálsamo tira o status, sem curar HP', () => {
    expect(resolveItem(BALM, { ...HURT, hasStatus: true })).toEqual({
      healed: 0,
      curesStatus: true,
    });
  });

  it('o Bálsamo sem status não teria efeito', () => {
    expect(resolveItem(BALM, HURT)).toEqual({ error: NO_EFFECT });
  });

  it('um item de cura e status vale mesmo com HP cheio', () => {
    expect(
      resolveItem(FULL_RESTORE, { ...HURT, currentHp: 50, hasStatus: true }),
    ).toEqual({ healed: 0, curesStatus: true });
  });

  it('um item de cura e status em quem não tem status só cura', () => {
    expect(resolveItem(FULL_RESTORE, HURT)).toEqual({
      healed: 40,
      curesStatus: false,
    });
  });

  it('ninguém usa item em um Ecobeast com 0 HP', () => {
    const fainted = { ...HURT, currentHp: 0, hasStatus: true };
    expect(resolveItem(TONIC, fainted)).toEqual({ error: CANNOT_REVIVE });
    expect(resolveItem(BALM, fainted)).toEqual({ error: CANNOT_REVIVE });
  });

  it('um item sem efeito de uso não pode ser usado, nem em quem tem 0 HP', () => {
    expect(resolveItem(SPHERE, HURT)).toEqual({ error: CANNOT_USE });
    expect(resolveItem(SPHERE, { ...HURT, currentHp: 0 })).toEqual({
      error: CANNOT_USE,
    });
  });
});

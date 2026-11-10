import type { BattleEvent } from '../battle/types.js';
import { enemySpeciesEntered, uniqueIds } from './codex.js';

const RUVO = 1;
const NILU = 4;
const ELU = 7;

function entered(side: 'player' | 'enemy', speciesId: number): BattleEvent {
  return {
    type: 'creature_entered',
    side,
    position: 0,
    team_index: 0,
    species_id: speciesId,
    level: 5,
    max_hp: 20,
    hp: 20,
    status: null,
  };
}

describe('enemySpeciesEntered', () => {
  it('lista as espécies inimigas que entraram em campo, na ordem', () => {
    const events: BattleEvent[] = [
      { type: 'battle_started' },
      entered('enemy', NILU),
      entered('enemy', RUVO),
    ];
    expect(enemySpeciesEntered(events)).toEqual([NILU, RUVO]);
  });

  it('ignora os Ecobeasts do jogador', () => {
    const events = [entered('player', ELU), entered('enemy', NILU)];
    expect(enemySpeciesEntered(events)).toEqual([NILU]);
  });

  it('conta uma vez a espécie que entrou mais de uma vez', () => {
    const events = [entered('enemy', RUVO), entered('enemy', RUVO)];
    expect(enemySpeciesEntered(events)).toEqual([RUVO]);
  });

  it('sem entradas inimigas, a lista é vazia', () => {
    expect(enemySpeciesEntered([{ type: 'battle_started' }])).toEqual([]);
  });
});

describe('uniqueIds', () => {
  it('tira as repetições e mantém a ordem da primeira vez', () => {
    expect(uniqueIds([ELU, RUVO, ELU, NILU, RUVO])).toEqual([ELU, RUVO, NILU]);
  });
});

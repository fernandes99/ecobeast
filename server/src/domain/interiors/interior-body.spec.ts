import { describe, expect, it } from 'vitest';
import { type InteriorBody, interiorError } from './interior-body.js';

const known = { npcIds: new Set([3]), actionTypeIds: new Set([1]) };

function room(change: (body: InteriorBody) => void = () => {}): InteriorBody {
  const body: InteriorBody = {
    name: 'Sala',
    width: 6,
    height: 5,
    door: { x: 3, y: 4 },
    tiles: [],
    objects: [],
    blocks: [],
    npcs: [],
  };
  for (let y = 0; y < 5; y++) {
    for (let x = 0; x < 6; x++) {
      body.tiles.push({ layer: 'floor', x, y, sheet: 'walls_floor', col: 4, row: 9 });
    }
  }
  change(body);
  return body;
}

const npc = { npc_id: 3, x: 1, y: 1, dialogue: 'Olá!', action_type_id: 1 };

describe('interiorError', () => {
  it('aceita a sala válida', () => {
    expect(interiorError(room((b) => b.npcs.push({ ...npc })), known)).toBeNull();
  });

  it('aceita a parede na porta, porque a parede não bloqueia sozinha', () => {
    const body = room((b) =>
      b.tiles.push({ layer: 'wall', x: 3, y: 4, sheet: 'walls_floor', col: 1, row: 0 }),
    );
    expect(interiorError(body, known)).toBeNull();
  });

  it('recusa o nome vazio ou longo', () => {
    expect(interiorError(room((b) => (b.name = '')), known)).toBe(
      'O nome precisa ter de 1 a 40 caracteres.',
    );
    expect(interiorError(room((b) => (b.name = 'a'.repeat(41))), known)).toBe(
      'O nome precisa ter de 1 a 40 caracteres.',
    );
  });

  it('recusa a sala menor que 4 ou maior que 64', () => {
    const message = 'A largura e a altura vão de 4 a 64 quadrados.';
    expect(interiorError(room((b) => (b.width = 3)), known)).toBe(message);
    expect(interiorError(room((b) => (b.height = 65)), known)).toBe(message);
  });

  it('recusa mais de 16.384 tiles, 1.000 objetos ou 50 NPCs', () => {
    const tiles = room((b) => {
      b.tiles = Array.from({ length: 16_385 }, () => b.tiles[0]!);
    });
    expect(interiorError(tiles, known)).toBe('A sala pode ter até 16.384 tiles.');
    const objects = room((b) => {
      b.objects = Array.from({ length: 1_001 }, () => ({
        x: 0, y: 0, sheet: 'interior', col: 0, row: 0, width: 1, height: 1,
      }));
    });
    expect(interiorError(objects, known)).toBe('A sala pode ter até 1.000 objetos.');
    const npcs = room((b) => {
      b.npcs = Array.from({ length: 51 }, () => ({ ...npc }));
    });
    expect(interiorError(npcs, known)).toBe('A sala pode ter até 50 NPCs.');
  });

  it('recusa um tile de camada, folha ou posição inválida', () => {
    const message = 'Há um tile inválido.';
    expect(interiorError(room((b) => (b.tiles[0]!.layer = 'roof')), known)).toBe(message);
    expect(interiorError(room((b) => (b.tiles[0]!.sheet = 'Walls')), known)).toBe(message);
    expect(interiorError(room((b) => (b.tiles[0]!.col = 64)), known)).toBe(message);
    expect(interiorError(room((b) => (b.tiles[0]!.row = -1)), known)).toBe(message);
  });

  it('recusa um tile fora da sala', () => {
    expect(interiorError(room((b) => (b.tiles[0]!.x = 6)), known)).toBe(
      'Há um tile fora da sala.',
    );
  });

  it('recusa dois tiles no mesmo quadrado e camada', () => {
    expect(interiorError(room((b) => b.tiles.push({ ...b.tiles[0]! })), known)).toBe(
      'Há dois tiles no mesmo quadrado e camada.',
    );
  });

  it('recusa um objeto inválido', () => {
    const object = { x: 0, y: 0, sheet: 'interior', col: 0, row: 0, width: 9, height: 1 };
    expect(interiorError(room((b) => b.objects.push(object)), known)).toBe(
      'Há um objeto inválido.',
    );
  });

  it('recusa um objeto que passa da borda', () => {
    const object = { x: 5, y: 0, sheet: 'interior', col: 0, row: 0, width: 2, height: 1 };
    expect(interiorError(room((b) => b.objects.push(object)), known)).toBe(
      'Há um objeto que passa da borda da sala.',
    );
  });

  it('recusa um bloqueio fora da sala ou repetido', () => {
    expect(interiorError(room((b) => b.blocks.push({ x: 0, y: 5 })), known)).toBe(
      'Há um bloqueio fora da sala.',
    );
    expect(
      interiorError(room((b) => b.blocks.push({ x: 0, y: 0 }, { x: 0, y: 0 })), known),
    ).toBe('Há um bloqueio repetido.');
  });

  it('recusa a fala longa', () => {
    const body = room((b) => b.npcs.push({ ...npc, dialogue: 'a'.repeat(2_001) }));
    expect(interiorError(body, known)).toBe('A fala do NPC pode ter até 2.000 caracteres.');
  });

  it('recusa o NPC que não existe e a ação que não existe', () => {
    expect(interiorError(room((b) => b.npcs.push({ ...npc, npc_id: 99 })), known)).toBe(
      'Esse NPC não existe.',
    );
    expect(
      interiorError(room((b) => b.npcs.push({ ...npc, action_type_id: 99 })), known),
    ).toBe('O NPC tem uma ação que não existe.');
  });

  it('recusa o NPC fora da sala, sem chão, bloqueado, na porta ou junto de outro', () => {
    const message = 'O NPC precisa de um quadrado livre.';
    expect(interiorError(room((b) => b.npcs.push({ ...npc, x: 6 })), known)).toBe(message);
    const noFloor = room((b) => {
      b.tiles = b.tiles.filter(({ x, y }) => !(x === 1 && y === 1));
      b.npcs.push({ ...npc });
    });
    expect(interiorError(noFloor, known)).toBe(message);
    const blocked = room((b) => {
      b.blocks.push({ x: 1, y: 1 });
      b.npcs.push({ ...npc });
    });
    expect(interiorError(blocked, known)).toBe(message);
    expect(interiorError(room((b) => b.npcs.push({ ...npc, x: 3, y: 4 })), known)).toBe(
      message,
    );
    expect(interiorError(room((b) => b.npcs.push({ ...npc }, { ...npc })), known)).toBe(
      message,
    );
  });

  it('recusa a porta fora da sala, sem chão ou bloqueada', () => {
    const message = 'A porta precisa estar num quadrado de chão, sem bloqueio.';
    expect(interiorError(room((b) => (b.door = { x: 6, y: 4 })), known)).toBe(message);
    const noFloor = room((b) => {
      b.tiles = b.tiles.filter(({ x, y }) => !(x === 3 && y === 4));
    });
    expect(interiorError(noFloor, known)).toBe(message);
    expect(interiorError(room((b) => b.blocks.push({ x: 3, y: 4 })), known)).toBe(message);
  });
});

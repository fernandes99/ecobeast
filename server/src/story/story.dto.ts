import { ApiProperty } from '@nestjs/swagger';

export const MAX_MARKS_PER_CALL = 50;
export const MAX_MARKS = 2000;
export const MARK_PATTERN = /^[a-z0-9_]{1,48}$/;
export const MARK_LENGTH = 48;
export const MARKS_PER_CALL_MESSAGE = `Mande de 1 a ${MAX_MARKS_PER_CALL} Marcos por vez.`;
export const MAX_MARKS_MESSAGE = 'O Domador pode ter até 2.000 Marcos.';

export function invalidMarkMessage(value: unknown): string {
  const text =
    typeof value === 'string' ? value : (JSON.stringify(value) ?? '');
  return `O Marco "${text.slice(0, MARK_LENGTH)}" tem caracteres inválidos.`;
}

export class StoryMarksBodyDto {
  @ApiProperty({
    description:
      `De 1 a ${MAX_MARKS_PER_CALL} Marcos, cada um com letras minúsculas, ` +
      'números e `_`, até 48 caracteres.',
    example: ['avo_chega', 'sabe_da_mira'],
  })
  marks: string[];
}

export class StoryMarksResponseDto {
  @ApiProperty({
    description:
      'Todos os Marcos do Domador depois de ligar, em ordem alfabética.',
    example: ['avo_chega', 'sabe_da_mira'],
  })
  story_marks: string[];
}

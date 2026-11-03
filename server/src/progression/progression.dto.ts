import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsInt, ValidateIf } from 'class-validator';
import { CreatureDto } from '../player/player.dto.js';

export const INVALID_CHOICE = 'Escolha inválida.';

export class EvolutionBodyDto {
  @ApiProperty({
    description:
      'true evolui; false cancela, e a oferta volta no próximo nível.',
    example: true,
  })
  @IsBoolean({ message: INVALID_CHOICE })
  accept: boolean;
}

export class LearnSkillBodyDto {
  @ApiProperty({ description: 'A Técnica pendente.', example: 6 })
  @IsInt({ message: INVALID_CHOICE })
  skill_id: number;

  @ApiProperty({
    description:
      'A Técnica que ele esquece para dar lugar à nova. `null` não aprende a nova, e ela não volta a ser oferecida.',
    type: 'integer',
    nullable: true,
    example: 1,
  })
  @ValidateIf((body: LearnSkillBodyDto) => body.forget_skill_id !== null)
  @IsInt({ message: INVALID_CHOICE })
  forget_skill_id: number | null;
}

export class EvolutionResponseDto {
  @ApiProperty({ type: () => CreatureDto })
  creature: CreatureDto;

  @ApiProperty({
    description: 'Técnicas aprendidas com vaga, já gravadas.',
    type: [Number],
    example: [6],
  })
  learned_skill_ids: number[];

  @ApiProperty({
    description: 'Técnicas que esperam a escolha do jogador.',
    type: [Number],
    example: [],
  })
  pending_skill_ids: number[];
}

export class LearnSkillResponseDto {
  @ApiProperty({ type: () => CreatureDto })
  creature: CreatureDto;

  @ApiProperty({
    description: 'As Técnicas que ainda esperam a escolha do jogador.',
    type: [Number],
    example: [],
  })
  pending_skill_ids: number[];
}

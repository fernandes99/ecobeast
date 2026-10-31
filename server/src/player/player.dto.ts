import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsString } from 'class-validator';
import type { StatBlock } from '../domain/rules/types.js';

export const INVALID_NAME = 'Use de 2 a 16 letras, números ou espaços.';

export class CreatePlayerBodyDto {
  @ApiProperty({
    description:
      'Nome do Domador. Espaços nas pontas saem e espaços repetidos viram um; depois, de 2 a 16 letras, números ou espaços.',
    example: 'Ana Maria',
  })
  @IsString({ message: INVALID_NAME })
  name: string;
}

export class ChooseStarterBodyDto {
  @ApiProperty({ description: 'Id da espécie inicial.', example: 1 })
  @IsInt({ message: '`species_id` deve ser um número inteiro.' })
  species_id: number;
}

export class SetNicknameBodyDto {
  @ApiProperty({
    description:
      'Apelido do Ecobeast, com as regras do nome do Domador. Vazio remove o apelido.',
    example: 'Chama Viva',
  })
  @IsString({ message: INVALID_NAME })
  nickname: string;
}

/** Os 6 stats, para a documentação dos campos `stats`, `genes` e `training_points`. */
const STAT_BLOCK = {
  type: 'object',
  properties: {
    hp: { type: 'integer' },
    atk: { type: 'integer' },
    def: { type: 'integer' },
    sp_atk: { type: 'integer' },
    sp_def: { type: 'integer' },
    spd: { type: 'integer' },
  },
} as const;

export class SkillSlotDto {
  @ApiProperty({ example: 1 })
  skill_id: number;

  @ApiProperty({ description: 'PP restante.', example: 35 })
  current_pp: number;
}

export class CreatureDto {
  @ApiProperty({ example: '0b5c2f4e-8d1a-4c3b-9e7f-1a2b3c4d5e6f' })
  uid: string;

  @ApiProperty({ example: 1 })
  species_id: number;

  @ApiProperty({ description: 'Vazio se não tem apelido.', example: '' })
  nickname: string;

  @ApiProperty({ example: 5 })
  level: number;

  @ApiProperty({ description: 'XP total acumulado.', example: 125 })
  current_xp: number;

  @ApiProperty({
    description: 'XP total para chegar ao nível atual.',
    example: 125,
  })
  level_xp: number;

  @ApiProperty({
    description: 'XP total para chegar ao próximo nível. Nulo no nível máximo.',
    type: 'integer',
    nullable: true,
    example: 216,
  })
  next_level_xp: number | null;

  @ApiProperty({ example: 19 })
  current_hp: number;

  @ApiProperty({
    ...STAT_BLOCK,
    description: 'Calculado pelo servidor a cada resposta.',
    example: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 11 },
  })
  stats: StatBlock;

  @ApiProperty({
    ...STAT_BLOCK,
    description: 'De 0 a 31 por stat.',
    example: { hp: 12, atk: 30, def: 4, sp_atk: 19, sp_def: 27, spd: 8 },
  })
  genes: StatBlock;

  @ApiProperty({
    ...STAT_BLOCK,
    description: 'Pontos de Treino, de 0 a 252 por stat.',
    example: { hp: 0, atk: 0, def: 0, sp_atk: 0, sp_def: 0, spd: 0 },
  })
  training_points: StatBlock;

  @ApiProperty({ example: 3 })
  temperament_id: number;

  @ApiProperty({ example: 1 })
  trait_id: number;

  @ApiProperty({ enum: ['male', 'female', 'none'], example: 'male' })
  gender: string;

  @ApiProperty({ example: false })
  is_prismatic: boolean;

  @ApiProperty({ description: 'De 0 a 255.', example: 70 })
  bond: number;

  @ApiProperty({
    description: 'De 1 a 4 Técnicas, na ordem dos slots.',
    type: () => [SkillSlotDto],
  })
  skills: SkillSlotDto[];

  @ApiProperty({ type: 'integer', nullable: true, example: null })
  status_condition_id: number | null;

  @ApiProperty({ type: 'integer', nullable: true, example: null })
  held_item_id: number | null;

  @ApiProperty({ example: '5b1d2c9e-1111-4222-8333-444455556666' })
  original_player_id: string;

  @ApiProperty({
    description: 'ISO 8601 em UTC.',
    example: '2026-10-30T12:01:00.000Z',
  })
  caught_at: string;

  @ApiProperty({
    description: 'O inicial não tem zona.',
    type: 'integer',
    nullable: true,
    example: null,
  })
  caught_zone_id: number | null;
}

export class PlayerDto {
  @ApiProperty({
    description: 'O id do usuário no login.',
    example: '5b1d2c9e-1111-4222-8333-444455556666',
  })
  id: string;

  @ApiProperty({ example: 'Ana Maria' })
  name: string;

  @ApiProperty({ example: 1 })
  level: number;

  @ApiProperty({ example: 1000 })
  coins: number;

  @ApiProperty({
    description: 'ISO 8601 em UTC.',
    example: '2026-10-30T12:00:00.000Z',
  })
  created_at: string;

  @ApiProperty({
    description: 'A equipe, na ordem dos slots.',
    type: () => [CreatureDto],
  })
  party: CreatureDto[];
}

export class PlayerResponseDto {
  @ApiProperty({ type: () => PlayerDto })
  player: PlayerDto;
}

export class MaybePlayerResponseDto {
  @ApiProperty({
    description: 'Nulo se esta conta ainda não tem Domador.',
    type: () => PlayerDto,
    nullable: true,
  })
  player: PlayerDto | null;
}

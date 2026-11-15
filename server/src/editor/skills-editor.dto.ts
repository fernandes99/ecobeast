import { applyDecorators } from '@nestjs/common';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';
import type {
  SkillDraft,
  SkillEffectDraft,
  SkillLearnerDraft,
} from '../domain/skills/skill-draft.js';

function intRange(label: string, min: number, max?: number) {
  const message =
    max === undefined
      ? `${label} vai de ${min} para cima.`
      : `${label} vai de ${min} a ${max}.`;
  return applyDecorators(
    IsInt({ message: `${label} precisa ser um número inteiro.` }),
    Min(min, { message }),
    ...(max === undefined ? [] : [Max(max, { message })]),
  );
}

function id(label: string) {
  return IsInt({ message: `${label} precisa ser um id.` });
}

function flag(label: string) {
  return IsBoolean({ message: `${label} precisa ser verdadeiro ou falso.` });
}

export class SkillEffectDraftDto implements SkillEffectDraft {
  @ApiProperty({ description: 'Id em `effect_types`.', example: 1 })
  @id('O tipo do efeito')
  effect_type_id: number;

  @ApiProperty({ description: 'A chance, em %.', example: 30 })
  @intRange('A chance do efeito', 1, 100)
  chance: number;

  @ApiPropertyOptional({
    description: 'Id em `skill_targets`.',
    nullable: true,
  })
  @IsOptional()
  @id('O alvo do efeito')
  skill_target_id?: number | null;

  @ApiPropertyOptional({
    description: 'Id em `status_conditions`.',
    nullable: true,
  })
  @IsOptional()
  @id('O Estado do efeito')
  status_condition_id?: number | null;

  @ApiPropertyOptional({ description: 'Id em `stats`.', nullable: true })
  @IsOptional()
  @id('O atributo do efeito')
  stat_id?: number | null;

  @ApiPropertyOptional({ description: 'De −6 a 6, sem o 0.', nullable: true })
  @IsOptional()
  @intRange('Os estágios do efeito', -6, 6)
  stages?: number | null;

  @ApiPropertyOptional({ description: 'De 1 a 100.', nullable: true })
  @IsOptional()
  @intRange('O % do efeito', 1, 100)
  percent?: number | null;

  @ApiPropertyOptional({ description: '1 ou mais.', nullable: true })
  @IsOptional()
  @intRange('O valor do efeito', 1)
  value?: number | null;

  @ApiPropertyOptional({ description: '1 ou mais.', nullable: true })
  @IsOptional()
  @intRange('Os turnos do efeito', 1)
  min_turns?: number | null;
}

export class SkillLearnerDraftDto implements SkillLearnerDraft {
  @ApiProperty({ description: 'Id em `species`.', example: 1 })
  @id('O Ecobeast')
  species_id: number;

  @ApiProperty({ description: 'Id em `skill_learn_methods`.', example: 1 })
  @id('O método')
  skill_learn_method_id: number;

  @ApiPropertyOptional({
    description: 'Por nível, de 1 a 100; ao evoluir, 0; ensinável, nulo.',
    nullable: true,
    example: 7,
  })
  @IsOptional()
  @intRange('O nível', 0, 100)
  level?: number | null;
}

export class SkillDraftDto implements SkillDraft {
  @ApiPropertyOptional({
    description:
      'Só ao criar: `^[a-z0-9_]+$`, sem repetir. Ao salvar, é ignorado.',
    example: 'erupcao_solar',
  })
  @IsOptional()
  @IsString({ message: 'O slug precisa ser um texto.' })
  slug?: string;

  @ApiProperty({ example: 'Erupção Solar' })
  @IsString({ message: 'O nome precisa ser um texto.' })
  name: string;

  @ApiProperty({ example: 'Uma explosão de calor.' })
  @IsString({ message: 'A descrição precisa ser um texto.' })
  description: string;

  @ApiProperty({ description: 'Id em `elements`.', example: 2 })
  @id('O Elemento')
  element_id: number;

  @ApiProperty({ description: 'Id em `skill_categories`.', example: 2 })
  @id('A categoria')
  skill_category_id: number;

  @ApiProperty({ example: 120 })
  @intRange('O poder', 0, 250)
  power: number;

  @ApiProperty({ example: 85 })
  @intRange('A precisão', 0, 100)
  accuracy: number;

  @ApiProperty({ example: 5 })
  @intRange('O PP', 5, 40)
  max_pp: number;

  @ApiProperty({ example: 0 })
  @intRange('A prioridade', -7, 5)
  priority: number;

  @ApiProperty({ example: 0 })
  @intRange('O estágio de crítico', 0, 3)
  crit_stage: number;

  @ApiProperty({ description: 'Id em `skill_targets`.', example: 1 })
  @id('O alvo')
  skill_target_id: number;

  @ApiProperty({ example: false })
  @flag('Faz contato')
  makes_contact: boolean;

  @ApiProperty({ example: 1 })
  @intRange('O mínimo de golpes', 1, 10)
  min_hits: number;

  @ApiProperty({ example: 1 })
  @intRange('O máximo de golpes', 1, 10)
  max_hits: number;

  @ApiProperty({ description: 'Id em `area_shapes`.', example: 1 })
  @id('A área')
  area_shape_id: number;

  @ApiProperty({ example: 1 })
  @intRange('O alcance', 1, 6)
  range: number;

  @ApiProperty({ example: false })
  @flag('Atravessa')
  pierces: boolean;

  @ApiPropertyOptional({
    description: 'Id em `ground_effects`.',
    nullable: true,
  })
  @IsOptional()
  @id('A marca no chão')
  ground_effect_id?: number | null;

  @ApiPropertyOptional({
    description: 'De 1 a 20, junto com a marca no chão.',
    nullable: true,
  })
  @IsOptional()
  @intRange('Os turnos da marca no chão', 1, 20)
  ground_turns?: number | null;

  @ApiProperty({
    description: 'As rodadas de espera depois de usar.',
    example: 3,
  })
  @intRange('O countdown', 0, 5)
  cooldown: number;

  @ApiProperty({
    type: [SkillEffectDraftDto],
    description: 'Os efeitos, na ordem. O `sort_order` vem da posição.',
  })
  @IsArray({ message: 'Os efeitos precisam ser uma lista.' })
  @ValidateNested({ each: true })
  @Type(() => SkillEffectDraftDto)
  effects: SkillEffectDraftDto[];

  @ApiProperty({
    type: [SkillLearnerDraftDto],
    description: 'A lista inteira de quem aprende a Técnica.',
  })
  @IsArray({ message: 'Quem aprende precisa ser uma lista.' })
  @ValidateNested({ each: true })
  @Type(() => SkillLearnerDraftDto)
  learners: SkillLearnerDraftDto[];
}

export class SkillSavedResponseDto {
  @ApiProperty({ example: 41 })
  id: number;
}

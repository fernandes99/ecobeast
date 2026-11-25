import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString } from 'class-validator';
import { AppearanceDto } from '../player/player.dto.js';

export class NpcAppearanceResponseDto extends AppearanceDto {
  @ApiProperty({ description: 'Id do NPC (`npcs`).', example: 4 })
  id: number;
}

export class NpcVoiceBodyDto {
  @ApiProperty({ description: 'Id da voz (`voices`).', example: 3 })
  @IsInt({ message: '`voice_id` deve ser um número inteiro.' })
  voice_id: number;
}

export class NpcVoiceResponseDto {
  @ApiProperty({ description: 'Id do NPC (`npcs`).', example: 3 })
  id: number;

  @ApiProperty({ description: 'Id da voz (`voices`).', example: 3 })
  voice_id: number;
}

const text = (field: string) => ({
  message: `\`${field}\` deve ser um texto.`,
});

export class NpcUpdateBodyDto {
  @ApiProperty({
    description: 'O nome na caixa de fala, de 1 a 30 letras.',
    example: 'Dona Zélia',
  })
  @IsString(text('name'))
  name: string;

  @ApiProperty({
    description: 'Só para o editor, até 200 letras.',
    example: 'Vende flores na praça.',
  })
  @IsString(text('description'))
  description: string;

  @ApiProperty({
    description:
      'A fala que o NPC ganha ao ser posto no F2, até 2.000 letras; cada parágrafo é uma caixa.',
    example: 'Bom dia!\n\nQuer uma flor?',
  })
  @IsString(text('default_dialogue'))
  default_dialogue: string;

  @ApiPropertyOptional({
    description:
      'Só de NPC Ecobeast: o `slug` da espécie (`species`) cujas folhas de explorar ele usa.',
    example: 'puffcoo',
  })
  @IsOptional()
  @IsString(text('sprite'))
  sprite?: string;
}

export class NpcCreateBodyDto extends NpcUpdateBodyDto {
  @ApiPropertyOptional({
    description:
      'Só de NPC pessoa, no lugar de `sprite`: o corpo (`body_types`, os de criança também).',
    example: 2,
  })
  @IsOptional()
  @IsInt({ message: '`body_type_id` deve ser um número inteiro.' })
  body_type_id?: number;

  @ApiPropertyOptional({
    description: 'A voz (`voices`); sem ela, a Média.',
    example: 4,
  })
  @IsOptional()
  @IsInt({ message: '`voice_id` deve ser um número inteiro.' })
  voice_id?: number;
}

/** O NPC no formato da linha `npcs` do catálogo. */
export class NpcRowDto {
  @ApiProperty({ example: 20 })
  id: number;

  @ApiProperty({ example: 'dona_zelia' })
  slug: string;

  @ApiProperty({ example: 'Dona Zélia' })
  name: string;

  @ApiProperty({ example: 'Vende flores na praça.' })
  description: string;

  @ApiProperty({
    nullable: true,
    type: String,
    description: 'Nulo é NPC pessoa.',
    example: null,
  })
  sprite: string | null;

  @ApiProperty({ nullable: true, type: Number, example: 2 })
  body_type_id: number | null;

  @ApiProperty({ nullable: true, type: Number, example: 1 })
  skin_palette_id: number | null;

  @ApiProperty({ example: 4 })
  voice_id: number;

  @ApiProperty({ example: 'Bom dia!' })
  default_dialogue: string;
}

export class NpcDeleteResponseDto {
  @ApiProperty({ description: 'Id do NPC apagado.', example: 20 })
  id: number;
}

import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsArray, IsString } from 'class-validator';
import { CreatureDto } from '../player/player.dto.js';

export const INVALID_ORDER = 'Ordem inválida.';

const EXAMPLE_UID = '0b5c2f4e-8d1a-4c3b-9e7f-1a2b3c4d5e6f';

export class StorageResponseDto {
  @ApiProperty({
    description: 'O Santuário, dos capturados mais recentes para os antigos.',
    type: () => [CreatureDto],
  })
  creatures: CreatureDto[];
}

export class TeamOrderBodyDto {
  @ApiProperty({
    description: 'Todos os Ecobeasts da equipe, na ordem nova.',
    example: [EXAMPLE_UID],
  })
  @IsArray({ message: INVALID_ORDER })
  @IsString({ each: true, message: INVALID_ORDER })
  uids: string[];
}

export class BringToTeamBodyDto {
  // Sem validação: um uid inválido é só um Ecobeast que não existe.
  @ApiProperty({
    description: 'O `uid` de um Ecobeast do Santuário.',
    example: EXAMPLE_UID,
  })
  uid: string;

  @ApiPropertyOptional({
    description:
      'O `uid` de quem sai da equipe, para os dois trocarem de lugar. Sem ele, ' +
      'o Ecobeast entra na primeira vaga livre.',
    example: EXAMPLE_UID,
  })
  replace_uid?: string;
}

export class SendToStorageBodyDto {
  // Sem validação: um uid inválido é só um Ecobeast que não existe.
  @ApiProperty({
    description: 'O `uid` de um Ecobeast da equipe.',
    example: EXAMPLE_UID,
  })
  uid: string;
}

import { ApiProperty } from '@nestjs/swagger';
import { IsInt } from 'class-validator';
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

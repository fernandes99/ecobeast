import { ApiProperty } from '@nestjs/swagger';
import { AppearanceDto } from '../player/player.dto.js';

export class NpcAppearanceResponseDto extends AppearanceDto {
  @ApiProperty({ description: 'Id do NPC (`npcs`).', example: 4 })
  id: number;
}

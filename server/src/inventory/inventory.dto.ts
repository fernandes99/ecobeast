import { ApiProperty } from '@nestjs/swagger';
import { IsInt } from 'class-validator';

export const INVALID_ITEM = 'Esse item não existe.';

export class BuyItemBodyDto {
  @ApiProperty({ description: 'Id do item.', example: 4 })
  @IsInt({ message: INVALID_ITEM })
  item_id: number;
}

export class UseItemBodyDto extends BuyItemBodyDto {
  // Sem validação: um uid inválido é só um Ecobeast que não está na equipe.
  @ApiProperty({
    description: 'O `uid` de um Ecobeast da equipe.',
    example: '0b5c2f4e-8d1a-4c3b-9e7f-1a2b3c4d5e6f',
  })
  creature_uid: string;
}

import { ApiProperty } from '@nestjs/swagger';
import { IsInt } from 'class-validator';

export const INVALID_ITEM = 'Esse item não existe.';

export class BuyItemBodyDto {
  @ApiProperty({ description: 'Id do item.', example: 4 })
  @IsInt({ message: INVALID_ITEM })
  item_id: number;
}

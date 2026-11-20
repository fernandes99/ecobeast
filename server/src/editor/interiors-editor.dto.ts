import { ApiProperty } from '@nestjs/swagger';
import { IsInt, IsString } from 'class-validator';

export class NewInteriorDto {
  @ApiProperty({
    description: 'O nome, de 1 a 40 caracteres.',
    example: 'Loja',
  })
  @IsString({ message: 'name precisa ser um texto.' })
  name: string;

  @ApiProperty({ description: 'A largura, de 4 a 64 quadrados.', example: 16 })
  @IsInt({ message: 'width precisa ser um número inteiro.' })
  width: number;

  @ApiProperty({ description: 'A altura, de 4 a 64 quadrados.', example: 12 })
  @IsInt({ message: 'height precisa ser um número inteiro.' })
  height: number;
}

export class InteriorSummaryDto {
  @ApiProperty({ example: 1 })
  id: number;

  @ApiProperty({ example: 'Refúgio' })
  name: string;
}

export class InteriorListDto {
  @ApiProperty({ type: [InteriorSummaryDto] })
  interiors: InteriorSummaryDto[];
}

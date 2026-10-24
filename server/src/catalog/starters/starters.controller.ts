import { Controller, Get } from '@nestjs/common';
import {
  ApiOkResponse,
  ApiOperation,
  ApiProperty,
  ApiTags,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import { ref, ResourceRef } from '../../common/resource-ref.js';
import { PrismaService } from '../../prisma/prisma.service.js';

export class StarterDto {
  @ApiProperty({ example: 1 })
  sort_order: number;

  @ApiProperty({
    example: { id: 1, slug: 'fagulho', name: 'Fagulho', url: '/v1/species/1' },
  })
  species: ResourceRef;
}

export class StartersDto {
  @ApiProperty({ type: () => [StarterDto] })
  results: StarterDto[];
}

@ApiTags('Iniciais')
@Controller('starters')
export class StartersController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({
    summary: 'Os Ecobeasts iniciais',
    description:
      'As espécies que o jogador pode escolher no começo, na ordem da tela. Sem paginação.',
  })
  @ApiOkResponse({ type: StartersDto })
  @ApiTooManyRequestsResponse({
    description: 'Limite de chamadas por minuto excedido.',
  })
  async list(): Promise<StartersDto> {
    const rows = await this.prisma.starterOption.findMany({
      include: { species: true },
      orderBy: { sortOrder: 'asc' },
    });
    return {
      results: rows.map((row) => ({
        sort_order: row.sortOrder,
        species: ref('species', row.species),
      })),
    };
  }
}

import { Controller, Get, HttpException, HttpStatus } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service.js';

@ApiTags('Saúde')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  @ApiOperation({
    summary: 'Saúde do servidor',
    description: 'Confere se o servidor está no ar e se o banco responde.',
  })
  @ApiResponse({
    status: 200,
    description: 'Servidor e banco ok.',
    schema: { example: { status: 'ok', database: 'ok' } },
  })
  @ApiResponse({
    status: 503,
    description: 'O banco não respondeu.',
    schema: { example: { status: 'error', database: 'error' } },
  })
  async check(): Promise<{ status: string; database: string }> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return { status: 'ok', database: 'ok' };
    } catch {
      throw new HttpException(
        { status: 'error', database: 'error' },
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }
  }
}

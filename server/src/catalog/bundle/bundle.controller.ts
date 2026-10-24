import { Controller, Get, Req, Res } from '@nestjs/common';
import {
  ApiHeader,
  ApiOkResponse,
  ApiOperation,
  ApiProperty,
  ApiResponse,
  ApiTags,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { BundleService } from './bundle.service.js';

export class CatalogBundleDto {
  @ApiProperty({
    description:
      'SHA-256 do conteúdo, em hex. Muda sempre que qualquer valor do catálogo muda.',
    example: '3f0c…',
  })
  version: string;

  @ApiProperty({
    description:
      'As 23 tabelas, pelo nome. Cada linha tem as colunas da tabela em snake_case, em ordem crescente da chave.',
    type: 'object',
    additionalProperties: { type: 'array', items: { type: 'object' } },
    example: {
      elements: [
        {
          id: 1,
          slug: 'fire',
          name: 'Fogo',
          color_hex: '#F2603C',
          is_rare: false,
        },
      ],
      element_efficacy: [
        { attacker_element_id: 1, defender_element_id: 3, multiplier: 2 },
      ],
    },
  })
  tables: Record<string, Record<string, unknown>[]>;
}

@ApiTags('Catálogo')
@Controller('catalog')
export class BundleController {
  constructor(private readonly bundle: BundleService) {}

  @Get()
  @ApiOperation({
    summary: 'O catálogo inteiro',
    description:
      'Todas as tabelas do catálogo numa resposta só, no formato que o jogo lê. ' +
      'O jogo baixa ao abrir. A resposta traz o cabeçalho `ETag` com a versão; ' +
      'mande esse valor no `If-None-Match` da próxima chamada e, se nada mudou, ' +
      'a resposta é `304`, sem corpo. Mudanças no banco aparecem em até 1 minuto.',
  })
  @ApiHeader({
    name: 'If-None-Match',
    required: false,
    description: 'O `ETag` recebido antes, com as aspas.',
  })
  @ApiOkResponse({ type: CatalogBundleDto })
  @ApiResponse({
    status: 304,
    description: 'O catálogo não mudou desde o `ETag` enviado.',
  })
  @ApiTooManyRequestsResponse({
    description: 'Limite de chamadas por minuto excedido.',
  })
  async get(@Req() req: Request, @Res() res: Response): Promise<void> {
    const bundle = await this.bundle.get();
    res.setHeader('ETag', `"${bundle.version}"`);
    // req.fresh compara o If-None-Match com o ETag acima (aceita lista e W/).
    if (req.fresh) {
      res.status(304).end();
      return;
    }
    res.json(bundle);
  }
}

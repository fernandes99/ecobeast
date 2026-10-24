import { applyDecorators } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTooManyRequestsResponse,
} from '@nestjs/swagger';
import { ResourceRefPage } from './pagination.js';

const TOO_MANY = ApiTooManyRequestsResponse({
  description: 'Limite de chamadas por minuto excedido.',
});

/** Documentação de uma rota de lista paginada. */
export function ApiListRoute(summary: string, description: string) {
  return applyDecorators(
    ApiOperation({ summary, description }),
    ApiOkResponse({ type: ResourceRefPage }),
    ApiBadRequestResponse({ description: '`limit` ou `offset` inválido.' }),
    TOO_MANY,
  );
}

/** Documentação de uma rota que recebe `{idOrSlug}`. */
export function ApiDetailRoute(
  summary: string,
  description: string,
  type: () => object,
  example: string,
) {
  return applyDecorators(
    ApiOperation({ summary, description }),
    ApiParam({
      name: 'idOrSlug',
      description:
        'O id (só dígitos) ou o slug, sem diferença entre maiúsculas e minúsculas.',
      example,
    }),
    ApiOkResponse({ type }),
    ApiNotFoundResponse({ description: 'Não existe com esse id ou slug.' }),
    TOO_MANY,
  );
}

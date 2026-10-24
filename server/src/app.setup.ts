import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { apiReference } from '@scalar/nestjs-api-reference';
import type { Request, Response } from 'express';

export const API_PREFIX = 'v1';
export const OPENAPI_PATH = '/docs/openapi.json';

/**
 * O que main.ts e os testes e2e montam igual: prefixo /v1 (menos /health) e a
 * documentação — OpenAPI em /docs/openapi.json e a Scalar em /docs.
 * Chamar antes de app.init() / app.listen().
 */
export function configureApp(app: INestApplication): void {
  app.setGlobalPrefix(API_PREFIX, { exclude: ['health'] });

  const config = new DocumentBuilder()
    .setTitle('Ecobeast API')
    .setVersion('1')
    .setDescription(
      'API do catálogo do Ecobeast. Usada pelo jogo; leitura aberta, sem login.',
    )
    .build();
  const document = SwaggerModule.createDocument(app, config);

  const http = app.getHttpAdapter();
  // O JSON vem antes da Scalar, que responde a tudo que começa com /docs.
  http.get(OPENAPI_PATH, (_req: Request, res: Response) => {
    res.json(document);
  });
  app.use('/docs', apiReference({ url: OPENAPI_PATH }));
}

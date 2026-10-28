import {
  BadRequestException,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { apiReference } from '@scalar/nestjs-api-reference';
import type { Request, Response } from 'express';

export const API_PREFIX = 'v1';
export const OPENAPI_PATH = '/docs/openapi.json';

/**
 * O que main.ts e os testes e2e montam igual: prefixo /v1 (menos /health e as
 * páginas do login no navegador, /auth/google/*),
 * validação dos parâmetros (400 com a mensagem em pt-BR) e a documentação — OpenAPI em /docs/openapi.json e a Scalar em /docs.
 * Chamar antes de app.init() / app.listen().
 */
export function configureApp(app: INestApplication): void {
  app.setGlobalPrefix(API_PREFIX, {
    exclude: ['health', 'auth/google/go', 'auth/google/callback'],
  });
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      // Um texto só, com as mensagens dos DTOs (já em pt-BR).
      exceptionFactory: (errors) =>
        new BadRequestException(
          errors
            .flatMap((error) => Object.values(error.constraints ?? {}))
            .join('; '),
        ),
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('Ecobeast API')
    .setVersion('1')
    .setDescription(
      'API do Ecobeast, usada pelo jogo. O catálogo é aberto; as rotas com ' +
        'cadeado exigem a sessão do login com Google (`Authorization: Bearer`).',
    )
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);

  const http = app.getHttpAdapter();
  // O JSON vem antes da Scalar, que responde a tudo que começa com /docs.
  http.get(OPENAPI_PATH, (_req: Request, res: Response) => {
    res.json(document);
  });
  app.use('/docs', apiReference({ url: OPENAPI_PATH }));
}

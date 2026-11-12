import {
  BadRequestException,
  INestApplication,
  ValidationPipe,
} from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { apiReference } from '@scalar/nestjs-api-reference';
import type { ValidationError } from 'class-validator';
import { json, type Request, type Response } from 'express';

export const API_PREFIX = 'v1';
export const OPENAPI_PATH = '/docs/openapi.json';
const EDITOR_BODY_LIMIT = '5mb';

function messagesOf(error: ValidationError): string[] {
  return [
    ...Object.values(error.constraints ?? {}),
    ...(error.children ?? []).flatMap(messagesOf),
  ];
}

export function configureApp(app: INestApplication): void {
  // Antes do leitor de JSON do Nest, que entra no init() com o limite padrão
  // de 100 KB: o corpo das rotas do editor chega a ele já lido. O nome próprio
  // importa: o Nest não põe o leitor dele se já houver um chamado "jsonParser".
  const editorJson = json({ limit: EDITOR_BODY_LIMIT });
  app.use(
    `/${API_PREFIX}/editor`,
    function editorBodyParser(req: Request, res: Response, next: () => void) {
      editorJson(req, res, next);
    },
  );
  app.setGlobalPrefix(API_PREFIX, {
    exclude: ['health', 'auth/google/go', 'auth/google/callback'],
  });
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      exceptionFactory: (errors) =>
        new BadRequestException(errors.flatMap(messagesOf).join('; ')),
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

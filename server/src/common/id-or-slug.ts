import { NotFoundException } from '@nestjs/common';

/** Maior valor de uma coluna integer do Postgres. */
const MAX_INT = 2_147_483_647;

/**
 * O parâmetro `{idOrSlug}` das rotas de detalhe (RF-04): só dígitos é id; o
 * resto é slug, em minúsculas. Um número além do integer do banco vira slug,
 * para dar 404 em vez de erro do banco.
 */
export function parseIdOrSlug(
  param: string,
): { id: number } | { slug: string } {
  if (/^\d+$/.test(param)) {
    const id = Number(param);
    if (id <= MAX_INT) return { id };
  }
  return { slug: param.toLowerCase() };
}

/** `notFound('Espécie não encontrada', 'xyz')` → 404 "Espécie não encontrada: xyz". */
export function notFound(message: string, param: string): NotFoundException {
  return new NotFoundException(`${message}: ${param}`);
}

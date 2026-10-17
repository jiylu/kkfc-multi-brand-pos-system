import { randomInt } from 'node:crypto';
import { Prisma, type Brand } from '@prisma/client';
import type { BrandsRepository } from '../brands/brands.repository';

export function generateBrandCode(name: string, retry = false): string {
  const letters = name
    .normalize('NFKD')
    .toUpperCase()
    .replace(/\p{M}/gu, '')
    .replace(/[^A-Z]/g, '');
  const code = (letters || 'BRND').padEnd(4, 'X').slice(0, 4);
  if (!retry) return code;

  // shortcut: 676 collision variants per two-letter prefix; use a three-letter suffix if needed.
  return (
    code.slice(0, 2) +
    Array.from({ length: 2 }, () =>
      String.fromCharCode(65 + randomInt(26)),
    ).join('')
  );
}

export async function withUniqueBrandCode(
  name: string,
  repository: Pick<BrandsRepository, 'findOneBrandByCode'>,
  save: (code: string) => Promise<Brand>,
): Promise<Brand> {
  let retry = false;
  while (true) {
    const code = generateBrandCode(name, retry);
    retry = true;
    if (await repository.findOneBrandByCode(code, false)) continue;

    try {
      return await save(code);
    } catch (error) {
      if (
        !(error instanceof Prisma.PrismaClientKnownRequestError) ||
        error.code !== 'P2002'
      ) {
        throw error;
      }

      const adapterError = error.meta?.driverAdapterError as
        { cause?: { constraint?: { fields?: string[] } } } | undefined;
      const fields =
        error.meta?.target ?? adapterError?.cause?.constraint?.fields;
      if (
        !Array.isArray(fields) ||
        fields.length !== 1 ||
        fields[0] !== 'code'
      ) {
        throw error;
      }
    }
  }
}

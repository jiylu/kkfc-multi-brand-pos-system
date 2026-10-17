import { randomInt } from 'node:crypto';
import { Prisma } from '@prisma/client';
import type { BrandsRepository } from '../brands/brands.repository';
import { generateBrandCode, withUniqueBrandCode } from './generate-brand-code';

jest.mock('node:crypto', () => ({
  ...jest.requireActual<typeof import('node:crypto')>('node:crypto'),
  randomInt: jest.fn(),
}));

describe('brand code generation', () => {
  const brand = {
    brand_id: 'brand-id',
    code: 'BRAA',
    name: 'Brand',
    logo_url: null,
    is_active: true,
    created_at: new Date(),
    modified_at: new Date(),
  };
  let repository: jest.Mocked<Pick<BrandsRepository, 'findOneBrandByCode'>>;
  let save: jest.Mock<Promise<typeof brand>, [string]>;

  beforeEach(() => {
    jest
      .mocked(randomInt)
      .mockReset()
      .mockImplementation(() => 0);
    repository = { findOneBrandByCode: jest.fn().mockResolvedValue(null) };
    save = jest.fn((code: string) => Promise.resolve({ ...brand, code }));
  });

  it.each([
    ['Gamcheon', 'GAMC'],
    ['Aurelia’s Inasal', 'AURE'],
    ['King Kungs Kafé', 'KING'],
    ['Café 24!', 'CAFE'],
    [' a-b_c! ', 'ABCX'],
    ['A', 'AXXX'],
    ['123!', 'BRND'],
    ['가게', 'BRND'],
  ])('derives a four-letter code from %s', (name, code) => {
    expect(generateBrandCode(name)).toBe(code);
    expect(randomInt).not.toHaveBeenCalled();
  });

  it.each([
    [0, 'GAAA'],
    [25, 'GAZZ'],
  ] as const)('keeps the name prefix on a collision: %s', (value, code) => {
    jest.mocked(randomInt).mockImplementation(() => value);
    expect(generateBrandCode('Gamcheon', true)).toBe(code);
    expect(randomInt).toHaveBeenCalledTimes(2);
    expect(randomInt).toHaveBeenCalledWith(26);
  });

  it.each([true, false])(
    'regenerates an existing code with is_active=%s before saving',
    async (is_active) => {
      repository.findOneBrandByCode.mockResolvedValueOnce({
        ...brand,
        code: 'BRAN',
        is_active,
      });

      await expect(
        withUniqueBrandCode(brand.name, repository, save),
      ).resolves.toMatchObject({
        code: 'BRAA',
      });
      expect(repository.findOneBrandByCode.mock.calls).toEqual([
        ['BRAN', false],
        ['BRAA', false],
      ]);
      expect(save).toHaveBeenCalledTimes(1);
      expect(save).toHaveBeenCalledWith('BRAA');
    },
  );

  it.each([
    { target: ['code'] },
    {
      modelName: 'Brand',
      driverAdapterError: { cause: { constraint: { fields: ['code'] } } },
    },
  ])('retries a concurrent code collision: %j', async (meta) => {
    save.mockRejectedValueOnce(
      new Prisma.PrismaClientKnownRequestError('Code already exists', {
        code: 'P2002',
        clientVersion: '7.8.0',
        meta,
      }),
    );

    await expect(
      withUniqueBrandCode(brand.name, repository, save),
    ).resolves.toMatchObject({
      code: 'BRAA',
    });
    expect(save.mock.calls).toEqual([['BRAN'], ['BRAA']]);
    expect(repository.findOneBrandByCode).toHaveBeenCalledTimes(2);
  });

  it('does not write if the availability lookup fails', async () => {
    const error = new Error('Database unavailable');
    repository.findOneBrandByCode.mockRejectedValue(error);

    await expect(
      withUniqueBrandCode(brand.name, repository, save),
    ).rejects.toBe(error);
    expect(save).not.toHaveBeenCalled();
  });

  it.each([
    new Error('Database unavailable'),
    new Prisma.PrismaClientKnownRequestError('Connection failed', {
      code: 'P1001',
      clientVersion: '7.8.0',
    }),
    new Prisma.PrismaClientKnownRequestError('Assignment already exists', {
      code: 'P2002',
      clientVersion: '7.8.0',
      meta: { target: ['user_id', 'brand_id'] },
    }),
    new Prisma.PrismaClientKnownRequestError('Unidentified constraint', {
      code: 'P2002',
      clientVersion: '7.8.0',
    }),
  ])('propagates unrelated failures without retrying: %s', async (error) => {
    save.mockRejectedValue(error);

    await expect(
      withUniqueBrandCode(brand.name, repository, save),
    ).rejects.toBe(error);
    expect(save).toHaveBeenCalledTimes(1);
  });
});

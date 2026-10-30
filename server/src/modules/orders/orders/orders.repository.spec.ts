import { ConflictException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../shared/prisma/prisma.service';
import { OrdersRepository } from './orders.repository';

function adapterError(originalCode: string, kind = 'TransactionWriteConflict') {
  const error = new Error(kind, { cause: { kind, originalCode } });
  error.name = 'DriverAdapterError';
  return error;
}

describe('Order transaction conflict recovery', () => {
  const conflicts = [
    ...['P2034', 'P2002'].map((code) => ({
      name: code,
      error: new Prisma.PrismaClientKnownRequestError('conflict', {
        code,
        clientVersion: '7',
      }),
    })),
    ...['40001', '40P01'].map((code) => ({
      name: `pg adapter ${code}`,
      error: adapterError(code),
    })),
  ];

  function setup() {
    const tx = {} as Prisma.TransactionClient;
    const prisma = {
      $transaction: jest.fn(
        (work: (client: Prisma.TransactionClient) => Promise<string>) =>
          work(tx),
      ),
    };
    return {
      tx,
      prisma,
      repository: new OrdersRepository(prisma as unknown as PrismaService),
    };
  }

  it.each(conflicts)(
    'retries the whole transaction after $name at commit',
    async ({ error }) => {
      const { tx, prisma, repository } = setup();
      const work = jest.fn().mockResolvedValue('saved result');
      prisma.$transaction.mockImplementationOnce(async (callback) => {
        await callback(tx);
        throw error;
      });
      await expect(repository.transaction(work)).resolves.toBe('saved result');
      expect(work).toHaveBeenCalledTimes(2);
      expect(prisma.$transaction).toHaveBeenCalledTimes(2);
    },
  );

  it.each(conflicts)(
    'bounds $name retries and returns a stable recovery code',
    async ({ error }) => {
      const { prisma, repository } = setup();
      prisma.$transaction.mockRejectedValue(error);
      const result = await repository
        .transaction(jest.fn())
        .catch((error: unknown) => error);
      expect(result).toBeInstanceOf(ConflictException);
      expect((result as ConflictException).getResponse()).toEqual({
        statusCode: 409,
        error: 'Conflict',
        code: 'ORDER_RETRY_REQUIRED',
        message: 'Concurrent order request; retry using the same order ID.',
      });
      expect(prisma.$transaction).toHaveBeenCalledTimes(5);
    },
  );

  it.each([
    new Error('Connection lost; commit outcome unknown'),
    adapterError('08006', 'ConnectionClosed'),
    adapterError('23503', 'ForeignKeyConstraintViolation'),
    adapterError('40001', 'UnexpectedError'),
    new Prisma.PrismaClientKnownRequestError('not found', {
      code: 'P2025',
      clientVersion: '7',
    }),
  ])(
    'propagates non-retryable errors without replaying work (%s)',
    async (error) => {
      const { prisma, repository } = setup();
      prisma.$transaction.mockRejectedValue(error);
      await expect(repository.transaction(jest.fn())).rejects.toBe(error);
      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    },
  );
});

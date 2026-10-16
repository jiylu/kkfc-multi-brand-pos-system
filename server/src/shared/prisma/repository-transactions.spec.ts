import { Prisma, UserRole } from '@prisma/client';
import { AuthRepository } from '../../modules/auth/auth.repository';
import { BrandsRepository } from '../../modules/brands/brands.repository';
import { UsersRepository } from '../../modules/users/users.repository';
import { PrismaService } from './prisma.service';

describe('Repository transaction clients', () => {
  type Client = Prisma.TransactionClient | PrismaService;
  const record = { id: 'transaction-record' };
  const userDTO = {
    username: 'owner',
    first_name: 'Test',
    last_name: 'Owner',
    role: UserRole.OWNER,
    password: 'test-password',
  };
  const sessionDTO = {
    user_id: 'user-id',
    token_hash: 'a'.repeat(64),
    expires_at: new Date('2030-01-01T00:00:00Z'),
  };

  function model() {
    return {
      create: jest.fn().mockResolvedValue(record),
      findUnique: jest.fn().mockResolvedValue(record),
      findFirst: jest.fn().mockResolvedValue(record),
      findMany: jest.fn().mockResolvedValue([record]),
      count: jest.fn().mockResolvedValue(1),
      update: jest.fn().mockResolvedValue(record),
      updateMany: jest.fn().mockResolvedValue({ count: 2 }),
      delete: jest.fn().mockResolvedValue(record),
      deleteMany: jest.fn().mockResolvedValue(record),
    };
  }

  let transaction: {
    user: ReturnType<typeof model>;
    userSession: ReturnType<typeof model>;
    brand: ReturnType<typeof model>;
    userBrandAssignment: ReturnType<typeof model>;
  };
  let standaloneTransaction: jest.Mock;
  let auth: AuthRepository;
  let users: UsersRepository;
  let brands: BrandsRepository;

  beforeEach(() => {
    transaction = {
      user: model(),
      userSession: model(),
      brand: model(),
      userBrandAssignment: model(),
    };
    standaloneTransaction = jest.fn(
      (
        queries:
          | Promise<unknown>[]
          | ((tx: Prisma.TransactionClient) => Promise<unknown>),
      ) =>
        typeof queries === 'function'
          ? queries(transaction as unknown as Prisma.TransactionClient)
          : Promise.all(queries),
    );
    // No root delegates: a query escaping the supplied transaction must fail.
    const prisma = {
      $transaction: standaloneTransaction,
    } as unknown as PrismaService;
    auth = new AuthRepository(prisma);
    users = new UsersRepository(prisma);
    brands = new BrandsRepository(prisma);
  });

  const operations: [string, (tx?: Client) => Promise<unknown>][] = [
    ['Auth.create', (tx) => auth.create(sessionDTO, tx)],
    [
      'Auth.findOneSessionByTokenHash',
      (tx) => auth.findOneSessionByTokenHash('hash', tx),
    ],
    ['Auth.updateLastSeen', (tx) => auth.updateLastSeen('session-id', tx)],
    ['Auth.delete', (tx) => auth.delete('session-id', tx)],
    ['Auth.deleteMany', (tx) => auth.deleteMany('user-id', tx)],
    ['Users.create', (tx) => users.create(userDTO, tx)],
    ['Users.findOne', (tx) => users.findOne('user-id', true, tx)],
    ['Users.findByUsername', (tx) => users.findByUsername('owner', true, tx)],
    [
      'Users.update',
      (tx) =>
        users.update(
          'user-id',
          { first_name: 'Updated', password: 'new-password' },
          tx,
        ),
    ],
    ['Users.delete', (tx) => users.delete('user-id', tx)],
    ['Brands.createBrand', (tx) => brands.createBrand({ name: 'Brand' }, tx)],
    ['Brands.assignUser', (tx) => brands.assignUser('user-id', 'brand-id', tx)],
    ['Brands.findOneBrand', (tx) => brands.findOneBrand('brand-id', true, tx)],
    [
      'Brands.findAssignmentByUserAndBrand',
      (tx) =>
        brands.findAssignmentByUserAndBrand('user-id', 'brand-id', false, tx),
    ],
    [
      'Brands.findOneBrandAssignment',
      (tx) => brands.findOneBrandAssignment('assignment-id', true, tx),
    ],
    [
      'Brands.updateBrand',
      (tx) => brands.updateBrand('brand-id', { name: 'Updated' }, tx),
    ],
    [
      'Brands.reactivateBrandAssignment',
      (tx) => brands.reactivateBrandAssignment('assignment-id', tx),
    ],
    [
      'Brands.deactivateAssignment',
      (tx) => brands.deactivateAssignment('assignment-id', tx),
    ],
  ];

  it.each(operations)(
    '%s uses the supplied transaction',
    async (_name, run) => {
      await expect(
        run(transaction as unknown as Prisma.TransactionClient),
      ).resolves.toEqual(record);
      expect(standaloneTransaction).not.toHaveBeenCalled();
    },
  );

  it.each(operations)(
    '%s defaults to the injected Prisma client',
    async (_name, run) => {
      const prisma = transaction as unknown as PrismaService;
      auth = new AuthRepository(prisma);
      users = new UsersRepository(prisma);
      brands = new BrandsRepository(prisma);

      await expect(run()).resolves.toEqual(record);
    },
  );

  it('deletes a brand and deactivates its active assignments in one transaction', async () => {
    await expect(brands.deleteBrand('brand-id')).resolves.toEqual(record);
    expect(standaloneTransaction).toHaveBeenCalledTimes(1);
    expect(transaction.brand.update.mock.calls).toMatchObject([
      [
        {
          where: { brand_id: 'brand-id', is_active: true },
          data: { is_active: false },
        },
      ],
    ]);
    expect(transaction.userBrandAssignment.updateMany.mock.calls).toMatchObject(
      [
        [
          {
            where: { brand_id: 'brand-id', is_active: true },
            data: { is_active: false },
          },
        ],
      ],
    );
  });

  it('deletes a brand with no active assignments', async () => {
    transaction.userBrandAssignment.updateMany.mockResolvedValue({ count: 0 });

    await expect(brands.deleteBrand('brand-id')).resolves.toEqual(record);
    expect(transaction.userBrandAssignment.updateMany).toHaveBeenCalledTimes(1);
  });

  it.each(['brand', 'assignment update'])(
    'rejects the delete transaction when %s fails',
    async (step) => {
      const error = new Error('Database operation failed');
      if (step === 'brand') transaction.brand.update.mockRejectedValue(error);
      else transaction.userBrandAssignment.updateMany.mockRejectedValue(error);

      await expect(brands.deleteBrand('brand-id')).rejects.toBe(error);
      expect(standaloneTransaction).toHaveBeenCalledTimes(1);
    },
  );

  it.each([true, false])(
    'paginates assignments with matching row and count filters for activeOnly=%s',
    async (activeOnly) => {
      transaction.userBrandAssignment.findMany.mockResolvedValue([]);
      transaction.userBrandAssignment.count.mockResolvedValue(21);

      await expect(
        brands.findAllAssignedUsersForBrand(
          'brand-id',
          30,
          10,
          activeOnly,
          transaction as unknown as Prisma.TransactionClient,
        ),
      ).resolves.toEqual({ users: [], total: 21 });
      const where = {
        brand_id: 'brand-id',
        is_active: activeOnly ? true : undefined,
      };
      expect(transaction.userBrandAssignment.findMany).toHaveBeenCalledWith({
        where,
        skip: 30,
        take: 10,
        orderBy: [{ created_at: 'desc' }, { user_id: 'asc' }],
      });
      expect(transaction.userBrandAssignment.count).toHaveBeenCalledWith({
        where,
      });
      expect(transaction.user.findMany).not.toHaveBeenCalled();
      expect(transaction.user.count).not.toHaveBeenCalled();
    },
  );

  const listings: [string, (tx?: Client) => Promise<unknown>, string][] = [
    ['Users.findAll', (tx) => users.findAll(0, 10, false, tx), 'users'],
    [
      'Brands.findAllAssignedUsersForBrand',
      (tx) =>
        brands.findAllAssignedUsersForBrand('brand-id', 0, 10, undefined, tx),
      'users',
    ],
    [
      'Brands.findAllBrands',
      (tx) => brands.findAllBrands(0, 10, false, tx),
      'brands',
    ],
    [
      'Brands.findAllBrandAssignmentsForUser',
      (tx) =>
        brands.findAllBrandAssignmentsForUser('user-id', 0, 10, false, tx),
      'brandAssignments',
    ],
  ];

  it.each(listings)(
    '%s reads rows and totals inside the supplied transaction',
    async (_name, run, key) => {
      await expect(
        run(transaction as unknown as Prisma.TransactionClient),
      ).resolves.toEqual({ [key]: [record], total: 1 });
      expect(standaloneTransaction).not.toHaveBeenCalled();
    },
  );

  it.each(listings)(
    '%s retains a RepeatableRead snapshot when standalone',
    async (_name, run, key) => {
      const prisma = {
        ...transaction,
        $transaction: standaloneTransaction,
      } as unknown as PrismaService;
      users = new UsersRepository(prisma);
      brands = new BrandsRepository(prisma);

      await expect(run()).resolves.toEqual({ [key]: [record], total: 1 });
      expect(standaloneTransaction).toHaveBeenCalledTimes(1);
      expect(standaloneTransaction).toHaveBeenCalledWith(expect.any(Array), {
        isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
      });
    },
  );

  it.each(listings)(
    '%s propagates failures to the transaction owner',
    async (_name, run) => {
      const error = new Error('Transaction failed');
      transaction.user.count.mockRejectedValue(error);
      transaction.brand.count.mockRejectedValue(error);
      transaction.userBrandAssignment.count.mockRejectedValue(error);

      await expect(
        run(transaction as unknown as Prisma.TransactionClient),
      ).rejects.toBe(error);
      expect(standaloneTransaction).not.toHaveBeenCalled();
    },
  );
});

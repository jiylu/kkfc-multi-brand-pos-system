import { UsersRepository } from '../users.repository';
import { PrismaService } from '../../../shared/prisma/prisma.service';

describe('UsersRepository active filters', () => {
  const findUnique = jest.fn().mockResolvedValue(null);
  const repository = new UsersRepository({
    user: { findUnique },
  } as unknown as PrismaService);

  beforeEach(() => findUnique.mockClear());

  it.each([undefined, true, false])(
    'filters user ID lookups with activeOnly=%s',
    async (activeOnly) => {
      await repository.findOne('user-id', activeOnly);
      expect(findUnique).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            user_id: 'user-id',
            is_active: activeOnly === false ? undefined : true,
          },
          omit: { password_hash: true },
        }),
      );
    },
  );

  it.each([undefined, true, false])(
    'filters username lookups with activeOnly=%s',
    async (activeOnly) => {
      await repository.findByUsername('owner', activeOnly);
      expect(findUnique).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            username: 'owner',
            is_active: activeOnly === false ? undefined : true,
          },
        }),
      );
    },
  );
});

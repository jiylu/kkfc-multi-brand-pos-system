import { Logger } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { CreateUserDTO } from '../dto/create-user.dto';
import { FindUsersDTO } from '../dto/find-users.dto';
import { UsersRepository } from '../users.repository';
import { UsersService } from '../users.service';

describe('UsersService', () => {
  const user = {
    user_id: 'user-id',
    username: 'owner',
    first_name: 'Test',
    last_name: 'Owner',
    role: UserRole.OWNER,
    is_active: true,
    created_at: new Date('2030-01-01T00:00:00Z'),
    modified_at: new Date('2030-01-01T00:00:00Z'),
    user_brand_assignments_user: [],
  };
  const createDTO: CreateUserDTO = {
    username: user.username,
    first_name: user.first_name,
    last_name: user.last_name,
    role: user.role,
    password: 'test-password',
  };
  let repository: jest.Mocked<
    Pick<
      UsersRepository,
      'create' | 'findAll' | 'findOne' | 'update' | 'delete'
    >
  >;
  let service: UsersService;

  beforeEach(() => {
    jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      create: jest.fn().mockResolvedValue(user),
      findAll: jest.fn().mockResolvedValue({ users: [user], total: 21 }),
      findOne: jest.fn().mockResolvedValue(user),
      update: jest.fn().mockResolvedValue({ ...user, first_name: 'Updated' }),
      delete: jest.fn().mockResolvedValue({ ...user, is_active: false }),
    };
    service = new UsersService(repository as unknown as UsersRepository);
  });

  afterEach(() => jest.restoreAllMocks());

  it('creates a user with the supplied fields', async () => {
    await expect(service.createUser(createDTO)).resolves.toEqual(user);
    expect(repository.create).toHaveBeenCalledWith(createDTO);
  });

  it.each([true, false])(
    'returns pagination metadata and forwards activeOnly=%s',
    async (activeOnly) => {
      await expect(
        service.findAllUsers({ page: 3, limit: 10, activeOnly }),
      ).resolves.toEqual({
        data: [user],
        meta: { page: 3, limit: 10, total: 21, totalPages: 3 },
      });
      expect(repository.findAll).toHaveBeenCalledWith(20, 10, activeOnly);
    },
  );

  it('returns an empty list and zero pages when no users match', async () => {
    repository.findAll.mockResolvedValue({ users: [], total: 0 });

    await expect(service.findAllUsers(new FindUsersDTO())).resolves.toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
    expect(repository.findAll).toHaveBeenCalledWith(0, 10, true);
  });

  it('returns an empty page past the last result while preserving totals', async () => {
    repository.findAll.mockResolvedValue({ users: [], total: 21 });

    await expect(
      service.findAllUsers({ page: 4, limit: 10, activeOnly: true }),
    ).resolves.toEqual({
      data: [],
      meta: { page: 4, limit: 10, total: 21, totalPages: 3 },
    });
  });

  it('rejects offsets outside the database range before querying', async () => {
    await expect(
      service.findAllUsers({
        page: 2_147_483_647,
        limit: 2,
        activeOnly: true,
      }),
    ).rejects.toMatchObject({
      status: 400,
      response: {
        code: 'PAGINATION_UNSUPPORTED_RANGE',
        message: 'Requested page exceeds the supported range.',
      },
    });
    expect(repository.findAll).not.toHaveBeenCalled();
  });

  it('allows the largest page number when its offset fits the database range', async () => {
    await service.findAllUsers({
      page: 2_147_483_647,
      limit: 1,
      activeOnly: true,
    });

    expect(repository.findAll).toHaveBeenCalledWith(2_147_483_646, 1, true);
  });

  it('returns an existing user', async () => {
    await expect(service.findOneUser(user.user_id)).resolves.toEqual(user);
    expect(repository.findOne).toHaveBeenCalledWith(user.user_id);
  });

  it('updates an existing user with the supplied fields', async () => {
    const dto = { first_name: 'Updated' };

    await expect(service.updateUser(user.user_id, dto)).resolves.toEqual({
      ...user,
      first_name: 'Updated',
    });
    expect(repository.findOne).toHaveBeenCalledWith(user.user_id);
    expect(repository.update).toHaveBeenCalledWith(user.user_id, dto);
  });

  it('deactivates an existing user', async () => {
    await expect(service.deleteUser(user.user_id)).resolves.toEqual({
      ...user,
      is_active: false,
    });
    expect(repository.findOne).toHaveBeenCalledWith(user.user_id);
    expect(repository.delete).toHaveBeenCalledWith(user.user_id);
  });

  it.each([
    ['finding', () => service.findOneUser(user.user_id)],
    [
      'updating',
      () => service.updateUser(user.user_id, { first_name: 'Updated' }),
    ],
    ['deactivating', () => service.deleteUser(user.user_id)],
  ] as const)(
    'rejects %s a missing user without writing',
    async (_action, run) => {
      repository.findOne.mockResolvedValue(null);

      await expect(run()).rejects.toMatchObject({
        status: 404,
        response: { code: 'USER_NOT_FOUND', message: 'User not found.' },
      });
      expect(repository.update).not.toHaveBeenCalled();
      expect(repository.delete).not.toHaveBeenCalled();
    },
  );

  it.each([
    ['create', () => service.createUser(createDTO)],
    ['findAll', () => service.findAllUsers(new FindUsersDTO())],
    ['findOne', () => service.findOneUser(user.user_id)],
    [
      'update',
      () => service.updateUser(user.user_id, { first_name: 'Updated' }),
    ],
    ['delete', () => service.deleteUser(user.user_id)],
  ] as const)('propagates repository failures from %s', async (method, run) => {
    const error = new Error('Database unavailable');
    repository[method].mockRejectedValue(error);

    await expect(run()).rejects.toBe(error);
  });
});

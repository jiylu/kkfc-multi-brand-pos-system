import { Logger } from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { CreateUserDTO } from '../dto/create-user.dto';
import { FindUsersDTO } from '../dto/find-users.dto';
import { UsersRepository } from '../users.repository';
import { UsersService } from '../users.service';

describe('UsersService', () => {
  const user = {
    user_id: '00000000-0000-4000-8000-000000000001',
    username: 'manager',
    first_name: 'Test',
    last_name: 'Manager',
    role: UserRole.MANAGER,
    is_active: true,
    created_at: new Date('2030-01-01T00:00:00Z'),
    modified_at: new Date('2030-01-01T00:00:00Z'),
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
      | 'create'
      | 'findAll'
      | 'findOne'
      | 'findByUsername'
      | 'safeFindByUsername'
      | 'update'
      | 'delete'
    >
  >;
  let service: UsersService;
  let log: jest.SpyInstance;

  beforeEach(() => {
    log = jest.spyOn(Logger.prototype, 'log').mockImplementation();
    jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    repository = {
      create: jest.fn().mockResolvedValue(user),
      findAll: jest.fn().mockResolvedValue({ users: [user], total: 21 }),
      findOne: jest.fn().mockResolvedValue(user),
      findByUsername: jest.fn().mockResolvedValue(null),
      safeFindByUsername: jest.fn().mockResolvedValue(null),
      update: jest.fn().mockResolvedValue({ ...user, first_name: 'Updated' }),
      delete: jest.fn().mockResolvedValue({ ...user, is_active: false }),
    };
    service = new UsersService(repository as unknown as UsersRepository);
  });

  afterEach(() => jest.restoreAllMocks());

  it.each(Object.values(UserRole))(
    'UT-USER-017: creates %s without an assignment',
    async (role) => {
      const dto = { ...createDTO, role };
      await service.createUser(dto, true);
      expect(repository.create).toHaveBeenCalledWith(dto);
    },
  );
  it('UT-USER-018: blocks managers from creating superadmins', async () => {
    await expect(
      service.createUser({ ...createDTO, role: UserRole.SUPERADMIN }),
    ).rejects.toMatchObject({ status: 403 });
    expect(repository.create).not.toHaveBeenCalled();
  });
  it.each([false, true])(
    'UT-USER-019: protects superadmin updates and deletion, caller superadmin=%s',
    async (isSuperAdmin) => {
      repository.findOne.mockResolvedValue({
        ...user,
        role: UserRole.SUPERADMIN,
      });
      const update = service.updateUser(
        user.user_id,
        { password: 'Password123!' },
        isSuperAdmin,
      );
      if (isSuperAdmin) await expect(update).resolves.toBeDefined();
      else await expect(update).rejects.toMatchObject({ status: 403 });
      const deletion = service.deleteUser(user.user_id, isSuperAdmin);
      if (isSuperAdmin) await expect(deletion).resolves.toBeDefined();
      else {
        await expect(deletion).rejects.toMatchObject({ status: 403 });
        expect(repository.update).not.toHaveBeenCalled();
        expect(repository.delete).not.toHaveBeenCalled();
      }
    },
  );
  it('UT-USER-020: allows managers to create staff without assignments', async () => {
    await service.createUser(createDTO);
    expect(repository.create).toHaveBeenCalledWith(createDTO);
  });
  it('UT-USER-021: looks up a username and forwards activeOnly', async () => {
    repository.safeFindByUsername.mockResolvedValue(user);
    await expect(service.findOneUser(user.username, false)).resolves.toEqual(
      user,
    );
    expect(repository.safeFindByUsername).toHaveBeenCalledWith(
      user.username,
      false,
    );
    expect(repository.findOne).not.toHaveBeenCalled();
  });

  it('UT-USER-001: creates a user with the supplied fields', async () => {
    await expect(service.createUser(createDTO, true)).resolves.toEqual(user);
    expect(repository.create).toHaveBeenCalledWith(createDTO);
  });

  it('UT-USER-002: returns a conflict when the username is already taken', async () => {
    repository.safeFindByUsername.mockResolvedValue(user);

    await expect(service.createUser(createDTO, true)).rejects.toMatchObject({
      status: 409,
      response: {
        code: 'USERNAME_ALREADY_EXISTS',
        message: 'Username already exists.',
      },
    });
    expect(repository.safeFindByUsername).toHaveBeenCalledWith(
      user.username,
      false,
    );
    expect(repository.create).not.toHaveBeenCalled();
    expect(log).not.toHaveBeenCalledWith(
      expect.stringContaining('Created new user'),
    );
  });

  it.each(['P1001', 'P2002', 'P2003'])(
    'UT-USER-003: propagates create failures to the global filter: %s',
    async (code) => {
      const error = new Prisma.PrismaClientKnownRequestError(
        'Database request failed',
        {
          code,
          clientVersion: '7.8.0',
        },
      );
      repository.create.mockRejectedValue(error);

      await expect(service.createUser(createDTO, true)).rejects.toBe(error);
    },
  );

  it.each([true, false])(
    'UT-USER-004: returns pagination metadata and forwards activeOnly=%s',
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

  it('UT-USER-005: returns an empty list and zero pages when no users match', async () => {
    repository.findAll.mockResolvedValue({ users: [], total: 0 });

    await expect(service.findAllUsers(new FindUsersDTO())).resolves.toEqual({
      data: [],
      meta: { page: 1, limit: 10, total: 0, totalPages: 0 },
    });
    expect(repository.findAll).toHaveBeenCalledWith(0, 10, true);
  });

  it('UT-USER-006: returns an empty page past the last result while preserving totals', async () => {
    repository.findAll.mockResolvedValue({ users: [], total: 21 });

    await expect(
      service.findAllUsers({ page: 4, limit: 10, activeOnly: true }),
    ).resolves.toEqual({
      data: [],
      meta: { page: 4, limit: 10, total: 21, totalPages: 3 },
    });
  });

  it('UT-USER-007: rejects offsets outside the database range before querying', async () => {
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

  it('UT-USER-008: allows the largest page number when its offset fits the database range', async () => {
    await service.findAllUsers({
      page: 2_147_483_647,
      limit: 1,
      activeOnly: true,
    });

    expect(repository.findAll).toHaveBeenCalledWith(2_147_483_646, 1, true);
  });

  it('UT-USER-009: returns an existing user', async () => {
    await expect(service.findOneUser(user.user_id, true)).resolves.toEqual(
      user,
    );
    expect(repository.findOne).toHaveBeenCalledWith(user.user_id, true);
  });

  it('UT-USER-010: allows explicitly finding an inactive user', async () => {
    const inactiveUser = { ...user, is_active: false };
    repository.findOne.mockResolvedValue(inactiveUser);

    await expect(service.findOneUser(user.user_id, false)).resolves.toEqual(
      inactiveUser,
    );
    expect(repository.findOne).toHaveBeenCalledWith(user.user_id, false);
  });

  it('UT-USER-011: updates an existing user with the supplied fields', async () => {
    const dto = { first_name: 'Updated' };

    await expect(service.updateUser(user.user_id, dto)).resolves.toEqual({
      ...user,
      first_name: 'Updated',
    });
    expect(repository.findOne).toHaveBeenCalledWith(user.user_id);
    expect(repository.update).toHaveBeenCalledWith(user.user_id, dto);
  });

  describe('username updates', () => {
    it('UT-USER-022: updates to an available username and checks inactive accounts too', async () => {
      const dto = { username: 'renamed_owner' };
      repository.update.mockResolvedValue({ ...user, ...dto });

      await expect(
        service.updateUser(user.user_id, dto),
      ).resolves.toMatchObject(dto);
      expect(repository.safeFindByUsername).toHaveBeenCalledWith(
        dto.username,
        false,
      );
      expect(repository.update).toHaveBeenCalledWith(user.user_id, dto);
    });

    it.each([true, false])(
      'UT-USER-023: rejects a username belonging to another account with is_active=%s',
      async (is_active) => {
        repository.safeFindByUsername.mockResolvedValue({
          ...user,
          user_id: 'other-user-id',
          username: 'taken_username',
          is_active,
        });

        await expect(
          service.updateUser(user.user_id, {
            username: 'taken_username',
            first_name: 'Changed',
          }),
        ).rejects.toMatchObject({
          status: 409,
          response: {
            code: 'USERNAME_ALREADY_EXISTS',
            message: 'Username already exists.',
          },
        });
        expect(repository.safeFindByUsername).toHaveBeenCalledWith(
          'taken_username',
          false,
        );
        expect(repository.update).not.toHaveBeenCalled();
      },
    );

    it.each([undefined, user.username])(
      'UT-USER-024: skips the availability check for an omitted or unchanged username: %s',
      async (username) => {
        const dto = { username, first_name: 'Updated' };

        await service.updateUser(user.user_id, dto);

        expect(repository.safeFindByUsername).not.toHaveBeenCalled();
        expect(repository.update).toHaveBeenCalledWith(user.user_id, dto);
      },
    );

    it('UT-USER-025: does not write if the availability lookup fails', async () => {
      const error = new Error('Database unavailable');
      repository.safeFindByUsername.mockRejectedValue(error);

      await expect(
        service.updateUser(user.user_id, { username: 'renamed_owner' }),
      ).rejects.toBe(error);
      expect(repository.update).not.toHaveBeenCalled();
    });

    it('UT-USER-026: propagates a concurrent username conflict to the global filter', async () => {
      const error = new Prisma.PrismaClientKnownRequestError(
        'Username is already taken',
        { code: 'P2002', clientVersion: '7.8.0' },
      );
      repository.update.mockRejectedValue(error);

      await expect(
        service.updateUser(user.user_id, { username: 'renamed_owner' }),
      ).rejects.toBe(error);
    });
  });

  it('UT-USER-012: rejects an update if the user is deactivated after the lookup', async () => {
    repository.update.mockRejectedValue(
      new Prisma.PrismaClientKnownRequestError('No matching user', {
        code: 'P2025',
        clientVersion: '7.8.0',
      }),
    );

    await expect(
      service.updateUser(user.user_id, { first_name: 'Updated' }),
    ).rejects.toMatchObject({
      status: 404,
      response: { code: 'USER_NOT_FOUND', message: 'User not found.' },
    });
    expect(repository.update).toHaveBeenCalledWith(user.user_id, {
      first_name: 'Updated',
    });
    expect(log).not.toHaveBeenCalledWith(`Updated user ${user.user_id}`);
  });

  it('UT-USER-013: propagates unrelated Prisma update failures', async () => {
    const error = new Prisma.PrismaClientKnownRequestError(
      'Database unavailable',
      {
        code: 'P1001',
        clientVersion: '7.8.0',
      },
    );
    repository.update.mockRejectedValue(error);

    await expect(
      service.updateUser(user.user_id, { first_name: 'Updated' }),
    ).rejects.toBe(error);
  });

  it('UT-USER-014: deactivates an existing user', async () => {
    await expect(service.deleteUser(user.user_id)).resolves.toEqual({
      ...user,
      is_active: false,
    });
    expect(repository.findOne).toHaveBeenCalledWith(user.user_id);
    expect(repository.delete).toHaveBeenCalledWith(user.user_id);
  });

  it.each([
    ['finding', () => service.findOneUser(user.user_id, true)],
    [
      'updating',
      () => service.updateUser(user.user_id, { first_name: 'Updated' }),
    ],
    ['deactivating', () => service.deleteUser(user.user_id)],
  ] as const)(
    'UT-USER-015: rejects %s a missing user without writing',
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
    ['create', () => service.createUser(createDTO, true)],
    ['findAll', () => service.findAllUsers(new FindUsersDTO())],
    ['findOne', () => service.findOneUser(user.user_id, true)],
    [
      'update',
      () => service.updateUser(user.user_id, { first_name: 'Updated' }),
    ],
    ['delete', () => service.deleteUser(user.user_id)],
  ] as const)(
    'UT-USER-016: propagates repository failures from %s',
    async (method, run) => {
      const error = new Error('Database unavailable');
      repository[method].mockRejectedValue(error);

      await expect(run()).rejects.toBe(error);
    },
  );
});

import {
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { UsersRepository } from './users.repository';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { FindUsersDTO } from './dto/find-users.dto';
import { assertExists } from '../../shared/assertions/assert-exists';
import { assertValidPagination } from '../../shared/assertions/assert-valid-pagination';
import { isUUID } from 'class-validator';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(private readonly usersRepository: UsersRepository) {}

  async createUser(dto: CreateUserDTO, isSuperAdmin = false) {
    this.logger.log(`Creating ${dto.role} user ${dto.first_name}`);

    if (!isSuperAdmin && dto.role === UserRole.SUPERADMIN) {
      throw new ForbiddenException({
        code: 'CANNOT_CREATE_PRIVILEGED_ACCOUNT',
        message: 'You are not authorized to create this role.',
      });
    }

    const existingUser = await this.usersRepository.safeFindByUsername(
      dto.username,
      false,
    );

    if (existingUser) {
      this.logger.warn(`Username ${dto.username} already exists.`);

      throw new ConflictException({
        code: 'USERNAME_ALREADY_EXISTS',
        message: 'Username already exists.',
      });
    }

    const user = await this.usersRepository.create(dto);

    this.logger.log(`
      Created new user with role: ${user.role} with user_id: ${user.user_id}
    `);

    return user;
  }

  async findAllUsers({ page, limit, activeOnly }: FindUsersDTO) {
    this.logger.log(
      `Listing users: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const { users, total } = await this.usersRepository.findAll(
      skip,
      limit,
      activeOnly,
    );

    this.logger.log(
      `Listed users: page=${page}, returned=${users.length}, total=${total}`,
    );

    return {
      data: users,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findOneUser(
    usernameOrUserId: string | { user_id: string },
    activeOnly = true,
  ) {
    const identifier =
      typeof usernameOrUserId === 'string'
        ? usernameOrUserId
        : usernameOrUserId.user_id;
    this.logger.log(`Finding user ${identifier}`);

    const user =
      typeof usernameOrUserId === 'string' && !isUUID(identifier)
        ? await this.usersRepository.safeFindByUsername(identifier, activeOnly)
        : await this.usersRepository.findOne(identifier, activeOnly);

    assertExists(user, 'User', identifier, this.logger);

    this.logger.log(`User ${user.user_id} with role ${user.role} found.`);
    return user;
  }

  async updateUser(userId: string, dto: UpdateUserDTO, isSuperAdmin = false) {
    this.logger.log(`Updating user ${userId}`);

    const user = await this.usersRepository.findOne(userId);
    assertExists(user, 'User', userId, this.logger);

    if (user.role === UserRole.SUPERADMIN && !isSuperAdmin) {
      throw new ForbiddenException({
        code: 'CANNOT_MODIFY_PRIVILEGED_ACCOUNT',
        message: 'Only superadmins can modify superadmin accounts.',
      });
    }

    if (dto.username !== undefined && dto.username !== user.username) {
      const existingUsername = await this.usersRepository.safeFindByUsername(
        dto.username,
        false,
      );

      if (existingUsername) {
        throw new ConflictException({
          code: 'USERNAME_ALREADY_EXISTS',
          message: 'Username already exists.',
        });
      }
    }

    try {
      const updated = await this.usersRepository.update(user.user_id, dto);
      this.logger.log(`Updated user ${userId}`);
      return updated;
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException({
          code: 'USER_NOT_FOUND',
          message: 'User not found.',
        });
      }

      throw error;
    }
  }

  async deleteUser(userId: string, isSuperAdmin = false) {
    this.logger.log(`Deactivating user ${userId}`);

    const user = await this.usersRepository.findOne(userId);
    assertExists(user, 'User', userId, this.logger);

    if (user.role === UserRole.SUPERADMIN && !isSuperAdmin) {
      throw new ForbiddenException({
        code: 'CANNOT_MODIFY_PRIVILEGED_ACCOUNT',
        message: 'Only superadmins can modify superadmin accounts.',
      });
    }

    const deleted = await this.usersRepository.delete(user.user_id);
    this.logger.log(`Deactivated user ${userId}`);
    return deleted;
  }
}

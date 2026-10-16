import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { UsersRepository } from './users.repository';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { FindUsersDTO } from './dto/find-users.dto';
import { assertValidPagination } from '../../shared/assertions/assert-valid-pagination';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(private readonly usersRepository: UsersRepository) {}

  async createUser(dto: CreateUserDTO) {
    this.logger.log(`Creating ${dto.role} user ${dto.first_name}`);

    try {
      const user = await this.usersRepository.create(dto);

      this.logger.log(`
        Created new user with role: ${user.role} with user_id: ${user.user_id}
      `);

      return user;
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException({
          code: 'USERNAME_ALREADY_EXISTS',
          message: 'Username already exists.',
        });
      }

      throw error;
    }
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

  async findOneUser(userId: string, activeOnly = true) {
    this.logger.log(`Finding user ${userId}`);

    const user = await this.usersRepository.findOne(userId, activeOnly);

    this.assertUserExists(user);

    this.logger.log(`User ${user.user_id} with role ${user.role} found.`);

    return user;
  }

  async updateUser(userId: string, dto: UpdateUserDTO) {
    this.logger.log(`Updating user ${userId}`);

    const user = await this.findOneUser(userId);

    this.assertUserExists(user);

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

  async deleteUser(userId: string) {
    this.logger.log(`Deactivating user ${userId}`);

    const user = await this.findOneUser(userId);

    this.assertUserExists(user);

    const deleted = await this.usersRepository.delete(user.user_id);
    this.logger.log(`Deactivated user ${userId}`);
    return deleted;
  }

  private assertUserExists<T>(
    user: T | null | undefined,
  ): asserts user is NonNullable<T> {
    if (user == null) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found.',
      });
    }
  }
}

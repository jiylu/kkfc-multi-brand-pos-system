import {
  BadRequestException,
  HttpException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { UsersRepository } from './users.repository';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { PaginationDTO } from '../../shared/dto/pagination.dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(private readonly usersRepository: UsersRepository) {}

  async createUser(dto: CreateUserDTO) {
    this.logger.log('Creating user');

    try {
      const user = await this.usersRepository.create(dto);
      this.logger.log(`Created user ${user.user_id}`);
      return user;
    } catch (error) {
      this.logFailure('Create user', error);
      throw error;
    }
  }

  async findAllUsers({ page, limit }: PaginationDTO) {
    this.logger.log(`Listing users: page=${page}, limit=${limit}`);

    try {
      const skip = (page - 1) * limit;

      if (skip > 2_147_483_647) {
        throw new BadRequestException(
          'Requested page exceeds the supported range.',
        );
      }

      const { users, total } = await this.usersRepository.findAll(skip, limit);
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
    } catch (error) {
      this.logFailure('List users', error);
      throw error;
    }
  }

  async findOneUser(userId: string) {
    this.logger.log(`Finding user ${userId}`);

    try {
      const user = await this.usersRepository.findOne(userId);

      if (user) {
        this.logger.log(`Found user ${userId}`);
      } else {
        this.logger.warn(`User ${userId} not found`);
      }

      return user;
    } catch (error) {
      this.logFailure(`Find user ${userId}`, error);
      throw error;
    }
  }

  async updateUser(userId: string, dto: UpdateUserDTO) {
    this.logger.log(`Updating user ${userId}`);

    try {
      const user = await this.findOneUser(userId);

      if (!user) {
        throw new NotFoundException({
          code: 'USER_NOT_FOUND',
          message: 'User not found.',
        });
      }

      const updated = await this.usersRepository.update(user.user_id, dto);
      this.logger.log(`Updated user ${userId}`);
      return updated;
    } catch (error) {
      this.logFailure(`Update user ${userId}`, error);
      throw error;
    }
  }

  async deleteUser(userId: string) {
    this.logger.log(`Deactivating user ${userId}`);

    try {
      const user = await this.findOneUser(userId);

      if (!user) {
        throw new NotFoundException({
          code: 'USER_NOT_FOUND',
          message: 'User not found.',
        });
      }

      const deleted = await this.usersRepository.delete(user.user_id);
      this.logger.log(`Deactivated user ${userId}`);
      return deleted;
    } catch (error) {
      this.logFailure(`Deactivate user ${userId}`, error);
      throw error;
    }
  }

  private logFailure(operation: string, error: unknown): void {
    if (error instanceof HttpException && error.getStatus() < 500) {
      this.logger.warn(`${operation} failed (HTTP ${error.getStatus()})`);
      return;
    }

    const errorType =
      error instanceof Prisma.PrismaClientKnownRequestError
        ? `${error.name}, code=${error.code}`
        : error instanceof Error
          ? error.name
          : 'UnknownError';

    this.logger.error(`${operation} failed (${errorType})`);
  }
}

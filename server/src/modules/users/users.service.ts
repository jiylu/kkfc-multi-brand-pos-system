import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
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

    const user = await this.usersRepository.create(dto);

    this.logger.log(`
      Created new user with role: ${user.role} and user_id: ${user.user_id}
    `);

    return user;
  }

  async findAllUsers({ page, limit }: PaginationDTO) {
    this.logger.log(`Listing users: page=${page}, limit=${limit}`);

    const skip = (page - 1) * limit;

    if (skip > 2_147_483_647) {
      this.logger.warn(`Unsupported pagination range: ${skip}`);

      throw new BadRequestException({
        code: 'PAGINATION_UNSUPPORTED_RANGE',
        message: 'Requested page exceeds the supported range.',
      });
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
  }

  async findOneUser(userId: string) {
    this.logger.log(`Finding user ${userId}`);

    const user = await this.usersRepository.findOne(userId);

    this.assertUserExists(user);

    this.logger.log(`User ${user.user_id} with role ${user.role} found.`);

    return user;
  }

  async updateUser(userId: string, dto: UpdateUserDTO) {
    this.logger.log(`Updating user ${userId}`);

    const user = await this.findOneUser(userId);

    this.assertUserExists(user);

    const updated = await this.usersRepository.update(user.user_id, dto);
    this.logger.log(`Updated user ${userId}`);
    return updated;
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

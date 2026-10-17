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

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(private readonly usersRepository: UsersRepository) {}

  async createUser(dto: CreateUserDTO) {
    this.logger.log(`Creating ${dto.role} user ${dto.first_name}`);

    const existingUser = await this.usersRepository.findByUsername(
      dto.username,
      false,
    );

    if (existingUser) {
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

  async findAllUsers(
    { page, limit, activeOnly }: FindUsersDTO,
    callerId: string,
  ) {
    this.logger.log(
      `Listing users: page=${page}, limit=${limit}, activeOnly=${activeOnly}`,
    );

    const skip = (page - 1) * limit;
    assertValidPagination(skip, this.logger);

    const { users, total } = await this.usersRepository.findAll(
      callerId,
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

  async findOneUser(userId: string, callerId: string, activeOnly = true) {
    this.logger.log(`Finding user ${userId}`);

    const user = await this.usersRepository.findOne(userId, activeOnly);

    assertExists(user, 'User', userId, this.logger);

    if (userId !== callerId) {
      const caller = await this.usersRepository.findOne(callerId);
      assertExists(caller, 'User', callerId, this.logger);
      const brandIds = caller.user_brand_assignments_user.map(
        (assignment) => assignment.brand_id,
      );
      const sharedAssignments = user.user_brand_assignments_user.filter(
        (assignment) => brandIds.includes(assignment.brand_id),
      );
      if (sharedAssignments.length === 0) {
        throw new ForbiddenException({
          code: 'ACCESS_DENIED',
          message: 'You cannot access users outside your brands.',
        });
      }
      return { ...user, user_brand_assignments_user: sharedAssignments };
    }

    this.logger.log(`User ${user.user_id} with role ${user.role} found.`);

    return user;
  }

  async updateUser(userId: string, dto: UpdateUserDTO, callerId: string) {
    this.logger.log(`Updating user ${userId}`);

    const user = await this.findOneUser(userId, callerId);

    assertExists(user, 'User', userId, this.logger);

    if (
      userId !== callerId &&
      (user.role === UserRole.OWNER || dto.password !== undefined)
    ) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message:
          "You cannot edit another owner or change another user's password.",
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

  async deleteUser(userId: string, callerId: string) {
    this.logger.log(`Deactivating user ${userId}`);

    if (userId !== callerId) {
      throw new ForbiddenException({
        code: 'ACCESS_DENIED',
        message: 'You can only deactivate your own account.',
      });
    }

    const user = await this.findOneUser(userId, callerId);

    assertExists(user, 'User', userId, this.logger);

    const deleted = await this.usersRepository.delete(user.user_id);
    this.logger.log(`Deactivated user ${userId}`);
    return deleted;
  }
}

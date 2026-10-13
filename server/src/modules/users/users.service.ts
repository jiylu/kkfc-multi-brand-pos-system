import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { UsersRepository } from './users.repository';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { PaginationDTO } from '../../shared/dto/pagination.dto';

@Injectable()
export class UsersService {
  constructor(private readonly usersRepository: UsersRepository) {}

  async createUser(dto: CreateUserDTO) {
    return this.usersRepository.create(dto);
  }

  async findAllUsers({ page, limit }: PaginationDTO) {
    const skip = (page - 1) * limit;

    if (skip > 2_147_483_647) {
      throw new BadRequestException(
        'Requested page exceeds the supported range.',
      );
    }

    const { users, total } = await this.usersRepository.findAll(skip, limit);

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
    return this.usersRepository.findOne(userId);
  }

  async updateUser(userId: string, dto: UpdateUserDTO) {
    const user = await this.findOneUser(userId);

    if (!user) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found.',
      });
    }

    return await this.usersRepository.update(user.user_id, dto);
  }

  async deleteUser(userId: string) {
    const user = await this.findOneUser(userId);

    if (!user) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found.',
      });
    }

    return await this.usersRepository.delete(user.user_id);
  }
}

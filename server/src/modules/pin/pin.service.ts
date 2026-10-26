import {
  ConflictException,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { PinRepository } from './pin.repository';
import { CreatePinDTO } from './dto/create-pin.dto';
import { UsersRepository } from '../users/users.repository';
import { assertExists } from '../../shared/assertions/assert-exists';
import { UpdatePinDTO } from './dto/update-pin.dto';
import * as argon2 from 'argon2';

@Injectable()
export class PinService {
  private readonly logger = new Logger(PinService.name);
  constructor(
    private readonly pinRepository: PinRepository,
    private readonly usersRepository: UsersRepository,
  ) {}

  async create(dto: CreatePinDTO, userId: string) {
    this.logger.debug(`Creating pin for user ${userId}`);

    const existingPin = await this.pinRepository.findByUserId(userId);

    if (existingPin) {
      this.logger.warn(`Existing pin found for ${userId}`);

      throw new ConflictException({
        code: 'EXISTING_PIN_FOUND',
        message: 'User already has existing pin',
      });
    }

    const pin = await this.pinRepository.create(dto, userId);
    this.logger.log(`Created pin for ${pin.user_id}`);

    return pin;
  }

  async findOne(userId: string) {
    this.logger.debug(`Finding pin credentials for ${userId}`);

    const user = await this.usersRepository.findOne(userId);
    assertExists(user, 'User', userId, this.logger);

    const pinCredentials = await this.pinRepository.findOneSafe(userId);
    this.logger.log(`Found pin credentials for ${userId}`);

    return pinCredentials;
  }

  async verifyPin(userId: string, pin: string) {
    this.logger.debug(`Verifying pin for ${userId}`);

    const attempt = await this.pinRepository.verifyPin(userId, pin);
    this.logger.log(
      `Verification attempt for user ${userId}: ${attempt.status}`,
    );

    return attempt;
  }

  async updatePin(dto: UpdatePinDTO, userId: string) {
    this.logger.debug(`Updating pin for ${userId}`);

    const passwordHash = await this.resolvePasswordHash(userId);

    if (!(await argon2.verify(passwordHash, dto.password))) {
      this.logger.warn(`Invalid password credentials`);

      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid password.',
      });
    }

    const updatedPin = await this.pinRepository.update(dto, userId);
    this.logger.log(`Updated pin for ${userId}`);

    return updatedPin;
  }

  private async resolvePasswordHash(userId: string) {
    const userHash = await this.usersRepository.findCredentialsByUserId(userId);

    assertExists(userHash, 'User', userId, this.logger);

    return userHash.password_hash;
  }
}

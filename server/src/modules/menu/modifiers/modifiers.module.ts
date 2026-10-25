import { Module } from '@nestjs/common';
import { PrismaModule } from '../../../shared/prisma/prisma.module';
import { ModifiersController } from './modifiers.controller';
import { ModifiersRepository } from './modifiers.repository';
import { ModifiersService } from './modifiers.service';

@Module({
  imports: [PrismaModule],
  controllers: [ModifiersController],
  providers: [ModifiersService, ModifiersRepository],
})
export class ModifiersModule {}

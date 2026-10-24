import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../shared/prisma/prisma.service';

@Injectable()
export class MenuChannelsRepository {
  constructor(private readonly prisma: PrismaService) {}
}

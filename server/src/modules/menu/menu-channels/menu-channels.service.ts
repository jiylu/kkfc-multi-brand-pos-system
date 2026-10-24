import { Injectable } from '@nestjs/common';
import { MenuChannelsRepository } from './menu-channels.repository';

@Injectable()
export class MenuChannelsService {
  constructor(
    private readonly menuChannelsRepository: MenuChannelsRepository,
  ) {}
}

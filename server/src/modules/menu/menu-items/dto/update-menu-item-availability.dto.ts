import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class UpdateMenuItemAvailabilityDTO {
  @ApiProperty({
    description: 'Whether the menu item is available for new orders.',
    example: false,
  })
  @IsBoolean({ message: 'Availability must be true or false.' })
  availability!: boolean;
}

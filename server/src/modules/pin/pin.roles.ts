import { UserRole } from '@prisma/client';

export const PIN_ROLES: readonly UserRole[] = [
  UserRole.SUPERADMIN,
  UserRole.MANAGER,
  UserRole.RECIPE_MANAGER,
  UserRole.SUPERVISOR,
  UserRole.KITCHEN_HEAD,
];

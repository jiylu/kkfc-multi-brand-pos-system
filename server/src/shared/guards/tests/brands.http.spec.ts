import {
  Body,
  Controller,
  Get,
  INestApplication,
  Patch,
  Post,
  SetMetadata,
  UseGuards,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { Authenticated } from '../../../modules/auth/auth.guard';
import { AuthService } from '../../../modules/auth/auth.service';
import { UpdateMenuItemDTO } from '../../../modules/menu/menu-items/dto/update-menu-item.dto';
import {
  BRAND_RESOURCE_KEY,
  BrandResource,
  BrandResourceType,
} from '../../decorators/brand-resource.decorator';
import { PrismaService } from '../../prisma/prisma.service';
import { BrandsGuard } from '../brands.guard';

@Controller('brand-access')
@UseGuards(Authenticated, BrandsGuard)
class BrandAccessController {
  @Get(['menu-items/:identifier', 'brands/:brandId/menu-items/:identifier'])
  @BrandResource(BrandResourceType.MENU_ITEM, 'identifier')
  menuItem() {
    return { ok: true };
  }

  @Patch('menu-items/:identifier')
  @BrandResource(BrandResourceType.MENU_ITEM, 'identifier')
  updateMenuItem(@Body() dto: UpdateMenuItemDTO) {
    return dto;
  }

  @Get('users/:id')
  @BrandResource(BrandResourceType.USER, 'id')
  user() {
    return { ok: true };
  }

  @Get('missing-identifier')
  @BrandResource(BrandResourceType.MENU_ITEM, 'identifier')
  missingIdentifier() {
    return { ok: true };
  }

  @Get('unsupported-resource/:id')
  @SetMetadata(BRAND_RESOURCE_KEY, { resource: 'unsupported', param: 'id' })
  unsupportedResource() {
    return { ok: true };
  }

  @Get('brands/:brandId')
  directBrand() {
    return { ok: true };
  }

  @Post(['direct', 'brands/:brandId'])
  directBody() {
    return { ok: true };
  }
}

describe('BrandsGuard HTTP access', () => {
  const brandId = '00000000-0000-4000-8000-000000000001';
  const otherBrandId = '00000000-0000-4000-8000-000000000002';
  const resourceId = '00000000-0000-4000-8000-000000000003';
  const headers = {
    Authorization: 'Bearer session',
    'Content-Type': 'application/json',
  };
  const prisma = {
    menuItem: { findUnique: jest.fn() },
    user: { findUnique: jest.fn() },
  };
  const auth = { validateSession: jest.fn() };
  const resources = [
    {
      path: 'menu-items',
      model: 'menuItem',
      idField: 'menu_item_id',
      code: 'GC-RICE',
      codeField: 'code',
    },
    {
      path: 'users',
      model: 'user',
      idField: 'user_id',
      code: 'staff',
      codeField: 'username',
    },
  ] as const;
  let app: INestApplication;
  let url: string;
  let role: UserRole;
  let callerBrand: string | null;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [BrandAccessController],
      providers: [
        Authenticated,
        BrandsGuard,
        { provide: AuthService, useValue: auth },
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/brand-access`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    role = UserRole.CASHIER_STAFF;
    callerBrand = brandId;
    auth.validateSession.mockImplementation(() =>
      Promise.resolve({ user: { role, brand_id: callerBrand } }),
    );
    for (const model of Object.values(prisma))
      model.findUnique.mockResolvedValue({ brand_id: brandId });
  });

  afterAll(async () => app?.close());

  it.each(resources)(
    'resolves $model by UUID and selects only its brand',
    async ({ path, model, idField }) => {
      expect(
        (await fetch(`${url}/${path}/${resourceId}`, { headers })).status,
      ).toBe(200);
      expect(prisma[model].findUnique).toHaveBeenCalledWith({
        where: { [idField]: resourceId },
        select: { brand_id: true },
      });
    },
  );

  it.each(resources)(
    'resolves $model by its code or username',
    async ({ path, model, code, codeField }) => {
      expect((await fetch(`${url}/${path}/${code}`, { headers })).status).toBe(
        200,
      );
      expect(prisma[model].findUnique).toHaveBeenCalledWith({
        where: { [codeField]: code },
        select: { brand_id: true },
      });
    },
  );

  it.each(resources)(
    'requires authentication before looking up $model',
    async ({ path, model }) => {
      expect((await fetch(`${url}/${path}/${resourceId}`)).status).toBe(401);
      expect(prisma[model].findUnique).not.toHaveBeenCalled();
    },
  );

  it.each(resources)(
    'denies other-brand and unassigned callers for $model',
    async ({ path }) => {
      for (const brand of [otherBrandId, null]) {
        callerBrand = brand;
        expect(
          (await fetch(`${url}/${path}/${resourceId}`, { headers })).status,
        ).toBe(403);
      }
    },
  );

  it.each(resources)(
    'allows only superadmins to bypass $model brand restrictions',
    async ({ path }) => {
      callerBrand = null;
      role = UserRole.SUPERADMIN;
      expect(
        (await fetch(`${url}/${path}/${resourceId}`, { headers })).status,
      ).toBe(200);
      role = UserRole.MANAGER;
      expect(
        (await fetch(`${url}/${path}/${resourceId}`, { headers })).status,
      ).toBe(403);
    },
  );

  it.each(resources)(
    'returns 404 for missing $model even for superadmins',
    async ({ path, model }) => {
      prisma[model].findUnique.mockResolvedValue(null);
      for (const callerRole of [UserRole.CASHIER_STAFF, UserRole.SUPERADMIN]) {
        role = callerRole;
        expect(
          (await fetch(`${url}/${path}/${resourceId}`, { headers })).status,
        ).toBe(404);
      }
    },
  );

  it.each(resources)(
    'does not filter inactive $model records',
    async ({ path, model, idField }) => {
      prisma[model].findUnique.mockResolvedValue({
        brand_id: brandId,
        is_active: false,
      });
      expect(
        (await fetch(`${url}/${path}/${resourceId}`, { headers })).status,
      ).toBe(200);
      expect(prisma[model].findUnique).toHaveBeenCalledWith({
        where: { [idField]: resourceId },
        select: { brand_id: true },
      });
    },
  );

  it('does not treat two unassigned users as sharing a brand', async () => {
    prisma.user.findUnique.mockResolvedValue({ brand_id: null });
    for (const brand of [brandId, null]) {
      callerBrand = brand;
      expect(
        (await fetch(`${url}/users/${resourceId}`, { headers })).status,
      ).toBe(403);
    }
    role = UserRole.SUPERADMIN;
    expect(
      (await fetch(`${url}/users/${resourceId}`, { headers })).status,
    ).toBe(200);
  });

  it('rejects missing resource parameters before querying', async () => {
    expect((await fetch(`${url}/missing-identifier`, { headers })).status).toBe(
      400,
    );
    expect(prisma.menuItem.findUnique).not.toHaveBeenCalled();
  });

  it('rejects unsupported resource metadata without querying either model', async () => {
    role = UserRole.SUPERADMIN;
    expect(
      (await fetch(`${url}/unsupported-resource/${resourceId}`, { headers }))
        .status,
    ).toBe(500);
    for (const model of Object.values(prisma))
      expect(model.findUnique).not.toHaveBeenCalled();
  });

  it.each([UserRole.CASHIER_STAFF, UserRole.SUPERADMIN])(
    'rejects payload attempts to change resource ownership for %s',
    async (callerRole) => {
      role = callerRole;
      callerBrand = otherBrandId;
      expect(
        (
          await fetch(`${url}/menu-items/${resourceId}`, {
            method: 'PATCH',
            headers,
            body: JSON.stringify({ brand_id: otherBrandId }),
          })
        ).status,
      ).toBe(400);
    },
  );

  it('rejects brand_id in the update DTO even when it matches the stored brand', async () => {
    expect(
      (
        await fetch(`${url}/menu-items/${resourceId}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ brand_id: brandId }),
        })
      ).status,
    ).toBe(400);
    const response = await fetch(`${url}/menu-items/${resourceId}`, {
      method: 'PATCH',
      headers,
      body: JSON.stringify({ name: 'Updated' }),
    });
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ name: 'Updated' });
  });

  it('rejects a brand parameter that conflicts with the stored resource brand', async () => {
    expect(
      (
        await fetch(`${url}/brands/${otherBrandId}/menu-items/${resourceId}`, {
          headers,
        })
      ).status,
    ).toBe(400);
    expect(
      (
        await fetch(`${url}/brands/${brandId}/menu-items/${resourceId}`, {
          headers,
        })
      ).status,
    ).toBe(200);
  });

  it('keeps direct-brand parameter and payload access working without resource queries', async () => {
    expect((await fetch(`${url}/brands/${brandId}`, { headers })).status).toBe(
      200,
    );
    expect(
      (
        await fetch(`${url}/direct`, {
          method: 'POST',
          headers,
          body: JSON.stringify({ brand_id: brandId }),
        })
      ).status,
    ).toBe(201);
    expect(
      (await fetch(`${url}/brands/${otherBrandId}`, { headers })).status,
    ).toBe(403);
    role = UserRole.SUPERADMIN;
    callerBrand = null;
    expect(
      (await fetch(`${url}/brands/${otherBrandId}`, { headers })).status,
    ).toBe(200);
    for (const model of Object.values(prisma))
      expect(model.findUnique).not.toHaveBeenCalled();
  });

  it('preserves invalid and conflicting direct-brand rejection for superadmins', async () => {
    role = UserRole.SUPERADMIN;
    expect((await fetch(`${url}/brands/invalid`, { headers })).status).toBe(
      400,
    );
    expect(
      (await fetch(`${url}/direct`, { method: 'POST', headers })).status,
    ).toBe(400);
    expect(
      (
        await fetch(`${url}/brands/${brandId}`, {
          method: 'POST',
          headers,
          body: JSON.stringify({ brand_id: otherBrandId }),
        })
      ).status,
    ).toBe(400);
  });

  it.each(resources)(
    'does not swallow $model lookup failures',
    async ({ path, model }) => {
      prisma[model].findUnique.mockRejectedValue(
        new Error('Database unavailable'),
      );
      expect(
        (await fetch(`${url}/${path}/${resourceId}`, { headers })).status,
      ).toBe(500);
    },
  );
});

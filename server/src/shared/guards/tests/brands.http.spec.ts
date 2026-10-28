import { OrdersController } from '../../../modules/orders/orders.controller';
import { OrdersService } from '../../../modules/orders/orders.service';
import { PinGuard } from '../../../modules/pin/pin.guard';
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
import { MenuChannelsController } from '../../../modules/menu/menu-channels/menu-channels.controller';
import { MenuChannelsService } from '../../../modules/menu/menu-channels/menu-channels.service';
import {
  BRAND_RESOURCE_KEY,
  BrandResource,
  BrandResourceType,
} from '../../decorators/brand-resource.decorator';
import { PrismaService } from '../../prisma/prisma.service';
import { BrandsGuard } from '../brands.guard';
import { RolesGuard } from '../roles.guard';

@Controller('brand-access')
@UseGuards(Authenticated, BrandsGuard)
class BrandAccessController {
  @Get(['menu-items/:identifier', 'brands/:brandId/menu-items/:identifier'])
  @BrandResource(BrandResourceType.MENU_ITEM, 'identifier')
  menuItem() {
    return { ok: true };
  }

  @Get('menu-item-channels/:id')
  @BrandResource(BrandResourceType.MENU_ITEM_CHANNEL, 'id')
  menuItemChannel() {
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

  @Get('brand-resources/:id')
  @BrandResource(BrandResourceType.BRAND, 'id')
  brand() {
    return { ok: true };
  }

  @Get('orders/:id')
  @BrandResource(BrandResourceType.ORDER, 'id')
  order() {
    return { ok: true };
  }

  @Get('recipes/:id')
  @BrandResource(BrandResourceType.RECIPE, 'id')
  recipe() {
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
    brand: { findUnique: jest.fn() },
    menuItem: { findUnique: jest.fn() },
    menuItemChannel: { findUnique: jest.fn() },
    order: { findUnique: jest.fn() },
    recipe: { findUnique: jest.fn() },
    user: { findUnique: jest.fn() },
  };
  const auth = { validateSession: jest.fn() };
  const orders = { create: jest.fn(), verify: jest.fn(), confirm: jest.fn() };
  const menuChannels = { create: jest.fn() };
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
    { path: 'brand-resources', model: 'brand', idField: 'brand_id' },
    { path: 'orders', model: 'order', idField: 'order_id' },
    { path: 'recipes', model: 'recipe', idField: 'recipe_id' },
  ] as const;
  let app: INestApplication;
  let url: string;
  let menuChannelsUrl: string;
  let role: UserRole;
  let callerBrand: string | null;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [
        BrandAccessController,
        MenuChannelsController,
        OrdersController,
      ],
      providers: [
        Authenticated,
        BrandsGuard,
        RolesGuard,
        { provide: AuthService, useValue: auth },
        { provide: PrismaService, useValue: prisma },
        { provide: MenuChannelsService, useValue: menuChannels },
        { provide: OrdersService, useValue: orders },
      ],
    })
      .overrideGuard(PinGuard)
      .useValue({ canActivate: () => true })
      .compile();
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
    menuChannelsUrl = `${await app.getUrl()}/menu-channels`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    role = UserRole.CASHIER_STAFF;
    callerBrand = brandId;
    menuChannels.create.mockResolvedValue({ ok: true });
    auth.validateSession.mockImplementation(() =>
      Promise.resolve({ user: { role, brand_id: callerBrand } }),
    );
    for (const model of Object.values(prisma))
      model.findUnique.mockResolvedValue({ brand_id: brandId });
    prisma.menuItemChannel.findUnique.mockResolvedValue({
      menu_item: { brand_id: brandId },
    });
  });

  afterAll(async () => app?.close());

  it.each(['verify', 'confirm'] as const)(
    'authorizes the actual order brand before %s, including for superadmins',
    async (operation) => {
      orders[operation].mockResolvedValue({ ok: true });
      const endpoint = `${await app.getUrl()}/brands/${brandId}/orders/${resourceId}/${operation}`;
      const send = () =>
        fetch(endpoint, { method: 'POST', headers, body: '{}' });
      expect((await send()).status).toBe(200);
      expect(prisma.order.findUnique).toHaveBeenCalledWith({
        where: { order_id: resourceId },
        select: { brand_id: true },
      });
      orders[operation].mockClear();
      callerBrand = otherBrandId;
      expect((await send()).status).toBe(403);
      expect(orders[operation]).not.toHaveBeenCalled();
      role = UserRole.SUPERADMIN;
      expect((await send()).status).toBe(200);
      orders[operation].mockClear();
      prisma.order.findUnique.mockResolvedValue({ brand_id: otherBrandId });
      expect((await send()).status).toBe(400);
      expect(orders[operation]).not.toHaveBeenCalled();
      prisma.order.findUnique.mockResolvedValue(null);
      expect((await send()).status).toBe(404);
    },
  );

  it('resolves the brand resource before creating an order', async () => {
    const endpoint = `${await app.getUrl()}/brands/${brandId}/orders`;
    const body = JSON.stringify({
      order_id: resourceId,
      order_channel: 'TAKEAWAY',
      lines: [{ menu_item_id: resourceId, quantity: 1 }],
    });
    orders.create.mockResolvedValue({ ok: true });
    expect(
      (await fetch(endpoint, { method: 'POST', headers, body })).status,
    ).toBe(201);
    expect(prisma.brand.findUnique).toHaveBeenCalledWith({
      where: { brand_id: brandId },
      select: { brand_id: true },
    });
    orders.create.mockClear();
    prisma.brand.findUnique.mockResolvedValue(null);
    expect(
      (await fetch(endpoint, { method: 'POST', headers, body })).status,
    ).toBe(404);
    expect(orders.create).not.toHaveBeenCalled();
  });

  it.each([
    { callerRole: UserRole.MANAGER, brand: brandId, status: 201 },
    { callerRole: UserRole.MANAGER, brand: otherBrandId, status: 403 },
    { callerRole: UserRole.MANAGER, brand: null, status: 403 },
    { callerRole: UserRole.SUPERADMIN, brand: null, status: 201 },
  ])(
    'resolves the create body menu item for $callerRole in brand $brand',
    async ({ callerRole, brand, status }) => {
      role = callerRole;
      callerBrand = brand;
      const dto = {
        menu_item_id: resourceId,
        order_channel: 'GRABFOOD',
        price: 120,
      };
      const response = await fetch(menuChannelsUrl, {
        method: 'POST',
        headers,
        body: JSON.stringify(dto),
      });
      expect(response.status).toBe(status);
      expect(prisma.menuItem.findUnique).toHaveBeenCalledWith({
        where: { menu_item_id: resourceId },
        select: { brand_id: true },
      });
      expect(menuChannels.create.mock.calls).toEqual(
        status === 201 ? [[dto]] : [],
      );
    },
  );

  it.each([undefined, null, '', '   ', 123, {}, []])(
    'rejects an invalid body resource identifier %j before looking it up',
    async (identifier) => {
      role = UserRole.MANAGER;
      const response = await fetch(menuChannelsUrl, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          menu_item_id: identifier,
          order_channel: 'GRABFOOD',
          price: 120,
        }),
      });
      expect(response.status).toBe(400);
      expect(await response.json()).toMatchObject({
        code: 'INVALID_RESOURCE_IDENTIFIER',
      });
      expect(prisma.menuItem.findUnique).not.toHaveBeenCalled();
      expect(menuChannels.create).not.toHaveBeenCalled();
    },
  );

  it('rejects attempts to spoof body resource ownership with brand_id', async () => {
    role = UserRole.MANAGER;
    callerBrand = otherBrandId;
    const response = await fetch(menuChannelsUrl, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        menu_item_id: resourceId,
        brand_id: otherBrandId,
        order_channel: 'GRABFOOD',
        price: 120,
      }),
    });
    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({
      code: 'BRAND_ID_MUST_MATCH_RESOURCE_BRAND',
    });
    expect(menuChannels.create).not.toHaveBeenCalled();
  });

  it('returns 404 for missing body resources even for superadmins', async () => {
    role = UserRole.SUPERADMIN;
    prisma.menuItem.findUnique.mockResolvedValue(null);
    expect(
      (
        await fetch(menuChannelsUrl, {
          method: 'POST',
          headers,
          body: JSON.stringify({
            menu_item_id: resourceId,
            order_channel: 'GRABFOOD',
            price: 120,
          }),
        })
      ).status,
    ).toBe(404);
    expect(menuChannels.create).not.toHaveBeenCalled();
  });

  it.each([
    { callerRole: UserRole.CASHIER_STAFF, brand: brandId, status: 200 },
    { callerRole: UserRole.CASHIER_STAFF, brand: otherBrandId, status: 403 },
    { callerRole: UserRole.MANAGER, brand: null, status: 403 },
    { callerRole: UserRole.SUPERADMIN, brand: null, status: 200 },
  ])(
    'checks menu item channel access for $callerRole in brand $brand',
    async ({ callerRole, brand, status }) => {
      role = callerRole;
      callerBrand = brand;
      expect(
        (await fetch(`${url}/menu-item-channels/${resourceId}`, { headers }))
          .status,
      ).toBe(status);
      expect(prisma.menuItemChannel.findUnique).toHaveBeenCalledWith({
        where: { menu_item_channel_id: resourceId },
        select: { menu_item: { select: { brand_id: true } } },
      });
    },
  );

  it('rejects invalid menu item channel UUIDs before querying', async () => {
    expect(
      (await fetch(`${url}/menu-item-channels/invalid`, { headers })).status,
    ).toBe(400);
    expect(prisma.menuItemChannel.findUnique).not.toHaveBeenCalled();
  });

  it.each([UserRole.CASHIER_STAFF, UserRole.SUPERADMIN])(
    'returns 404 for missing menu item channels for %s',
    async (callerRole) => {
      role = callerRole;
      prisma.menuItemChannel.findUnique.mockResolvedValue(null);
      const response = await fetch(`${url}/menu-item-channels/${resourceId}`, {
        headers,
      });
      expect(response.status).toBe(404);
      expect(await response.json()).toMatchObject({
        message: 'MenuItemChannel not found.',
      });
    },
  );

  it('resolves unavailable menu item channels without filtering their state', async () => {
    prisma.menuItemChannel.findUnique.mockResolvedValue({
      menu_item: { brand_id: brandId },
      is_available: false,
    });
    expect(
      (await fetch(`${url}/menu-item-channels/${resourceId}`, { headers }))
        .status,
    ).toBe(200);
    expect(prisma.menuItemChannel.findUnique).toHaveBeenCalledWith({
      where: { menu_item_channel_id: resourceId },
      select: { menu_item: { select: { brand_id: true } } },
    });
  });

  it('requires authentication before looking up menu item channels', async () => {
    expect(
      (await fetch(`${url}/menu-item-channels/${resourceId}`)).status,
    ).toBe(401);
    expect(prisma.menuItemChannel.findUnique).not.toHaveBeenCalled();
  });

  it('does not swallow menu item channel lookup failures', async () => {
    prisma.menuItemChannel.findUnique.mockRejectedValue(
      new Error('Database unavailable'),
    );
    expect(
      (await fetch(`${url}/menu-item-channels/${resourceId}`, { headers }))
        .status,
    ).toBe(500);
  });

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

  it.each(resources.filter((resource) => 'code' in resource))(
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

  it.each(resources.filter((resource) => resource.model !== 'order'))(
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

  it.each(resources.filter((resource) => !('code' in resource)))(
    'rejects invalid UUIDs for $model before querying',
    async ({ path, model }) => {
      expect((await fetch(`${url}/${path}/invalid`, { headers })).status).toBe(
        400,
      );
      expect(prisma[model].findUnique).not.toHaveBeenCalled();
    },
  );

  it('checks cancelled orders by brand without imposing order-status rules', async () => {
    prisma.order.findUnique.mockResolvedValue({
      brand_id: brandId,
      status: 'CANCELLED',
    });
    expect(
      (await fetch(`${url}/orders/${resourceId}`, { headers })).status,
    ).toBe(200);
    expect(prisma.order.findUnique).toHaveBeenCalledWith({
      where: { order_id: resourceId },
      select: { brand_id: true },
    });
  });

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

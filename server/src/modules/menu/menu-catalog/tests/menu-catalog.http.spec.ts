import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../../../shared/prisma/prisma.service';
import { AuthService } from '../../../auth/auth.service';
import { PinService } from '../../../pin/pin.service';
import { MenuCatalogController } from '../menu-catalog.controller';
import { MenuCatalogService } from '../menu-catalog.service';

describe('Menu catalog HTTP endpoints', () => {
  const brandId = '00000000-0000-4000-8000-000000000001';
  const otherBrandId = '00000000-0000-4000-8000-000000000002';
  const user = {
    user_id: '00000000-0000-4000-8000-000000000003',
    brand_id: brandId,
    role: UserRole.MANAGER,
  };
  const dto = {
    menu_item: {
      brand_id: brandId,
      recipe_id: '00000000-0000-4000-8000-000000000004',
      img_url: 'https://example.com/rice.jpg',
      code: 'RICE',
      name: 'Rice',
      base_price: 100,
    },
    menu_channel: [{ order_channel: 'GRABFOOD', price: 120 }],
    menu_item_modifier: [
      { modifier_id: '00000000-0000-4000-8000-000000000005' },
    ],
  };
  const createdEntry = {
    ...dto.menu_item,
    menu_item_id: 'created-item',
    menuChannels: [{ ...dto.menu_channel[0], menu_item_id: 'created-item' }],
    menuItemModifiers: [
      {
        ...dto.menu_item_modifier[0],
        menu_item_id: 'created-item',
        modifier: {
          modifier_id: dto.menu_item_modifier[0].modifier_id,
          name: 'Extra cheese',
        },
      },
    ],
  };
  const service = { create: jest.fn(), findAll: jest.fn() };
  const auth = { validateSession: jest.fn() };
  const pin = { verifyPin: jest.fn() };
  const brandLookup = jest.fn();
  const headers = {
    authorization: 'Bearer session-token',
    'content-type': 'application/json',
    'x-action-pin': '1234',
  };
  let app: INestApplication;
  let url: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [MenuCatalogController],
      providers: [
        { provide: MenuCatalogService, useValue: service },
        { provide: AuthService, useValue: auth },
        { provide: PinService, useValue: pin },
        {
          provide: PrismaService,
          useValue: { brand: { findUnique: brandLookup } },
        },
      ],
    }).compile();
    app = module.createNestApplication();
    app.useLogger(false);
    app.setGlobalPrefix('api');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0, '127.0.0.1');
    url = `${await app.getUrl()}/api/menu-catalog`;
  });

  beforeEach(() => {
    jest.resetAllMocks();
    service.create.mockResolvedValue(createdEntry);
    service.findAll.mockResolvedValue({ data: [], meta: { total: 0 } });
    auth.validateSession.mockResolvedValue({ user });
    pin.verifyPin.mockResolvedValue({ status: 'valid' });
    brandLookup.mockResolvedValue({ brand_id: brandId });
  });

  afterAll(async () => app?.close());

  it('creates a catalog entry for a manager assigned to its nested brand', async () => {
    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(dto),
    });

    expect(response.status).toBe(201);
    expect(await response.json()).toEqual(createdEntry);
    expect(service.create).toHaveBeenCalledWith(dto);
    expect(brandLookup).toHaveBeenCalledWith({
      where: { brand_id: brandId },
      select: { brand_id: true },
    });
    expect(pin.verifyPin).toHaveBeenCalledWith(user.user_id, '1234');
  });

  it.each([
    { query: '', pagination: { page: 1, limit: 10 } },
    { query: '?page=2&limit=5', pagination: { page: 2, limit: 5 } },
  ])(
    'lists a brand catalog with query "$query"',
    async ({ query, pagination }) => {
      const response = await fetch(`${url}/brand/${brandId}${query}`, {
        headers: { authorization: headers.authorization },
      });

      expect(response.status).toBe(200);
      expect(await response.json()).toEqual({ data: [], meta: { total: 0 } });
      expect(service.findAll).toHaveBeenCalledWith(brandId, pagination);
      expect(pin.verifyPin).not.toHaveBeenCalled();
    },
  );

  it('requires authentication to create and list entries', async () => {
    const createResponse = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(dto),
    });
    const listResponse = await fetch(`${url}/brand/${brandId}`);

    expect(createResponse.status).toBe(401);
    expect(listResponse.status).toBe(401);
    expect(service.create).not.toHaveBeenCalled();
    expect(service.findAll).not.toHaveBeenCalled();
  });

  it('rejects creation by roles that cannot create menu items', async () => {
    auth.validateSession.mockResolvedValue({
      user: { ...user, role: UserRole.CASHIER_STAFF },
    });
    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify(dto),
    });

    expect(response.status).toBe(403);
    expect(service.create).not.toHaveBeenCalled();
  });

  it('rejects creation for another brand even when the brand is nested', async () => {
    brandLookup.mockResolvedValue({ brand_id: otherBrandId });
    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        ...dto,
        menu_item: { ...dto.menu_item, brand_id: otherBrandId },
      }),
    });

    expect(response.status).toBe(403);
    expect(service.create).not.toHaveBeenCalled();
    expect(pin.verifyPin).not.toHaveBeenCalled();
  });

  it('rejects listing a brand the caller is not assigned to', async () => {
    const response = await fetch(`${url}/brand/${otherBrandId}`, { headers });
    expect(response.status).toBe(403);
    expect(service.findAll).not.toHaveBeenCalled();
  });

  it('requires an action PIN for creation', async () => {
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        authorization: headers.authorization,
        'content-type': 'application/json',
      },
      body: JSON.stringify(dto),
    });

    expect(response.status).toBe(403);
    expect(service.create).not.toHaveBeenCalled();
  });

  it.each([undefined, null, {}])(
    'rejects a missing nested brand in menu_item=%j',
    async (menu_item) => {
      const response = await fetch(url, {
        method: 'POST',
        headers,
        body: JSON.stringify({ ...dto, menu_item }),
      });

      expect(response.status).toBe(400);
      expect(service.create).not.toHaveBeenCalled();
    },
  );

  it('validates nested modifier IDs', async () => {
    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        ...dto,
        menu_item_modifier: [{ modifier_id: 'invalid' }],
      }),
    });

    expect(response.status).toBe(400);
    expect(service.create).not.toHaveBeenCalled();
  });

  it.each(['?page=0', '?limit=101'])(
    'rejects invalid pagination %s',
    async (query) => {
      const response = await fetch(`${url}/brand/${brandId}${query}`, {
        headers,
      });
      expect(response.status).toBe(400);
      expect(service.findAll).not.toHaveBeenCalled();
    },
  );

  it('rejects malformed brand IDs', async () => {
    const response = await fetch(`${url}/brand/invalid`, { headers });
    expect(response.status).toBe(400);
    expect(service.findAll).not.toHaveBeenCalled();
  });
});

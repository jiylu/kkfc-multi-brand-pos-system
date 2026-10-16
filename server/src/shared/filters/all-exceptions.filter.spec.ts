import {
  BadRequestException,
  ConflictException,
  Controller,
  Get,
  INestApplication,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { Prisma } from '@prisma/client';
import { AllExceptionsFilter } from './all-exceptions.filter';
import { PrismaExceptionFilter } from './prisma-exception.filter';

describe('AllExceptionsFilter', () => {
  let app: INestApplication;
  let url: string;
  let failure: unknown;
  let warn: jest.SpyInstance;
  let error: jest.SpyInstance;

  @Controller()
  class TestController {
    @Get()
    fail() {
      throw failure;
    }
  }

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      controllers: [TestController],
      providers: [
        { provide: APP_FILTER, useClass: AllExceptionsFilter },
        { provide: APP_FILTER, useClass: PrismaExceptionFilter },
      ],
    }).compile();
    app = module.createNestApplication();
    await app.listen(0, '127.0.0.1');
    url = await app.getUrl();
  });

  beforeEach(() => {
    warn = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    error = jest.spyOn(Logger.prototype, 'error').mockImplementation();
  });

  afterEach(() => jest.restoreAllMocks());
  afterAll(async () => app?.close());

  it('UT-SHRD-001: preserves application error codes and logs client errors as warnings', async () => {
    const body = { code: 'USER_NOT_FOUND', message: 'User not found.' };
    failure = new BadRequestException(body);

    const response = await fetch(url);

    expect(response.status).toBe(400);
    expect(await response.json()).toEqual(body);
    expect(warn).toHaveBeenCalledWith('BadRequestException (HTTP 400)');
    expect(error).not.toHaveBeenCalled();
  });

  it('UT-SHRD-002: preserves validation message arrays', async () => {
    failure = new BadRequestException(['username must be a string']);

    const response = await fetch(url);

    expect(response.status).toBe(400);
    expect(await response.json()).toEqual({
      statusCode: 400,
      error: 'Bad Request',
      message: ['username must be a string'],
    });
  });

  it.each([
    {
      code: 'P2002',
      status: 409,
      body: {
        code: 'DUPLICATE_RESOURCE',
        message: 'A record with these unique values already exists.',
      },
      exceptionName: 'ConflictException',
    },
    {
      code: 'P2025',
      status: 404,
      body: {
        code: 'RESOURCE_NOT_FOUND',
        message: 'The requested record was not found.',
      },
      exceptionName: 'NotFoundException',
    },
  ])(
    'UT-SHRD-003: maps $code to HTTP $status without exposing database details',
    async ({ code, status, body, exceptionName }) => {
      failure = new Prisma.PrismaClientKnownRequestError(
        'private database details',
        {
          code,
          clientVersion: '7.8.0',
          meta: { target: ['username'] },
        },
      );

      const response = await fetch(url);

      expect(response.status).toBe(status);
      expect(await response.json()).toEqual(body);
      expect(warn).toHaveBeenCalledTimes(1);
      expect(warn).toHaveBeenCalledWith(`${exceptionName} (HTTP ${status})`);
      expect(error).not.toHaveBeenCalled();
    },
  );

  it('UT-SHRD-004: preserves custom service not-found responses', async () => {
    const body = { code: 'USER_NOT_FOUND', message: 'User not found.' };
    failure = new NotFoundException(body);

    const response = await fetch(url);

    expect(response.status).toBe(404);
    expect(await response.json()).toEqual(body);
  });

  it('UT-SHRD-005: preserves custom service conflict responses', async () => {
    const body = {
      code: 'USERNAME_ALREADY_EXISTS',
      message: 'Username already exists.',
    };
    failure = new ConflictException(body);

    const response = await fetch(url);

    expect(response.status).toBe(409);
    expect(await response.json()).toEqual(body);
  });

  it.each(['P1001', 'P2003'])(
    'UT-SHRD-006: keeps unhandled Prisma error %s as a server error',
    async (code) => {
      failure = new Prisma.PrismaClientKnownRequestError(
        'private database details',
        {
          code,
          clientVersion: '7.8.0',
        },
      );

      const response = await fetch(url);

      expect(response.status).toBe(500);
      expect(await response.json()).toEqual({
        statusCode: 500,
        message: 'Internal server error',
      });
      expect(error).toHaveBeenCalledTimes(1);
      expect(warn).not.toHaveBeenCalled();
    },
  );

  it('UT-SHRD-007: logs HTTP server errors once', async () => {
    failure = new InternalServerErrorException();

    const response = await fetch(url);

    expect(response.status).toBe(500);
    expect(error).toHaveBeenCalledTimes(1);
    expect(error).toHaveBeenCalledWith(
      'InternalServerErrorException (HTTP 500)',
    );
    expect(warn).not.toHaveBeenCalled();
  });

  it.each([new Error('private database details'), 'unexpected value', null])(
    'UT-SHRD-008: delegates unexpected failures to Nest without leaking details: %s',
    async (exception) => {
      failure = exception;

      const response = await fetch(url);

      expect(response.status).toBe(500);
      expect(await response.json()).toEqual({
        statusCode: 500,
        message: 'Internal server error',
      });
      expect(error).toHaveBeenCalledTimes(1);
      expect(warn).not.toHaveBeenCalled();
    },
  );
});

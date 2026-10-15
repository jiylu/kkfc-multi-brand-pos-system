import {
  BadRequestException,
  Controller,
  Get,
  INestApplication,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { AllExceptionsFilter } from './all-exceptions.filter';

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
      providers: [{ provide: APP_FILTER, useClass: AllExceptionsFilter }],
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

  it('preserves application error codes and logs client errors as warnings', async () => {
    const body = { code: 'USER_NOT_FOUND', message: 'User not found.' };
    failure = new BadRequestException(body);

    const response = await fetch(url);

    expect(response.status).toBe(400);
    expect(await response.json()).toEqual(body);
    expect(warn).toHaveBeenCalledWith('BadRequestException (HTTP 400)');
    expect(error).not.toHaveBeenCalled();
  });

  it('preserves validation message arrays', async () => {
    failure = new BadRequestException(['username must be a string']);

    const response = await fetch(url);

    expect(response.status).toBe(400);
    expect(await response.json()).toEqual({
      statusCode: 400,
      error: 'Bad Request',
      message: ['username must be a string'],
    });
  });

  it('logs HTTP server errors once', async () => {
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
    'delegates unexpected failures to Nest without leaking details: %s',
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

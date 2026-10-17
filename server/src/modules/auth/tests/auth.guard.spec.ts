import {
  ExecutionContext,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Authenticated } from '../auth.guard';
import { AuthService } from '../auth.service';

describe('Authenticated Guard (UT-AUTH)', () => {
  const session = {
    session_id: 'session-id',
    user_id: 'user-id',
    created_at: new Date('2030-01-01T12:00:00Z'),
    expires_at: new Date('2030-01-01T20:00:00Z'),
    last_seen_at: new Date('2030-01-01T12:00:00Z'),
    user: {
      user_id: 'user-id',
      username: 'owner',
      first_name: 'Test',
      last_name: 'Owner',
      role: 'OWNER',
      is_active: true,
      created_at: new Date('2030-01-01T12:00:00Z'),
      modified_at: new Date('2030-01-01T12:00:00Z'),
      user_brand_assignments_user: [],
    },
  };

  let authService: jest.Mocked<Pick<AuthService, 'validateSession'>>;
  let guard: Authenticated;

  beforeEach(() => {
    authService = {
      validateSession: jest.fn().mockResolvedValue(session),
    };
    guard = new Authenticated(authService as unknown as AuthService);
  });

  function createContext(authorization?: string): {
    context: ExecutionContext;
    request: { headers: { authorization?: string }; session?: unknown };
  } {
    const request: { headers: { authorization?: string }; session?: unknown } =
      {
        headers: authorization !== undefined ? { authorization } : {},
      };
    const context = {
      switchToHttp: () => ({
        getRequest: () => request,
      }),
    } as unknown as ExecutionContext;
    return { context, request };
  }

  it('UT-AUTH-013: attaches validated session and returns true for valid Bearer token', async () => {
    const { context, request } = createContext('Bearer valid-session-token');

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(authService.validateSession).toHaveBeenCalledWith(
      'valid-session-token',
    );
    expect(request.session).toEqual(session);
  });

  it.each([undefined, '', 'Basic abc123', 'Bearer', 'Bearer tok1 tok2'])(
    'UT-AUTH-014: rejects missing or malformed Authorization header (%s) with SESSION_TOKEN_REQUIRED',
    async (header) => {
      const { context } = createContext(header);

      await expect(guard.canActivate(context)).rejects.toMatchObject({
        status: 401,
        response: {
          code: 'SESSION_TOKEN_REQUIRED',
          message: 'A bearer session token is required.',
        },
      });
      expect(authService.validateSession).not.toHaveBeenCalled();
    },
  );

  it('UT-AUTH-015: maps NotFoundException from validateSession to INVALID_SESSION UnauthorizedException', async () => {
    authService.validateSession.mockRejectedValue(
      new NotFoundException({ code: 'USER_NOT_FOUND' }),
    );
    const { context } = createContext('Bearer orphaned-session-token');

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    await expect(guard.canActivate(context)).rejects.toMatchObject({
      status: 401,
      response: {
        code: 'INVALID_SESSION',
        message: 'Invalid or expired session.',
      },
    });
  });

  it('UT-AUTH-016: rethrows non-NotFoundException errors from validateSession', async () => {
    const error = new UnauthorizedException({
      code: 'EXPIRED_SESSION',
      message: 'Invalid or expired session.',
    });
    authService.validateSession.mockRejectedValue(error);
    const { context } = createContext('Bearer expired-token');

    await expect(guard.canActivate(context)).rejects.toBe(error);
  });
});

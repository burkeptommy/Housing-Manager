import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthPayload } from './firebase-auth.guard';

/**
 * Decorator to extract the current authenticated user from the request.
 *
 * Usage:
 * - @CurrentUser() user: AuthPayload - gets full user payload
 * - @CurrentUser('userId') userId: string - gets specific property
 * - @CurrentUser('householdId') householdId: string | null - gets household ID
 */
export const CurrentUser = createParamDecorator(
  (data: keyof AuthPayload | undefined, ctx: ExecutionContext): AuthPayload | string | null => {
    const request = ctx.switchToHttp().getRequest();
    const user = request.user as AuthPayload;

    if (!user) {
      return null as any;
    }

    return data ? user[data] : user;
  },
);

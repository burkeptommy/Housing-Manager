import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';

import { JwtPayload } from '../../auth';
import { AuthPayload } from '../../firebase';
import { PrismaService } from '../../prisma';

// Metadata keys
export const HOUSEHOLD_ACCESS_PARAM_KEY = 'householdAccessParam';
export const ALLOW_OWNER_KEY = 'allowOwner';
export const ALLOW_MANAGER_KEY = 'allowManager';
export const ALLOW_MEMBER_KEY = 'allowMember';

/**
 * Decorator to specify which route parameter contains the household ID
 * Defaults to 'householdId'
 */
export const HouseholdAccessParam = (param: string = 'householdId') =>
  SetMetadata(HOUSEHOLD_ACCESS_PARAM_KEY, param);

/**
 * Decorator to allow household owners access
 */
export const AllowOwner = () => SetMetadata(ALLOW_OWNER_KEY, true);

/**
 * Decorator to allow assigned managers access
 */
export const AllowManager = () => SetMetadata(ALLOW_MANAGER_KEY, true);

/**
 * Decorator to allow household members access
 */
export const AllowMember = () => SetMetadata(ALLOW_MEMBER_KEY, true);

/**
 * Interface for user info from either JWT or Firebase auth
 */
interface UserInfo {
  userId: string;
  role: UserRole;
}

/**
 * HouseholdAccessGuard - Enforces role-based access control for households
 *
 * Permission Model:
 * - ADMIN: Can access ALL households (platform-wide access)
 * - MANAGER: Can ONLY access households where household.managerId === user.id
 * - HOMEOWNER: Can access households where they are the owner OR active member
 * - VENDOR: Handled separately through work order assignments
 *
 * Usage:
 * @UseGuards(FirebaseAuthGuard, HouseholdAccessGuard)
 * @HouseholdAccessParam('id')  // optional, specify the param name containing household ID
 * @AllowOwner()                // allow household owners
 * @AllowManager()              // allow assigned managers
 * @AllowMember()               // allow household members
 */
@Injectable()
export class HouseholdAccessGuard implements CanActivate {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    // Extract user info from either JWT or Firebase auth
    const userInfo = this.extractUserInfo(request);

    if (!userInfo) {
      throw new ForbiddenException('User not authenticated');
    }

    // ADMIN can access everything
    if (userInfo.role === UserRole.ADMIN) {
      return true;
    }

    // Get household ID from request
    const householdId = this.extractHouseholdId(context, request);

    if (!householdId) {
      // No household ID to check - allow (for list endpoints, filtering happens in service)
      return true;
    }

    // Fetch the household with owner and manager info
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: {
        id: true,
        name: true,
        ownerId: true,
        managerId: true,
      },
    });

    if (!household) {
      throw new NotFoundException(`Household with ID ${householdId} not found`);
    }

    // Get permission settings from decorators
    const allowOwner = this.reflector.getAllAndOverride<boolean>(ALLOW_OWNER_KEY, [
      context.getHandler(),
      context.getClass(),
    ]) ?? true; // Default to allowing owners

    const allowManager = this.reflector.getAllAndOverride<boolean>(ALLOW_MANAGER_KEY, [
      context.getHandler(),
      context.getClass(),
    ]) ?? true; // Default to allowing managers

    const allowMember = this.reflector.getAllAndOverride<boolean>(ALLOW_MEMBER_KEY, [
      context.getHandler(),
      context.getClass(),
    ]) ?? false; // Default to NOT allowing members (they need explicit permission)

    // Check access based on user role
    switch (userInfo.role) {
      case UserRole.MANAGER:
        // Managers can only access households they manage
        if (allowManager && household.managerId === userInfo.userId) {
          request.household = household;
          request.accessType = 'manager';
          return true;
        }
        throw new ForbiddenException('You are not assigned as the manager of this household');

      case UserRole.HOMEOWNER:
        // Check if user is the owner
        if (allowOwner && household.ownerId === userInfo.userId) {
          request.household = household;
          request.accessType = 'owner';
          return true;
        }

        // Check if user is a member
        if (allowMember) {
          const membership = await this.prisma.householdMember.findUnique({
            where: {
              householdId_userId: {
                householdId,
                userId: userInfo.userId,
              },
            },
          });

          if (membership && membership.status === 'ACTIVE') {
            request.household = household;
            request.householdMembership = membership;
            request.accessType = 'member';
            return true;
          }
        }
        throw new ForbiddenException('You do not have access to this household');

      case UserRole.VENDOR:
        // Vendors don't access households directly - they access work orders
        // This should be handled by a separate WorkOrderAccessGuard
        throw new ForbiddenException('Vendors cannot access households directly');

      default:
        throw new ForbiddenException('Unknown user role');
    }
  }

  /**
   * Extract household ID from request params, body, or query
   */
  private extractHouseholdId(context: ExecutionContext, request: any): string | null {
    // Get custom param name from decorator, default to common names
    const paramName = this.reflector.get<string>(
      HOUSEHOLD_ACCESS_PARAM_KEY,
      context.getHandler(),
    );

    // Try different sources in order of priority
    if (paramName) {
      return request.params[paramName] || request.body?.[paramName] || request.query?.[paramName];
    }

    // Try common parameter names
    return (
      request.params.householdId ||
      request.params.id ||
      request.body?.householdId ||
      request.query?.householdId
    );
  }

  /**
   * Extract user info from either JWT or Firebase auth payload
   */
  private extractUserInfo(request: any): UserInfo | null {
    // Check for Firebase auth payload (from FirebaseAuthGuard)
    if (request.user?.userId) {
      const firebaseUser = request.user as AuthPayload;
      return {
        userId: firebaseUser.userId,
        role: firebaseUser.role as UserRole,
      };
    }

    // Check for JWT payload (from JwtAuthGuard)
    if (request.user?.sub) {
      const jwtUser = request.user as JwtPayload;
      return {
        userId: jwtUser.sub,
        role: jwtUser.role as UserRole,
      };
    }

    return null;
  }
}

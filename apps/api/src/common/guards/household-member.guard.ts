import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { HouseholdRole } from '@prisma/client';

import { JwtPayload } from '../../auth';
import { AuthPayload } from '../../firebase';
import { PrismaService } from '../../prisma';

export const HOUSEHOLD_ID_PARAM = 'householdIdParam';
export const HOUSEHOLD_ROLES_KEY = 'householdRoles';

/**
 * Decorator to specify which route parameter contains the household ID
 * Defaults to 'id'
 */
export const HouseholdIdParam = (param: string = 'id') =>
  (target: object, propertyKey: string | symbol, descriptor: PropertyDescriptor) => {
    Reflect.defineMetadata(HOUSEHOLD_ID_PARAM, param, descriptor.value);
    return descriptor;
  };

/**
 * Decorator to specify required household roles for an endpoint
 * If not specified, any active member can access
 */
export const HouseholdRoles = (...roles: HouseholdRole[]) =>
  SetMetadata(HOUSEHOLD_ROLES_KEY, roles);

/**
 * Interface for user info from either JWT or Firebase auth
 */
interface UserInfo {
  userId: string;
  role: string;
}

@Injectable()
export class HouseholdMemberGuard implements CanActivate {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();

    // Support both JWT (legacy) and Firebase auth
    const userInfo = this.extractUserInfo(request);

    if (!userInfo) {
      throw new ForbiddenException('User not authenticated');
    }

    // Admin can access any household
    if (userInfo.role === 'ADMIN') {
      return true;
    }

    // Get the parameter name that contains the household ID
    const paramName = this.reflector.get<string>(
      HOUSEHOLD_ID_PARAM,
      context.getHandler(),
    ) || 'id';

    const householdId = request.params[paramName] || request.body?.householdId || request.query?.householdId;

    if (!householdId) {
      return true; // No household ID to check
    }

    // Check if household exists
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
    });

    if (!household) {
      throw new NotFoundException(`Household with ID ${householdId} not found`);
    }

    // Check if user is a member of the household
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId,
          userId: userInfo.userId,
        },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You are not a member of this household');
    }

    // Check required household roles if specified
    const requiredRoles = this.reflector.getAllAndOverride<HouseholdRole[]>(
      HOUSEHOLD_ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (requiredRoles && requiredRoles.length > 0) {
      if (!requiredRoles.includes(membership.role as HouseholdRole)) {
        throw new ForbiddenException(
          `This action requires one of the following roles: ${requiredRoles.join(', ')}`,
        );
      }
    }

    // Attach household and membership to request for later use
    request.household = household;
    request.householdMembership = membership;

    return true;
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
        role: firebaseUser.role,
      };
    }

    // Check for JWT payload (from JwtAuthGuard)
    if (request.user?.sub) {
      const jwtUser = request.user as JwtPayload;
      return {
        userId: jwtUser.sub,
        role: jwtUser.role,
      };
    }

    return null;
  }
}

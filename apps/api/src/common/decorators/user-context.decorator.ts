import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthPayload } from '../../firebase';
import { JwtPayload } from '../../auth';

/**
 * UserContext - Represents the authenticated user's context for permission filtering
 *
 * This context is used throughout the application to:
 * 1. Filter database queries based on user role
 * 2. Determine what resources a user can access
 * 3. Inject user information into services and repositories
 */
export interface UserContext {
  userId: string;
  email: string;
  role: UserRole;
  firebaseUid?: string;

  // For managers: list of household IDs they manage
  managedHouseholdIds?: string[];

  // For homeowners: their household memberships
  householdMemberships?: Array<{
    householdId: string;
    role: string;
    status: string;
  }>;

  // For vendors: their assigned work order context
  vendorId?: string;
}

/**
 * Permission helpers for filtering queries based on user context
 */
export interface PermissionFilter {
  // For household-level queries
  householdFilter: {
    // ADMIN: no filter (all)
    // MANAGER: { managerId: userId }
    // HOMEOWNER: { OR: [{ ownerId }, { members: { some: { userId, status: 'ACTIVE' } } }] }
    where: Record<string, any>;
  };

  // Helper method to check if user can access a specific household
  canAccessHousehold: (householdId: string) => Promise<boolean>;

  // Helper to check if user is admin
  isAdmin: boolean;

  // Helper to check if user is a manager
  isManager: boolean;

  // Helper to check if user is a homeowner
  isHomeowner: boolean;

  // Helper to check if user is a vendor
  isVendor: boolean;
}

/**
 * Decorator to extract the authenticated user context from the request
 *
 * Usage:
 * @Get()
 * findAll(@CurrentUserContext() ctx: UserContext) {
 *   // Use ctx to filter queries
 * }
 */
export const CurrentUserContext = createParamDecorator(
  async (data: unknown, ctx: ExecutionContext): Promise<UserContext | null> => {
    const request = ctx.switchToHttp().getRequest();

    // Try Firebase auth first
    if (request.user?.userId) {
      const firebaseUser = request.user as AuthPayload;
      return {
        userId: firebaseUser.userId,
        email: firebaseUser.email,
        role: firebaseUser.role as UserRole,
        firebaseUid: firebaseUser.firebaseUid,
        householdMemberships: firebaseUser.memberships,
      };
    }

    // Fall back to JWT auth
    if (request.user?.sub) {
      const jwtUser = request.user as JwtPayload;
      return {
        userId: jwtUser.sub,
        email: jwtUser.email,
        role: jwtUser.role as UserRole,
      };
    }

    return null;
  },
);

/**
 * Helper function to build Prisma where clause for household access
 */
export function buildHouseholdAccessFilter(userContext: UserContext): Record<string, any> {
  switch (userContext.role) {
    case UserRole.ADMIN:
      // Admin can access all households
      return {};

    case UserRole.MANAGER:
      // Manager can only access households they manage
      return {
        managerId: userContext.userId,
      };

    case UserRole.HOMEOWNER:
      // Homeowner can access households they own or are members of
      return {
        OR: [
          { ownerId: userContext.userId },
          {
            members: {
              some: {
                userId: userContext.userId,
                status: 'ACTIVE',
              },
            },
          },
        ],
      };

    case UserRole.VENDOR:
      // Vendors access households through work orders, not directly
      // Return empty filter that matches nothing for direct household queries
      return {
        id: '__never__', // This will match nothing
      };

    default:
      return {
        id: '__never__',
      };
  }
}

/**
 * Helper function to build work order access filter
 */
export function buildWorkOrderAccessFilter(userContext: UserContext): Record<string, any> {
  switch (userContext.role) {
    case UserRole.ADMIN:
      return {};

    case UserRole.MANAGER:
      return {
        household: {
          managerId: userContext.userId,
        },
      };

    case UserRole.HOMEOWNER:
      return {
        household: {
          OR: [
            { ownerId: userContext.userId },
            {
              members: {
                some: {
                  userId: userContext.userId,
                  status: 'ACTIVE',
                },
              },
            },
          ],
        },
      };

    case UserRole.VENDOR:
      return {
        assignedVendor: {
          userId: userContext.userId,
        },
      };

    default:
      return {
        id: '__never__',
      };
  }
}

/**
 * Helper function to build service request access filter
 */
export function buildServiceRequestAccessFilter(userContext: UserContext): Record<string, any> {
  switch (userContext.role) {
    case UserRole.ADMIN:
      return {};

    case UserRole.MANAGER:
      return {
        household: {
          managerId: userContext.userId,
        },
      };

    case UserRole.HOMEOWNER:
      return {
        household: {
          OR: [
            { ownerId: userContext.userId },
            {
              members: {
                some: {
                  userId: userContext.userId,
                  status: 'ACTIVE',
                },
              },
            },
          ],
        },
      };

    case UserRole.VENDOR:
      // Vendors see service requests through work orders
      return {
        workOrders: {
          some: {
            assignedVendor: {
              userId: userContext.userId,
            },
          },
        },
      };

    default:
      return {
        id: '__never__',
      };
  }
}

import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';

import { JwtPayload } from '../../auth';
import { PrismaService } from '../../prisma';

export const HOUSEHOLD_ID_PARAM = 'householdIdParam';
export const HouseholdIdParam = (param: string = 'id') =>
  (target: object, propertyKey: string | symbol, descriptor: PropertyDescriptor) => {
    Reflect.defineMetadata(HOUSEHOLD_ID_PARAM, param, descriptor.value);
    return descriptor;
  };

@Injectable()
export class HouseholdMemberGuard implements CanActivate {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user: JwtPayload = request.user;

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    // Admin can access any household
    if (user.role === 'ADMIN') {
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
          userId: user.sub,
        },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You are not a member of this household');
    }

    // Attach household and membership to request for later use
    request.household = household;
    request.householdMembership = membership;

    return true;
  }
}

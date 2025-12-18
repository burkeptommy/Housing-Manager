import { Controller, Get, UseGuards } from '@nestjs/common';

import { AppService } from './app.service';
import { FirebaseAuthGuard, AuthPayload } from './firebase/firebase-auth.guard';
import { CurrentUser } from './firebase/current-user.decorator';
import { PrismaService } from './prisma';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly prisma: PrismaService,
  ) {}

  @Get()
  getHello(): { message: string; version: string } {
    return this.appService.getHello();
  }

  @Get('me')
  @UseGuards(FirebaseAuthGuard)
  async getMe(@CurrentUser() user: AuthPayload) {
    // Get full user data
    const dbUser = await this.prisma.user.findUnique({
      where: { id: user.userId },
    });

    if (!dbUser) {
      return { user: null, household: null, memberships: [] };
    }

    // Get primary household info
    const primaryMembership = user.memberships[0];
    let household = null;

    if (primaryMembership) {
      const h = await this.prisma.household.findUnique({
        where: { id: primaryMembership.householdId },
        include: { homeProfile: true },
      });

      if (h) {
        household = {
          id: h.id,
          name: h.name,
          description: h.description,
          subscriptionPlan: h.subscriptionPlan,
          subscriptionStatus: h.subscriptionStatus,
          billingCycleDay: h.billingCycleDay,
          role: primaryMembership.role,
          hasProperty: !!h.homeProfile,
          propertyAddress: h.homeProfile
            ? `${h.homeProfile.addressLine1}, ${h.homeProfile.city}, ${h.homeProfile.state}`
            : undefined,
        };
      }
    }

    return {
      user: {
        id: dbUser.id,
        email: dbUser.email,
        displayName: dbUser.displayName,
        firstName: dbUser.firstName,
        lastName: dbUser.lastName,
        avatarUrl: dbUser.avatarUrl,
        role: dbUser.role,
        emailVerified: dbUser.emailVerified,
        createdAt: dbUser.createdAt,
      },
      household,
      memberships: user.memberships.map((m) => ({
        householdId: m.householdId,
        householdName: m.householdName,
        role: m.role,
        status: m.status,
      })),
    };
  }
}

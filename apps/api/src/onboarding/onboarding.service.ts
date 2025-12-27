import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PropertyType } from '@prisma/client';

export interface CompleteSignupDto {
  biggestChallenge: string;
  address: {
    street: string;
    city: string;
    state: string;
    zipCode: string;
  };
  propertyDetails: {
    bedrooms: number | null;
    bathrooms: number | null;
    squareFeet: number | null;
    yearBuilt: number | null;
    propertyType: string | null;
  };
  enrichmentData: any | null;
}

@Injectable()
export class OnboardingService {
  constructor(private prisma: PrismaService) {}

  /**
   * Complete the initial signup flow
   * Creates/updates household, home profile, and onboarding progress
   */
  async completeSignup(userId: string, data: CompleteSignupDto) {
    // Get user
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        ownedHouseholds: {
          include: {
            homeProfile: true,
            onboardingProgress: true,
          },
        },
      },
    });

    if (!user) {
      throw new Error('User not found');
    }

    // Check if user already has a household
    let household = user.ownedHouseholds[0];

    if (!household) {
      // Create new household
      const householdName = user.lastName
        ? `The ${user.lastName} Family`
        : `${user.firstName || user.email.split('@')[0]}'s Home`;

      household = await this.prisma.household.create({
        data: {
          name: householdName,
          ownerId: userId,
          enrichmentData: data.enrichmentData || undefined,
        },
        include: {
          homeProfile: true,
          onboardingProgress: true,
        },
      });
    }

    // Create or update home profile
    const homeProfile = await this.prisma.homeProfile.upsert({
      where: { householdId: household.id },
      create: {
        householdId: household.id,
        addressLine1: data.address.street,
        city: data.address.city,
        state: data.address.state,
        postalCode: data.address.zipCode,
        country: 'USA',
        propertyType: this.mapPropertyType(data.propertyDetails.propertyType),
        bedrooms: data.propertyDetails.bedrooms || undefined,
        bathrooms: data.propertyDetails.bathrooms || undefined,
        squareFeet: data.propertyDetails.squareFeet || undefined,
        yearBuilt: data.propertyDetails.yearBuilt || undefined,
      },
      update: {
        addressLine1: data.address.street,
        city: data.address.city,
        state: data.address.state,
        postalCode: data.address.zipCode,
        propertyType: this.mapPropertyType(data.propertyDetails.propertyType),
        bedrooms: data.propertyDetails.bedrooms || undefined,
        bathrooms: data.propertyDetails.bathrooms || undefined,
        squareFeet: data.propertyDetails.squareFeet || undefined,
        yearBuilt: data.propertyDetails.yearBuilt || undefined,
      },
    });

    // Create or update onboarding progress
    const onboardingProgress = await this.prisma.onboardingProgress.upsert({
      where: { householdId: household.id },
      create: {
        householdId: household.id,
        biggestChallenge: data.biggestChallenge,
        status: 'SIGNUP_COMPLETE',
      },
      update: {
        biggestChallenge: data.biggestChallenge,
        status: 'SIGNUP_COMPLETE',
      },
    });

    // Update household with enrichment data if provided
    if (data.enrichmentData) {
      await this.prisma.household.update({
        where: { id: household.id },
        data: {
          enrichmentData: data.enrichmentData,
        },
      });
    }

    return {
      success: true,
      household: {
        id: household.id,
        name: household.name,
      },
      homeProfile: {
        id: homeProfile.id,
        address: `${homeProfile.addressLine1}, ${homeProfile.city}, ${homeProfile.state} ${homeProfile.postalCode}`,
      },
      onboardingProgress: {
        id: onboardingProgress.id,
        status: onboardingProgress.status,
        biggestChallenge: onboardingProgress.biggestChallenge,
      },
    };
  }

  /**
   * Schedule an intro call
   */
  async scheduleCall(userId: string, scheduledAt: Date) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        ownedHouseholds: {
          include: {
            onboardingProgress: true,
          },
        },
      },
    });

    if (!user || !user.ownedHouseholds[0]) {
      throw new Error('Household not found');
    }

    const household = user.ownedHouseholds[0];

    const onboardingProgress = await this.prisma.onboardingProgress.upsert({
      where: { householdId: household.id },
      create: {
        householdId: household.id,
        callScheduledFor: scheduledAt,
        status: 'CALL_SCHEDULED',
      },
      update: {
        callScheduledFor: scheduledAt,
        status: 'CALL_SCHEDULED',
      },
    });

    return {
      success: true,
      scheduledFor: onboardingProgress.callScheduledFor,
    };
  }

  /**
   * Get onboarding status for a user
   */
  async getStatus(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        ownedHouseholds: {
          include: {
            homeProfile: true,
            onboardingProgress: true,
          },
        },
      },
    });

    if (!user || !user.ownedHouseholds[0]) {
      return {
        hasHousehold: false,
        status: null,
      };
    }

    const household = user.ownedHouseholds[0];
    const progress = household.onboardingProgress;

    return {
      hasHousehold: true,
      householdId: household.id,
      householdName: household.name,
      homeProfile: household.homeProfile
        ? {
            address: `${household.homeProfile.addressLine1}, ${household.homeProfile.city}, ${household.homeProfile.state}`,
          }
        : null,
      status: progress?.status || null,
      callScheduledFor: progress?.callScheduledFor || null,
      callCompletedAt: progress?.callCompletedAt || null,
      profileDeliveredAt: progress?.profileDeliveredAt || null,
    };
  }

  private mapPropertyType(type: string | null): PropertyType {
    if (!type) return PropertyType.SINGLE_FAMILY;

    const mapping: Record<string, PropertyType> = {
      SFR: PropertyType.SINGLE_FAMILY,
      'Single Family': PropertyType.SINGLE_FAMILY,
      CONDO: PropertyType.CONDO,
      Condo: PropertyType.CONDO,
      TOWNHOUSE: PropertyType.TOWNHOUSE,
      Townhouse: PropertyType.TOWNHOUSE,
      MULTI: PropertyType.MULTI_FAMILY,
      'Multi-Family': PropertyType.MULTI_FAMILY,
    };

    return mapping[type] || PropertyType.SINGLE_FAMILY;
  }
}

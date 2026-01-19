import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import {
  RequestWalkthroughDto,
  WalkthroughEligibilityResponse,
  WalkthroughRequestResponse,
} from './dto/walkthrough.dto';

@Injectable()
export class WalkthroughService {
  private readonly logger = new Logger(WalkthroughService.name);

  // Qualifying zip codes
  private readonly FAIRFIELD_CT_ZIPS = /^068/; // Fairfield County, CT
  private readonly WESTCHESTER_NY_ZIPS = /^10[5-9]/; // Westchester County, NY (105xx-109xx)

  constructor(
    private readonly prisma: PrismaService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Check if a household is eligible for a free home walkthrough
   */
  async checkEligibility(householdId: string): Promise<WalkthroughEligibilityResponse> {
    try {
      const household = await this.prisma.household.findUnique({
        where: { id: householdId },
        include: {
          homeProfile: true,
          homeSystems: true,
          vendors: true,
          bills: true,
          serviceRequests: {
            where: {
              requestType: 'HOME_WALKTHROUGH',
            },
          },
        },
      });

      if (!household) {
        return {
          eligible: false,
          reason: 'Household not found',
          hasScheduled: false,
        };
      }

      // Check if already scheduled
      const existingWalkthrough = household.serviceRequests.find(
        (sr) => sr.requestType === 'HOME_WALKTHROUGH' &&
          ['PENDING', 'IN_PROGRESS', 'SCHEDULED'].includes(sr.status),
      );

      if (existingWalkthrough) {
        return {
          eligible: false,
          reason: 'You already have a walkthrough scheduled',
          hasScheduled: true,
          scheduledDate: existingWalkthrough.scheduledDate?.toISOString(),
        };
      }

      // Check for completed walkthrough
      const completedWalkthrough = household.serviceRequests.find(
        (sr) => sr.requestType === 'HOME_WALKTHROUGH' && sr.status === 'COMPLETED',
      );

      if (completedWalkthrough) {
        return {
          eligible: false,
          reason: 'You have already received your free walkthrough',
          hasScheduled: false,
        };
      }

      // Check location eligibility
      const zipCode = household.homeProfile?.zipCode;
      const isQualifyingZip = this.isQualifyingZipCode(zipCode);

      if (!isQualifyingZip) {
        return {
          eligible: false,
          reason: 'Free walkthroughs are currently available only in Fairfield County, CT and Westchester County, NY',
          hasScheduled: false,
        };
      }

      // Check profile completeness - if incomplete, they're definitely eligible
      const systemCount = household.homeSystems.length;
      const vendorCount = household.vendors.length;
      const billCount = household.bills.length;
      const needsSetup = systemCount < 3 || vendorCount < 3 || billCount < 5;

      // Check account age
      const daysSinceCreation = Math.floor(
        (Date.now() - new Date(household.createdAt).getTime()) / (1000 * 60 * 60 * 24),
      );
      const isNewUser = daysSinceCreation < 30;

      if (isNewUser || needsSetup) {
        return {
          eligible: true,
          reason: needsSetup
            ? 'You qualify for a free home walkthrough to help complete your home profile!'
            : 'As a new Haven user, you qualify for a free home walkthrough!',
          hasScheduled: false,
        };
      }

      // Even if profile is complete, beta users in qualifying areas get it free
      return {
        eligible: true,
        reason: 'As a beta user in our service area, you qualify for a free home walkthrough!',
        hasScheduled: false,
      };
    } catch (error) {
      this.logger.error(`Error checking eligibility: ${error.message}`, error.stack);
      return {
        eligible: false,
        reason: 'Unable to check eligibility at this time',
        hasScheduled: false,
      };
    }
  }

  /**
   * Request a free home walkthrough
   */
  async requestWalkthrough(
    userId: string,
    dto: RequestWalkthroughDto,
  ): Promise<WalkthroughRequestResponse> {
    try {
      // Verify eligibility first
      const eligibility = await this.checkEligibility(dto.householdId);

      if (!eligibility.eligible) {
        return {
          success: false,
          requestId: '',
          message: eligibility.reason,
          estimatedResponseTime: '',
        };
      }

      // Get household and user info
      const household = await this.prisma.household.findUnique({
        where: { id: dto.householdId },
        include: {
          homeProfile: true,
          members: {
            include: {
              user: true,
            },
          },
        },
      });

      const user = await this.prisma.user.findUnique({
        where: { id: userId },
      });

      // Create service request for the walkthrough
      const serviceRequest = await this.prisma.serviceRequest.create({
        data: {
          householdId: dto.householdId,
          requestedById: userId,
          requestType: 'HOME_WALKTHROUGH',
          title: 'Free Home Walkthrough',
          description: this.buildWalkthroughDescription(dto, household, user),
          status: 'PENDING',
          priority: 'MEDIUM',
          scheduledDate: dto.preferredDate ? new Date(dto.preferredDate) : null,
          metadata: {
            preferredTimeSlot: dto.preferredTimeSlot,
            contactPhone: dto.contactPhone || user?.phoneNumber,
            notes: dto.notes,
            address: household?.homeProfile
              ? `${household.homeProfile.street}, ${household.homeProfile.city}, ${household.homeProfile.state} ${household.homeProfile.zipCode}`
              : 'Address not provided',
          },
        },
      });

      // Create an Alfred case for tracking
      await this.prisma.alfredCase.create({
        data: {
          householdId: dto.householdId,
          subject: 'Free Home Walkthrough Request',
          status: 'OPEN',
          serviceRequestId: serviceRequest.id,
        },
      });

      // Notify operations team
      // For now, we'll log it - in production this would email/slack the team
      this.logger.log(
        `New walkthrough request: ${serviceRequest.id} for household ${dto.householdId}`,
      );

      // Send confirmation to user
      if (user) {
        await this.notificationsService.createNotification({
          userId: user.id,
          householdId: dto.householdId,
          type: 'SERVICE_REQUEST',
          title: 'Walkthrough Request Received',
          body: "We've received your request for a free home walkthrough. Our team will contact you within 24-48 hours to schedule.",
          data: {
            serviceRequestId: serviceRequest.id,
          },
        });
      }

      return {
        success: true,
        requestId: serviceRequest.id,
        message:
          "Your walkthrough request has been submitted! We'll contact you within 24-48 hours to confirm your appointment.",
        estimatedResponseTime: '24-48 hours',
      };
    } catch (error) {
      this.logger.error(`Error requesting walkthrough: ${error.message}`, error.stack);
      return {
        success: false,
        requestId: '',
        message: 'Unable to submit walkthrough request. Please try again later.',
        estimatedResponseTime: '',
      };
    }
  }

  /**
   * Check if a zip code is in a qualifying area
   */
  private isQualifyingZipCode(zipCode: string | null | undefined): boolean {
    if (!zipCode) return false;

    // Fairfield County, CT: 068xx
    if (this.FAIRFIELD_CT_ZIPS.test(zipCode)) return true;

    // Westchester County, NY: 105xx, 106xx, 107xx, 108xx, 109xx
    if (this.WESTCHESTER_NY_ZIPS.test(zipCode)) return true;

    return false;
  }

  /**
   * Build a detailed description for the walkthrough service request
   */
  private buildWalkthroughDescription(
    dto: RequestWalkthroughDto,
    household: any,
    user: any,
  ): string {
    const parts: string[] = [];

    parts.push('FREE HOME WALKTHROUGH REQUEST');
    parts.push('');

    if (user) {
      parts.push(`Requested by: ${user.name || user.email}`);
      parts.push(`Contact: ${dto.contactPhone || user.phoneNumber || user.email}`);
    }

    if (household?.homeProfile) {
      parts.push('');
      parts.push('Property Details:');
      parts.push(
        `Address: ${household.homeProfile.street}, ${household.homeProfile.city}, ${household.homeProfile.state} ${household.homeProfile.zipCode}`,
      );
      if (household.homeProfile.squareFeet) {
        parts.push(`Square Feet: ${household.homeProfile.squareFeet}`);
      }
      if (household.homeProfile.yearBuilt) {
        parts.push(`Year Built: ${household.homeProfile.yearBuilt}`);
      }
    }

    parts.push('');
    parts.push('Scheduling Preferences:');
    if (dto.preferredDate) {
      parts.push(`Preferred Date: ${dto.preferredDate}`);
    }
    if (dto.preferredTimeSlot) {
      parts.push(`Preferred Time: ${dto.preferredTimeSlot}`);
    }

    if (dto.notes) {
      parts.push('');
      parts.push('Additional Notes:');
      parts.push(dto.notes);
    }

    parts.push('');
    parts.push('Walkthrough includes:');
    parts.push('- Document all home systems (HVAC, water heater, appliances, etc.)');
    parts.push('- Record model numbers and installation dates');
    parts.push('- Create personalized maintenance schedule');
    parts.push('- Identify any immediate maintenance concerns');
    parts.push('- Set up vendor recommendations');

    return parts.join('\n');
  }

  /**
   * Get all walkthrough requests for admin view
   */
  async getWalkthroughRequests(status?: string) {
    return this.prisma.serviceRequest.findMany({
      where: {
        requestType: 'HOME_WALKTHROUGH',
        ...(status ? { status } : {}),
      },
      include: {
        household: {
          include: {
            homeProfile: true,
          },
        },
        requestedBy: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
  }
}

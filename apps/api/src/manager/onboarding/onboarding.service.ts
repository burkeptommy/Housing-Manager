import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { OnboardingStatus } from '@prisma/client';

@Injectable()
export class ManagerOnboardingService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Get queue of households pending onboarding
   */
  async getQueue(status?: string) {
    const where = status
      ? { status: status as OnboardingStatus }
      : {
          status: {
            in: [
              'PENDING_CALL' as OnboardingStatus,
              'SIGNUP_COMPLETE' as OnboardingStatus,
              'CALL_SCHEDULED' as OnboardingStatus,
              'INTAKE_PARTIAL' as OnboardingStatus,
            ],
          },
        };

    const sessions = await this.prisma.onboardingProgress.findMany({
      where,
      include: {
        household: {
          include: {
            homeProfile: true,
            owner: {
              select: {
                id: true,
                displayName: true,
                firstName: true,
                lastName: true,
                email: true,
                phone: true,
              },
            },
          },
        },
        homeManager: {
          select: { id: true, displayName: true },
        },
      },
      orderBy: { createdAt: 'asc' },
    });

    return sessions.map((s) => ({
      id: s.id,
      householdId: s.householdId,
      status: s.status,
      homeownerName:
        s.household.owner?.displayName ||
        `${s.household.owner?.firstName || ''} ${s.household.owner?.lastName || ''}`.trim() ||
        'Unknown',
      homeownerEmail: s.household.owner?.email,
      homeownerPhone: s.household.owner?.phone,
      propertyAddress: s.household.homeProfile
        ? `${s.household.homeProfile.addressLine1}, ${s.household.homeProfile.city}, ${s.household.homeProfile.state}`
        : 'No address',
      biggestChallenge: s.biggestChallenge,
      selectedTier: s.selectedTier,
      callScheduledFor: s.callScheduledFor,
      assignedManager: s.homeManager?.displayName,
      progress: this.calculateOverallProgress(s),
      enrichmentHighlights: this.getEnrichmentHighlights(
        s.household.homeProfile,
      ),
      createdAt: s.createdAt,
    }));
  }

  /**
   * Get single session with full details for intake
   */
  async getSession(id: string) {
    const session = await this.prisma.onboardingProgress.findUnique({
      where: { id },
      include: {
        household: {
          include: {
            homeProfile: true,
            owner: {
              select: {
                id: true,
                displayName: true,
                firstName: true,
                lastName: true,
                email: true,
                phone: true,
              },
            },
            familyMembers: {
              include: { activities: true },
            },
            ownedVendors: true,
            comprehensiveBills: true,
          },
        },
      },
    });

    if (!session) {
      return null;
    }

    const homeProfile = session.household.homeProfile;

    return {
      session: {
        id: session.id,
        status: session.status,
        biggestChallenge: session.biggestChallenge,
        selectedTier: session.selectedTier,
        progress: {
          family: session.familyComplete,
          property: session.propertyComplete,
          zones: session.zonesComplete,
          systems: session.systemsComplete,
          vendors: session.vendorsComplete,
          bills: session.billsComplete,
          overall: this.calculateOverallProgress(session),
        },
        intakeData: session.intakeData || {},
        monthlyFundingEstimate: session.monthlyEstimate
          ? Number(session.monthlyEstimate)
          : null,
        callNotes: session.callNotes,
        followUpNeeded: session.followUpNeeded,
        followUpNotes: session.followUpNotes,
      },
      household: {
        id: session.household.id,
        name: session.household.name,
        users: [session.household.owner],
      },
      property: homeProfile
        ? {
            id: homeProfile.id,
            street: homeProfile.addressLine1,
            city: homeProfile.city,
            state: homeProfile.state,
            zipCode: homeProfile.postalCode,
            bedrooms: homeProfile.bedrooms,
            bathrooms: homeProfile.bathrooms,
            squareFeet: homeProfile.squareFeet,
            yearBuilt: homeProfile.yearBuilt,
            propertyType: homeProfile.propertyType,
          }
        : null,
      enrichment: homeProfile
        ? {
            bedrooms: homeProfile.bedrooms,
            bathrooms: homeProfile.bathrooms,
            squareFeet: homeProfile.squareFeet,
            yearBuilt: homeProfile.yearBuilt,
            heatingFuel: homeProfile.heatingType,
            fireplaces: homeProfile.fireplaces,
            pool: homeProfile.hasPool,
          }
        : null,
      existingData: {
        familyMembers: session.household.familyMembers,
        vendors: session.household.ownedVendors,
        bills: session.household.comprehensiveBills,
      },
    };
  }

  /**
   * Update intake progress
   */
  async updateIntake(
    id: string,
    body: {
      section: string;
      data: any;
      progress?: number;
    },
  ) {
    const session = await this.prisma.onboardingProgress.findUnique({
      where: { id },
    });

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    // Merge new data with existing
    const existingData = (session.intakeData as Record<string, any>) || {};
    const updatedData = {
      ...existingData,
      [body.section]: {
        ...(existingData[body.section] || {}),
        ...body.data,
        lastUpdated: new Date().toISOString(),
      },
    };

    // Map section to progress field
    const progressFieldMap: Record<string, string> = {
      family: 'familyComplete',
      property: 'propertyComplete',
      zones: 'zonesComplete',
      systems: 'systemsComplete',
      vendors: 'vendorsComplete',
      bills: 'billsComplete',
      quickStart: 'familyComplete', // Map quickStart to family progress
    };

    const updateData: Record<string, any> = {
      intakeData: updatedData,
      status: 'CALL_IN_PROGRESS' as OnboardingStatus,
    };

    const progressField = progressFieldMap[body.section];
    if (body.progress !== undefined && progressField) {
      updateData[progressField] = body.progress;
    }

    return this.prisma.onboardingProgress.update({
      where: { id },
      data: updateData,
    });
  }

  /**
   * Start call
   */
  async startCall(id: string) {
    return this.prisma.onboardingProgress.update({
      where: { id },
      data: {
        status: 'CALL_IN_PROGRESS' as OnboardingStatus,
        callStartedAt: new Date(),
      },
    });
  }

  /**
   * Complete intake
   */
  async completeIntake(
    id: string,
    body: {
      callNotes?: string;
      followUpNeeded?: boolean;
      followUpNotes?: string;
    },
  ) {
    const session = await this.prisma.onboardingProgress.findUnique({
      where: { id },
      include: { household: true },
    });

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    // Process intake data into actual records
    await this.processIntakeData(session);

    // Calculate monthly funding
    const monthlyFunding = await this.calculateMonthlyFunding(
      session.householdId,
    );

    return this.prisma.onboardingProgress.update({
      where: { id },
      data: {
        status: body.followUpNeeded
          ? ('INTAKE_PARTIAL' as OnboardingStatus)
          : ('INTAKE_COMPLETE' as OnboardingStatus),
        callCompletedAt: new Date(),
        callNotes: body.callNotes,
        followUpNeeded: body.followUpNeeded || false,
        followUpNotes: body.followUpNotes,
        monthlyEstimate: monthlyFunding,
        familyComplete: 100,
        propertyComplete: 100,
        zonesComplete: 100,
        systemsComplete: 100,
        vendorsComplete: 100,
        billsComplete: 100,
      },
    });
  }

  /**
   * Deliver profile to homeowner
   */
  async deliverProfile(id: string) {
    return this.prisma.onboardingProgress.update({
      where: { id },
      data: {
        status: 'PROFILE_DELIVERED' as OnboardingStatus,
        profileDeliveredAt: new Date(),
      },
    });
  }

  /**
   * Calculate overall progress from all sections
   */
  private calculateOverallProgress(session: any): number {
    const weights = {
      family: 15,
      property: 10,
      zones: 20,
      systems: 15,
      vendors: 15,
      bills: 25,
    };

    const weighted =
      ((session.familyComplete || 0) * weights.family +
        (session.propertyComplete || 0) * weights.property +
        (session.zonesComplete || 0) * weights.zones +
        (session.systemsComplete || 0) * weights.systems +
        (session.vendorsComplete || 0) * weights.vendors +
        (session.billsComplete || 0) * weights.bills) /
      100;

    return Math.round(weighted);
  }

  /**
   * Extract highlights from home profile/enrichment data
   */
  private getEnrichmentHighlights(homeProfile: any): string[] {
    if (!homeProfile) return [];

    const highlights: string[] = [];

    if (homeProfile.heatingType?.toLowerCase().includes('oil')) {
      highlights.push('Oil heat');
    }
    if (homeProfile.fireplaces && homeProfile.fireplaces > 0) {
      highlights.push(
        `${homeProfile.fireplaces} fireplace${homeProfile.fireplaces > 1 ? 's' : ''}`,
      );
    }
    if (homeProfile.hasPool) {
      highlights.push('Pool');
    }
    if (homeProfile.hasSeptic) {
      highlights.push('Septic');
    }
    if (homeProfile.hasWell) {
      highlights.push('Well water');
    }

    return highlights;
  }

  /**
   * Process intake data and create database records
   */
  private async processIntakeData(session: any) {
    const data = (session.intakeData as Record<string, any>) || {};
    const householdId = session.householdId;

    // Process family members
    if (data.family?.adults) {
      for (const member of data.family.adults) {
        if (!member.firstName) continue;
        await this.prisma.familyMember.create({
          data: {
            householdId,
            type: 'ADULT',
            firstName: member.firstName,
            lastName: member.lastName,
            email: member.email,
            phone: member.phone,
            relationship: member.role,
          },
        });
      }
    }

    if (data.family?.children) {
      for (const child of data.family.children) {
        if (!child.firstName) continue;
        await this.prisma.familyMember.create({
          data: {
            householdId,
            type: 'CHILD',
            firstName: child.firstName,
            lastName: child.lastName,
            school: child.school,
            schoolGrade: child.grade,
          },
        });
      }
    }

    if (data.family?.pets) {
      for (const pet of data.family.pets) {
        if (!pet.name) continue;
        await this.prisma.pet.create({
          data: {
            householdId,
            name: pet.name,
            type: pet.type?.split(' ')[0] || 'Other',
            breed: pet.type,
            vetClinicName: pet.vetName,
            vetClinicPhone: pet.vetPhone,
          },
        });
      }
    }

    // Process vehicles
    if (data.vehicles?.vehicles) {
      for (const vehicle of data.vehicles.vehicles) {
        if (!vehicle.make) continue;
        await this.prisma.vehicle.create({
          data: {
            householdId,
            year: vehicle.year ? parseInt(vehicle.year) : null,
            make: vehicle.make,
            model: vehicle.model,
            color: vehicle.color,
            licensePlate: vehicle.licensePlate,
            primaryDriver: vehicle.primaryDriver,
          },
        });
      }
    }

    // Process bills - create comprehensive bills from intake data
    await this.processBillsFromIntake(householdId, data);
  }

  /**
   * Process bills from intake data
   */
  private async processBillsFromIntake(
    householdId: string,
    data: Record<string, any>,
  ) {
    const billsData = data.bills || {};

    // Mortgage
    if (billsData.mortgageLender && billsData.mortgagePayment) {
      await this.prisma.comprehensiveBill.create({
        data: {
          householdId,
          category: 'MORTGAGE',
          name: 'Mortgage',
          payeeName: billsData.mortgageLender,
          accountNumber: billsData.mortgageAccount,
          amount: parseFloat(billsData.mortgagePayment) || 0,
          frequency: 'MONTHLY',
          dueDay: billsData.mortgageDueDay
            ? parseInt(billsData.mortgageDueDay)
            : null,
          status: 'ACTIVE',
        },
      });
    }

    // Electric
    if (billsData.electricProvider) {
      await this.prisma.comprehensiveBill.create({
        data: {
          householdId,
          category: 'ELECTRIC',
          name: 'Electric',
          payeeName: billsData.electricProvider,
          accountNumber: billsData.electricAccount,
          amount: parseFloat(billsData.electricAvgBill) || 0,
          frequency: 'MONTHLY',
          status: 'ACTIVE',
        },
      });
    }

    // Gas
    if (billsData.gasProvider) {
      await this.prisma.comprehensiveBill.create({
        data: {
          householdId,
          category: 'GAS',
          name: 'Natural Gas',
          payeeName: billsData.gasProvider,
          accountNumber: billsData.gasAccount,
          frequency: 'MONTHLY',
          status: 'ACTIVE',
        },
      });
    }

    // Water
    if (billsData.waterProvider) {
      await this.prisma.comprehensiveBill.create({
        data: {
          householdId,
          category: 'WATER_SEWER',
          name: 'Water/Sewer',
          payeeName: billsData.waterProvider,
          accountNumber: billsData.waterAccount,
          frequency: 'MONTHLY',
          status: 'ACTIVE',
        },
      });
    }

    // Internet
    if (billsData.internetProvider) {
      await this.prisma.comprehensiveBill.create({
        data: {
          householdId,
          category: 'INTERNET',
          name: 'Internet',
          payeeName: billsData.internetProvider,
          accountNumber: billsData.internetAccount,
          amount: parseFloat(billsData.internetCost) || 0,
          frequency: 'MONTHLY',
          status: 'ACTIVE',
        },
      });
    }

    // Cell Phone
    if (billsData.cellProvider) {
      await this.prisma.comprehensiveBill.create({
        data: {
          householdId,
          category: 'CELL_PHONE',
          name: 'Cell Phone',
          payeeName: billsData.cellProvider,
          accountNumber: billsData.cellAccount,
          amount: parseFloat(billsData.cellCost) || 0,
          frequency: 'MONTHLY',
          status: 'ACTIVE',
        },
      });
    }

    // HOA
    if (billsData.hasHoa && billsData.hoaAmount) {
      await this.prisma.comprehensiveBill.create({
        data: {
          householdId,
          category: 'HOA',
          name: 'HOA Dues',
          amount: parseFloat(billsData.hoaAmount) || 0,
          frequency: billsData.hoaFrequency?.toUpperCase() || 'MONTHLY',
          status: 'ACTIVE',
        },
      });
    }

    // School Tuitions
    if (billsData.schoolTuitions) {
      for (const tuition of billsData.schoolTuitions) {
        if (!tuition.school) continue;
        await this.prisma.comprehensiveBill.create({
          data: {
            householdId,
            category: 'SCHOOL_TUITION',
            name: `${tuition.school} Tuition`,
            payeeName: tuition.school,
            amount: parseFloat(tuition.amount) || 0,
            frequency: tuition.frequency?.toUpperCase() || 'MONTHLY',
            status: 'ACTIVE',
          },
        });
      }
    }

    // Subscriptions
    if (billsData.subscriptions) {
      for (const sub of billsData.subscriptions) {
        if (!sub.name) continue;
        await this.prisma.comprehensiveBill.create({
          data: {
            householdId,
            category: 'SUBSCRIPTION',
            name: sub.name,
            amount: parseFloat(sub.cost) || 0,
            frequency: 'MONTHLY',
            status: 'ACTIVE',
          },
        });
      }
    }

    // Other bills
    if (billsData.otherBills) {
      for (const bill of billsData.otherBills) {
        if (!bill.name) continue;
        await this.prisma.comprehensiveBill.create({
          data: {
            householdId,
            category: 'OTHER',
            name: bill.name,
            payeeName: bill.payee,
            accountNumber: bill.account,
            amount: parseFloat(bill.amount) || 0,
            frequency: bill.frequency?.toUpperCase() || 'MONTHLY',
            status: 'ACTIVE',
          },
        });
      }
    }
  }

  /**
   * Calculate monthly funding based on all bills
   */
  private async calculateMonthlyFunding(householdId: string): Promise<number> {
    const bills = await this.prisma.comprehensiveBill.findMany({
      where: { householdId, status: 'ACTIVE' },
    });

    let monthly = 0;

    for (const bill of bills) {
      const amount = Number(bill.amount) || 0;
      switch (bill.frequency) {
        case 'WEEKLY':
          monthly += amount * 4.33;
          break;
        case 'BI_WEEKLY':
          monthly += amount * 2.17;
          break;
        case 'MONTHLY':
          monthly += amount;
          break;
        case 'QUARTERLY':
          monthly += amount / 3;
          break;
        case 'SEMI_ANNUALLY':
          monthly += amount / 6;
          break;
        case 'ANNUALLY':
          monthly += amount / 12;
          break;
        default:
          monthly += amount;
      }
    }

    // Add 10% buffer
    monthly *= 1.1;

    return Math.round(monthly * 100) / 100;
  }
}

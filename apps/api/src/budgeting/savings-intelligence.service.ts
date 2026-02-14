import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthPayload } from '../firebase';
import { getCategoryInfo } from './constants/budget-categories';

interface SavingsOpportunity {
  id: string;
  type: 'refinance' | 'rate_optimization' | 'subscription_audit' | 'insurance_bundle';
  title: string;
  description: string;
  currentCost: number;
  potentialSavings: number;
  category: string;
  confidence: 'high' | 'medium' | 'low';
  actionUrl?: string;
}

@Injectable()
export class SavingsIntelligenceService {
  private readonly logger = new Logger(SavingsIntelligenceService.name);

  constructor(private prisma: PrismaService) {}

  private async getHouseholdId(user: AuthPayload): Promise<string> {
    const member = await this.prisma.householdMember.findFirst({
      where: { userId: user.userId },
      select: { householdId: true },
    });
    if (!member) throw new Error('No household found');
    return member.householdId;
  }

  /**
   * Get refinancing opportunities for loans
   */
  async getRefinancingOpportunities(user: AuthPayload) {
    const householdId = await this.getHouseholdId(user);

    // Find loans from ComprehensiveBill
    const loans = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        isLoan: true,
        status: 'ACTIVE',
      },
    });

    if (loans.length === 0) {
      return { opportunities: [], totalPotentialSavings: 0 };
    }

    // Current market rates (simplified - in production, use a rates API)
    const marketRates: Record<string, number> = {
      MORTGAGE: 6.25,
      HOME_EQUITY: 7.5,
      AUTO_LOAN: 5.9,
      STUDENT_LOAN: 5.5,
      PERSONAL_LOAN: 8.0,
    };

    const opportunities = loans
      .filter((loan) => loan.interestRate && loan.principalBalance)
      .map((loan) => {
        const currentRate = Number(loan.interestRate);
        const balance = Number(loan.principalBalance);
        const categoryKey = loan.category?.toString() || 'PERSONAL_LOAN';
        const marketRate = marketRates[categoryKey] || marketRates.PERSONAL_LOAN;

        // Only suggest if current rate is > market rate + 0.5%
        if (currentRate <= marketRate + 0.5) return null;

        const currentMonthly = Number(loan.amount) || 0;
        // Simplified savings estimate
        const rateDiff = currentRate - marketRate;
        const monthlySavings = Math.round((balance * (rateDiff / 100)) / 12);
        const lifetimeSavings = monthlySavings * 12 * 5; // 5-year estimate
        const breakEvenMonths = monthlySavings > 0 ? Math.ceil(3000 / monthlySavings) : 999; // ~$3K closing costs

        return {
          id: loan.id,
          name: loan.name,
          category: categoryKey,
          currentRate,
          marketRate,
          balance,
          currentMonthly,
          estimatedNewMonthly: currentMonthly - monthlySavings,
          monthlySavings,
          lifetimeSavings,
          breakEvenMonths,
        };
      })
      .filter(Boolean);

    const totalPotentialSavings = opportunities.reduce(
      (s, o) => s + (o?.monthlySavings || 0),
      0,
    );

    return {
      opportunities,
      totalPotentialSavings,
      totalAnnualSavings: totalPotentialSavings * 12,
    };
  }

  /**
   * Get rate optimization opportunities by comparing to local medians
   */
  async getRateOptimizations(user: AuthPayload) {
    const householdId = await this.getHouseholdId(user);

    const homeProfile = await this.prisma.homeProfile.findFirst({
      where: { householdId },
    });
    if (!homeProfile?.postalCode) return { optimizations: [] };

    // Get local cost data
    const localData = await this.prisma.localCostData.findMany({
      where: { zipCode: homeProfile.postalCode },
    });

    if (localData.length === 0) return { optimizations: [] };

    // Get current month spending by category
    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    const endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    const transactions = await this.prisma.budgetTransaction.findMany({
      where: {
        householdId,
        date: { gte: startDate, lte: endDate },
        isHidden: false,
        amount: { gt: 0 },
      },
    });

    const spendingByCategory: Record<string, number> = {};
    for (const t of transactions) {
      if (t.categoryId) {
        spendingByCategory[t.categoryId] = (spendingByCategory[t.categoryId] || 0) + t.amount;
      }
    }

    // Find categories where spending > 20% above local median
    const optimizations = localData
      .filter((local) => {
        const spending = spendingByCategory[local.category] || 0;
        const median = local.medianMonthly || local.averageMonthly;
        return spending > 0 && median > 0 && spending > median * 1.2;
      })
      .map((local) => {
        const spending = spendingByCategory[local.category] || 0;
        const median = local.medianMonthly || local.averageMonthly;
        const info = getCategoryInfo(local.category);
        const percentOver = Math.round(((spending - median) / median) * 100);

        return {
          category: local.category,
          name: info?.name || local.category,
          color: info?.color || '#90a4ae',
          currentCost: Math.round(spending),
          localMedian: Math.round(median),
          percentOver,
          potentialSavings: Math.round(spending - median),
          suggestion: getSuggestion(local.category, percentOver),
        };
      })
      .sort((a, b) => b.potentialSavings - a.potentialSavings);

    const totalPotentialSavings = optimizations.reduce(
      (s, o) => s + o.potentialSavings,
      0,
    );

    return {
      optimizations,
      totalPotentialSavings,
      zipCode: homeProfile.postalCode,
    };
  }

  /**
   * Comprehensive savings summary combining all sources
   */
  async getSavingsSummary(user: AuthPayload) {
    const [refinancing, rateOptimizations] = await Promise.all([
      this.getRefinancingOpportunities(user),
      this.getRateOptimizations(user),
    ]);

    // Subscription audit - find potential duplicates
    const householdId = await this.getHouseholdId(user);
    const subscriptions = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
        category: { in: ['STREAMING_SERVICE', 'SOFTWARE_SUBSCRIPTION', 'CLUB_MEMBERSHIP', 'GYM_FITNESS', 'AMAZON_PRIME', 'WAREHOUSE_CLUB', 'NEWSPAPER_MAGAZINE', 'MEAL_KIT'] },
      },
    });

    const subscriptionTotal = subscriptions.reduce(
      (s, sub) => s + (Number(sub.amount) || 0),
      0,
    );

    // Insurance bundling check
    const insuranceBills = await this.prisma.comprehensiveBill.findMany({
      where: {
        householdId,
        status: 'ACTIVE',
        isInsurance: true,
      },
    });

    const uniqueInsuranceProviders = new Set(
      insuranceBills.map((b) => b.payeeName?.toLowerCase()).filter(Boolean),
    );
    const canBundle = uniqueInsuranceProviders.size > 1 && insuranceBills.length >= 2;
    const bundleSavings = canBundle
      ? Math.round(insuranceBills.reduce((s, b) => s + (Number(b.amount) || 0), 0) * 0.15)
      : 0;

    const totalMonthlySavings =
      (refinancing.totalPotentialSavings || 0) +
      (rateOptimizations.totalPotentialSavings || 0) +
      bundleSavings;

    return {
      totalMonthlySavings,
      totalAnnualSavings: totalMonthlySavings * 12,
      refinancing: {
        count: refinancing.opportunities.length,
        monthlySavings: refinancing.totalPotentialSavings || 0,
        topOpportunity: refinancing.opportunities[0] || null,
      },
      rateOptimization: {
        count: rateOptimizations.optimizations.length,
        monthlySavings: rateOptimizations.totalPotentialSavings || 0,
        topCategory: rateOptimizations.optimizations[0] || null,
      },
      subscriptions: {
        count: subscriptions.length,
        monthlyTotal: subscriptionTotal,
        items: subscriptions.map((s) => ({
          id: s.id,
          name: s.name,
          amount: Number(s.amount) || 0,
          frequency: s.frequency,
        })),
      },
      insuranceBundling: {
        canBundle,
        providerCount: uniqueInsuranceProviders.size,
        potentialSavings: bundleSavings,
      },
    };
  }
}

function getSuggestion(category: string, percentOver: number): string {
  const cat = category.toLowerCase();
  if (cat.includes('electric')) {
    return percentOver > 40
      ? 'Consider a home energy audit or solar panels'
      : 'Compare electricity providers for better rates';
  }
  if (cat.includes('gas') || cat.includes('heating')) {
    return 'Check insulation and thermostat settings. Compare gas suppliers.';
  }
  if (cat.includes('internet') || cat.includes('cable')) {
    return 'Call your provider to negotiate or switch to a competitor';
  }
  if (cat.includes('insurance')) {
    return 'Shop for quotes from 3+ providers. Bundle policies for discounts.';
  }
  if (cat.includes('water')) {
    return 'Check for leaks and consider water-efficient fixtures';
  }
  return 'Compare rates with other providers in your area';
}

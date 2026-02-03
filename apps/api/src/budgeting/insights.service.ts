import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthPayload } from '../firebase';
import { getCategoryInfo } from './constants/budget-categories';
import { BadRequestException } from '@nestjs/common';

@Injectable()
export class InsightsService {
  constructor(private prisma: PrismaService) {}

  private async getHouseholdId(user: AuthPayload): Promise<string> {
    const member = await this.prisma.householdMember.findFirst({
      where: { userId: user.userId },
      select: { householdId: true },
    });
    if (!member) throw new BadRequestException('No household found');
    return member.householdId;
  }

  async getBudgetInsights(user: AuthPayload) {
    const householdId = await this.getHouseholdId(user);

    const [spending, forecasts, homeProfile, budget] = await Promise.all([
      this.getSpendingData(householdId),
      this.prisma.systemForecast.findMany({ where: { householdId } }),
      this.prisma.homeProfile.findFirst({ where: { householdId } }),
      this.prisma.budget.findUnique({ where: { householdId } }),
    ]);

    const insights: string[] = [];

    // Compare to local averages
    const zipCode = homeProfile?.postalCode;
    if (zipCode) {
      const localData = await this.prisma.localCostData.findMany({
        where: { zipCode },
      });

      for (const local of localData) {
        const userSpending = spending.byCategory[local.category];
        if (userSpending && local.averageMonthly) {
          const diff = ((userSpending - local.averageMonthly) / local.averageMonthly) * 100;

          if (diff > 20) {
            const info = getCategoryInfo(local.category);
            insights.push(
              `Your ${info?.name || local.category} spending is ${diff.toFixed(0)}% above the local average. Want Alfred to find better rates?`,
            );
          } else if (diff < -20) {
            const info = getCategoryInfo(local.category);
            insights.push(
              `Great job! Your ${info?.name || local.category} costs are ${Math.abs(diff).toFixed(0)}% below average.`,
            );
          }
        }
      }
    }

    // Forecast warnings
    const urgentForecasts = forecasts.filter(
      (f) => f.urgency === 'HIGH' || f.urgency === 'CRITICAL',
    );
    if (urgentForecasts.length > 0) {
      const names = urgentForecasts.map((f) => f.systemName).join(', ');
      insights.push(
        `Heads up: Your ${names} ${urgentForecasts.length > 1 ? 'are' : 'is'} approaching end of life. Consider budgeting for replacement.`,
      );
    }

    // 50/30/20 analysis
    const monthlyIncome = budget?.monthlyIncome;
    if (monthlyIncome && monthlyIncome > 0) {
      const needsPercent = (spending.needs / monthlyIncome) * 100;
      const wantsPercent = (spending.wants / monthlyIncome) * 100;

      if (needsPercent > 55) {
        insights.push(
          `Your essential spending is ${needsPercent.toFixed(0)}% of income (target: 50%). Look for ways to reduce fixed costs.`,
        );
      }

      if (wantsPercent > 35) {
        insights.push(
          `Discretionary spending is ${wantsPercent.toFixed(0)}% of income (target: 30%). Small cuts here can boost savings.`,
        );
      }
    }

    return {
      insights,
      recommendations: this.generateRecommendations(spending, forecasts),
    };
  }

  private async getSpendingData(householdId: string) {
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

    const byCategory: Record<string, number> = {};
    let needs = 0;
    let wants = 0;

    const needsGroups = ['HOUSING', 'UTILITIES', 'TRANSPORTATION', 'HEALTH', 'FOOD'];

    for (const t of transactions) {
      if (t.categoryId) {
        byCategory[t.categoryId] = (byCategory[t.categoryId] || 0) + t.amount;
      }

      if (t.groupId && needsGroups.includes(t.groupId)) {
        needs += t.amount;
      } else {
        wants += t.amount;
      }
    }

    return { byCategory, needs, wants, total: needs + wants };
  }

  private generateRecommendations(
    spending: { byCategory: Record<string, number>; total: number },
    forecasts: Array<{ urgency: string | null; systemName: string; estimatedReplacementCost: number | null }>,
  ) {
    const recs: Array<{
      title: string;
      description: string;
      action: string;
      savings?: number;
    }> = [];

    if ((spending.byCategory.electric || 0) > 200) {
      recs.push({
        title: 'Reduce Electric Bill',
        description:
          'Your electric bill is above average. Alfred can research solar options or energy audits.',
        action: 'ASK_ALFRED_RESEARCH',
        savings: (spending.byCategory.electric || 0) * 0.2,
      });
    }

    const criticalForecasts = forecasts.filter((f) => f.urgency === 'CRITICAL');
    for (const forecast of criticalForecasts) {
      recs.push({
        title: `Plan for ${forecast.systemName} Replacement`,
        description: `This system is past typical lifespan. Budget ~$${forecast.estimatedReplacementCost?.toLocaleString()} for replacement.`,
        action: 'CREATE_BUDGET_CATEGORY',
      });
    }

    return recs;
  }
}

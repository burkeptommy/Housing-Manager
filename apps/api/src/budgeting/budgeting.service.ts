import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthPayload } from '../firebase';
import { BUDGET_CATEGORY_GROUPS, getCategoryInfo, BUDGET_BENCHMARKS } from './constants/budget-categories';

interface BudgetCategoryInput {
  categoryId: string;
  groupId: string;
  budgetedAmount: number;
}

interface ManualTransactionInput {
  date: string;
  amount: number;
  name: string;
  categoryId?: string;
  groupId?: string;
  notes?: string;
}

@Injectable()
export class BudgetingService {
  private readonly logger = new Logger(BudgetingService.name);

  constructor(private prisma: PrismaService) {}

  private async getHouseholdId(user: AuthPayload): Promise<string> {
    const member = await this.prisma.householdMember.findFirst({
      where: { userId: user.userId },
      select: { householdId: true },
    });
    if (!member) throw new BadRequestException('No household found');
    return member.householdId;
  }

  // =========================================================================
  // BUDGET SETUP
  // =========================================================================

  async getBudget(user: AuthPayload) {
    const householdId = await this.getHouseholdId(user);

    const budget = await this.prisma.budget.findUnique({
      where: { householdId },
      include: { categories: true },
    });

    if (!budget) {
      return {
        exists: false,
        categoryGroups: BUDGET_CATEGORY_GROUPS,
        benchmarks: BUDGET_BENCHMARKS,
      };
    }

    // Enrich categories with display info
    const enrichedCategories = budget.categories.map((cat) => {
      const info = getCategoryInfo(cat.categoryId);
      return {
        ...cat,
        name: info?.name || cat.categoryId,
        groupName: info?.groupName || cat.groupId,
        color: info?.color || '#90a4ae',
        icon: info?.icon || 'help',
      };
    });

    return {
      exists: true,
      id: budget.id,
      name: budget.name,
      monthlyIncome: budget.monthlyIncome,
      categories: enrichedCategories,
      categoryGroups: BUDGET_CATEGORY_GROUPS,
      benchmarks: BUDGET_BENCHMARKS,
    };
  }

  async createOrUpdateBudget(
    user: AuthPayload,
    body: { monthlyIncome?: number; categories: BudgetCategoryInput[] },
  ) {
    const householdId = await this.getHouseholdId(user);

    const budget = await this.prisma.budget.upsert({
      where: { householdId },
      create: {
        householdId,
        monthlyIncome: body.monthlyIncome,
      },
      update: {
        monthlyIncome: body.monthlyIncome,
      },
    });

    // Upsert categories
    for (const cat of body.categories) {
      await this.prisma.budgetCategory.upsert({
        where: {
          budgetId_categoryId: {
            budgetId: budget.id,
            categoryId: cat.categoryId,
          },
        },
        create: {
          budgetId: budget.id,
          categoryId: cat.categoryId,
          groupId: cat.groupId,
          budgetedAmount: cat.budgetedAmount,
        },
        update: {
          budgetedAmount: cat.budgetedAmount,
          groupId: cat.groupId,
        },
      });
    }

    return this.getBudget(user);
  }

  async updateCategoryBudget(
    user: AuthPayload,
    categoryId: string,
    budgetedAmount: number,
  ) {
    const householdId = await this.getHouseholdId(user);

    const budget = await this.prisma.budget.findUnique({
      where: { householdId },
    });
    if (!budget) throw new BadRequestException('Budget not set up yet');

    await this.prisma.budgetCategory.updateMany({
      where: { budgetId: budget.id, categoryId },
      data: { budgetedAmount },
    });

    return { success: true };
  }

  // =========================================================================
  // SPENDING ANALYSIS
  // =========================================================================

  async getSpendingSummary(user: AuthPayload, month?: string) {
    const householdId = await this.getHouseholdId(user);
    const { startDate, endDate } = this.getMonthRange(month);

    const [budget, transactions, bills, forecasts] = await Promise.all([
      this.prisma.budget.findUnique({
        where: { householdId },
        include: { categories: true },
      }),
      this.prisma.budgetTransaction.findMany({
        where: {
          householdId,
          date: { gte: startDate, lte: endDate },
          isHidden: false,
          amount: { gt: 0 },
        },
      }),
      this.prisma.bill.findMany({
        where: { householdId, status: 'active' },
        orderBy: { nextDueDate: 'asc' },
        take: 5,
      }),
      this.prisma.systemForecast.findMany({
        where: { householdId },
      }),
    ]);

    const totalSpent = transactions.reduce((sum, t) => sum + t.amount, 0);
    const totalBudget = budget?.categories.reduce((sum, c) => sum + c.budgetedAmount, 0) || 0;

    // Group spending by category
    const spendingByCategory: Record<string, number> = {};
    for (const t of transactions) {
      if (t.categoryId) {
        spendingByCategory[t.categoryId] = (spendingByCategory[t.categoryId] || 0) + t.amount;
      }
    }

    // Top categories
    const topCategories = Object.entries(spendingByCategory)
      .map(([categoryId, spent]) => {
        const info = getCategoryInfo(categoryId);
        const budgetCat = budget?.categories.find((c) => c.categoryId === categoryId);
        return {
          categoryId,
          name: info?.name || categoryId,
          color: info?.color || '#90a4ae',
          spent,
          budget: budgetCat?.budgetedAmount || null,
        };
      })
      .sort((a, b) => b.spent - a.spent);

    // Upcoming bills
    const upcomingBills = bills.map((b) => ({
      id: b.id,
      name: b.name,
      amount: b.amount || 0,
      dueDate: b.nextDueDate
        ? new Date(b.nextDueDate).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
        : 'No date',
    }));

    // Forecast preview
    const currentYear = new Date().getFullYear();
    const upcomingForecasts = forecasts.filter(
      (f) => f.expectedReplacementYear && f.expectedReplacementYear <= currentYear + 5,
    );
    const forecastPreview = upcomingForecasts.length > 0
      ? {
          upcomingCount: upcomingForecasts.length,
          totalCost: upcomingForecasts.reduce(
            (sum, f) => sum + (f.estimatedReplacementCost || 0),
            0,
          ),
        }
      : null;

    // Quick insight
    let insight: string | null = null;
    if (totalBudget > 0 && totalSpent > totalBudget * 0.9) {
      insight = `You've used ${Math.round((totalSpent / totalBudget) * 100)}% of your budget this month. Consider reviewing discretionary spending.`;
    } else if (topCategories.length > 0) {
      insight = `${topCategories[0].name} is your top spending category this month at $${topCategories[0].spent.toLocaleString()}.`;
    }

    return {
      monthlyIncome: budget?.monthlyIncome || null,
      totalSpent,
      totalBudget,
      topCategories,
      upcomingBills,
      forecastPreview,
      insight,
    };
  }

  async getSpendingByCategory(user: AuthPayload, month?: string) {
    const householdId = await this.getHouseholdId(user);
    const { startDate, endDate } = this.getMonthRange(month);

    const [budget, transactions] = await Promise.all([
      this.prisma.budget.findUnique({
        where: { householdId },
        include: { categories: true },
      }),
      this.prisma.budgetTransaction.findMany({
        where: {
          householdId,
          date: { gte: startDate, lte: endDate },
          isHidden: false,
          amount: { gt: 0 },
        },
      }),
    ]);

    // Group by groupId
    const groupSpending: Record<string, { spent: number; budgeted: number; categories: Record<string, number> }> = {};

    for (const t of transactions) {
      const groupId = t.groupId || 'OTHER';
      if (!groupSpending[groupId]) {
        groupSpending[groupId] = { spent: 0, budgeted: 0, categories: {} };
      }
      groupSpending[groupId].spent += t.amount;
      if (t.categoryId) {
        groupSpending[groupId].categories[t.categoryId] =
          (groupSpending[groupId].categories[t.categoryId] || 0) + t.amount;
      }
    }

    // Add budget amounts
    if (budget) {
      for (const cat of budget.categories) {
        if (!groupSpending[cat.groupId]) {
          groupSpending[cat.groupId] = { spent: 0, budgeted: 0, categories: {} };
        }
        groupSpending[cat.groupId].budgeted += cat.budgetedAmount;
      }
    }

    return Object.entries(groupSpending).map(([groupId, data]) => {
      const group = BUDGET_CATEGORY_GROUPS[groupId];
      return {
        groupId,
        name: group?.name || groupId,
        color: group?.color || '#90a4ae',
        icon: group?.icon || 'help',
        spent: data.spent,
        budgeted: data.budgeted,
        categories: Object.entries(data.categories).map(([catId, spent]) => {
          const info = getCategoryInfo(catId);
          const budgetCat = budget?.categories.find((c) => c.categoryId === catId);
          return {
            categoryId: catId,
            name: info?.name || catId,
            icon: info?.icon || 'help',
            spent,
            budgeted: budgetCat?.budgetedAmount || 0,
          };
        }),
      };
    });
  }

  async getSpendingTrends(user: AuthPayload, months: number) {
    const householdId = await this.getHouseholdId(user);
    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth() - months + 1, 1);

    const transactions = await this.prisma.budgetTransaction.findMany({
      where: {
        householdId,
        date: { gte: startDate },
        isHidden: false,
        amount: { gt: 0 },
      },
      orderBy: { date: 'asc' },
    });

    // Group by month
    const byMonth: Record<string, { total: number; byGroup: Record<string, number> }> = {};
    for (const t of transactions) {
      const monthKey = `${t.date.getFullYear()}-${String(t.date.getMonth() + 1).padStart(2, '0')}`;
      if (!byMonth[monthKey]) {
        byMonth[monthKey] = { total: 0, byGroup: {} };
      }
      byMonth[monthKey].total += t.amount;
      const group = t.groupId || 'OTHER';
      byMonth[monthKey].byGroup[group] = (byMonth[monthKey].byGroup[group] || 0) + t.amount;
    }

    return Object.entries(byMonth).map(([month, data]) => ({
      month,
      total: data.total,
      byGroup: data.byGroup,
    }));
  }

  async getLocalComparisons(user: AuthPayload) {
    const householdId = await this.getHouseholdId(user);

    const homeProfile = await this.prisma.homeProfile.findFirst({
      where: { householdId },
    });
    if (!homeProfile?.postalCode) return { comparisons: [] };

    const localData = await this.prisma.localCostData.findMany({
      where: { zipCode: homeProfile.postalCode },
    });

    const { startDate, endDate } = this.getMonthRange();
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

    return {
      comparisons: localData.map((local) => {
        const userSpending = spendingByCategory[local.category] || 0;
        const info = getCategoryInfo(local.category);
        return {
          category: local.category,
          name: info?.name || local.category,
          yourSpending: userSpending,
          localAverage: local.averageMonthly,
          localMedian: local.medianMonthly,
          percentile25: local.percentile25,
          percentile75: local.percentile75,
          diff: local.averageMonthly > 0
            ? ((userSpending - local.averageMonthly) / local.averageMonthly) * 100
            : 0,
        };
      }),
    };
  }

  // =========================================================================
  // TRANSACTIONS
  // =========================================================================

  async getTransactions(
    user: AuthPayload,
    filters: { month?: string; category?: string; limit?: number },
  ) {
    const householdId = await this.getHouseholdId(user);
    const { startDate, endDate } = this.getMonthRange(filters.month);

    const transactions = await this.prisma.budgetTransaction.findMany({
      where: {
        householdId,
        date: { gte: startDate, lte: endDate },
        isHidden: false,
        ...(filters.category && { categoryId: filters.category }),
      },
      orderBy: { date: 'desc' },
      take: filters.limit || 50,
    });

    return transactions.map((t) => {
      const info = t.categoryId ? getCategoryInfo(t.categoryId) : null;
      return {
        ...t,
        categoryName: info?.name || 'Uncategorized',
        categoryColor: info?.color || '#90a4ae',
        categoryIcon: info?.icon || 'help',
      };
    });
  }

  async categorizeTransaction(
    user: AuthPayload,
    id: string,
    body: { categoryId: string; groupId: string },
  ) {
    const householdId = await this.getHouseholdId(user);

    await this.prisma.budgetTransaction.updateMany({
      where: { id, householdId },
      data: {
        categoryId: body.categoryId,
        groupId: body.groupId,
        isAutoCategorized: false,
      },
    });

    return { success: true };
  }

  async addManualTransaction(user: AuthPayload, body: ManualTransactionInput) {
    const householdId = await this.getHouseholdId(user);

    const transaction = await this.prisma.budgetTransaction.create({
      data: {
        householdId,
        date: new Date(body.date),
        amount: body.amount,
        name: body.name,
        categoryId: body.categoryId,
        groupId: body.groupId,
        notes: body.notes,
      },
    });

    return transaction;
  }

  // =========================================================================
  // ENHANCED SUMMARY (Monarch-level)
  // =========================================================================

  async getEnhancedSummary(user: AuthPayload, month?: string) {
    const householdId = await this.getHouseholdId(user);
    const { startDate, endDate } = this.getMonthRange(month);

    // Previous month range
    const prevStart = new Date(startDate);
    prevStart.setMonth(prevStart.getMonth() - 1);
    const prevEnd = new Date(startDate);
    prevEnd.setDate(prevEnd.getDate() - 1);
    prevEnd.setHours(23, 59, 59);

    // Previous week ranges
    const now = new Date();
    const thisWeekStart = new Date(now);
    thisWeekStart.setDate(now.getDate() - now.getDay());
    thisWeekStart.setHours(0, 0, 0, 0);
    const lastWeekStart = new Date(thisWeekStart);
    lastWeekStart.setDate(lastWeekStart.getDate() - 7);
    const lastWeekEnd = new Date(thisWeekStart);
    lastWeekEnd.setMilliseconds(-1);

    const [budget, currentTx, prevTx, thisWeekTx, lastWeekTx, bills, maintenanceTasks, forecasts] = await Promise.all([
      this.prisma.budget.findUnique({
        where: { householdId },
        include: { categories: true },
      }),
      this.prisma.budgetTransaction.findMany({
        where: { householdId, date: { gte: startDate, lte: endDate }, isHidden: false, amount: { gt: 0 } },
      }),
      this.prisma.budgetTransaction.findMany({
        where: { householdId, date: { gte: prevStart, lte: prevEnd }, isHidden: false, amount: { gt: 0 } },
      }),
      this.prisma.budgetTransaction.findMany({
        where: { householdId, date: { gte: thisWeekStart, lte: now }, isHidden: false, amount: { gt: 0 } },
      }),
      this.prisma.budgetTransaction.findMany({
        where: { householdId, date: { gte: lastWeekStart, lte: lastWeekEnd }, isHidden: false, amount: { gt: 0 } },
      }),
      this.prisma.bill.findMany({
        where: { householdId, status: 'active' },
        orderBy: { nextDueDate: 'asc' },
        take: 10,
      }),
      this.prisma.maintenanceTask.findMany({
        where: {
          householdId,
          status: { in: ['PENDING', 'SCHEDULED'] },
          dueDate: { gte: now },
        },
        orderBy: { dueDate: 'asc' },
        take: 5,
      }),
      this.prisma.systemForecast.findMany({
        where: { householdId },
      }),
    ]);

    const totalSpent = currentTx.reduce((s, t) => s + t.amount, 0);
    const prevTotalSpent = prevTx.reduce((s, t) => s + t.amount, 0);
    const thisWeekSpent = thisWeekTx.reduce((s, t) => s + t.amount, 0);
    const lastWeekSpent = lastWeekTx.reduce((s, t) => s + t.amount, 0);
    const totalBudget = budget?.categories.reduce((s, c) => s + c.budgetedAmount, 0) || 0;

    // Period comparisons
    const monthOverMonth = prevTotalSpent > 0
      ? ((totalSpent - prevTotalSpent) / prevTotalSpent) * 100
      : 0;
    const weekOverWeek = lastWeekSpent > 0
      ? ((thisWeekSpent - lastWeekSpent) / lastWeekSpent) * 100
      : 0;

    // Spending pace
    const dayOfMonth = now.getDate();
    const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
    const dailyAverage = dayOfMonth > 0 ? totalSpent / dayOfMonth : 0;
    const projectedTotal = dailyAverage * daysInMonth;
    const onTrack = totalBudget > 0 ? projectedTotal <= totalBudget * 1.05 : true;

    // Weekly breakdown for sparkline
    const weeklyBreakdown: Array<{ week: number; amount: number }> = [];
    for (let w = 0; w < 5; w++) {
      const wStart = new Date(startDate);
      wStart.setDate(wStart.getDate() + w * 7);
      const wEnd = new Date(wStart);
      wEnd.setDate(wEnd.getDate() + 6);
      wEnd.setHours(23, 59, 59);
      if (wStart > endDate) break;
      const weekAmount = currentTx
        .filter((t) => t.date >= wStart && t.date <= wEnd)
        .reduce((s, t) => s + t.amount, 0);
      weeklyBreakdown.push({ week: w + 1, amount: weekAmount });
    }

    // Top categories with delta
    const currentByCategory: Record<string, number> = {};
    const prevByCategory: Record<string, number> = {};
    for (const t of currentTx) {
      if (t.categoryId) currentByCategory[t.categoryId] = (currentByCategory[t.categoryId] || 0) + t.amount;
    }
    for (const t of prevTx) {
      if (t.categoryId) prevByCategory[t.categoryId] = (prevByCategory[t.categoryId] || 0) + t.amount;
    }

    const topCategories = Object.entries(currentByCategory)
      .map(([categoryId, spent]) => {
        const info = getCategoryInfo(categoryId);
        const prevSpent = prevByCategory[categoryId] || 0;
        const delta = prevSpent > 0 ? ((spent - prevSpent) / prevSpent) * 100 : 0;
        return {
          categoryId,
          name: info?.name || categoryId,
          color: info?.color || '#90a4ae',
          icon: info?.icon || 'help',
          spent,
          prevSpent,
          delta: Math.round(delta),
          trend: delta > 5 ? 'up' as const : delta < -5 ? 'down' as const : 'stable' as const,
        };
      })
      .sort((a, b) => b.spent - a.spent)
      .slice(0, 6);

    // Unified upcoming: bills + maintenance merged
    const upcomingItems = [
      ...bills.map((b) => ({
        id: b.id,
        name: b.name,
        amount: b.amount || 0,
        dueDate: b.nextDueDate?.toISOString() || null,
        type: 'bill' as const,
        icon: 'card-outline' as const,
      })),
      ...maintenanceTasks.map((m) => ({
        id: m.id,
        name: m.title,
        amount: m.estimatedCost || 0,
        dueDate: m.dueDate?.toISOString() || null,
        type: 'maintenance' as const,
        icon: 'build-outline' as const,
      })),
    ].sort((a, b) => {
      if (!a.dueDate) return 1;
      if (!b.dueDate) return -1;
      return new Date(a.dueDate).getTime() - new Date(b.dueDate).getTime();
    }).slice(0, 8);

    // Maintenance summary
    const maintenanceBudgetCat = budget?.categories.find((c) => c.categoryId === 'maintenance');
    const maintenanceSpent = currentByCategory['maintenance'] || 0;
    const urgentForecasts = forecasts.filter(
      (f) => f.urgency === 'HIGH' || f.urgency === 'CRITICAL',
    );

    // Typed insights
    const insights: Array<{ type: string; title: string; message: string; action?: string }> = [];
    if (monthOverMonth > 15) {
      insights.push({
        type: 'overspend',
        title: 'Spending Up',
        message: `You're spending ${Math.round(monthOverMonth)}% more than last month.`,
        action: 'Review Budget',
      });
    }
    if (!onTrack && totalBudget > 0) {
      insights.push({
        type: 'pace',
        title: 'Over Pace',
        message: `At this rate, you'll spend ${formatAmount(projectedTotal)} this month (budget: ${formatAmount(totalBudget)}).`,
        action: 'View Transactions',
      });
    }
    if (urgentForecasts.length > 0) {
      insights.push({
        type: 'forecast',
        title: 'Home Alert',
        message: `${urgentForecasts.length} home system${urgentForecasts.length > 1 ? 's' : ''} need${urgentForecasts.length === 1 ? 's' : ''} attention soon.`,
        action: 'View Forecast',
      });
    }
    if (totalBudget === 0 && totalSpent > 0) {
      insights.push({
        type: 'setup',
        title: 'Set a Budget',
        message: 'Create a budget to track your spending against goals.',
        action: 'Set Up Budget',
      });
    }

    return {
      period: {
        month: startDate.toLocaleDateString('en-US', { month: 'long', year: 'numeric' }),
        startDate: startDate.toISOString(),
        endDate: endDate.toISOString(),
      },
      spending: {
        totalSpent,
        totalBudget,
        remaining: totalBudget - totalSpent,
        monthlyIncome: budget?.monthlyIncome || null,
      },
      comparisons: {
        monthOverMonth: Math.round(monthOverMonth),
        weekOverWeek: Math.round(weekOverWeek),
        prevMonthTotal: prevTotalSpent,
        thisWeekTotal: thisWeekSpent,
        lastWeekTotal: lastWeekSpent,
      },
      pace: {
        dailyAverage: Math.round(dailyAverage),
        projectedTotal: Math.round(projectedTotal),
        onTrack,
        dayOfMonth,
        daysInMonth,
      },
      weeklyBreakdown,
      topCategories,
      upcoming: upcomingItems,
      maintenance: {
        budgeted: maintenanceBudgetCat?.budgetedAmount || 0,
        spent: maintenanceSpent,
        urgentCount: urgentForecasts.length,
      },
      insights,
    };
  }

  // =========================================================================
  // RECURRING PAYMENTS
  // =========================================================================

  async getRecurringPayments(user: AuthPayload) {
    const householdId = await this.getHouseholdId(user);

    // Fetch from three sources
    const [detectedBills, manualBills, comprehensiveBills] = await Promise.all([
      this.prisma.detectedBill.findMany({
        where: { householdId, status: { in: ['PENDING', 'CONFIRMED'] } },
      }),
      this.prisma.bill.findMany({
        where: { householdId, status: 'active' },
      }),
      this.prisma.comprehensiveBill.findMany({
        where: { householdId, status: 'ACTIVE' },
      }),
    ]);

    // Merge and dedupe by normalized name
    const normalize = (name: string) => name.toLowerCase().replace(/[^a-z0-9]/g, '');
    const seen = new Set<string>();
    const payments: Array<{
      id: string;
      name: string;
      amount: number;
      frequency: string;
      category: string;
      categoryName: string;
      nextDueDate: string | null;
      trend: 'up' | 'down' | 'stable';
      monthlyEquivalent: number;
      source: string;
    }> = [];

    // Helper to compute monthly equivalent
    const toMonthly = (amount: number, freq: string) => {
      switch (freq.toLowerCase()) {
        case 'weekly': return amount * 4.33;
        case 'biweekly': return amount * 2.17;
        case 'monthly': return amount;
        case 'quarterly': return amount / 3;
        case 'semiannual': return amount / 6;
        case 'annual': case 'yearly': return amount / 12;
        default: return amount;
      }
    };

    // Detected bills (Plaid)
    for (const b of detectedBills) {
      const key = normalize(b.merchantName);
      if (seen.has(key)) continue;
      seen.add(key);
      const catStr = b.category?.toString().toLowerCase() || 'uncategorized';
      const info = getCategoryInfo(catStr);
      payments.push({
        id: b.id,
        name: b.merchantName,
        amount: b.lastAmount || b.averageAmount || 0,
        frequency: b.frequency || 'MONTHLY',
        category: catStr,
        categoryName: info?.name || b.category?.toString() || 'Uncategorized',
        nextDueDate: b.nextExpectedDate?.toISOString() || null,
        trend: b.lastAmount && b.averageAmount
          ? b.lastAmount > b.averageAmount * 1.05 ? 'up'
            : b.lastAmount < b.averageAmount * 0.95 ? 'down'
            : 'stable'
          : 'stable',
        monthlyEquivalent: toMonthly(b.lastAmount || b.averageAmount || 0, b.frequency || 'MONTHLY'),
        source: 'detected',
      });
    }

    // Manual bills
    for (const b of manualBills) {
      const key = normalize(b.name);
      if (seen.has(key)) continue;
      seen.add(key);
      const catStr = b.category || 'uncategorized';
      const info = getCategoryInfo(catStr);
      payments.push({
        id: b.id,
        name: b.name,
        amount: b.amount || 0,
        frequency: b.frequency || 'monthly',
        category: catStr,
        categoryName: info?.name || 'Uncategorized',
        nextDueDate: b.nextDueDate?.toISOString() || null,
        trend: 'stable',
        monthlyEquivalent: toMonthly(b.amount || 0, b.frequency || 'monthly'),
        source: 'manual',
      });
    }

    // Comprehensive bills
    for (const b of comprehensiveBills) {
      const key = normalize(b.name);
      if (seen.has(key)) continue;
      seen.add(key);
      const catStr = b.category?.toString().toLowerCase() || 'uncategorized';
      const info = getCategoryInfo(catStr);
      const amt = Number(b.amount) || 0;
      payments.push({
        id: b.id,
        name: b.name,
        amount: amt,
        frequency: b.frequency || 'MONTHLY',
        category: catStr,
        categoryName: info?.name || b.category?.toString() || 'Uncategorized',
        nextDueDate: b.dueDate?.toISOString() || null,
        trend: 'stable',
        monthlyEquivalent: toMonthly(amt, b.frequency || 'MONTHLY'),
        source: 'comprehensive',
      });
    }

    // Sort by next due date
    payments.sort((a, b) => {
      if (!a.nextDueDate) return 1;
      if (!b.nextDueDate) return -1;
      return new Date(a.nextDueDate).getTime() - new Date(b.nextDueDate).getTime();
    });

    // Summary stats
    const monthlyTotal = payments.reduce((s, p) => s + p.monthlyEquivalent, 0);
    const annualTotal = monthlyTotal * 12;

    // Category breakdown
    const byCategory: Record<string, { name: string; total: number; count: number }> = {};
    for (const p of payments) {
      if (!byCategory[p.category]) {
        byCategory[p.category] = { name: p.categoryName, total: 0, count: 0 };
      }
      byCategory[p.category].total += p.monthlyEquivalent;
      byCategory[p.category].count += 1;
    }

    return {
      payments,
      summary: {
        monthlyTotal: Math.round(monthlyTotal),
        annualTotal: Math.round(annualTotal),
        count: payments.length,
      },
      byCategory: Object.entries(byCategory)
        .map(([categoryId, data]) => ({
          categoryId,
          name: data.name,
          monthlyTotal: Math.round(data.total),
          count: data.count,
        }))
        .sort((a, b) => b.monthlyTotal - a.monthlyTotal),
    };
  }

  // =========================================================================
  // BUDGET SUGGESTIONS
  // =========================================================================

  async getBudgetSuggestions(user: AuthPayload) {
    const householdId = await this.getHouseholdId(user);

    // Get 3-month spending averages
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const [transactions, budget, forecasts, homeProfile] = await Promise.all([
      this.prisma.budgetTransaction.findMany({
        where: {
          householdId,
          date: { gte: threeMonthsAgo },
          isHidden: false,
          amount: { gt: 0 },
        },
      }),
      this.prisma.budget.findUnique({
        where: { householdId },
        include: { categories: true },
      }),
      this.prisma.systemForecast.findMany({
        where: { householdId },
      }),
      this.prisma.homeProfile.findFirst({
        where: { householdId },
      }),
    ]);

    // 3-month averages by category
    const categoryTotals: Record<string, number> = {};
    for (const t of transactions) {
      if (t.categoryId) {
        categoryTotals[t.categoryId] = (categoryTotals[t.categoryId] || 0) + t.amount;
      }
    }
    const monthlyAverages: Record<string, number> = {};
    for (const [catId, total] of Object.entries(categoryTotals)) {
      monthlyAverages[catId] = Math.round(total / 3);
    }

    // Maintenance reserve suggestion
    const totalMaintenanceForecast = forecasts.reduce(
      (s, f) => s + (f.estimatedMaintenanceCost || 0),
      0,
    );
    const maintenanceReserve = Math.round(totalMaintenanceForecast / 12);

    // Generate suggestions: use actual averages + benchmarks
    const monthlyIncome = budget?.monthlyIncome || 0;
    const suggestions: Array<{
      categoryId: string;
      groupId: string;
      name: string;
      icon: string;
      suggestedAmount: number;
      threeMonthAvg: number;
      benchmarkPercent: number | null;
      benchmarkAmount: number | null;
      reason: string;
    }> = [];

    for (const [groupId, bench] of Object.entries(BUDGET_BENCHMARKS)) {
      const group = BUDGET_CATEGORY_GROUPS[groupId];
      if (!group) continue;

      for (const cat of group.categories) {
        const avg = monthlyAverages[cat.id] || 0;
        const benchAmount = monthlyIncome > 0
          ? Math.round(monthlyIncome * (bench.recommended / 100))
          : null;

        // Suggest based on actual spending or benchmark, whichever is more useful
        let suggestedAmount = avg;
        let reason = '';

        if (avg > 0) {
          suggestedAmount = avg;
          reason = 'Based on your 3-month average';
          if (benchAmount && avg > benchAmount * 1.2) {
            reason = 'Your spending exceeds recommended levels';
            suggestedAmount = Math.round((avg + benchAmount) / 2); // Suggest midpoint
          }
        } else if (benchAmount && benchAmount > 0) {
          suggestedAmount = benchAmount;
          reason = `${bench.label} of income`;
        }

        if (suggestedAmount > 0) {
          suggestions.push({
            categoryId: cat.id,
            groupId,
            name: cat.name,
            icon: cat.icon || group.icon,
            suggestedAmount,
            threeMonthAvg: avg,
            benchmarkPercent: bench.recommended,
            benchmarkAmount: benchAmount,
            reason,
          });
        }
      }
    }

    // Add maintenance reserve if applicable
    if (maintenanceReserve > 0) {
      suggestions.push({
        categoryId: 'maintenance',
        groupId: 'HOUSING',
        name: 'Home Maintenance Reserve',
        icon: 'build',
        suggestedAmount: maintenanceReserve,
        threeMonthAvg: monthlyAverages['maintenance'] || 0,
        benchmarkPercent: null,
        benchmarkAmount: null,
        reason: 'Based on your home system forecasts',
      });
    }

    // Sort: highest suggested first
    suggestions.sort((a, b) => b.suggestedAmount - a.suggestedAmount);

    return {
      hasBudget: budget?.categories ? budget.categories.length > 0 : false,
      monthlyIncome,
      suggestions,
      totalSuggested: suggestions.reduce((s, sg) => s + sg.suggestedAmount, 0),
      maintenanceReserve,
    };
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  private getMonthRange(month?: string): { startDate: Date; endDate: Date } {
    const now = new Date();
    let year = now.getFullYear();
    let m = now.getMonth();

    if (month) {
      const parts = month.split('-');
      year = parseInt(parts[0]);
      m = parseInt(parts[1]) - 1;
    }

    const startDate = new Date(year, m, 1);
    const endDate = new Date(year, m + 1, 0, 23, 59, 59);
    return { startDate, endDate };
  }
}

function formatAmount(amount: number): string {
  return `$${Math.round(amount).toLocaleString()}`;
}

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

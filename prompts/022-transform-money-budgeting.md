# Haven: Transform Money into Monarch-Style Budgeting App

**Created:** February 3, 2026  
**Priority:** HIGH - Core feature for beta launch 2/15  
**Focus:** Mobile-first (then web)  
**Prerequisite:** Run 011b first to fix Firebase auth

---

## OVERVIEW

Transform Haven's Money feature from a payment processing concept into a comprehensive Monarch-style budgeting and home forecasting application. This becomes one of Haven's core value propositions at the Essentials tier.

**Key Differentiator:** While Monarch does general budgeting, Haven focuses on HOME finances with intelligent forecasting based on property age, systems, and maintenance schedules.

---

## CORE FEATURES

### 1. Budget Categories (Monarch-style)
- Hierarchical category groups
- Customizable categories
- Smart transaction categorization
- 50/30/20 rule guidance

### 2. Spending Analysis
- Monthly/annual views
- Category breakdowns
- Trends over time
- Local & national comparisons

### 3. Home Forecasting (Haven Exclusive)
- System replacement timeline
- Maintenance cost projections
- "Your furnace is 25 years old, budget $X in 2027"
- Alfred research for make/model specific data

### 4. Bill Tracking
- Detected from Plaid
- Manual entry
- Due date reminders
- Average comparisons

---

## BUDGET CATEGORY STRUCTURE

Based on Monarch's proven hierarchy, adapted for homeowners:

```typescript
// apps/api/src/budgeting/constants/budget-categories.ts

export const BUDGET_CATEGORY_GROUPS = {
  // === HOUSING (Home-focused - Haven's specialty) ===
  HOUSING: {
    name: 'Housing',
    icon: 'home',
    color: '#7D8E74', // Sage
    categories: [
      { id: 'mortgage', name: 'Mortgage/Rent', icon: 'business' },
      { id: 'property_tax', name: 'Property Tax', icon: 'document' },
      { id: 'home_insurance', name: 'Home Insurance', icon: 'shield' },
      { id: 'hoa', name: 'HOA Fees', icon: 'people' },
      { id: 'home_improvement', name: 'Home Improvement', icon: 'construct' },
      { id: 'home_maintenance', name: 'Home Maintenance', icon: 'hammer' },
      { id: 'home_services', name: 'Home Services', icon: 'sparkles' },
    ],
  },

  // === UTILITIES ===
  UTILITIES: {
    name: 'Bills & Utilities',
    icon: 'flash',
    color: '#486581',
    categories: [
      { id: 'electric', name: 'Electric', icon: 'flash' },
      { id: 'gas', name: 'Gas', icon: 'flame' },
      { id: 'water', name: 'Water & Sewer', icon: 'water' },
      { id: 'garbage', name: 'Garbage', icon: 'trash' },
      { id: 'internet', name: 'Internet & Cable', icon: 'wifi' },
      { id: 'phone', name: 'Phone', icon: 'phone-portrait' },
      { id: 'security', name: 'Security System', icon: 'shield-checkmark' },
    ],
  },

  // === FOOD & DINING ===
  FOOD: {
    name: 'Food & Dining',
    icon: 'restaurant',
    color: '#c4a574',
    categories: [
      { id: 'groceries', name: 'Groceries', icon: 'cart' },
      { id: 'restaurants', name: 'Restaurants & Bars', icon: 'restaurant' },
      { id: 'coffee', name: 'Coffee Shops', icon: 'cafe' },
      { id: 'food_delivery', name: 'Food Delivery', icon: 'bicycle' },
    ],
  },

  // === TRANSPORTATION ===
  TRANSPORTATION: {
    name: 'Auto & Transport',
    icon: 'car',
    color: '#334e68',
    categories: [
      { id: 'auto_payment', name: 'Auto Payment', icon: 'car' },
      { id: 'auto_insurance', name: 'Auto Insurance', icon: 'shield' },
      { id: 'gas_fuel', name: 'Gas & Fuel', icon: 'speedometer' },
      { id: 'auto_maintenance', name: 'Auto Maintenance', icon: 'build' },
      { id: 'parking', name: 'Parking & Tolls', icon: 'location' },
      { id: 'rideshare', name: 'Taxi & Ride Shares', icon: 'car-sport' },
      { id: 'public_transit', name: 'Public Transit', icon: 'train' },
    ],
  },

  // === HEALTH ===
  HEALTH: {
    name: 'Health & Wellness',
    icon: 'heart',
    color: '#e57373',
    categories: [
      { id: 'medical', name: 'Medical', icon: 'medkit' },
      { id: 'dental', name: 'Dental', icon: 'happy' },
      { id: 'vision', name: 'Vision', icon: 'eye' },
      { id: 'pharmacy', name: 'Pharmacy', icon: 'medical' },
      { id: 'fitness', name: 'Fitness & Gym', icon: 'barbell' },
      { id: 'health_insurance', name: 'Health Insurance', icon: 'shield' },
    ],
  },

  // === CHILDREN (Home-focused) ===
  CHILDREN: {
    name: 'Children',
    icon: 'people',
    color: '#81c784',
    categories: [
      { id: 'childcare', name: 'Child Care', icon: 'person' },
      { id: 'tuition', name: 'Tuition', icon: 'school' },
      { id: 'activities', name: 'Activities & Sports', icon: 'football' },
      { id: 'child_supplies', name: 'Kids Supplies', icon: 'bag' },
      { id: 'summer_camp', name: 'Summer Camp', icon: 'sunny' },
    ],
  },

  // === PETS (Home-focused) ===
  PETS: {
    name: 'Pets',
    icon: 'paw',
    color: '#a1887f',
    categories: [
      { id: 'pet_food', name: 'Pet Food & Supplies', icon: 'nutrition' },
      { id: 'vet', name: 'Veterinary', icon: 'medkit' },
      { id: 'pet_grooming', name: 'Grooming', icon: 'cut' },
      { id: 'pet_boarding', name: 'Boarding & Daycare', icon: 'home' },
    ],
  },

  // === SHOPPING ===
  SHOPPING: {
    name: 'Shopping',
    icon: 'bag',
    color: '#9575cd',
    categories: [
      { id: 'clothing', name: 'Clothing', icon: 'shirt' },
      { id: 'electronics', name: 'Electronics', icon: 'laptop' },
      { id: 'furniture', name: 'Furniture & Housewares', icon: 'bed' },
      { id: 'general_shopping', name: 'General Shopping', icon: 'bag' },
    ],
  },

  // === LIFESTYLE ===
  LIFESTYLE: {
    name: 'Travel & Lifestyle',
    icon: 'airplane',
    color: '#4fc3f7',
    categories: [
      { id: 'travel', name: 'Travel & Vacation', icon: 'airplane' },
      { id: 'entertainment', name: 'Entertainment', icon: 'film' },
      { id: 'subscriptions', name: 'Subscriptions', icon: 'tv' },
      { id: 'hobbies', name: 'Hobbies', icon: 'game-controller' },
      { id: 'personal_care', name: 'Personal Care', icon: 'cut' },
    ],
  },

  // === FINANCIAL ===
  FINANCIAL: {
    name: 'Financial & Legal',
    icon: 'wallet',
    color: '#ffd54f',
    categories: [
      { id: 'savings', name: 'Savings', icon: 'trending-up' },
      { id: 'investments', name: 'Investments', icon: 'stats-chart' },
      { id: 'loans', name: 'Loan Repayment', icon: 'cash' },
      { id: 'fees', name: 'Bank Fees', icon: 'card' },
      { id: 'taxes', name: 'Taxes', icon: 'document-text' },
      { id: 'life_insurance', name: 'Life Insurance', icon: 'shield' },
    ],
  },

  // === GIVING ===
  GIVING: {
    name: 'Gifts & Donations',
    icon: 'gift',
    color: '#f48fb1',
    categories: [
      { id: 'charity', name: 'Charity', icon: 'heart' },
      { id: 'gifts', name: 'Gifts', icon: 'gift' },
    ],
  },

  // === INCOME ===
  INCOME: {
    name: 'Income',
    icon: 'trending-up',
    color: '#66bb6a',
    type: 'INCOME',
    categories: [
      { id: 'salary', name: 'Salary', icon: 'briefcase' },
      { id: 'bonus', name: 'Bonus', icon: 'star' },
      { id: 'freelance', name: 'Freelance', icon: 'laptop' },
      { id: 'rental_income', name: 'Rental Income', icon: 'home' },
      { id: 'investments_income', name: 'Investment Returns', icon: 'trending-up' },
      { id: 'other_income', name: 'Other Income', icon: 'cash' },
    ],
  },

  // === OTHER ===
  OTHER: {
    name: 'Other',
    icon: 'ellipsis-horizontal',
    color: '#90a4ae',
    categories: [
      { id: 'uncategorized', name: 'Uncategorized', icon: 'help' },
      { id: 'cash', name: 'Cash & ATM', icon: 'cash' },
      { id: 'transfer', name: 'Transfer', icon: 'swap-horizontal' },
    ],
  },
};

// National average benchmarks (% of income)
export const BUDGET_BENCHMARKS = {
  HOUSING: { recommended: 0.28, max: 0.35, label: '28-35%' },
  UTILITIES: { recommended: 0.05, max: 0.10, label: '5-10%' },
  FOOD: { recommended: 0.10, max: 0.15, label: '10-15%' },
  TRANSPORTATION: { recommended: 0.10, max: 0.15, label: '10-15%' },
  HEALTH: { recommended: 0.05, max: 0.10, label: '5-10%' },
  CHILDREN: { recommended: 0.10, max: 0.20, label: '10-20%' },
  SHOPPING: { recommended: 0.05, max: 0.10, label: '5-10%' },
  LIFESTYLE: { recommended: 0.05, max: 0.10, label: '5-10%' },
  FINANCIAL: { recommended: 0.15, max: 0.20, label: '15-20% (savings)' },
};
```

---

## DATABASE SCHEMA UPDATES

**File:** `apps/api/prisma/schema.prisma`

```prisma
// ============================================================================
// BUDGETING SYSTEM
// ============================================================================

model Budget {
  id            String   @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  name          String   @default("Monthly Budget")
  monthlyIncome Float?   // Estimated monthly income
  
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  
  categories    BudgetCategory[]
  
  @@unique([householdId])
}

model BudgetCategory {
  id            String   @id @default(cuid())
  budgetId      String
  budget        Budget   @relation(fields: [budgetId], references: [id], onDelete: Cascade)
  
  categoryId    String   // e.g., 'groceries', 'electric'
  groupId       String   // e.g., 'FOOD', 'UTILITIES'
  
  budgetedAmount  Float  // Monthly budget
  isActive        Boolean @default(true)
  rolloverEnabled Boolean @default(false)
  
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  
  @@unique([budgetId, categoryId])
  @@index([budgetId])
}

model Transaction {
  id            String   @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  // From Plaid or manual
  plaidTransactionId String?  @unique
  accountId     String?
  
  date          DateTime
  amount        Float    // Positive = expense, Negative = income
  name          String   // Original description
  merchantName  String?  // Cleaned merchant name
  
  // Categorization
  categoryId    String?  // e.g., 'groceries'
  groupId       String?  // e.g., 'FOOD'
  isAutoCategorized Boolean @default(false)
  
  // Flags
  isPending     Boolean  @default(false)
  isHidden      Boolean  @default(false)
  isRecurring   Boolean  @default(false)
  
  notes         String?
  
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  
  @@index([householdId, date])
  @@index([householdId, categoryId])
}

// Home system forecasts - Haven's differentiator
model SystemForecast {
  id            String   @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id], onDelete: Cascade)
  
  systemId      String?  // Link to PropertyAsset if exists
  systemType    String   // HVAC_FURNACE, WATER_HEATER, ROOF, etc.
  systemName    String   // "Carrier Furnace" or generic
  
  // Age tracking
  installYear   Int?
  currentAge    Int?     // Calculated
  
  // Lifecycle data
  typicalLifespan     Int    // Years (e.g., 20 for furnace)
  lifespanMin         Int?   // Range min
  lifespanMax         Int?   // Range max
  
  // Cost estimates
  estimatedReplacementCost  Float?
  estimatedMaintenanceCost  Float?  // Annual
  
  // Forecast
  expectedReplacementYear   Int?
  urgency                   String?  // LOW, MEDIUM, HIGH, CRITICAL
  
  // Alfred research data
  alfredResearchDate  DateTime?
  alfredResearchData  Json?    // Make/model specific info, recalls, etc.
  
  notes         String?
  
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  
  @@index([householdId])
}

// Local cost data for comparisons
model LocalCostData {
  id            String   @id @default(cuid())
  zipCode       String
  category      String   // 'electric', 'water', 'gas', etc.
  
  averageMonthly    Float
  medianMonthly     Float?
  percentile25      Float?
  percentile75      Float?
  
  sampleSize    Int?
  lastUpdated   DateTime
  source        String?  // 'BLS', 'EIA', 'user_data'
  
  @@unique([zipCode, category])
}
```

---

## API ENDPOINTS

**File:** `apps/api/src/budgeting/budgeting.controller.ts`

```typescript
@Controller('budgeting')
@UseGuards(JwtAuthGuard)
export class BudgetingController {
  constructor(private readonly budgetingService: BudgetingService) {}

  // === BUDGET SETUP ===
  
  @Get('budget')
  async getBudget(@CurrentUser() user: User) {
    return this.budgetingService.getBudget(user);
  }

  @Post('budget')
  async createOrUpdateBudget(
    @CurrentUser() user: User,
    @Body() body: { monthlyIncome?: number; categories: BudgetCategoryInput[] },
  ) {
    return this.budgetingService.createOrUpdateBudget(user, body);
  }

  @Put('budget/category/:categoryId')
  async updateCategoryBudget(
    @CurrentUser() user: User,
    @Param('categoryId') categoryId: string,
    @Body() body: { budgetedAmount: number },
  ) {
    return this.budgetingService.updateCategoryBudget(user, categoryId, body.budgetedAmount);
  }

  // === SPENDING ANALYSIS ===

  @Get('spending/summary')
  async getSpendingSummary(
    @CurrentUser() user: User,
    @Query('month') month?: string, // YYYY-MM
  ) {
    return this.budgetingService.getSpendingSummary(user, month);
  }

  @Get('spending/by-category')
  async getSpendingByCategory(
    @CurrentUser() user: User,
    @Query('month') month?: string,
  ) {
    return this.budgetingService.getSpendingByCategory(user, month);
  }

  @Get('spending/trends')
  async getSpendingTrends(
    @CurrentUser() user: User,
    @Query('months') months?: number, // Default 6
  ) {
    return this.budgetingService.getSpendingTrends(user, months || 6);
  }

  @Get('spending/comparisons')
  async getLocalComparisons(@CurrentUser() user: User) {
    return this.budgetingService.getLocalComparisons(user);
  }

  // === TRANSACTIONS ===

  @Get('transactions')
  async getTransactions(
    @CurrentUser() user: User,
    @Query('month') month?: string,
    @Query('category') category?: string,
    @Query('limit') limit?: number,
  ) {
    return this.budgetingService.getTransactions(user, { month, category, limit });
  }

  @Put('transactions/:id/categorize')
  async categorizeTransaction(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: { categoryId: string; groupId: string },
  ) {
    return this.budgetingService.categorizeTransaction(user, id, body);
  }

  @Post('transactions/manual')
  async addManualTransaction(
    @CurrentUser() user: User,
    @Body() body: ManualTransactionInput,
  ) {
    return this.budgetingService.addManualTransaction(user, body);
  }

  // === HOME FORECASTING (Haven Exclusive) ===

  @Get('forecast')
  async getHomeForecasts(@CurrentUser() user: User) {
    return this.budgetingService.getHomeForecasts(user);
  }

  @Get('forecast/timeline')
  async getForecastTimeline(
    @CurrentUser() user: User,
    @Query('years') years?: number, // Default 10
  ) {
    return this.budgetingService.getForecastTimeline(user, years || 10);
  }

  @Post('forecast/system')
  async addSystemForecast(
    @CurrentUser() user: User,
    @Body() body: SystemForecastInput,
  ) {
    return this.budgetingService.addSystemForecast(user, body);
  }

  @Put('forecast/system/:id')
  async updateSystemForecast(
    @CurrentUser() user: User,
    @Param('id') id: string,
    @Body() body: Partial<SystemForecastInput>,
  ) {
    return this.budgetingService.updateSystemForecast(user, id, body);
  }

  @Post('forecast/system/:id/alfred-research')
  async requestAlfredResearch(
    @CurrentUser() user: User,
    @Param('id') id: string,
  ) {
    return this.budgetingService.requestAlfredResearch(user, id);
  }

  // === INSIGHTS ===

  @Get('insights')
  async getBudgetInsights(@CurrentUser() user: User) {
    return this.budgetingService.getBudgetInsights(user);
  }
}
```

---

## HOME FORECASTING SERVICE (Haven's Differentiator)

**File:** `apps/api/src/budgeting/forecast.service.ts`

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import Anthropic from '@anthropic-ai/sdk';

// Typical lifespans for home systems
const SYSTEM_LIFESPANS: Record<string, { min: number; max: number; typical: number; avgCost: number }> = {
  HVAC_FURNACE: { min: 15, max: 30, typical: 20, avgCost: 5000 },
  HVAC_AC: { min: 10, max: 20, typical: 15, avgCost: 4000 },
  HVAC_HEAT_PUMP: { min: 10, max: 20, typical: 15, avgCost: 6000 },
  WATER_HEATER_TANK: { min: 8, max: 15, typical: 12, avgCost: 1500 },
  WATER_HEATER_TANKLESS: { min: 15, max: 25, typical: 20, avgCost: 3000 },
  ROOF_ASPHALT: { min: 20, max: 30, typical: 25, avgCost: 15000 },
  ROOF_METAL: { min: 40, max: 70, typical: 50, avgCost: 25000 },
  ROOF_TILE: { min: 50, max: 100, typical: 75, avgCost: 30000 },
  SEPTIC: { min: 25, max: 40, typical: 30, avgCost: 10000 },
  WELL_PUMP: { min: 8, max: 15, typical: 10, avgCost: 2000 },
  GARAGE_DOOR: { min: 15, max: 30, typical: 20, avgCost: 1500 },
  APPLIANCE_DISHWASHER: { min: 8, max: 15, typical: 10, avgCost: 800 },
  APPLIANCE_WASHER: { min: 10, max: 15, typical: 12, avgCost: 900 },
  APPLIANCE_DRYER: { min: 10, max: 18, typical: 13, avgCost: 800 },
  APPLIANCE_REFRIGERATOR: { min: 10, max: 20, typical: 15, avgCost: 1500 },
  APPLIANCE_OVEN: { min: 12, max: 20, typical: 15, avgCost: 1200 },
  POOL_PUMP: { min: 8, max: 12, typical: 10, avgCost: 2500 },
  POOL_HEATER: { min: 7, max: 12, typical: 10, avgCost: 3500 },
  GENERATOR: { min: 15, max: 30, typical: 20, avgCost: 8000 },
  SIDING_VINYL: { min: 20, max: 40, typical: 30, avgCost: 12000 },
  SIDING_WOOD: { min: 15, max: 25, typical: 20, avgCost: 15000 },
  WINDOWS: { min: 15, max: 30, typical: 20, avgCost: 10000 },
  DECK: { min: 10, max: 20, typical: 15, avgCost: 5000 },
  DRIVEWAY_ASPHALT: { min: 15, max: 25, typical: 20, avgCost: 4000 },
  DRIVEWAY_CONCRETE: { min: 25, max: 50, typical: 30, avgCost: 6000 },
};

@Injectable()
export class ForecastService {
  private readonly logger = new Logger(ForecastService.name);
  private anthropic: Anthropic;

  constructor(private prisma: PrismaService) {
    this.anthropic = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY,
    });
  }

  /**
   * Generate forecasts from existing home systems
   */
  async generateForecastsFromSystems(householdId: string) {
    // Get all property assets (systems)
    const assets = await this.prisma.propertyAsset.findMany({
      where: { householdId },
    });

    // Get home profile for year built
    const homeProfile = await this.prisma.homeProfile.findFirst({
      where: { householdId },
    });

    const currentYear = new Date().getFullYear();
    const forecasts: any[] = [];

    for (const asset of assets) {
      const systemType = this.mapAssetToSystemType(asset.category, asset.name);
      if (!systemType || !SYSTEM_LIFESPANS[systemType]) continue;

      const lifespan = SYSTEM_LIFESPANS[systemType];
      
      // Determine install year
      let installYear = asset.installDate 
        ? new Date(asset.installDate).getFullYear()
        : homeProfile?.yearBuilt || currentYear - Math.floor(lifespan.typical / 2);

      const currentAge = currentYear - installYear;
      const expectedReplacementYear = installYear + lifespan.typical;
      
      // Calculate urgency
      let urgency = 'LOW';
      const remainingYears = expectedReplacementYear - currentYear;
      if (remainingYears <= 0) urgency = 'CRITICAL';
      else if (remainingYears <= 2) urgency = 'HIGH';
      else if (remainingYears <= 5) urgency = 'MEDIUM';

      forecasts.push({
        householdId,
        systemId: asset.id,
        systemType,
        systemName: asset.name || this.getSystemDisplayName(systemType),
        installYear,
        currentAge,
        typicalLifespan: lifespan.typical,
        lifespanMin: lifespan.min,
        lifespanMax: lifespan.max,
        estimatedReplacementCost: lifespan.avgCost,
        expectedReplacementYear,
        urgency,
      });
    }

    // Upsert all forecasts
    for (const forecast of forecasts) {
      await this.prisma.systemForecast.upsert({
        where: {
          id: forecast.systemId ? 
            (await this.prisma.systemForecast.findFirst({
              where: { systemId: forecast.systemId },
            }))?.id || 'new' 
            : 'new',
        },
        create: forecast,
        update: forecast,
      });
    }

    return forecasts;
  }

  /**
   * Get forecast timeline for visual display
   */
  async getForecastTimeline(householdId: string, years: number = 10) {
    const forecasts = await this.prisma.systemForecast.findMany({
      where: { householdId },
      orderBy: { expectedReplacementYear: 'asc' },
    });

    const currentYear = new Date().getFullYear();
    const timeline: Record<number, { items: any[]; totalCost: number }> = {};

    // Initialize years
    for (let y = currentYear; y <= currentYear + years; y++) {
      timeline[y] = { items: [], totalCost: 0 };
    }

    // Populate with forecasts
    for (const forecast of forecasts) {
      const year = forecast.expectedReplacementYear;
      if (year && year >= currentYear && year <= currentYear + years) {
        timeline[year].items.push({
          id: forecast.id,
          name: forecast.systemName,
          type: forecast.systemType,
          cost: forecast.estimatedReplacementCost || 0,
          urgency: forecast.urgency,
        });
        timeline[year].totalCost += forecast.estimatedReplacementCost || 0;
      }
    }

    return {
      years: Object.entries(timeline).map(([year, data]) => ({
        year: parseInt(year),
        ...data,
      })),
      totalProjected: forecasts.reduce((sum, f) => sum + (f.estimatedReplacementCost || 0), 0),
    };
  }

  /**
   * Alfred researches specific make/model for better data
   */
  async alfredResearch(forecastId: string) {
    const forecast = await this.prisma.systemForecast.findUnique({
      where: { id: forecastId },
      include: {
        household: {
          include: {
            homeProfiles: true,
          },
        },
      },
    });

    if (!forecast) throw new Error('Forecast not found');

    // Get linked asset for more details
    const asset = forecast.systemId 
      ? await this.prisma.propertyAsset.findUnique({
          where: { id: forecast.systemId },
        })
      : null;

    const prompt = `Research the following home system for a homeowner:

System Type: ${forecast.systemType}
System Name: ${forecast.systemName}
${asset?.brand ? `Brand: ${asset.brand}` : ''}
${asset?.model ? `Model: ${asset.model}` : ''}
${forecast.installYear ? `Install Year: ${forecast.installYear}` : ''}
Location: ${forecast.household.homeProfiles?.[0]?.city}, ${forecast.household.homeProfiles?.[0]?.state}

Please provide:
1. Expected lifespan for this specific make/model (if known)
2. Common issues/failure points for this age
3. Any recalls or known problems
4. Estimated replacement cost in this area
5. Recommended maintenance to extend life
6. Signs that replacement is needed

Return as JSON:
{
  "specificLifespan": { "min": number, "max": number, "typical": number },
  "commonIssues": ["string"],
  "recalls": [{ "date": "string", "description": "string" }],
  "estimatedCost": { "low": number, "high": number, "average": number },
  "maintenanceTips": ["string"],
  "replacementSigns": ["string"],
  "notes": "string"
}`;

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 2000,
        messages: [{ role: 'user', content: prompt }],
      });

      const content = response.content[0];
      if (content.type !== 'text') throw new Error('Unexpected response');

      const jsonMatch = content.text.match(/\{[\s\S]*\}/);
      if (!jsonMatch) throw new Error('No JSON in response');

      const researchData = JSON.parse(jsonMatch[0]);

      // Update forecast with research
      await this.prisma.systemForecast.update({
        where: { id: forecastId },
        data: {
          alfredResearchDate: new Date(),
          alfredResearchData: researchData,
          // Update estimates if research provided better data
          ...(researchData.specificLifespan && {
            typicalLifespan: researchData.specificLifespan.typical,
            lifespanMin: researchData.specificLifespan.min,
            lifespanMax: researchData.specificLifespan.max,
          }),
          ...(researchData.estimatedCost && {
            estimatedReplacementCost: researchData.estimatedCost.average,
          }),
        },
      });

      return researchData;
    } catch (error) {
      this.logger.error(`Alfred research failed: ${error.message}`);
      throw error;
    }
  }

  private mapAssetToSystemType(category: string, name: string): string | null {
    const nameLower = (name || '').toLowerCase();
    
    if (category === 'HVAC') {
      if (nameLower.includes('furnace')) return 'HVAC_FURNACE';
      if (nameLower.includes('ac') || nameLower.includes('air condition')) return 'HVAC_AC';
      if (nameLower.includes('heat pump')) return 'HVAC_HEAT_PUMP';
    }
    if (nameLower.includes('water heater')) {
      return nameLower.includes('tankless') ? 'WATER_HEATER_TANKLESS' : 'WATER_HEATER_TANK';
    }
    if (nameLower.includes('roof')) return 'ROOF_ASPHALT'; // Default
    if (nameLower.includes('septic')) return 'SEPTIC';
    if (nameLower.includes('well') && nameLower.includes('pump')) return 'WELL_PUMP';
    // ... more mappings
    
    return null;
  }

  private getSystemDisplayName(systemType: string): string {
    const names: Record<string, string> = {
      HVAC_FURNACE: 'Furnace',
      HVAC_AC: 'Air Conditioner',
      HVAC_HEAT_PUMP: 'Heat Pump',
      WATER_HEATER_TANK: 'Water Heater (Tank)',
      WATER_HEATER_TANKLESS: 'Water Heater (Tankless)',
      ROOF_ASPHALT: 'Roof (Asphalt Shingle)',
      ROOF_METAL: 'Roof (Metal)',
      SEPTIC: 'Septic System',
      WELL_PUMP: 'Well Pump',
      // ... more
    };
    return names[systemType] || systemType;
  }
}
```

---

## MOBILE SCREENS

### Money Tab Structure (Mobile-First)

```
Money Tab
├── Overview (Default)
│   ├── Monthly Summary Card
│   ├── Budget Progress Bars
│   ├── Recent Transactions
│   └── Quick Actions
│
├── Budget Screen
│   ├── Category List with Progress
│   ├── Add/Edit Category
│   └── Income Setup
│
├── Transactions Screen
│   ├── Transaction List (filterable)
│   ├── Categorize Modal
│   └── Add Manual Transaction
│
├── Forecast Screen (Haven Exclusive)
│   ├── Timeline View
│   ├── System Cards
│   ├── Add System
│   └── Alfred Research Button
│
├── Bills Screen
│   ├── Upcoming Bills
│   ├── Bill History
│   └── Connect Bank
│
└── Insights Screen
    ├── Comparisons
    ├── Trends Charts
    └── Recommendations
```

### Overview Screen

**File:** `apps/mobile/app/(tabs)/money/index.tsx`

```tsx
import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  RefreshControl,
} from 'react-native';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { ScreenContainer } from '../../../src/components';
import { colors, spacing, typography, borderRadius } from '../../../src/lib/theme';
import { getIdToken } from '../../../src/lib/firebase';

const API_URL = process.env.EXPO_PUBLIC_API_URL;

export default function MoneyOverviewScreen() {
  const [summary, setSummary] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      const token = await getIdToken();
      const response = await fetch(`${API_URL}/budgeting/spending/summary`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await response.json();
      setSummary(data);
    } catch (error) {
      console.error('Failed to fetch summary:', error);
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const onRefresh = () => {
    setIsRefreshing(true);
    fetchData();
  };

  if (!summary) return null;

  const spentPercent = summary.monthlyIncome 
    ? (summary.totalSpent / summary.monthlyIncome) * 100 
    : 0;

  return (
    <ScreenContainer title="Money">
      <ScrollView
        style={styles.container}
        refreshControl={
          <RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />
        }
      >
        {/* Monthly Summary Card */}
        <View style={styles.summaryCard}>
          <Text style={styles.summaryMonth}>
            {new Date().toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
          </Text>
          
          <View style={styles.summaryRow}>
            <View style={styles.summaryItem}>
              <Text style={styles.summaryLabel}>Spent</Text>
              <Text style={styles.summaryAmount}>
                ${summary.totalSpent?.toLocaleString() || '0'}
              </Text>
            </View>
            <View style={styles.summaryDivider} />
            <View style={styles.summaryItem}>
              <Text style={styles.summaryLabel}>Budget</Text>
              <Text style={styles.summaryAmount}>
                ${summary.totalBudget?.toLocaleString() || '0'}
              </Text>
            </View>
          </View>

          {/* Progress Bar */}
          <View style={styles.progressContainer}>
            <View style={styles.progressBar}>
              <View 
                style={[
                  styles.progressFill,
                  { width: `${Math.min(spentPercent, 100)}%` },
                  spentPercent > 100 && styles.progressOverBudget,
                ]} 
              />
            </View>
            <Text style={[
              styles.progressText,
              spentPercent > 100 && styles.progressTextOver,
            ]}>
              {spentPercent > 100 
                ? `${(spentPercent - 100).toFixed(0)}% over budget`
                : `${(100 - spentPercent).toFixed(0)}% remaining`}
            </Text>
          </View>
        </View>

        {/* Quick Navigation */}
        <View style={styles.quickNav}>
          <TouchableOpacity 
            style={styles.quickNavItem}
            onPress={() => router.push('/(tabs)/money/budget')}
          >
            <View style={[styles.quickNavIcon, { backgroundColor: colors.haven.sage[100] }]}>
              <Ionicons name="pie-chart" size={20} color={colors.haven.sage[600]} />
            </View>
            <Text style={styles.quickNavLabel}>Budget</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.quickNavItem}
            onPress={() => router.push('/(tabs)/money/transactions')}
          >
            <View style={[styles.quickNavIcon, { backgroundColor: colors.haven.navy[100] }]}>
              <Ionicons name="list" size={20} color={colors.haven.navy[600]} />
            </View>
            <Text style={styles.quickNavLabel}>Transactions</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.quickNavItem}
            onPress={() => router.push('/(tabs)/money/forecast')}
          >
            <View style={[styles.quickNavIcon, { backgroundColor: '#FFF3E0' }]}>
              <Ionicons name="trending-up" size={20} color="#F57C00" />
            </View>
            <Text style={styles.quickNavLabel}>Forecast</Text>
          </TouchableOpacity>

          <TouchableOpacity 
            style={styles.quickNavItem}
            onPress={() => router.push('/(tabs)/money/bills')}
          >
            <View style={[styles.quickNavIcon, { backgroundColor: '#E8F5E9' }]}>
              <Ionicons name="receipt" size={20} color="#43A047" />
            </View>
            <Text style={styles.quickNavLabel}>Bills</Text>
          </TouchableOpacity>
        </View>

        {/* Top Categories */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Top Spending</Text>
            <TouchableOpacity onPress={() => router.push('/(tabs)/money/budget')}>
              <Text style={styles.sectionLink}>See All</Text>
            </TouchableOpacity>
          </View>

          {summary.topCategories?.slice(0, 4).map((cat: any, index: number) => (
            <View key={cat.categoryId || index} style={styles.categoryRow}>
              <View style={[styles.categoryDot, { backgroundColor: cat.color || colors.haven.sage[500] }]} />
              <Text style={styles.categoryName}>{cat.name}</Text>
              <Text style={styles.categoryAmount}>${cat.spent.toLocaleString()}</Text>
              <Text style={styles.categoryBudget}>/ ${cat.budget?.toLocaleString() || '-'}</Text>
            </View>
          ))}
        </View>

        {/* Upcoming Bills */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Upcoming Bills</Text>
            <TouchableOpacity onPress={() => router.push('/(tabs)/money/bills')}>
              <Text style={styles.sectionLink}>See All</Text>
            </TouchableOpacity>
          </View>

          {summary.upcomingBills?.slice(0, 3).map((bill: any, index: number) => (
            <View key={bill.id || index} style={styles.billRow}>
              <View style={styles.billInfo}>
                <Text style={styles.billName}>{bill.name}</Text>
                <Text style={styles.billDue}>Due {bill.dueDate}</Text>
              </View>
              <Text style={styles.billAmount}>${bill.amount.toLocaleString()}</Text>
            </View>
          ))}

          {(!summary.upcomingBills || summary.upcomingBills.length === 0) && (
            <TouchableOpacity 
              style={styles.connectBankButton}
              onPress={() => router.push('/(tabs)/money/connect')}
            >
              <Ionicons name="add-circle-outline" size={20} color={colors.haven.sage[600]} />
              <Text style={styles.connectBankText}>Connect bank to auto-detect bills</Text>
            </TouchableOpacity>
          )}
        </View>

        {/* Forecast Preview */}
        {summary.forecastPreview && (
          <TouchableOpacity 
            style={styles.forecastCard}
            onPress={() => router.push('/(tabs)/money/forecast')}
          >
            <View style={styles.forecastHeader}>
              <Ionicons name="trending-up" size={24} color={colors.haven.sage[500]} />
              <Text style={styles.forecastTitle}>Home Forecast</Text>
            </View>
            <Text style={styles.forecastText}>
              {summary.forecastPreview.upcomingCount} items projected in the next 5 years
            </Text>
            <Text style={styles.forecastAmount}>
              ~${summary.forecastPreview.totalCost?.toLocaleString()} estimated
            </Text>
          </TouchableOpacity>
        )}

        {/* Insights Banner */}
        {summary.insight && (
          <View style={styles.insightBanner}>
            <Ionicons name="bulb" size={20} color={colors.haven.sage[600]} />
            <Text style={styles.insightText}>{summary.insight}</Text>
          </View>
        )}
      </ScrollView>
    </ScreenContainer>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  summaryCard: {
    backgroundColor: colors.haven.navy[900],
    margin: spacing[4],
    padding: spacing[5],
    borderRadius: borderRadius.xl,
  },
  summaryMonth: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    opacity: 0.8,
    marginBottom: spacing[3],
  },
  summaryRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  summaryItem: {
    flex: 1,
  },
  summaryLabel: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    opacity: 0.7,
    marginBottom: spacing[1],
  },
  summaryAmount: {
    color: colors.white,
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
  },
  summaryDivider: {
    width: 1,
    height: 40,
    backgroundColor: 'rgba(255,255,255,0.2)',
    marginHorizontal: spacing[4],
  },
  progressContainer: {
    marginTop: spacing[4],
  },
  progressBar: {
    height: 8,
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderRadius: 4,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.haven.sage[400],
    borderRadius: 4,
  },
  progressOverBudget: {
    backgroundColor: '#ef4444',
  },
  progressText: {
    color: colors.white,
    fontSize: typography.fontSizes.sm,
    marginTop: spacing[2],
    opacity: 0.8,
  },
  progressTextOver: {
    color: '#fca5a5',
  },
  quickNav: {
    flexDirection: 'row',
    paddingHorizontal: spacing[4],
    marginBottom: spacing[4],
    gap: spacing[3],
  },
  quickNavItem: {
    flex: 1,
    alignItems: 'center',
  },
  quickNavIcon: {
    width: 48,
    height: 48,
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[2],
  },
  quickNavLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.navy[600],
    fontWeight: typography.fontWeights.medium,
  },
  section: {
    paddingHorizontal: spacing[4],
    marginBottom: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  sectionLink: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.sage[600],
    fontWeight: typography.fontWeights.medium,
  },
  categoryRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
  },
  categoryDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: spacing[3],
  },
  categoryName: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.haven.navy[800],
  },
  categoryAmount: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  categoryBudget: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[400],
    marginLeft: spacing[1],
  },
  billRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[2],
  },
  billInfo: {
    flex: 1,
  },
  billName: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[900],
  },
  billDue: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[500],
  },
  billAmount: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  connectBankButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.haven.softGreen,
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    gap: spacing[2],
  },
  connectBankText: {
    color: colors.haven.sage[700],
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
  },
  forecastCard: {
    backgroundColor: colors.haven.softGreen,
    marginHorizontal: spacing[4],
    marginBottom: spacing[4],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
  },
  forecastHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  forecastTitle: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.navy[900],
  },
  forecastText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[600],
    marginBottom: spacing[1],
  },
  forecastAmount: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.sage[700],
  },
  insightBanner: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: colors.white,
    marginHorizontal: spacing[4],
    marginBottom: spacing[4],
    padding: spacing[4],
    borderRadius: borderRadius.lg,
    borderLeftWidth: 4,
    borderLeftColor: colors.haven.sage[500],
    gap: spacing[3],
  },
  insightText: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[700],
    lineHeight: 20,
  },
});
```

---

## INSIGHTS SERVICE (Comparisons & Recommendations)

**File:** `apps/api/src/budgeting/insights.service.ts`

```typescript
@Injectable()
export class InsightsService {
  constructor(private prisma: PrismaService) {}

  async getBudgetInsights(householdId: string) {
    const [spending, forecasts, homeProfile] = await Promise.all([
      this.getSpendingData(householdId),
      this.prisma.systemForecast.findMany({ where: { householdId } }),
      this.prisma.homeProfile.findFirst({ where: { householdId } }),
    ]);

    const insights: string[] = [];

    // Compare to local averages
    const zipCode = homeProfile?.zipCode;
    if (zipCode) {
      const localData = await this.prisma.localCostData.findMany({
        where: { zipCode },
      });

      for (const local of localData) {
        const userSpending = spending.byCategory[local.category];
        if (userSpending && local.averageMonthly) {
          const diff = ((userSpending - local.averageMonthly) / local.averageMonthly) * 100;
          
          if (diff > 20) {
            insights.push(
              `Your ${local.category} spending is ${diff.toFixed(0)}% above the local average. ` +
              `Want Alfred to find better rates?`
            );
          } else if (diff < -20) {
            insights.push(
              `Great job! Your ${local.category} costs are ${Math.abs(diff).toFixed(0)}% below average.`
            );
          }
        }
      }
    }

    // Forecast warnings
    const urgentForecasts = forecasts.filter(f => f.urgency === 'HIGH' || f.urgency === 'CRITICAL');
    if (urgentForecasts.length > 0) {
      const names = urgentForecasts.map(f => f.systemName).join(', ');
      insights.push(
        `Heads up: Your ${names} ${urgentForecasts.length > 1 ? 'are' : 'is'} approaching end of life. ` +
        `Consider budgeting for replacement.`
      );
    }

    // 50/30/20 analysis
    if (spending.monthlyIncome) {
      const needsPercent = (spending.needs / spending.monthlyIncome) * 100;
      const wantsPercent = (spending.wants / spending.monthlyIncome) * 100;
      
      if (needsPercent > 55) {
        insights.push(
          `Your essential spending is ${needsPercent.toFixed(0)}% of income (target: 50%). ` +
          `Look for ways to reduce fixed costs.`
        );
      }
      
      if (wantsPercent > 35) {
        insights.push(
          `Discretionary spending is ${wantsPercent.toFixed(0)}% of income (target: 30%). ` +
          `Small cuts here can boost savings.`
        );
      }
    }

    return {
      insights,
      comparisons: await this.getLocalComparisons(householdId, zipCode),
      recommendations: this.generateRecommendations(spending, forecasts),
    };
  }

  private generateRecommendations(spending: any, forecasts: any[]) {
    const recs: Array<{ title: string; description: string; action: string; savings?: number }> = [];

    // High utility costs
    if (spending.byCategory.electric > 200) {
      recs.push({
        title: 'Reduce Electric Bill',
        description: 'Your electric bill is above average. Alfred can research solar options or energy audits.',
        action: 'ASK_ALFRED_RESEARCH',
        savings: spending.byCategory.electric * 0.2,
      });
    }

    // Upcoming replacements
    const criticalForecasts = forecasts.filter(f => f.urgency === 'CRITICAL');
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
```

---

## DEPLOYMENT CHECKLIST

### Database
- [ ] Run migration: `pnpm prisma migrate dev --name budgeting_system`
- [ ] Seed budget categories
- [ ] Import local cost data (optional)

### API
- [ ] BudgetingModule registered
- [ ] All endpoints tested
- [ ] Forecast generation from systems works
- [ ] Alfred research integration works

### Mobile
- [ ] Money tab restructured
- [ ] Overview screen complete
- [ ] Budget screen with category management
- [ ] Transactions screen with categorization
- [ ] Forecast timeline screen
- [ ] Bills screen updated
- [ ] Insights/comparisons displayed

### Integration
- [ ] Plaid transactions flow to budgeting
- [ ] Auto-categorization working
- [ ] Home systems generate forecasts
- [ ] Alfred research updates forecasts

---

## TEST SCENARIOS

### 1. First Time User
- No budget set up
- Shows "Set up your budget" prompt
- Income entry → Category selection → Budget amounts

### 2. Connected Bank
- Transactions import automatically
- Smart categorization applied
- User can recategorize with one tap

### 3. Over Budget Alert
- Category exceeds budget
- Red progress bar
- Notification sent

### 4. Forecast Discovery
- User has 25-year-old furnace
- Alfred identifies as HIGH urgency
- Shows in forecast timeline
- "Ask Alfred to research" available

### 5. Local Comparison
- Electric bill $250/month
- Local average $180/month
- Insight: "39% above local average"
- Recommendation: "Want Alfred to find better rates?"

---

## DEPLOYMENT

```bash
# 1. Run migration
cd apps/api
pnpm prisma migrate dev --name budgeting_system

# 2. Deploy API
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# 3. Build mobile
cd apps/mobile
eas build --platform ios --profile production --auto-submit
```

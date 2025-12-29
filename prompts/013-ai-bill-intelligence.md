# Haven: AI-Powered Bill Intelligence & "Missing Bills" UX

**Created:** December 29, 2024  
**Purpose:** Smart bill detection, categorization, and "Anything we're missing?" feature  
**Priority:** P1 - Enhanced user experience  
**Depends On:** 012 (Demo Data) - in progress

---

## Overview

Enhance Haven's bill detection with AI intelligence:

1. **"Anything We're Missing?"** - Suggest bills based on property profile
2. **Smart Categorization** - Use Claude to categorize ambiguous transactions
3. **Merchant Name Matching** - "EVRSC" → "Eversource Electric"
4. **Document Parsing** - Extract bill details from uploaded documents

---

## CRITICAL RULES

1. **AI is assistive** - Always let user confirm/override AI suggestions
2. **Privacy first** - Don't send sensitive financial data to AI unnecessarily
3. **Graceful fallback** - If AI fails, fall back to rule-based detection
4. **DO NOT DELETE existing functionality**

---

## PHASE 1: "Anything We're Missing?" Feature

### Task 1.1: Create Bill Suggestions Service

Create `apps/api/src/bills/bill-suggestions.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import Anthropic from '@anthropic-ai/sdk';

interface BillSuggestion {
  category: string;
  label: string;
  description: string;
  estimatedAmount?: { min: number; max: number };
  frequency: string;
  reason: string; // Why we're suggesting this
  confidence: number;
}

@Injectable()
export class BillSuggestionsService {
  private readonly logger = new Logger(BillSuggestionsService.name);
  private anthropic: Anthropic | null = null;

  constructor(private prisma: PrismaService) {
    if (process.env.ANTHROPIC_API_KEY) {
      this.anthropic = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY,
      });
    }
  }

  /**
   * Get suggested bills based on property profile and location
   */
  async getSuggestedBills(householdId: string): Promise<BillSuggestion[]> {
    // Get household property data
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        properties: {
          include: { enrichmentData: true },
        },
        detectedBills: true,
      },
    });

    if (!household) return [];

    const property = household.properties?.[0];
    const enrichment = property?.enrichmentData;
    const existingBills = household.detectedBills || [];
    const existingCategories = new Set(existingBills.map((b) => b.category));

    // Rule-based suggestions
    const suggestions: BillSuggestion[] = [];

    // Property-based suggestions
    if (enrichment) {
      // Pool
      if (enrichment.hasPool && !existingCategories.has('POOL_SERVICE')) {
        suggestions.push({
          category: 'POOL_SERVICE',
          label: 'Pool Service',
          description: 'Weekly pool maintenance and chemical balancing',
          estimatedAmount: { min: 200, max: 500 },
          frequency: 'MONTHLY',
          reason: 'Your property has a pool',
          confidence: 0.9,
        });
      }

      // Septic (not on sewer)
      if (enrichment.sewerType === 'SEPTIC' && !existingCategories.has('SEPTIC_SERVICE')) {
        suggestions.push({
          category: 'SEPTIC_SERVICE',
          label: 'Septic Pumping',
          description: 'Septic tank pumping and inspection',
          estimatedAmount: { min: 300, max: 600 },
          frequency: 'ANNUAL',
          reason: 'Your property has a septic system',
          confidence: 0.85,
        });
      }

      // Large lot = landscaping
      if (enrichment.lotSizeAcres && enrichment.lotSizeAcres > 0.5 && !existingCategories.has('LANDSCAPING')) {
        suggestions.push({
          category: 'LANDSCAPING',
          label: 'Landscaping Service',
          description: 'Lawn maintenance, mowing, seasonal cleanup',
          estimatedAmount: { min: 300, max: 1500 },
          frequency: 'MONTHLY',
          reason: `Your property is ${enrichment.lotSizeAcres.toFixed(1)} acres`,
          confidence: 0.8,
        });
      }

      // Fireplace = chimney sweep
      if (enrichment.fireplaceCount && enrichment.fireplaceCount > 0 && !existingCategories.has('CHIMNEY_SERVICE')) {
        suggestions.push({
          category: 'CHIMNEY_SERVICE',
          label: 'Chimney Sweep',
          description: 'Annual chimney cleaning and inspection',
          estimatedAmount: { min: 150, max: 400 },
          frequency: 'ANNUAL',
          reason: `Your home has ${enrichment.fireplaceCount} fireplace(s)`,
          confidence: 0.75,
        });
      }

      // Generator
      if (enrichment.hasGenerator && !existingCategories.has('GENERATOR_SERVICE')) {
        suggestions.push({
          category: 'GENERATOR_SERVICE',
          label: 'Generator Maintenance',
          description: 'Annual generator service and testing',
          estimatedAmount: { min: 200, max: 500 },
          frequency: 'ANNUAL',
          reason: 'Your property has a backup generator',
          confidence: 0.8,
        });
      }
    }

    // Location-based suggestions
    const state = property?.state?.toUpperCase();
    
    // Northeast = heating oil, snow removal
    if (['CT', 'MA', 'NY', 'NJ', 'NH', 'VT', 'ME', 'RI', 'PA'].includes(state || '')) {
      if (!existingCategories.has('SNOW_REMOVAL')) {
        suggestions.push({
          category: 'SNOW_REMOVAL',
          label: 'Snow Removal',
          description: 'Driveway plowing and walkway clearing',
          estimatedAmount: { min: 50, max: 200 },
          frequency: 'PER_EVENT',
          reason: 'Common service in the Northeast',
          confidence: 0.7,
        });
      }

      if (enrichment?.heatingFuel === 'OIL' && !existingCategories.has('HEATING_OIL')) {
        suggestions.push({
          category: 'HEATING_OIL',
          label: 'Heating Oil Delivery',
          description: 'Oil tank refills during heating season',
          estimatedAmount: { min: 400, max: 800 },
          frequency: 'MONTHLY',
          reason: 'Your home uses oil heat',
          confidence: 0.85,
        });
      }
    }

    // Common bills everyone might have
    const commonBills = [
      {
        category: 'HOA',
        label: 'HOA Dues',
        description: 'Homeowners association fees',
        frequency: 'MONTHLY',
        confidence: 0.5,
      },
      {
        category: 'PEST_CONTROL',
        label: 'Pest Control',
        description: 'Quarterly pest prevention treatment',
        frequency: 'QUARTERLY',
        confidence: 0.5,
      },
      {
        category: 'HOME_WARRANTY',
        label: 'Home Warranty',
        description: 'Appliance and system coverage plan',
        frequency: 'ANNUAL',
        confidence: 0.4,
      },
      {
        category: 'TRASH',
        label: 'Trash/Recycling',
        description: 'Private waste removal service',
        frequency: 'MONTHLY',
        confidence: 0.5,
      },
      {
        category: 'ALARM_MONITORING',
        label: 'Security Monitoring',
        description: 'Home security system monitoring',
        frequency: 'MONTHLY',
        confidence: 0.5,
      },
    ];

    for (const bill of commonBills) {
      if (!existingCategories.has(bill.category)) {
        suggestions.push({
          ...bill,
          reason: 'Common household expense',
          estimatedAmount: undefined,
        });
      }
    }

    // Sort by confidence
    return suggestions.sort((a, b) => b.confidence - a.confidence);
  }

  /**
   * Use AI to suggest bills based on property profile (enhanced)
   */
  async getAISuggestedBills(householdId: string): Promise<BillSuggestion[]> {
    if (!this.anthropic) {
      return this.getSuggestedBills(householdId);
    }

    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      include: {
        properties: { include: { enrichmentData: true } },
        detectedBills: { select: { category: true, merchantName: true } },
      },
    });

    if (!household) return [];

    const property = household.properties?.[0];
    const enrichment = property?.enrichmentData;
    const existingBills = household.detectedBills || [];

    // Build context for AI
    const propertyContext = {
      address: property ? `${property.city}, ${property.state}` : 'Unknown',
      sqft: enrichment?.squareFootage,
      bedrooms: enrichment?.bedrooms,
      bathrooms: enrichment?.bathrooms,
      lotSize: enrichment?.lotSizeAcres,
      yearBuilt: enrichment?.yearBuilt,
      hasPool: enrichment?.hasPool,
      hasFireplace: enrichment?.fireplaceCount > 0,
      heatingType: enrichment?.heatingType,
      heatingFuel: enrichment?.heatingFuel,
      hasGenerator: enrichment?.hasGenerator,
      sewerType: enrichment?.sewerType,
    };

    const existingBillsList = existingBills.map((b) => b.merchantName).join(', ');

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-3-haiku-20240307',
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: `You are a home management expert. Based on this property profile, suggest bills the homeowner might be missing.

Property:
${JSON.stringify(propertyContext, null, 2)}

Bills already detected:
${existingBillsList || 'None'}

Respond with a JSON array of suggested bills. Each should have:
- category: string (e.g., "POOL_SERVICE", "LANDSCAPING", "PEST_CONTROL")
- label: string (human readable name)
- description: string (brief description)
- estimatedAmount: { min: number, max: number } (monthly estimate in USD)
- frequency: string ("MONTHLY", "QUARTERLY", "ANNUAL")
- reason: string (why you're suggesting this based on the property)
- confidence: number (0-1, how likely they need this)

Only suggest bills that make sense for this specific property. Return JSON only, no other text.`,
          },
        ],
      });

      const content = response.content[0];
      if (content.type === 'text') {
        const suggestions = JSON.parse(content.text);
        return Array.isArray(suggestions) ? suggestions : [];
      }
    } catch (error) {
      this.logger.warn('AI suggestions failed, falling back to rules:', error);
    }

    // Fallback to rule-based
    return this.getSuggestedBills(householdId);
  }
}
```

### Task 1.2: Create API Endpoint

Add to bills controller:

```typescript
@Get('household/:householdId/suggestions')
@UseGuards(FirebaseAuthGuard)
async getBillSuggestions(@Param('householdId') householdId: string) {
  return this.billSuggestionsService.getSuggestedBills(householdId);
}

@Get('household/:householdId/suggestions/ai')
@UseGuards(FirebaseAuthGuard)
async getAISuggestions(@Param('householdId') householdId: string) {
  return this.billSuggestionsService.getAISuggestedBills(householdId);
}
```

### Task 1.3: Create Frontend UI

Add to `apps/web/src/app/app/money/bills/page.tsx`:

```typescript
import { HelpCircle, Plus, Sparkles, Home, Droplets, TreePine } from 'lucide-react';

interface BillSuggestion {
  category: string;
  label: string;
  description: string;
  estimatedAmount?: { min: number; max: number };
  frequency: string;
  reason: string;
  confidence: number;
}

// Add state
const [suggestions, setSuggestions] = useState<BillSuggestion[]>([]);
const [loadingSuggestions, setLoadingSuggestions] = useState(false);
const [showAddModal, setShowAddModal] = useState(false);
const [selectedSuggestion, setSelectedSuggestion] = useState<BillSuggestion | null>(null);

// Load suggestions
const loadSuggestions = useCallback(async () => {
  if (!householdId) return;
  try {
    setLoadingSuggestions(true);
    const token = await getIdToken();
    const response = await fetch(
      `${apiUrl}/bills/household/${householdId}/suggestions`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    if (response.ok) {
      const data = await response.json();
      setSuggestions(data.slice(0, 6)); // Show top 6
    }
  } catch (error) {
    console.error('Failed to load suggestions:', error);
  } finally {
    setLoadingSuggestions(false);
  }
}, [householdId]);

useEffect(() => {
  loadSuggestions();
}, [loadSuggestions]);

// Get icon for suggestion category
const getSuggestionIcon = (category: string) => {
  switch (category) {
    case 'POOL_SERVICE': return <Droplets className="w-5 h-5" />;
    case 'LANDSCAPING': return <TreePine className="w-5 h-5" />;
    case 'SNOW_REMOVAL': return <Snowflake className="w-5 h-5" />;
    default: return <Home className="w-5 h-5" />;
  }
};

// Handle clicking a suggestion
const handleSuggestionClick = (suggestion: BillSuggestion) => {
  setSelectedSuggestion(suggestion);
  setShowAddModal(true);
};
```

```tsx
{/* Suggestions Section */}
{suggestions.length > 0 && (
  <div className="bg-gradient-to-br from-blue-50 to-indigo-50 rounded-xl border border-blue-200 p-6">
    <div className="flex items-center gap-3 mb-4">
      <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
        <Sparkles className="w-5 h-5 text-blue-600" />
      </div>
      <div>
        <h3 className="font-semibold text-gray-900">Anything we're missing?</h3>
        <p className="text-sm text-gray-600">
          Based on your property, you might also have these bills
        </p>
      </div>
    </div>

    <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
      {suggestions.map((suggestion) => (
        <button
          key={suggestion.category}
          onClick={() => handleSuggestionClick(suggestion)}
          className="p-4 bg-white rounded-xl border border-gray-200 hover:border-blue-300 hover:shadow-md text-left transition group"
        >
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 bg-gray-100 group-hover:bg-blue-100 rounded-lg flex items-center justify-center text-gray-600 group-hover:text-blue-600 transition">
              {getSuggestionIcon(suggestion.category)}
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-medium text-gray-900">{suggestion.label}</p>
              <p className="text-xs text-gray-500 truncate">{suggestion.reason}</p>
              {suggestion.estimatedAmount && (
                <p className="text-xs text-blue-600 mt-1">
                  ~${suggestion.estimatedAmount.min}-${suggestion.estimatedAmount.max}/{suggestion.frequency.toLowerCase()}
                </p>
              )}
            </div>
          </div>
        </button>
      ))}
    </div>

    <button
      onClick={() => {
        setSelectedSuggestion(null);
        setShowAddModal(true);
      }}
      className="mt-4 w-full p-3 bg-white border-2 border-dashed border-gray-300 rounded-xl hover:border-blue-400 text-gray-600 hover:text-blue-600 transition flex items-center justify-center gap-2"
    >
      <Plus className="w-4 h-4" />
      Add a different bill
    </button>
  </div>
)}
```

---

## PHASE 2: Smart Merchant Categorization

### Task 2.1: Create Merchant Intelligence Service

Create `apps/api/src/plaid/merchant-intelligence.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';

interface MerchantInfo {
  normalizedName: string;
  category: string;
  isRecurring: boolean;
  confidence: number;
}

// Known merchant mappings (rule-based, fast)
const MERCHANT_MAPPINGS: Record<string, MerchantInfo> = {
  // Utilities
  'evrsc': { normalizedName: 'Eversource', category: 'UTILITIES_ELECTRIC', isRecurring: true, confidence: 0.95 },
  'eversource': { normalizedName: 'Eversource', category: 'UTILITIES_ELECTRIC', isRecurring: true, confidence: 0.98 },
  'coned': { normalizedName: 'Con Edison', category: 'UTILITIES_ELECTRIC', isRecurring: true, confidence: 0.95 },
  'conedison': { normalizedName: 'Con Edison', category: 'UTILITIES_ELECTRIC', isRecurring: true, confidence: 0.98 },
  'pseg': { normalizedName: 'PSE&G', category: 'UTILITIES_ELECTRIC', isRecurring: true, confidence: 0.95 },
  'nationalgrid': { normalizedName: 'National Grid', category: 'UTILITIES_GAS', isRecurring: true, confidence: 0.95 },
  'aquarion': { normalizedName: 'Aquarion Water', category: 'UTILITIES_WATER', isRecurring: true, confidence: 0.95 },
  
  // Telecom
  'vzw': { normalizedName: 'Verizon Wireless', category: 'PHONE', isRecurring: true, confidence: 0.95 },
  'verizon': { normalizedName: 'Verizon', category: 'PHONE', isRecurring: true, confidence: 0.90 },
  'att': { normalizedName: 'AT&T', category: 'PHONE', isRecurring: true, confidence: 0.90 },
  'tmobile': { normalizedName: 'T-Mobile', category: 'PHONE', isRecurring: true, confidence: 0.95 },
  'comcast': { normalizedName: 'Comcast/Xfinity', category: 'INTERNET', isRecurring: true, confidence: 0.95 },
  'xfinity': { normalizedName: 'Xfinity', category: 'INTERNET', isRecurring: true, confidence: 0.95 },
  'spectrum': { normalizedName: 'Spectrum', category: 'INTERNET', isRecurring: true, confidence: 0.95 },
  'optimum': { normalizedName: 'Optimum', category: 'INTERNET', isRecurring: true, confidence: 0.95 },
  'fios': { normalizedName: 'Verizon Fios', category: 'INTERNET', isRecurring: true, confidence: 0.95 },
  
  // Streaming
  'netflix': { normalizedName: 'Netflix', category: 'STREAMING', isRecurring: true, confidence: 0.99 },
  'spotify': { normalizedName: 'Spotify', category: 'STREAMING', isRecurring: true, confidence: 0.99 },
  'hulu': { normalizedName: 'Hulu', category: 'STREAMING', isRecurring: true, confidence: 0.99 },
  'disneyplus': { normalizedName: 'Disney+', category: 'STREAMING', isRecurring: true, confidence: 0.99 },
  'disney+': { normalizedName: 'Disney+', category: 'STREAMING', isRecurring: true, confidence: 0.99 },
  'hbomax': { normalizedName: 'HBO Max', category: 'STREAMING', isRecurring: true, confidence: 0.99 },
  'max': { normalizedName: 'Max (HBO)', category: 'STREAMING', isRecurring: true, confidence: 0.85 },
  'amazonprime': { normalizedName: 'Amazon Prime', category: 'SUBSCRIPTION', isRecurring: true, confidence: 0.90 },
  'appletv': { normalizedName: 'Apple TV+', category: 'STREAMING', isRecurring: true, confidence: 0.95 },
  'peacock': { normalizedName: 'Peacock', category: 'STREAMING', isRecurring: true, confidence: 0.95 },
  'paramount': { normalizedName: 'Paramount+', category: 'STREAMING', isRecurring: true, confidence: 0.90 },
  
  // Insurance
  'geico': { normalizedName: 'GEICO', category: 'INSURANCE_AUTO', isRecurring: true, confidence: 0.95 },
  'statefarm': { normalizedName: 'State Farm', category: 'INSURANCE_AUTO', isRecurring: true, confidence: 0.90 },
  'allstate': { normalizedName: 'Allstate', category: 'INSURANCE_AUTO', isRecurring: true, confidence: 0.90 },
  'progressive': { normalizedName: 'Progressive', category: 'INSURANCE_AUTO', isRecurring: true, confidence: 0.90 },
  'liberty': { normalizedName: 'Liberty Mutual', category: 'INSURANCE_HOME', isRecurring: true, confidence: 0.85 },
  'chubb': { normalizedName: 'Chubb Insurance', category: 'INSURANCE_HOME', isRecurring: true, confidence: 0.90 },
  'travelers': { normalizedName: 'Travelers', category: 'INSURANCE_HOME', isRecurring: true, confidence: 0.85 },
  
  // Gyms
  'planetfitness': { normalizedName: 'Planet Fitness', category: 'GYM', isRecurring: true, confidence: 0.95 },
  'equinox': { normalizedName: 'Equinox', category: 'GYM', isRecurring: true, confidence: 0.95 },
  'lifetime': { normalizedName: 'Lifetime Fitness', category: 'GYM', isRecurring: true, confidence: 0.90 },
  'orangetheory': { normalizedName: 'Orangetheory', category: 'GYM', isRecurring: true, confidence: 0.95 },
  'ymca': { normalizedName: 'YMCA', category: 'GYM', isRecurring: true, confidence: 0.90 },
  
  // Security
  'adt': { normalizedName: 'ADT Security', category: 'SECURITY', isRecurring: true, confidence: 0.95 },
  'simplisafe': { normalizedName: 'SimpliSafe', category: 'SECURITY', isRecurring: true, confidence: 0.95 },
  'ring': { normalizedName: 'Ring', category: 'SECURITY', isRecurring: true, confidence: 0.85 },
  'vivint': { normalizedName: 'Vivint', category: 'SECURITY', isRecurring: true, confidence: 0.95 },
  
  // Ambiguous - needs context
  'amazon': { normalizedName: 'Amazon', category: 'OTHER', isRecurring: false, confidence: 0.5 },
  'amzn': { normalizedName: 'Amazon', category: 'OTHER', isRecurring: false, confidence: 0.5 },
  'apple': { normalizedName: 'Apple', category: 'OTHER', isRecurring: false, confidence: 0.5 },
};

@Injectable()
export class MerchantIntelligenceService {
  private readonly logger = new Logger(MerchantIntelligenceService.name);
  private anthropic: Anthropic | null = null;

  constructor() {
    if (process.env.ANTHROPIC_API_KEY) {
      this.anthropic = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY,
      });
    }
  }

  /**
   * Normalize and categorize a merchant name (fast, rule-based)
   */
  identifyMerchant(rawName: string): MerchantInfo | null {
    const normalized = rawName.toLowerCase().replace(/[^a-z0-9]/g, '');
    
    // Check exact matches first
    if (MERCHANT_MAPPINGS[normalized]) {
      return MERCHANT_MAPPINGS[normalized];
    }

    // Check partial matches
    for (const [key, info] of Object.entries(MERCHANT_MAPPINGS)) {
      if (normalized.includes(key) || key.includes(normalized)) {
        return info;
      }
    }

    return null;
  }

  /**
   * Use AI to identify ambiguous merchants
   */
  async identifyMerchantWithAI(
    rawName: string,
    amount: number,
    frequency: number // days between transactions
  ): Promise<MerchantInfo> {
    // Try rules first
    const ruleResult = this.identifyMerchant(rawName);
    if (ruleResult && ruleResult.confidence > 0.8) {
      return ruleResult;
    }

    // Use AI for ambiguous cases
    if (!this.anthropic) {
      return {
        normalizedName: rawName,
        category: 'OTHER',
        isRecurring: frequency > 0 && frequency <= 35,
        confidence: 0.5,
      };
    }

    try {
      const response = await this.anthropic.messages.create({
        model: 'claude-3-haiku-20240307',
        max_tokens: 256,
        messages: [
          {
            role: 'user',
            content: `Identify this merchant from a bank transaction:

Merchant name: "${rawName}"
Amount: $${amount}
Transaction frequency: every ${frequency} days

Respond with JSON only:
{
  "normalizedName": "Human readable merchant name",
  "category": "One of: MORTGAGE, RENT, UTILITIES_ELECTRIC, UTILITIES_GAS, UTILITIES_WATER, INTERNET, PHONE, CABLE, INSURANCE_HOME, INSURANCE_AUTO, SUBSCRIPTION, STREAMING, GYM, CHILDCARE, TUITION, LANDSCAPING, HOUSEKEEPING, POOL_SERVICE, SECURITY, LOAN, CREDIT_CARD, HOA, OTHER",
  "isRecurring": true/false,
  "confidence": 0.0-1.0
}`,
          },
        ],
      });

      const content = response.content[0];
      if (content.type === 'text') {
        return JSON.parse(content.text);
      }
    } catch (error) {
      this.logger.warn('AI merchant identification failed:', error);
    }

    // Fallback
    return {
      normalizedName: rawName,
      category: ruleResult?.category || 'OTHER',
      isRecurring: frequency > 0 && frequency <= 35,
      confidence: 0.5,
    };
  }

  /**
   * Determine if an Amazon transaction is a subscription
   */
  async isAmazonSubscription(
    rawName: string,
    amount: number,
    transactionCount: number,
    amountVariance: number
  ): Promise<{ isSubscription: boolean; subscriptionType: string | null }> {
    // Known Amazon subscription amounts
    const AMAZON_SUBSCRIPTIONS: Record<number, string> = {
      14.99: 'Amazon Prime Monthly',
      139: 'Amazon Prime Annual',
      9.99: 'Amazon Music/Audible',
      4.99: 'Amazon Kids+',
      2.99: 'Amazon Photos',
    };

    // Check if amount matches known subscription
    const roundedAmount = Math.round(amount * 100) / 100;
    if (AMAZON_SUBSCRIPTIONS[roundedAmount] && amountVariance < 0.01) {
      return {
        isSubscription: true,
        subscriptionType: AMAZON_SUBSCRIPTIONS[roundedAmount],
      };
    }

    // Low variance + recurring = likely subscription
    if (amountVariance < amount * 0.05 && transactionCount >= 3) {
      return {
        isSubscription: true,
        subscriptionType: 'Amazon Subscription',
      };
    }

    return { isSubscription: false, subscriptionType: null };
  }
}
```

### Task 2.2: Integrate into Plaid Service

Update `apps/api/src/plaid/plaid.service.ts` to use MerchantIntelligenceService:

```typescript
constructor(
  private prisma: PrismaService,
  private merchantIntelligence: MerchantIntelligenceService,
) {
  // ... existing constructor
}

// In analyzeTransactions method, use smart identification:
private async analyzeTransactions(transactions: any[], householdId: string, accounts: any[]) {
  // ... existing grouping logic ...

  for (const [normalizedName, txs] of merchantGroups) {
    // Use smart merchant identification
    const merchantInfo = await this.merchantIntelligence.identifyMerchantWithAI(
      txs[0].merchant_name || txs[0].name,
      avgAmount,
      avgGap
    );

    detected.push({
      // ...
      merchantName: merchantInfo.normalizedName,
      category: merchantInfo.category,
      confidence: merchantInfo.confidence,
      // ...
    });
  }
}
```

---

## PHASE 3: Document Bill Extraction

### Task 3.1: Create Bill Extraction Service

Create `apps/api/src/document/bill-extraction.service.ts`:

```typescript
import { Injectable, Logger } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';
import * as pdf from 'pdf-parse';

interface ExtractedBill {
  vendorName: string;
  category: string;
  amount: number;
  dueDate: string | null;
  accountNumber: string | null;
  frequency: string;
  confidence: number;
}

@Injectable()
export class BillExtractionService {
  private readonly logger = new Logger(BillExtractionService.name);
  private anthropic: Anthropic | null = null;

  constructor() {
    if (process.env.ANTHROPIC_API_KEY) {
      this.anthropic = new Anthropic({
        apiKey: process.env.ANTHROPIC_API_KEY,
      });
    }
  }

  /**
   * Extract bill information from an uploaded document
   */
  async extractBillFromDocument(
    fileBuffer: Buffer,
    mimeType: string,
    fileName: string
  ): Promise<ExtractedBill | null> {
    if (!this.anthropic) {
      this.logger.warn('Anthropic not configured, skipping bill extraction');
      return null;
    }

    let textContent = '';

    // Extract text from PDF
    if (mimeType === 'application/pdf') {
      try {
        const pdfData = await pdf(fileBuffer);
        textContent = pdfData.text;
      } catch (error) {
        this.logger.error('PDF parsing failed:', error);
        return null;
      }
    }

    // For images, use Claude's vision
    if (mimeType.startsWith('image/')) {
      try {
        const base64 = fileBuffer.toString('base64');
        const response = await this.anthropic.messages.create({
          model: 'claude-3-haiku-20240307',
          max_tokens: 1024,
          messages: [
            {
              role: 'user',
              content: [
                {
                  type: 'image',
                  source: {
                    type: 'base64',
                    media_type: mimeType as 'image/jpeg' | 'image/png' | 'image/gif' | 'image/webp',
                    data: base64,
                  },
                },
                {
                  type: 'text',
                  text: `This is an image of a bill or invoice. Extract the following information and respond with JSON only:
{
  "vendorName": "Name of the company/service provider",
  "category": "One of: UTILITIES_ELECTRIC, UTILITIES_GAS, UTILITIES_WATER, INTERNET, PHONE, INSURANCE_HOME, INSURANCE_AUTO, SUBSCRIPTION, OTHER",
  "amount": 123.45 (number, the amount due),
  "dueDate": "2024-01-15" (ISO date string or null),
  "accountNumber": "Account number if visible" (string or null),
  "frequency": "MONTHLY, QUARTERLY, or ANNUAL",
  "confidence": 0.0-1.0 (how confident you are in this extraction)
}

If this doesn't appear to be a bill, respond with null.`,
                },
              ],
            },
          ],
        });

        const content = response.content[0];
        if (content.type === 'text') {
          const result = JSON.parse(content.text);
          return result;
        }
      } catch (error) {
        this.logger.error('Image bill extraction failed:', error);
        return null;
      }
    }

    // For text-based PDFs
    if (textContent) {
      try {
        const response = await this.anthropic.messages.create({
          model: 'claude-3-haiku-20240307',
          max_tokens: 1024,
          messages: [
            {
              role: 'user',
              content: `Extract bill information from this document text:

---
${textContent.slice(0, 4000)}
---

Respond with JSON only:
{
  "vendorName": "Name of the company/service provider",
  "category": "One of: UTILITIES_ELECTRIC, UTILITIES_GAS, UTILITIES_WATER, INTERNET, PHONE, INSURANCE_HOME, INSURANCE_AUTO, SUBSCRIPTION, OTHER",
  "amount": 123.45,
  "dueDate": "2024-01-15" or null,
  "accountNumber": "Account number" or null,
  "frequency": "MONTHLY, QUARTERLY, or ANNUAL",
  "confidence": 0.0-1.0
}

If this doesn't appear to be a bill, respond with null.`,
            },
          ],
        });

        const content = response.content[0];
        if (content.type === 'text') {
          return JSON.parse(content.text);
        }
      } catch (error) {
        this.logger.error('PDF bill extraction failed:', error);
      }
    }

    return null;
  }

  /**
   * Process uploaded document and optionally create a bill
   */
  async processDocumentForBills(
    documentId: string,
    householdId: string,
    fileBuffer: Buffer,
    mimeType: string,
    fileName: string
  ): Promise<{ extracted: boolean; bill: ExtractedBill | null }> {
    const extracted = await this.extractBillFromDocument(fileBuffer, mimeType, fileName);

    if (extracted && extracted.confidence > 0.7) {
      // Could automatically create a bill or prompt user
      return { extracted: true, bill: extracted };
    }

    return { extracted: false, bill: null };
  }
}
```

### Task 3.2: Add to Document Upload Flow

Update document upload to optionally extract bill info:

```typescript
// In document.controller.ts
@Post('household/:householdId/upload')
async uploadDocument(
  @Param('householdId') householdId: string,
  @UploadedFile() file: Express.Multer.File,
  @Body() dto: UploadDocumentDto,
) {
  const document = await this.documentService.upload(householdId, file, dto);

  // Try to extract bill info
  if (dto.extractBillInfo) {
    const extraction = await this.billExtractionService.processDocumentForBills(
      document.id,
      householdId,
      file.buffer,
      file.mimetype,
      file.originalname
    );

    return { document, billExtraction: extraction };
  }

  return { document };
}
```

---

## PHASE 4: Add Anthropic API Key

### Task 4.1: Add Environment Variable

Add to `apps/api/.env`:

```env
ANTHROPIC_API_KEY=your-anthropic-api-key
```

Add to Cloud Run:

```bash
gcloud run services update haven-api \
  --region=us-east1 \
  --update-env-vars="ANTHROPIC_API_KEY=your-key" \
  --project=home-manager-480616
```

### Task 4.2: Install Anthropic SDK

```bash
cd apps/api
pnpm add @anthropic-ai/sdk pdf-parse
pnpm add -D @types/pdf-parse
```

---

## PHASE 5: Manual Bill Entry Modal

### Task 5.1: Create Add Bill Modal Component

```tsx
// In bills/page.tsx or separate component

interface ManualBillForm {
  name: string;
  category: string;
  amount: string;
  frequency: string;
  dueDay: string;
  notes: string;
}

const [showAddModal, setShowAddModal] = useState(false);
const [manualBill, setManualBill] = useState<ManualBillForm>({
  name: selectedSuggestion?.label || '',
  category: selectedSuggestion?.category || 'OTHER',
  amount: selectedSuggestion?.estimatedAmount 
    ? String(Math.round((selectedSuggestion.estimatedAmount.min + selectedSuggestion.estimatedAmount.max) / 2))
    : '',
  frequency: selectedSuggestion?.frequency || 'MONTHLY',
  dueDay: '',
  notes: '',
});

const handleAddManualBill = async () => {
  try {
    const token = await getIdToken();
    const response = await fetch(`${apiUrl}/bills/household/${householdId}/manual`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        name: manualBill.name,
        category: manualBill.category,
        amount: parseFloat(manualBill.amount),
        frequency: manualBill.frequency,
        dueDay: manualBill.dueDay ? parseInt(manualBill.dueDay) : null,
        notes: manualBill.notes,
      }),
    });

    if (response.ok) {
      setShowAddModal(false);
      loadBills();
    }
  } catch (error) {
    console.error('Failed to add bill:', error);
  }
};
```

```tsx
{/* Add Bill Modal */}
{showAddModal && (
  <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
    <div className="bg-white rounded-xl w-full max-w-md">
      <div className="flex items-center justify-between p-4 border-b">
        <h2 className="text-lg font-semibold">Add Bill</h2>
        <button onClick={() => setShowAddModal(false)} className="p-1 hover:bg-gray-100 rounded">
          <X className="w-5 h-5" />
        </button>
      </div>

      <div className="p-4 space-y-4">
        {/* Name */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Bill Name</label>
          <input
            type="text"
            value={manualBill.name}
            onChange={(e) => setManualBill({ ...manualBill, name: e.target.value })}
            className="w-full px-3 py-2 border rounded-lg"
            placeholder="e.g., Pool Service"
          />
        </div>

        {/* Category */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Category</label>
          <select
            value={manualBill.category}
            onChange={(e) => setManualBill({ ...manualBill, category: e.target.value })}
            className="w-full px-3 py-2 border rounded-lg"
          >
            <option value="HOA">HOA Dues</option>
            <option value="LANDSCAPING">Landscaping</option>
            <option value="POOL_SERVICE">Pool Service</option>
            <option value="HOUSEKEEPING">Housekeeping</option>
            <option value="PEST_CONTROL">Pest Control</option>
            <option value="SECURITY">Security</option>
            <option value="UTILITIES_ELECTRIC">Electric</option>
            <option value="UTILITIES_GAS">Gas</option>
            <option value="UTILITIES_WATER">Water</option>
            <option value="INTERNET">Internet</option>
            <option value="PHONE">Phone</option>
            <option value="INSURANCE_HOME">Home Insurance</option>
            <option value="SUBSCRIPTION">Subscription</option>
            <option value="OTHER">Other</option>
          </select>
        </div>

        {/* Amount & Frequency */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Amount</label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500">$</span>
              <input
                type="number"
                value={manualBill.amount}
                onChange={(e) => setManualBill({ ...manualBill, amount: e.target.value })}
                className="w-full pl-7 pr-3 py-2 border rounded-lg"
                placeholder="0.00"
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Frequency</label>
            <select
              value={manualBill.frequency}
              onChange={(e) => setManualBill({ ...manualBill, frequency: e.target.value })}
              className="w-full px-3 py-2 border rounded-lg"
            >
              <option value="WEEKLY">Weekly</option>
              <option value="BIWEEKLY">Every 2 weeks</option>
              <option value="MONTHLY">Monthly</option>
              <option value="QUARTERLY">Quarterly</option>
              <option value="ANNUAL">Annual</option>
            </select>
          </div>
        </div>

        {/* Due Day */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Due Day (optional)</label>
          <input
            type="number"
            min="1"
            max="31"
            value={manualBill.dueDay}
            onChange={(e) => setManualBill({ ...manualBill, dueDay: e.target.value })}
            className="w-full px-3 py-2 border rounded-lg"
            placeholder="Day of month (1-31)"
          />
        </div>

        {/* Notes */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">Notes (optional)</label>
          <textarea
            value={manualBill.notes}
            onChange={(e) => setManualBill({ ...manualBill, notes: e.target.value })}
            className="w-full px-3 py-2 border rounded-lg"
            rows={2}
            placeholder="Any additional details"
          />
        </div>
      </div>

      <div className="flex gap-3 p-4 border-t">
        <button
          onClick={() => setShowAddModal(false)}
          className="flex-1 px-4 py-2 border rounded-lg hover:bg-gray-50"
        >
          Cancel
        </button>
        <button
          onClick={handleAddManualBill}
          disabled={!manualBill.name || !manualBill.amount}
          className="flex-1 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50"
        >
          Add Bill
        </button>
      </div>
    </div>
  </div>
)}
```

---

## PHASE 6: Deploy & Test

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Install dependencies
cd apps/api
pnpm add @anthropic-ai/sdk pdf-parse
pnpm add -D @types/pdf-parse

# Build
cd ../..
pnpm build

# Deploy
git add .
git commit -m "feat: AI-powered bill intelligence and missing bills feature"
git push origin main

gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
gcloud builds submit --config=cloudbuild-web.yaml --project=home-manager-480616

# Add Anthropic key to production
gcloud run services update haven-api \
  --region=us-east1 \
  --update-env-vars="ANTHROPIC_API_KEY=your-key" \
  --project=home-manager-480616

pnpm test:e2e
```

---

## Summary

After this prompt:

| Feature | Description |
|---------|-------------|
| **"Anything We're Missing?"** | Property-aware bill suggestions |
| **Smart Categorization** | 100+ merchant mappings + AI fallback |
| **Merchant Matching** | "EVRSC" → "Eversource Electric" |
| **Document Extraction** | Upload bill → auto-extract details |
| **Manual Bill Entry** | Add bills not detected by Plaid |

**AI is used for:**
1. Ambiguous merchant categorization
2. Property-based bill suggestions
3. Bill extraction from uploaded documents

**AI is NOT used for:**
- Basic pattern detection (rule-based)
- Known merchant matching (lookup table)
- Frequency calculation (math)

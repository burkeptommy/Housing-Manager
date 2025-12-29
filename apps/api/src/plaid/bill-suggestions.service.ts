import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import Anthropic from '@anthropic-ai/sdk';

interface BillSuggestion {
  category: string;
  label: string;
  description: string;
  estimatedAmount?: { min: number; max: number };
  frequency: string;
  reason: string;
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
        homeProfile: true,
        detectedBills: true,
      },
    });

    if (!household) return [];

    const homeProfile = household.homeProfile;
    const existingBills = household.detectedBills || [];
    const existingCategories = new Set(existingBills.map((b) => b.category as string));

    // Rule-based suggestions
    const suggestions: BillSuggestion[] = [];

    // Parse notes JSON for property features
    let propertyFeatures: Record<string, unknown> = {};
    if (homeProfile?.notes) {
      try {
        propertyFeatures =
          typeof homeProfile.notes === 'string'
            ? JSON.parse(homeProfile.notes)
            : homeProfile.notes;
      } catch {
        // Ignore parse errors
      }
    }

    const systems = (propertyFeatures as { systems?: Record<string, unknown> })?.systems || {};

    // Property-based suggestions
    if (systems) {
      // Pool
      if (systems.hasPool && !existingCategories.has('POOL_SERVICE')) {
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
      if (
        systems.septicOrSewer === 'septic' &&
        !existingCategories.has('OTHER_BILL')
      ) {
        suggestions.push({
          category: 'OTHER_BILL',
          label: 'Septic Pumping',
          description: 'Septic tank pumping and inspection',
          estimatedAmount: { min: 300, max: 600 },
          frequency: 'ANNUAL',
          reason: 'Your property has a septic system',
          confidence: 0.85,
        });
      }

      // Generator
      if (systems.hasGenerator && !existingCategories.has('OTHER_BILL')) {
        suggestions.push({
          category: 'OTHER_BILL',
          label: 'Generator Maintenance',
          description: 'Annual generator service and testing',
          estimatedAmount: { min: 200, max: 500 },
          frequency: 'ANNUAL',
          reason: 'Your property has a backup generator',
          confidence: 0.8,
        });
      }

      // Fireplace = chimney sweep
      if (systems.hasFireplace && !existingCategories.has('OTHER_BILL')) {
        suggestions.push({
          category: 'OTHER_BILL',
          label: 'Chimney Sweep',
          description: 'Annual chimney cleaning and inspection',
          estimatedAmount: { min: 150, max: 400 },
          frequency: 'ANNUAL',
          reason: 'Your home has a fireplace',
          confidence: 0.75,
        });
      }
    }

    // Large lot = landscaping
    if (
      homeProfile?.lotSize &&
      homeProfile.lotSize > 0.5 &&
      !existingCategories.has('LAWN_LANDSCAPE')
    ) {
      suggestions.push({
        category: 'LAWN_LANDSCAPE',
        label: 'Landscaping Service',
        description: 'Lawn maintenance, mowing, seasonal cleanup',
        estimatedAmount: { min: 300, max: 1500 },
        frequency: 'MONTHLY',
        reason: `Your property is ${homeProfile.lotSize.toFixed(1)} acres`,
        confidence: 0.8,
      });
    }

    // Location-based suggestions
    const state = homeProfile?.state?.toUpperCase();

    // Northeast = snow removal
    if (
      ['CT', 'MA', 'NY', 'NJ', 'NH', 'VT', 'ME', 'RI', 'PA'].includes(
        state || '',
      )
    ) {
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
        category: 'OTHER_BILL',
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
        category: 'SECURITY_MONITORING',
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
        homeProfile: true,
        detectedBills: { select: { category: true, merchantName: true } },
      },
    });

    if (!household) return [];

    const homeProfile = household.homeProfile;
    const existingBills = household.detectedBills || [];

    // Parse notes JSON for property features
    let propertyFeatures: Record<string, unknown> = {};
    if (homeProfile?.notes) {
      try {
        propertyFeatures =
          typeof homeProfile.notes === 'string'
            ? JSON.parse(homeProfile.notes)
            : homeProfile.notes;
      } catch {
        // Ignore parse errors
      }
    }

    const systems = (propertyFeatures as { systems?: Record<string, unknown> })?.systems || {};

    // Build context for AI
    const propertyContext = {
      address: homeProfile
        ? `${homeProfile.city}, ${homeProfile.state}`
        : 'Unknown',
      sqft: homeProfile?.squareFeet,
      bedrooms: homeProfile?.bedrooms,
      bathrooms: homeProfile?.bathrooms,
      lotSize: homeProfile?.lotSize,
      yearBuilt: homeProfile?.yearBuilt,
      hasPool: systems?.hasPool,
      hasFireplace: systems?.hasFireplace,
      hasGenerator: systems?.hasGenerator,
      septicOrSewer: systems?.septicOrSewer,
    };

    const existingBillsList = existingBills
      .map((b) => b.merchantName)
      .join(', ');

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
- category: string (e.g., "POOL_SERVICE", "LAWN_LANDSCAPE", "PEST_CONTROL")
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

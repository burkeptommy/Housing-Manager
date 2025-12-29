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
  // Utilities - Electric
  evrsc: {
    normalizedName: 'Eversource',
    category: 'ELECTRIC',
    isRecurring: true,
    confidence: 0.95,
  },
  eversource: {
    normalizedName: 'Eversource',
    category: 'ELECTRIC',
    isRecurring: true,
    confidence: 0.98,
  },
  coned: {
    normalizedName: 'Con Edison',
    category: 'ELECTRIC',
    isRecurring: true,
    confidence: 0.95,
  },
  conedison: {
    normalizedName: 'Con Edison',
    category: 'ELECTRIC',
    isRecurring: true,
    confidence: 0.98,
  },
  pseg: {
    normalizedName: 'PSE&G',
    category: 'ELECTRIC',
    isRecurring: true,
    confidence: 0.95,
  },
  pge: {
    normalizedName: 'PG&E',
    category: 'ELECTRIC',
    isRecurring: true,
    confidence: 0.95,
  },
  duke: {
    normalizedName: 'Duke Energy',
    category: 'ELECTRIC',
    isRecurring: true,
    confidence: 0.85,
  },
  dominion: {
    normalizedName: 'Dominion Energy',
    category: 'ELECTRIC',
    isRecurring: true,
    confidence: 0.9,
  },
  // Utilities - Gas
  nationalgrid: {
    normalizedName: 'National Grid',
    category: 'GAS',
    isRecurring: true,
    confidence: 0.95,
  },
  keyspan: {
    normalizedName: 'KeySpan (National Grid)',
    category: 'GAS',
    isRecurring: true,
    confidence: 0.9,
  },
  // Utilities - Water
  aquarion: {
    normalizedName: 'Aquarion Water',
    category: 'WATER_SEWER',
    isRecurring: true,
    confidence: 0.95,
  },
  americanwater: {
    normalizedName: 'American Water',
    category: 'WATER_SEWER',
    isRecurring: true,
    confidence: 0.9,
  },

  // Telecom - Phone
  vzw: {
    normalizedName: 'Verizon Wireless',
    category: 'CELL_PHONE',
    isRecurring: true,
    confidence: 0.95,
  },
  verizonwireless: {
    normalizedName: 'Verizon Wireless',
    category: 'CELL_PHONE',
    isRecurring: true,
    confidence: 0.98,
  },
  verizon: {
    normalizedName: 'Verizon',
    category: 'CELL_PHONE',
    isRecurring: true,
    confidence: 0.9,
  },
  att: {
    normalizedName: 'AT&T',
    category: 'CELL_PHONE',
    isRecurring: true,
    confidence: 0.9,
  },
  tmobile: {
    normalizedName: 'T-Mobile',
    category: 'CELL_PHONE',
    isRecurring: true,
    confidence: 0.95,
  },
  sprint: {
    normalizedName: 'Sprint (T-Mobile)',
    category: 'CELL_PHONE',
    isRecurring: true,
    confidence: 0.9,
  },

  // Internet
  comcast: {
    normalizedName: 'Comcast/Xfinity',
    category: 'INTERNET',
    isRecurring: true,
    confidence: 0.95,
  },
  xfinity: {
    normalizedName: 'Xfinity',
    category: 'INTERNET',
    isRecurring: true,
    confidence: 0.95,
  },
  spectrum: {
    normalizedName: 'Spectrum',
    category: 'INTERNET',
    isRecurring: true,
    confidence: 0.95,
  },
  optimum: {
    normalizedName: 'Optimum',
    category: 'INTERNET',
    isRecurring: true,
    confidence: 0.95,
  },
  fios: {
    normalizedName: 'Verizon Fios',
    category: 'INTERNET',
    isRecurring: true,
    confidence: 0.95,
  },
  cox: {
    normalizedName: 'Cox Communications',
    category: 'INTERNET',
    isRecurring: true,
    confidence: 0.9,
  },
  frontier: {
    normalizedName: 'Frontier',
    category: 'INTERNET',
    isRecurring: true,
    confidence: 0.9,
  },

  // Streaming
  netflix: {
    normalizedName: 'Netflix',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.99,
  },
  spotify: {
    normalizedName: 'Spotify',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.99,
  },
  hulu: {
    normalizedName: 'Hulu',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.99,
  },
  disneyplus: {
    normalizedName: 'Disney+',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.99,
  },
  disney: {
    normalizedName: 'Disney+',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.85,
  },
  hbomax: {
    normalizedName: 'HBO Max',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.99,
  },
  max: {
    normalizedName: 'Max (HBO)',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.85,
  },
  amazonprime: {
    normalizedName: 'Amazon Prime',
    category: 'SOFTWARE_SUBSCRIPTION',
    isRecurring: true,
    confidence: 0.9,
  },
  primevideo: {
    normalizedName: 'Amazon Prime Video',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.95,
  },
  appletv: {
    normalizedName: 'Apple TV+',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.95,
  },
  peacock: {
    normalizedName: 'Peacock',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.95,
  },
  paramount: {
    normalizedName: 'Paramount+',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.9,
  },
  youtube: {
    normalizedName: 'YouTube Premium',
    category: 'STREAMING_SERVICE',
    isRecurring: true,
    confidence: 0.8,
  },

  // Insurance
  geico: {
    normalizedName: 'GEICO',
    category: 'AUTO_INSURANCE',
    isRecurring: true,
    confidence: 0.95,
  },
  statefarm: {
    normalizedName: 'State Farm',
    category: 'AUTO_INSURANCE',
    isRecurring: true,
    confidence: 0.9,
  },
  allstate: {
    normalizedName: 'Allstate',
    category: 'AUTO_INSURANCE',
    isRecurring: true,
    confidence: 0.9,
  },
  progressive: {
    normalizedName: 'Progressive',
    category: 'AUTO_INSURANCE',
    isRecurring: true,
    confidence: 0.9,
  },
  liberty: {
    normalizedName: 'Liberty Mutual',
    category: 'HOME_INSURANCE',
    isRecurring: true,
    confidence: 0.85,
  },
  chubb: {
    normalizedName: 'Chubb Insurance',
    category: 'HOME_INSURANCE',
    isRecurring: true,
    confidence: 0.9,
  },
  travelers: {
    normalizedName: 'Travelers',
    category: 'HOME_INSURANCE',
    isRecurring: true,
    confidence: 0.85,
  },
  aetna: {
    normalizedName: 'Aetna',
    category: 'HEALTH_INSURANCE',
    isRecurring: true,
    confidence: 0.9,
  },
  cigna: {
    normalizedName: 'Cigna',
    category: 'HEALTH_INSURANCE',
    isRecurring: true,
    confidence: 0.9,
  },
  united: {
    normalizedName: 'UnitedHealthcare',
    category: 'HEALTH_INSURANCE',
    isRecurring: true,
    confidence: 0.8,
  },

  // Gyms
  planetfitness: {
    normalizedName: 'Planet Fitness',
    category: 'GYM_FITNESS',
    isRecurring: true,
    confidence: 0.95,
  },
  equinox: {
    normalizedName: 'Equinox',
    category: 'GYM_FITNESS',
    isRecurring: true,
    confidence: 0.95,
  },
  lifetime: {
    normalizedName: 'Lifetime Fitness',
    category: 'GYM_FITNESS',
    isRecurring: true,
    confidence: 0.9,
  },
  orangetheory: {
    normalizedName: 'Orangetheory',
    category: 'GYM_FITNESS',
    isRecurring: true,
    confidence: 0.95,
  },
  ymca: {
    normalizedName: 'YMCA',
    category: 'GYM_FITNESS',
    isRecurring: true,
    confidence: 0.9,
  },
  soulcycle: {
    normalizedName: 'SoulCycle',
    category: 'GYM_FITNESS',
    isRecurring: true,
    confidence: 0.9,
  },
  peloton: {
    normalizedName: 'Peloton',
    category: 'GYM_FITNESS',
    isRecurring: true,
    confidence: 0.95,
  },

  // Security
  adt: {
    normalizedName: 'ADT Security',
    category: 'SECURITY_MONITORING',
    isRecurring: true,
    confidence: 0.95,
  },
  simplisafe: {
    normalizedName: 'SimpliSafe',
    category: 'SECURITY_MONITORING',
    isRecurring: true,
    confidence: 0.95,
  },
  ring: {
    normalizedName: 'Ring',
    category: 'SECURITY_MONITORING',
    isRecurring: true,
    confidence: 0.85,
  },
  vivint: {
    normalizedName: 'Vivint',
    category: 'SECURITY_MONITORING',
    isRecurring: true,
    confidence: 0.95,
  },

  // Mortgage & Loans
  chase: {
    normalizedName: 'Chase',
    category: 'MORTGAGE',
    isRecurring: true,
    confidence: 0.7,
  },
  wellsfargo: {
    normalizedName: 'Wells Fargo',
    category: 'MORTGAGE',
    isRecurring: true,
    confidence: 0.7,
  },
  bankofamerica: {
    normalizedName: 'Bank of America',
    category: 'MORTGAGE',
    isRecurring: true,
    confidence: 0.7,
  },
  quicken: {
    normalizedName: 'Quicken Loans',
    category: 'MORTGAGE',
    isRecurring: true,
    confidence: 0.9,
  },
  rocket: {
    normalizedName: 'Rocket Mortgage',
    category: 'MORTGAGE',
    isRecurring: true,
    confidence: 0.9,
  },

  // Home Services
  trugreen: {
    normalizedName: 'TruGreen',
    category: 'LAWN_LANDSCAPE',
    isRecurring: true,
    confidence: 0.95,
  },
  orkin: {
    normalizedName: 'Orkin',
    category: 'PEST_CONTROL',
    isRecurring: true,
    confidence: 0.95,
  },
  terminix: {
    normalizedName: 'Terminix',
    category: 'PEST_CONTROL',
    isRecurring: true,
    confidence: 0.95,
  },

  // Software/Subscriptions
  dropbox: {
    normalizedName: 'Dropbox',
    category: 'SOFTWARE_SUBSCRIPTION',
    isRecurring: true,
    confidence: 0.95,
  },
  microsoft: {
    normalizedName: 'Microsoft 365',
    category: 'SOFTWARE_SUBSCRIPTION',
    isRecurring: true,
    confidence: 0.85,
  },
  adobe: {
    normalizedName: 'Adobe',
    category: 'SOFTWARE_SUBSCRIPTION',
    isRecurring: true,
    confidence: 0.9,
  },
  zoom: {
    normalizedName: 'Zoom',
    category: 'SOFTWARE_SUBSCRIPTION',
    isRecurring: true,
    confidence: 0.9,
  },
  google: {
    normalizedName: 'Google',
    category: 'SOFTWARE_SUBSCRIPTION',
    isRecurring: true,
    confidence: 0.7,
  },
  icloud: {
    normalizedName: 'Apple iCloud',
    category: 'SOFTWARE_SUBSCRIPTION',
    isRecurring: true,
    confidence: 0.95,
  },

  // Ambiguous - needs context
  amazon: {
    normalizedName: 'Amazon',
    category: 'OTHER_BILL',
    isRecurring: false,
    confidence: 0.5,
  },
  amzn: {
    normalizedName: 'Amazon',
    category: 'OTHER_BILL',
    isRecurring: false,
    confidence: 0.5,
  },
  apple: {
    normalizedName: 'Apple',
    category: 'OTHER_BILL',
    isRecurring: false,
    confidence: 0.5,
  },
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
    frequency: number, // days between transactions
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
        category: 'OTHER_BILL',
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
  "category": "One of: MORTGAGE, RENT, ELECTRIC, GAS, WATER_SEWER, INTERNET, CELL_PHONE, CABLE_TV, HOME_INSURANCE, AUTO_INSURANCE, SOFTWARE_SUBSCRIPTION, STREAMING_SERVICE, GYM_FITNESS, CHILDCARE, SCHOOL_TUITION, LAWN_LANDSCAPE, HOUSE_CLEANING, POOL_SERVICE, SECURITY_MONITORING, PERSONAL_LOAN, CREDIT_CARD, HOA, OTHER_BILL",
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
      category: ruleResult?.category || 'OTHER_BILL',
      isRecurring: frequency > 0 && frequency <= 35,
      confidence: 0.5,
    };
  }

  /**
   * Determine if an Amazon transaction is a subscription
   */
  isAmazonSubscription(
    amount: number,
    transactionCount: number,
    amountVariance: number,
  ): { isSubscription: boolean; subscriptionType: string | null } {
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

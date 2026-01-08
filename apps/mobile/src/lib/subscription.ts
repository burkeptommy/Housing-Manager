// =============================================================================
// SUBSCRIPTION TIER SYSTEM
// =============================================================================
// Haven offers different experiences based on subscription tier:
// - Essentials ($39/mo): AI manager "Alfred" assists users
// - Premium tiers ($349+): Human manager "Sarah Chen" handles everything

export type SubscriptionTier = 'essentials' | 'lite' | 'haven' | 'haven_plus' | 'estate';

export interface TierDetails {
  name: string;
  price: number;
  hasHumanManager: boolean;
  managerName: string;
  managerTitle: string;
  hasIncludedHandyman: boolean;
  handymanPrice?: number;
  handymanHoursIncluded?: number;
}

export const TIER_DETAILS: Record<SubscriptionTier, TierDetails> = {
  essentials: {
    name: 'Essentials',
    price: 39,
    hasHumanManager: false,
    managerName: 'Alfred',
    managerTitle: 'Your AI Home Manager',
    hasIncludedHandyman: false,
    handymanPrice: 50,
  },
  lite: {
    name: 'Lite',
    price: 349,
    hasHumanManager: true,
    managerName: 'Sarah Chen',
    managerTitle: 'Your Home Manager',
    hasIncludedHandyman: false,
    handymanPrice: 50,
  },
  haven: {
    name: 'Haven',
    price: 749,
    hasHumanManager: true,
    managerName: 'Sarah Chen',
    managerTitle: 'Your Home Manager',
    hasIncludedHandyman: true,
    handymanHoursIncluded: 2,
  },
  haven_plus: {
    name: 'Haven+',
    price: 1499,
    hasHumanManager: true,
    managerName: 'Sarah Chen',
    managerTitle: 'Your Home Manager',
    hasIncludedHandyman: true,
    handymanHoursIncluded: 4,
  },
  estate: {
    name: 'Estate',
    price: 3499,
    hasHumanManager: true,
    managerName: 'Sarah Chen',
    managerTitle: 'Your Home Manager',
    hasIncludedHandyman: true,
    handymanHoursIncluded: 8,
  },
};

/**
 * Check if the tier is Essentials (AI-managed)
 */
export function isEssentialsTier(tier: SubscriptionTier): boolean {
  return tier === 'essentials';
}

/**
 * Check if the tier includes a human manager
 */
export function hasHumanManager(tier: SubscriptionTier): boolean {
  return TIER_DETAILS[tier].hasHumanManager;
}

/**
 * Get manager information for the tier
 */
export function getManagerInfo(tier: SubscriptionTier) {
  const details = TIER_DETAILS[tier];
  return {
    name: details.managerName,
    title: details.managerTitle,
    isAI: !details.hasHumanManager,
  };
}

/**
 * Get handyman pricing for the tier
 */
export function getHandymanInfo(tier: SubscriptionTier) {
  const details = TIER_DETAILS[tier];
  return {
    hasIncluded: details.hasIncludedHandyman,
    hoursIncluded: details.handymanHoursIncluded || 0,
    pricePerHour: details.handymanPrice || 50,
  };
}

/**
 * Get upgrade options for the current tier
 */
export function getUpgradeOptions(currentTier: SubscriptionTier): SubscriptionTier[] {
  const tierOrder: SubscriptionTier[] = ['essentials', 'lite', 'haven', 'haven_plus', 'estate'];
  const currentIndex = tierOrder.indexOf(currentTier);
  return tierOrder.slice(currentIndex + 1);
}

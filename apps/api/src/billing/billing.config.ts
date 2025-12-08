import { registerAs } from '@nestjs/config';

import { SubscriptionTier } from './dto';

/**
 * Billing Configuration
 *
 * Maps internal subscription tiers to Stripe price IDs.
 * Update these values with your actual Stripe price IDs.
 *
 * To create prices in Stripe:
 * 1. Go to Products in Stripe Dashboard
 * 2. Create a product for each tier
 * 3. Create a price for each product (monthly/yearly)
 * 4. Copy the price ID (e.g., price_xxx) to this config
 */
export const billingConfig = registerAs('billing', () => ({
  // Stripe API keys (set via environment variables)
  stripeSecretKey: process.env.STRIPE_SECRET_KEY,
  stripeWebhookSecret: process.env.STRIPE_WEBHOOK_SECRET,

  // Map tiers to Stripe price IDs
  // Replace with actual Stripe price IDs from your dashboard
  stripePriceIds: {
    [SubscriptionTier.FREE]: null, // Free tier doesn't need a price ID
    [SubscriptionTier.BASIC]: process.env.STRIPE_PRICE_BASIC || 'price_basic_placeholder',
    [SubscriptionTier.PREMIUM]: process.env.STRIPE_PRICE_PREMIUM || 'price_premium_placeholder',
    [SubscriptionTier.ENTERPRISE]: process.env.STRIPE_PRICE_ENTERPRISE || 'price_enterprise_placeholder',
  },

  // Tier features (for reference)
  tierFeatures: {
    [SubscriptionTier.FREE]: {
      maxHouseholds: 1,
      maxMembers: 2,
      maxServiceRequests: 5,
      hasAnalytics: false,
      hasPrioritySupport: false,
    },
    [SubscriptionTier.BASIC]: {
      maxHouseholds: 2,
      maxMembers: 5,
      maxServiceRequests: 25,
      hasAnalytics: false,
      hasPrioritySupport: false,
    },
    [SubscriptionTier.PREMIUM]: {
      maxHouseholds: 5,
      maxMembers: 15,
      maxServiceRequests: -1, // Unlimited
      hasAnalytics: true,
      hasPrioritySupport: false,
    },
    [SubscriptionTier.ENTERPRISE]: {
      maxHouseholds: -1, // Unlimited
      maxMembers: -1, // Unlimited
      maxServiceRequests: -1, // Unlimited
      hasAnalytics: true,
      hasPrioritySupport: true,
    },
  },
}));

export type BillingConfig = ReturnType<typeof billingConfig>;

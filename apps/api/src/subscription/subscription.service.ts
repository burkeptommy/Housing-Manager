import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

// Client-facing tier names (lowercase)
export type SubscriptionTierClient =
  | 'essentials'
  | 'lite'
  | 'haven'
  | 'haven_plus'
  | 'estate';

// Database tier values (uppercase enum)
export type SubscriptionTierDb =
  | 'ESSENTIALS'
  | 'LITE'
  | 'HAVEN'
  | 'HAVEN_PLUS'
  | 'ESTATE'
  | 'FREE'
  | 'BASIC'
  | 'PREMIUM'
  | 'ENTERPRISE';

export const TIER_CONFIG: Record<
  string,
  { price: number; hasHumanManager: boolean; managerName: string }
> = {
  ESSENTIALS: { price: 39, hasHumanManager: false, managerName: 'Alfred' },
  LITE: { price: 349, hasHumanManager: true, managerName: 'Sarah Chen' },
  HAVEN: { price: 749, hasHumanManager: true, managerName: 'Sarah Chen' },
  HAVEN_PLUS: { price: 1499, hasHumanManager: true, managerName: 'Sarah Chen' },
  ESTATE: { price: 3499, hasHumanManager: true, managerName: 'Sarah Chen' },
  // Legacy tiers (map to essentials)
  FREE: { price: 0, hasHumanManager: false, managerName: 'Alfred' },
  BASIC: { price: 39, hasHumanManager: false, managerName: 'Alfred' },
  PREMIUM: { price: 349, hasHumanManager: true, managerName: 'Sarah Chen' },
  ENTERPRISE: { price: 3499, hasHumanManager: true, managerName: 'Sarah Chen' },
};

@Injectable()
export class SubscriptionService {
  constructor(private prisma: PrismaService) {}

  async getSubscription(userId: string) {
    try {
      const subscription = await this.prisma.subscription.findFirst({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      });

      const dbTier = subscription?.tier || 'ESSENTIALS';
      const config = TIER_CONFIG[dbTier] || TIER_CONFIG.ESSENTIALS;

      // Return client-friendly lowercase tier
      const clientTier = dbTier.toLowerCase().replace('_', '_') as SubscriptionTierClient;

      return {
        tier: clientTier,
        tierDb: dbTier,
        status: subscription?.status || 'ACTIVE',
        config,
        hasHumanManager: config.hasHumanManager,
        managerName: config.managerName,
      };
    } catch (error) {
      // If subscription table doesn't exist yet, return defaults
      return {
        tier: 'essentials' as SubscriptionTierClient,
        tierDb: 'ESSENTIALS',
        status: 'ACTIVE',
        config: TIER_CONFIG.ESSENTIALS,
        hasHumanManager: false,
        managerName: 'Alfred',
      };
    }
  }
}

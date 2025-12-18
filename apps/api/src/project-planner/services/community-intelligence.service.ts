import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ProjectCategory } from '@prisma/client';
import * as h3 from 'h3-js';
import { VendorSuggestionDto, VendorWithSocialSignalsDto } from '../dto';

@Injectable()
export class CommunityIntelligenceService {
  private readonly logger = new Logger(CommunityIntelligenceService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generate system suggestions for a project idea based on neighborhood data
   * "Ace Decking was used by 2 neighbors for similar projects"
   */
  async generateSystemSuggestions(projectIdeaId: string): Promise<VendorSuggestionDto[]> {
    const idea = await this.prisma.projectIdea.findUnique({
      where: { id: projectIdeaId },
      include: {
        household: {
          select: { h3Index: true },
        },
      },
    });

    if (!idea || !idea.household.h3Index) {
      return [];
    }

    // Get neighbor cells
    const neighborCells = h3.gridDisk(idea.household.h3Index, 2); // 2 rings for more coverage

    // Find vendors used by neighbors in completed work orders
    const neighborWorkOrders = await this.prisma.workOrder.findMany({
      where: {
        household: {
          h3Index: { in: neighborCells },
          id: { not: idea.householdId },
        },
        vendorId: { not: null },
        status: 'COMPLETED',
      },
      include: {
        vendor: {
          select: {
            id: true,
            displayName: true,
            contactName: true,
            email: true,
            phone: true,
            category: true,
          },
        },
      },
    });

    // Also check ProjectPosts for vendor mentions
    const neighborProjectPosts = await this.prisma.projectPost.findMany({
      where: {
        household: {
          h3Index: { in: neighborCells },
          id: { not: idea.householdId },
        },
        vendorId: { not: null },
        completedAt: { not: null },
      },
      include: {
        vendor: {
          select: {
            id: true,
            displayName: true,
            contactName: true,
            email: true,
            phone: true,
            category: true,
          },
        },
      },
    });

    // Count vendor usage
    const vendorCounts = new Map<string, { vendor: any; count: number }>();

    for (const wo of neighborWorkOrders) {
      if (!wo.vendorId || !wo.vendor) continue;
      const existing = vendorCounts.get(wo.vendorId);
      if (existing) {
        existing.count++;
      } else {
        vendorCounts.set(wo.vendorId, { vendor: wo.vendor, count: 1 });
      }
    }

    for (const post of neighborProjectPosts) {
      if (!post.vendorId || !post.vendor) continue;
      const existing = vendorCounts.get(post.vendorId);
      if (existing) {
        existing.count++;
      } else {
        vendorCounts.set(post.vendorId, { vendor: post.vendor, count: 1 });
      }
    }

    // Sort by count and create suggestions
    const sortedVendors = Array.from(vendorCounts.entries())
      .sort((a, b) => b[1].count - a[1].count)
      .slice(0, 5); // Top 5

    const suggestions: VendorSuggestionDto[] = [];

    for (const [vendorId, { vendor, count }] of sortedVendors) {
      // Check if suggestion already exists
      const existingSuggestion = await this.prisma.vendorSuggestion.findFirst({
        where: {
          projectIdeaId,
          vendorId,
          isSystemSuggestion: true,
        },
      });

      if (existingSuggestion) continue;

      // Create system suggestion
      const suggestion = await this.prisma.vendorSuggestion.create({
        data: {
          projectIdeaId,
          vendorId,
          isSystemSuggestion: true,
          systemNote: count === 1
            ? `Used by 1 neighbor for a similar project`
            : `Used by ${count} neighbors for similar projects`,
        },
        include: {
          vendor: {
            select: {
              id: true,
              displayName: true,
              contactName: true,
              email: true,
              phone: true,
              category: true,
            },
          },
        },
      });

      suggestions.push(this.mapToDto(suggestion));
    }

    return suggestions;
  }

  /**
   * Get vendors with social signals for a user
   * Shows which vendors were used by friends and neighbors
   */
  async getVendorSocialSignals(
    userId: string,
    householdId: string,
    category?: ProjectCategory,
  ): Promise<VendorWithSocialSignalsDto[]> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { h3Index: true },
    });

    if (!household?.h3Index) {
      return [];
    }

    // Get user's friends (bi-directional friendships)
    const friendships = await this.prisma.friendship.findMany({
      where: {
        OR: [
          { requesterId: userId, status: 'ACCEPTED' },
          { addresseeId: userId, status: 'ACCEPTED' },
        ],
      },
      select: {
        requesterId: true,
        addresseeId: true,
      },
    });

    const friendUserIds = friendships.map(f =>
      f.requesterId === userId ? f.addresseeId : f.requesterId
    );

    // Get neighbor cells
    const neighborCells = h3.gridDisk(household.h3Index, 2);

    // Get all vendors used by neighbors and friends
    const vendorMap = new Map<string, VendorWithSocialSignalsDto>();

    // Query neighbor work orders
    const neighborWorkOrders = await this.prisma.workOrder.findMany({
      where: {
        household: {
          h3Index: { in: neighborCells },
          id: { not: householdId },
        },
        vendorId: { not: null },
        status: 'COMPLETED',
      },
      include: {
        vendor: {
          select: {
            id: true,
            displayName: true,
            contactName: true,
            category: true,
          },
        },
        household: {
          select: {
            members: {
              select: {
                userId: true,
                user: {
                  select: { id: true, displayName: true },
                },
              },
            },
          },
        },
      },
    });

    // Query friend project posts
    const friendProjectPosts = await this.prisma.projectPost.findMany({
      where: {
        authorId: { in: friendUserIds },
        vendorId: { not: null },
        completedAt: { not: null },
      },
      include: {
        vendor: {
          select: {
            id: true,
            displayName: true,
            contactName: true,
            category: true,
          },
        },
        author: {
          select: { id: true, displayName: true },
        },
      },
    });

    // Process neighbor work orders
    for (const wo of neighborWorkOrders) {
      if (!wo.vendor) continue;

      let entry = vendorMap.get(wo.vendor.id);
      if (!entry) {
        entry = {
          vendor: {
            id: wo.vendor.id,
            companyName: wo.vendor.displayName,
            contactName: wo.vendor.contactName ?? undefined,
            specialty: wo.vendor.category ? [wo.vendor.category] : undefined,
          },
          usedByNeighborsCount: 0,
          usedByFriendsCount: 0,
          friendRecommendations: [],
        };
        vendorMap.set(wo.vendor.id, entry);
      }
      entry.usedByNeighborsCount++;

      // Check if any household member is a friend
      const friendMember = wo.household.members.find(m => friendUserIds.includes(m.userId));
      if (friendMember?.user) {
        entry.usedByFriendsCount++;
        if (!entry.friendRecommendations.find(r => r.userId === friendMember.user.id)) {
          entry.friendRecommendations.push({
            userId: friendMember.user.id,
            displayName: friendMember.user.displayName ?? 'Unknown',
          });
        }
      }
    }

    // Process friend project posts
    for (const post of friendProjectPosts) {
      if (!post.vendor) continue;

      let entry = vendorMap.get(post.vendor.id);
      if (!entry) {
        entry = {
          vendor: {
            id: post.vendor.id,
            companyName: post.vendor.displayName,
            contactName: post.vendor.contactName ?? undefined,
            specialty: post.vendor.category ? [post.vendor.category] : undefined,
          },
          usedByNeighborsCount: 0,
          usedByFriendsCount: 0,
          friendRecommendations: [],
        };
        vendorMap.set(post.vendor.id, entry);
      }

      if (!entry.friendRecommendations.find(r => r.userId === post.author.id)) {
        entry.usedByFriendsCount++;
        entry.friendRecommendations.push({
          userId: post.author.id,
          displayName: post.author.displayName ?? 'Unknown',
          projectPostId: post.id,
          projectTitle: post.title,
        });
      }
    }

    // Sort by combined social signals
    return Array.from(vendorMap.values())
      .sort((a, b) => {
        const scoreA = a.usedByFriendsCount * 2 + a.usedByNeighborsCount;
        const scoreB = b.usedByFriendsCount * 2 + b.usedByNeighborsCount;
        return scoreB - scoreA;
      });
  }

  /**
   * Get inspiration from neighbor project posts
   */
  async getNeighborInspiration(
    householdId: string,
    category: ProjectCategory,
    limit: number = 10,
  ): Promise<Array<{
    id: string;
    title: string;
    description?: string;
    images: string[];
    actualCost?: number;
    authorDisplayName: string;
    isNeighbor: boolean;
    vendorName?: string;
  }>> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { h3Index: true },
    });

    if (!household?.h3Index) {
      return [];
    }

    const neighborCells = h3.gridDisk(household.h3Index, 2);

    const posts = await this.prisma.projectPost.findMany({
      where: {
        household: {
          h3Index: { in: neighborCells },
          id: { not: householdId },
        },
        visibility: { in: ['PUBLIC', 'NEIGHBORS_ONLY'] },
        completedAt: { not: null },
      },
      take: limit,
      orderBy: [
        { likesCount: 'desc' },
        { createdAt: 'desc' },
      ],
      include: {
        author: {
          select: { displayName: true },
        },
        vendor: {
          select: { displayName: true },
        },
        household: {
          select: { h3Index: true },
        },
      },
    });

    return posts.map(post => ({
      id: post.id,
      title: post.title,
      description: post.description ?? undefined,
      images: [...post.beforeImages, ...post.afterImages],
      actualCost: post.actualCost ? Number(post.actualCost) : undefined,
      authorDisplayName: post.author.displayName ?? 'Unknown',
      isNeighbor: h3.gridDisk(household.h3Index!, 1).includes(post.household.h3Index!),
      vendorName: post.vendor?.displayName,
    }));
  }

  private mapToDto(suggestion: any): VendorSuggestionDto {
    return {
      id: suggestion.id,
      projectIdeaId: suggestion.projectIdeaId,
      recommendationRequestId: suggestion.recommendationRequestId,
      vendorId: suggestion.vendorId,
      suggestedByUserId: suggestion.suggestedByUserId,
      comment: suggestion.comment,
      rating: suggestion.rating,
      isSystemSuggestion: suggestion.isSystemSuggestion,
      systemNote: suggestion.systemNote,
      referenceProjectPostId: suggestion.referenceProjectPostId,
      isHelpful: suggestion.isHelpful,
      createdAt: suggestion.createdAt,
      vendor: suggestion.vendor ? {
        id: suggestion.vendor.id,
        companyName: suggestion.vendor.displayName,
        contactName: suggestion.vendor.contactName,
        email: suggestion.vendor.email,
        phone: suggestion.vendor.phone,
        specialty: suggestion.vendor.category ? [suggestion.vendor.category] : undefined,
      } : undefined,
      suggestedBy: suggestion.suggestedBy,
      referenceProjectPost: suggestion.referenceProjectPost,
    };
  }
}

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma';
import { PostVisibility, FriendshipStatus } from '@prisma/client';
import { FriendshipService } from './friendship.service';
import { FollowService } from './follow.service';

export interface SocialVendorResult {
  vendor: any;
  socialSignals: {
    usedByFriendsCount: number;
    usedByNeighborsCount: number;
    usedByInfluencersCount: number;
    friendProjects: Array<{
      userId: string;
      displayName: string;
      postId: string;
      postTitle: string;
    }>;
  };
}

export interface SocialVendorSearchOptions {
  category?: string;
  socialProof?: 'friends' | 'neighbors' | 'influencers';
  limit?: number;
  cursor?: string;
}

@Injectable()
export class SocialVendorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly friendshipService: FriendshipService,
    private readonly followService: FollowService,
  ) {}

  /**
   * Search vendors with social signals
   */
  async searchVendorsWithSocial(
    userId: string,
    householdId: string,
    options: SocialVendorSearchOptions = {},
  ): Promise<{ vendors: SocialVendorResult[]; hasMore: boolean; nextCursor: string | null }> {
    const limit = options.limit || 20;

    // Get user's social graph
    const [friendIds, followingIds] = await Promise.all([
      this.friendshipService.getFriendIds(userId),
      this.followService.getFollowingIds(userId),
    ]);

    // Get household H3 index for neighbor matching
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { h3Index: true },
    });

    // Build base vendor query
    const whereClause: any = {
      isActive: true,
      projectPosts: {
        some: {
          visibility: { not: PostVisibility.PRIVATE },
        },
      },
    };

    if (options.category) {
      whereClause.category = options.category;
    }

    // Fetch vendors with project post counts
    const vendors = await this.prisma.vendor.findMany({
      where: whereClause,
      include: {
        projectPosts: {
          where: {
            visibility: { not: PostVisibility.PRIVATE },
          },
          include: {
            author: {
              select: {
                id: true,
                displayName: true,
                isPublicProfile: true,
                influencerBadges: true,
              },
            },
            household: {
              select: { h3Index: true },
            },
          },
        },
        serviceCategory: {
          select: { name: true },
        },
      },
      take: limit + 1,
      ...(options.cursor && { cursor: { id: options.cursor }, skip: 1 }),
    });

    const hasMore = vendors.length > limit;
    if (hasMore) vendors.pop();

    // Calculate social signals for each vendor
    const results: SocialVendorResult[] = vendors.map((vendor) => {
      const friendProjects: SocialVendorResult['socialSignals']['friendProjects'] = [];
      let usedByFriendsCount = 0;
      let usedByNeighborsCount = 0;
      let usedByInfluencersCount = 0;

      for (const post of vendor.projectPosts) {
        // Check if used by friend
        if (friendIds.includes(post.authorId)) {
          usedByFriendsCount++;
          friendProjects.push({
            userId: post.author.id,
            displayName: post.author.displayName || 'A friend',
            postId: post.id,
            postTitle: post.title,
          });
        }

        // Check if used by neighbor (same H3 cell)
        if (household?.h3Index && post.household.h3Index === household.h3Index) {
          usedByNeighborsCount++;
        }

        // Check if used by influencer (someone with badges that we follow)
        if (
          post.author.influencerBadges?.length > 0 &&
          (followingIds.includes(post.authorId) || post.author.isPublicProfile)
        ) {
          usedByInfluencersCount++;
        }
      }

      // Remove projectPosts from vendor to clean up response
      const { projectPosts, ...vendorData } = vendor;

      return {
        vendor: vendorData,
        socialSignals: {
          usedByFriendsCount,
          usedByNeighborsCount,
          usedByInfluencersCount,
          friendProjects: friendProjects.slice(0, 3), // Limit to 3 friend reviews
        },
      };
    });

    // Sort by social proof if requested
    if (options.socialProof === 'friends') {
      results.sort((a, b) => b.socialSignals.usedByFriendsCount - a.socialSignals.usedByFriendsCount);
    } else if (options.socialProof === 'neighbors') {
      results.sort((a, b) => b.socialSignals.usedByNeighborsCount - a.socialSignals.usedByNeighborsCount);
    } else if (options.socialProof === 'influencers') {
      results.sort((a, b) => b.socialSignals.usedByInfluencersCount - a.socialSignals.usedByInfluencersCount);
    }

    return {
      vendors: results,
      hasMore,
      nextCursor: hasMore ? vendors[vendors.length - 1].id : null,
    };
  }

  /**
   * Get social activity for a specific vendor
   */
  async getVendorSocialActivity(
    vendorId: string,
    userId: string,
    householdId: string,
  ) {
    const [friendIds, household] = await Promise.all([
      this.friendshipService.getFriendIds(userId),
      this.prisma.household.findUnique({
        where: { id: householdId },
        select: { h3Index: true },
      }),
    ]);

    const vendor = await this.prisma.vendor.findUnique({
      where: { id: vendorId },
      include: {
        projectPosts: {
          where: {
            visibility: { not: PostVisibility.PRIVATE },
          },
          include: {
            author: {
              select: {
                id: true,
                displayName: true,
                avatarUrl: true,
                isPublicProfile: true,
                influencerBadges: true,
              },
            },
            household: {
              select: { h3Index: true },
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
      },
    });

    if (!vendor) {
      return null;
    }

    // Categorize posts by social relationship
    const friendPosts: any[] = [];
    const neighborPosts: any[] = [];
    const publicPosts: any[] = [];

    for (const post of vendor.projectPosts) {
      const postData = {
        id: post.id,
        title: post.title,
        author: {
          id: post.author.id,
          displayName: post.author.displayName,
          avatarUrl: post.author.avatarUrl,
          isInfluencer: (post.author.influencerBadges?.length || 0) > 0,
        },
        isVerified: post.isVerified,
        createdAt: post.createdAt,
      };

      if (friendIds.includes(post.authorId)) {
        friendPosts.push(postData);
      } else if (household?.h3Index && post.household.h3Index === household.h3Index) {
        neighborPosts.push({ ...postData, author: { displayName: 'A neighbor' } });
      } else if (post.visibility === PostVisibility.PUBLIC) {
        publicPosts.push(postData);
      }
    }

    return {
      vendorId,
      vendorName: vendor.displayName,
      rating: vendor.rating,
      reviewCount: vendor.reviewCount,
      friendPosts,
      neighborPosts,
      publicPosts,
      totalProjects: vendor.projectPosts.length,
    };
  }
}

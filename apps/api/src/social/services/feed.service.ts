import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma';
import { PostVisibility, FriendshipStatus } from '@prisma/client';
import { FriendshipService } from './friendship.service';
import { FollowService } from './follow.service';

export type FeedSource = 'neighbor' | 'friend' | 'following';

export interface FeedItem {
  post: any; // ProjectPost with includes
  source: FeedSource;
  isAnonymized: boolean;
  author: {
    id: string;
    displayName: string | null;
    avatarUrl: string | null;
    isInfluencer: boolean;
  };
}

export interface FeedQueryOptions {
  limit?: number;
  cursor?: string;
  source?: FeedSource;
}

@Injectable()
export class FeedService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly friendshipService: FriendshipService,
    private readonly followService: FollowService,
  ) {}

  private readonly postInclude = {
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
      select: {
        id: true,
        name: true,
        h3Index: true,
      },
    },
    vendor: {
      select: {
        id: true,
        displayName: true,
        rating: true,
        category: true,
      },
    },
    _count: {
      select: {
        likes: true,
        saves: true,
        comments: true,
      },
    },
  };

  /**
   * Get aggregated feed combining neighbor, friend, and following posts
   */
  async getAggregatedFeed(
    userId: string,
    householdId: string,
    options: FeedQueryOptions = {},
  ): Promise<{ items: FeedItem[]; hasMore: boolean; nextCursor: string | null }> {
    const limit = options.limit || 20;

    // Get user's household H3 index
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { h3Index: true },
    });

    const h3Index = household?.h3Index;

    // Get friend and following IDs
    const [friendIds, followingIds] = await Promise.all([
      this.friendshipService.getFriendIds(userId),
      this.followService.getFollowingIds(userId),
    ]);

    // Build the query based on source filter
    let posts: any[] = [];

    if (!options.source || options.source === 'friend') {
      // Friend posts (FRIENDS_ONLY or PUBLIC from friends)
      if (friendIds.length > 0) {
        const friendPosts = await this.prisma.projectPost.findMany({
          where: {
            authorId: { in: friendIds },
            visibility: { in: [PostVisibility.FRIENDS_ONLY, PostVisibility.PUBLIC] },
            ...(options.cursor && { createdAt: { lt: new Date(options.cursor) } }),
          },
          include: this.postInclude,
          orderBy: { createdAt: 'desc' },
          take: limit + 1,
        });

        posts.push(
          ...friendPosts.map((p) => ({
            post: p,
            source: 'friend' as FeedSource,
            isAnonymized: false,
          })),
        );
      }
    }

    if (!options.source || options.source === 'following') {
      // Following posts (PUBLIC from people we follow who aren't friends)
      const nonFriendFollowing = followingIds.filter((id) => !friendIds.includes(id));
      if (nonFriendFollowing.length > 0) {
        const followingPosts = await this.prisma.projectPost.findMany({
          where: {
            authorId: { in: nonFriendFollowing },
            visibility: PostVisibility.PUBLIC,
            ...(options.cursor && { createdAt: { lt: new Date(options.cursor) } }),
          },
          include: this.postInclude,
          orderBy: { createdAt: 'desc' },
          take: limit + 1,
        });

        posts.push(
          ...followingPosts.map((p) => ({
            post: p,
            source: 'following' as FeedSource,
            isAnonymized: false,
          })),
        );
      }
    }

    if ((!options.source || options.source === 'neighbor') && h3Index) {
      // Neighbor posts (NEIGHBORS_ONLY from same H3 cell, excluding friends/self)
      const neighborPosts = await this.prisma.projectPost.findMany({
        where: {
          household: { h3Index },
          authorId: { notIn: [userId, ...friendIds] },
          visibility: PostVisibility.NEIGHBORS_ONLY,
          ...(options.cursor && { createdAt: { lt: new Date(options.cursor) } }),
        },
        include: this.postInclude,
        orderBy: { createdAt: 'desc' },
        take: limit + 1,
      });

      posts.push(
        ...neighborPosts.map((p) => ({
          post: p,
          source: 'neighbor' as FeedSource,
          isAnonymized: true, // Neighbors are anonymized unless friends
        })),
      );
    }

    // Sort all posts by createdAt
    posts.sort((a, b) =>
      new Date(b.post.createdAt).getTime() - new Date(a.post.createdAt).getTime()
    );

    // Apply pagination
    const hasMore = posts.length > limit;
    if (hasMore) posts = posts.slice(0, limit);

    // Transform to FeedItem format
    const items: FeedItem[] = posts.map((p) => ({
      post: p.post,
      source: p.source,
      isAnonymized: p.isAnonymized,
      author: p.isAnonymized
        ? {
            id: p.post.author.id,
            displayName: `A neighbor in ${p.post.household.name?.split(' ')[0] || 'your area'}`,
            avatarUrl: null,
            isInfluencer: false,
          }
        : {
            id: p.post.author.id,
            displayName: p.post.author.displayName,
            avatarUrl: p.post.author.avatarUrl,
            isInfluencer: (p.post.author.influencerBadges?.length || 0) > 0,
          },
    }));

    return {
      items,
      hasMore,
      nextCursor: hasMore ? posts[posts.length - 1].post.createdAt.toISOString() : null,
    };
  }

  /**
   * Get feed filtered by source
   */
  async getFeedBySource(
    userId: string,
    householdId: string,
    source: FeedSource,
    options: FeedQueryOptions = {},
  ) {
    return this.getAggregatedFeed(userId, householdId, { ...options, source });
  }

  /**
   * Get neighbor posts for map view (returns location info for pins)
   */
  async getNeighborPostsForMap(householdId: string, limit = 50) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { h3Index: true },
    });

    if (!household?.h3Index) {
      return [];
    }

    const posts = await this.prisma.projectPost.findMany({
      where: {
        household: { h3Index: household.h3Index },
        visibility: PostVisibility.NEIGHBORS_ONLY,
      },
      include: {
        household: {
          select: { h3Index: true },
        },
        vendor: {
          select: { id: true, displayName: true, category: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });

    // Return anonymized data suitable for map pins
    return posts.map((p) => ({
      id: p.id,
      title: p.title,
      h3Index: p.household.h3Index,
      costDisplay: p.costDisplay,
      actualCost: p.costDisplay === 'EXACT' ? p.actualCost : null,
      vendor: p.vendor,
      isVerified: p.isVerified,
      createdAt: p.createdAt,
    }));
  }
}

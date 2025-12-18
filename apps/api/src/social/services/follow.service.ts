import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma';

@Injectable()
export class FollowService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Follow a user
   */
  async follow(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new BadRequestException('Cannot follow yourself');
    }

    // Check if target user exists
    const targetUser = await this.prisma.user.findUnique({
      where: { id: followingId },
      select: { id: true, displayName: true, isPublicProfile: true },
    });

    if (!targetUser) {
      throw new NotFoundException('User not found');
    }

    // Check if already following
    const existing = await this.prisma.follow.findUnique({
      where: {
        followerId_followingId: { followerId, followingId },
      },
    });

    if (existing) {
      throw new BadRequestException('Already following this user');
    }

    const follow = await this.prisma.follow.create({
      data: {
        followerId,
        followingId,
      },
      include: {
        following: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
    });

    // Notify the followed user
    await this.prisma.inAppNotification.create({
      data: {
        userId: followingId,
        title: 'New Follower',
        body: 'Someone started following you',
        link: `/app/profile/${followerId}`,
      },
    });

    return follow;
  }

  /**
   * Unfollow a user
   */
  async unfollow(followerId: string, followingId: string) {
    const follow = await this.prisma.follow.findUnique({
      where: {
        followerId_followingId: { followerId, followingId },
      },
    });

    if (!follow) {
      throw new NotFoundException('Not following this user');
    }

    await this.prisma.follow.delete({
      where: { id: follow.id },
    });
  }

  /**
   * Get list of users that a user is following
   */
  async getFollowing(userId: string) {
    const follows = await this.prisma.follow.findMany({
      where: { followerId: userId },
      include: {
        following: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isPublicProfile: true,
            influencerBadges: true,
            bio: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return follows.map((f) => f.following);
  }

  /**
   * Get list of users following a user
   */
  async getFollowers(userId: string) {
    const follows = await this.prisma.follow.findMany({
      where: { followingId: userId },
      include: {
        follower: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isPublicProfile: true,
            influencerBadges: true,
            bio: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return follows.map((f) => f.follower);
  }

  /**
   * Get IDs of users that a user is following (for feed queries)
   */
  async getFollowingIds(userId: string): Promise<string[]> {
    const follows = await this.prisma.follow.findMany({
      where: { followerId: userId },
      select: { followingId: true },
    });

    return follows.map((f) => f.followingId);
  }

  /**
   * Check if a user is following another user
   */
  async isFollowing(followerId: string, followingId: string): Promise<boolean> {
    const follow = await this.prisma.follow.findUnique({
      where: {
        followerId_followingId: { followerId, followingId },
      },
    });

    return !!follow;
  }

  /**
   * Get follower and following counts for a user
   */
  async getCounts(userId: string): Promise<{ followers: number; following: number }> {
    const [followers, following] = await Promise.all([
      this.prisma.follow.count({ where: { followingId: userId } }),
      this.prisma.follow.count({ where: { followerId: userId } }),
    ]);

    return { followers, following };
  }
}

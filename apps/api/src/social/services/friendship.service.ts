import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma';
import { FriendshipStatus } from '@prisma/client';

@Injectable()
export class FriendshipService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Send a friend request
   */
  async sendFriendRequest(requesterId: string, addresseeId: string) {
    if (requesterId === addresseeId) {
      throw new BadRequestException('Cannot send friend request to yourself');
    }

    // Check if friendship already exists (in either direction)
    const existing = await this.prisma.friendship.findFirst({
      where: {
        OR: [
          { requesterId, addresseeId },
          { requesterId: addresseeId, addresseeId: requesterId },
        ],
      },
    });

    if (existing) {
      if (existing.status === FriendshipStatus.ACCEPTED) {
        throw new BadRequestException('Already friends with this user');
      }
      if (existing.status === FriendshipStatus.PENDING) {
        throw new BadRequestException('Friend request already pending');
      }
      if (existing.status === FriendshipStatus.BLOCKED) {
        throw new BadRequestException('Cannot send friend request');
      }
    }

    // Check addressee exists
    const addressee = await this.prisma.user.findUnique({
      where: { id: addresseeId },
    });
    if (!addressee) {
      throw new NotFoundException('User not found');
    }

    const friendship = await this.prisma.friendship.create({
      data: {
        requesterId,
        addresseeId,
        status: FriendshipStatus.PENDING,
      },
      include: {
        addressee: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
    });

    // Create notification for addressee
    await this.prisma.inAppNotification.create({
      data: {
        userId: addresseeId,
        title: 'New Friend Request',
        body: `${friendship.addressee.displayName || 'Someone'} sent you a friend request`,
        link: '/app/community/friends',
      },
    });

    return friendship;
  }

  /**
   * Accept a friend request
   */
  async acceptFriendRequest(friendshipId: string, userId: string) {
    const friendship = await this.prisma.friendship.findUnique({
      where: { id: friendshipId },
      include: {
        requester: {
          select: { id: true, displayName: true },
        },
      },
    });

    if (!friendship) {
      throw new NotFoundException('Friend request not found');
    }

    if (friendship.addresseeId !== userId) {
      throw new ForbiddenException('Not authorized to accept this request');
    }

    if (friendship.status !== FriendshipStatus.PENDING) {
      throw new BadRequestException('Friend request is not pending');
    }

    const updated = await this.prisma.friendship.update({
      where: { id: friendshipId },
      data: {
        status: FriendshipStatus.ACCEPTED,
        acceptedAt: new Date(),
      },
      include: {
        requester: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
        addressee: {
          select: { id: true, displayName: true, avatarUrl: true },
        },
      },
    });

    // Notify requester
    await this.prisma.inAppNotification.create({
      data: {
        userId: friendship.requesterId,
        title: 'Friend Request Accepted',
        body: `${updated.addressee.displayName || 'Someone'} accepted your friend request`,
        link: `/app/profile/${userId}`,
      },
    });

    return updated;
  }

  /**
   * Decline a friend request
   */
  async declineFriendRequest(friendshipId: string, userId: string) {
    const friendship = await this.prisma.friendship.findUnique({
      where: { id: friendshipId },
    });

    if (!friendship) {
      throw new NotFoundException('Friend request not found');
    }

    if (friendship.addresseeId !== userId) {
      throw new ForbiddenException('Not authorized to decline this request');
    }

    if (friendship.status !== FriendshipStatus.PENDING) {
      throw new BadRequestException('Friend request is not pending');
    }

    await this.prisma.friendship.update({
      where: { id: friendshipId },
      data: { status: FriendshipStatus.DECLINED },
    });
  }

  /**
   * Remove a friend (either party can do this)
   */
  async removeFriend(userId: string, friendId: string) {
    const friendship = await this.prisma.friendship.findFirst({
      where: {
        OR: [
          { requesterId: userId, addresseeId: friendId },
          { requesterId: friendId, addresseeId: userId },
        ],
        status: FriendshipStatus.ACCEPTED,
      },
    });

    if (!friendship) {
      throw new NotFoundException('Friendship not found');
    }

    await this.prisma.friendship.delete({
      where: { id: friendship.id },
    });
  }

  /**
   * Block a user
   */
  async blockUser(userId: string, blockedUserId: string) {
    if (userId === blockedUserId) {
      throw new BadRequestException('Cannot block yourself');
    }

    // Find or create friendship record
    const existing = await this.prisma.friendship.findFirst({
      where: {
        OR: [
          { requesterId: userId, addresseeId: blockedUserId },
          { requesterId: blockedUserId, addresseeId: userId },
        ],
      },
    });

    if (existing) {
      await this.prisma.friendship.update({
        where: { id: existing.id },
        data: { status: FriendshipStatus.BLOCKED },
      });
    } else {
      await this.prisma.friendship.create({
        data: {
          requesterId: userId,
          addresseeId: blockedUserId,
          status: FriendshipStatus.BLOCKED,
        },
      });
    }
  }

  /**
   * Get list of friends for a user
   */
  async getFriends(userId: string) {
    const friendships = await this.prisma.friendship.findMany({
      where: {
        OR: [{ requesterId: userId }, { addresseeId: userId }],
        status: FriendshipStatus.ACCEPTED,
      },
      include: {
        requester: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isPublicProfile: true,
            influencerBadges: true,
          },
        },
        addressee: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isPublicProfile: true,
            influencerBadges: true,
          },
        },
      },
    });

    // Return the friend (not self) from each friendship
    return friendships.map((f) =>
      f.requesterId === userId ? f.addressee : f.requester,
    );
  }

  /**
   * Get pending friend requests received by user
   */
  async getPendingRequests(userId: string) {
    return this.prisma.friendship.findMany({
      where: {
        addresseeId: userId,
        status: FriendshipStatus.PENDING,
      },
      include: {
        requester: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            isPublicProfile: true,
            influencerBadges: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * Get IDs of all friends for a user (for feed queries)
   */
  async getFriendIds(userId: string): Promise<string[]> {
    const friendships = await this.prisma.friendship.findMany({
      where: {
        OR: [{ requesterId: userId }, { addresseeId: userId }],
        status: FriendshipStatus.ACCEPTED,
      },
      select: {
        requesterId: true,
        addresseeId: true,
      },
    });

    return friendships.map((f) =>
      f.requesterId === userId ? f.addresseeId : f.requesterId,
    );
  }

  /**
   * Check if two users are friends
   */
  async areFriends(userId1: string, userId2: string): Promise<boolean> {
    const friendship = await this.prisma.friendship.findFirst({
      where: {
        OR: [
          { requesterId: userId1, addresseeId: userId2 },
          { requesterId: userId2, addresseeId: userId1 },
        ],
        status: FriendshipStatus.ACCEPTED,
      },
    });

    return !!friendship;
  }
}

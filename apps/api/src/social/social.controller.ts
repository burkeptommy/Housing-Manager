import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase';
import { FriendshipService } from './services/friendship.service';
import { FollowService } from './services/follow.service';
import { ProjectPostService } from './services/project-post.service';
import { FeedService, FeedSource } from './services/feed.service';
import { SocialVendorService } from './services/social-vendor.service';
import {
  SendFriendRequestDto,
  FollowUserDto,
  CreateProjectPostDto,
  UpdateProjectPostDto,
  AddCommentDto,
  FeedQueryDto,
  SocialVendorSearchDto,
  UpdateSocialProfileDto,
  PaginationQueryDto,
} from './dto';
import { PrismaService } from '../prisma';

@Controller('social')
@UseGuards(FirebaseAuthGuard)
export class SocialController {
  constructor(
    private readonly friendshipService: FriendshipService,
    private readonly followService: FollowService,
    private readonly projectPostService: ProjectPostService,
    private readonly feedService: FeedService,
    private readonly socialVendorService: SocialVendorService,
    private readonly prisma: PrismaService,
  ) {}

  // ==================== Feed Endpoints ====================

  @Get('feed')
  async getAggregatedFeed(@Request() req, @Query() query: FeedQueryDto) {
    const householdId = await this.getActiveHouseholdId(req.user.userId);
    return this.feedService.getAggregatedFeed(req.user.userId, householdId, {
      limit: query.limit,
      cursor: query.cursor,
      source: query.source as FeedSource,
    });
  }

  @Get('feed/neighbors')
  async getNeighborFeed(@Request() req, @Query() query: PaginationQueryDto) {
    const householdId = await this.getActiveHouseholdId(req.user.userId);
    return this.feedService.getFeedBySource(req.user.userId, householdId, 'neighbor', query);
  }

  @Get('feed/friends')
  async getFriendFeed(@Request() req, @Query() query: PaginationQueryDto) {
    const householdId = await this.getActiveHouseholdId(req.user.userId);
    return this.feedService.getFeedBySource(req.user.userId, householdId, 'friend', query);
  }

  @Get('feed/following')
  async getFollowingFeed(@Request() req, @Query() query: PaginationQueryDto) {
    const householdId = await this.getActiveHouseholdId(req.user.userId);
    return this.feedService.getFeedBySource(req.user.userId, householdId, 'following', query);
  }

  @Get('feed/map')
  async getNeighborPostsForMap(@Request() req, @Query('limit') limit?: number) {
    const householdId = await this.getActiveHouseholdId(req.user.userId);
    return this.feedService.getNeighborPostsForMap(householdId, limit);
  }

  // ==================== Friendship Endpoints ====================

  @Get('friends')
  async getFriends(@Request() req) {
    return this.friendshipService.getFriends(req.user.userId);
  }

  @Get('friends/pending')
  async getPendingRequests(@Request() req) {
    return this.friendshipService.getPendingRequests(req.user.userId);
  }

  @Post('friends/request')
  async sendFriendRequest(@Request() req, @Body() dto: SendFriendRequestDto) {
    return this.friendshipService.sendFriendRequest(req.user.userId, dto.addresseeId);
  }

  @Post('friends/:id/accept')
  async acceptFriendRequest(@Request() req, @Param('id') friendshipId: string) {
    return this.friendshipService.acceptFriendRequest(friendshipId, req.user.userId);
  }

  @Post('friends/:id/decline')
  async declineFriendRequest(@Request() req, @Param('id') friendshipId: string) {
    return this.friendshipService.declineFriendRequest(friendshipId, req.user.userId);
  }

  @Delete('friends/:userId')
  async removeFriend(@Request() req, @Param('userId') friendId: string) {
    return this.friendshipService.removeFriend(req.user.userId, friendId);
  }

  @Post('friends/:userId/block')
  async blockUser(@Request() req, @Param('userId') blockedUserId: string) {
    return this.friendshipService.blockUser(req.user.userId, blockedUserId);
  }

  @Get('friends/check/:userId')
  async checkFriendship(@Request() req, @Param('userId') userId: string) {
    const areFriends = await this.friendshipService.areFriends(req.user.userId, userId);
    return { areFriends };
  }

  // ==================== Follow Endpoints ====================

  @Get('following')
  async getFollowing(@Request() req) {
    return this.followService.getFollowing(req.user.userId);
  }

  @Get('followers')
  async getFollowers(@Request() req) {
    return this.followService.getFollowers(req.user.userId);
  }

  @Post('follow/:userId')
  async followUser(@Request() req, @Param('userId') userId: string) {
    return this.followService.follow(req.user.userId, userId);
  }

  @Delete('follow/:userId')
  async unfollowUser(@Request() req, @Param('userId') userId: string) {
    return this.followService.unfollow(req.user.userId, userId);
  }

  @Get('follow/check/:userId')
  async checkFollowing(@Request() req, @Param('userId') userId: string) {
    const isFollowing = await this.followService.isFollowing(req.user.userId, userId);
    return { isFollowing };
  }

  @Get('follow/counts/:userId')
  async getFollowCounts(@Param('userId') userId: string) {
    return this.followService.getCounts(userId);
  }

  // ==================== Project Post Endpoints ====================

  @Post('posts')
  async createPost(@Request() req, @Body() dto: CreateProjectPostDto) {
    return this.projectPostService.createPost(req.user.userId, dto);
  }

  @Patch('posts/:id')
  async updatePost(
    @Request() req,
    @Param('id') postId: string,
    @Body() dto: UpdateProjectPostDto,
  ) {
    return this.projectPostService.updatePost(postId, req.user.userId, dto);
  }

  @Delete('posts/:id')
  async deletePost(@Request() req, @Param('id') postId: string) {
    return this.projectPostService.deletePost(postId, req.user.userId);
  }

  @Get('posts/:id')
  async getPost(@Request() req, @Param('id') postId: string) {
    return this.projectPostService.getPostById(postId, req.user.userId);
  }

  @Post('posts/:id/like')
  async likePost(@Request() req, @Param('id') postId: string) {
    await this.projectPostService.likePost(postId, req.user.userId);
    return { success: true };
  }

  @Delete('posts/:id/like')
  async unlikePost(@Request() req, @Param('id') postId: string) {
    await this.projectPostService.unlikePost(postId, req.user.userId);
    return { success: true };
  }

  @Post('posts/:id/save')
  async savePost(@Request() req, @Param('id') postId: string) {
    await this.projectPostService.savePost(postId, req.user.userId);
    return { success: true };
  }

  @Delete('posts/:id/save')
  async unsavePost(@Request() req, @Param('id') postId: string) {
    await this.projectPostService.unsavePost(postId, req.user.userId);
    return { success: true };
  }

  @Get('posts/saved')
  async getSavedPosts(@Request() req, @Query() query: PaginationQueryDto) {
    return this.projectPostService.getSavedPosts(req.user.userId, query.limit, query.cursor);
  }

  @Get('posts/:id/comments')
  async getComments(@Param('id') postId: string, @Query() query: PaginationQueryDto) {
    return this.projectPostService.getComments(postId, query.limit, query.cursor);
  }

  @Post('posts/:id/comments')
  async addComment(
    @Request() req,
    @Param('id') postId: string,
    @Body() dto: AddCommentDto,
  ) {
    return this.projectPostService.addComment(postId, req.user.userId, dto.content);
  }

  @Delete('posts/:postId/comments/:commentId')
  async deleteComment(
    @Request() req,
    @Param('postId') postId: string,
    @Param('commentId') commentId: string,
  ) {
    await this.projectPostService.deleteComment(commentId, req.user.userId);
    return { success: true };
  }

  // ==================== Profile Endpoints ====================

  @Get('users/:id/profile')
  async getUserProfile(@Request() req, @Param('id') userId: string) {
    try {
      const user = await this.prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          displayName: true,
          avatarUrl: true,
          bio: true,
          isPublicProfile: true,
          influencerBadges: true,
          createdAt: true,
        },
      });

      // If user not found, return a default profile structure instead of throwing 404
      // This allows the profile page to display gracefully for new users
      if (!user) {
        return {
          id: userId,
          displayName: 'User',
          avatarUrl: null,
          bio: null,
          isPublicProfile: true,
          influencerBadges: [],
          createdAt: new Date(),
          followersCount: 0,
          followingCount: 0,
          areFriends: false,
          isFollowing: false,
          postsCount: 0,
          totalInvestment: 0,
        };
      }

      const [followCounts, areFriends, isFollowing, portfolioStats] = await Promise.all([
        this.followService.getCounts(userId).catch(() => ({ followersCount: 0, followingCount: 0 })),
        this.friendshipService.areFriends(req.user.userId, userId).catch(() => false),
        this.followService.isFollowing(req.user.userId, userId).catch(() => false),
        this.projectPostService.getPortfolioStats(userId).catch(() => ({ postsCount: 0, totalInvestment: 0 })),
      ]);

      return {
        ...user,
        ...followCounts,
        areFriends,
        isFollowing,
        ...portfolioStats,
      };
    } catch (error) {
      // Return default profile on any error
      return {
        id: userId,
        displayName: 'User',
        avatarUrl: null,
        bio: null,
        isPublicProfile: true,
        influencerBadges: [],
        createdAt: new Date(),
        followersCount: 0,
        followingCount: 0,
        areFriends: false,
        isFollowing: false,
        postsCount: 0,
        totalInvestment: 0,
      };
    }
  }

  @Get('users/:id/portfolio')
  async getUserPortfolio(
    @Request() req,
    @Param('id') userId: string,
    @Query() query: PaginationQueryDto,
  ) {
    try {
      return await this.projectPostService.getPostsByUser(userId, req.user.userId, query.limit, query.cursor);
    } catch (error) {
      // Return empty portfolio on error
      return { posts: [], nextCursor: null };
    }
  }

  @Patch('profile')
  async updateProfile(@Request() req, @Body() dto: UpdateSocialProfileDto) {
    return this.prisma.user.update({
      where: { id: req.user.userId },
      data: {
        isPublicProfile: dto.isPublicProfile,
        bio: dto.bio,
        displayName: dto.displayName,
      },
      select: {
        id: true,
        displayName: true,
        bio: true,
        isPublicProfile: true,
        influencerBadges: true,
      },
    });
  }

  @Get('profile/stats')
  async getProfileStats(@Request() req) {
    try {
      const [followCounts, portfolioStats] = await Promise.all([
        this.followService.getCounts(req.user.userId).catch(() => ({ followersCount: 0, followingCount: 0 })),
        this.projectPostService.getPortfolioStats(req.user.userId).catch(() => ({ postsCount: 0, totalInvestment: 0 })),
      ]);

      return {
        ...followCounts,
        ...portfolioStats,
      };
    } catch (error) {
      // Return default stats on error
      return {
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        totalInvestment: 0,
      };
    }
  }

  // ==================== Social Vendor Endpoints ====================

  @Get('vendors')
  async searchVendorsWithSocial(@Request() req, @Query() query: SocialVendorSearchDto) {
    const householdId = await this.getActiveHouseholdId(req.user.userId);
    return this.socialVendorService.searchVendorsWithSocial(req.user.userId, householdId, query);
  }

  @Get('vendors/:id/social')
  async getVendorSocialActivity(@Request() req, @Param('id') vendorId: string) {
    const householdId = await this.getActiveHouseholdId(req.user.userId);
    return this.socialVendorService.getVendorSocialActivity(vendorId, req.user.userId, householdId);
  }

  // ==================== Helper Methods ====================

  private async getActiveHouseholdId(userId: string): Promise<string> {
    const membership = await this.prisma.householdMember.findFirst({
      where: {
        userId,
        status: 'ACTIVE',
      },
      select: { householdId: true },
      orderBy: { createdAt: 'desc' },
    });

    if (!membership) {
      throw new Error('No active household found');
    }

    return membership.householdId;
  }
}

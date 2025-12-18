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
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.feedService.getAggregatedFeed(req.user.uid, householdId, {
      limit: query.limit,
      cursor: query.cursor,
      source: query.source as FeedSource,
    });
  }

  @Get('feed/neighbors')
  async getNeighborFeed(@Request() req, @Query() query: PaginationQueryDto) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.feedService.getFeedBySource(req.user.uid, householdId, 'neighbor', query);
  }

  @Get('feed/friends')
  async getFriendFeed(@Request() req, @Query() query: PaginationQueryDto) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.feedService.getFeedBySource(req.user.uid, householdId, 'friend', query);
  }

  @Get('feed/following')
  async getFollowingFeed(@Request() req, @Query() query: PaginationQueryDto) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.feedService.getFeedBySource(req.user.uid, householdId, 'following', query);
  }

  @Get('feed/map')
  async getNeighborPostsForMap(@Request() req, @Query('limit') limit?: number) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.feedService.getNeighborPostsForMap(householdId, limit);
  }

  // ==================== Friendship Endpoints ====================

  @Get('friends')
  async getFriends(@Request() req) {
    return this.friendshipService.getFriends(req.user.uid);
  }

  @Get('friends/pending')
  async getPendingRequests(@Request() req) {
    return this.friendshipService.getPendingRequests(req.user.uid);
  }

  @Post('friends/request')
  async sendFriendRequest(@Request() req, @Body() dto: SendFriendRequestDto) {
    return this.friendshipService.sendFriendRequest(req.user.uid, dto.addresseeId);
  }

  @Post('friends/:id/accept')
  async acceptFriendRequest(@Request() req, @Param('id') friendshipId: string) {
    return this.friendshipService.acceptFriendRequest(friendshipId, req.user.uid);
  }

  @Post('friends/:id/decline')
  async declineFriendRequest(@Request() req, @Param('id') friendshipId: string) {
    return this.friendshipService.declineFriendRequest(friendshipId, req.user.uid);
  }

  @Delete('friends/:userId')
  async removeFriend(@Request() req, @Param('userId') friendId: string) {
    return this.friendshipService.removeFriend(req.user.uid, friendId);
  }

  @Post('friends/:userId/block')
  async blockUser(@Request() req, @Param('userId') blockedUserId: string) {
    return this.friendshipService.blockUser(req.user.uid, blockedUserId);
  }

  @Get('friends/check/:userId')
  async checkFriendship(@Request() req, @Param('userId') userId: string) {
    const areFriends = await this.friendshipService.areFriends(req.user.uid, userId);
    return { areFriends };
  }

  // ==================== Follow Endpoints ====================

  @Get('following')
  async getFollowing(@Request() req) {
    return this.followService.getFollowing(req.user.uid);
  }

  @Get('followers')
  async getFollowers(@Request() req) {
    return this.followService.getFollowers(req.user.uid);
  }

  @Post('follow/:userId')
  async followUser(@Request() req, @Param('userId') userId: string) {
    return this.followService.follow(req.user.uid, userId);
  }

  @Delete('follow/:userId')
  async unfollowUser(@Request() req, @Param('userId') userId: string) {
    return this.followService.unfollow(req.user.uid, userId);
  }

  @Get('follow/check/:userId')
  async checkFollowing(@Request() req, @Param('userId') userId: string) {
    const isFollowing = await this.followService.isFollowing(req.user.uid, userId);
    return { isFollowing };
  }

  @Get('follow/counts/:userId')
  async getFollowCounts(@Param('userId') userId: string) {
    return this.followService.getCounts(userId);
  }

  // ==================== Project Post Endpoints ====================

  @Post('posts')
  async createPost(@Request() req, @Body() dto: CreateProjectPostDto) {
    return this.projectPostService.createPost(req.user.uid, dto);
  }

  @Patch('posts/:id')
  async updatePost(
    @Request() req,
    @Param('id') postId: string,
    @Body() dto: UpdateProjectPostDto,
  ) {
    return this.projectPostService.updatePost(postId, req.user.uid, dto);
  }

  @Delete('posts/:id')
  async deletePost(@Request() req, @Param('id') postId: string) {
    return this.projectPostService.deletePost(postId, req.user.uid);
  }

  @Get('posts/:id')
  async getPost(@Request() req, @Param('id') postId: string) {
    return this.projectPostService.getPostById(postId, req.user.uid);
  }

  @Post('posts/:id/like')
  async likePost(@Request() req, @Param('id') postId: string) {
    await this.projectPostService.likePost(postId, req.user.uid);
    return { success: true };
  }

  @Delete('posts/:id/like')
  async unlikePost(@Request() req, @Param('id') postId: string) {
    await this.projectPostService.unlikePost(postId, req.user.uid);
    return { success: true };
  }

  @Post('posts/:id/save')
  async savePost(@Request() req, @Param('id') postId: string) {
    await this.projectPostService.savePost(postId, req.user.uid);
    return { success: true };
  }

  @Delete('posts/:id/save')
  async unsavePost(@Request() req, @Param('id') postId: string) {
    await this.projectPostService.unsavePost(postId, req.user.uid);
    return { success: true };
  }

  @Get('posts/saved')
  async getSavedPosts(@Request() req, @Query() query: PaginationQueryDto) {
    return this.projectPostService.getSavedPosts(req.user.uid, query.limit, query.cursor);
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
    return this.projectPostService.addComment(postId, req.user.uid, dto.content);
  }

  @Delete('posts/:postId/comments/:commentId')
  async deleteComment(
    @Request() req,
    @Param('postId') postId: string,
    @Param('commentId') commentId: string,
  ) {
    await this.projectPostService.deleteComment(commentId, req.user.uid);
    return { success: true };
  }

  // ==================== Profile Endpoints ====================

  @Get('users/:id/profile')
  async getUserProfile(@Request() req, @Param('id') userId: string) {
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
      this.followService.getCounts(userId),
      this.friendshipService.areFriends(req.user.uid, userId),
      this.followService.isFollowing(req.user.uid, userId),
      this.projectPostService.getPortfolioStats(userId),
    ]);

    return {
      ...user,
      ...followCounts,
      areFriends,
      isFollowing,
      ...portfolioStats,
    };
  }

  @Get('users/:id/portfolio')
  async getUserPortfolio(
    @Request() req,
    @Param('id') userId: string,
    @Query() query: PaginationQueryDto,
  ) {
    return this.projectPostService.getPostsByUser(userId, req.user.uid, query.limit, query.cursor);
  }

  @Patch('profile')
  async updateProfile(@Request() req, @Body() dto: UpdateSocialProfileDto) {
    return this.prisma.user.update({
      where: { id: req.user.uid },
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
    const [followCounts, portfolioStats] = await Promise.all([
      this.followService.getCounts(req.user.uid),
      this.projectPostService.getPortfolioStats(req.user.uid),
    ]);

    return {
      ...followCounts,
      ...portfolioStats,
    };
  }

  // ==================== Social Vendor Endpoints ====================

  @Get('vendors')
  async searchVendorsWithSocial(@Request() req, @Query() query: SocialVendorSearchDto) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.socialVendorService.searchVendorsWithSocial(req.user.uid, householdId, query);
  }

  @Get('vendors/:id/social')
  async getVendorSocialActivity(@Request() req, @Param('id') vendorId: string) {
    const householdId = await this.getActiveHouseholdId(req.user.uid);
    return this.socialVendorService.getVendorSocialActivity(vendorId, req.user.uid, householdId);
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

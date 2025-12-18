import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma';
import { PostVisibility, CostDisplay, WorkOrderStatus } from '@prisma/client';

export interface CreateProjectPostDto {
  householdId: string;
  workOrderId?: string;
  vendorId?: string;
  title: string;
  description?: string;
  beforeImages?: string[];
  afterImages?: string[];
  visibility?: PostVisibility;
  costDisplay?: CostDisplay;
  actualCost?: number;
  costRangeMin?: number;
  costRangeMax?: number;
  durationDays?: number;
  completedAt?: Date;
}

export interface UpdateProjectPostDto {
  title?: string;
  description?: string;
  beforeImages?: string[];
  afterImages?: string[];
  visibility?: PostVisibility;
  costDisplay?: CostDisplay;
  actualCost?: number;
  costRangeMin?: number;
  costRangeMax?: number;
  durationDays?: number;
}

@Injectable()
export class ProjectPostService {
  constructor(private readonly prisma: PrismaService) {}

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
    workOrder: {
      select: {
        id: true,
        title: true,
        status: true,
        actualCost: true,
        completedAt: true,
        verifiedAt: true,
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
   * Create a new project post
   */
  async createPost(userId: string, dto: CreateProjectPostDto) {
    // Verify user has access to household
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: { householdId: dto.householdId, userId },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('No access to this household');
    }

    let isVerified = false;
    let vendorId = dto.vendorId;
    let actualCost = dto.actualCost;
    let completedAt = dto.completedAt;

    // If linking to work order, pull data from it
    if (dto.workOrderId) {
      const workOrder = await this.prisma.workOrder.findUnique({
        where: { id: dto.workOrderId },
      });

      if (!workOrder || workOrder.householdId !== dto.householdId) {
        throw new BadRequestException('Invalid work order');
      }

      // Work order must be completed or verified to create a post
      if (
        workOrder.status !== WorkOrderStatus.COMPLETED &&
        workOrder.status !== WorkOrderStatus.VERIFIED
      ) {
        throw new BadRequestException('Work order must be completed to create a post');
      }

      isVerified = workOrder.status === WorkOrderStatus.VERIFIED;
      vendorId = vendorId || workOrder.vendorId || undefined;
      actualCost = actualCost ?? (workOrder.actualCost ? Number(workOrder.actualCost) : undefined);
      completedAt = completedAt || workOrder.completedAt || undefined;
    }

    return this.prisma.projectPost.create({
      data: {
        authorId: userId,
        householdId: dto.householdId,
        workOrderId: dto.workOrderId,
        vendorId,
        title: dto.title,
        description: dto.description,
        beforeImages: dto.beforeImages || [],
        afterImages: dto.afterImages || [],
        visibility: dto.visibility || PostVisibility.PRIVATE,
        costDisplay: dto.costDisplay || CostDisplay.HIDDEN,
        actualCost: actualCost,
        costRangeMin: dto.costRangeMin,
        costRangeMax: dto.costRangeMax,
        durationDays: dto.durationDays,
        completedAt,
        isVerified,
      },
      include: this.postInclude,
    });
  }

  /**
   * Update a project post
   */
  async updatePost(postId: string, userId: string, dto: UpdateProjectPostDto) {
    const post = await this.prisma.projectPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.authorId !== userId) {
      throw new ForbiddenException('Not authorized to update this post');
    }

    return this.prisma.projectPost.update({
      where: { id: postId },
      data: {
        title: dto.title,
        description: dto.description,
        beforeImages: dto.beforeImages,
        afterImages: dto.afterImages,
        visibility: dto.visibility,
        costDisplay: dto.costDisplay,
        actualCost: dto.actualCost,
        costRangeMin: dto.costRangeMin,
        costRangeMax: dto.costRangeMax,
        durationDays: dto.durationDays,
      },
      include: this.postInclude,
    });
  }

  /**
   * Delete a project post
   */
  async deletePost(postId: string, userId: string) {
    const post = await this.prisma.projectPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    if (post.authorId !== userId) {
      throw new ForbiddenException('Not authorized to delete this post');
    }

    await this.prisma.projectPost.delete({
      where: { id: postId },
    });
  }

  /**
   * Get a single post by ID
   */
  async getPostById(postId: string, viewerId?: string) {
    const post = await this.prisma.projectPost.findUnique({
      where: { id: postId },
      include: this.postInclude,
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    // Add viewer-specific data
    let isLiked = false;
    let isSaved = false;

    if (viewerId) {
      const [like, save] = await Promise.all([
        this.prisma.projectLike.findUnique({
          where: { userId_postId: { userId: viewerId, postId } },
        }),
        this.prisma.savedPost.findUnique({
          where: { userId_postId: { userId: viewerId, postId } },
        }),
      ]);

      isLiked = !!like;
      isSaved = !!save;
    }

    return { ...post, isLiked, isSaved };
  }

  /**
   * Get posts by a specific user (their portfolio)
   */
  async getPostsByUser(userId: string, viewerId?: string, limit = 20, cursor?: string) {
    const posts = await this.prisma.projectPost.findMany({
      where: {
        authorId: userId,
        // Only show non-private posts unless viewing own profile
        ...(viewerId !== userId && {
          visibility: { not: PostVisibility.PRIVATE },
        }),
      },
      include: this.postInclude,
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    });

    const hasMore = posts.length > limit;
    if (hasMore) posts.pop();

    return {
      posts,
      hasMore,
      nextCursor: hasMore ? posts[posts.length - 1].id : null,
    };
  }

  /**
   * Like a post
   */
  async likePost(postId: string, userId: string) {
    const post = await this.prisma.projectPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    // Check if already liked
    const existing = await this.prisma.projectLike.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing) {
      throw new BadRequestException('Already liked this post');
    }

    await this.prisma.$transaction([
      this.prisma.projectLike.create({
        data: { userId, postId },
      }),
      this.prisma.projectPost.update({
        where: { id: postId },
        data: { likesCount: { increment: 1 } },
      }),
    ]);
  }

  /**
   * Unlike a post
   */
  async unlikePost(postId: string, userId: string) {
    const like = await this.prisma.projectLike.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (!like) {
      throw new NotFoundException('Like not found');
    }

    await this.prisma.$transaction([
      this.prisma.projectLike.delete({
        where: { id: like.id },
      }),
      this.prisma.projectPost.update({
        where: { id: postId },
        data: { likesCount: { decrement: 1 } },
      }),
    ]);
  }

  /**
   * Save/bookmark a post
   */
  async savePost(postId: string, userId: string) {
    const post = await this.prisma.projectPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    const existing = await this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (existing) {
      throw new BadRequestException('Already saved this post');
    }

    await this.prisma.$transaction([
      this.prisma.savedPost.create({
        data: { userId, postId },
      }),
      this.prisma.projectPost.update({
        where: { id: postId },
        data: { savesCount: { increment: 1 } },
      }),
    ]);
  }

  /**
   * Unsave a post
   */
  async unsavePost(postId: string, userId: string) {
    const save = await this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId, postId } },
    });

    if (!save) {
      throw new NotFoundException('Saved post not found');
    }

    await this.prisma.$transaction([
      this.prisma.savedPost.delete({
        where: { id: save.id },
      }),
      this.prisma.projectPost.update({
        where: { id: postId },
        data: { savesCount: { decrement: 1 } },
      }),
    ]);
  }

  /**
   * Get saved posts for a user
   */
  async getSavedPosts(userId: string, limit = 20, cursor?: string) {
    const saved = await this.prisma.savedPost.findMany({
      where: { userId },
      include: {
        post: {
          include: this.postInclude,
        },
      },
      orderBy: { createdAt: 'desc' },
      take: limit + 1,
      ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    });

    const hasMore = saved.length > limit;
    if (hasMore) saved.pop();

    return {
      posts: saved.map((s) => ({ ...s.post, isSaved: true })),
      hasMore,
      nextCursor: hasMore ? saved[saved.length - 1].id : null,
    };
  }

  /**
   * Add a comment to a post
   */
  async addComment(postId: string, userId: string, content: string) {
    const post = await this.prisma.projectPost.findUnique({
      where: { id: postId },
    });

    if (!post) {
      throw new NotFoundException('Post not found');
    }

    const [comment] = await this.prisma.$transaction([
      this.prisma.postComment.create({
        data: {
          postId,
          authorId: userId,
          content,
        },
        include: {
          author: {
            select: {
              id: true,
              displayName: true,
              avatarUrl: true,
            },
          },
        },
      }),
      this.prisma.projectPost.update({
        where: { id: postId },
        data: { commentsCount: { increment: 1 } },
      }),
    ]);

    // Notify post author (if not commenting on own post)
    if (post.authorId !== userId) {
      await this.prisma.inAppNotification.create({
        data: {
          userId: post.authorId,
          title: 'New Comment',
          body: 'Someone commented on your project',
          link: `/app/community/post/${postId}`,
        },
      });
    }

    return comment;
  }

  /**
   * Delete a comment
   */
  async deleteComment(commentId: string, userId: string) {
    const comment = await this.prisma.postComment.findUnique({
      where: { id: commentId },
      include: { post: { select: { authorId: true } } },
    });

    if (!comment) {
      throw new NotFoundException('Comment not found');
    }

    // Only comment author or post author can delete
    if (comment.authorId !== userId && comment.post.authorId !== userId) {
      throw new ForbiddenException('Not authorized to delete this comment');
    }

    await this.prisma.$transaction([
      this.prisma.postComment.delete({
        where: { id: commentId },
      }),
      this.prisma.projectPost.update({
        where: { id: comment.postId },
        data: { commentsCount: { decrement: 1 } },
      }),
    ]);
  }

  /**
   * Get comments for a post
   */
  async getComments(postId: string, limit = 20, cursor?: string) {
    const comments = await this.prisma.postComment.findMany({
      where: { postId },
      include: {
        author: {
          select: {
            id: true,
            displayName: true,
            avatarUrl: true,
            influencerBadges: true,
          },
        },
      },
      orderBy: { createdAt: 'asc' },
      take: limit + 1,
      ...(cursor && { cursor: { id: cursor }, skip: 1 }),
    });

    const hasMore = comments.length > limit;
    if (hasMore) comments.pop();

    return {
      comments,
      hasMore,
      nextCursor: hasMore ? comments[comments.length - 1].id : null,
    };
  }

  /**
   * Get user portfolio stats
   */
  async getPortfolioStats(userId: string) {
    const posts = await this.prisma.projectPost.findMany({
      where: { authorId: userId },
      select: { actualCost: true },
    });

    const totalValueAdded = posts.reduce(
      (sum, p) => sum + (p.actualCost ? Number(p.actualCost) : 0),
      0,
    );

    return {
      totalPosts: posts.length,
      totalValueAdded,
    };
  }
}

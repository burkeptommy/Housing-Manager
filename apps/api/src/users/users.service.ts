import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { User, UserRole } from '@prisma/client';
import { randomBytes } from 'crypto';

import { PrismaService } from '../prisma';
import { AuthPayload } from '../firebase';

import { UserDto, AdminUpdateUserDto, UserListQueryDto } from './dto';

export interface PaginatedUsers {
  data: UserDto[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

export interface UserProfile {
  id: string;
  email: string;
  displayName: string | null;
  firstName: string | null;
  lastName: string | null;
  avatarUrl: string | null;
  role: string;
  emailVerified: boolean;
  createdAt: Date;
}

export interface HouseholdInfo {
  id: string;
  name: string;
  description: string | null;
  subscriptionPlan: string;
  subscriptionStatus: string;
  billingCycleDay: number;
  role: string;
  hasProperty: boolean;
  propertyAddress?: string;
}

export interface MeResponse {
  user: UserProfile;
  household: HouseholdInfo | null;
  memberships: Array<{
    householdId: string;
    householdName: string;
    role: string;
    status: string;
  }>;
}

export interface InviteUserDto {
  email: string;
  role?: 'MEMBER' | 'GUEST';
}

export interface AcceptInviteDto {
  token: string;
}

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string): Promise<UserDto> {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return this.mapToDto(user);
  }

  async findMany(query: UserListQueryDto): Promise<PaginatedUsers> {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 20;
    const skip = (page - 1) * pageSize;

    const where: {
      role?: UserRole;
      OR?: Array<{ email?: { contains: string; mode: 'insensitive' }; firstName?: { contains: string; mode: 'insensitive' }; lastName?: { contains: string; mode: 'insensitive' } }>;
    } = {};

    if (query.role) {
      where.role = query.role;
    }

    if (query.search) {
      where.OR = [
        { email: { contains: query.search, mode: 'insensitive' } },
        { firstName: { contains: query.search, mode: 'insensitive' } },
        { lastName: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [users, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        skip,
        take: pageSize,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: users.map((user) => this.mapToDto(user)),
      total,
      page,
      pageSize,
      totalPages: Math.ceil(total / pageSize),
    };
  }

  async update(id: string, dto: AdminUpdateUserDto): Promise<UserDto> {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    const updatedUser = await this.prisma.user.update({
      where: { id },
      data: {
        ...(dto.firstName && { firstName: dto.firstName }),
        ...(dto.lastName && { lastName: dto.lastName }),
        ...(dto.phone !== undefined && { phone: dto.phone }),
        ...(dto.avatarUrl !== undefined && { avatarUrl: dto.avatarUrl }),
        ...(dto.email && { email: dto.email.toLowerCase() }),
        ...(dto.role && { role: dto.role }),
      },
    });

    return this.mapToDto(updatedUser);
  }

  async delete(id: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id },
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    await this.prisma.user.delete({
      where: { id },
    });
  }

  /**
   * Get current user profile with household info
   */
  async getMe(authPayload: AuthPayload): Promise<MeResponse> {
    const user = await this.prisma.user.findUnique({
      where: { id: authPayload.userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Get active memberships with household details
    const memberships = await this.prisma.householdMember.findMany({
      where: {
        userId: user.id,
        status: 'ACTIVE',
      },
      include: {
        household: {
          include: {
            homeProfile: true,
          },
        },
      },
      orderBy: {
        joinedAt: 'asc',
      },
    });

    // Get primary household (first active membership)
    const primaryMembership = memberships[0];

    let householdInfo: HouseholdInfo | null = null;
    if (primaryMembership) {
      const household = primaryMembership.household;
      const profile = household.homeProfile;

      householdInfo = {
        id: household.id,
        name: household.name,
        description: household.description,
        subscriptionPlan: household.subscriptionPlan,
        subscriptionStatus: household.subscriptionStatus,
        billingCycleDay: household.billingCycleDay,
        role: primaryMembership.role,
        hasProperty: !!profile,
        propertyAddress: profile
          ? `${profile.addressLine1}, ${profile.city}, ${profile.state} ${profile.postalCode}`
          : undefined,
      };
    }

    return {
      user: {
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        firstName: user.firstName,
        lastName: user.lastName,
        avatarUrl: user.avatarUrl,
        role: user.role,
        emailVerified: user.emailVerified,
        createdAt: user.createdAt,
      },
      household: householdInfo,
      memberships: memberships.map((m) => ({
        householdId: m.householdId,
        householdName: m.household.name,
        role: m.role,
        status: m.status,
      })),
    };
  }

  /**
   * Create a new household for the current user
   */
  async createHousehold(
    userId: string,
    data: { name: string; description?: string },
  ) {
    // Check if user already owns a household
    const existingOwnership = await this.prisma.householdMember.findFirst({
      where: {
        userId,
        role: 'OWNER',
        status: 'ACTIVE',
      },
    });

    if (existingOwnership) {
      throw new ConflictException('You already own a household');
    }

    // Create household with owner membership in transaction
    const result = await this.prisma.$transaction(async (tx) => {
      const household = await tx.household.create({
        data: {
          name: data.name,
          description: data.description,
          ownerId: userId,
        },
      });

      await tx.householdMember.create({
        data: {
          householdId: household.id,
          userId,
          role: 'OWNER',
          status: 'ACTIVE',
          joinedAt: new Date(),
          acceptedAt: new Date(),
        },
      });

      return household;
    });

    return result;
  }

  /**
   * Invite a user to the household by email
   */
  async inviteUser(
    authPayload: AuthPayload,
    householdId: string,
    dto: InviteUserDto,
  ) {
    // Verify user is OWNER of the household
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId,
          userId: authPayload.userId,
        },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You are not a member of this household');
    }

    if (membership.role !== 'OWNER' && authPayload.role !== 'ADMIN') {
      throw new ForbiddenException('Only household owners can invite members');
    }

    // Check if email is already a member
    const existingUser = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
      include: {
        householdMembers: {
          where: { householdId },
        },
      },
    });

    if (existingUser?.householdMembers.length) {
      throw new ConflictException('User is already a member of this household');
    }

    // Check for existing pending invite
    const existingInvite = await this.prisma.householdInvite.findFirst({
      where: {
        householdId,
        email: dto.email.toLowerCase(),
        acceptedAt: null,
        expiresAt: { gt: new Date() },
      },
    });

    if (existingInvite) {
      throw new ConflictException('An invite has already been sent to this email');
    }

    // Generate secure token
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 day expiry

    const invite = await this.prisma.householdInvite.create({
      data: {
        householdId,
        email: dto.email.toLowerCase(),
        token,
        role: dto.role || 'MEMBER',
        invitedById: authPayload.userId,
        expiresAt,
      },
      include: {
        household: {
          select: { name: true },
        },
        invitedBy: {
          select: { displayName: true, email: true },
        },
      },
    });

    this.logger.log(
      `Invite sent to ${dto.email} for household ${householdId} by user ${authPayload.userId}`,
    );

    // TODO: Send email notification with invite link
    // For now, return the token for testing
    return {
      success: true,
      message: `Invite sent to ${dto.email}`,
      inviteId: invite.id,
      // In production, don't return token - send via email
      token: invite.token,
      expiresAt: invite.expiresAt,
    };
  }

  /**
   * Accept a household invitation
   */
  async acceptInvite(authPayload: AuthPayload, dto: AcceptInviteDto) {
    const invite = await this.prisma.householdInvite.findUnique({
      where: { token: dto.token },
      include: {
        household: true,
      },
    });

    if (!invite) {
      throw new NotFoundException('Invalid invite token');
    }

    if (invite.acceptedAt) {
      throw new BadRequestException('This invite has already been used');
    }

    if (invite.expiresAt < new Date()) {
      throw new BadRequestException('This invite has expired');
    }

    // Check if user's email matches invite email
    const user = await this.prisma.user.findUnique({
      where: { id: authPayload.userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.email.toLowerCase() !== invite.email.toLowerCase()) {
      throw new ForbiddenException(
        'This invite was sent to a different email address',
      );
    }

    // Check if already a member
    const existingMembership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId: invite.householdId,
          userId: authPayload.userId,
        },
      },
    });

    if (existingMembership) {
      throw new ConflictException('You are already a member of this household');
    }

    // Accept invite and create membership in transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // Mark invite as accepted
      await tx.householdInvite.update({
        where: { id: invite.id },
        data: { acceptedAt: new Date() },
      });

      // Create membership
      const membership = await tx.householdMember.create({
        data: {
          householdId: invite.householdId,
          userId: authPayload.userId,
          role: invite.role,
          status: 'ACTIVE',
          invitedByUserId: invite.invitedById,
          acceptedAt: new Date(),
          joinedAt: new Date(),
        },
        include: {
          household: true,
        },
      });

      return membership;
    });

    this.logger.log(
      `User ${authPayload.userId} accepted invite to household ${invite.householdId}`,
    );

    return {
      success: true,
      message: `You have joined ${result.household.name}`,
      household: {
        id: result.household.id,
        name: result.household.name,
      },
      role: result.role,
    };
  }

  /**
   * Get pending invites for the current user's email
   */
  async getPendingInvites(email: string) {
    const invites = await this.prisma.householdInvite.findMany({
      where: {
        email: email.toLowerCase(),
        acceptedAt: null,
        expiresAt: { gt: new Date() },
      },
      include: {
        household: {
          select: { id: true, name: true },
        },
        invitedBy: {
          select: { displayName: true, email: true },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return invites.map((invite) => ({
      id: invite.id,
      token: invite.token,
      role: invite.role,
      expiresAt: invite.expiresAt,
      household: invite.household,
      invitedBy: invite.invitedBy,
      createdAt: invite.createdAt,
    }));
  }

  /**
   * Switch current household context
   */
  async switchHousehold(userId: string, householdId: string) {
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId,
          userId,
        },
      },
      include: {
        household: {
          include: {
            homeProfile: true,
          },
        },
      },
    });

    if (!membership || membership.status !== 'ACTIVE') {
      throw new ForbiddenException('You are not an active member of this household');
    }

    const household = membership.household;
    const profile = household.homeProfile;

    return {
      id: household.id,
      name: household.name,
      description: household.description,
      subscriptionPlan: household.subscriptionPlan,
      subscriptionStatus: household.subscriptionStatus,
      billingCycleDay: household.billingCycleDay,
      role: membership.role,
      hasProperty: !!profile,
      propertyAddress: profile
        ? `${profile.addressLine1}, ${profile.city}, ${profile.state} ${profile.postalCode}`
        : undefined,
    };
  }

  private mapToDto(user: User): UserDto {
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phone: user.phone,
      avatarUrl: user.avatarUrl,
      role: user.role,
      emailVerified: user.emailVerified,
      emailVerifiedAt: user.emailVerifiedAt,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }
}

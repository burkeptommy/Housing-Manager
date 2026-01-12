import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { HouseholdRole } from '@prisma/client';
import {
  CreateInvitationDto,
  InvitationResponseDto,
  PendingInvitationsDto,
} from './dto';
import { randomBytes } from 'crypto';

const INVITATION_EXPIRY_DAYS = 7;

@Injectable()
export class InvitationsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generate a unique invitation token
   */
  private generateToken(): string {
    return randomBytes(32).toString('hex');
  }

  /**
   * Create a new household invitation
   */
  async createInvitation(
    userId: string,
    dto: CreateInvitationDto,
  ): Promise<InvitationResponseDto> {
    // Get the user's primary household if not specified
    let householdId = dto.householdId;
    if (!householdId) {
      const membership = await this.prisma.householdMember.findFirst({
        where: { userId },
        select: { householdId: true },
      });
      if (!membership) {
        throw new BadRequestException('You are not a member of any household');
      }
      householdId = membership.householdId;
    }

    // Verify user has permission to invite to this household
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId,
          userId,
        },
      },
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this household');
    }

    // Only owners and admins can invite
    if (
      membership.role !== HouseholdRole.OWNER &&
      membership.role !== HouseholdRole.ADMIN
    ) {
      throw new ForbiddenException(
        'Only owners and admins can invite new members',
      );
    }

    // Check if user is already a member
    const existingMember = await this.prisma.householdMember.findFirst({
      where: {
        householdId,
        user: { email: dto.email },
      },
    });

    if (existingMember) {
      throw new BadRequestException(
        'This person is already a member of this household',
      );
    }

    // Check for existing pending invitation
    const existingInvite = await this.prisma.householdInvite.findFirst({
      where: {
        householdId,
        email: dto.email,
        acceptedAt: null,
        expiresAt: { gt: new Date() },
      },
    });

    if (existingInvite) {
      throw new BadRequestException(
        'An invitation has already been sent to this email',
      );
    }

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + INVITATION_EXPIRY_DAYS);

    const invitation = await this.prisma.householdInvite.create({
      data: {
        householdId,
        email: dto.email,
        token: this.generateToken(),
        role: dto.role || HouseholdRole.MEMBER,
        invitedById: userId,
        expiresAt,
      },
      include: {
        household: { select: { id: true, name: true } },
        invitedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
    });

    return this.mapToResponse(invitation);
  }

  /**
   * Get all invitations for a user (sent and received)
   */
  async getUserInvitations(userId: string): Promise<PendingInvitationsDto> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true },
    });

    if (!user) throw new NotFoundException('User not found');

    // Get sent invitations (from households user can manage)
    const memberships = await this.prisma.householdMember.findMany({
      where: { userId },
      select: { householdId: true },
    });

    const householdIds = memberships.map((m) => m.householdId);

    const sentInvitations = await this.prisma.householdInvite.findMany({
      where: {
        householdId: { in: householdIds },
        invitedById: userId,
      },
      include: {
        household: { select: { id: true, name: true } },
        invitedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    // Get received invitations (to user's email)
    const receivedInvitations = await this.prisma.householdInvite.findMany({
      where: {
        email: user.email,
        acceptedAt: null,
      },
      include: {
        household: { select: { id: true, name: true } },
        invitedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return {
      sent: sentInvitations.map(this.mapToResponse),
      received: receivedInvitations.map(this.mapToResponse),
    };
  }

  /**
   * Get pending invitations for a household
   */
  async getHouseholdInvitations(
    householdId: string,
    userId: string,
  ): Promise<InvitationResponseDto[]> {
    // Verify user has access
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId,
          userId,
        },
      },
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this household');
    }

    const invitations = await this.prisma.householdInvite.findMany({
      where: {
        householdId,
        acceptedAt: null,
      },
      include: {
        household: { select: { id: true, name: true } },
        invitedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return invitations.map(this.mapToResponse);
  }

  /**
   * Accept an invitation
   */
  async acceptInvitation(
    userId: string,
    token: string,
  ): Promise<{ householdId: string; householdName: string }> {
    const invitation = await this.prisma.householdInvite.findUnique({
      where: { token },
      include: { household: true },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.acceptedAt) {
      throw new BadRequestException('This invitation has already been accepted');
    }

    if (new Date() > invitation.expiresAt) {
      throw new BadRequestException('This invitation has expired');
    }

    // Verify the accepting user's email matches
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user || user.email.toLowerCase() !== invitation.email.toLowerCase()) {
      throw new ForbiddenException(
        'This invitation was sent to a different email address',
      );
    }

    // Check if already a member
    const existingMembership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId: invitation.householdId,
          userId,
        },
      },
    });

    if (existingMembership) {
      // Mark invitation as accepted but don't add duplicate member
      await this.prisma.householdInvite.update({
        where: { id: invitation.id },
        data: { acceptedAt: new Date() },
      });
      return {
        householdId: invitation.householdId,
        householdName: invitation.household.name,
      };
    }

    // Add user to household
    await this.prisma.$transaction([
      this.prisma.householdMember.create({
        data: {
          householdId: invitation.householdId,
          userId,
          role: invitation.role,
          invitedById: invitation.invitedById,
        },
      }),
      this.prisma.householdInvite.update({
        where: { id: invitation.id },
        data: { acceptedAt: new Date() },
      }),
    ]);

    return {
      householdId: invitation.householdId,
      householdName: invitation.household.name,
    };
  }

  /**
   * Get invitation by token (public for preview)
   */
  async getInvitationByToken(token: string): Promise<InvitationResponseDto | null> {
    const invitation = await this.prisma.householdInvite.findUnique({
      where: { token },
      include: {
        household: { select: { id: true, name: true } },
        invitedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
    });

    if (!invitation) return null;
    return this.mapToResponse(invitation);
  }

  /**
   * Cancel/revoke an invitation
   */
  async cancelInvitation(invitationId: string, userId: string): Promise<void> {
    const invitation = await this.prisma.householdInvite.findUnique({
      where: { id: invitationId },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    // Verify user has permission
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId: invitation.householdId,
          userId,
        },
      },
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this household');
    }

    // Only the inviter, owners, or admins can cancel
    if (
      invitation.invitedById !== userId &&
      membership.role !== HouseholdRole.OWNER &&
      membership.role !== HouseholdRole.ADMIN
    ) {
      throw new ForbiddenException(
        'You do not have permission to cancel this invitation',
      );
    }

    await this.prisma.householdInvite.delete({
      where: { id: invitationId },
    });
  }

  /**
   * Resend an invitation (generates new token and extends expiry)
   */
  async resendInvitation(
    invitationId: string,
    userId: string,
  ): Promise<InvitationResponseDto> {
    const invitation = await this.prisma.householdInvite.findUnique({
      where: { id: invitationId },
      include: {
        household: { select: { id: true, name: true } },
        invitedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
    });

    if (!invitation) {
      throw new NotFoundException('Invitation not found');
    }

    if (invitation.acceptedAt) {
      throw new BadRequestException('This invitation has already been accepted');
    }

    // Verify user has permission
    const membership = await this.prisma.householdMember.findUnique({
      where: {
        householdId_userId: {
          householdId: invitation.householdId,
          userId,
        },
      },
    });

    if (!membership) {
      throw new ForbiddenException('You are not a member of this household');
    }

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + INVITATION_EXPIRY_DAYS);

    const updated = await this.prisma.householdInvite.update({
      where: { id: invitationId },
      data: {
        token: this.generateToken(),
        expiresAt,
      },
      include: {
        household: { select: { id: true, name: true } },
        invitedBy: {
          select: { id: true, firstName: true, lastName: true, email: true },
        },
      },
    });

    return this.mapToResponse(updated);
  }

  private mapToResponse(invitation: {
    id: string;
    householdId: string;
    email: string;
    token: string;
    role: HouseholdRole;
    acceptedAt: Date | null;
    expiresAt: Date;
    createdAt: Date;
    household?: { id: string; name: string };
    invitedBy?: {
      id: string;
      firstName: string | null;
      lastName: string | null;
      email: string;
    };
  }): InvitationResponseDto {
    const now = new Date();
    return {
      id: invitation.id,
      householdId: invitation.householdId,
      email: invitation.email,
      role: invitation.role,
      token: invitation.token,
      acceptedAt: invitation.acceptedAt,
      expiresAt: invitation.expiresAt,
      createdAt: invitation.createdAt,
      household: invitation.household,
      invitedBy: invitation.invitedBy,
      isExpired: now > invitation.expiresAt,
      isAccepted: !!invitation.acceptedAt,
    };
  }
}

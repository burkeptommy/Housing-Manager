import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { FirebaseAuthGuard } from '../firebase';
import { InvitationsService } from './invitations.service';
import { CreateInvitationDto, AcceptInvitationDto, ResendInvitationDto } from './dto';

@ApiTags('invitations')
@Controller('invitations')
export class InvitationsController {
  constructor(private readonly invitationsService: InvitationsService) {}

  /**
   * Get all invitations for the current user (sent and received)
   */
  @Get()
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get all invitations (sent and received)' })
  async getInvitations(@Request() req: any) {
    const userId = req.user.userId || req.user.id;
    return this.invitationsService.getUserInvitations(userId);
  }

  /**
   * Get pending invitations for a household
   */
  @Get('household/:householdId')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get pending invitations for a household' })
  async getHouseholdInvitations(
    @Request() req: any,
    @Param('householdId') householdId: string,
  ) {
    const userId = req.user.userId || req.user.id;
    return this.invitationsService.getHouseholdInvitations(householdId, userId);
  }

  /**
   * Get invitation details by token (public for preview)
   */
  @Get('token/:token')
  @ApiOperation({ summary: 'Get invitation details by token' })
  async getInvitationByToken(@Param('token') token: string) {
    const invitation = await this.invitationsService.getInvitationByToken(token);
    if (!invitation) {
      return { valid: false };
    }
    return {
      valid: true,
      invitation: {
        householdName: invitation.household?.name,
        role: invitation.role,
        email: invitation.email,
        invitedBy: invitation.invitedBy
          ? `${invitation.invitedBy.firstName || ''} ${invitation.invitedBy.lastName || ''}`.trim()
          : null,
        isExpired: invitation.isExpired,
        isAccepted: invitation.isAccepted,
      },
    };
  }

  /**
   * Create a new household invitation
   */
  @Post()
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Invite someone to your household' })
  async createInvitation(@Request() req: any, @Body() dto: CreateInvitationDto) {
    const userId = req.user.userId || req.user.id;
    return this.invitationsService.createInvitation(userId, dto);
  }

  /**
   * Accept an invitation
   */
  @Post('accept')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Accept a household invitation' })
  async acceptInvitation(@Request() req: any, @Body() dto: AcceptInvitationDto) {
    const userId = req.user.userId || req.user.id;
    return this.invitationsService.acceptInvitation(userId, dto.token);
  }

  /**
   * Resend an invitation
   */
  @Post('resend')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Resend an invitation' })
  async resendInvitation(@Request() req: any, @Body() dto: ResendInvitationDto) {
    const userId = req.user.userId || req.user.id;
    return this.invitationsService.resendInvitation(dto.invitationId, userId);
  }

  /**
   * Cancel/revoke an invitation
   */
  @Delete(':id')
  @UseGuards(FirebaseAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel an invitation' })
  async cancelInvitation(@Request() req: any, @Param('id') id: string) {
    const userId = req.user.userId || req.user.id;
    await this.invitationsService.cancelInvitation(id, userId);
    return { success: true };
  }
}

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
  Req,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { RolesGuard } from '../auth/guards/roles.guard';
import {
  TripService,
  ProposalService,
  ItineraryService,
  VacationModeService,
} from './services';
import {
  AssignTripDto,
  CreateProposalDto,
  UpdateProposalDto,
  CreateItineraryItemDto,
  UpdateItineraryItemDto,
  LinkTransactionDto,
  AttachDocumentDto,
  AssignProtocolDto,
  ProtocolQueryDto,
  CompleteProtocolItemDto,
  CreateProtocolItemDto,
} from './dto';
import { TripStatus } from '@prisma/client';

@Controller('internal/travel')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles('ADMIN', 'MANAGER', 'HANDYMAN')
export class TravelInternalController {
  constructor(
    private readonly tripService: TripService,
    private readonly proposalService: ProposalService,
    private readonly itineraryService: ItineraryService,
    private readonly vacationModeService: VacationModeService,
  ) {}

  // ============================================================================
  // PIPELINE
  // ============================================================================

  @Get('pipeline')
  async getPipeline() {
    return this.tripService.getPipeline();
  }

  @Get('trips/:id')
  async getTrip(@Param('id') id: string) {
    return this.tripService.findOne(id);
  }

  @Patch('trips/:id/assign')
  async assignTrip(@Req() req: any, @Param('id') id: string, @Body() dto: AssignTripDto) {
    const managerId = dto.managerId || req.user.id;
    return this.tripService.assignManager(id, managerId);
  }

  @Patch('trips/:id/status')
  async updateTripStatus(
    @Param('id') id: string,
    @Body('status') status: TripStatus,
  ) {
    return this.tripService.updateStatus(id, status);
  }

  // ============================================================================
  // PROPOSALS
  // ============================================================================

  @Post('trips/:tripId/proposals')
  async createProposal(
    @Req() req: any,
    @Param('tripId') tripId: string,
    @Body() dto: CreateProposalDto,
  ) {
    return this.proposalService.create(tripId, req.user.id, dto);
  }

  @Patch('proposals/:id')
  async updateProposal(@Param('id') id: string, @Body() dto: UpdateProposalDto) {
    return this.proposalService.update(id, dto);
  }

  @Post('proposals/:id/send')
  async sendProposal(@Param('id') id: string) {
    return this.proposalService.send(id);
  }

  @Delete('proposals/:id')
  async deleteProposal(@Param('id') id: string) {
    return this.proposalService.remove(id);
  }

  // ============================================================================
  // ITINERARY
  // ============================================================================

  @Post('trips/:tripId/itinerary')
  async addItineraryItem(@Param('tripId') tripId: string, @Body() dto: CreateItineraryItemDto) {
    return this.itineraryService.create(tripId, dto);
  }

  @Patch('itinerary/:id')
  async updateItineraryItem(@Param('id') id: string, @Body() dto: UpdateItineraryItemDto) {
    return this.itineraryService.update(id, dto);
  }

  @Delete('itinerary/:id')
  async deleteItineraryItem(@Param('id') id: string) {
    return this.itineraryService.remove(id);
  }

  @Post('itinerary/:id/document')
  async attachDocument(@Param('id') id: string, @Body() dto: AttachDocumentDto) {
    return this.itineraryService.attachDocument(id, dto);
  }

  @Post('itinerary/:id/transaction')
  async linkTransaction(@Param('id') id: string, @Body() dto: LinkTransactionDto) {
    return this.itineraryService.linkToTransaction(id, dto.transactionId);
  }

  @Post('trips/:tripId/mark-booked')
  async markTripAsBooked(@Param('tripId') tripId: string) {
    return this.itineraryService.markTripAsBooked(tripId);
  }

  // ============================================================================
  // HOUSE PROTOCOL
  // ============================================================================

  @Get('protocols/pending')
  async getPendingProtocols(@Query() query: ProtocolQueryDto) {
    return this.vacationModeService.getPendingProtocols(query);
  }

  @Get('protocols/:id')
  async getProtocol(@Param('id') id: string) {
    return this.vacationModeService.findOne(id);
  }

  @Post('trips/:tripId/protocol/generate')
  async generateProtocol(@Param('tripId') tripId: string) {
    return this.vacationModeService.generateProtocol(tripId);
  }

  @Patch('protocols/:id/assign')
  async assignProtocol(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: AssignProtocolDto,
  ) {
    return this.vacationModeService.assign(id, dto, req.user.id);
  }

  @Post('protocols/:id/start')
  async startProtocol(@Param('id') id: string) {
    return this.vacationModeService.startProtocol(id);
  }

  @Post('protocols/:id/items/:itemId/complete')
  async completeProtocolItem(
    @Req() req: any,
    @Param('id') id: string,
    @Param('itemId') itemId: string,
    @Body() dto: CompleteProtocolItemDto,
  ) {
    return this.vacationModeService.completeItem(itemId, req.user.id, dto);
  }

  @Post('protocols/:id/items/:itemId/skip')
  async skipProtocolItem(
    @Req() req: any,
    @Param('id') id: string,
    @Param('itemId') itemId: string,
    @Body('reason') reason?: string,
  ) {
    return this.vacationModeService.skipItem(itemId, req.user.id, reason);
  }

  @Post('protocols/:id/items/:itemId/block')
  async blockProtocolItem(
    @Req() req: any,
    @Param('id') id: string,
    @Param('itemId') itemId: string,
    @Body('reason') reason: string,
  ) {
    return this.vacationModeService.blockItem(itemId, req.user.id, reason);
  }

  @Post('protocols/:id/items')
  async addProtocolItem(@Param('id') id: string, @Body() dto: CreateProtocolItemDto) {
    return this.vacationModeService.addItem(id, dto);
  }

  @Post('protocols/:id/complete')
  async completeProtocol(@Param('id') id: string) {
    // This would typically be called after all items are complete
    // The service will validate that all required items are done
    const protocol = await this.vacationModeService.findOne(id);
    const percentage = await this.vacationModeService.getCompletionPercentage(id);

    if (percentage < 100) {
      throw new Error('Not all items are complete');
    }

    return protocol;
  }
}

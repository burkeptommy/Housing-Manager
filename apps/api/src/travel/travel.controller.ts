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
import {
  TravelProfileService,
  TripService,
  ProposalService,
  ItineraryService,
  VacationModeService,
} from './services';
import {
  UpdateTravelProfileDto,
  CreateTripDto,
  UpdateTripDto,
  TripQueryDto,
  SelectProposalOptionDto,
} from './dto';

@Controller('travel')
@UseGuards(FirebaseAuthGuard)
export class TravelController {
  constructor(
    private readonly travelProfileService: TravelProfileService,
    private readonly tripService: TripService,
    private readonly proposalService: ProposalService,
    private readonly itineraryService: ItineraryService,
    private readonly vacationModeService: VacationModeService,
  ) {}

  // ============================================================================
  // TRAVEL PROFILE
  // ============================================================================

  @Get('profile')
  async getMyProfile(@Req() req: any) {
    return this.travelProfileService.getMyProfile(req.user.id, req.user.householdId);
  }

  @Patch('profile')
  async updateMyProfile(@Req() req: any, @Body() dto: UpdateTravelProfileDto) {
    return this.travelProfileService.updateMyProfile(req.user.id, req.user.householdId, dto);
  }

  @Get('profile/members')
  async getMemberProfiles(@Req() req: any) {
    return this.travelProfileService.findAllByHousehold(req.user.householdId);
  }

  // ============================================================================
  // TRIPS
  // ============================================================================

  @Post('trips')
  async createTrip(@Req() req: any, @Body() dto: CreateTripDto) {
    return this.tripService.create(req.user.householdId, req.user.id, dto);
  }

  @Get('trips')
  async getTrips(@Req() req: any, @Query() query: TripQueryDto) {
    return this.tripService.findAllByHousehold(req.user.householdId, query);
  }

  @Get('trips/upcoming')
  async getUpcomingTrips(@Req() req: any, @Query('limit') limit?: string) {
    return this.tripService.getUpcoming(req.user.householdId, limit ? parseInt(limit, 10) : 5);
  }

  @Get('trips/:id')
  async getTrip(@Req() req: any, @Param('id') id: string) {
    return this.tripService.findOne(id, req.user.householdId);
  }

  @Patch('trips/:id')
  async updateTrip(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateTripDto) {
    return this.tripService.update(id, req.user.householdId, dto);
  }

  @Delete('trips/:id')
  async cancelTrip(@Req() req: any, @Param('id') id: string) {
    return this.tripService.cancel(id, req.user.householdId);
  }

  // ============================================================================
  // PROPOSALS
  // ============================================================================

  @Get('trips/:tripId/proposals')
  async getTripProposals(@Req() req: any, @Param('tripId') tripId: string) {
    return this.proposalService.findByTrip(tripId, req.user.householdId);
  }

  @Get('proposals/pending')
  async getPendingProposals(@Req() req: any) {
    return this.proposalService.getPendingProposals(req.user.householdId);
  }

  @Post('proposals/:id/select')
  async selectProposalOption(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: SelectProposalOptionDto,
  ) {
    return this.proposalService.selectOption(id, req.user.id, dto);
  }

  // ============================================================================
  // ITINERARY
  // ============================================================================

  @Get('trips/:tripId/itinerary')
  async getTripItinerary(@Req() req: any, @Param('tripId') tripId: string) {
    return this.itineraryService.getTimeline(tripId, req.user.householdId);
  }

  @Get('trips/:tripId/documents')
  async getTripDocuments(@Req() req: any, @Param('tripId') tripId: string) {
    return this.itineraryService.getDocuments(tripId, req.user.householdId);
  }

  // ============================================================================
  // HOUSE PROTOCOL
  // ============================================================================

  @Get('trips/:tripId/protocol')
  async getTripProtocol(@Req() req: any, @Param('tripId') tripId: string) {
    return this.vacationModeService.findByTrip(tripId, req.user.householdId);
  }

  @Post('trips/:tripId/protocol/verify')
  async verifyProtocol(@Req() req: any, @Param('tripId') tripId: string) {
    const protocol = await this.vacationModeService.findByTrip(tripId, req.user.householdId);
    return this.vacationModeService.verify(protocol.id, req.user.id);
  }
}

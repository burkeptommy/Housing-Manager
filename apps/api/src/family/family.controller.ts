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
  Res,
  ParseBoolPipe,
  DefaultValuePipe,
  Headers,
} from '@nestjs/common';
import { Response } from 'express';
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
import { VehicleService, PetService, HomeSystemService, CalendarService } from './services';
import {
  CreateVehicleDto,
  UpdateVehicleDto,
  CreateVehicleServiceRecordDto,
  CreatePetDto,
  UpdatePetDto,
  CreatePetVetRecordDto,
  CreateHomeSystemDto,
  UpdateHomeSystemDto,
  CreateHomeSystemServiceDto,
  CreateFamilyEventDto,
  UpdateFamilyEventDto,
  CalendarFeedQueryDto,
  UpdateMemberProfileDto,
} from './dto';
import { PrismaService } from '../prisma/prisma.service';
import { FamilyEventCategory, HomeSystemType } from '@prisma/client';

@Controller('family')
export class FamilyController {
  constructor(
    private readonly vehicleService: VehicleService,
    private readonly petService: PetService,
    private readonly homeSystemService: HomeSystemService,
    private readonly calendarService: CalendarService,
    private readonly prisma: PrismaService,
  ) {}

  // ==================== VEHICLES ====================

  @UseGuards(FirebaseAuthGuard)
  @Post('vehicles')
  async createVehicle(@Req() req: any, @Body() dto: CreateVehicleDto) {
    return this.vehicleService.create(req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('vehicles')
  async getVehicles(
    @Req() req: any,
    @Query('includeInactive', new DefaultValuePipe(false), ParseBoolPipe) includeInactive: boolean,
  ) {
    return this.vehicleService.findAllByHousehold(req.user.householdId, includeInactive);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('vehicles/alerts')
  async getVehicleAlerts(@Req() req: any) {
    return this.vehicleService.getMaintenanceAlerts(req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('vehicles/:id')
  async getVehicle(@Req() req: any, @Param('id') id: string) {
    return this.vehicleService.findOne(id, req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('vehicles/:id')
  async updateVehicle(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateVehicleDto) {
    return this.vehicleService.update(id, req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('vehicles/:id')
  async deleteVehicle(@Req() req: any, @Param('id') id: string) {
    return this.vehicleService.remove(id, req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('vehicles/:id/service-records')
  async addVehicleServiceRecord(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: CreateVehicleServiceRecordDto,
  ) {
    return this.vehicleService.addServiceRecord(id, req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('vehicles/:id/service-records')
  async getVehicleServiceRecords(@Req() req: any, @Param('id') id: string) {
    return this.vehicleService.getServiceRecords(id, req.user.householdId);
  }

  // ==================== PETS ====================

  @UseGuards(FirebaseAuthGuard)
  @Post('pets')
  async createPet(@Req() req: any, @Body() dto: CreatePetDto) {
    return this.petService.create(req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('pets')
  async getPets(
    @Req() req: any,
    @Query('includeInactive', new DefaultValuePipe(false), ParseBoolPipe) includeInactive: boolean,
  ) {
    return this.petService.findAllByHousehold(req.user.householdId, includeInactive);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('pets/alerts')
  async getPetAlerts(@Req() req: any) {
    return this.petService.getCareAlerts(req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('pets/:id')
  async getPet(@Req() req: any, @Param('id') id: string) {
    return this.petService.findOne(id, req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('pets/:id/passport')
  async getPetPassport(@Req() req: any, @Param('id') id: string) {
    return this.petService.getPetPassport(id, req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('pets/:id')
  async updatePet(@Req() req: any, @Param('id') id: string, @Body() dto: UpdatePetDto) {
    return this.petService.update(id, req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('pets/:id')
  async deletePet(@Req() req: any, @Param('id') id: string) {
    return this.petService.remove(id, req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('pets/:id/vet-records')
  async addPetVetRecord(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: CreatePetVetRecordDto,
  ) {
    return this.petService.addVetRecord(id, req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('pets/:id/vet-records')
  async getPetVetRecords(@Req() req: any, @Param('id') id: string) {
    return this.petService.getVetRecords(id, req.user.householdId);
  }

  // ==================== HOME SYSTEMS ====================

  @UseGuards(FirebaseAuthGuard)
  @Post('home-systems')
  async createHomeSystem(@Req() req: any, @Body() dto: CreateHomeSystemDto) {
    return this.homeSystemService.create(req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('home-systems')
  async getHomeSystems(
    @Req() req: any,
    @Query('includeInactive', new DefaultValuePipe(false), ParseBoolPipe) includeInactive: boolean,
  ) {
    return this.homeSystemService.findAllByHousehold(req.user.householdId, includeInactive);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('home-systems/dashboard')
  async getHomeDashboard(@Req() req: any) {
    return this.homeSystemService.getHomeDashboard(req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('home-systems/alerts')
  async getHomeSystemAlerts(@Req() req: any) {
    return this.homeSystemService.getMaintenanceAlerts(req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('home-systems/type/:type')
  async getHomeSystemsByType(@Req() req: any, @Param('type') type: HomeSystemType) {
    return this.homeSystemService.findByType(req.user.householdId, type);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('home-systems/:id')
  async getHomeSystem(@Req() req: any, @Param('id') id: string) {
    return this.homeSystemService.findOne(id, req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('home-systems/:id')
  async updateHomeSystem(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateHomeSystemDto,
  ) {
    return this.homeSystemService.update(id, req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('home-systems/:id')
  async deleteHomeSystem(@Req() req: any, @Param('id') id: string) {
    return this.homeSystemService.remove(id, req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('home-systems/:id/tank-level')
  async updateTankLevel(
    @Req() req: any,
    @Param('id') id: string,
    @Body('level') level: number,
  ) {
    return this.homeSystemService.updateTankLevel(id, req.user.householdId, level);
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('home-systems/:id/service-records')
  async addHomeSystemServiceRecord(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: CreateHomeSystemServiceDto,
  ) {
    return this.homeSystemService.addServiceRecord(id, req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('home-systems/:id/service-records')
  async getHomeSystemServiceRecords(@Req() req: any, @Param('id') id: string) {
    return this.homeSystemService.getServiceRecords(id, req.user.householdId);
  }

  // ==================== CALENDAR & EVENTS ====================

  @UseGuards(FirebaseAuthGuard)
  @Post('events')
  async createEvent(@Req() req: any, @Body() dto: CreateFamilyEventDto) {
    return this.calendarService.create(req.user.householdId, req.user.id, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('events')
  async getEvents(
    @Req() req: any,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('categories') categories?: string,
    @Query('memberId') memberId?: string,
  ) {
    const parsedCategories = categories
      ? (categories.split(',') as FamilyEventCategory[])
      : undefined;
    return this.calendarService.findAllByHousehold(
      req.user.householdId,
      startDate ? new Date(startDate) : undefined,
      endDate ? new Date(endDate) : undefined,
      parsedCategories,
      memberId,
    );
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('events/upcoming')
  async getUpcomingEvents(
    @Req() req: any,
    @Query('limit', new DefaultValuePipe(10)) limit: number,
  ) {
    return this.calendarService.getUpcoming(req.user.householdId, limit);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('calendar')
  async getUnifiedCalendar(
    @Req() req: any,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Query('includeMaintenance', new DefaultValuePipe(true), ParseBoolPipe) includeMaintenance: boolean,
  ) {
    return this.calendarService.getUnifiedCalendar(
      req.user.householdId,
      new Date(startDate),
      new Date(endDate),
      includeMaintenance,
    );
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('calendar/summary')
  async getCalendarSummary(@Req() req: any) {
    return this.calendarService.getCalendarSummary(req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('calendar/feed-url')
  async getCalendarFeedUrl(@Req() req: any, @Headers('host') host: string) {
    const protocol = process.env.NODE_ENV === 'production' ? 'https' : 'http';
    const baseUrl = `${protocol}://${host}`;
    return {
      url: this.calendarService.getFeedUrl(req.user.householdId, baseUrl),
    };
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('events/:id')
  async getEvent(@Req() req: any, @Param('id') id: string) {
    return this.calendarService.findOne(id, req.user.householdId);
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('events/:id')
  async updateEvent(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateFamilyEventDto,
  ) {
    return this.calendarService.update(id, req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('events/:id')
  async deleteEvent(@Req() req: any, @Param('id') id: string) {
    return this.calendarService.remove(id, req.user.householdId);
  }

  // Public iCal feed endpoint (no auth - uses token in URL)
  @Get('calendar/:householdId/feed/:token.ics')
  async getICalFeed(
    @Param('householdId') householdId: string,
    @Param('token') token: string,
    @Query() query: CalendarFeedQueryDto,
    @Res() res: Response,
  ) {
    const icalContent = await this.calendarService.generateICalFeed(householdId, token, query);

    res.set({
      'Content-Type': 'text/calendar; charset=utf-8',
      'Content-Disposition': 'attachment; filename="haven-calendar.ics"',
    });
    res.send(icalContent);
  }

  // ==================== MEMBERS ====================

  @UseGuards(FirebaseAuthGuard)
  @Get('members')
  async getMembers(@Req() req: any) {
    return this.prisma.householdMember.findMany({
      where: {
        householdId: req.user.householdId,
        status: 'ACTIVE',
      },
      include: {
        user: {
          select: { id: true, email: true, displayName: true, avatarUrl: true },
        },
      },
      orderBy: { user: { displayName: 'asc' } },
    });
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('members/:id')
  async getMember(@Req() req: any, @Param('id') id: string) {
    const member = await this.prisma.householdMember.findUnique({
      where: { id },
      include: {
        user: {
          select: { id: true, email: true, displayName: true, avatarUrl: true },
        },
      },
    });

    if (!member || member.householdId !== req.user.householdId) {
      throw new Error('Member not found');
    }

    // Fetch assigned events separately
    const assignedEvents = await this.prisma.familyEvent.findMany({
      where: {
        assignedToMemberId: id,
        startDate: { gte: new Date() },
      },
      orderBy: { startDate: 'asc' },
      take: 10,
    });

    return { ...member, assignedEvents };
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('members/:id/profile')
  async updateMemberProfile(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: UpdateMemberProfileDto,
  ) {
    const member = await this.prisma.householdMember.findUnique({
      where: { id },
    });

    if (!member || member.householdId !== req.user.householdId) {
      throw new Error('Member not found');
    }

    // Update individual profile fields
    return this.prisma.householdMember.update({
      where: { id },
      data: {
        birthday: dto.birthday ? new Date(dto.birthday) : undefined,
        shirtSize: dto.shirtSize,
        dietaryRestrictions: dto.dietaryRestrictions,
        allergies: dto.allergies,
        medicalNotes: dto.medicalNotes,
      },
    });
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('members/:id/permissions')
  async updateMemberPermissions(
    @Req() req: any,
    @Param('id') id: string,
    @Body('permissions') permissions: string[],
  ) {
    const member = await this.prisma.householdMember.findUnique({
      where: { id },
    });

    if (!member || member.householdId !== req.user.householdId) {
      throw new Error('Member not found');
    }

    // Only owner can update permissions
    const currentUserMember = await this.prisma.householdMember.findFirst({
      where: {
        householdId: req.user.householdId,
        userId: req.user.id,
      },
    });

    if (currentUserMember?.role !== 'OWNER') {
      throw new Error('Only household owner can update permissions');
    }

    // Cast permissions to the expected type
    return this.prisma.householdMember.update({
      where: { id },
      data: { permissions: permissions as any },
    });
  }

  // ==================== AGGREGATED ALERTS ====================

  @UseGuards(FirebaseAuthGuard)
  @Get('alerts')
  async getAllAlerts(@Req() req: any) {
    const [vehicleAlerts, petAlerts, homeAlerts] = await Promise.all([
      this.vehicleService.getMaintenanceAlerts(req.user.householdId),
      this.petService.getCareAlerts(req.user.householdId),
      this.homeSystemService.getMaintenanceAlerts(req.user.householdId),
    ]);

    return {
      vehicles: vehicleAlerts,
      pets: petAlerts,
      homeSystems: homeAlerts,
      total: vehicleAlerts.length + petAlerts.length + homeAlerts.length,
    };
  }
}

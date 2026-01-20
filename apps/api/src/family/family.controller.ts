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
import { VehicleService, PetService, HomeSystemService, CalendarService, VehicleMaintenanceResearchService } from './services';
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
  CreateFamilyMemberDto,
  UpdateFamilyMemberDto,
  CreateActivityDto,
  UpdateActivityDto,
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
    private readonly vehicleMaintenanceResearchService: VehicleMaintenanceResearchService,
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

  @UseGuards(FirebaseAuthGuard)
  @Get('vehicles/:id/maintenance-due')
  async getVehicleMaintenanceDue(@Req() req: any, @Param('id') id: string) {
    // Verify user has access to this vehicle
    await this.vehicleService.findOne(id, req.user.householdId);
    return this.vehicleMaintenanceResearchService.getMaintenanceDue(id);
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('vehicles/:id/refresh-maintenance-research')
  async refreshVehicleMaintenanceResearch(@Req() req: any, @Param('id') id: string) {
    // Verify user has access to this vehicle
    await this.vehicleService.findOne(id, req.user.householdId);
    return this.vehicleMaintenanceResearchService.refreshMaintenanceResearch(id);
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

  @UseGuards(FirebaseAuthGuard)
  @Post('pets/:id/vaccinations')
  async addPetVaccination(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: {
      name: string;
      date: string;
      expiresAt?: string | null;
      veterinarian?: string | null;
      batchNumber?: string | null;
      notes?: string | null;
    },
  ) {
    return this.petService.addVaccination(id, req.user.householdId, dto);
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('pets/:id/medications')
  async addPetMedication(
    @Req() req: any,
    @Param('id') id: string,
    @Body() dto: {
      name: string;
      dosage: string;
      frequency: string;
      prescribedBy?: string | null;
      startDate?: string | null;
      endDate?: string | null;
      reason?: string | null;
      notes?: string | null;
    },
  ) {
    return this.petService.addMedication(id, req.user.householdId, dto);
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

  // ==================== HOUSEHOLD FAMILY DATA ====================

  @UseGuards(FirebaseAuthGuard)
  @Get('household/:householdId/member/:memberId')
  async getHouseholdFamilyMember(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('memberId') memberId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    // Get the family member with activities
    const familyMember = await this.prisma.familyMember.findUnique({
      where: { id: memberId },
      include: {
        activities: true,
      },
    });

    if (!familyMember || familyMember.householdId !== householdId) {
      throw new Error('Family member not found');
    }

    // Calculate age if birthdate exists
    const age = familyMember.birthdate
      ? Math.floor(
          (Date.now() - familyMember.birthdate.getTime()) /
            (365.25 * 24 * 60 * 60 * 1000),
        )
      : null;

    return {
      id: familyMember.id,
      firstName: familyMember.firstName,
      lastName: familyMember.lastName,
      nickname: familyMember.nickname,
      relationship: familyMember.relationship,
      email: familyMember.email,
      phone: familyMember.phone,
      birthDate: familyMember.birthdate?.toISOString() || null,
      age,
      school: familyMember.school,
      schoolGrade: familyMember.schoolGrade,
      teacher: familyMember.teacher,
      activities:
        familyMember.activities?.map((a) => ({
          id: a.id,
          name: a.name,
          category: a.category,
          schedule: a.schedule,
          location: a.location,
        })) || [],
      workSchedule: familyMember.workSchedule,
      type: familyMember.type,
      // Work info
      occupation: (familyMember as any).occupation,
      employer: (familyMember as any).employer,
      workPhone: (familyMember as any).workPhone,
      workAddress: (familyMember as any).workAddress,
      // Medical Information
      primaryDoctorName: (familyMember as any).primaryDoctorName,
      primaryDoctorPhone: (familyMember as any).primaryDoctorPhone,
      primaryDoctorAddress: (familyMember as any).primaryDoctorAddress,
      dentistName: (familyMember as any).dentistName,
      dentistPhone: (familyMember as any).dentistPhone,
      dentistAddress: (familyMember as any).dentistAddress,
      bloodType: (familyMember as any).bloodType,
      allergies: familyMember.allergies,
      medications: familyMember.medications,
      specialNeeds: familyMember.specialNeeds,
      medicalNotes: (familyMember as any).medicalNotes,
      // Emergency contacts
      emergencyContact: familyMember.emergencyContact,
      emergencyContactPhone: familyMember.emergencyContactPhone,
    };
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('household/:householdId/member/:memberId')
  async deleteHouseholdFamilyMember(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('memberId') memberId: string,
  ) {
    // Check if user is system admin
    const isSystemAdmin =
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    // Check household membership and role
    const membership = await this.prisma.householdMember.findFirst({
      where: {
        householdId,
        userId: req.user.id,
        status: 'ACTIVE',
      },
    });

    if (!membership && !isSystemAdmin) {
      throw new Error('Access denied to this household');
    }

    // Only OWNER can delete family members
    const isOwner = membership?.role === 'OWNER';
    if (!isSystemAdmin && !isOwner) {
      throw new Error('Only the household owner can remove family members');
    }

    // Verify the family member exists and belongs to this household
    const familyMember = await this.prisma.familyMember.findUnique({
      where: { id: memberId },
    });

    if (!familyMember || familyMember.householdId !== householdId) {
      throw new Error('Family member not found');
    }

    // Delete the family member
    await this.prisma.familyMember.delete({
      where: { id: memberId },
    });

    return { success: true, message: 'Family member removed' };
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('household/:householdId/members')
  async createHouseholdFamilyMember(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Body() dto: CreateFamilyMemberDto,
  ) {
    // Check if user is system admin
    const isSystemAdmin =
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    // Check household membership and role
    const membership = await this.prisma.householdMember.findFirst({
      where: {
        householdId,
        userId: req.user.id,
        status: 'ACTIVE',
      },
    });

    if (!membership && !isSystemAdmin) {
      throw new Error('Access denied to this household');
    }

    // Only OWNER can add new family members
    const isOwner = membership?.role === 'OWNER';
    if (!isSystemAdmin && !isOwner) {
      throw new Error('Only the household owner can add family members');
    }

    // Create the family member
    const familyMember = await this.prisma.familyMember.create({
      data: {
        householdId,
        firstName: dto.firstName,
        lastName: dto.lastName,
        nickname: dto.nickname,
        type: dto.type,
        relationship: dto.relationship,
        email: dto.email,
        phone: dto.phone,
        birthdate: dto.birthdate,
        school: dto.school,
        schoolGrade: dto.schoolGrade,
        teacher: dto.teacher,
        schoolPickup: dto.schoolPickup,
        schoolDropoff: dto.schoolDropoff,
        workSchedule: dto.workSchedule,
        responsibilities: dto.responsibilities,
        startDate: dto.startDate,
        paymentMethod: dto.paymentMethod,
        allergies: dto.allergies,
        medications: dto.medications,
        specialNeeds: dto.specialNeeds,
        emergencyContact: dto.emergencyContact,
        emergencyContactPhone: dto.emergencyContactPhone,
        photoUrl: dto.photoUrl,
        notes: dto.notes,
      },
    });

    return familyMember;
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('household/:householdId/member/:memberId')
  async updateHouseholdFamilyMember(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('memberId') memberId: string,
    @Body() dto: UpdateFamilyMemberDto,
  ) {
    // Get current user info
    const currentUser = await this.prisma.user.findUnique({
      where: { id: req.user.id },
      select: { email: true },
    });

    // Check if user is system admin
    const isSystemAdmin =
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    // Check household membership and role
    const membership = await this.prisma.householdMember.findFirst({
      where: {
        householdId,
        userId: req.user.id,
        status: 'ACTIVE',
      },
    });

    if (!membership && !isSystemAdmin) {
      throw new Error('Access denied to this household');
    }

    const isOwner = membership?.role === 'OWNER';

    // Verify the family member exists and belongs to this household
    const existingMember = await this.prisma.familyMember.findUnique({
      where: { id: memberId },
    });

    if (!existingMember || existingMember.householdId !== householdId) {
      throw new Error('Family member not found');
    }

    // Permission check: Only OWNER can edit any family member
    // Regular members can only edit their own FamilyMember record (matched by email)
    const isOwnProfile =
      currentUser?.email &&
      existingMember.email &&
      currentUser.email.toLowerCase() === existingMember.email.toLowerCase();

    if (!isSystemAdmin && !isOwner && !isOwnProfile) {
      throw new Error('You can only edit your own profile. Contact the household owner to edit other family members.');
    }

    // Update the family member
    const familyMember = await this.prisma.familyMember.update({
      where: { id: memberId },
      data: {
        firstName: dto.firstName,
        lastName: dto.lastName,
        nickname: dto.nickname,
        type: dto.type,
        relationship: dto.relationship,
        email: dto.email,
        phone: dto.phone,
        birthdate: dto.birthdate,
        school: dto.school,
        schoolGrade: dto.schoolGrade,
        teacher: dto.teacher,
        schoolPickup: dto.schoolPickup,
        schoolDropoff: dto.schoolDropoff,
        workSchedule: dto.workSchedule,
        responsibilities: dto.responsibilities,
        startDate: dto.startDate,
        paymentMethod: dto.paymentMethod,
        allergies: dto.allergies,
        medications: dto.medications,
        specialNeeds: dto.specialNeeds,
        emergencyContact: dto.emergencyContact,
        emergencyContactPhone: dto.emergencyContactPhone,
        photoUrl: dto.photoUrl,
        notes: dto.notes,
      },
    });

    // If updating name and this member has a linked User account, update User record too
    if ((dto.firstName || dto.lastName || dto.phone || dto.photoUrl) && existingMember.email) {
      await this.prisma.user.updateMany({
        where: { email: existingMember.email.toLowerCase() },
        data: {
          ...(dto.firstName && { firstName: dto.firstName }),
          ...(dto.lastName && { lastName: dto.lastName }),
          ...(dto.phone !== undefined && { phone: dto.phone }),
          ...(dto.photoUrl !== undefined && { avatarUrl: dto.photoUrl }),
        },
      });
    }

    return familyMember;
  }

  // ==================== ACTIVITIES/MEMBERSHIPS ====================

  @UseGuards(FirebaseAuthGuard)
  @Get('household/:householdId/activities')
  async getHouseholdActivities(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Query('memberId') memberId?: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    const where: any = { householdId };
    if (memberId) {
      where.familyMemberId = memberId;
    }

    const activities = await this.prisma.kidActivity.findMany({
      where,
      include: {
        familyMember: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
      orderBy: { name: 'asc' },
    });

    return activities;
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('household/:householdId/activities')
  async createHouseholdActivity(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Body() dto: CreateActivityDto,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    // Create the activity
    const activity = await this.prisma.kidActivity.create({
      data: {
        householdId,
        familyMemberId: dto.familyMemberId,
        name: dto.name,
        type: dto.type,
        organization: dto.organization,
        location: dto.location,
        schedule: dto.schedule,
        cost: dto.cost,
        costFrequency: dto.costFrequency,
        registrationFee: dto.registrationFee,
        equipmentCost: dto.equipmentCost,
        coachName: dto.coachName,
        contactPhone: dto.contactPhone,
        contactEmail: dto.contactEmail,
        paymentMethod: dto.paymentMethod,
        accountNumber: dto.accountNumber,
        portalUrl: dto.portalUrl,
        notes: dto.notes,
      },
    });

    return activity;
  }

  @UseGuards(FirebaseAuthGuard)
  @Get('household/:householdId/activity/:activityId')
  async getHouseholdActivity(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('activityId') activityId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    const activity = await this.prisma.kidActivity.findUnique({
      where: { id: activityId },
      include: {
        familyMember: {
          select: { id: true, firstName: true, lastName: true },
        },
      },
    });

    if (!activity || activity.householdId !== householdId) {
      throw new Error('Activity not found');
    }

    return activity;
  }

  @UseGuards(FirebaseAuthGuard)
  @Patch('household/:householdId/activity/:activityId')
  async updateHouseholdActivity(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('activityId') activityId: string,
    @Body() dto: UpdateActivityDto,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    // Verify the activity exists and belongs to this household
    const existingActivity = await this.prisma.kidActivity.findUnique({
      where: { id: activityId },
    });

    if (!existingActivity || existingActivity.householdId !== householdId) {
      throw new Error('Activity not found');
    }

    // Update the activity
    const activity = await this.prisma.kidActivity.update({
      where: { id: activityId },
      data: {
        name: dto.name,
        type: dto.type,
        organization: dto.organization,
        location: dto.location,
        schedule: dto.schedule,
        cost: dto.cost,
        costFrequency: dto.costFrequency,
        registrationFee: dto.registrationFee,
        equipmentCost: dto.equipmentCost,
        coachName: dto.coachName,
        contactPhone: dto.contactPhone,
        contactEmail: dto.contactEmail,
        paymentMethod: dto.paymentMethod,
        accountNumber: dto.accountNumber,
        portalUrl: dto.portalUrl,
        notes: dto.notes,
        familyMemberId: dto.familyMemberId,
      },
    });

    return activity;
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('household/:householdId/activity/:activityId')
  async deleteHouseholdActivity(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('activityId') activityId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    // Verify the activity exists and belongs to this household
    const activity = await this.prisma.kidActivity.findUnique({
      where: { id: activityId },
    });

    if (!activity || activity.householdId !== householdId) {
      throw new Error('Activity not found');
    }

    // Delete the activity
    await this.prisma.kidActivity.delete({
      where: { id: activityId },
    });

    return { success: true, message: 'Activity removed' };
  }

  // ==================== HOUSEHOLD VEHICLE ENDPOINTS ====================

  @UseGuards(FirebaseAuthGuard)
  @Get('household/:householdId/vehicle/:vehicleId')
  async getHouseholdVehicle(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('vehicleId') vehicleId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
    });

    if (!vehicle || vehicle.householdId !== householdId) {
      throw new Error('Vehicle not found');
    }

    return vehicle;
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('household/:householdId/vehicle/:vehicleId')
  async deleteHouseholdVehicle(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('vehicleId') vehicleId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
    });

    if (!vehicle || vehicle.householdId !== householdId) {
      throw new Error('Vehicle not found');
    }

    await this.prisma.vehicle.delete({
      where: { id: vehicleId },
    });

    return { success: true, message: 'Vehicle removed' };
  }

  // ==================== HOUSEHOLD PET ENDPOINTS ====================

  @UseGuards(FirebaseAuthGuard)
  @Get('household/:householdId/pet/:petId')
  async getHouseholdPet(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('petId') petId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    const pet = await this.prisma.pet.findUnique({
      where: { id: petId },
      include: {
        vetRecords: {
          orderBy: { visitDate: 'desc' },
          take: 1,
        },
      },
    });

    if (!pet || pet.householdId !== householdId) {
      throw new Error('Pet not found');
    }

    // Get the most recent vet record for lastVetVisit
    const lastVetRecord = pet.vetRecords?.[0];

    // Format response to match mobile app expectations
    return {
      id: pet.id,
      name: pet.name,
      type: pet.type,
      breed: pet.breed,
      color: pet.color,
      age: pet.birthday ? Math.floor((Date.now() - pet.birthday.getTime()) / (365.25 * 24 * 60 * 60 * 1000)) : null,
      weight: pet.weight ? Number(pet.weight) : null,
      birthDate: pet.birthday?.toISOString() || null,
      microchipId: pet.microchipId,
      vetName: pet.primaryVetName || pet.vetClinicName,
      vetPhone: pet.vetClinicPhone,
      lastVetVisit: lastVetRecord?.visitDate?.toISOString() || null,
      nextVetVisit: lastVetRecord?.followUpDate?.toISOString() || null,
      medications: pet.medications,
      allergies: pet.allergies,
      notes: pet.notes,
    };
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('household/:householdId/pet/:petId')
  async deleteHouseholdPet(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('petId') petId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    const pet = await this.prisma.pet.findUnique({
      where: { id: petId },
    });

    if (!pet || pet.householdId !== householdId) {
      throw new Error('Pet not found');
    }

    await this.prisma.pet.delete({
      where: { id: petId },
    });

    return { success: true, message: 'Pet removed' };
  }

  // ==================== HOUSEHOLD STAFF ENDPOINTS ====================

  @UseGuards(FirebaseAuthGuard)
  @Get('household/:householdId/staff/:staffId')
  async getHouseholdStaff(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('staffId') staffId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    // Staff is stored as FamilyMember with type STAFF
    const staff = await this.prisma.familyMember.findUnique({
      where: { id: staffId },
    });

    if (!staff || staff.householdId !== householdId || staff.type !== 'STAFF') {
      throw new Error('Staff member not found');
    }

    return {
      id: staff.id,
      firstName: staff.firstName,
      lastName: staff.lastName,
      relationship: staff.relationship,
      phone: staff.phone,
      email: staff.email,
      workSchedule: staff.workSchedule,
      startDate: staff.startDate?.toISOString() || null,
      notes: staff.notes,
      emergencyContact: staff.emergencyContact ? true : false,
    };
  }

  @UseGuards(FirebaseAuthGuard)
  @Delete('household/:householdId/staff/:staffId')
  async deleteHouseholdStaff(
    @Req() req: any,
    @Param('householdId') householdId: string,
    @Param('staffId') staffId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    const staff = await this.prisma.familyMember.findUnique({
      where: { id: staffId },
    });

    if (!staff || staff.householdId !== householdId || staff.type !== 'STAFF') {
      throw new Error('Staff member not found');
    }

    await this.prisma.familyMember.delete({
      where: { id: staffId },
    });

    return { success: true, message: 'Staff member removed' };
  }

  // ==================== HOUSEHOLD FAMILY LIST ====================

  @UseGuards(FirebaseAuthGuard)
  @Get('household/:householdId')
  async getHouseholdFamily(
    @Req() req: any,
    @Param('householdId') householdId: string,
  ) {
    // Verify user has access to this household
    const userHasAccess =
      req.user.householdId === householdId ||
      req.user.role === 'ADMIN' ||
      req.user.role === 'HOME_MANAGER' ||
      req.user.role === 'MANAGER';

    if (!userHasAccess) {
      // Check if user is a member of the household
      const membership = await this.prisma.householdMember.findFirst({
        where: {
          householdId,
          userId: req.user.id,
          status: 'ACTIVE',
        },
      });

      if (!membership) {
        throw new Error('Access denied to this household');
      }
    }

    // Get family members
    const familyMembers = await this.prisma.familyMember.findMany({
      where: { householdId },
      include: {
        activities: true,
      },
      orderBy: [{ type: 'asc' }, { firstName: 'asc' }],
    });

    // Get pets
    const pets = await this.prisma.pet.findMany({
      where: { householdId },
      orderBy: { name: 'asc' },
    });

    // Get vehicles
    const vehicles = await this.prisma.vehicle.findMany({
      where: { householdId, isActive: true },
      orderBy: { name: 'asc' },
    });

    // Organize by type
    const adults = familyMembers
      .filter(m => m.type === 'ADULT')
      .map(m => ({
        id: m.id,
        firstName: m.firstName,
        lastName: m.lastName,
        nickname: m.nickname,
        relationship: m.relationship,
        email: m.email,
        phone: m.phone,
      }));

    const children = familyMembers
      .filter(m => m.type === 'CHILD')
      .map(m => ({
        id: m.id,
        firstName: m.firstName,
        lastName: m.lastName,
        nickname: m.nickname,
        age: m.birthdate ? Math.floor((Date.now() - m.birthdate.getTime()) / (365.25 * 24 * 60 * 60 * 1000)) : null,
        school: m.school,
        schoolGrade: m.schoolGrade,
        activities: m.activities?.map(a => ({
          id: a.id,
          name: a.name,
          type: a.category,
          schedule: a.schedule,
        })) || [],
      }));

    const staff = familyMembers
      .filter(m => m.type === 'STAFF')
      .map(m => ({
        id: m.id,
        firstName: m.firstName,
        lastName: m.lastName,
        relationship: m.relationship,
        phone: m.phone,
        workSchedule: m.workSchedule,
      }));

    return {
      adults,
      children,
      staff,
      pets: pets.map(p => ({
        id: p.id,
        name: p.name,
        type: p.type,
        breed: p.breed,
        color: p.color,
        age: p.birthday ? Math.floor((Date.now() - p.birthday.getTime()) / (365.25 * 24 * 60 * 60 * 1000)) : null,
      })),
      vehicles: vehicles.map(v => ({
        id: v.id,
        name: v.name,
        year: v.year,
        make: v.make,
        model: v.model,
        color: v.color,
        licensePlate: v.licensePlate,
      })),
    };
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

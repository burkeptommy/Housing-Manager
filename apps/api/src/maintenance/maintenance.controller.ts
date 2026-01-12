import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  UseGuards,
  Request,
} from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase/firebase-auth.guard';
import { MaintenanceService } from './maintenance.service';
import { MaintenanceGeneratorService } from './maintenance-generator.service';
import { MaintenanceTaskStatus, MaintenanceCategory } from '@prisma/client';

@Controller('maintenance')
@UseGuards(FirebaseAuthGuard)
export class MaintenanceController {
  constructor(
    private maintenanceService: MaintenanceService,
    private generatorService: MaintenanceGeneratorService,
  ) {}

  /**
   * Get all checklist templates
   */
  @Get('templates')
  getTemplates() {
    return this.maintenanceService.getTemplates();
  }

  /**
   * Get a single maintenance task with full details
   */
  @Get(':taskId')
  async getTask(@Param('taskId') taskId: string) {
    return this.maintenanceService.getTask(taskId);
  }

  @Get('household/:householdId')
  async getHouseholdTasks(
    @Param('householdId') householdId: string,
    @Query('status') status?: MaintenanceTaskStatus,
    @Query('category') category?: MaintenanceCategory,
  ) {
    return this.maintenanceService.getHouseholdTasks(householdId, {
      status,
      category,
    });
  }

  @Get('household/:householdId/calendar')
  async getTaskCalendar(@Param('householdId') householdId: string) {
    return this.maintenanceService.getTaskCalendar(householdId);
  }

  @Get('household/:householdId/summary')
  async getTaskSummary(@Param('householdId') householdId: string) {
    return this.maintenanceService.getTaskSummary(householdId);
  }

  @Post('household/:householdId/generate')
  async generateTasks(
    @Param('householdId') householdId: string,
    @Body() body: { enrichment: any; state?: string },
  ) {
    const count = await this.generatorService.generateTasksForHousehold(
      householdId,
      body.enrichment,
      body.state,
    );
    return { generated: count };
  }

  @Put(':taskId/complete')
  async completeTask(
    @Request() req: any,
    @Param('taskId') taskId: string,
    @Body() body: { notes?: string; actualCost?: number },
  ) {
    return this.maintenanceService.completeTask(
      taskId,
      req.user.userId || req.user.id,
      body,
    );
  }

  @Put(':taskId/schedule')
  async scheduleTask(
    @Param('taskId') taskId: string,
    @Body() body: { vendorId?: string; scheduledDate?: string; notes?: string },
  ) {
    return this.maintenanceService.scheduleTask(taskId, {
      ...body,
      scheduledDate: body.scheduledDate
        ? new Date(body.scheduledDate)
        : undefined,
    });
  }

  @Put(':taskId/skip')
  async skipTask(
    @Param('taskId') taskId: string,
    @Body() body: { reason?: string },
  ) {
    return this.maintenanceService.skipTask(taskId, body.reason);
  }

  /**
   * Complete or uncomplete a checklist step
   */
  @Put(':taskId/step/:stepId/complete')
  async completeChecklistStep(
    @Request() req: any,
    @Param('taskId') taskId: string,
    @Param('stepId') stepId: string,
    @Body() body: { completed: boolean },
  ) {
    return this.maintenanceService.completeChecklistStep(
      taskId,
      stepId,
      req.user.userId || req.user.id,
      body.completed,
    );
  }

  /**
   * Initialize checklist from template
   */
  @Post(':taskId/initialize-checklist')
  async initializeChecklist(
    @Param('taskId') taskId: string,
    @Body() body: { templateId?: string },
  ) {
    return this.maintenanceService.initializeChecklist(taskId, body.templateId);
  }

  /**
   * Update checklist steps
   */
  @Put(':taskId/checklist')
  async updateChecklist(
    @Param('taskId') taskId: string,
    @Body() body: { steps: any[] },
  ) {
    return this.maintenanceService.updateChecklist(taskId, body.steps);
  }
}

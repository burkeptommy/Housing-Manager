import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ForbiddenException,
} from '@nestjs/common';
import { WorkOrdersService } from './work-orders.service';
import {
  CreateWorkOrderDto,
  UpdateWorkOrderDto,
  CreateWorkOrderNoteDto,
  WorkOrderQueryDto,
  InternalWorkOrderQueryDto,
} from './dto';
import { FirebaseAuthGuard } from '../firebase';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

/**
 * Work Orders Controller for Homeowners
 */
@Controller('work-orders')
@UseGuards(FirebaseAuthGuard)
export class WorkOrdersController {
  constructor(private readonly workOrdersService: WorkOrdersService) {}

  /**
   * Create a new work order
   */
  @Post()
  async createWorkOrder(@Request() req, @Body() dto: CreateWorkOrderDto) {
    const householdId = req.user.householdId;
    if (!householdId) {
      throw new ForbiddenException('No household context');
    }
    return this.workOrdersService.createWorkOrder(householdId, req.user.userId, dto);
  }

  /**
   * List work orders for current household
   */
  @Get()
  async listWorkOrders(@Request() req, @Query() query: WorkOrderQueryDto) {
    // Use query param householdId if provided, otherwise fall back to user's primary household
    const householdId = query.householdId || req.user.householdId;
    if (!householdId) {
      throw new ForbiddenException('No household context');
    }
    return this.workOrdersService.listWorkOrders(householdId, query);
  }

  /**
   * Get a single work order
   */
  @Get(':id')
  async getWorkOrder(@Request() req, @Param('id') id: string) {
    const householdId = req.user.householdId;
    if (!householdId) {
      throw new ForbiddenException('No household context');
    }
    return this.workOrdersService.getWorkOrder(id, householdId);
  }
}

/**
 * Internal Work Orders Controller for Home Managers
 */
@Controller('internal/work-orders')
@UseGuards(FirebaseAuthGuard, RolesGuard)
@Roles('HOME_MANAGER', 'MANAGER', 'ADMIN')
export class InternalWorkOrdersController {
  constructor(private readonly workOrdersService: WorkOrdersService) {}

  /**
   * List all work orders (queue view)
   */
  @Get()
  async listWorkOrders(@Query() query: InternalWorkOrderQueryDto) {
    return this.workOrdersService.listInternalWorkOrders(query);
  }

  /**
   * Get a single work order
   */
  @Get(':id')
  async getWorkOrder(@Param('id') id: string) {
    return this.workOrdersService.getWorkOrder(id);
  }

  /**
   * Update a work order (assign vendor, schedule, update status, etc.)
   */
  @Patch(':id')
  async updateWorkOrder(@Param('id') id: string, @Body() dto: UpdateWorkOrderDto) {
    return this.workOrdersService.updateWorkOrder(id, dto);
  }

  /**
   * Add a note to a work order
   */
  @Post(':id/notes')
  async addNote(
    @Request() req,
    @Param('id') id: string,
    @Body() dto: CreateWorkOrderNoteDto,
  ) {
    return this.workOrdersService.addNote(id, req.user.userId, dto);
  }
}

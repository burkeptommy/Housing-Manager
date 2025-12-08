import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import {
  MaintenanceCategory,
  MaintenanceTaskStatus,
  TaskPriority,
  VendorCategory,
} from '@prisma/client';

import { PrismaService } from '../prisma';

import { MaintenanceTasksService } from './maintenance-tasks.service';
import {
  CreateMaintenanceTaskDto,
  UpdateMaintenanceTaskDto,
  GenerateFromTemplatesDto,
} from './dto';

describe('MaintenanceTasksService', () => {
  let service: MaintenanceTasksService;

  const mockUserId = 'user-123';
  const mockHouseholdId = 'household-123';
  const mockVendorId = 'vendor-123';
  const mockTemplateId = 'template-123';

  const mockMembership = {
    householdId: mockHouseholdId,
    userId: mockUserId,
    status: 'ACTIVE',
    role: 'OWNER',
  };

  const mockVendor = {
    id: mockVendorId,
    householdId: mockHouseholdId,
    displayName: 'HVAC Pro Services',
    category: VendorCategory.HVAC_SERVICE,
  };

  const mockTemplate = {
    id: mockTemplateId,
    slug: 'hvac_tuneup_spring',
    title: 'HVAC Spring Tune-Up',
    description: 'Professional inspection and maintenance of cooling system before summer.',
    category: MaintenanceCategory.HVAC,
    recommendedFrequencyMonths: 12,
    recommendedSeasonStartMonth: 3,
    recommendedSeasonEndMonth: 5,
    propertyConditionsJson: null,
    defaultVendorCategory: VendorCategory.HVAC_SERVICE,
    estimatedCostMin: { toNumber: () => 75 },
    estimatedCostMax: { toNumber: () => 200 },
    isActive: true,
    sortOrder: 1,
  };

  const mockTask = {
    id: 'task-123',
    householdId: mockHouseholdId,
    templateId: null,
    assignedVendorId: null,
    title: 'Test Maintenance Task',
    description: 'A test task description',
    category: MaintenanceCategory.HVAC,
    status: MaintenanceTaskStatus.PENDING,
    dueDate: new Date('2024-04-15'),
    scheduledDate: null,
    completedAt: null,
    estimatedCost: { toNumber: () => 150 },
    actualCost: null,
    createdFromTemplate: false,
    notes: null,
    priority: TaskPriority.MEDIUM,
    createdAt: new Date(),
    updatedAt: new Date(),
    template: null,
    assignedVendor: null,
  };

  const mockPrismaService = {
    maintenanceTask: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    maintenanceTemplate: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
    },
    householdMember: {
      findUnique: jest.fn(),
    },
    vendor: {
      findFirst: jest.fn(),
    },
    homeProfile: {
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MaintenanceTasksService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<MaintenanceTasksService>(MaintenanceTasksService);

    jest.clearAllMocks();

    // Default mock setup
    mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);
    mockPrismaService.vendor.findFirst.mockResolvedValue(mockVendor);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    const createDto: CreateMaintenanceTaskDto = {
      householdId: mockHouseholdId,
      title: 'Test Maintenance Task',
      description: 'A test task description',
      category: MaintenanceCategory.HVAC,
      dueDate: '2024-04-15',
      priority: TaskPriority.MEDIUM,
    };

    it('should successfully create a maintenance task', async () => {
      mockPrismaService.maintenanceTask.create.mockResolvedValue(mockTask);

      const result = await service.create(mockUserId, createDto);

      expect(result).toHaveProperty('id');
      expect(result.title).toBe(createDto.title);
      expect(result.category).toBe(MaintenanceCategory.HVAC);
      expect(result.status).toBe(MaintenanceTaskStatus.PENDING);
    });

    it('should create task from template and inherit template values', async () => {
      const templateDto: CreateMaintenanceTaskDto = {
        householdId: mockHouseholdId,
        templateId: mockTemplateId,
        title: 'HVAC Spring Tune-Up',
      };

      mockPrismaService.maintenanceTemplate.findUnique.mockResolvedValue(mockTemplate);
      mockPrismaService.maintenanceTask.create.mockResolvedValue({
        ...mockTask,
        templateId: mockTemplateId,
        title: mockTemplate.title,
        description: mockTemplate.description,
        category: mockTemplate.category,
        estimatedCost: mockTemplate.estimatedCostMin,
        createdFromTemplate: true,
        template: mockTemplate,
      });

      const result = await service.create(mockUserId, templateDto);

      expect(result.templateId).toBe(mockTemplateId);
      expect(result.category).toBe(MaintenanceCategory.HVAC);
      expect(result.createdFromTemplate).toBe(true);
    });

    it('should throw BadRequestException when template not found', async () => {
      const templateDto: CreateMaintenanceTaskDto = {
        householdId: mockHouseholdId,
        templateId: 'invalid-template',
        title: 'Test Task',
      };

      mockPrismaService.maintenanceTemplate.findUnique.mockResolvedValue(null);

      await expect(service.create(mockUserId, templateDto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should assign vendor to task', async () => {
      const dtoWithVendor: CreateMaintenanceTaskDto = {
        ...createDto,
        assignedVendorId: mockVendorId,
      };

      mockPrismaService.maintenanceTask.create.mockResolvedValue({
        ...mockTask,
        assignedVendorId: mockVendorId,
        assignedVendor: mockVendor,
      });

      const result = await service.create(mockUserId, dtoWithVendor);

      expect(result.assignedVendorId).toBe(mockVendorId);
      expect(result.assignedVendor?.displayName).toBe('HVAC Pro Services');
    });

    it('should throw ForbiddenException when user has no household access', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(null);

      await expect(service.create(mockUserId, createDto)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw BadRequestException when vendor not found', async () => {
      const dtoWithVendor: CreateMaintenanceTaskDto = {
        ...createDto,
        assignedVendorId: 'invalid-vendor',
      };

      mockPrismaService.vendor.findFirst.mockResolvedValue(null);

      await expect(service.create(mockUserId, dtoWithVendor)).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('generateFromTemplates', () => {
    const generateDto: GenerateFromTemplatesDto = {
      householdId: mockHouseholdId,
      propertyFeatures: {
        has_pool: true,
        has_septic: true,
        has_fireplace: true,
      },
    };

    const poolTemplate = {
      ...mockTemplate,
      id: 'pool-template',
      slug: 'pool_opening',
      title: 'Pool Opening (Spring)',
      category: MaintenanceCategory.POOL,
      propertyConditionsJson: { has_pool: true },
      recommendedSeasonStartMonth: 4,
    };

    const septicTemplate = {
      ...mockTemplate,
      id: 'septic-template',
      slug: 'septic_pumping',
      title: 'Septic Tank Pumping',
      category: MaintenanceCategory.SEPTIC,
      propertyConditionsJson: { has_septic: true },
      recommendedFrequencyMonths: 36,
      recommendedSeasonStartMonth: null,
    };

    const chimneyTemplate = {
      ...mockTemplate,
      id: 'chimney-template',
      slug: 'chimney_sweep',
      title: 'Chimney Sweep & Inspection',
      category: MaintenanceCategory.CHIMNEY,
      propertyConditionsJson: { has_fireplace: true },
      recommendedSeasonStartMonth: 9,
    };

    it('should generate tasks from applicable templates based on property features', async () => {
      mockPrismaService.maintenanceTemplate.findMany.mockResolvedValue([
        mockTemplate, // No conditions - should be included
        poolTemplate, // has_pool: true - should be included
        septicTemplate, // has_septic: true - should be included
        chimneyTemplate, // has_fireplace: true - should be included
      ]);
      mockPrismaService.homeProfile.findFirst.mockResolvedValue(null);
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([]); // No existing tasks

      mockPrismaService.maintenanceTask.create.mockImplementation((args) =>
        Promise.resolve({
          id: `task-${Date.now()}-${Math.random()}`,
          ...args.data,
          status: MaintenanceTaskStatus.PENDING,
          createdAt: new Date(),
          updatedAt: new Date(),
          template: null,
          assignedVendor: null,
        }),
      );

      const result = await service.generateFromTemplates(mockUserId, generateDto);

      expect(result.length).toBe(4);
      expect(mockPrismaService.maintenanceTask.create).toHaveBeenCalledTimes(4);
    });

    it('should skip templates that do not match property features', async () => {
      const generateDtoNoPool: GenerateFromTemplatesDto = {
        householdId: mockHouseholdId,
        propertyFeatures: {
          has_pool: false,
          has_septic: true,
        },
      };

      mockPrismaService.maintenanceTemplate.findMany.mockResolvedValue([
        poolTemplate, // has_pool: true but property has no pool - should be skipped
        septicTemplate, // has_septic: true - should be included
      ]);
      mockPrismaService.homeProfile.findFirst.mockResolvedValue(null);
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([]);

      mockPrismaService.maintenanceTask.create.mockImplementation((args) =>
        Promise.resolve({
          id: `task-${Date.now()}`,
          ...args.data,
          status: MaintenanceTaskStatus.PENDING,
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );

      const result = await service.generateFromTemplates(mockUserId, generateDtoNoPool);

      expect(result.length).toBe(1);
      expect(result[0].category).toBe(MaintenanceCategory.SEPTIC);
    });

    it('should skip templates that already have pending tasks', async () => {
      mockPrismaService.maintenanceTemplate.findMany.mockResolvedValue([
        mockTemplate,
        poolTemplate,
      ]);
      mockPrismaService.homeProfile.findFirst.mockResolvedValue(null);
      // Simulate existing pending task for HVAC template
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([
        { templateId: mockTemplateId },
      ]);

      mockPrismaService.maintenanceTask.create.mockImplementation((args) =>
        Promise.resolve({
          id: `task-${Date.now()}`,
          ...args.data,
          status: MaintenanceTaskStatus.PENDING,
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );

      const result = await service.generateFromTemplates(mockUserId, generateDto);

      // Only pool template should create a task
      expect(result.length).toBe(1);
      expect(result[0].category).toBe(MaintenanceCategory.POOL);
    });

    it('should calculate due date based on recommended season', async () => {
      // Template with season start month of April (4)
      mockPrismaService.maintenanceTemplate.findMany.mockResolvedValue([poolTemplate]);
      mockPrismaService.homeProfile.findFirst.mockResolvedValue(null);
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([]);

      let createdDueDate: Date | null = null;
      mockPrismaService.maintenanceTask.create.mockImplementation((args) => {
        createdDueDate = args.data.dueDate;
        return Promise.resolve({
          id: 'task-123',
          ...args.data,
          status: MaintenanceTaskStatus.PENDING,
          createdAt: new Date(),
          updatedAt: new Date(),
        });
      });

      await service.generateFromTemplates(mockUserId, generateDto);

      expect(createdDueDate).not.toBeNull();
      // Due date should be in April (month index 3)
      expect(createdDueDate!.getMonth()).toBe(3);
    });

    it('should calculate due date based on frequency when no season specified', async () => {
      const noSeasonTemplate = {
        ...mockTemplate,
        recommendedSeasonStartMonth: null,
        recommendedSeasonEndMonth: null,
        recommendedFrequencyMonths: 6,
        propertyConditionsJson: null,
      };

      mockPrismaService.maintenanceTemplate.findMany.mockResolvedValue([noSeasonTemplate]);
      mockPrismaService.homeProfile.findFirst.mockResolvedValue(null);
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([]);

      let createdDueDate: Date | null = null;
      mockPrismaService.maintenanceTask.create.mockImplementation((args) => {
        createdDueDate = args.data.dueDate;
        return Promise.resolve({
          id: 'task-123',
          ...args.data,
          status: MaintenanceTaskStatus.PENDING,
          createdAt: new Date(),
          updatedAt: new Date(),
        });
      });

      await service.generateFromTemplates(mockUserId, {
        householdId: mockHouseholdId,
      });

      expect(createdDueDate).not.toBeNull();
      // Should be ~3 months in the future (half of 6-month frequency)
      const now = new Date();
      const expectedMonth = (now.getMonth() + 3) % 12;
      expect(createdDueDate!.getMonth()).toBe(expectedMonth);
    });

    it('should set createdFromTemplate flag to true', async () => {
      mockPrismaService.maintenanceTemplate.findMany.mockResolvedValue([mockTemplate]);
      mockPrismaService.homeProfile.findFirst.mockResolvedValue(null);
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([]);

      mockPrismaService.maintenanceTask.create.mockImplementation((args) =>
        Promise.resolve({
          id: 'task-123',
          ...args.data,
          status: MaintenanceTaskStatus.PENDING,
          createdFromTemplate: true,
          createdAt: new Date(),
          updatedAt: new Date(),
        }),
      );

      const result = await service.generateFromTemplates(mockUserId, {
        householdId: mockHouseholdId,
      });

      expect(result[0].createdFromTemplate).toBe(true);
    });
  });

  describe('findAll', () => {
    it('should return tasks excluding completed by default', async () => {
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([mockTask]);

      await service.findAll(mockUserId, { householdId: mockHouseholdId });

      expect(mockPrismaService.maintenanceTask.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            status: {
              notIn: [MaintenanceTaskStatus.COMPLETED, MaintenanceTaskStatus.SKIPPED],
            },
          }),
        }),
      );
    });

    it('should include completed tasks when specified', async () => {
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([mockTask]);

      await service.findAll(mockUserId, {
        householdId: mockHouseholdId,
        includeCompleted: true,
      });

      expect(mockPrismaService.maintenanceTask.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.not.objectContaining({
            status: expect.anything(),
          }),
        }),
      );
    });

    it('should filter by category', async () => {
      mockPrismaService.maintenanceTask.findMany.mockResolvedValue([mockTask]);

      await service.findAll(mockUserId, {
        householdId: mockHouseholdId,
        category: MaintenanceCategory.HVAC,
      });

      expect(mockPrismaService.maintenanceTask.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            category: MaintenanceCategory.HVAC,
          }),
        }),
      );
    });
  });

  describe('update', () => {
    it('should set completedAt when status changes to COMPLETED', async () => {
      mockPrismaService.maintenanceTask.findUnique.mockResolvedValue(mockTask);
      mockPrismaService.maintenanceTask.update.mockResolvedValue({
        ...mockTask,
        status: MaintenanceTaskStatus.COMPLETED,
        completedAt: new Date(),
      });

      const result = await service.update(mockTask.id, mockUserId, {
        status: MaintenanceTaskStatus.COMPLETED,
      });

      expect(result.status).toBe(MaintenanceTaskStatus.COMPLETED);
      expect(mockPrismaService.maintenanceTask.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            completedAt: expect.any(Date),
          }),
        }),
      );
    });

    it('should not set completedAt when status is not COMPLETED', async () => {
      mockPrismaService.maintenanceTask.findUnique.mockResolvedValue(mockTask);
      mockPrismaService.maintenanceTask.update.mockResolvedValue({
        ...mockTask,
        status: MaintenanceTaskStatus.SCHEDULED,
      });

      await service.update(mockTask.id, mockUserId, {
        status: MaintenanceTaskStatus.SCHEDULED,
      });

      expect(mockPrismaService.maintenanceTask.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.not.objectContaining({
            completedAt: expect.anything(),
          }),
        }),
      );
    });
  });

  describe('getTemplates', () => {
    it('should return all active templates', async () => {
      mockPrismaService.maintenanceTemplate.findMany.mockResolvedValue([mockTemplate]);

      const result = await service.getTemplates();

      expect(result).toHaveLength(1);
      expect(result[0].slug).toBe('hvac_tuneup_spring');
      expect(result[0].isActive).toBe(true);
    });
  });
});

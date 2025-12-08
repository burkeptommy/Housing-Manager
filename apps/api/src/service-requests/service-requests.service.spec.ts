import { Test, TestingModule } from '@nestjs/testing';
import {
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { UserRole, HouseholdRole } from '@prisma/client';

import { PrismaService } from '../prisma';
import { JwtPayload } from '../auth';

import { ServiceRequestsService } from './service-requests.service';
import { CreateServiceRequestDto, UpdateServiceRequestDto } from './dto';

describe('ServiceRequestsService', () => {
  let service: ServiceRequestsService;

  const mockUser: JwtPayload = {
    sub: 'user-123',
    email: 'test@example.com',
    role: UserRole.HOMEOWNER,
  };

  const mockManagerUser: JwtPayload = {
    sub: 'manager-123',
    email: 'manager@example.com',
    role: UserRole.MANAGER,
  };

  const mockAdminUser: JwtPayload = {
    sub: 'admin-123',
    email: 'admin@example.com',
    role: UserRole.ADMIN,
  };

  const mockHousehold = {
    id: 'household-123',
    name: "John's Home",
  };

  const mockMembership = {
    id: 'member-123',
    householdId: 'household-123',
    userId: 'user-123',
    role: HouseholdRole.OWNER,
    status: 'ACTIVE',
  };

  const mockCategory = {
    id: 'category-123',
    name: 'Plumbing',
    icon: 'plumbing',
  };

  const mockServiceRequest = {
    id: 'request-123',
    householdId: 'household-123',
    serviceCategoryId: 'category-123',
    vendorId: null,
    createdById: 'user-123',
    title: 'Fix leaky faucet',
    description: 'Kitchen faucet is dripping',
    status: 'SUBMITTED',
    priority: 'MEDIUM',
    preferredDate: null,
    scheduledDate: null,
    completedDate: null,
    estimatedCost: null,
    actualCost: null,
    notes: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    serviceCategory: mockCategory,
    vendor: null,
    createdBy: {
      id: 'user-123',
      firstName: 'John',
      lastName: 'Doe',
      email: 'test@example.com',
    },
    household: mockHousehold,
  };

  const mockPrismaService = {
    serviceRequest: {
      create: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    householdMember: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
    },
    serviceCategory: {
      findUnique: jest.fn(),
    },
    vendor: {
      findUnique: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ServiceRequestsService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<ServiceRequestsService>(ServiceRequestsService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    const createDto: CreateServiceRequestDto = {
      householdId: 'household-123',
      categoryId: 'category-123',
      title: 'Fix leaky faucet',
      description: 'Kitchen faucet is dripping',
      priority: 'MEDIUM',
    };

    it('should successfully create a service request', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);
      mockPrismaService.serviceCategory.findUnique.mockResolvedValue(mockCategory);
      mockPrismaService.serviceRequest.create.mockResolvedValue(mockServiceRequest);

      const result = await service.create(createDto, mockUser);

      expect(result).toHaveProperty('id');
      expect(result.title).toBe(createDto.title);
      expect(result.status).toBe('SUBMITTED');
      expect(mockPrismaService.serviceRequest.create).toHaveBeenCalled();
    });

    it('should create request without category', async () => {
      const dtoWithoutCategory: CreateServiceRequestDto = {
        householdId: 'household-123',
        title: 'General maintenance',
        description: 'Various fixes needed',
      };

      mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);
      mockPrismaService.serviceRequest.create.mockResolvedValue({
        ...mockServiceRequest,
        serviceCategoryId: null,
        serviceCategory: null,
      });

      const result = await service.create(dtoWithoutCategory, mockUser);

      expect(result.serviceCategory).toBeNull();
    });

    it('should throw ForbiddenException when user is not a member', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(null);

      await expect(service.create(createDto, mockUser)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw BadRequestException for invalid category', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);
      mockPrismaService.serviceCategory.findUnique.mockResolvedValue(null);

      await expect(service.create(createDto, mockUser)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should allow admin to create request for any household', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(null);
      mockPrismaService.serviceCategory.findUnique.mockResolvedValue(mockCategory);
      mockPrismaService.serviceRequest.create.mockResolvedValue(mockServiceRequest);

      const result = await service.create(createDto, mockAdminUser);

      expect(result).toHaveProperty('id');
    });
  });

  describe('findByHousehold', () => {
    it('should return requests for household member', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);
      mockPrismaService.serviceRequest.findMany.mockResolvedValue([mockServiceRequest]);

      const result = await service.findByHousehold('household-123', mockUser);

      expect(result).toHaveLength(1);
      expect(result[0].householdId).toBe('household-123');
    });

    it('should throw ForbiddenException for non-members', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(null);

      await expect(
        service.findByHousehold('household-123', mockUser),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow admin to view any household requests', async () => {
      mockPrismaService.serviceRequest.findMany.mockResolvedValue([mockServiceRequest]);

      const result = await service.findByHousehold('household-123', mockAdminUser);

      expect(result).toHaveLength(1);
    });
  });

  describe('findOne', () => {
    it('should return service request details', async () => {
      mockPrismaService.serviceRequest.findUnique.mockResolvedValue(mockServiceRequest);
      mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);

      const result = await service.findOne('request-123', mockUser);

      expect(result.id).toBe('request-123');
      expect(result.title).toBe(mockServiceRequest.title);
    });

    it('should throw NotFoundException when request not found', async () => {
      mockPrismaService.serviceRequest.findUnique.mockResolvedValue(null);

      await expect(service.findOne('non-existent', mockUser)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException for non-members', async () => {
      mockPrismaService.serviceRequest.findUnique.mockResolvedValue(mockServiceRequest);
      mockPrismaService.householdMember.findUnique.mockResolvedValue(null);

      await expect(service.findOne('request-123', mockUser)).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('update', () => {
    const updateDto: UpdateServiceRequestDto = {
      title: 'Updated title',
      description: 'Updated description',
    };

    it('should allow household member to update basic fields', async () => {
      mockPrismaService.serviceRequest.findUnique.mockResolvedValue(mockServiceRequest);
      mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);
      mockPrismaService.serviceRequest.update.mockResolvedValue({
        ...mockServiceRequest,
        ...updateDto,
      });

      const result = await service.update('request-123', updateDto, mockUser);

      expect(result.title).toBe(updateDto.title);
    });

    it('should throw NotFoundException when request not found', async () => {
      mockPrismaService.serviceRequest.findUnique.mockResolvedValue(null);

      await expect(
        service.update('non-existent', updateDto, mockUser),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ForbiddenException when non-manager updates status', async () => {
      const statusUpdateDto: UpdateServiceRequestDto = {
        status: 'IN_PROGRESS',
      };

      mockPrismaService.serviceRequest.findUnique.mockResolvedValue(mockServiceRequest);
      mockPrismaService.householdMember.findUnique.mockResolvedValue({
        ...mockMembership,
        role: HouseholdRole.MEMBER, // Not a manager
      });

      await expect(
        service.update('request-123', statusUpdateDto, mockUser),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should allow manager to update status', async () => {
      const statusUpdateDto: UpdateServiceRequestDto = {
        status: 'IN_PROGRESS',
      };

      mockPrismaService.serviceRequest.findUnique.mockResolvedValue(mockServiceRequest);
      mockPrismaService.householdMember.findUnique.mockResolvedValue({
        ...mockMembership,
        role: HouseholdRole.MANAGER,
      });
      mockPrismaService.serviceRequest.update.mockResolvedValue({
        ...mockServiceRequest,
        status: 'IN_PROGRESS',
      });

      const result = await service.update('request-123', statusUpdateDto, mockManagerUser);

      expect(result.status).toBe('IN_PROGRESS');
    });

    it('should set completedDate when status is COMPLETED', async () => {
      const completeDto: UpdateServiceRequestDto = {
        status: 'COMPLETED',
      };

      mockPrismaService.serviceRequest.findUnique.mockResolvedValue(mockServiceRequest);
      mockPrismaService.householdMember.findUnique.mockResolvedValue({
        ...mockMembership,
        role: HouseholdRole.MANAGER,
      });
      mockPrismaService.serviceRequest.update.mockResolvedValue({
        ...mockServiceRequest,
        status: 'COMPLETED',
        completedDate: new Date(),
      });

      await service.update('request-123', completeDto, mockManagerUser);

      expect(mockPrismaService.serviceRequest.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: 'COMPLETED',
            completedDate: expect.any(Date),
          }),
        }),
      );
    });
  });

  describe('findManagerRequests', () => {
    it('should return requests for managed households', async () => {
      mockPrismaService.householdMember.findMany.mockResolvedValue([
        { householdId: 'household-123' },
      ]);
      mockPrismaService.serviceRequest.findMany.mockResolvedValue([mockServiceRequest]);

      const result = await service.findManagerRequests(mockManagerUser);

      expect(result).toHaveLength(1);
    });

    it('should return empty array when no managed households', async () => {
      mockPrismaService.householdMember.findMany.mockResolvedValue([]);
      mockPrismaService.serviceRequest.findMany.mockResolvedValue([]);

      const result = await service.findManagerRequests(mockManagerUser);

      expect(result).toHaveLength(0);
    });
  });
});

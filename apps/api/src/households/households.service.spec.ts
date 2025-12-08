import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { HouseholdRole } from '@prisma/client';

import { PrismaService } from '../prisma';

import { HouseholdsService } from './households.service';
import { CreateHouseholdDto, UpdateHouseholdDto } from './dto';

describe('HouseholdsService', () => {
  let service: HouseholdsService;

  const mockUser = {
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
  };

  const mockHousehold = {
    id: 'household-123',
    name: "John's Home",
    description: 'A cozy house',
    ownerId: 'user-123',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockMembership = {
    id: 'member-123',
    householdId: 'household-123',
    userId: 'user-123',
    role: HouseholdRole.OWNER,
    status: 'ACTIVE',
    joinedAt: new Date(),
    user: mockUser,
    household: mockHousehold,
  };

  const mockPrismaService = {
    household: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    householdMember: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HouseholdsService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<HouseholdsService>(HouseholdsService);

    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    const createDto: CreateHouseholdDto = {
      name: 'New Home',
      description: 'A new household',
    };

    it('should successfully create a household', async () => {
      const createdHousehold = {
        ...mockHousehold,
        name: createDto.name,
        description: createDto.description,
      };

      mockPrismaService.household.create.mockResolvedValue(createdHousehold);

      const result = await service.create('user-123', createDto);

      expect(result).toHaveProperty('id');
      expect(result.name).toBe(createDto.name);
      expect(result.description).toBe(createDto.description);
      expect(mockPrismaService.household.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          name: createDto.name,
          description: createDto.description,
          ownerId: 'user-123',
        }),
      });
    });

    it('should create household without description', async () => {
      const dtoWithoutDescription: CreateHouseholdDto = {
        name: 'Simple Home',
      };

      mockPrismaService.household.create.mockResolvedValue({
        ...mockHousehold,
        name: dtoWithoutDescription.name,
        description: null,
      });

      const result = await service.create('user-123', dtoWithoutDescription);

      expect(result.name).toBe(dtoWithoutDescription.name);
    });
  });

  describe('findAllForUser', () => {
    it('should return all households for a user', async () => {
      mockPrismaService.householdMember.findMany.mockResolvedValue([
        {
          ...mockMembership,
          household: { ...mockHousehold, homeProfile: null },
        },
      ]);

      const result = await service.findAllForUser('user-123');

      expect(result).toHaveLength(1);
      expect(result[0].name).toBe(mockHousehold.name);
      expect(result[0].userRole).toBe(HouseholdRole.OWNER);
    });

    it('should return empty array when user has no households', async () => {
      mockPrismaService.householdMember.findMany.mockResolvedValue([]);

      const result = await service.findAllForUser('user-456');

      expect(result).toHaveLength(0);
    });
  });

  describe('findById', () => {
    it('should return household details', async () => {
      mockPrismaService.household.findUnique.mockResolvedValue({
        ...mockHousehold,
        homeProfile: null,
        members: [mockMembership],
        vendors: [],
      });

      const result = await service.findById('household-123');

      expect(result.id).toBe('household-123');
      expect(result.name).toBe(mockHousehold.name);
      expect(result.members).toHaveLength(1);
    });

    it('should throw NotFoundException when household not found', async () => {
      mockPrismaService.household.findUnique.mockResolvedValue(null);

      await expect(service.findById('non-existent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('update', () => {
    const updateDto: UpdateHouseholdDto = {
      name: 'Updated Home Name',
    };

    it('should successfully update household as owner', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);
      mockPrismaService.household.update.mockResolvedValue({
        ...mockHousehold,
        name: updateDto.name,
      });

      const result = await service.update('household-123', 'user-123', updateDto);

      expect(result.name).toBe(updateDto.name);
    });

    it('should throw ForbiddenException when user is not a member', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(null);

      await expect(
        service.update('household-123', 'user-456', updateDto),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw ForbiddenException when user is not owner', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue({
        ...mockMembership,
        role: HouseholdRole.MEMBER,
      });

      await expect(
        service.update('household-123', 'user-123', updateDto),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('delete', () => {
    it('should successfully delete household as owner', async () => {
      mockPrismaService.household.findUnique.mockResolvedValue(mockHousehold);
      mockPrismaService.household.delete.mockResolvedValue(mockHousehold);

      await service.delete('household-123', 'user-123');

      expect(mockPrismaService.household.delete).toHaveBeenCalledWith({
        where: { id: 'household-123' },
      });
    });

    it('should throw NotFoundException when household not found', async () => {
      mockPrismaService.household.findUnique.mockResolvedValue(null);

      await expect(service.delete('non-existent', 'user-123')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw ForbiddenException when user is not owner', async () => {
      mockPrismaService.household.findUnique.mockResolvedValue({
        ...mockHousehold,
        ownerId: 'other-user',
      });

      await expect(service.delete('household-123', 'user-123')).rejects.toThrow(
        ForbiddenException,
      );
    });
  });
});

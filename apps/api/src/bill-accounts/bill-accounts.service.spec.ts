import { Test, TestingModule } from '@nestjs/testing';
import { NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { VendorCategory, BillingFrequency, PaymentResponsibility } from '@prisma/client';

import { PrismaService } from '../prisma';

import { BillAccountsService } from './bill-accounts.service';
import { CreateBillAccountDto, UpdateBillAccountDto } from './dto';

describe('BillAccountsService', () => {
  let service: BillAccountsService;

  const mockUserId = 'user-123';
  const mockHouseholdId = 'household-123';
  const mockVendorId = 'vendor-123';
  const mockPaymentMethodId = 'pm-123';

  const mockVendor = {
    id: mockVendorId,
    householdId: mockHouseholdId,
    displayName: 'Electric Company',
    category: VendorCategory.ELECTRIC,
  };

  const mockMembership = {
    householdId: mockHouseholdId,
    userId: mockUserId,
    status: 'ACTIVE',
    role: 'OWNER',
  };

  const mockPaymentMethod = {
    id: mockPaymentMethodId,
    householdId: mockHouseholdId,
    type: 'CARD',
    last4: '4242',
  };

  const mockBillAccount = {
    id: 'bill-123',
    householdId: mockHouseholdId,
    vendorId: mockVendorId,
    paymentMethodId: null,
    nickname: 'Electric Bill',
    category: VendorCategory.ELECTRIC,
    accountNumber: '123456789',
    billingFrequency: BillingFrequency.MONTHLY,
    paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
    typicalAmount: { toNumber: () => 150 },
    nextDueDate: new Date('2024-02-15'),
    autopayEnabled: false,
    portalUrl: 'https://electric.example.com',
    supportPhone: '1-800-123-4567',
    notes: 'Main house electric',
    isActive: true,
    deletedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    vendor: mockVendor,
  };

  const mockPrismaService = {
    billAccount: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
    },
    householdMember: {
      findUnique: jest.fn(),
    },
    vendor: {
      findFirst: jest.fn(),
    },
    paymentMethod: {
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BillAccountsService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<BillAccountsService>(BillAccountsService);

    jest.clearAllMocks();

    // Default mock setup - user has access
    mockPrismaService.householdMember.findUnique.mockResolvedValue(mockMembership);
    mockPrismaService.vendor.findFirst.mockResolvedValue(mockVendor);
    mockPrismaService.paymentMethod.findFirst.mockResolvedValue(mockPaymentMethod);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    const createDto: CreateBillAccountDto = {
      householdId: mockHouseholdId,
      vendorId: mockVendorId,
      nickname: 'Electric Bill',
      category: VendorCategory.ELECTRIC,
      accountNumber: '123456789',
      billingFrequency: BillingFrequency.MONTHLY,
      paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
      typicalAmount: 150,
      nextDueDate: '2024-02-15',
      autopayEnabled: false,
      portalUrl: 'https://electric.example.com',
      supportPhone: '1-800-123-4567',
      notes: 'Main house electric',
    };

    it('should successfully create a bill account with all fields', async () => {
      mockPrismaService.billAccount.create.mockResolvedValue(mockBillAccount);

      const result = await service.create(mockUserId, createDto);

      expect(result).toHaveProperty('id');
      expect(result.nickname).toBe(createDto.nickname);
      expect(result.category).toBe(VendorCategory.ELECTRIC);
      expect(result.billingFrequency).toBe(BillingFrequency.MONTHLY);
      expect(result.paymentResponsibility).toBe(PaymentResponsibility.OWNER_PAYS_DIRECT);
      expect(mockPrismaService.billAccount.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          householdId: mockHouseholdId,
          vendorId: mockVendorId,
          nickname: createDto.nickname,
          category: VendorCategory.ELECTRIC,
        }),
        include: { vendor: true },
      });
    });

    it('should create bill account with default values when optional fields not provided', async () => {
      const minimalDto: CreateBillAccountDto = {
        householdId: mockHouseholdId,
        vendorId: mockVendorId,
        nickname: 'Simple Bill',
        category: VendorCategory.WATER_SEWER,
      };

      mockPrismaService.billAccount.create.mockResolvedValue({
        ...mockBillAccount,
        nickname: minimalDto.nickname,
        category: minimalDto.category,
        billingFrequency: BillingFrequency.MONTHLY,
        paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
        autopayEnabled: false,
      });

      const result = await service.create(mockUserId, minimalDto);

      expect(result.billingFrequency).toBe(BillingFrequency.MONTHLY);
      expect(result.paymentResponsibility).toBe(PaymentResponsibility.OWNER_PAYS_DIRECT);
      expect(mockPrismaService.billAccount.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          billingFrequency: BillingFrequency.MONTHLY,
          paymentResponsibility: PaymentResponsibility.OWNER_PAYS_DIRECT,
          autopayEnabled: false,
        }),
        include: { vendor: true },
      });
    });

    it('should create bill account with Haven pay-on-behalf settings', async () => {
      const havenPayDto: CreateBillAccountDto = {
        householdId: mockHouseholdId,
        vendorId: mockVendorId,
        nickname: 'Haven Managed Bill',
        category: VendorCategory.ELECTRIC,
        paymentResponsibility: PaymentResponsibility.HAVEN_PAYS_ON_BEHALF,
        paymentMethodId: mockPaymentMethodId,
        typicalAmount: 200,
      };

      mockPrismaService.billAccount.create.mockResolvedValue({
        ...mockBillAccount,
        paymentResponsibility: PaymentResponsibility.HAVEN_PAYS_ON_BEHALF,
        paymentMethodId: mockPaymentMethodId,
      });

      const result = await service.create(mockUserId, havenPayDto);

      expect(result.paymentResponsibility).toBe(PaymentResponsibility.HAVEN_PAYS_ON_BEHALF);
    });

    it('should throw ForbiddenException when user has no household access', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue(null);

      await expect(service.create(mockUserId, createDto)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw ForbiddenException when membership is inactive', async () => {
      mockPrismaService.householdMember.findUnique.mockResolvedValue({
        ...mockMembership,
        status: 'INACTIVE',
      });

      await expect(service.create(mockUserId, createDto)).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should throw BadRequestException when vendor not found', async () => {
      mockPrismaService.vendor.findFirst.mockResolvedValue(null);

      await expect(service.create(mockUserId, createDto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw BadRequestException when payment method not found', async () => {
      const dtoWithPayment: CreateBillAccountDto = {
        ...createDto,
        paymentMethodId: 'invalid-pm',
      };

      mockPrismaService.paymentMethod.findFirst.mockResolvedValue(null);

      await expect(service.create(mockUserId, dtoWithPayment)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should accept all valid billing frequencies', async () => {
      const frequencies = [
        BillingFrequency.WEEKLY,
        BillingFrequency.BIWEEKLY,
        BillingFrequency.MONTHLY,
        BillingFrequency.QUARTERLY,
        BillingFrequency.SEMIANNUALLY,
        BillingFrequency.ANNUAL,
      ];

      for (const frequency of frequencies) {
        const dto: CreateBillAccountDto = {
          ...createDto,
          billingFrequency: frequency,
        };

        mockPrismaService.billAccount.create.mockResolvedValue({
          ...mockBillAccount,
          billingFrequency: frequency,
        });

        const result = await service.create(mockUserId, dto);
        expect(result.billingFrequency).toBe(frequency);
      }
    });

    it('should validate all vendor categories', async () => {
      const categories = [
        VendorCategory.MORTGAGE,
        VendorCategory.HOA,
        VendorCategory.ELECTRIC,
        VendorCategory.GAS,
        VendorCategory.WATER_SEWER,
        VendorCategory.INTERNET,
        VendorCategory.LAWN_CARE,
        VendorCategory.PEST_CONTROL,
      ];

      for (const category of categories) {
        const dto: CreateBillAccountDto = {
          ...createDto,
          category,
        };

        mockPrismaService.vendor.findFirst.mockResolvedValue({
          ...mockVendor,
          category,
        });
        mockPrismaService.billAccount.create.mockResolvedValue({
          ...mockBillAccount,
          category,
        });

        const result = await service.create(mockUserId, dto);
        expect(result.category).toBe(category);
      }
    });
  });

  describe('findAll', () => {
    it('should return all active bill accounts for household', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([mockBillAccount]);

      const result = await service.findAll(mockUserId, {
        householdId: mockHouseholdId,
      });

      expect(result).toHaveLength(1);
      expect(result[0].nickname).toBe(mockBillAccount.nickname);
    });

    it('should filter by category', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([mockBillAccount]);

      await service.findAll(mockUserId, {
        householdId: mockHouseholdId,
        category: VendorCategory.ELECTRIC,
      });

      expect(mockPrismaService.billAccount.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            category: VendorCategory.ELECTRIC,
          }),
        }),
      );
    });

    it('should filter by upcoming due date', async () => {
      mockPrismaService.billAccount.findMany.mockResolvedValue([mockBillAccount]);

      await service.findAll(mockUserId, {
        householdId: mockHouseholdId,
        upcomingDays: 30,
      });

      expect(mockPrismaService.billAccount.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            nextDueDate: expect.any(Object),
          }),
        }),
      );
    });
  });

  describe('findOne', () => {
    it('should return a bill account by id', async () => {
      mockPrismaService.billAccount.findUnique.mockResolvedValue(mockBillAccount);

      const result = await service.findOne('bill-123', mockUserId);

      expect(result.id).toBe('bill-123');
      expect(result.nickname).toBe(mockBillAccount.nickname);
    });

    it('should throw NotFoundException when bill account not found', async () => {
      mockPrismaService.billAccount.findUnique.mockResolvedValue(null);

      await expect(service.findOne('non-existent', mockUserId)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw NotFoundException when bill account is soft-deleted', async () => {
      mockPrismaService.billAccount.findUnique.mockResolvedValue({
        ...mockBillAccount,
        deletedAt: new Date(),
      });

      await expect(service.findOne('bill-123', mockUserId)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('update', () => {
    const updateDto: UpdateBillAccountDto = {
      nickname: 'Updated Electric Bill',
      typicalAmount: 175,
    };

    it('should successfully update bill account', async () => {
      mockPrismaService.billAccount.findUnique.mockResolvedValue(mockBillAccount);
      mockPrismaService.billAccount.update.mockResolvedValue({
        ...mockBillAccount,
        ...updateDto,
      });

      const result = await service.update('bill-123', mockUserId, updateDto);

      expect(result.nickname).toBe(updateDto.nickname);
    });

    it('should update payment responsibility to Haven pays on behalf', async () => {
      mockPrismaService.billAccount.findUnique.mockResolvedValue(mockBillAccount);
      mockPrismaService.billAccount.update.mockResolvedValue({
        ...mockBillAccount,
        paymentResponsibility: PaymentResponsibility.HAVEN_PAYS_ON_BEHALF,
      });

      const result = await service.update('bill-123', mockUserId, {
        paymentResponsibility: PaymentResponsibility.HAVEN_PAYS_ON_BEHALF,
      });

      expect(result.paymentResponsibility).toBe(PaymentResponsibility.HAVEN_PAYS_ON_BEHALF);
    });

    it('should throw NotFoundException when updating non-existent bill', async () => {
      mockPrismaService.billAccount.findUnique.mockResolvedValue(null);

      await expect(
        service.update('non-existent', mockUserId, updateDto),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    it('should soft delete a bill account', async () => {
      mockPrismaService.billAccount.findUnique.mockResolvedValue(mockBillAccount);
      mockPrismaService.billAccount.update.mockResolvedValue({
        ...mockBillAccount,
        deletedAt: new Date(),
        isActive: false,
      });

      await service.remove('bill-123', mockUserId);

      expect(mockPrismaService.billAccount.update).toHaveBeenCalledWith({
        where: { id: 'bill-123' },
        data: {
          deletedAt: expect.any(Date),
          isActive: false,
        },
      });
    });

    it('should throw NotFoundException when removing non-existent bill', async () => {
      mockPrismaService.billAccount.findUnique.mockResolvedValue(null);

      await expect(service.remove('non-existent', mockUserId)).rejects.toThrow(
        NotFoundException,
      );
    });
  });
});

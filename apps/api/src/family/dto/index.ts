import { Type, Transform } from 'class-transformer';
import {
  IsString,
  IsOptional,
  IsInt,
  IsNumber,
  IsBoolean,
  IsArray,
  IsDate,
  IsEnum,
  Min,
  Max,
} from 'class-validator';
import {
  VehicleType,
  FuelType,
  PetType,
  PetSize,
  HomeSystemType,
  ApplianceCondition,
  FamilyEventCategory,
  MemberPermissionType,
  FamilyMemberType,
  ActivityType,
  PaymentFrequency,
} from '@prisma/client';

// ============================================================================
// FAMILY MEMBER DTOs
// ============================================================================

export class CreateFamilyMemberDto {
  @IsString()
  firstName: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsString()
  nickname?: string;

  @IsEnum(FamilyMemberType)
  type: FamilyMemberType;

  @IsOptional()
  @IsString()
  relationship?: string;

  @IsOptional()
  @IsString()
  email?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  birthdate?: Date;

  // Child-specific
  @IsOptional()
  @IsString()
  school?: string;

  @IsOptional()
  @IsString()
  schoolGrade?: string;

  @IsOptional()
  @IsString()
  teacher?: string;

  @IsOptional()
  @IsString()
  schoolPickup?: string;

  @IsOptional()
  @IsString()
  schoolDropoff?: string;

  // Staff-specific
  @IsOptional()
  @IsString()
  workSchedule?: string;

  @IsOptional()
  @IsString()
  responsibilities?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  startDate?: Date;

  @IsOptional()
  @IsString()
  paymentMethod?: string;

  // Staff Compensation
  @IsOptional()
  @IsNumber()
  payAmount?: number;

  @IsOptional()
  @IsString()
  payFrequency?: string; // WEEKLY, BIWEEKLY, MONTHLY, YEARLY

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastPayDate?: Date;

  @IsOptional()
  @IsString()
  agencyName?: string;

  @IsOptional()
  @IsString()
  agencyContact?: string;

  @IsOptional()
  @IsString()
  agencyPhone?: string;

  // Staff Benefits
  @IsOptional()
  @IsBoolean()
  hasHealthInsurance?: boolean;

  @IsOptional()
  @IsBoolean()
  hasDentalInsurance?: boolean;

  @IsOptional()
  @IsNumber()
  paidTimeOffDays?: number;

  @IsOptional()
  @IsNumber()
  sickDays?: number;

  @IsOptional()
  @IsBoolean()
  hasHolidayPay?: boolean;

  // Staff Reimbursements
  @IsOptional()
  @IsBoolean()
  mileageReimbursement?: boolean;

  @IsOptional()
  @IsBoolean()
  gasReimbursement?: boolean;

  @IsOptional()
  @IsBoolean()
  mealsReimbursement?: boolean;

  @IsOptional()
  @IsBoolean()
  phoneAllowance?: boolean;

  // Staff Documents
  @IsOptional()
  @IsBoolean()
  hasW9?: boolean;

  @IsOptional()
  @IsBoolean()
  hasI9?: boolean;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  backgroundCheckDate?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  cprCertifiedUntil?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  firstAidCertifiedUntil?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  driversLicenseExpiry?: Date;

  // Medical
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  allergies?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  medications?: string[];

  @IsOptional()
  @IsString()
  specialNeeds?: string;

  @IsOptional()
  @IsString()
  emergencyContact?: string;

  @IsOptional()
  @IsString()
  emergencyContactPhone?: string;

  @IsOptional()
  @IsString()
  photoUrl?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateFamilyMemberDto extends CreateFamilyMemberDto {}

// ============================================================================
// ACTIVITY/MEMBERSHIP DTOs (KidActivity)
// ============================================================================

export class CreateActivityDto {
  @IsString()
  name: string;

  @IsEnum(ActivityType)
  type: ActivityType;

  @IsOptional()
  @IsString()
  organization?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  schedule?: string;

  @IsOptional()
  @IsString()
  startDate?: string;

  @IsOptional()
  @IsString()
  endDate?: string;

  @IsOptional()
  @IsNumber()
  cost?: number;

  @IsOptional()
  @IsEnum(PaymentFrequency)
  costFrequency?: PaymentFrequency;

  @IsOptional()
  @IsNumber()
  registrationFee?: number;

  @IsOptional()
  @IsNumber()
  equipmentCost?: number;

  @IsOptional()
  @IsString()
  coachName?: string;

  @IsOptional()
  @IsString()
  contactPhone?: string;

  @IsOptional()
  @IsString()
  contactEmail?: string;

  @IsOptional()
  @IsString()
  paymentMethod?: string;

  @IsOptional()
  @IsString()
  accountNumber?: string;

  @IsOptional()
  @IsString()
  portalUrl?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsString()
  familyMemberId: string;
}

export class UpdateActivityDto extends CreateActivityDto {}

// ============================================================================
// MEMBER PROFILE DTOs
// ============================================================================

export class UpdateMemberProfileDto {
  @IsOptional()
  @IsString()
  nickname?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  birthday?: Date;

  @IsOptional()
  @IsString()
  shirtSize?: string;

  @IsOptional()
  @IsString()
  pantSize?: string;

  @IsOptional()
  @IsString()
  shoeSize?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  dietaryRestrictions?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  allergies?: string[];

  @IsOptional()
  @IsString()
  medicalNotes?: string;

  @IsOptional()
  @IsString()
  favoriteColor?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];

  @IsOptional()
  @IsString()
  profilePhotoUrl?: string;

  @IsOptional()
  @IsArray()
  @IsEnum(MemberPermissionType, { each: true })
  permissions?: MemberPermissionType[];
}

// ============================================================================
// VEHICLE DTOs
// ============================================================================

export class CreateVehicleDto {
  @IsOptional()
  @IsString()
  nickname?: string;

  @IsOptional()
  @IsEnum(VehicleType)
  type?: VehicleType;

  @IsString()
  make: string;

  @IsString()
  model: string;

  @IsInt()
  @Min(1900)
  @Max(2100)
  year: number;

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsString()
  licensePlate?: string;

  @IsOptional()
  @IsString()
  vin?: string;

  @IsOptional()
  @IsEnum(FuelType)
  fuelType?: FuelType;

  @IsOptional()
  @IsInt()
  @Min(0)
  currentMileage?: number;

  @IsOptional()
  @IsString()
  insuranceProvider?: string;

  @IsOptional()
  @IsString()
  insurancePolicyNum?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  insuranceExpires?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  registrationExpires?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  inspectionExpires?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  purchaseDate?: Date;

  @IsOptional()
  @IsNumber()
  purchasePrice?: number;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  warrantyExpires?: Date;

  @IsOptional()
  @IsString()
  warrantyProvider?: string;

  @IsOptional()
  @IsInt()
  oilChangeIntervalMiles?: number;

  @IsOptional()
  @IsInt()
  oilChangeIntervalMonths?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateVehicleDto extends CreateVehicleDto {
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastOilChangeDate?: Date;

  @IsOptional()
  @IsInt()
  lastOilChangeMileage?: number;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastTireRotationDate?: Date;

  @IsOptional()
  @IsInt()
  lastTireRotationMileage?: number;

  @IsOptional()
  @IsString()
  preferredServiceVendorId?: string;
}

export class CreateVehicleServiceRecordDto {
  @IsDate()
  @Type(() => Date)
  serviceDate: Date;

  @IsString()
  serviceType: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  mileageAtService?: number;

  @IsOptional()
  @IsNumber()
  cost?: number;

  @IsOptional()
  @IsString()
  vendorName?: string;

  @IsOptional()
  @IsString()
  vendorId?: string;

  @IsOptional()
  @IsString()
  receiptUrl?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  nextServiceDate?: Date;

  @IsOptional()
  @IsInt()
  nextServiceMileage?: number;

  @IsOptional()
  @IsString()
  notes?: string;
}

// ============================================================================
// PET DTOs
// ============================================================================

export class CreatePetDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsEnum(PetType)
  type?: PetType;

  @IsOptional()
  @IsString()
  breed?: string;

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsEnum(PetSize)
  size?: PetSize;

  @IsOptional()
  @IsNumber()
  weight?: number;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  birthday?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  adoptionDate?: Date;

  @IsOptional()
  @IsString()
  gender?: string;

  @IsOptional()
  @IsString()
  microchipId?: string;

  @IsOptional()
  @IsBoolean()
  isSpayedNeutered?: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  allergies?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  medications?: string[];

  @IsOptional()
  @IsString()
  specialNeeds?: string;

  @IsOptional()
  @IsString()
  vetClinicName?: string;

  @IsOptional()
  @IsString()
  vetClinicPhone?: string;

  @IsOptional()
  @IsString()
  vetClinicAddress?: string;

  @IsOptional()
  @IsString()
  primaryVetName?: string;

  @IsOptional()
  @IsString()
  insuranceProvider?: string;

  @IsOptional()
  @IsString()
  insurancePolicyNum?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  insuranceExpires?: Date;

  @IsOptional()
  @IsString()
  foodBrand?: string;

  @IsOptional()
  @IsString()
  foodType?: string;

  @IsOptional()
  @IsString()
  feedingSchedule?: string;

  @IsOptional()
  @IsString()
  dietaryNotes?: string;

  @IsOptional()
  @IsString()
  careInstructions?: string;

  @IsOptional()
  @IsString()
  emergencyContact?: string;

  @IsOptional()
  @IsString()
  behavioralNotes?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdatePetDto extends CreatePetDto {}

export class CreatePetVetRecordDto {
  @IsDate()
  @Type(() => Date)
  visitDate: Date;

  @IsString()
  visitType: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  diagnosis?: string;

  @IsOptional()
  @IsString()
  treatment?: string;

  @IsOptional()
  @IsNumber()
  weight?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  vaccinationsGiven?: string[];

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  nextVaccinationDate?: Date;

  @IsOptional()
  prescriptions?: Record<string, unknown>;

  @IsOptional()
  @IsNumber()
  cost?: number;

  @IsOptional()
  @IsString()
  vetClinic?: string;

  @IsOptional()
  @IsString()
  vetName?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  documentUrls?: string[];

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  followUpDate?: Date;

  @IsOptional()
  @IsString()
  followUpNotes?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

// ============================================================================
// HOME SYSTEM DTOs
// ============================================================================

export class CreateHomeSystemDto {
  @IsString()
  name: string;

  @IsEnum(HomeSystemType)
  type: HomeSystemType;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  brand?: string;

  @IsOptional()
  @IsString()
  model?: string;

  @IsOptional()
  @IsString()
  modelNumber?: string;

  @IsOptional()
  @IsString()
  serialNumber?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  purchaseDate?: Date;

  @IsOptional()
  @IsNumber()
  purchasePrice?: number;

  @IsOptional()
  @IsString()
  purchasedFrom?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  installedDate?: Date;

  @IsOptional()
  @IsString()
  installedBy?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  warrantyExpires?: Date;

  @IsOptional()
  @IsString()
  warrantyProvider?: string;

  @IsOptional()
  @IsString()
  warrantyPhone?: string;

  @IsOptional()
  @IsString()
  warrantyDetails?: string;

  @IsOptional()
  @IsEnum(ApplianceCondition)
  condition?: ApplianceCondition;

  @IsOptional()
  @IsInt()
  maintenanceIntervalMonths?: number;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastMaintenanceDate?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  nextMaintenanceDate?: Date;

  // Service/utility info
  @IsOptional()
  @IsString()
  serviceProvider?: string;

  @IsOptional()
  @IsString()
  serviceAccountNumber?: string;

  @IsOptional()
  @IsString()
  servicePhone?: string;

  @IsOptional()
  @IsNumber()
  currentRate?: number;

  @IsOptional()
  @IsString()
  rateUnit?: string;

  @IsOptional()
  @IsNumber()
  lastBillAmount?: number;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastBillDate?: Date;

  @IsOptional()
  @IsNumber()
  averageMonthlyUsage?: number;

  @IsOptional()
  @IsString()
  usageUnit?: string;

  // Fuel tank info
  @IsOptional()
  @IsNumber()
  tankCapacity?: number;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastFillDate?: Date;

  @IsOptional()
  @IsNumber()
  lastFillAmount?: number;

  @IsOptional()
  @IsNumber()
  estimatedRemaining?: number;

  // Documents
  @IsOptional()
  @IsString()
  manualUrl?: string;

  @IsOptional()
  @IsString()
  receiptUrl?: string;

  @IsOptional()
  @IsString()
  warrantyDocUrl?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  photoUrls?: string[];

  // Energy
  @IsOptional()
  @IsString()
  energyRating?: string;

  // Filter info
  @IsOptional()
  @IsString()
  filterSize?: string;

  @IsOptional()
  @IsString()
  filterType?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  lastFilterChange?: Date;

  @IsOptional()
  @IsInt()
  filterChangeIntervalMonths?: number;

  @IsOptional()
  @IsString()
  serviceVendorId?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateHomeSystemDto extends CreateHomeSystemDto {}

export class CreateHomeSystemServiceDto {
  @IsDate()
  @Type(() => Date)
  serviceDate: Date;

  @IsString()
  serviceType: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  technicianName?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  partsReplaced?: string[];

  @IsOptional()
  @IsNumber()
  laborCost?: number;

  @IsOptional()
  @IsNumber()
  partsCost?: number;

  @IsOptional()
  @IsNumber()
  totalCost?: number;

  @IsOptional()
  @IsString()
  vendorId?: string;

  @IsOptional()
  @IsString()
  vendorName?: string;

  @IsOptional()
  @IsString()
  invoiceUrl?: string;

  @IsOptional()
  @IsString()
  receiptUrl?: string;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  nextServiceDate?: Date;

  @IsOptional()
  @IsString()
  recommendations?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

// ============================================================================
// FAMILY EVENT DTOs
// ============================================================================

export class CreateFamilyEventDto {
  @IsString()
  title: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsEnum(FamilyEventCategory)
  category?: FamilyEventCategory;

  @IsOptional()
  @IsString()
  assignedToMemberId?: string;

  @IsDate()
  @Type(() => Date)
  startDate: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  endDate?: Date;

  @IsOptional()
  @IsBoolean()
  isAllDay?: boolean;

  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;

  @IsOptional()
  @IsString()
  recurrence?: string;

  @IsOptional()
  @IsArray()
  @IsInt({ each: true })
  reminderMinutes?: number[];

  @IsOptional()
  @IsString()
  color?: string;

  @IsOptional()
  @IsString()
  vehicleId?: string;

  @IsOptional()
  @IsString()
  petId?: string;

  @IsOptional()
  @IsString()
  workOrderId?: string;
}

export class UpdateFamilyEventDto extends CreateFamilyEventDto {}

// ============================================================================
// CALENDAR FEED DTOs
// ============================================================================

export class CalendarFeedQueryDto {
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  includeMaintenance?: boolean;

  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  @IsInt()
  lookbackDays?: number;

  @IsOptional()
  @Transform(({ value }) => parseInt(value, 10))
  @IsInt()
  lookaheadDays?: number;

  @IsOptional()
  @IsArray()
  @IsEnum(FamilyEventCategory, { each: true })
  categories?: FamilyEventCategory[];
}

// ============================================================================
// CALENDAR QUERY DTOs
// ============================================================================

export class CalendarQueryDto {
  @IsOptional()
  @IsDate()
  @Type(() => Date)
  startDate?: Date;

  @IsOptional()
  @IsDate()
  @Type(() => Date)
  endDate?: Date;

  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  includeMaintenance?: boolean;

  @IsOptional()
  @IsArray()
  @IsEnum(FamilyEventCategory, { each: true })
  categories?: FamilyEventCategory[];

  @IsOptional()
  @IsString()
  memberId?: string;
}

// ============================================================================
// USER TYPES
// ============================================================================

export type UserRole = 'ADMIN' | 'HOMEOWNER' | 'MANAGER' | 'VENDOR';

export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: UserRole;
  phone?: string | null;
  avatarUrl?: string | null;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// ============================================================================
// AUTH TYPES
// ============================================================================

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface AuthResponse {
  user: User;
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface RegisterRequest {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role?: UserRole;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

// ============================================================================
// HOUSEHOLD TYPES
// ============================================================================

export type HouseholdRole = 'OWNER' | 'MANAGER' | 'MEMBER';
export type HouseholdMemberStatus = 'PENDING' | 'ACTIVE' | 'INACTIVE';

export interface Household {
  id: string;
  name: string;
  description?: string | null;
  ownerId: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface HouseholdMember {
  id: string;
  householdId: string;
  userId: string;
  role: HouseholdRole;
  status: HouseholdMemberStatus;
  user?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };
}

export interface HouseholdDetail extends Household {
  members: HouseholdMember[];
  homeProfile?: HomeProfile | null;
}

export interface CreateHouseholdRequest {
  name: string;
  description?: string;
}

export interface UpdateHouseholdRequest {
  name?: string;
  description?: string;
}

// ============================================================================
// HOME PROFILE TYPES
// ============================================================================

export type PropertyType =
  | 'SINGLE_FAMILY'
  | 'TOWNHOUSE'
  | 'CONDO'
  | 'APARTMENT'
  | 'MULTI_FAMILY'
  | 'MOBILE_HOME'
  | 'OTHER';

export interface HomeProfile {
  id: string;
  householdId: string;
  propertyType: PropertyType;
  addressLine1: string;
  addressLine2?: string | null;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  squareFeet?: number | null;
  lotSize?: number | null;
  yearBuilt?: number | null;
  bedrooms?: number | null;
  bathrooms?: number | null;
  stories?: number | null;
  garageSpaces?: number | null;
  purchaseDate?: Date | null;
  purchasePrice?: number | null;
  currentValue?: number | null;
  notes?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface UpsertHomeProfileRequest {
  propertyType: PropertyType;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  country?: string;
  squareFeet?: number;
  lotSize?: number;
  yearBuilt?: number;
  bedrooms?: number;
  bathrooms?: number;
  stories?: number;
  garageSpaces?: number;
  purchaseDate?: string;
  purchasePrice?: number;
  currentValue?: number;
  notes?: string;
}

// ============================================================================
// SERVICE CATEGORY TYPES
// ============================================================================

export interface ServiceCategory {
  id: string;
  name: string;
  description?: string | null;
  icon?: string | null;
  sortOrder: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// ============================================================================
// SERVICE REQUEST TYPES
// ============================================================================

export type ServiceRequestStatus =
  | 'DRAFT'
  | 'SUBMITTED'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED';

export type ServiceRequestPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';

export interface ServiceRequest {
  id: string;
  householdId: string;
  serviceCategoryId?: string | null;
  vendorId?: string | null;
  createdById: string;
  title: string;
  description: string;
  status: ServiceRequestStatus;
  priority: ServiceRequestPriority;
  preferredDate?: Date | null;
  scheduledDate?: Date | null;
  completedDate?: Date | null;
  estimatedCost?: number | null;
  actualCost?: number | null;
  notes?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface ServiceRequestDetail extends ServiceRequest {
  serviceCategory?: {
    id: string;
    name: string;
    icon?: string | null;
  } | null;
  vendor?: {
    id: string;
    companyName: string;
  } | null;
  createdBy?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };
  household?: {
    id: string;
    name: string;
  };
}

export interface CreateServiceRequestRequest {
  householdId: string;
  categoryId?: string;
  title: string;
  description: string;
  priority?: ServiceRequestPriority;
  preferredDate?: string;
  notes?: string;
  photoUrl?: string;
}

export interface UpdateServiceRequestRequest {
  categoryId?: string;
  title?: string;
  description?: string;
  priority?: ServiceRequestPriority;
  preferredDate?: string;
  notes?: string;
  status?: ServiceRequestStatus;
  vendorId?: string;
  scheduledDate?: string;
  estimatedCost?: number;
  actualCost?: number;
}

// ============================================================================
// TASK TYPES
// ============================================================================

export type TaskStatus = 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
export type TaskPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';

export interface Task {
  id: string;
  householdId: string;
  title: string;
  description?: string | null;
  status: TaskStatus;
  priority: TaskPriority;
  dueDate?: Date | null;
  assigneeId?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

// ============================================================================
// SUBSCRIPTION / BILLING TYPES
// ============================================================================

export type SubscriptionTier = 'FREE' | 'BASIC' | 'PREMIUM' | 'ENTERPRISE';
export type SubscriptionStatus = 'ACTIVE' | 'PAST_DUE' | 'CANCELLED' | 'EXPIRED';

export interface Subscription {
  id: string;
  userId: string;
  tier: SubscriptionTier;
  status: SubscriptionStatus;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  stripeCustomerId?: string | null;
  stripeSubscriptionId?: string | null;
  cancelledAt?: Date | null;
  cancelAtPeriodEnd: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateSubscriptionRequest {
  tier: SubscriptionTier;
  paymentMethodId: string;
}

// ============================================================================
// ONBOARDING TYPES
// ============================================================================

export type PainPoint =
  | 'maintenance_scheduling'
  | 'finding_vendors'
  | 'tracking_bills'
  | 'household_supplies'
  | 'pet_care'
  | 'vehicle_maintenance';

export type CommunicationChannel = 'sms' | 'email' | 'app';

export interface HomeSystems {
  hvacType?: string;
  hvacAge?: number;
  roofType?: string;
  roofAge?: number;
  waterHeaterType?: string;
  waterHeaterAge?: number;
  septicOrSewer?: 'septic' | 'sewer';
  septicLastServiced?: string;
  electricalPanelAmps?: number;
  hasPool?: boolean;
  hasSprinklerSystem?: boolean;
  hasSecuritySystem?: boolean;
  hasSmartHome?: boolean;
}

export interface OnboardingPreferences {
  painPoints: PainPoint[];
  communicationChannels: CommunicationChannel[];
}

export interface OnboardingData {
  // Step 1: Basic home info
  name: string;
  propertyType: PropertyType;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  yearBuilt?: number;
  bedrooms?: number;
  bathrooms?: number;
  squareFeet?: number;

  // Step 2: Systems overview
  systems: HomeSystems;

  // Step 3: Pain points
  painPoints: PainPoint[];

  // Step 4: Communication preferences
  communicationChannels: CommunicationChannel[];
}

// Extended home profile that includes systems and preferences (stored in notes as JSON)
export interface ExtendedHomeProfile extends HomeProfile {
  systems?: HomeSystems;
  preferences?: OnboardingPreferences;
}

// ============================================================================
// VENDOR TYPES
// ============================================================================

export interface Vendor {
  id: string;
  name: string;
  description?: string | null;
  contactName?: string | null;
  email?: string | null;
  phone?: string | null;
  website?: string | null;
  serviceCategoryId?: string | null;
  isVerified: boolean;
  isActive: boolean;
  rating?: number | null;
  reviewCount: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface VendorSummary {
  id: string;
  name: string;
  phone?: string | null;
  email?: string | null;
  categoryName?: string | null;
  isFavorite?: boolean;
}

// ============================================================================
// FILE TYPES
// ============================================================================

export type FileCategory =
  | 'DOCUMENT'
  | 'IMAGE'
  | 'RECEIPT'
  | 'WARRANTY'
  | 'MANUAL'
  | 'CONTRACT'
  | 'OTHER';

export interface FileUpload {
  id: string;
  filename: string;
  originalName: string;
  mimeType: string;
  size: number;
  url?: string;
  category: FileCategory;
  description?: string;
  householdId?: string;
  serviceRequestId?: string;
  taskId?: string;
  createdAt: Date;
}

export interface UploadFileRequest {
  householdId: string;
  category?: FileCategory;
  description?: string;
  serviceRequestId?: string;
  taskId?: string;
}

export interface UploadResponse {
  success: boolean;
  file: FileUpload;
}

// ============================================================================
// MANAGER TYPES
// ============================================================================

export interface ManagedHousehold extends Household {
  userRole: HouseholdRole;
  homeProfile?: {
    id: string;
    propertyType: PropertyType;
    addressLine1: string;
    city: string;
    state: string;
    postalCode: string;
  } | null;
}

// ============================================================================
// API RESPONSE TYPES
// ============================================================================

export interface ApiError {
  message: string;
  error?: string;
  statusCode: number;
}

// ============================================================================
// ADMIN TYPES
// ============================================================================

export interface AdminUser extends User {
  emailVerified: boolean;
  _count?: {
    households: number;
  };
}

export interface AdminHousehold extends Household {
  owner?: {
    id: string;
    firstName: string;
    lastName: string;
    email: string;
  };
  _count?: {
    members: number;
    serviceRequests: number;
  };
  homeProfile?: {
    propertyType: PropertyType;
    city: string;
    state: string;
  } | null;
}

export interface AdminDashboardStats {
  totalUsers: number;
  totalHouseholds: number;
  totalServiceRequests: number;
  totalVendors: number;
  usersByRole: { role: string; count: number }[];
  requestsByStatus: { status: string; count: number }[];
}

export interface UpdateUserRoleRequest {
  role: UserRole;
}

export interface CreateServiceCategoryRequest {
  name: string;
  description?: string;
  icon?: string;
  sortOrder?: number;
}

export interface UpdateServiceCategoryRequest {
  name?: string;
  description?: string;
  icon?: string;
  sortOrder?: number;
  isActive?: boolean;
}

// Legacy types for backwards compatibility
export interface Home extends Household {}
export interface ApiResponse<T> {
  data: T;
  message?: string;
  success: boolean;
}
export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}

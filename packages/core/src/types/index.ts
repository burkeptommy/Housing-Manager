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
// API RESPONSE TYPES
// ============================================================================

export interface ApiError {
  message: string;
  error?: string;
  statusCode: number;
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

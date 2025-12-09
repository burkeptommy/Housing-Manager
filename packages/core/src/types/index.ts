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

// ============================================================================
// VENDOR CATEGORY ENUM
// ============================================================================

export type VendorCategory =
  | 'MORTGAGE'
  | 'HOA'
  | 'PROPERTY_TAX'
  | 'ELECTRIC'
  | 'GAS'
  | 'WATER_SEWER'
  | 'TRASH'
  | 'INTERNET'
  | 'MOBILE'
  | 'CABLE'
  | 'HOME_INSURANCE'
  | 'AUTO_INSURANCE'
  | 'HEALTH_INSURANCE'
  | 'LIFE_INSURANCE'
  | 'PET_INSURANCE'
  | 'CREDIT_CARD'
  | 'STUDENT_LOAN'
  | 'PERSONAL_LOAN'
  | 'VEHICLE_LOAN'
  | 'HELOC'
  | 'STREAMING'
  | 'GYM'
  | 'SECURITY_MONITORING'
  | 'PEST_CONTROL'
  | 'LAWN_CARE'
  | 'LANDSCAPING'
  | 'HOME_WARRANTY'
  | 'CLEANING'
  | 'WINDOW_WASHING'
  | 'GUTTER_CLEANING'
  | 'HVAC_SERVICE'
  | 'FILTER_SERVICE'
  | 'CHIMNEY_SWEEP'
  | 'SEPTIC_SERVICE'
  | 'POOL_SERVICE'
  | 'SNOW_REMOVAL'
  | 'HANDYMAN'
  | 'OTHER';

export type BillingFrequency =
  | 'WEEKLY'
  | 'BIWEEKLY'
  | 'MONTHLY'
  | 'QUARTERLY'
  | 'SEMIANNUALLY'
  | 'ANNUAL'
  | 'PER_VISIT'
  | 'PER_JOB'
  | 'OTHER';

export type PaymentResponsibility =
  | 'OWNER_PAYS_DIRECT'
  | 'HAVEN_PAYS_ON_BEHALF'
  | 'VENDOR_AUTOPAY';

export type PaymentMethodType = 'CARD' | 'BANK_ACCOUNT';

export type MaintenanceCategory =
  | 'HVAC'
  | 'PLUMBING'
  | 'ROOF_GUTTER'
  | 'CHIMNEY'
  | 'SEPTIC'
  | 'LANDSCAPING'
  | 'PEST'
  | 'POOL'
  | 'SAFETY'
  | 'CLEANING'
  | 'APPLIANCES'
  | 'EXTERIOR'
  | 'INTERIOR'
  | 'GENERAL';

export type MaintenanceTaskStatus =
  | 'PENDING'
  | 'SCHEDULED'
  | 'COMPLETED'
  | 'SKIPPED'
  | 'OVERDUE';

// ============================================================================
// HOUSEHOLD VENDOR TYPES
// ============================================================================

export interface HouseholdVendor {
  id: string;
  householdId: string;
  displayName: string;
  category: VendorCategory;
  serviceDescription?: string | null;
  isLocal: boolean;
  phone?: string | null;
  email?: string | null;
  websiteUrl?: string | null;
  notes?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateHouseholdVendorRequest {
  displayName: string;
  category: VendorCategory;
  serviceDescription?: string;
  isLocal?: boolean;
  phone?: string;
  email?: string;
  websiteUrl?: string;
  notes?: string;
}

export interface UpdateHouseholdVendorRequest {
  displayName?: string;
  category?: VendorCategory;
  serviceDescription?: string;
  isLocal?: boolean;
  phone?: string;
  email?: string;
  websiteUrl?: string;
  notes?: string;
}

// ============================================================================
// PAYMENT METHOD TYPES
// ============================================================================

export interface PaymentMethod {
  id: string;
  householdId: string;
  stripeCustomerId: string;
  stripePaymentMethodId: string;
  label: string;
  type: PaymentMethodType;
  last4: string;
  expMonth?: number | null;
  expYear?: number | null;
  bankName?: string | null;
  isDefaultForSubscription: boolean;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreatePaymentMethodRequest {
  householdId: string;
  stripePaymentMethodId: string;
  label: string;
  type: PaymentMethodType;
  last4: string;
  expMonth?: number;
  expYear?: number;
  bankName?: string;
  isDefaultForSubscription?: boolean;
}

// ============================================================================
// BILL ACCOUNT TYPES
// ============================================================================

export interface BillAccount {
  id: string;
  householdId: string;
  vendorId: string;
  paymentMethodId?: string | null;
  nickname: string;
  category: VendorCategory;
  accountNumber?: string | null;
  billingFrequency: BillingFrequency;
  paymentResponsibility: PaymentResponsibility;
  typicalAmount?: number | null;
  nextDueDate?: Date | null;
  autopayEnabled: boolean;
  portalUrl?: string | null;
  supportPhone?: string | null;
  notes?: string | null;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
  deletedAt?: Date | null;
  vendor?: HouseholdVendor;
}

export interface CreateBillAccountRequest {
  householdId: string;
  vendorId: string;
  paymentMethodId?: string;
  nickname: string;
  category: VendorCategory;
  accountNumber?: string;
  billingFrequency?: BillingFrequency;
  paymentResponsibility?: PaymentResponsibility;
  typicalAmount?: number;
  nextDueDate?: string;
  autopayEnabled?: boolean;
  portalUrl?: string;
  supportPhone?: string;
  notes?: string;
}

export interface UpdateBillAccountRequest {
  vendorId?: string;
  paymentMethodId?: string | null;
  nickname?: string;
  category?: VendorCategory;
  accountNumber?: string;
  billingFrequency?: BillingFrequency;
  paymentResponsibility?: PaymentResponsibility;
  typicalAmount?: number;
  nextDueDate?: string;
  autopayEnabled?: boolean;
  portalUrl?: string;
  supportPhone?: string;
  notes?: string;
}

// ============================================================================
// MAINTENANCE TEMPLATE TYPES
// ============================================================================

export interface MaintenanceTemplate {
  id: string;
  slug: string;
  title: string;
  description?: string | null;
  category: MaintenanceCategory;
  recommendedFrequencyMonths?: number | null;
  recommendedSeasonStartMonth?: number | null;
  recommendedSeasonEndMonth?: number | null;
  propertyConditionsJson?: Record<string, unknown> | null;
  defaultVendorCategory?: VendorCategory | null;
  estimatedCostMin?: number | null;
  estimatedCostMax?: number | null;
  isActive: boolean;
  sortOrder: number;
  createdAt: Date;
  updatedAt: Date;
}

// ============================================================================
// MAINTENANCE TASK TYPES
// ============================================================================

export interface MaintenanceTask {
  id: string;
  householdId: string;
  templateId?: string | null;
  assignedVendorId?: string | null;
  title: string;
  description?: string | null;
  category: MaintenanceCategory;
  status: MaintenanceTaskStatus;
  dueDate?: Date | null;
  scheduledDate?: Date | null;
  completedAt?: Date | null;
  estimatedCost?: number | null;
  actualCost?: number | null;
  createdFromTemplate: boolean;
  notes?: string | null;
  priority: TaskPriority;
  createdAt: Date;
  updatedAt: Date;
  template?: MaintenanceTemplate | null;
  assignedVendor?: HouseholdVendor | null;
}

export interface CreateMaintenanceTaskRequest {
  householdId: string;
  templateId?: string;
  assignedVendorId?: string;
  title: string;
  description?: string;
  category: MaintenanceCategory;
  dueDate?: string;
  scheduledDate?: string;
  estimatedCost?: number;
  notes?: string;
  priority?: TaskPriority;
}

export interface UpdateMaintenanceTaskRequest {
  assignedVendorId?: string | null;
  title?: string;
  description?: string;
  category?: MaintenanceCategory;
  status?: MaintenanceTaskStatus;
  dueDate?: string | null;
  scheduledDate?: string | null;
  completedAt?: string | null;
  estimatedCost?: number;
  actualCost?: number;
  notes?: string;
  priority?: TaskPriority;
}

export interface GenerateMaintenanceTasksRequest {
  householdId: string;
  templateIds?: string[];
}

export interface GenerateMaintenanceTasksResponse {
  tasks: MaintenanceTask[];
  skippedTemplates: string[];
}

// ============================================================================
// STRIPE TYPES
// ============================================================================

export interface CreateSetupIntentRequest {
  householdId: string;
}

export interface SetupIntentResponse {
  clientSecret: string;
  customerId: string;
}

// ============================================================================
// SUBSCRIPTION PLAN TYPES
// ============================================================================

export type SubscriptionPlan = 'ESSENTIALS' | 'PREMIUM';

export interface SubscriptionPlanDetails {
  id: SubscriptionPlan;
  name: string;
  price: number;
  features: string[];
}

export const SUBSCRIPTION_PLANS: Record<SubscriptionPlan, SubscriptionPlanDetails> = {
  ESSENTIALS: {
    id: 'ESSENTIALS',
    name: 'Essentials',
    price: 9.99,
    features: [
      'Maintenance reminders',
      'Bill tracking',
      'Vendor directory',
      'Basic support',
    ],
  },
  PREMIUM: {
    id: 'PREMIUM',
    name: 'Premium',
    price: 24.99,
    features: [
      'Everything in Essentials',
      'Bill pay on your behalf',
      'Priority support',
      'Concierge service',
      'Document storage',
    ],
  },
};

// ============================================================================
// ONBOARDING STATE TYPES
// ============================================================================

export interface PropertyFeatures {
  hasCentralAc: boolean;
  hasGasHeat: boolean;
  hasOilHeat: boolean;
  hasFireplace: boolean;
  hasSeptic: boolean;
  hasWellWater: boolean;
  hasPool: boolean;
  hasGenerator: boolean;
  hasLawn: boolean;
  hasDriveway: boolean;
}

export interface OnboardingState {
  step: number;
  householdId?: string;
  propertyFeatures?: PropertyFeatures;
  vendors: HouseholdVendor[];
  billAccounts: BillAccount[];
  maintenanceTasks: MaintenanceTask[];
  selectedPlan?: SubscriptionPlan;
  paymentMethodId?: string;
}

// ============================================================================
// REMINDERS & DASHBOARD
// ============================================================================

export type ReminderType = 'BILL_DUE' | 'MAINTENANCE_TASK';
export type ReminderStatus = 'PENDING' | 'SENT' | 'CANCELLED' | 'FAILED';
export type ReminderChannel = 'EMAIL' | 'PUSH' | 'SMS' | 'IN_APP';

export interface Reminder {
  id: string;
  householdId: string;
  type: ReminderType;
  billAccountId?: string | null;
  maintenanceTaskId?: string | null;
  scheduledAt: string;
  sentAt?: string | null;
  status: ReminderStatus;
  channel: ReminderChannel;
  payloadJson?: Record<string, unknown> | null;
  errorMessage?: string | null;
  retryCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface UpcomingBill {
  id: string;
  nickname: string;
  vendorName: string;
  vendorId: string;
  category: VendorCategory;
  typicalAmount?: number;
  nextDueDate: string;
  daysUntilDue: number;
  isOverdue: boolean;
  paymentResponsibility: PaymentResponsibility;
}

export interface UpcomingMaintenanceTask {
  id: string;
  title: string;
  description?: string;
  category: MaintenanceCategory;
  status: MaintenanceTaskStatus;
  dueDate?: string;
  scheduledDate?: string;
  daysUntilDue: number;
  isOverdue: boolean;
  assignedVendorId?: string;
  assignedVendorName?: string;
  estimatedCost?: number;
}

export interface UpcomingItemsResponse {
  upcomingBills: UpcomingBill[];
  upcomingMaintenanceTasks: UpcomingMaintenanceTask[];
}

// Dashboard types
export interface NextUpItem {
  type: 'bill' | 'maintenance';
  id: string;
  title: string;
  category: string;
  vendorName?: string;
  amount?: number;
  daysUntilDue: number;
  dueDate: string;
}

export interface TodayTask {
  type: 'bill' | 'maintenance';
  id: string;
  title: string;
  category: string;
  vendorName?: string;
  amount?: number;
  estimatedCost?: number;
  scheduledTime?: string;
}

export interface DashboardSummary {
  billsManagedThisMonth: number;
  tasksScheduledThisMonth: number;
  tasksCompletedThisMonth: number;
  nextUp?: NextUpItem;
  todaysTasks: TodayTask[];
}

export interface DashboardResponse {
  summary: DashboardSummary;
  upcomingBills: UpcomingBill[];
  upcomingMaintenanceTasks: UpcomingMaintenanceTask[];
}

export interface InAppNotification {
  id: string;
  userId: string;
  householdId?: string;
  title: string;
  body: string;
  link?: string;
  billAccountId?: string;
  maintenanceTaskId?: string;
  reminderId?: string;
  isRead: boolean;
  readAt?: string;
  createdAt: string;
}

export interface CronJobResult {
  success: boolean;
  billRemindersScheduled: number;
  maintenanceRemindersScheduled: number;
  remindersProcessed: number;
  error?: string;
}

// ============================================================================
// VENDOR PAYOUT TYPES (Stripe Connect)
// ============================================================================

export type PayoutMethod = 'STRIPE_CONNECT' | 'CHECK' | 'MANUAL';

export interface VendorPayoutAccount {
  id: string;
  vendorId: string;
  stripeAccountId?: string | null;
  payoutMethod: PayoutMethod;
  payoutDetails?: Record<string, unknown> | null;
  stripeOnboardingComplete: boolean;
  notes?: string | null;
  createdAt: string;
  updatedAt: string;
}

// ============================================================================
// HOUSEHOLD INVOICE TYPES (Consolidated Billing)
// ============================================================================

export type HouseholdInvoiceStatus =
  | 'PENDING'
  | 'PROCESSING'
  | 'PAID'
  | 'FAILED'
  | 'CANCELLED';

export interface HouseholdInvoiceItem {
  id: string;
  billAccountId: string;
  description: string;
  amount: number;
  billNickname?: string;
  vendorName?: string;
  category?: string;
}

export interface HouseholdInvoice {
  id: string;
  householdId: string;
  invoiceNumber: string;
  billingPeriodStart: string;
  billingPeriodEnd: string;
  subtotal: number;
  platformFee: number;
  total: number;
  status: HouseholdInvoiceStatus;
  stripePaymentIntentId?: string;
  stripePaymentStatus?: string;
  paidAt?: string;
  failedAt?: string;
  failureReason?: string;
  items: HouseholdInvoiceItem[];
  createdAt: string;
  updatedAt: string;
}

export interface HouseholdInvoiceListItem {
  id: string;
  invoiceNumber: string;
  billingPeriodStart: string;
  billingPeriodEnd: string;
  total: number;
  status: HouseholdInvoiceStatus;
  itemCount: number;
  createdAt: string;
}

export interface BillingSummary {
  subscriptionTier: string;
  subscriptionAmount: number;
  subscriptionStatus?: string;
  latestInvoice?: HouseholdInvoiceListItem;
  totalBillsManaged: number;
  monthlyBillEstimate: number;
  billAccountsIncluded: Array<{
    id: string;
    nickname: string;
    vendorName: string;
    category: string;
    typicalAmount: number | null;
  }>;
}

export interface SetupHouseholdStripeRequest {
  paymentMethodId: string;
}

export interface UpdateBillingPreferencesRequest {
  consolidatedBillingDay?: number;
}

export interface GenerateInvoicesResult {
  success: boolean;
  invoicesGenerated: number;
  householdsProcessed: number;
  errors?: string[];
}

// ============================================================================
// SUPPORT CHAT TYPES
// ============================================================================

export type ConversationStatus = 'OPEN' | 'PENDING' | 'CLOSED';
export type SenderRole = 'HOMEOWNER' | 'HOME_MANAGER' | 'SYSTEM';

export interface Conversation {
  id: string;
  householdId: string;
  createdByUserId: string;
  subject?: string | null;
  status: ConversationStatus;
  homeownerUnreadCount: number;
  homeManagerUnreadCount: number;
  createdAt: string;
  updatedAt: string;
  // Included in responses
  lastMessage?: SupportMessage;
  createdBy?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  };
  assignments?: HomeManagerAssignment[];
}

export interface SupportMessage {
  id: string;
  conversationId: string;
  senderUserId?: string | null;
  senderRole: SenderRole;
  body: string;
  attachmentUrl?: string | null;
  createdAt: string;
  // Included in responses
  sender?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  } | null;
}

export interface HomeManagerAssignment {
  id: string;
  conversationId: string;
  homeManagerUserId: string;
  assignedAt: string;
  assignedByUserId?: string | null;
  // Included in responses
  homeManager?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  };
}

export interface CreateConversationRequest {
  subject?: string;
  body: string;
  attachmentUrl?: string;
}

export interface SendMessageRequest {
  body: string;
  attachmentUrl?: string;
}

export interface ConversationListQuery {
  status?: ConversationStatus;
  updatedSince?: string;
}

export interface ConversationDetail extends Conversation {
  messages: SupportMessage[];
  household?: {
    id: string;
    name: string;
  };
}

export interface AssignConversationRequest {
  homeManagerUserId: string;
}

export interface InternalConversationListQuery {
  status?: ConversationStatus;
  assignedToMe?: boolean;
  unassigned?: boolean;
}

// ============================================================================
// WORK ORDER TYPES
// ============================================================================

export type WorkOrderStatus =
  | 'DRAFT'
  | 'REQUESTED'
  | 'SCHEDULED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'CANCELLED';

export interface WorkOrder {
  id: string;
  householdId: string;
  maintenanceTaskId?: string | null;
  vendorId?: string | null;
  createdByUserId: string;
  title: string;
  description?: string | null;
  status: WorkOrderStatus;
  preferredDate?: string | null;
  preferredTimeWindowStart?: string | null;
  preferredTimeWindowEnd?: string | null;
  scheduledStart?: string | null;
  scheduledEnd?: string | null;
  estimatedCost?: number | null;
  actualCost?: number | null;
  completedAt?: string | null;
  createdAt: string;
  updatedAt: string;
  // Included in responses
  household?: {
    id: string;
    name: string;
  };
  maintenanceTask?: {
    id: string;
    title: string;
    category: string;
    status: string;
  } | null;
  vendor?: {
    id: string;
    displayName: string;
    phone?: string | null;
    email?: string | null;
    category: string;
  } | null;
  createdBy?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  };
  notes?: WorkOrderNote[];
}

export interface WorkOrderNote {
  id: string;
  workOrderId: string;
  authorUserId: string;
  body: string;
  createdAt: string;
  author?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  };
}

export interface CreateWorkOrderRequest {
  title: string;
  description?: string;
  maintenanceTaskId?: string;
  vendorId?: string;
  preferredDate?: string;
  preferredTimeWindowStart?: string;
  preferredTimeWindowEnd?: string;
}

export interface UpdateWorkOrderRequest {
  title?: string;
  description?: string;
  vendorId?: string;
  status?: WorkOrderStatus;
  scheduledStart?: string;
  scheduledEnd?: string;
  estimatedCost?: number;
  actualCost?: number;
}

export interface CreateWorkOrderNoteRequest {
  body: string;
}

export interface WorkOrderListQuery {
  status?: WorkOrderStatus;
  includeCompleted?: boolean;
}

export interface InternalWorkOrderListQuery {
  status?: WorkOrderStatus;
  unassigned?: boolean;
  upcoming?: boolean;
}

// ============================================================================
// INTERNAL DASHBOARD TYPES
// ============================================================================

export interface InternalDashboardStats {
  activeHouseholds: number;
  openConversations: number;
  unassignedConversations: number;
  openWorkOrders: number;
  todaysAppointments: number;
}

export interface InternalHousehold {
  id: string;
  name: string;
  description?: string | null;
  subscriptionPlan: string;
  subscriptionStatus: string;
  createdAt: string;
  updatedAt: string;
  owner: {
    id: string;
    email: string;
    firstName: string | null;
    lastName: string | null;
    phone?: string | null;
  };
  homeProfile?: {
    id: string;
    propertyType: string;
    addressLine1?: string | null;
    addressLine2?: string | null;
    city?: string | null;
    state?: string | null;
    postalCode?: string | null;
  } | null;
  _count: {
    members: number;
    serviceRequests: number;
    tasks: number;
    billAccounts: number;
    conversations: number;
    workOrders: number;
  };
}

export interface InternalConversation {
  id: string;
  subject?: string | null;
  status: ConversationStatus;
  homeownerUnreadCount: number;
  homeManagerUnreadCount: number;
  createdAt: string;
  updatedAt: string;
  household: {
    id: string;
    name: string;
    owner: {
      firstName: string | null;
      lastName: string | null;
      email: string;
    };
  };
  assignedTo?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  } | null;
  _count: {
    messages: number;
  };
}

export interface InternalWorkOrder {
  id: string;
  title: string;
  description?: string | null;
  status: WorkOrderStatus;
  scheduledStart?: string | null;
  scheduledEnd?: string | null;
  estimatedCost?: number | null;
  actualCost?: number | null;
  createdAt: string;
  updatedAt: string;
  household: {
    id: string;
    name: string;
    homeProfile?: {
      addressLine1?: string | null;
      city?: string | null;
      state?: string | null;
    } | null;
  };
  vendor?: {
    id: string;
    name: string;
    phone?: string | null;
  } | null;
  maintenanceTask?: {
    id: string;
    name: string;
  } | null;
  createdBy: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  };
  _count: {
    notes: number;
  };
}

export interface InternalConversationFilters {
  status?: 'all' | 'unassigned' | 'assigned' | 'closed';
}

export interface InternalWorkOrderFilters {
  status?: WorkOrderStatus | 'all';
  dateFrom?: string;
  dateTo?: string;
}

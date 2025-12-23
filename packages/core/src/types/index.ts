// ============================================================================
// USER TYPES
// ============================================================================

export type UserRole = 'ADMIN' | 'HOMEOWNER' | 'MANAGER' | 'VENDOR' | 'HANDYMAN';

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
  attachmentFileId?: string | null;
  createdAt: string;
  // Included in responses
  sender?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  } | null;
  attachmentFile?: FileAsset | null;
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
  attachmentFileId?: string;
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
  attachmentFileId?: string | null;
  createdAt: string;
  author?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  };
  attachmentFile?: FileAsset | null;
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
  attachmentFileId?: string;
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

// ============================================================================
// FILE ASSET / UPLOAD TYPES
// ============================================================================

export type FileAssetType = 'ISSUE_PHOTO' | 'RECEIPT' | 'DOCUMENT' | 'OTHER';
export type FileAssetStatus = 'PENDING' | 'UPLOADED' | 'FAILED';

export interface FileAsset {
  id: string;
  householdId: string;
  uploaderUserId: string;
  type: FileAssetType;
  status: FileAssetStatus;
  gcsPath: string;
  url?: string | null;
  filename: string;
  contentType: string;
  size?: number | null;
  createdAt: string;
  updatedAt: string;
}

export interface SignUploadRequest {
  filename: string;
  contentType: string;
  type?: FileAssetType;
  householdId: string;
}

export interface SignUploadResponse {
  fileAssetId: string;
  signedUrl: string;
  gcsPath: string;
  expiresAt: string;
}

export interface CompleteUploadRequest {
  fileAssetId: string;
}

export interface CompleteUploadResponse {
  fileAsset: FileAsset;
}

// ============================================================================
// FINANCIAL ENGINE TYPES (The Float)
// ============================================================================

export type TransactionPayoutMethod =
  | 'CHECKBOOK_IO'
  | 'STRIPE'
  | 'CASH'
  | 'COMPANY_CARD'
  | 'BANK_TRANSFER';

export type TransactionStatus =
  | 'PENDING'
  | 'PAID_TO_VENDOR'
  | 'BILLED_TO_CLIENT'
  | 'SETTLED'
  | 'CANCELLED';

export interface Transaction {
  id: string;
  householdId: string;
  vendorId?: string | null;
  managerId: string;
  description: string;
  amount: number;
  payoutMethod: TransactionPayoutMethod;
  status: TransactionStatus;
  isReimbursable: boolean;
  paidAt?: string | null;
  billedAt?: string | null;
  settledAt?: string | null;
  receiptUrl?: string | null;
  receiptFileId?: string | null;
  workOrderId?: string | null;
  maintenanceTaskId?: string | null;
  householdInvoiceId?: string | null;
  notes?: string | null;
  createdAt: string;
  updatedAt: string;
  // Included in responses
  vendor?: {
    id: string;
    displayName: string;
    category: string;
  } | null;
  manager?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
    email: string;
  };
  household?: {
    id: string;
    name: string;
  };
}

export interface CreateTransactionRequest {
  householdId: string;
  vendorId?: string;
  description: string;
  amount: number;
  payoutMethod: TransactionPayoutMethod;
  isReimbursable?: boolean;
  receiptUrl?: string;
  receiptFileId?: string;
  workOrderId?: string;
  maintenanceTaskId?: string;
  notes?: string;
}

export interface UpdateTransactionRequest {
  description?: string;
  amount?: number;
  payoutMethod?: TransactionPayoutMethod;
  status?: TransactionStatus;
  isReimbursable?: boolean;
  receiptUrl?: string;
  receiptFileId?: string;
  notes?: string;
}

export interface TransactionListQuery {
  householdId?: string;
  status?: TransactionStatus;
  startDate?: string;
  endDate?: string;
}

export interface ClientBankAccount {
  id: string;
  householdId: string;
  stripePaymentMethodId: string;
  stripeBankAccountId?: string | null;
  bankName: string;
  accountType: string;
  last4: string;
  routingLast4?: string | null;
  isVerified: boolean;
  verifiedAt?: string | null;
  isDefault: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface HouseholdFinancialSummary {
  currentMonthBalance: number;
  pendingTransactions: number;
  settledThisMonth: number;
  transactions: Transaction[];
  bankAccount?: ClientBankAccount | null;
}

// ============================================================================
// VENDOR PAYOUT / PAYABLES TYPES
// ============================================================================

export interface VendorAddressInfo {
  name: string;
  line1: string;
  line2?: string;
  city: string;
  state: string;
  zip: string;
}

export interface VendorPayable {
  id: string;
  transactionId: string;
  vendorId: string;
  vendorName: string;
  householdId: string;
  householdName: string;
  description: string;
  amount: number;
  status: TransactionStatus;
  createdAt: string;
  vendorAddress?: VendorAddressInfo;
  vendorStripeConnectId?: string;
  vendorEmail?: string;
  availablePayoutMethods: TransactionPayoutMethod[];
  recommendedPayoutMethod: TransactionPayoutMethod;
}

export interface PayoutItem {
  transactionId: string;
  payoutMethod: TransactionPayoutMethod;
}

export interface ExecutePayoutRequest {
  items: PayoutItem[];
}

export interface PayoutResultItem {
  transactionId: string;
  success: boolean;
  payoutMethod: TransactionPayoutMethod;
  referenceId?: string;
  error?: string;
  estimatedDelivery?: string;
}

export interface ExecutePayoutResponse {
  success: boolean;
  totalAmount: number;
  totalItems: number;
  successfulItems: number;
  failedItems: number;
  results: PayoutResultItem[];
  summary?: {
    checksQueued: number;
    stripeTransfers: number;
    totalCheckAmount: number;
    totalStripeAmount: number;
  };
}

export interface BatchPayPreviewItem {
  transactionId: string;
  vendorName: string;
  amount: number;
  payoutMethod: TransactionPayoutMethod;
  methodLabel: string;
}

export interface BatchPayPreview {
  items: BatchPayPreviewItem[];
  totalAmount: number;
  checkCount: number;
  stripeCount: number;
  checkTotal: number;
  stripeTotal: number;
}

// ============================================================================
// SETTLEMENT / MONTHLY INVOICE TYPES
// ============================================================================

export type MonthlyInvoiceStatus = 'PENDING' | 'PROCESSING' | 'PAID' | 'FAILED' | 'PAST_DUE';

export interface TransactionLineItem {
  id: string;
  transactionId: string;
  description: string;
  vendorName: string | null;
  amount: number;
  paidAt: string | null;
  receiptUrl?: string;
  managerNote?: string;
}

export interface MonthlyInvoice {
  id: string;
  invoiceNumber: string;
  householdId: string;
  householdName: string;
  billingPeriodStart: string;
  billingPeriodEnd: string;
  transactionsSubtotal: number;
  managementFee: number;
  total: number;
  status: MonthlyInvoiceStatus;
  stripePaymentIntentId?: string;
  dueDate?: string;
  paidAt?: string;
  failedAt?: string;
  failureReason?: string;
  lineItems: TransactionLineItem[];
  createdAt: string;
}

export interface MonthlyInvoiceListItem {
  id: string;
  invoiceNumber: string;
  billingPeriodStart: string;
  billingPeriodEnd: string;
  total: number;
  status: MonthlyInvoiceStatus;
  itemCount: number;
  paidAt?: string;
  createdAt: string;
}

export interface RevenueStats {
  pendingAmount: number;
  collectedThisMonth: number;
  collectedAllTime: number;
  failedAmount: number;
  pendingInvoices: number;
  paidInvoicesThisMonth: number;
  failedInvoices: number;
  monthlyTrend: MonthlyRevenue[];
}

export interface MonthlyRevenue {
  month: string;
  pending: number;
  collected: number;
  failed: number;
}

export interface HouseholdRevenue {
  householdId: string;
  householdName: string;
  pendingAmount: number;
  collectedAmount: number;
  failedAmount?: number;
  lastInvoiceStatus?: string;
  lastInvoiceDate?: string | null;
  failedInvoiceId?: string;
  lastPaymentDate?: string | null;
}

export interface CollectionResult {
  success: boolean;
  invoiceId: string;
  paymentIntentId?: string;
  status?: string;
  error?: string;
}

// ============================================================================
// VENDOR PORTAL TYPES
// ============================================================================

export type VendorWorkOrderStatus =
  | 'DRAFT'
  | 'REQUESTED'
  | 'SCHEDULED'
  | 'OPEN'
  | 'ASSIGNED'
  | 'IN_PROGRESS'
  | 'COMPLETED'
  | 'VERIFIED'
  | 'CANCELLED';

export interface VendorJobBoardItem {
  id: string;
  title: string;
  description: string | null;
  status: VendorWorkOrderStatus;
  scheduledStart: string | null;
  scheduledEnd: string | null;
  estimatedCost: number | null;
  serviceArea: string | null;
  household: {
    id: string;
    name: string;
  };
  createdAt: string;
}

export interface VendorScheduleItem {
  id: string;
  title: string;
  description: string | null;
  status: VendorWorkOrderStatus;
  scheduledStart: string | null;
  scheduledEnd: string | null;
  estimatedCost: number | null;
  serviceArea: string | null;
  checkInAt: string | null;
  checkOutAt: string | null;
  household: {
    id: string;
    name: string;
    homeProfile?: {
      address: string;
      latitude: number | null;
      longitude: number | null;
    };
  };
}

export interface VendorJobDetail extends VendorScheduleItem {
  proofImages: string[];
  notes: Array<{
    id: string;
    body: string;
    createdAt: string;
    author: {
      id: string;
      firstName: string;
      lastName: string;
    };
  }>;
}

export interface VendorProfile {
  id: string;
  displayName: string;
  category: string;
  email: string | null;
  phone: string | null;
  serviceAreas: string[];
  isVerified: boolean;
}

export interface VerificationQueueItem {
  id: string;
  title: string;
  description: string | null;
  status: VendorWorkOrderStatus;
  completedAt: string | null;
  proofImages: string[];
  actualCost: number | null;
  vendor: {
    id: string;
    displayName: string;
    phone: string | null;
    email: string | null;
  } | null;
  household: {
    id: string;
    name: string;
  };
  notes: Array<{
    id: string;
    body: string;
    createdAt: string;
    author: {
      firstName: string;
      lastName: string;
    };
  }>;
}

// ============================================================================
// CONCIERGE / HANDYMAN TYPES
// ============================================================================

export type WorkOrderBillingType = 'BILLABLE_TO_CLIENT' | 'INCLUSIVE';

export type ServiceCategoryTier = 'MINOR_MAINTENANCE' | 'MAJOR_REPAIR' | 'SPECIALIZED';

export type ConciergeTaskType =
  | 'FILTER_CHANGE'
  | 'LIGHT_BULB'
  | 'LOOSE_HINGE'
  | 'CAULKING'
  | 'MINOR_REPAIR'
  | 'SMOKE_DETECTOR_BATTERY'
  | 'GENERAL_INSPECTION'
  | 'OTHER';

export interface ConciergeRequest {
  id: string;
  title: string;
  description: string | null;
  status: VendorWorkOrderStatus;
  billingType: WorkOrderBillingType;
  isConciergeRequest: boolean;
  scheduledStart: string | null;
  scheduledEnd: string | null;
  handyman: {
    id: string;
    displayName: string | null;
    phone: string | null;
  } | null;
  createdAt: string;
}

export interface CreateConciergeRequestPayload {
  taskType: ConciergeTaskType;
  title: string;
  description?: string;
  preferredDate?: string;
  preferredTimeStart?: string;
  preferredTimeEnd?: string;
  notes?: string;
  addToMonthlyVisit?: boolean;
}

export interface HandymanInfo {
  id: string;
  displayName: string | null;
  firstName: string | null;
  lastName: string | null;
  phone: string | null;
  email: string;
}

export interface HandymanTask {
  id: string;
  title: string;
  householdName: string;
  householdAddress: string;
  address?: string | null;  // Alias for householdAddress (backward compat)
  scheduledStart: string | null;
  status: string;
  billingType: 'INCLUSIVE' | 'BILLABLE' | 'QUOTED';
  estimatedMinutes: number;
  taskType?: string;
  checkedInAt?: string;
  location?: { lat: number; lng: number };
}

export interface HandymanDashboard {
  handymanId: string;
  handymanName: string;
  todaysTasks: HandymanTask[];
  activeTask: HandymanTask | null;
  upcomingTasks: {
    id: string;
    title: string;
    householdName: string;
    scheduledStart: string | null;
    status: string;
  }[];
  assignedHouseholds: {
    id: string;
    name: string;
    address: string;
    nextVisitDate: string;
    monthlyVisitDay?: number | null;
    conciergeEnabled?: boolean;
  }[];
  stats: {
    completedToday: number;
    completedThisWeek: number;
    completedThisMonth: number;
    hoursLoggedToday: number;
    hoursThisWeek: number;
    hoursThisMonth: number;
    pendingTasks: number;
    assignedHouseholds: number;
  };
}

export interface HouseholdProfit {
  householdId: string;
  householdName: string;
  subscriptionPlan: string;
  period: {
    startDate: string;
    endDate: string;
  };
  subscriptionRevenue: number;
  inclusiveCosts: number;
  billableRevenue: number;
  netProfit: number;
  inclusiveTaskCount: number;
  billableTaskCount: number;
}

// ============================================================================
// SOCIAL ENGINE TYPES
// ============================================================================

export type PostVisibility = 'PRIVATE' | 'NEIGHBORS_ONLY' | 'FRIENDS_ONLY' | 'PUBLIC';
export type CostDisplay = 'HIDDEN' | 'RANGE' | 'EXACT';
export type FriendshipStatus = 'PENDING' | 'ACCEPTED' | 'DECLINED' | 'BLOCKED';
export type FeedSource = 'neighbor' | 'friend' | 'following';

// ---- Friendship Types ----

export interface Friendship {
  id: string;
  requesterId: string;
  addresseeId: string;
  status: FriendshipStatus;
  createdAt: string;
  acceptedAt?: string | null;
  requester?: SocialUserSummary;
  addressee?: SocialUserSummary;
}

export interface SocialUserSummary {
  id: string;
  displayName: string | null;
  avatarUrl: string | null;
  isPublicProfile?: boolean;
  influencerBadges?: string[];
  bio?: string | null;
}

// ---- Follow Types ----

export interface Follow {
  id: string;
  followerId: string;
  followingId: string;
  createdAt: string;
  follower?: SocialUserSummary;
  following?: SocialUserSummary;
}

export interface FollowCounts {
  followers: number;
  following: number;
}

// ---- Project Post Types ----

export interface ProjectPost {
  id: string;
  authorId: string;
  householdId: string;
  workOrderId?: string | null;
  vendorId?: string | null;
  title: string;
  description?: string | null;
  beforeImages: string[];
  afterImages: string[];
  visibility: PostVisibility;
  costDisplay: CostDisplay;
  actualCost?: number | null;
  costRangeMin?: number | null;
  costRangeMax?: number | null;
  durationDays?: number | null;
  completedAt?: string | null;
  likesCount: number;
  savesCount: number;
  commentsCount: number;
  isVerified: boolean;
  createdAt: string;
  updatedAt: string;
  // Included in responses
  author?: SocialUserSummary;
  household?: {
    id: string;
    name: string;
    h3Index?: string | null;
  };
  vendor?: {
    id: string;
    displayName: string;
    rating?: number | null;
    category?: string;
  } | null;
  workOrder?: {
    id: string;
    title: string;
    status: string;
  } | null;
  _count?: {
    likes: number;
    saves: number;
    comments: number;
  };
  isLiked?: boolean;
  isSaved?: boolean;
}

export interface CreateProjectPostRequest {
  householdId: string;
  workOrderId?: string;
  vendorId?: string;
  title: string;
  description?: string;
  beforeImages?: string[];
  afterImages?: string[];
  visibility?: PostVisibility;
  costDisplay?: CostDisplay;
  actualCost?: number;
  costRangeMin?: number;
  costRangeMax?: number;
  durationDays?: number;
  completedAt?: string;
}

export interface UpdateProjectPostRequest {
  title?: string;
  description?: string;
  beforeImages?: string[];
  afterImages?: string[];
  visibility?: PostVisibility;
  costDisplay?: CostDisplay;
  actualCost?: number;
  costRangeMin?: number;
  costRangeMax?: number;
  durationDays?: number;
}

// ---- Post Comment Types ----

export interface PostComment {
  id: string;
  postId: string;
  authorId: string;
  content: string;
  createdAt: string;
  updatedAt: string;
  author?: SocialUserSummary;
}

// ---- Feed Types ----

export interface FeedItem {
  post: ProjectPost;
  source: FeedSource;
  isAnonymized: boolean;
  author: {
    id: string;
    displayName: string | null;
    avatarUrl: string | null;
    isInfluencer: boolean;
  };
}

export interface FeedResponse {
  items: FeedItem[];
  hasMore: boolean;
  nextCursor: string | null;
}

export interface FeedQueryParams {
  limit?: number;
  cursor?: string;
  source?: FeedSource;
}

// ---- Social Vendor Types ----

export interface SocialVendorSignals {
  usedByFriendsCount: number;
  usedByNeighborsCount: number;
  usedByInfluencersCount: number;
  friendProjects: Array<{
    userId: string;
    displayName: string;
    postId: string;
    postTitle: string;
  }>;
}

export interface SocialVendorResult {
  vendor: {
    id: string;
    displayName: string;
    rating?: number | null;
    reviewCount?: number;
    category?: string;
    serviceCategory?: {
      name: string;
    };
  };
  socialSignals: SocialVendorSignals;
}

export interface SocialVendorSearchParams {
  category?: string;
  socialProof?: 'friends' | 'neighbors' | 'influencers';
  limit?: number;
  cursor?: string;
}

export interface VendorSocialActivity {
  vendorId: string;
  vendorName: string;
  rating?: number | null;
  reviewCount?: number;
  friendPosts: ProjectPost[];
  neighborPosts: ProjectPost[];
  publicPosts: ProjectPost[];
  totalProjects: number;
}

// ---- Social Profile Types ----

export interface SocialProfile extends SocialUserSummary {
  followers: number;
  following: number;
  areFriends: boolean;
  isFollowing: boolean;
  totalPosts: number;
  totalValueAdded: number;
  createdAt: string;
}

export interface UpdateSocialProfileRequest {
  isPublicProfile?: boolean;
  bio?: string;
  displayName?: string;
}

export interface ProfileStats {
  followers: number;
  following: number;
  totalPosts: number;
  totalValueAdded: number;
}

// ---- Paginated Responses ----

export interface ProjectPostListResponse {
  posts: ProjectPost[];
  hasMore: boolean;
  nextCursor: string | null;
}

export interface CommentListResponse {
  comments: PostComment[];
  hasMore: boolean;
  nextCursor: string | null;
}

export interface SocialVendorSearchResponse {
  vendors: SocialVendorResult[];
  hasMore: boolean;
  nextCursor: string | null;
}

// ============================================================================
// PROJECT PLANNER TYPES
// ============================================================================

export type ProjectIdeaStatus = 'DREAMING' | 'PLANNING' | 'ACTIVE' | 'COMPLETED' | 'ARCHIVED';

export type ProjectCategory =
  | 'BATHROOM_REMODEL'
  | 'KITCHEN_REMODEL'
  | 'DECK_PATIO'
  | 'LANDSCAPING'
  | 'ROOF'
  | 'WINDOWS_DOORS'
  | 'FLOORING'
  | 'PAINTING'
  | 'HVAC'
  | 'ELECTRICAL'
  | 'PLUMBING'
  | 'ADDITION'
  | 'BASEMENT'
  | 'GARAGE'
  | 'FENCE'
  | 'POOL'
  | 'SOLAR'
  | 'SMART_HOME'
  | 'EXTERIOR_SIDING'
  | 'OTHER';

export type RecommendationRequestStatus = 'OPEN' | 'REVIEWING' | 'SELECTED' | 'CLOSED';

// ---- Project Template Types ----

export interface ProjectTemplate {
  id: string;
  slug: string;
  category: ProjectCategory;
  name: string;
  description?: string | null;
  baseMaterialCost: number;
  laborHoursPerSqFt?: number | null;
  baseLaborRate: number;
  complexityFactors?: Record<string, number> | null;
  minSqFt?: number | null;
  maxSqFt?: number | null;
  estimatedDaysMin?: number | null;
  estimatedDaysMax?: number | null;
  inspirationImages: string[];
  isActive: boolean;
  sortOrder: number;
}

export interface ProjectCategoryOption {
  value: ProjectCategory;
  label: string;
  description: string;
}

// ---- Estimation Types ----

export interface ProjectSpecs {
  sqFt: number;
  material?: string;
  complexity?: string[];
}

export interface CalculateEstimateRequest {
  templateId?: string;
  category: ProjectCategory;
  specs: ProjectSpecs;
}

export interface CostBreakdown {
  materials: number;
  labor: number;
  regionalAdjustment: number;
  complexityAdjustment: number;
}

export interface SocialProof {
  neighborProjectCount: number;
  averageCost?: number;
  note: string;
}

export interface EstimateResult {
  estimatedMin: number;
  estimatedMax: number;
  breakdown: CostBreakdown;
  regionalMultiplier: number;
  socialProof: SocialProof;
  templateName?: string;
  estimatedDays?: { min: number; max: number };
}

export interface RegionalMultiplier {
  multiplier: number;
  laborMultiplier: number;
  regionName?: string;
  stateCode?: string;
  h3Index: string;
}

// ---- Project Idea Types ----

export interface ProjectIdea {
  id: string;
  householdId: string;
  createdByUserId: string;
  templateId?: string | null;
  title: string;
  category: ProjectCategory;
  description?: string | null;
  specs?: Record<string, unknown> | null;
  style?: string | null;
  vibeNotes?: string | null;
  moodBoardImages: string[];
  estimatedCostMin?: number | null;
  estimatedCostMax?: number | null;
  neighborProjectCount: number;
  socialProofNote?: string | null;
  status: ProjectIdeaStatus;
  targetStartDate?: string | null;
  targetCompletionDate?: string | null;
  urgency?: string | null;
  workOrderId?: string | null;
  projectPostId?: string | null;
  createdAt: string;
  updatedAt: string;
  // Relations
  template?: { id: string; name: string; slug: string } | null;
  createdBy?: { id: string; displayName: string | null } | null;
}

export interface CreateProjectIdeaRequest {
  templateId?: string;
  title: string;
  category: ProjectCategory;
  description?: string;
  specs?: Record<string, unknown>;
  style?: string;
  vibeNotes?: string;
  moodBoardImages?: string[];
  targetStartDate?: string;
  targetCompletionDate?: string;
  urgency?: string;
  estimatedCostMin?: number;
  estimatedCostMax?: number;
  socialProofNote?: string;
  neighborProjectCount?: number;
}

export interface UpdateProjectIdeaRequest {
  templateId?: string;
  title?: string;
  category?: ProjectCategory;
  description?: string;
  specs?: Record<string, unknown>;
  style?: string;
  vibeNotes?: string;
  moodBoardImages?: string[];
  targetStartDate?: string;
  targetCompletionDate?: string;
  urgency?: string;
  estimatedCostMin?: number;
  estimatedCostMax?: number;
  socialProofNote?: string;
  neighborProjectCount?: number;
}

export interface ProjectIdeasListResponse {
  ideas: ProjectIdea[];
  total: number;
}

export interface ProjectPipelineStats {
  DREAMING: number;
  PLANNING: number;
  ACTIVE: number;
  COMPLETED: number;
  ARCHIVED: number;
}

export interface ConvertToWorkOrderRequest {
  title?: string;
  description?: string;
  vendorId?: string;
}

export interface ConvertToWorkOrderResponse {
  ideaId: string;
  workOrderId: string;
}

// ---- Recommendation Request Types ----

export interface RecommendationRequest {
  id: string;
  projectIdeaId: string;
  householdId: string;
  createdByUserId: string;
  title: string;
  description?: string | null;
  budget?: string | null;
  timeline?: string | null;
  h3Index?: string | null;
  isPublic: boolean;
  status: RecommendationRequestStatus;
  viewCount: number;
  suggestionCount: number;
  expiresAt?: string | null;
  closedAt?: string | null;
  createdAt: string;
  updatedAt: string;
  // Relations
  projectIdea?: {
    id: string;
    title: string;
    category: ProjectCategory;
    estimatedCostMin?: number | null;
    estimatedCostMax?: number | null;
  } | null;
  createdBy?: { id: string; displayName: string | null } | null;
  household?: { id: string; name: string } | null;
}

export interface CreateRecommendationRequestDto {
  projectIdeaId: string;
  title: string;
  description?: string;
  budget?: string;
  timeline?: string;
  isPublic?: boolean;
  expiresAt?: string;
}

export interface RecommendationRequestListResponse {
  requests: RecommendationRequest[];
  total: number;
}

// ---- Vendor Suggestion Types ----

export interface VendorSuggestion {
  id: string;
  projectIdeaId?: string | null;
  recommendationRequestId?: string | null;
  vendorId: string;
  suggestedByUserId?: string | null;
  comment?: string | null;
  rating?: number | null;
  isSystemSuggestion: boolean;
  systemNote?: string | null;
  referenceProjectPostId?: string | null;
  isHelpful?: boolean | null;
  createdAt: string;
  // Relations
  vendor?: {
    id: string;
    companyName: string;
    contactName?: string | null;
    email?: string | null;
    phone?: string | null;
    specialty?: string[];
  } | null;
  suggestedBy?: { id: string; displayName: string | null } | null;
  referenceProjectPost?: {
    id: string;
    title: string;
    mediaUrls: string[];
  } | null;
}

export interface SubmitVendorSuggestionRequest {
  projectIdeaId?: string;
  recommendationRequestId?: string;
  vendorId: string;
  comment?: string;
  rating?: number;
  referenceProjectPostId?: string;
}

// ---- Community Intelligence Types ----

export interface VendorWithSocialSignals {
  vendor: {
    id: string;
    companyName: string;
    contactName?: string;
    specialty?: string[];
    averageRating?: number;
  };
  usedByNeighborsCount: number;
  usedByFriendsCount: number;
  friendRecommendations: Array<{
    userId: string;
    displayName: string;
    projectPostId?: string;
    projectTitle?: string;
  }>;
}

export interface NeighborInspiration {
  id: string;
  title: string;
  description?: string;
  images: string[];
  actualCost?: number;
  authorDisplayName: string;
  isNeighbor: boolean;
  vendorName?: string;
}

// ============================================================================
// CONCIERGE TRIAGE TYPES
// ============================================================================

export type RequestSource = 'EMAIL' | 'SMS' | 'CHAT' | 'WEB' | 'VOICE';

export type RequestCategory =
  | 'BILL_PAY'
  | 'FIX_REQUEST'
  | 'PROJECT_IDEA'
  | 'CALENDAR_EVENT'
  | 'TRIP_PLAN'
  | 'GENERAL_INQUIRY'
  | 'UNKNOWN';

export type TriageStatus =
  | 'RECEIVED'
  | 'PROCESSING'
  | 'PENDING_REVIEW'
  | 'AUTO_APPROVED'
  | 'NEEDS_ATTENTION'
  | 'RESOLVED'
  | 'REJECTED'
  | 'ERROR';

export type TriageActionType =
  | 'PAY_BILL'
  | 'CREATE_WORK_ORDER'
  | 'CREATE_PROJECT'
  | 'CREATE_EVENT'
  | 'CREATE_TRIP'
  | 'RESPOND_INQUIRY'
  | 'UNKNOWN';

export type RequestPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';

// ---- Triage Suggestion Types ----

export interface TriageSuggestion {
  id: string;
  requestId: string;
  actionType: TriageActionType;
  actionData: Record<string, unknown>;
  confidence: number;
  reasoning: string;
  isApproved: boolean;
  createdAt: string;
}

// ---- Inbound Request Types ----

export interface InboundRequest {
  id: string;
  source: RequestSource;
  senderEmail?: string | null;
  senderPhone?: string | null;
  senderUserId?: string | null;
  householdId?: string | null;
  subject?: string | null;
  body: string;
  attachmentUrls: string[];
  category?: RequestCategory | null;
  priority?: RequestPriority | null;
  status: TriageStatus;
  summary?: string | null;
  aiConfidence?: number | null;
  aiReasoning?: string | null;
  extractedEntities?: Record<string, unknown> | null;
  resolvedAction?: string | null;
  resolvedEntityType?: string | null;
  resolvedEntityId?: string | null;
  resolvedAt?: string | null;
  resolvedByUserId?: string | null;
  createdAt: string;
  updatedAt: string;
  // Relations
  senderUser?: {
    id: string;
    email: string;
    firstName: string | null;
    lastName: string | null;
    displayName: string | null;
  } | null;
  household?: {
    id: string;
    name: string;
  } | null;
  suggestions?: TriageSuggestion[];
  resolvedBy?: {
    id: string;
    firstName: string | null;
    lastName: string | null;
  } | null;
}

// ---- Triage List Query Types ----

export interface TriageListQuery {
  status?: TriageStatus;
  source?: RequestSource;
  category?: RequestCategory;
  householdId?: string;
  limit?: number;
  offset?: number;
}

// ---- Triage Stats Types ----

export interface TriageStats {
  total: number;
  byStatus: {
    status: TriageStatus;
    count: number;
  }[];
  byCategory: {
    category: RequestCategory;
    count: number;
  }[];
  todayCount: number;
  pendingReviewCount: number;
  needsAttentionCount: number;
  avgProcessingTimeSeconds: number;
}

// ---- Triage Action Types ----

export interface ApproveTriageActionRequest {
  requestId: string;
  suggestionId: string;
  overrideData?: Record<string, unknown>;
}

export interface RejectTriageRequest {
  requestId: string;
  reason: string;
}

export interface ManualClassifyRequest {
  category: RequestCategory;
  priority?: RequestPriority;
  notes?: string;
}

export interface LinkToHouseholdRequest {
  householdId: string;
}

// ---- Execution Result Types ----

export interface ExecutionResult {
  success: boolean;
  actionType: TriageActionType;
  entityType: string | null;
  entityId: string | null;
  message: string;
  error?: string;
}

// ---- Chat Message Types ----

export interface SendChatMessageRequest {
  message: string;
  attachmentUrls?: string[];
}

export interface ChatResponse {
  requestId: string;
  message: string;
  suggestion?: {
    actionType: TriageActionType;
    description: string;
    confidence: number;
  } | null;
}

// ============================================================================
// FAMILY OPERATIONS TYPES
// ============================================================================

// ---- Enums ----

export type FamilyEventCategory =
  | 'SCHOOL'
  | 'MEDICAL'
  | 'SPORTS'
  | 'SOCIAL'
  | 'WORK'
  | 'TRAVEL'
  | 'MAINTENANCE'
  | 'FINANCIAL'
  | 'RELIGIOUS'
  | 'BIRTHDAY'
  | 'HOLIDAY'
  | 'OTHER';

export type MemberPermissionType =
  | 'VIEW_CALENDAR'
  | 'EDIT_CALENDAR'
  | 'VIEW_BILLS'
  | 'PAY_BILLS'
  | 'VIEW_MAINTENANCE'
  | 'REQUEST_MAINTENANCE'
  | 'VIEW_ASSETS'
  | 'EDIT_ASSETS'
  | 'VIEW_MEMBERS'
  | 'MANAGE_MEMBERS'
  | 'VIEW_BUDGET'
  | 'FULL_ACCESS';

export type VehicleType =
  | 'CAR'
  | 'SUV'
  | 'TRUCK'
  | 'VAN'
  | 'MOTORCYCLE'
  | 'BOAT'
  | 'RV'
  | 'ATV'
  | 'OTHER';

export type FuelType =
  | 'GASOLINE'
  | 'DIESEL'
  | 'ELECTRIC'
  | 'HYBRID'
  | 'PLUG_IN_HYBRID'
  | 'HYDROGEN'
  | 'OTHER';

export type PetType =
  | 'DOG'
  | 'CAT'
  | 'BIRD'
  | 'FISH'
  | 'REPTILE'
  | 'SMALL_MAMMAL'
  | 'HORSE'
  | 'OTHER';

export type PetSize = 'SMALL' | 'MEDIUM' | 'LARGE' | 'EXTRA_LARGE';

export type HomeSystemType =
  | 'FURNACE'
  | 'AIR_CONDITIONER'
  | 'HEAT_PUMP'
  | 'BOILER'
  | 'THERMOSTAT'
  | 'WATER_HEATER'
  | 'WATER_SOFTENER'
  | 'WELL_PUMP'
  | 'SUMP_PUMP'
  | 'ELECTRICAL_PANEL'
  | 'GENERATOR'
  | 'SOLAR_PANELS'
  | 'BATTERY_STORAGE'
  | 'REFRIGERATOR'
  | 'DISHWASHER'
  | 'OVEN_RANGE'
  | 'MICROWAVE'
  | 'GARBAGE_DISPOSAL'
  | 'WASHER'
  | 'DRYER'
  | 'IRRIGATION_SYSTEM'
  | 'POOL_EQUIPMENT'
  | 'HOT_TUB'
  | 'LAWN_MOWER'
  | 'SMOKE_DETECTOR'
  | 'CO_DETECTOR'
  | 'SECURITY_SYSTEM'
  | 'FIRE_EXTINGUISHER'
  | 'GARAGE_DOOR_OPENER'
  | 'CEILING_FAN'
  | 'FIREPLACE'
  | 'OTHER';

export type ApplianceCondition =
  | 'EXCELLENT'
  | 'GOOD'
  | 'FAIR'
  | 'NEEDS_REPAIR'
  | 'REPLACED';

// ---- Member Profile Types ----

export interface MemberProfile {
  birthday?: string;
  shirtSize?: string;
  dietaryRestrictions?: string[];
  allergies?: string[];
  medicalNotes?: string;
  emergencyContact?: string;
  emergencyPhone?: string;
  school?: string;
  grade?: string;
  employer?: string;
  workPhone?: string;
}

export interface UpdateMemberProfileRequest {
  birthday?: string;
  shirtSize?: string;
  dietaryRestrictions?: string[];
  allergies?: string[];
  medicalNotes?: string;
  emergencyContact?: string;
  emergencyPhone?: string;
  school?: string;
  grade?: string;
  employer?: string;
  workPhone?: string;
}

export interface FamilyMember {
  id: string;
  householdId: string;
  userId?: string | null;
  displayName: string;
  role: string;
  isActive: boolean;
  profile?: MemberProfile | null;
  permissions: MemberPermissionType[];
  user?: {
    id: string;
    email: string;
    displayName: string | null;
    photoUrl: string | null;
  } | null;
}

// ---- Vehicle Types ----

export interface Vehicle {
  id: string;
  householdId: string;
  type: VehicleType;
  year?: number | null;
  make?: string | null;
  model?: string | null;
  trim?: string | null;
  color?: string | null;
  vin?: string | null;
  licensePlate?: string | null;
  licenseState?: string | null;
  nickname?: string | null;
  fuelType?: FuelType | null;
  currentMileage?: number | null;
  lastMileageUpdate?: string | null;
  purchaseDate?: string | null;
  purchasePrice?: number | null;
  insuranceProvider?: string | null;
  insurancePolicyNum?: string | null;
  insuranceExpires?: string | null;
  registrationExpires?: string | null;
  inspectionExpires?: string | null;
  lastOilChangeDate?: string | null;
  lastOilChangeMileage?: number | null;
  oilChangeIntervalMiles?: number | null;
  oilChangeIntervalMonths?: number | null;
  lastTireRotationDate?: string | null;
  lastTireRotationMileage?: number | null;
  preferredVendorId?: string | null;
  notes?: string | null;
  photoUrls: string[];
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  serviceRecords?: VehicleServiceRecord[];
  preferredVendor?: {
    id: string;
    displayName: string;
    phone?: string | null;
  } | null;
}

export interface VehicleServiceRecord {
  id: string;
  vehicleId: string;
  serviceType: string;
  serviceDate: string;
  mileageAtService?: number | null;
  cost?: number | null;
  vendorId?: string | null;
  vendorName?: string | null;
  notes?: string | null;
  receiptUrl?: string | null;
  createdAt: string;
  vendor?: {
    id: string;
    displayName: string;
  } | null;
}

export interface CreateVehicleRequest {
  type: VehicleType;
  year?: number;
  make?: string;
  model?: string;
  trim?: string;
  color?: string;
  vin?: string;
  licensePlate?: string;
  licenseState?: string;
  nickname?: string;
  fuelType?: FuelType;
  currentMileage?: number;
  purchaseDate?: string;
  purchasePrice?: number;
  insuranceProvider?: string;
  insurancePolicyNum?: string;
  insuranceExpires?: string;
  registrationExpires?: string;
  inspectionExpires?: string;
  preferredVendorId?: string;
  notes?: string;
  photoUrls?: string[];
}

export interface UpdateVehicleRequest {
  type?: VehicleType;
  year?: number;
  make?: string;
  model?: string;
  trim?: string;
  color?: string;
  vin?: string;
  licensePlate?: string;
  licenseState?: string;
  nickname?: string;
  fuelType?: FuelType;
  currentMileage?: number;
  purchaseDate?: string;
  purchasePrice?: number;
  insuranceProvider?: string;
  insurancePolicyNum?: string;
  insuranceExpires?: string;
  registrationExpires?: string;
  inspectionExpires?: string;
  oilChangeIntervalMiles?: number;
  oilChangeIntervalMonths?: number;
  preferredVendorId?: string;
  notes?: string;
  photoUrls?: string[];
}

export interface CreateVehicleServiceRecordRequest {
  serviceType: string;
  serviceDate: string;
  mileageAtService?: number;
  cost?: number;
  vendorId?: string;
  vendorName?: string;
  notes?: string;
  receiptUrl?: string;
}

export interface VehicleMaintenanceAlert {
  vehicleId: string;
  vehicleName: string;
  type: string;
  message: string;
  severity: 'low' | 'medium' | 'high';
}

// ---- Pet Types ----

export interface Pet {
  id: string;
  householdId: string;
  name: string;
  type: PetType;
  breed?: string | null;
  color?: string | null;
  size?: PetSize | null;
  weight?: number | null;
  birthday?: string | null;
  gender?: string | null;
  microchipId?: string | null;
  isSpayedNeutered?: boolean | null;
  photoUrls: string[];
  vetClinicName?: string | null;
  vetClinicPhone?: string | null;
  vetClinicAddress?: string | null;
  vetClinicEmail?: string | null;
  primaryVetName?: string | null;
  insuranceProvider?: string | null;
  insurancePolicyNum?: string | null;
  insuranceExpires?: string | null;
  licenseNumber?: string | null;
  licenseExpires?: string | null;
  allergies: string[];
  medications: string[];
  specialNeeds?: string | null;
  foodBrand?: string | null;
  foodType?: string | null;
  feedingSchedule?: string | null;
  dietaryNotes?: string | null;
  careInstructions?: string | null;
  emergencyContact?: string | null;
  behavioralNotes?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  vetRecords?: PetVetRecord[];
}

export interface PetVetRecord {
  id: string;
  petId: string;
  visitDate: string;
  visitType: string;
  clinicName?: string | null;
  vetName?: string | null;
  weight?: number | null;
  diagnosis?: string | null;
  treatment?: string | null;
  prescriptions?: Record<string, unknown> | null;
  vaccinationsGiven: string[];
  nextVaccinationDate?: string | null;
  notes?: string | null;
  cost?: number | null;
  receiptUrl?: string | null;
  createdAt: string;
}

export interface CreatePetRequest {
  name: string;
  type: PetType;
  breed?: string;
  color?: string;
  size?: PetSize;
  weight?: number;
  birthday?: string;
  gender?: string;
  microchipId?: string;
  isSpayedNeutered?: boolean;
  photoUrls?: string[];
  vetClinicName?: string;
  vetClinicPhone?: string;
  vetClinicAddress?: string;
  vetClinicEmail?: string;
  primaryVetName?: string;
  insuranceProvider?: string;
  insurancePolicyNum?: string;
  insuranceExpires?: string;
  licenseNumber?: string;
  licenseExpires?: string;
  allergies?: string[];
  medications?: string[];
  specialNeeds?: string;
  foodBrand?: string;
  foodType?: string;
  feedingSchedule?: string;
  dietaryNotes?: string;
  careInstructions?: string;
  emergencyContact?: string;
  behavioralNotes?: string;
}

export interface UpdatePetRequest {
  name?: string;
  type?: PetType;
  breed?: string;
  color?: string;
  size?: PetSize;
  weight?: number;
  birthday?: string;
  gender?: string;
  microchipId?: string;
  isSpayedNeutered?: boolean;
  photoUrls?: string[];
  vetClinicName?: string;
  vetClinicPhone?: string;
  vetClinicAddress?: string;
  vetClinicEmail?: string;
  primaryVetName?: string;
  insuranceProvider?: string;
  insurancePolicyNum?: string;
  insuranceExpires?: string;
  licenseNumber?: string;
  licenseExpires?: string;
  allergies?: string[];
  medications?: string[];
  specialNeeds?: string;
  foodBrand?: string;
  foodType?: string;
  feedingSchedule?: string;
  dietaryNotes?: string;
  careInstructions?: string;
  emergencyContact?: string;
  behavioralNotes?: string;
}

export interface CreatePetVetRecordRequest {
  visitDate: string;
  visitType: string;
  clinicName?: string;
  vetName?: string;
  weight?: number;
  diagnosis?: string;
  treatment?: string;
  prescriptions?: Record<string, unknown>;
  vaccinationsGiven?: string[];
  nextVaccinationDate?: string;
  notes?: string;
  cost?: number;
  receiptUrl?: string;
}

export interface PetPassport {
  id: string;
  name: string;
  type: PetType;
  breed?: string | null;
  color?: string | null;
  size?: PetSize | null;
  weight?: number | null;
  birthday?: string | null;
  gender?: string | null;
  microchipId?: string | null;
  isSpayedNeutered?: boolean | null;
  photoUrls: string[];
  vetClinic: {
    name?: string | null;
    phone?: string | null;
    address?: string | null;
    email?: string | null;
    primaryVet?: string | null;
  };
  insurance?: {
    provider: string;
    policyNumber?: string | null;
    expires?: string | null;
  } | null;
  allergies: string[];
  medications: string[];
  specialNeeds?: string | null;
  vaccinations: Record<string, { date: string; nextDue?: string }>;
  diet: {
    foodBrand?: string | null;
    foodType?: string | null;
    feedingSchedule?: string | null;
    dietaryNotes?: string | null;
  };
  careInstructions?: string | null;
  emergencyContact?: string | null;
  behavioralNotes?: string | null;
}

export interface PetCareAlert {
  petId: string;
  petName: string;
  type: string;
  message: string;
  severity: 'low' | 'medium' | 'high';
}

// ---- Home System Types ----

export interface HomeSystem {
  id: string;
  householdId: string;
  systemType: HomeSystemType;
  name?: string | null;
  brand?: string | null;
  model?: string | null;
  serialNumber?: string | null;
  installDate?: string | null;
  warrantyExpires?: string | null;
  lastServiceDate?: string | null;
  nextServiceDue?: string | null;
  serviceIntervalMonths?: number | null;
  condition?: ApplianceCondition | null;
  location?: string | null;
  notes?: string | null;
  manualUrl?: string | null;
  photoUrls: string[];
  utilityProvider?: string | null;
  accountNumber?: string | null;
  monthlyServiceCost?: number | null;
  autoPayEnabled?: boolean | null;
  tankCapacityGallons?: number | null;
  currentTankLevel?: number | null;
  lastTankReading?: string | null;
  filterSize?: string | null;
  lastFilterChange?: string | null;
  nextFilterChange?: string | null;
  purchasePrice?: number | null;
  preferredVendorId?: string | null;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  serviceHistory?: HomeSystemService[];
  preferredVendor?: {
    id: string;
    displayName: string;
    phone?: string | null;
  } | null;
}

export interface HomeSystemService {
  id: string;
  homeSystemId: string;
  serviceType: string;
  serviceDate: string;
  performedBy?: string | null;
  vendorId?: string | null;
  cost?: number | null;
  notes?: string | null;
  partsReplaced?: Record<string, unknown> | null;
  filterReplaced: boolean;
  nextServiceDate?: string | null;
  receiptUrl?: string | null;
  createdAt: string;
  vendor?: {
    id: string;
    displayName: string;
  } | null;
}

export interface CreateHomeSystemRequest {
  systemType: HomeSystemType;
  name?: string;
  brand?: string;
  model?: string;
  serialNumber?: string;
  installDate?: string;
  warrantyExpires?: string;
  nextServiceDue?: string;
  serviceIntervalMonths?: number;
  condition?: ApplianceCondition;
  location?: string;
  notes?: string;
  manualUrl?: string;
  photoUrls?: string[];
  utilityProvider?: string;
  accountNumber?: string;
  monthlyServiceCost?: number;
  autoPayEnabled?: boolean;
  tankCapacityGallons?: number;
  currentTankLevel?: number;
  filterSize?: string;
  purchasePrice?: number;
  preferredVendorId?: string;
}

export interface UpdateHomeSystemRequest {
  systemType?: HomeSystemType;
  name?: string;
  brand?: string;
  model?: string;
  serialNumber?: string;
  installDate?: string;
  warrantyExpires?: string;
  nextServiceDue?: string;
  serviceIntervalMonths?: number;
  condition?: ApplianceCondition;
  location?: string;
  notes?: string;
  manualUrl?: string;
  photoUrls?: string[];
  utilityProvider?: string;
  accountNumber?: string;
  monthlyServiceCost?: number;
  autoPayEnabled?: boolean;
  tankCapacityGallons?: number;
  currentTankLevel?: number;
  filterSize?: string;
  nextFilterChange?: string;
  purchasePrice?: number;
  preferredVendorId?: string;
}

export interface CreateHomeSystemServiceRequest {
  serviceType: string;
  serviceDate: string;
  performedBy?: string;
  vendorId?: string;
  cost?: number;
  notes?: string;
  partsReplaced?: Record<string, unknown>;
  filterReplaced?: boolean;
  nextServiceDate?: string;
  receiptUrl?: string;
}

export interface HomeSystemMaintenanceAlert {
  systemId: string;
  systemName: string;
  systemType: HomeSystemType;
  type: string;
  message: string;
  severity: 'low' | 'medium' | 'high';
}

export interface HomeDashboard {
  hvac: FormattedHomeSystem[];
  water: FormattedHomeSystem[];
  electrical: FormattedHomeSystem[];
  kitchen: FormattedHomeSystem[];
  laundry: FormattedHomeSystem[];
  outdoor: FormattedHomeSystem[];
  safety: FormattedHomeSystem[];
  other: FormattedHomeSystem[];
  totalSystems: number;
}

export interface FormattedHomeSystem {
  id: string;
  type: HomeSystemType;
  name?: string | null;
  brand?: string | null;
  model?: string | null;
  serialNumber?: string | null;
  installDate?: string | null;
  warrantyExpires?: string | null;
  lastServiceDate?: string | null;
  nextServiceDue?: string | null;
  condition?: ApplianceCondition | null;
  location?: string | null;
  notes?: string | null;
  utilityProvider?: string | null;
  accountNumber?: string | null;
  monthlyServiceCost?: number | null;
  tankCapacity?: number | null;
  currentTankLevel?: number | null;
  lastTankReading?: string | null;
  filterSize?: string | null;
  lastFilterChange?: string | null;
  nextFilterChange?: string | null;
  preferredVendor?: {
    id: string;
    displayName: string;
    phone?: string | null;
  } | null;
  lastService?: {
    date: string;
    type: string;
    notes?: string | null;
  } | null;
}

// ---- Family Event Types ----

export interface FamilyEvent {
  id: string;
  householdId: string;
  createdByUserId: string;
  title: string;
  description?: string | null;
  startDate: string;
  endDate?: string | null;
  isAllDay: boolean;
  location?: string | null;
  recurrenceRule?: string | null;
  category: FamilyEventCategory;
  assignedToMemberId?: string | null;
  color?: string | null;
  vehicleId?: string | null;
  petId?: string | null;
  workOrderId?: string | null;
  createdAt: string;
  updatedAt: string;
  assignedToMember?: {
    id: string;
    displayName: string;
  } | null;
  vehicle?: {
    id: string;
    nickname?: string | null;
    make?: string | null;
    model?: string | null;
  } | null;
  pet?: {
    id: string;
    name: string;
    type: PetType;
  } | null;
  workOrder?: {
    id: string;
    title: string;
    status: string;
  } | null;
}

export interface CreateFamilyEventRequest {
  title: string;
  description?: string;
  startDate: string;
  endDate?: string;
  isAllDay?: boolean;
  location?: string;
  recurrenceRule?: string;
  category?: FamilyEventCategory;
  assignedToMemberId?: string;
  color?: string;
  vehicleId?: string;
  petId?: string;
  workOrderId?: string;
}

export interface UpdateFamilyEventRequest {
  title?: string;
  description?: string;
  startDate?: string;
  endDate?: string;
  isAllDay?: boolean;
  location?: string;
  recurrenceRule?: string;
  category?: FamilyEventCategory;
  assignedToMemberId?: string;
  color?: string;
  vehicleId?: string;
  petId?: string;
  workOrderId?: string;
}

export interface CalendarEvent {
  id: string;
  title: string;
  start: string;
  end?: string;
  allDay: boolean;
  category: string;
  color?: string;
  type: 'family' | 'maintenance';
  meta?: {
    description?: string;
    location?: string;
    assignedTo?: string;
    vehicle?: { id: string; nickname?: string | null };
    pet?: { id: string; name: string };
    vendor?: string;
    status?: string;
    workOrderId?: string;
  };
}

export interface CalendarFeedUrlResponse {
  url: string;
}

export interface CalendarSummary {
  todayCount: number;
  weekCount: number;
  monthCount: number;
  upcomingBirthdays: {
    memberId: string;
    name: string;
    date: string;
    daysUntil: number;
  }[];
}

// ---- Combined Alerts ----

export interface AllFamilyAlerts {
  vehicles: VehicleMaintenanceAlert[];
  pets: PetCareAlert[];
  homeSystems: HomeSystemMaintenanceAlert[];
  total: number;
}

// ============================================================================
// TRAVEL CONCIERGE TYPES
// ============================================================================

export type TripStatus =
  | 'INQUIRY'
  | 'PROPOSAL_SENT'
  | 'PENDING_SELECTION'
  | 'BOOKED'
  | 'ACTIVE'
  | 'COMPLETED'
  | 'CANCELLED';

export type ItineraryItemType =
  | 'FLIGHT'
  | 'STAY'
  | 'CAR_RENTAL'
  | 'ACTIVITY'
  | 'TRANSFER'
  | 'OTHER';

export type SeatingPreference = 'WINDOW' | 'AISLE' | 'MIDDLE' | 'NO_PREFERENCE';

export type HouseProtocolStatus = 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'VERIFIED';

export type ProtocolItemStatus = 'PENDING' | 'COMPLETED' | 'SKIPPED' | 'BLOCKED';

// ---- Travel Profile ----

export interface LoyaltyProgram {
  provider: string;
  number: string;
  tier?: string;
}

export interface TravelProfile {
  id: string;
  householdMemberId: string;
  passportNumber?: string | null;
  passportCountry?: string | null;
  passportExpiry?: string | null;
  tsaPreCheck?: string | null;
  globalEntry?: string | null;
  seatingPreference: SeatingPreference;
  mealPreference?: string | null;
  airlineLoyalty?: LoyaltyProgram[] | null;
  hotelLoyalty?: LoyaltyProgram[] | null;
  carRentalLoyalty?: LoyaltyProgram[] | null;
  emergencyContactName?: string | null;
  emergencyContactPhone?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface TravelProfileWithMember {
  memberId: string;
  displayName: string;
  nickname?: string | null;
  user?: {
    id: string;
    displayName?: string | null;
    email: string;
  };
  travelProfile?: TravelProfile | null;
}

export interface UpdateTravelProfileRequest {
  passportNumber?: string;
  passportCountry?: string;
  passportExpiry?: string;
  tsaPreCheck?: string;
  globalEntry?: string;
  seatingPreference?: SeatingPreference;
  mealPreference?: string;
  airlineLoyalty?: LoyaltyProgram[];
  hotelLoyalty?: LoyaltyProgram[];
  carRentalLoyalty?: LoyaltyProgram[];
  emergencyContactName?: string;
  emergencyContactPhone?: string;
}

// ---- Trip ----

export interface TripTraveler {
  memberId: string;
  role: string; // "adult", "child", "infant"
}

export interface Trip {
  id: string;
  householdId: string;
  createdByUserId: string;
  title: string;
  destination: string;
  destinationCountry?: string | null;
  departureCity?: string | null;
  startDate: string;
  endDate: string;
  isFlexibleDates: boolean;
  budgetMin?: number | null;
  budgetMax?: number | null;
  budgetNotes?: string | null;
  travelerCount: number;
  travelers?: TripTraveler[] | null;
  status: TripStatus;
  notes?: string | null;
  assignedManagerId?: string | null;
  totalEstimatedCost?: number | null;
  totalActualCost?: number | null;
  createdAt: string;
  updatedAt: string;
  // Relations (when included)
  createdBy?: { id: string; displayName?: string | null };
  assignedManager?: { id: string; displayName?: string | null } | null;
  household?: { id: string; name: string };
  proposals?: TripProposal[];
  itineraryItems?: ItineraryItem[];
  houseProtocol?: HouseProtocol | null;
  _count?: {
    proposals?: number;
    itineraryItems?: number;
  };
}

export interface TripListItem extends Omit<Trip, 'proposals' | 'itineraryItems' | 'houseProtocol'> {
  _count?: {
    proposals?: number;
    itineraryItems?: number;
  };
}

export interface CreateTripRequest {
  title: string;
  destination: string;
  destinationCountry?: string;
  departureCity?: string;
  startDate: string;
  endDate: string;
  isFlexibleDates?: boolean;
  budgetMin?: number;
  budgetMax?: number;
  budgetNotes?: string;
  travelerCount?: number;
  travelers?: TripTraveler[];
  notes?: string;
}

export interface UpdateTripRequest extends Partial<CreateTripRequest> {
  status?: TripStatus;
}

// ---- Proposal ----

export interface ProposalOption {
  index: number;
  title: string;
  details: string;
  price: number;
  pros?: string[];
  cons?: string[];
  bookingReference?: string;
  expiresAt?: string;
}

export interface TripProposal {
  id: string;
  tripId: string;
  createdByManagerId: string;
  title: string;
  category: ItineraryItemType;
  description?: string | null;
  options: ProposalOption[];
  selectedOptionIndex?: number | null;
  selectedAt?: string | null;
  sentAt?: string | null;
  expiresAt?: string | null;
  createdAt: string;
  updatedAt: string;
  // Relations
  trip?: { id: string; title: string; householdId: string };
  createdByManager?: { id: string; displayName?: string | null };
}

export interface CreateProposalRequest {
  title: string;
  category: ItineraryItemType;
  description?: string;
  options: ProposalOption[];
  expiresAt?: string;
}

export interface UpdateProposalRequest extends CreateProposalRequest {}

export interface SelectProposalOptionRequest {
  optionIndex: number;
}

// ---- Itinerary ----

export interface ItemDocument {
  name: string;
  fileAssetId?: string;
  url?: string;
}

export interface ItineraryItem {
  id: string;
  tripId: string;
  type: ItineraryItemType;
  title: string;
  description?: string | null;
  startDateTime: string;
  endDateTime?: string | null;
  timezone?: string | null;
  startLocation?: string | null;
  endLocation?: string | null;
  confirmationNumber?: string | null;
  bookingReference?: string | null;
  providerName?: string | null;
  cost: number;
  currency: string;
  paidByHaven: boolean;
  transactionId?: string | null;
  documents?: ItemDocument[] | null;
  sortOrder: number;
  notes?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ItineraryDay {
  date: string;
  dayNumber: number;
  items: ItineraryItem[];
}

export interface CreateItineraryItemRequest {
  type: ItineraryItemType;
  title: string;
  description?: string;
  startDateTime: string;
  endDateTime?: string;
  timezone?: string;
  startLocation?: string;
  endLocation?: string;
  confirmationNumber?: string;
  bookingReference?: string;
  providerName?: string;
  cost: number;
  currency?: string;
  paidByHaven?: boolean;
  documents?: ItemDocument[];
  sortOrder?: number;
  notes?: string;
}

export interface UpdateItineraryItemRequest extends CreateItineraryItemRequest {}

export interface TripDocument extends ItemDocument {
  itemId: string;
  itemTitle: string;
  itemType: ItineraryItemType;
}

// ---- House Protocol ----

export interface HouseProtocolItem {
  id: string;
  protocolId: string;
  title: string;
  description?: string | null;
  category?: string | null;
  status: ProtocolItemStatus;
  completedAt?: string | null;
  completedByUserId?: string | null;
  proofPhotoUrl?: string | null;
  proofFileAssetId?: string | null;
  proofNotes?: string | null;
  sortOrder: number;
  isRequired: boolean;
  createdAt: string;
  updatedAt: string;
  completedBy?: { id: string; displayName?: string | null } | null;
}

export interface HouseProtocol {
  id: string;
  tripId: string;
  householdId: string;
  assignedToUserId?: string | null;
  scheduledDate: string;
  completedAt?: string | null;
  verifiedAt?: string | null;
  verifiedByUserId?: string | null;
  status: HouseProtocolStatus;
  notes?: string | null;
  createdAt: string;
  updatedAt: string;
  // Relations
  trip?: { id: string; title: string; destination: string; startDate: string };
  household?: { id: string; name: string };
  assignedTo?: { id: string; displayName?: string | null } | null;
  items?: HouseProtocolItem[];
  _count?: {
    items?: number;
  };
}

export interface CompleteProtocolItemRequest {
  proofPhotoUrl?: string;
  proofFileAssetId?: string;
  proofNotes?: string;
}

export interface CreateProtocolItemRequest {
  title: string;
  description?: string;
  category?: string;
  sortOrder?: number;
  isRequired?: boolean;
}

// ---- Trip Pipeline (Manager) ----

export interface TripPipeline {
  INQUIRY: TripListItem[];
  PROPOSAL_SENT: TripListItem[];
  PENDING_SELECTION: TripListItem[];
  BOOKED: TripListItem[];
  ACTIVE: TripListItem[];
  COMPLETED: TripListItem[];
  CANCELLED: TripListItem[];
}

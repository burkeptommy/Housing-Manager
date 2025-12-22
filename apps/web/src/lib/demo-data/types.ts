// ============================================================================
// DEMO DATA TYPES
// ============================================================================
// Comprehensive type definitions for Haven demo data
// These types are used across the manager and homeowner portals

// ============================================================================
// UTILITY TYPES
// ============================================================================

export type HouseholdId = 'smith' | 'johnson' | 'miller' | 'williams' | 'chen' | 'davis';
export type PlanType = 'STANDARD' | 'CONCIERGE' | 'ESTATE';
export type RequestStatus = 'NEW' | 'IN_PROGRESS' | 'SCHEDULED' | 'AWAITING_APPROVAL' | 'COMPLETED' | 'CANCELLED';
export type WorkOrderStatus = 'DRAFT' | 'SCHEDULED' | 'IN_PROGRESS' | 'AWAITING_APPROVAL' | 'COMPLETED' | 'CANCELLED';
export type TaskStatus = 'NOT_STARTED' | 'IN_PROGRESS' | 'COMPLETED' | 'OVERDUE' | 'BLOCKED';
export type TaskSource = 'HOMEOWNER' | 'SYSTEM' | 'MANAGER';
export type TaskPriority = 'LOW' | 'MEDIUM' | 'HIGH' | 'URGENT';
export type BillCategory = 'MORTGAGE' | 'UTILITIES' | 'INSURANCE' | 'AUTO' | 'EDUCATION' | 'CHILDCARE' | 'SERVICES' | 'SUBSCRIPTIONS';
export type MemberType = 'ADULT' | 'CHILD' | 'PET' | 'STAFF';
export type HandymanStatus = 'ON_DUTY' | 'ON_JOB' | 'BREAK' | 'OFF_DUTY' | 'UNAVAILABLE';
export type ActivityType = 'REQUEST_SUBMITTED' | 'APPROVAL_RECEIVED' | 'HANDYMAN_CHECKIN' | 'EMAIL_FORWARDED' | 'WORK_ORDER_COMPLETED' | 'PAYMENT_PROCESSED' | 'MESSAGE_RECEIVED';

// ============================================================================
// MANAGER TYPES
// ============================================================================

export interface Manager {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  displayName: string;
  role: 'MANAGER';
  avatar?: string;
  phone: string;
  title: string;
  hireDate: Date;
  settings: ManagerSettings;
  metrics: ManagerMetrics;
}

export interface ManagerSettings {
  notificationsEnabled: boolean;
  emailDigest: 'realtime' | 'daily' | 'weekly';
  defaultView: 'dashboard' | 'tasks' | 'calendar';
  theme: 'light' | 'dark' | 'system';
}

export interface ManagerMetrics {
  householdsManaged: number;
  avgResponseTime: number;
  avgRating: number;
  requestsThisMonth: number;
  tasksCompletedThisMonth: number;
}

// ============================================================================
// HOUSEHOLD TYPES
// ============================================================================

export interface Address {
  street: string;
  city: string;
  state: string;
  zip: string;
  country?: string;
}

export interface PaymentMethod {
  type: 'bank_account' | 'credit_card';
  last4: string;
  bank?: string;
  brand?: string;
}

export interface WifiCredentials {
  ssid: string;
  password: string;
}

export interface AccessCodes {
  gate?: string | null;
  alarm?: string | null;
  alarmDisarm?: string;
  wifi?: WifiCredentials;
  garage?: string;
  lockbox?: string;
  buildingEntry?: string;
  poolHouse?: string;
}

export interface PropertyInfo {
  type: 'single_family' | 'townhouse' | 'condo' | 'apartment';
  yearBuilt: number;
  sqft: number;
  bedrooms: number;
  bathrooms: number;
  lotSize?: number;
  hasPool: boolean;
  hasGarage: boolean;
  garageSpaces?: number;
}

export interface Household {
  id: string;
  name: string;
  address: Address;
  plan: PlanType;
  monthlyFee: number;
  memberSince: Date;
  status: 'ACTIVE' | 'PAUSED' | 'CANCELLED';
  autoPayEnabled: boolean;
  paymentMethod: PaymentMethod;
  accountBalance: number;
  property: PropertyInfo;
  accessCodes: AccessCodes;
  havenEmail: string;
  managerId: string;
  handymanId: string;
  healthScore: number;
  urgentItems: number;
  pendingApprovals: number;
  unreadMessages: number;
  lastContact: Date;
}

// ============================================================================
// FAMILY MEMBER TYPES
// ============================================================================

export interface WorkInfo {
  employer: string;
  title: string;
  address: string;
  schedule: string;
  daysInOffice?: number;
}

export interface HealthInfo {
  doctor?: string;
  doctorPhone?: string;
  pediatrician?: string;
  pediatricianPhone?: string;
  allergies: string[];
  medications: string[];
  epiPenLocation?: string;
}

export interface SizeInfo {
  shirt: string;
  pants: string;
  shoe: string;
  lastUpdated?: Date;
}

export interface ClubMembership {
  name: string;
  type: string;
  memberId: string;
  monthlyDues: number;
}

export interface AdultMember {
  id: string;
  householdId: string;
  type: 'ADULT';
  firstName: string;
  lastName: string;
  displayName: string;
  email: string;
  phone: string;
  role: 'HEAD_OF_HOUSEHOLD' | 'SPOUSE' | 'PARTNER' | 'OTHER';
  isAdmin: boolean;
  work?: WorkInfo;
  primaryVehicleId?: string;
  health?: HealthInfo;
  sizes?: SizeInfo;
  clubs?: ClubMembership[];
  preferences?: {
    contactMethod: 'call' | 'text' | 'email' | 'either';
    bestTimeToReach?: string;
    handlesFinancialDecisions?: boolean;
  };
}

export interface SchoolInfo {
  name: string;
  address: string;
  phone: string;
  tuitionMonthly: number;
  tuitionDueDay?: number;
}

export interface Activity {
  name: string;
  organization: string;
  coach?: string;
  teacher?: string;
  schedule: string;
  monthlyFee: number;
  contact: string;
}

export interface ChildMember {
  id: string;
  householdId: string;
  type: 'CHILD';
  firstName: string;
  lastName: string;
  displayName: string;
  age: number;
  birthDate: Date;
  grade: string;
  school: SchoolInfo;
  activities: Activity[];
  health: HealthInfo;
  sizes?: SizeInfo;
  careProviderId?: string;
}

export interface VetInfo {
  name: string;
  clinic: string;
  phone: string;
  address: string;
}

export interface PetFood {
  brand: string;
  type: string;
  amountPerMonth: string;
  autoReorder: boolean;
}

export interface PetMember {
  id: string;
  householdId: string;
  name: string;
  type: 'DOG' | 'CAT' | 'OTHER';
  breed: string;
  age: number;
  birthDate: Date;
  color: string;
  weight: number;
  vet: VetInfo;
  vaccinesDue: Date;
  lastVetVisit: Date;
  microchipId?: string;
  food?: PetFood;
  monthlyExpenses: number;
  notes?: string;
}

export interface StaffScheduleDay {
  day: string;
  hours: string;
}

export interface EmergencyContact {
  name: string;
  relationship: string;
  phone: string;
}

export interface StaffMember {
  id: string;
  householdId: string;
  type: 'STAFF';
  firstName: string;
  lastName: string;
  displayName: string;
  role: string;
  email: string;
  phone: string;
  agency?: string;
  agencyPhone?: string;
  schedule: StaffScheduleDay[];
  weeklyStipend: number;
  paymentMethod: string;
  permissions: string[];
  startDate: Date;
  contractEndDate?: Date;
  emergencyContact: EmergencyContact;
  notes?: string;
}

// ============================================================================
// VEHICLE TYPES
// ============================================================================

export interface VehicleMileage {
  current: number;
  updatedAt: Date;
  annualEstimate: number;
}

export interface VehicleRegistration {
  state: string;
  expiresAt: Date;
}

export interface VehicleInsurance {
  provider: string;
  policyNumber: string;
  expiresAt: Date;
  monthlyPremium: number;
}

export interface VehicleLoan {
  hasLoan: boolean;
  lender?: string;
  monthlyPayment?: number;
  balance?: number;
  maturityDate?: Date;
}

export interface VehicleService {
  lastServiceDate: Date;
  lastServiceMileage: number;
  lastOilChange?: Date;
  oilChangeMileage?: number;
  nextServiceDue: Date;
  nextServiceMileage: number;
  preferredShop: string;
}

export interface ServiceHistoryItem {
  date: Date;
  type: string;
  mileage: number;
  cost: number;
  shop: string;
}

export interface Vehicle {
  id: string;
  householdId: string;
  name: string;
  make: string;
  model: string;
  year: number;
  trim?: string;
  color: string;
  vin: string;
  licensePlate: string;
  primaryDriverId: string;
  mileage: VehicleMileage;
  registration: VehicleRegistration;
  insurance: VehicleInsurance;
  loan?: VehicleLoan;
  service: VehicleService;
  serviceHistory: ServiceHistoryItem[];
}

// ============================================================================
// REQUEST & WORK ORDER TYPES
// ============================================================================

export interface Photo {
  id: string;
  url: string;
  caption?: string;
}

export interface AITriageSuggestion {
  category: string;
  recommendedAction: string;
  estimatedCost: { min: number; max: number };
  suggestedVendor: string;
  confidence: number;
}

export interface ServiceRequest {
  id: string;
  visibleId: string;
  householdId: string;
  submittedBy?: string;
  submittedAt: Date;
  title: string;
  description: string;
  category: string;
  location?: string;
  priority: TaskPriority;
  status: RequestStatus;
  photos?: Photo[];
  aiTriageSuggestion?: AITriageSuggestion;
  workOrderId?: string;
  scheduledDate?: Date;
  scheduledTime?: string;
  assignedVendor?: string;
  quotedAmount?: number;
  quoteSentAt?: Date;
  approvalDeadline?: Date;
  managerNotes?: string;
}

export interface VendorQuote {
  vendorId: string;
  vendorName: string;
  amount: number;
  submittedAt: Date;
}

export interface WorkOrderAssignment {
  type: 'vendor' | 'handyman';
  vendorId?: string;
  vendorName?: string;
  technicianName?: string;
  technicianPhone?: string;
  handymanId?: string;
  handymanName?: string;
  handymanPhone?: string;
}

export interface WorkOrder {
  id: string;
  visibleId: string;
  householdId: string;
  requestId?: string;
  title: string;
  description: string;
  category: string;
  priority: TaskPriority;
  status: WorkOrderStatus;
  assignedTo: WorkOrderAssignment;
  scheduledDate?: Date;
  scheduledTime?: string;
  estimatedDuration?: number;
  estimatedCost?: number;
  requiresApproval: boolean;
  quotes?: VendorQuote[];
  selectedQuote?: number;
  approvalSentAt?: Date;
  approvalReminders?: number;
  accessInstructions?: string;
  managerNote?: string;
  createdAt: Date;
  createdBy: string;
}

// ============================================================================
// TASK TYPES
// ============================================================================

export interface TaskProgress {
  note: string;
  addedAt: Date;
  completed: boolean;
}

export interface Task {
  id: string;
  householdId: string;
  title: string;
  description: string;
  source: TaskSource;
  requestedBy?: string;
  requestedAt?: Date;
  generatedFrom?: string;
  dueDate: Date;
  priority: TaskPriority;
  status: TaskStatus;
  progress?: TaskProgress[];
  notifyOnComplete?: boolean;
  linkedAssetId?: string;
  linkedBillAccountId?: string;
  linkedVehicleId?: string;
  linkedStaffId?: string;
  amount?: number;
}

// ============================================================================
// BILL TYPES
// ============================================================================

export interface BillPayment {
  amount: number;
  paidAt: Date;
  confirmationNumber?: string;
}

export interface BillDue {
  amount: number;
  dueDate: Date;
}

export interface Bill {
  id: string;
  householdId: string;
  vendor: string;
  category: BillCategory;
  accountNumber?: string;
  linkedMemberId?: string;
  linkedStaffId?: string;
  amount: number;
  frequency: 'WEEKLY' | 'MONTHLY' | 'QUARTERLY' | 'ANNUAL';
  dueDay?: number;
  autoPayEnabled: boolean;
  paymentMethod?: string;
  lastPaid?: BillPayment;
  nextDue: BillDue;
  status?: 'CURRENT' | 'DUE_SOON' | 'OVERDUE';
}

// ============================================================================
// MESSAGE TYPES
// ============================================================================

export interface MessageAttachment {
  type: 'image' | 'file' | 'link';
  url: string;
  name?: string;
}

export interface MessageMetadata {
  linkedWorkOrder?: string;
  linkedRequest?: string;
}

export interface Message {
  id: string;
  conversationId: string;
  householdId: string;
  senderId: string;
  senderType: 'HOMEOWNER' | 'MANAGER' | 'VENDOR' | 'SYSTEM';
  senderName: string;
  content: string;
  attachments?: MessageAttachment[];
  metadata?: MessageMetadata;
  sentAt: Date;
  readAt?: Date | null;
}

// ============================================================================
// VENDOR & HANDYMAN TYPES
// ============================================================================

export interface VendorContact {
  name: string;
  phone: string;
  email?: string;
}

export interface VendorService {
  name: string;
  price?: number;
  priceRange?: string;
}

export interface VendorDocuments {
  insurance?: { expiry: Date };
  license?: string;
  w9?: boolean;
}

export interface Vendor {
  id: string;
  name: string;
  category: string;
  contact: VendorContact;
  address?: string;
  serviceArea?: string[];
  rating: number;
  totalJobs: number;
  totalBilled?: number;
  priceRange?: string;
  responseTime?: string;
  services?: VendorService[];
  notes?: string;
  documents?: VendorDocuments;
}

export interface HandymanScheduleItem {
  date: Date;
  householdId: string;
  time: string;
  task: string;
  status: 'SCHEDULED' | 'IN_PROGRESS' | 'COMPLETED';
}

export interface HandymanLocation {
  householdId: string;
  checkedInAt: Date;
  taskDescription: string;
}

export interface Handyman {
  id: string;
  firstName: string;
  lastName: string;
  displayName: string;
  phone: string;
  email?: string;
  role: 'PRIMARY' | 'BACKUP';
  serviceArea: string;
  status: HandymanStatus;
  currentLocation?: HandymanLocation;
  nextAvailable?: Date;
  schedule: HandymanScheduleItem[];
  specialties: string[];
  rating: number;
  jobsCompleted: number;
}

// ============================================================================
// SCHEDULE & ACTIVITY TYPES
// ============================================================================

export interface ScheduleCall {
  householdId: string;
  topic: string;
}

export interface ScheduleEvent {
  id: string;
  type: 'BLOCK' | 'SITE_VISIT' | 'CALL_BLOCK' | 'BILL_PAY' | 'VENDOR_APPOINTMENT';
  title: string;
  description?: string;
  householdId?: string;
  workOrderId?: string;
  vendorName?: string;
  handymanId?: string;
  startTime: number;
  duration: number;
  address?: string;
  accessNotes?: string;
  calls?: ScheduleCall[];
  tasks?: string[];
}

export interface ActivityItem {
  id: string;
  type: ActivityType;
  householdId: string;
  householdName: string;
  description: string;
  timestamp: Date;
  read: boolean;
}

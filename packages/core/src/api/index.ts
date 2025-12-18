import type {
  User,
  AuthResponse,
  RegisterRequest,
  LoginRequest,
  RefreshTokenRequest,
  Household,
  HouseholdDetail,
  CreateHouseholdRequest,
  UpdateHouseholdRequest,
  HomeProfile,
  UpsertHomeProfileRequest,
  ServiceCategory,
  ServiceRequest,
  ServiceRequestDetail,
  CreateServiceRequestRequest,
  UpdateServiceRequestRequest,
  Subscription,
  CreateSubscriptionRequest,
  ApiError,
  ManagedHousehold,
  Vendor,
  FileUpload,
  UploadResponse,
  FileCategory,
  AdminUser,
  AdminHousehold,
  AdminDashboardStats,
  UpdateUserRoleRequest,
  CreateServiceCategoryRequest,
  UpdateServiceCategoryRequest,
  HouseholdVendor,
  CreateHouseholdVendorRequest,
  UpdateHouseholdVendorRequest,
  BillAccount,
  CreateBillAccountRequest,
  UpdateBillAccountRequest,
  MaintenanceTemplate,
  MaintenanceTask,
  CreateMaintenanceTaskRequest,
  UpdateMaintenanceTaskRequest,
  GenerateMaintenanceTasksRequest,
  GenerateMaintenanceTasksResponse,
  PaymentMethod,
  CreatePaymentMethodRequest,
  SetupIntentResponse,
  VendorCategory,
  UpcomingItemsResponse,
  InAppNotification,
  HouseholdInvoice,
  HouseholdInvoiceListItem,
  BillingSummary,
  DashboardResponse,
  WorkOrder,
  CreateWorkOrderRequest,
  UpdateWorkOrderRequest,
  WorkOrderStatus,
  CreateWorkOrderNoteRequest,
  WorkOrderNote,
  InternalDashboardStats,
  InternalHousehold,
  InternalConversation,
  InternalWorkOrder,
  InternalConversationFilters,
  InternalWorkOrderFilters,
  Conversation,
  ConversationDetail,
  ConversationStatus,
  ConversationListQuery,
  CreateConversationRequest,
  SendMessageRequest,
  SupportMessage,
  FileAsset,
  FileAssetType,
  SignUploadRequest,
  SignUploadResponse,
  CompleteUploadResponse,
  VendorPayable,
  ExecutePayoutRequest,
  ExecutePayoutResponse,
  BatchPayPreview,
  MonthlyInvoice,
  MonthlyInvoiceListItem,
  RevenueStats,
  HouseholdRevenue,
  CollectionResult,
  ConciergeRequest,
  CreateConciergeRequestPayload,
  HandymanDashboard,
  HandymanInfo,
  // Social Engine types
  SocialUserSummary,
  Friendship,
  Follow,
  FollowCounts,
  ProjectPost,
  CreateProjectPostRequest,
  UpdateProjectPostRequest,
  PostComment,
  FeedResponse,
  FeedQueryParams,
  SocialVendorSearchParams,
  SocialVendorSearchResponse,
  VendorSocialActivity,
  SocialProfile,
  UpdateSocialProfileRequest,
  ProfileStats,
  ProjectPostListResponse,
  CommentListResponse,
  // Project Planner types
  ProjectTemplate,
  ProjectCategoryOption,
  ProjectCategory,
  CalculateEstimateRequest,
  EstimateResult,
  RegionalMultiplier,
  ProjectIdea,
  ProjectIdeaStatus,
  CreateProjectIdeaRequest,
  UpdateProjectIdeaRequest,
  ProjectIdeasListResponse,
  ProjectPipelineStats,
  ConvertToWorkOrderRequest,
  ConvertToWorkOrderResponse,
  RecommendationRequest,
  RecommendationRequestStatus,
  CreateRecommendationRequestDto,
  RecommendationRequestListResponse,
  VendorSuggestion,
  SubmitVendorSuggestionRequest,
  VendorWithSocialSignals,
  NeighborInspiration,
  // Triage types
  InboundRequest,
  TriageListQuery,
  TriageStats,
  ApproveTriageActionRequest,
  ExecutionResult,
  RequestCategory,
  RequestPriority,
  // Family Operations types
  FamilyMember,
  UpdateMemberProfileRequest,
  MemberPermissionType,
  Vehicle,
  VehicleServiceRecord,
  CreateVehicleRequest,
  UpdateVehicleRequest,
  CreateVehicleServiceRecordRequest,
  VehicleMaintenanceAlert,
  Pet,
  PetVetRecord,
  CreatePetRequest,
  UpdatePetRequest,
  CreatePetVetRecordRequest,
  PetPassport,
  PetCareAlert,
  HomeSystem,
  HomeSystemService,
  HomeSystemType,
  CreateHomeSystemRequest,
  UpdateHomeSystemRequest,
  CreateHomeSystemServiceRequest,
  HomeSystemMaintenanceAlert,
  HomeDashboard,
  FamilyEvent,
  FamilyEventCategory,
  CreateFamilyEventRequest,
  UpdateFamilyEventRequest,
  CalendarEvent,
  CalendarFeedUrlResponse,
  CalendarSummary,
  AllFamilyAlerts,
  // Travel Concierge types
  TravelProfile,
  TravelProfileWithMember,
  UpdateTravelProfileRequest,
  Trip,
  TripListItem,
  TripStatus,
  CreateTripRequest,
  UpdateTripRequest,
  TripProposal,
  CreateProposalRequest,
  UpdateProposalRequest,
  ItineraryItem,
  ItineraryDay,
  CreateItineraryItemRequest,
  UpdateItineraryItemRequest,
  TripDocument,
  HouseProtocol,
  HouseProtocolItem,
  CompleteProtocolItemRequest,
  CreateProtocolItemRequest,
  TripPipeline,
} from '../types';

export interface ApiClientConfig {
  baseUrl: string;
  getAccessToken?: () => string | null;
  getRefreshToken?: () => string | null;
  onTokenRefresh?: (tokens: { accessToken: string; refreshToken: string }) => void;
  onUnauthorized?: () => void;
}

export class ApiClient {
  private config: ApiClientConfig;
  private isRefreshing = false;
  private refreshPromise: Promise<boolean> | null = null;

  constructor(config: ApiClientConfig) {
    this.config = config;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
    skipAuth = false
  ): Promise<T> {
    const url = `${this.config.baseUrl}${endpoint}`;
    const token = skipAuth ? null : this.config.getAccessToken?.();

    const headers: HeadersInit = {
      'Content-Type': 'application/json',
      ...options.headers,
    };

    if (token) {
      (headers as Record<string, string>)['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(url, {
      ...options,
      headers,
      credentials: 'include',
    });

    // Handle 401 - try to refresh token
    if (response.status === 401 && !skipAuth) {
      const refreshed = await this.tryRefreshToken();
      if (refreshed) {
        // Retry the original request
        return this.request<T>(endpoint, options, false);
      } else {
        this.config.onUnauthorized?.();
        throw { message: 'Unauthorized', statusCode: 401 } as ApiError;
      }
    }

    if (!response.ok) {
      const error = await response.json().catch(() => ({
        message: 'An error occurred',
        statusCode: response.status,
      })) as ApiError;
      throw error;
    }

    // Handle empty responses (204 No Content)
    if (response.status === 204) {
      return undefined as T;
    }

    return response.json() as Promise<T>;
  }

  private async tryRefreshToken(): Promise<boolean> {
    // Prevent multiple simultaneous refresh attempts
    if (this.isRefreshing) {
      return this.refreshPromise || Promise.resolve(false);
    }

    const refreshToken = this.config.getRefreshToken?.();
    if (!refreshToken) {
      return false;
    }

    this.isRefreshing = true;
    this.refreshPromise = (async () => {
      try {
        const response = await this.refreshAccessToken({ refreshToken });
        this.config.onTokenRefresh?.({
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        });
        return true;
      } catch {
        return false;
      } finally {
        this.isRefreshing = false;
        this.refreshPromise = null;
      }
    })();

    return this.refreshPromise;
  }

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================

  async register(data: RegisterRequest): Promise<AuthResponse> {
    return this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(data),
    }, true);
  }

  async login(data: LoginRequest): Promise<AuthResponse> {
    return this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify(data),
    }, true);
  }

  async refreshAccessToken(data: RefreshTokenRequest): Promise<AuthResponse> {
    return this.request('/auth/refresh', {
      method: 'POST',
      body: JSON.stringify(data),
    }, true);
  }

  async getMe(): Promise<User> {
    return this.request('/auth/me');
  }

  // ============================================================================
  // HOUSEHOLD ENDPOINTS
  // ============================================================================

  async getHouseholds(): Promise<Household[]> {
    return this.request('/households');
  }

  async getHousehold(id: string): Promise<HouseholdDetail> {
    return this.request(`/households/${id}`);
  }

  async createHousehold(data: CreateHouseholdRequest): Promise<Household> {
    return this.request('/households', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateHousehold(id: string, data: UpdateHouseholdRequest): Promise<Household> {
    return this.request(`/households/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async deleteHousehold(id: string): Promise<void> {
    return this.request(`/households/${id}`, {
      method: 'DELETE',
    });
  }

  // ============================================================================
  // HOME PROFILE ENDPOINTS
  // ============================================================================

  async getHomeProfile(householdId: string): Promise<HomeProfile | null> {
    return this.request(`/households/${householdId}/profile`);
  }

  async upsertHomeProfile(householdId: string, data: UpsertHomeProfileRequest): Promise<HomeProfile> {
    return this.request(`/households/${householdId}/profile`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  // ============================================================================
  // SERVICE CATEGORY ENDPOINTS
  // ============================================================================

  async getServiceCategories(includeInactive = false): Promise<ServiceCategory[]> {
    const query = includeInactive ? '?includeInactive=true' : '';
    return this.request(`/service-categories${query}`);
  }

  // ============================================================================
  // SERVICE REQUEST ENDPOINTS
  // ============================================================================

  async getServiceRequests(householdId: string): Promise<ServiceRequest[]> {
    return this.request(`/requests?householdId=${householdId}`);
  }

  async getServiceRequest(id: string): Promise<ServiceRequestDetail> {
    return this.request(`/requests/${id}`);
  }

  async getManagerRequests(): Promise<ServiceRequestDetail[]> {
    return this.request('/manager/requests');
  }

  // Filter managed households (those where user has MANAGER role)
  async getManagedHouseholds(): Promise<ManagedHousehold[]> {
    return this.request('/households');
  }

  // ============================================================================
  // VENDOR ENDPOINTS
  // ============================================================================

  async getVendors(): Promise<Vendor[]> {
    return this.request('/vendors');
  }

  async getVendor(id: string): Promise<Vendor> {
    return this.request(`/vendors/${id}`);
  }

  async createServiceRequest(data: CreateServiceRequestRequest): Promise<ServiceRequestDetail> {
    return this.request('/requests', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateServiceRequest(id: string, data: UpdateServiceRequestRequest): Promise<ServiceRequestDetail> {
    return this.request(`/requests/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  // ============================================================================
  // SUBSCRIPTION / BILLING ENDPOINTS
  // ============================================================================

  async getSubscription(): Promise<Subscription | null> {
    return this.request('/billing/subscription');
  }

  async createSubscription(data: CreateSubscriptionRequest): Promise<Subscription> {
    return this.request('/billing/subscribe', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async cancelSubscription(cancelAtPeriodEnd = true): Promise<Subscription> {
    return this.request('/billing/subscription', {
      method: 'DELETE',
      body: JSON.stringify({ cancelAtPeriodEnd }),
    });
  }

  // ============================================================================
  // FILE UPLOAD ENDPOINTS
  // ============================================================================

  async uploadFile(
    file: File | Blob,
    options: {
      householdId: string;
      category?: FileCategory;
      description?: string;
      serviceRequestId?: string;
      taskId?: string;
    },
  ): Promise<UploadResponse> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('householdId', options.householdId);
    if (options.category) formData.append('category', options.category);
    if (options.description) formData.append('description', options.description);
    if (options.serviceRequestId) formData.append('serviceRequestId', options.serviceRequestId);
    if (options.taskId) formData.append('taskId', options.taskId);

    const url = `${this.config.baseUrl}/files/upload`;
    const token = this.config.getAccessToken?.();

    const headers: HeadersInit = {};
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    // Don't set Content-Type - browser will set it with boundary for multipart

    const response = await fetch(url, {
      method: 'POST',
      headers,
      body: formData,
      credentials: 'include',
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({
        message: 'Upload failed',
        statusCode: response.status,
      })) as ApiError;
      throw error;
    }

    return response.json() as Promise<UploadResponse>;
  }

  async getFile(id: string): Promise<FileUpload & { url: string }> {
    return this.request(`/files/${id}`);
  }

  async getFileUrl(id: string): Promise<string> {
    const result = await this.request<{ url: string }>(`/files/${id}/url`);
    return result.url;
  }

  async getHouseholdFiles(householdId: string, category?: FileCategory): Promise<FileUpload[]> {
    const query = category ? `?householdId=${householdId}&category=${category}` : `?householdId=${householdId}`;
    return this.request(`/files${query}`);
  }

  async getServiceRequestFiles(requestId: string): Promise<(FileUpload & { url: string })[]> {
    return this.request(`/files/request/${requestId}`);
  }

  async deleteFile(id: string): Promise<void> {
    return this.request(`/files/${id}`, { method: 'DELETE' });
  }

  // ============================================================================
  // ADMIN ENDPOINTS
  // ============================================================================

  async getAdminStats(): Promise<AdminDashboardStats> {
    return this.request('/admin/stats');
  }

  async getAdminUsers(): Promise<AdminUser[]> {
    return this.request('/admin/users');
  }

  async getAdminUser(id: string): Promise<AdminUser> {
    return this.request(`/admin/users/${id}`);
  }

  async updateUserRole(id: string, data: UpdateUserRoleRequest): Promise<AdminUser> {
    return this.request(`/admin/users/${id}/role`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async toggleUserActive(id: string): Promise<AdminUser> {
    return this.request(`/admin/users/${id}/toggle-active`, {
      method: 'PATCH',
    });
  }

  async getAdminHouseholds(): Promise<AdminHousehold[]> {
    return this.request('/admin/households');
  }

  async getAdminHousehold(id: string): Promise<AdminHousehold> {
    return this.request(`/admin/households/${id}`);
  }

  async getAdminServiceCategories(): Promise<ServiceCategory[]> {
    return this.request('/admin/service-categories');
  }

  async createServiceCategory(data: CreateServiceCategoryRequest): Promise<ServiceCategory> {
    return this.request('/admin/service-categories', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateServiceCategory(id: string, data: UpdateServiceCategoryRequest): Promise<ServiceCategory> {
    return this.request(`/admin/service-categories/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  // ============================================================================
  // HOUSEHOLD VENDOR ENDPOINTS
  // ============================================================================

  async getHouseholdVendors(householdId: string, category?: VendorCategory): Promise<HouseholdVendor[]> {
    const query = category ? `?category=${category}` : '';
    return this.request(`/households/${householdId}/vendors${query}`);
  }

  async createHouseholdVendor(householdId: string, data: CreateHouseholdVendorRequest): Promise<HouseholdVendor> {
    return this.request(`/households/${householdId}/vendors`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateHouseholdVendor(householdId: string, vendorId: string, data: UpdateHouseholdVendorRequest): Promise<HouseholdVendor> {
    return this.request(`/households/${householdId}/vendors/${vendorId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async deleteHouseholdVendor(householdId: string, vendorId: string): Promise<void> {
    return this.request(`/households/${householdId}/vendors/${vendorId}`, {
      method: 'DELETE',
    });
  }

  // ============================================================================
  // BILL ACCOUNT ENDPOINTS
  // ============================================================================

  async getBillAccounts(
    householdId: string,
    options?: { category?: VendorCategory; upcomingDays?: number }
  ): Promise<BillAccount[]> {
    const params = new URLSearchParams({ householdId });
    if (options?.category) params.append('category', options.category);
    if (options?.upcomingDays) params.append('upcomingDays', options.upcomingDays.toString());
    return this.request(`/bill-accounts?${params.toString()}`);
  }

  async createBillAccount(data: CreateBillAccountRequest): Promise<BillAccount> {
    return this.request('/bill-accounts', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateBillAccount(id: string, data: UpdateBillAccountRequest): Promise<BillAccount> {
    return this.request(`/bill-accounts/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async deleteBillAccount(id: string): Promise<void> {
    return this.request(`/bill-accounts/${id}`, {
      method: 'DELETE',
    });
  }

  // ============================================================================
  // MAINTENANCE TEMPLATE ENDPOINTS
  // ============================================================================

  async getMaintenanceTemplates(): Promise<MaintenanceTemplate[]> {
    return this.request('/maintenance-tasks/templates');
  }

  // ============================================================================
  // MAINTENANCE TASK ENDPOINTS
  // ============================================================================

  async getMaintenanceTasks(
    householdId: string,
    options?: { status?: string; category?: string }
  ): Promise<MaintenanceTask[]> {
    const params = new URLSearchParams({ householdId });
    if (options?.status) params.append('status', options.status);
    if (options?.category) params.append('category', options.category);
    return this.request(`/maintenance-tasks?${params.toString()}`);
  }

  async getMaintenanceTask(id: string): Promise<MaintenanceTask> {
    return this.request(`/maintenance-tasks/${id}`);
  }

  async createMaintenanceTask(data: CreateMaintenanceTaskRequest): Promise<MaintenanceTask> {
    return this.request('/maintenance-tasks', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateMaintenanceTask(id: string, data: UpdateMaintenanceTaskRequest): Promise<MaintenanceTask> {
    return this.request(`/maintenance-tasks/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async deleteMaintenanceTask(id: string): Promise<void> {
    return this.request(`/maintenance-tasks/${id}`, {
      method: 'DELETE',
    });
  }

  async generateMaintenanceTasksFromTemplates(data: GenerateMaintenanceTasksRequest): Promise<GenerateMaintenanceTasksResponse> {
    return this.request('/maintenance-tasks/generate-from-templates', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  // ============================================================================
  // PAYMENT METHOD ENDPOINTS
  // ============================================================================

  async getPaymentMethods(householdId: string): Promise<PaymentMethod[]> {
    return this.request(`/payment-methods?householdId=${householdId}`);
  }

  async createPaymentMethod(data: CreatePaymentMethodRequest): Promise<PaymentMethod> {
    return this.request('/payment-methods', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async deletePaymentMethod(id: string): Promise<void> {
    return this.request(`/payment-methods/${id}`, {
      method: 'DELETE',
    });
  }

  async setDefaultPaymentMethod(id: string): Promise<PaymentMethod> {
    return this.request(`/payment-methods/${id}/set-default`, {
      method: 'POST',
    });
  }

  // ============================================================================
  // STRIPE SETUP INTENT ENDPOINTS
  // ============================================================================

  async createSetupIntent(householdId: string): Promise<SetupIntentResponse> {
    return this.request('/billing/setup-intent', {
      method: 'POST',
      body: JSON.stringify({ householdId }),
    });
  }

  // ============================================================================
  // DASHBOARD & REMINDERS ENDPOINTS
  // ============================================================================

  async getDashboard(householdId: string): Promise<DashboardResponse> {
    return this.request(`/dashboard?householdId=${householdId}`);
  }

  async getUpcomingItems(
    householdId: string,
    days?: number
  ): Promise<UpcomingItemsResponse> {
    const params = new URLSearchParams({ householdId });
    if (days) params.append('days', days.toString());
    return this.request(`/dashboard/upcoming?${params.toString()}`);
  }

  async getNotifications(unreadOnly?: boolean): Promise<InAppNotification[]> {
    const params = unreadOnly ? '?unreadOnly=true' : '';
    return this.request(`/notifications${params}`);
  }

  async getUnreadNotificationCount(): Promise<{ count: number }> {
    return this.request('/notifications/unread-count');
  }

  async markNotificationRead(id: string, isRead: boolean): Promise<{ success: boolean }> {
    return this.request(`/notifications/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({ isRead }),
    });
  }

  async markAllNotificationsRead(): Promise<{ success: boolean }> {
    return this.request('/notifications/mark-all-read', {
      method: 'POST',
    });
  }

  // ============================================================================
  // HOUSEHOLD INVOICE & BILLING ENDPOINTS
  // ============================================================================

  async getHouseholdInvoices(householdId: string): Promise<HouseholdInvoiceListItem[]> {
    return this.request(`/invoices?householdId=${householdId}`);
  }

  async getHouseholdInvoice(invoiceId: string, householdId: string): Promise<HouseholdInvoice> {
    return this.request(`/invoices/${invoiceId}?householdId=${householdId}`);
  }

  async getBillingSummary(householdId: string): Promise<BillingSummary> {
    return this.request(`/billing/summary?householdId=${householdId}`);
  }

  async setupHouseholdStripe(
    householdId: string,
    paymentMethodId: string
  ): Promise<{ stripeCustomerId: string }> {
    return this.request(`/billing/setup-stripe?householdId=${householdId}`, {
      method: 'POST',
      body: JSON.stringify({ paymentMethodId }),
    });
  }

  async updateBillingPreferences(
    householdId: string,
    preferences: { consolidatedBillingDay?: number }
  ): Promise<{ success: boolean }> {
    return this.request(`/billing/preferences?householdId=${householdId}`, {
      method: 'PATCH',
      body: JSON.stringify(preferences),
    });
  }

  // ============================================================================
  // WORK ORDER ENDPOINTS
  // ============================================================================

  async getWorkOrders(
    householdId: string,
    options?: { status?: WorkOrderStatus; includeCompleted?: boolean }
  ): Promise<WorkOrder[]> {
    const params = new URLSearchParams({ householdId });
    if (options?.status) params.append('status', options.status);
    if (options?.includeCompleted !== undefined)
      params.append('includeCompleted', options.includeCompleted.toString());
    return this.request(`/work-orders?${params.toString()}`);
  }

  async getWorkOrder(id: string): Promise<WorkOrder> {
    return this.request(`/work-orders/${id}`);
  }

  async createWorkOrder(householdId: string, data: CreateWorkOrderRequest): Promise<WorkOrder> {
    return this.request(`/work-orders?householdId=${householdId}`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateWorkOrder(id: string, data: UpdateWorkOrderRequest): Promise<WorkOrder> {
    return this.request(`/work-orders/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  // Internal work order endpoints (for managers)
  async getInternalWorkOrders(
    options?: { status?: WorkOrderStatus; unassigned?: boolean; upcoming?: boolean }
  ): Promise<WorkOrder[]> {
    const params = new URLSearchParams();
    if (options?.status) params.append('status', options.status);
    if (options?.unassigned !== undefined)
      params.append('unassigned', options.unassigned.toString());
    if (options?.upcoming !== undefined) params.append('upcoming', options.upcoming.toString());
    const query = params.toString();
    return this.request(`/internal/work-orders${query ? `?${query}` : ''}`);
  }

  async updateInternalWorkOrder(id: string, data: UpdateWorkOrderRequest): Promise<WorkOrder> {
    return this.request(`/internal/work-orders/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async addWorkOrderNote(workOrderId: string, data: CreateWorkOrderNoteRequest): Promise<WorkOrderNote> {
    return this.request(`/internal/work-orders/${workOrderId}/notes`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  // ============================================================================
  // INTERNAL DASHBOARD ENDPOINTS
  // ============================================================================

  async getInternalStats(): Promise<InternalDashboardStats> {
    return this.request('/internal/stats');
  }

  async getInternalHouseholds(): Promise<InternalHousehold[]> {
    return this.request('/internal/households');
  }

  async getInternalHousehold(id: string): Promise<InternalHousehold> {
    return this.request(`/internal/households/${id}`);
  }

  async getInternalConversations(
    filters?: InternalConversationFilters
  ): Promise<InternalConversation[]> {
    const params = new URLSearchParams();
    if (filters?.status) params.append('status', filters.status);
    const query = params.toString();
    return this.request(`/internal/conversations${query ? `?${query}` : ''}`);
  }

  async assignInternalConversation(
    conversationId: string,
    assignedToId?: string | null
  ): Promise<void> {
    return this.request(`/internal/conversations/${conversationId}/assign`, {
      method: 'PATCH',
      body: JSON.stringify({ assignedToId }),
    });
  }

  async updateInternalConversationStatus(
    conversationId: string,
    status: ConversationStatus
  ): Promise<void> {
    return this.request(`/internal/conversations/${conversationId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  }

  async getInternalWorkOrdersQueue(
    filters?: InternalWorkOrderFilters
  ): Promise<InternalWorkOrder[]> {
    const params = new URLSearchParams();
    if (filters?.status) params.append('status', filters.status);
    if (filters?.dateFrom) params.append('dateFrom', filters.dateFrom);
    if (filters?.dateTo) params.append('dateTo', filters.dateTo);
    const query = params.toString();
    return this.request(`/internal/work-orders${query ? `?${query}` : ''}`);
  }

  async getInternalUpcomingAppointments(days?: number): Promise<InternalWorkOrder[]> {
    const params = days ? `?days=${days}` : '';
    return this.request(`/internal/appointments${params}`);
  }

  // ============================================================================
  // GCS FILE UPLOAD ENDPOINTS (Signed URL Flow)
  // ============================================================================

  /**
   * Get a signed URL for uploading a file to GCS
   */
  async signUpload(data: SignUploadRequest): Promise<SignUploadResponse> {
    return this.request('/uploads/sign', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Mark a file upload as complete after uploading to GCS
   */
  async completeUpload(fileAssetId: string): Promise<CompleteUploadResponse> {
    return this.request('/uploads/complete', {
      method: 'POST',
      body: JSON.stringify({ fileAssetId }),
    });
  }

  /**
   * Get a file asset by ID
   */
  async getFileAsset(id: string): Promise<FileAsset> {
    return this.request(`/uploads/${id}`);
  }

  /**
   * Get a signed read URL for a file asset
   */
  async getFileAssetUrl(id: string): Promise<{ url: string; expiresAt: string }> {
    return this.request(`/uploads/${id}/url`);
  }

  /**
   * Delete a file asset
   */
  async deleteFileAsset(id: string): Promise<void> {
    return this.request(`/uploads/${id}`, { method: 'DELETE' });
  }

  // ============================================================================
  // FINANCIALS / PAYOUT ENDPOINTS
  // ============================================================================

  /**
   * Get unpaid vendor payables (transactions pending payment)
   */
  async getPayables(householdId?: string): Promise<VendorPayable[]> {
    const query = householdId ? `?householdId=${householdId}` : '';
    return this.request(`/financials/payables${query}`);
  }

  /**
   * Preview a batch payout before execution
   */
  async previewPayout(data: ExecutePayoutRequest): Promise<BatchPayPreview> {
    return this.request('/financials/payout/preview', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Execute batch payout to vendors
   */
  async executePayout(data: ExecutePayoutRequest): Promise<ExecutePayoutResponse> {
    return this.request('/financials/payout', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get payout status for a transaction
   */
  async getPayoutStatus(transactionId: string): Promise<{ status: string; details?: unknown }> {
    return this.request(`/financials/payout/${transactionId}/status`);
  }

  /**
   * Upload a file using the signed URL flow
   * This is a convenience method that handles the full upload flow:
   * 1. Get signed URL from backend
   * 2. Upload file directly to GCS
   * 3. Mark upload as complete
   */
  async uploadFileToGcs(
    file: File | Blob,
    options: {
      householdId: string;
      type?: FileAssetType;
      filename?: string;
    }
  ): Promise<FileAsset> {
    const filename = options.filename || (file instanceof File ? file.name : 'upload');
    const contentType = file.type || 'application/octet-stream';

    // 1. Get signed URL
    const signResponse = await this.signUpload({
      filename,
      contentType,
      type: options.type,
      householdId: options.householdId,
    });

    // 2. Upload directly to GCS
    const uploadResponse = await fetch(signResponse.signedUrl, {
      method: 'PUT',
      headers: {
        'Content-Type': contentType,
      },
      body: file,
    });

    if (!uploadResponse.ok) {
      throw {
        message: 'Failed to upload file to storage',
        statusCode: uploadResponse.status,
      } as ApiError;
    }

    // 3. Mark upload as complete
    const completeResponse = await this.completeUpload(signResponse.fileAssetId);
    return completeResponse.fileAsset;
  }

  // ============================================================================
  // SETTLEMENT / STATEMENTS ENDPOINTS
  // ============================================================================

  /**
   * Get monthly statements (invoices) for the household
   */
  async getStatements(householdId?: string): Promise<MonthlyInvoiceListItem[]> {
    const query = householdId ? `?householdId=${householdId}` : '';
    return this.request(`/settlement/invoices${query}`);
  }

  /**
   * Get statement details by ID
   */
  async getStatementById(invoiceId: string): Promise<MonthlyInvoice> {
    return this.request(`/settlement/invoices/${invoiceId}`);
  }

  /**
   * Get PDF URL for a statement
   */
  getStatementPdfUrl(invoiceId: string): string {
    return `${this.config.baseUrl}/settlement/invoices/${invoiceId}/pdf`;
  }

  /**
   * Get revenue statistics (manager/admin only)
   */
  async getRevenueStats(): Promise<RevenueStats> {
    return this.request('/settlement/revenue/stats');
  }

  /**
   * Get revenue breakdown by household (manager/admin only)
   */
  async getHouseholdRevenue(): Promise<HouseholdRevenue[]> {
    return this.request('/settlement/revenue/households');
  }

  /**
   * Force collect payment for an invoice (manager/admin only)
   */
  async forceCollectInvoice(invoiceId: string, force = true): Promise<CollectionResult> {
    return this.request('/settlement/collect', {
      method: 'POST',
      body: JSON.stringify({ invoiceId, force }),
    });
  }

  /**
   * Generate monthly invoice for a household (admin only)
   */
  async generateInvoice(householdId: string): Promise<{ success: boolean; invoice?: MonthlyInvoice; error?: string }> {
    return this.request('/settlement/invoices/generate', {
      method: 'POST',
      body: JSON.stringify({ householdId }),
    });
  }

  // ============================================================================
  // CONCIERGE ENDPOINTS (Homeowner)
  // ============================================================================

  /**
   * Create a concierge request for free maintenance
   */
  async createConciergeRequest(
    householdId: string,
    data: CreateConciergeRequestPayload
  ): Promise<ConciergeRequest> {
    return this.request(`/concierge/households/${householdId}/requests`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get concierge requests for a household
   */
  async getConciergeRequests(householdId: string): Promise<ConciergeRequest[]> {
    return this.request(`/concierge/households/${householdId}/requests`);
  }

  // ============================================================================
  // HANDYMAN ENDPOINTS (Internal Staff)
  // ============================================================================

  /**
   * Get handyman dashboard with tasks and stats
   */
  async getHandymanDashboard(): Promise<HandymanDashboard> {
    return this.request('/concierge/handyman/dashboard');
  }

  /**
   * Handyman check-in to a work order with geolocation
   */
  async handymanCheckIn(data: {
    workOrderId: string;
    latitude: number;
    longitude: number;
  }): Promise<{ success: boolean }> {
    return this.request('/concierge/handyman/check-in', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Handyman check-out from a work order with completion details
   */
  async handymanCheckOut(data: {
    workOrderId: string;
    hoursWorked?: number;
    notes?: string;
    proofImages?: string[];
  }): Promise<{ success: boolean }> {
    return this.request('/concierge/handyman/check-out', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Handyman rejects a work order assignment
   */
  async handymanRejectRequest(data: {
    workOrderId: string;
    reason: string;
  }): Promise<{ success: boolean }> {
    return this.request('/concierge/handyman/reject', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get list of all handymen (for manager assignment)
   */
  async getHandymen(): Promise<HandymanInfo[]> {
    return this.request('/concierge/handymen');
  }

  // ============================================================================
  // SOCIAL FEED ENDPOINTS
  // ============================================================================

  /**
   * Get aggregated social feed
   */
  async getSocialFeed(params?: FeedQueryParams): Promise<FeedResponse> {
    const query = new URLSearchParams();
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.cursor) query.append('cursor', params.cursor);
    if (params?.source) query.append('source', params.source);
    const queryString = query.toString();
    return this.request(`/social/feed${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get neighbor posts feed
   */
  async getNeighborFeed(params?: { limit?: number; cursor?: string }): Promise<FeedResponse> {
    const query = new URLSearchParams();
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.cursor) query.append('cursor', params.cursor);
    const queryString = query.toString();
    return this.request(`/social/feed/neighbors${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get friend posts feed
   */
  async getFriendFeed(params?: { limit?: number; cursor?: string }): Promise<FeedResponse> {
    const query = new URLSearchParams();
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.cursor) query.append('cursor', params.cursor);
    const queryString = query.toString();
    return this.request(`/social/feed/friends${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get following posts feed
   */
  async getFollowingFeed(params?: { limit?: number; cursor?: string }): Promise<FeedResponse> {
    const query = new URLSearchParams();
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.cursor) query.append('cursor', params.cursor);
    const queryString = query.toString();
    return this.request(`/social/feed/following${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get neighbor posts for map view
   */
  async getNeighborPostsForMap(limit?: number): Promise<ProjectPost[]> {
    const query = limit ? `?limit=${limit}` : '';
    return this.request(`/social/feed/map${query}`);
  }

  // ============================================================================
  // SOCIAL FRIENDSHIP ENDPOINTS
  // ============================================================================

  /**
   * Get list of friends
   */
  async getFriends(): Promise<SocialUserSummary[]> {
    return this.request('/social/friends');
  }

  /**
   * Get pending friend requests
   */
  async getPendingFriendRequests(): Promise<Friendship[]> {
    return this.request('/social/friends/pending');
  }

  /**
   * Send a friend request
   */
  async sendFriendRequest(addresseeId: string): Promise<Friendship> {
    return this.request('/social/friends/request', {
      method: 'POST',
      body: JSON.stringify({ addresseeId }),
    });
  }

  /**
   * Accept a friend request
   */
  async acceptFriendRequest(friendshipId: string): Promise<Friendship> {
    return this.request(`/social/friends/${friendshipId}/accept`, {
      method: 'POST',
    });
  }

  /**
   * Decline a friend request
   */
  async declineFriendRequest(friendshipId: string): Promise<void> {
    return this.request(`/social/friends/${friendshipId}/decline`, {
      method: 'POST',
    });
  }

  /**
   * Remove a friend
   */
  async removeFriend(friendId: string): Promise<void> {
    return this.request(`/social/friends/${friendId}`, {
      method: 'DELETE',
    });
  }

  /**
   * Block a user
   */
  async blockUser(userId: string): Promise<void> {
    return this.request(`/social/friends/${userId}/block`, {
      method: 'POST',
    });
  }

  /**
   * Check if two users are friends
   */
  async checkFriendship(userId: string): Promise<{ areFriends: boolean }> {
    return this.request(`/social/friends/check/${userId}`);
  }

  // ============================================================================
  // SOCIAL FOLLOW ENDPOINTS
  // ============================================================================

  /**
   * Get users I'm following
   */
  async getFollowing(): Promise<SocialUserSummary[]> {
    return this.request('/social/following');
  }

  /**
   * Get my followers
   */
  async getFollowers(): Promise<SocialUserSummary[]> {
    return this.request('/social/followers');
  }

  /**
   * Follow a user
   */
  async followUser(userId: string): Promise<Follow> {
    return this.request(`/social/follow/${userId}`, {
      method: 'POST',
    });
  }

  /**
   * Unfollow a user
   */
  async unfollowUser(userId: string): Promise<void> {
    return this.request(`/social/follow/${userId}`, {
      method: 'DELETE',
    });
  }

  /**
   * Check if following a user
   */
  async checkFollowing(userId: string): Promise<{ isFollowing: boolean }> {
    return this.request(`/social/follow/check/${userId}`);
  }

  /**
   * Get follower/following counts for a user
   */
  async getFollowCounts(userId: string): Promise<FollowCounts> {
    return this.request(`/social/follow/counts/${userId}`);
  }

  // ============================================================================
  // SOCIAL PROJECT POST ENDPOINTS
  // ============================================================================

  /**
   * Create a project post
   */
  async createProjectPost(data: CreateProjectPostRequest): Promise<ProjectPost> {
    return this.request('/social/posts', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Update a project post
   */
  async updateProjectPost(postId: string, data: UpdateProjectPostRequest): Promise<ProjectPost> {
    return this.request(`/social/posts/${postId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Delete a project post
   */
  async deleteProjectPost(postId: string): Promise<void> {
    return this.request(`/social/posts/${postId}`, {
      method: 'DELETE',
    });
  }

  /**
   * Get a project post by ID
   */
  async getProjectPost(postId: string): Promise<ProjectPost> {
    return this.request(`/social/posts/${postId}`);
  }

  /**
   * Like a post
   */
  async likePost(postId: string): Promise<{ success: boolean }> {
    return this.request(`/social/posts/${postId}/like`, {
      method: 'POST',
    });
  }

  /**
   * Unlike a post
   */
  async unlikePost(postId: string): Promise<{ success: boolean }> {
    return this.request(`/social/posts/${postId}/like`, {
      method: 'DELETE',
    });
  }

  /**
   * Save/bookmark a post
   */
  async savePostBookmark(postId: string): Promise<{ success: boolean }> {
    return this.request(`/social/posts/${postId}/save`, {
      method: 'POST',
    });
  }

  /**
   * Unsave a post
   */
  async unsavePostBookmark(postId: string): Promise<{ success: boolean }> {
    return this.request(`/social/posts/${postId}/save`, {
      method: 'DELETE',
    });
  }

  /**
   * Get saved posts
   */
  async getSavedPosts(params?: { limit?: number; cursor?: string }): Promise<ProjectPostListResponse> {
    const query = new URLSearchParams();
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.cursor) query.append('cursor', params.cursor);
    const queryString = query.toString();
    return this.request(`/social/posts/saved${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get comments for a post
   */
  async getPostComments(postId: string, params?: { limit?: number; cursor?: string }): Promise<CommentListResponse> {
    const query = new URLSearchParams();
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.cursor) query.append('cursor', params.cursor);
    const queryString = query.toString();
    return this.request(`/social/posts/${postId}/comments${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Add a comment to a post
   */
  async addPostComment(postId: string, content: string): Promise<PostComment> {
    return this.request(`/social/posts/${postId}/comments`, {
      method: 'POST',
      body: JSON.stringify({ content }),
    });
  }

  /**
   * Delete a comment
   */
  async deletePostComment(postId: string, commentId: string): Promise<{ success: boolean }> {
    return this.request(`/social/posts/${postId}/comments/${commentId}`, {
      method: 'DELETE',
    });
  }

  // ============================================================================
  // SOCIAL PROFILE ENDPOINTS
  // ============================================================================

  /**
   * Get a user's social profile
   */
  async getSocialProfile(userId: string): Promise<SocialProfile> {
    return this.request(`/social/users/${userId}/profile`);
  }

  /**
   * Get a user's project portfolio
   */
  async getUserPortfolio(userId: string, params?: { limit?: number; cursor?: string }): Promise<ProjectPostListResponse> {
    const query = new URLSearchParams();
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.cursor) query.append('cursor', params.cursor);
    const queryString = query.toString();
    return this.request(`/social/users/${userId}/portfolio${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Update my social profile
   */
  async updateSocialProfile(data: UpdateSocialProfileRequest): Promise<SocialUserSummary> {
    return this.request('/social/profile', {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get my profile stats
   */
  async getProfileStats(): Promise<ProfileStats> {
    return this.request('/social/profile/stats');
  }

  // ============================================================================
  // SOCIAL VENDOR DISCOVERY ENDPOINTS
  // ============================================================================

  /**
   * Search vendors with social signals
   */
  async searchSocialVendors(params?: SocialVendorSearchParams): Promise<SocialVendorSearchResponse> {
    const query = new URLSearchParams();
    if (params?.category) query.append('category', params.category);
    if (params?.socialProof) query.append('socialProof', params.socialProof);
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.cursor) query.append('cursor', params.cursor);
    const queryString = query.toString();
    return this.request(`/social/vendors${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get social activity for a vendor
   */
  async getVendorSocialActivity(vendorId: string): Promise<VendorSocialActivity> {
    return this.request(`/social/vendors/${vendorId}/social`);
  }

  // ============================================================================
  // PROJECT PLANNER - TEMPLATES ENDPOINTS
  // ============================================================================

  /**
   * List project templates by category
   */
  async getProjectTemplates(params?: { category?: ProjectCategory; activeOnly?: boolean }): Promise<ProjectTemplate[]> {
    const query = new URLSearchParams();
    if (params?.category) query.append('category', params.category);
    if (params?.activeOnly !== undefined) query.append('activeOnly', params.activeOnly.toString());
    const queryString = query.toString();
    return this.request(`/project-planner/templates${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get templates grouped by category
   */
  async getProjectTemplatesByCategory(): Promise<Record<ProjectCategory, ProjectTemplate[]>> {
    return this.request('/project-planner/templates/by-category');
  }

  /**
   * Get category options for the wizard
   */
  async getProjectCategoryOptions(): Promise<ProjectCategoryOption[]> {
    return this.request('/project-planner/templates/categories');
  }

  /**
   * Get a single template
   */
  async getProjectTemplate(id: string): Promise<ProjectTemplate> {
    return this.request(`/project-planner/templates/${id}`);
  }

  // ============================================================================
  // PROJECT PLANNER - ESTIMATION ENDPOINTS
  // ============================================================================

  /**
   * Calculate project estimate
   */
  async calculateProjectEstimate(data: CalculateEstimateRequest): Promise<EstimateResult> {
    return this.request('/project-planner/estimate', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get regional cost multiplier for user's location
   */
  async getRegionalMultiplier(): Promise<RegionalMultiplier> {
    return this.request('/project-planner/regional-multiplier');
  }

  // ============================================================================
  // PROJECT PLANNER - IDEAS ENDPOINTS
  // ============================================================================

  /**
   * Create a new project idea
   */
  async createProjectIdea(data: CreateProjectIdeaRequest): Promise<ProjectIdea> {
    return this.request('/project-planner/ideas', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * List project ideas (pipeline view)
   */
  async getProjectIdeas(params?: {
    status?: ProjectIdeaStatus;
    category?: ProjectCategory;
    page?: number;
    limit?: number;
  }): Promise<ProjectIdeasListResponse> {
    const query = new URLSearchParams();
    if (params?.status) query.append('status', params.status);
    if (params?.category) query.append('category', params.category);
    if (params?.page) query.append('page', params.page.toString());
    if (params?.limit) query.append('limit', params.limit.toString());
    const queryString = query.toString();
    return this.request(`/project-planner/ideas${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get pipeline stats
   */
  async getProjectPipelineStats(): Promise<ProjectPipelineStats> {
    return this.request('/project-planner/ideas/stats');
  }

  /**
   * Get a single project idea
   */
  async getProjectIdea(id: string): Promise<ProjectIdea> {
    return this.request(`/project-planner/ideas/${id}`);
  }

  /**
   * Update a project idea
   */
  async updateProjectIdea(id: string, data: UpdateProjectIdeaRequest): Promise<ProjectIdea> {
    return this.request(`/project-planner/ideas/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Progress idea to new status
   */
  async progressProjectIdea(id: string, status: ProjectIdeaStatus): Promise<ProjectIdea> {
    return this.request(`/project-planner/ideas/${id}/progress`, {
      method: 'POST',
      body: JSON.stringify({ status }),
    });
  }

  /**
   * Convert idea to work order
   */
  async convertIdeaToWorkOrder(id: string, data?: ConvertToWorkOrderRequest): Promise<ConvertToWorkOrderResponse> {
    return this.request(`/project-planner/ideas/${id}/convert`, {
      method: 'POST',
      body: JSON.stringify(data ?? {}),
    });
  }

  /**
   * Archive a project idea
   */
  async archiveProjectIdea(id: string): Promise<{ success: boolean }> {
    return this.request(`/project-planner/ideas/${id}`, {
      method: 'DELETE',
    });
  }

  // ============================================================================
  // PROJECT PLANNER - COMMUNITY INTELLIGENCE ENDPOINTS
  // ============================================================================

  /**
   * Generate system vendor suggestions for an idea
   */
  async generateVendorSuggestions(ideaId: string): Promise<VendorSuggestion[]> {
    return this.request(`/project-planner/ideas/${ideaId}/generate-suggestions`, {
      method: 'POST',
    });
  }

  /**
   * Get all suggestions for a project idea
   */
  async getIdeaSuggestions(ideaId: string): Promise<VendorSuggestion[]> {
    return this.request(`/project-planner/ideas/${ideaId}/suggestions`);
  }

  /**
   * Get neighbor inspiration for a project category
   */
  async getNeighborInspiration(ideaId: string, limit?: number): Promise<NeighborInspiration[]> {
    const query = limit ? `?limit=${limit}` : '';
    return this.request(`/project-planner/ideas/${ideaId}/inspiration${query}`);
  }

  /**
   * Get vendors with social signals
   */
  async getVendorSocialSignals(category?: ProjectCategory): Promise<VendorWithSocialSignals[]> {
    const query = category ? `?category=${category}` : '';
    return this.request(`/project-planner/vendor-signals${query}`);
  }

  // ============================================================================
  // PROJECT PLANNER - RECOMMENDATION REQUEST ENDPOINTS
  // ============================================================================

  /**
   * Create a community ask for recommendations
   */
  async createRecommendationRequest(ideaId: string, data: Omit<CreateRecommendationRequestDto, 'projectIdeaId'>): Promise<RecommendationRequest> {
    return this.request(`/project-planner/ideas/${ideaId}/ask-community`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * List my recommendation requests
   */
  async getMyRecommendationRequests(params?: {
    status?: RecommendationRequestStatus;
    page?: number;
    limit?: number;
  }): Promise<RecommendationRequestListResponse> {
    const query = new URLSearchParams();
    if (params?.status) query.append('status', params.status);
    if (params?.page) query.append('page', params.page.toString());
    if (params?.limit) query.append('limit', params.limit.toString());
    const queryString = query.toString();
    return this.request(`/project-planner/requests${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get nearby community asks from neighbors
   */
  async getNearbyRecommendationRequests(): Promise<RecommendationRequest[]> {
    return this.request('/project-planner/requests/nearby');
  }

  /**
   * Update recommendation request status
   */
  async updateRecommendationRequestStatus(id: string, status: RecommendationRequestStatus): Promise<RecommendationRequest> {
    return this.request(`/project-planner/requests/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  }

  /**
   * Submit vendor suggestion for a request
   */
  async submitVendorSuggestion(requestId: string, data: Omit<SubmitVendorSuggestionRequest, 'recommendationRequestId'>): Promise<VendorSuggestion> {
    return this.request(`/project-planner/requests/${requestId}/suggest`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Mark suggestion as helpful or not
   */
  async submitSuggestionFeedback(suggestionId: string, isHelpful: boolean): Promise<{ success: boolean }> {
    return this.request(`/project-planner/suggestions/${suggestionId}/feedback`, {
      method: 'POST',
      body: JSON.stringify({ isHelpful }),
    });
  }

  // ============================================================================
  // TRIAGE COMMAND CENTER ENDPOINTS
  // ============================================================================

  /**
   * List inbound requests for triage
   */
  async getTriageRequests(params?: TriageListQuery): Promise<InboundRequest[]> {
    const query = new URLSearchParams();
    if (params?.status) query.append('status', params.status);
    if (params?.source) query.append('source', params.source);
    if (params?.category) query.append('category', params.category);
    if (params?.householdId) query.append('householdId', params.householdId);
    if (params?.limit) query.append('limit', params.limit.toString());
    if (params?.offset) query.append('offset', params.offset.toString());
    const queryString = query.toString();
    return this.request(`/concierge/triage${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get triage statistics
   */
  async getTriageStats(): Promise<TriageStats> {
    return this.request('/concierge/triage/stats');
  }

  /**
   * Get a single inbound request
   */
  async getTriageRequest(id: string): Promise<InboundRequest> {
    return this.request(`/concierge/triage/${id}`);
  }

  /**
   * Approve and execute a triage suggestion
   */
  async approveTriageAction(data: ApproveTriageActionRequest): Promise<ExecutionResult> {
    return this.request('/concierge/triage/approve', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Reject a triage request
   */
  async rejectTriageRequest(requestId: string, reason: string): Promise<{ success: boolean }> {
    return this.request('/concierge/triage/reject', {
      method: 'POST',
      body: JSON.stringify({ requestId, reason }),
    });
  }

  /**
   * Manually classify a request
   */
  async manuallyClassifyRequest(
    id: string,
    data: { category: RequestCategory; priority?: RequestPriority; notes?: string }
  ): Promise<InboundRequest> {
    return this.request(`/concierge/triage/${id}/classify`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Link request to a household
   */
  async linkRequestToHousehold(id: string, householdId: string): Promise<InboundRequest> {
    return this.request(`/concierge/triage/${id}/link-household`, {
      method: 'PATCH',
      body: JSON.stringify({ householdId }),
    });
  }

  // ============================================================================
  // FAMILY OPERATIONS - MEMBERS ENDPOINTS
  // ============================================================================

  /**
   * Get family members for a household
   */
  async getFamilyMembers(): Promise<FamilyMember[]> {
    return this.request('/family/members');
  }

  /**
   * Get a family member by ID
   */
  async getFamilyMember(id: string): Promise<FamilyMember> {
    return this.request(`/family/members/${id}`);
  }

  /**
   * Update member profile
   */
  async updateMemberProfile(memberId: string, data: UpdateMemberProfileRequest): Promise<FamilyMember> {
    return this.request(`/family/members/${memberId}/profile`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Update member permissions
   */
  async updateMemberPermissions(memberId: string, permissions: MemberPermissionType[]): Promise<FamilyMember> {
    return this.request(`/family/members/${memberId}/permissions`, {
      method: 'PATCH',
      body: JSON.stringify({ permissions }),
    });
  }

  // ============================================================================
  // FAMILY OPERATIONS - VEHICLES ENDPOINTS
  // ============================================================================

  /**
   * Create a vehicle
   */
  async createVehicle(data: CreateVehicleRequest): Promise<Vehicle> {
    return this.request('/family/vehicles', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get all vehicles
   */
  async getFamilyVehicles(includeInactive = false): Promise<Vehicle[]> {
    const query = includeInactive ? '?includeInactive=true' : '';
    return this.request(`/family/vehicles${query}`);
  }

  /**
   * Get vehicle alerts
   */
  async getVehicleAlerts(): Promise<VehicleMaintenanceAlert[]> {
    return this.request('/family/vehicles/alerts');
  }

  /**
   * Get a vehicle by ID
   */
  async getFamilyVehicle(id: string): Promise<Vehicle> {
    return this.request(`/family/vehicles/${id}`);
  }

  /**
   * Update a vehicle
   */
  async updateVehicle(id: string, data: UpdateVehicleRequest): Promise<Vehicle> {
    return this.request(`/family/vehicles/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Delete a vehicle
   */
  async deleteVehicle(id: string): Promise<void> {
    return this.request(`/family/vehicles/${id}`, {
      method: 'DELETE',
    });
  }

  /**
   * Add vehicle service record
   */
  async addVehicleServiceRecord(vehicleId: string, data: CreateVehicleServiceRecordRequest): Promise<VehicleServiceRecord> {
    return this.request(`/family/vehicles/${vehicleId}/service-records`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get vehicle service records
   */
  async getVehicleServiceRecords(vehicleId: string): Promise<VehicleServiceRecord[]> {
    return this.request(`/family/vehicles/${vehicleId}/service-records`);
  }

  // ============================================================================
  // FAMILY OPERATIONS - PETS ENDPOINTS
  // ============================================================================

  /**
   * Create a pet
   */
  async createPet(data: CreatePetRequest): Promise<Pet> {
    return this.request('/family/pets', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get all pets
   */
  async getFamilyPets(includeInactive = false): Promise<Pet[]> {
    const query = includeInactive ? '?includeInactive=true' : '';
    return this.request(`/family/pets${query}`);
  }

  /**
   * Get pet alerts
   */
  async getPetAlerts(): Promise<PetCareAlert[]> {
    return this.request('/family/pets/alerts');
  }

  /**
   * Get a pet by ID
   */
  async getFamilyPet(id: string): Promise<Pet> {
    return this.request(`/family/pets/${id}`);
  }

  /**
   * Get pet passport (for pet sitters)
   */
  async getPetPassport(petId: string): Promise<PetPassport> {
    return this.request(`/family/pets/${petId}/passport`);
  }

  /**
   * Update a pet
   */
  async updatePet(id: string, data: UpdatePetRequest): Promise<Pet> {
    return this.request(`/family/pets/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Delete a pet
   */
  async deletePet(id: string): Promise<void> {
    return this.request(`/family/pets/${id}`, {
      method: 'DELETE',
    });
  }

  /**
   * Add pet vet record
   */
  async addPetVetRecord(petId: string, data: CreatePetVetRecordRequest): Promise<PetVetRecord> {
    return this.request(`/family/pets/${petId}/vet-records`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get pet vet records
   */
  async getPetVetRecords(petId: string): Promise<PetVetRecord[]> {
    return this.request(`/family/pets/${petId}/vet-records`);
  }

  // ============================================================================
  // FAMILY OPERATIONS - HOME SYSTEMS ENDPOINTS
  // ============================================================================

  /**
   * Create a home system
   */
  async createHomeSystem(data: CreateHomeSystemRequest): Promise<HomeSystem> {
    return this.request('/family/home-systems', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get all home systems
   */
  async getHomeSystems(includeInactive = false): Promise<HomeSystem[]> {
    const query = includeInactive ? '?includeInactive=true' : '';
    return this.request(`/family/home-systems${query}`);
  }

  /**
   * Get home dashboard (systems grouped by category)
   */
  async getHomeSystemsDashboard(): Promise<HomeDashboard> {
    return this.request('/family/home-systems/dashboard');
  }

  /**
   * Get home system alerts
   */
  async getHomeSystemAlerts(): Promise<HomeSystemMaintenanceAlert[]> {
    return this.request('/family/home-systems/alerts');
  }

  /**
   * Get home systems by type
   */
  async getHomeSystemsByType(type: HomeSystemType): Promise<HomeSystem[]> {
    return this.request(`/family/home-systems/type/${type}`);
  }

  /**
   * Get a home system by ID
   */
  async getHomeSystem(id: string): Promise<HomeSystem> {
    return this.request(`/family/home-systems/${id}`);
  }

  /**
   * Update a home system
   */
  async updateHomeSystem(id: string, data: UpdateHomeSystemRequest): Promise<HomeSystem> {
    return this.request(`/family/home-systems/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Delete a home system
   */
  async deleteHomeSystem(id: string): Promise<void> {
    return this.request(`/family/home-systems/${id}`, {
      method: 'DELETE',
    });
  }

  /**
   * Update tank level
   */
  async updateTankLevel(systemId: string, level: number): Promise<HomeSystem> {
    return this.request(`/family/home-systems/${systemId}/tank-level`, {
      method: 'PATCH',
      body: JSON.stringify({ level }),
    });
  }

  /**
   * Add home system service record
   */
  async addHomeSystemServiceRecord(systemId: string, data: CreateHomeSystemServiceRequest): Promise<HomeSystemService> {
    return this.request(`/family/home-systems/${systemId}/service-records`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get home system service records
   */
  async getHomeSystemServiceRecords(systemId: string): Promise<HomeSystemService[]> {
    return this.request(`/family/home-systems/${systemId}/service-records`);
  }

  // ============================================================================
  // FAMILY OPERATIONS - CALENDAR ENDPOINTS
  // ============================================================================

  /**
   * Create a family event
   */
  async createFamilyEvent(data: CreateFamilyEventRequest): Promise<FamilyEvent> {
    return this.request('/family/events', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get family events
   */
  async getFamilyEvents(params?: {
    startDate?: string;
    endDate?: string;
    categories?: FamilyEventCategory[];
    memberId?: string;
  }): Promise<FamilyEvent[]> {
    const query = new URLSearchParams();
    if (params?.startDate) query.append('startDate', params.startDate);
    if (params?.endDate) query.append('endDate', params.endDate);
    if (params?.categories?.length) query.append('categories', params.categories.join(','));
    if (params?.memberId) query.append('memberId', params.memberId);
    const queryString = query.toString();
    return this.request(`/family/events${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get upcoming family events
   */
  async getUpcomingFamilyEvents(limit = 10): Promise<FamilyEvent[]> {
    return this.request(`/family/events/upcoming?limit=${limit}`);
  }

  /**
   * Get unified calendar (family events + maintenance)
   */
  async getUnifiedCalendar(params: {
    startDate: string;
    endDate: string;
    includeMaintenance?: boolean;
  }): Promise<CalendarEvent[]> {
    const query = new URLSearchParams();
    query.append('startDate', params.startDate);
    query.append('endDate', params.endDate);
    if (params.includeMaintenance !== undefined) {
      query.append('includeMaintenance', params.includeMaintenance.toString());
    }
    return this.request(`/family/calendar?${query.toString()}`);
  }

  /**
   * Get calendar summary
   */
  async getCalendarSummary(): Promise<CalendarSummary> {
    return this.request('/family/calendar/summary');
  }

  /**
   * Get iCal feed URL
   */
  async getCalendarFeedUrl(): Promise<CalendarFeedUrlResponse> {
    return this.request('/family/calendar/feed-url');
  }

  /**
   * Get a family event by ID
   */
  async getFamilyEvent(id: string): Promise<FamilyEvent> {
    return this.request(`/family/events/${id}`);
  }

  /**
   * Update a family event
   */
  async updateFamilyEvent(id: string, data: UpdateFamilyEventRequest): Promise<FamilyEvent> {
    return this.request(`/family/events/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Delete a family event
   */
  async deleteFamilyEvent(id: string): Promise<void> {
    return this.request(`/family/events/${id}`, {
      method: 'DELETE',
    });
  }

  // ============================================================================
  // FAMILY OPERATIONS - ALERTS ENDPOINTS
  // ============================================================================

  /**
   * Get all family alerts (vehicles, pets, home systems)
   */
  async getAllFamilyAlerts(): Promise<AllFamilyAlerts> {
    return this.request('/family/alerts');
  }

  // ============================================================================
  // TRAVEL CONCIERGE - USER ENDPOINTS
  // ============================================================================

  /**
   * Get my travel profile
   */
  async getMyTravelProfile(): Promise<TravelProfileWithMember> {
    return this.request('/travel/profile');
  }

  /**
   * Update my travel profile
   */
  async updateMyTravelProfile(data: UpdateTravelProfileRequest): Promise<TravelProfile> {
    return this.request('/travel/profile', {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get all household member travel profiles
   */
  async getMemberTravelProfiles(): Promise<TravelProfileWithMember[]> {
    return this.request('/travel/profile/members');
  }

  /**
   * Create a new trip
   */
  async createTrip(data: CreateTripRequest): Promise<Trip> {
    return this.request('/travel/trips', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Get all trips
   */
  async getTrips(params?: { status?: TripStatus[] }): Promise<TripListItem[]> {
    const query = new URLSearchParams();
    if (params?.status) {
      params.status.forEach(s => query.append('status', s));
    }
    const queryStr = query.toString();
    return this.request(`/travel/trips${queryStr ? `?${queryStr}` : ''}`);
  }

  /**
   * Get upcoming trips
   */
  async getUpcomingTrips(limit?: number): Promise<TripListItem[]> {
    const query = limit ? `?limit=${limit}` : '';
    return this.request(`/travel/trips/upcoming${query}`);
  }

  /**
   * Get a trip by ID
   */
  async getTrip(id: string): Promise<Trip> {
    return this.request(`/travel/trips/${id}`);
  }

  /**
   * Update a trip
   */
  async updateTrip(id: string, data: UpdateTripRequest): Promise<Trip> {
    return this.request(`/travel/trips/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Cancel a trip
   */
  async cancelTrip(id: string): Promise<Trip> {
    return this.request(`/travel/trips/${id}`, {
      method: 'DELETE',
    });
  }

  /**
   * Get proposals for a trip
   */
  async getTripProposals(tripId: string): Promise<TripProposal[]> {
    return this.request(`/travel/trips/${tripId}/proposals`);
  }

  /**
   * Get pending proposals
   */
  async getPendingProposals(): Promise<TripProposal[]> {
    return this.request('/travel/proposals/pending');
  }

  /**
   * Select a proposal option
   */
  async selectProposalOption(proposalId: string, optionIndex: number): Promise<TripProposal> {
    return this.request(`/travel/proposals/${proposalId}/select`, {
      method: 'POST',
      body: JSON.stringify({ optionIndex }),
    });
  }

  /**
   * Get trip itinerary (day-by-day)
   */
  async getTripItinerary(tripId: string): Promise<ItineraryDay[]> {
    return this.request(`/travel/trips/${tripId}/itinerary`);
  }

  /**
   * Get trip documents
   */
  async getTripDocuments(tripId: string): Promise<TripDocument[]> {
    return this.request(`/travel/trips/${tripId}/documents`);
  }

  /**
   * Get trip house protocol
   */
  async getTripProtocol(tripId: string): Promise<HouseProtocol> {
    return this.request(`/travel/trips/${tripId}/protocol`);
  }

  /**
   * Verify trip protocol
   */
  async verifyTripProtocol(tripId: string): Promise<HouseProtocol> {
    return this.request(`/travel/trips/${tripId}/protocol/verify`, {
      method: 'POST',
    });
  }

  // ============================================================================
  // TRAVEL CONCIERGE - MANAGER ENDPOINTS
  // ============================================================================

  /**
   * Get trip pipeline (all trips by status)
   */
  async getTripPipeline(): Promise<TripPipeline> {
    return this.request('/internal/travel/pipeline');
  }

  /**
   * Assign manager to trip
   */
  async assignTripManager(tripId: string, managerId?: string): Promise<Trip> {
    return this.request(`/internal/travel/trips/${tripId}/assign`, {
      method: 'PATCH',
      body: JSON.stringify({ managerId }),
    });
  }

  /**
   * Update trip status
   */
  async updateTripStatus(tripId: string, status: TripStatus): Promise<Trip> {
    return this.request(`/internal/travel/trips/${tripId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  }

  /**
   * Create a proposal for a trip
   */
  async createProposal(tripId: string, data: CreateProposalRequest): Promise<TripProposal> {
    return this.request(`/internal/travel/trips/${tripId}/proposals`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Update a proposal
   */
  async updateProposal(proposalId: string, data: UpdateProposalRequest): Promise<TripProposal> {
    return this.request(`/internal/travel/proposals/${proposalId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Send a proposal to user
   */
  async sendProposal(proposalId: string): Promise<TripProposal> {
    return this.request(`/internal/travel/proposals/${proposalId}/send`, {
      method: 'POST',
    });
  }

  /**
   * Add itinerary item to trip
   */
  async addItineraryItem(tripId: string, data: CreateItineraryItemRequest): Promise<ItineraryItem> {
    return this.request(`/internal/travel/trips/${tripId}/itinerary`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Update itinerary item
   */
  async updateItineraryItem(itemId: string, data: UpdateItineraryItemRequest): Promise<ItineraryItem> {
    return this.request(`/internal/travel/itinerary/${itemId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  /**
   * Delete itinerary item
   */
  async deleteItineraryItem(itemId: string): Promise<void> {
    return this.request(`/internal/travel/itinerary/${itemId}`, {
      method: 'DELETE',
    });
  }

  /**
   * Mark trip as booked
   */
  async markTripAsBooked(tripId: string): Promise<Trip> {
    return this.request(`/internal/travel/trips/${tripId}/mark-booked`, {
      method: 'POST',
    });
  }

  /**
   * Generate house protocol for trip
   */
  async generateTripProtocol(tripId: string): Promise<HouseProtocol> {
    return this.request(`/internal/travel/trips/${tripId}/protocol/generate`, {
      method: 'POST',
    });
  }

  /**
   * Get pending house protocols
   */
  async getPendingProtocols(): Promise<HouseProtocol[]> {
    return this.request('/internal/travel/protocols/pending');
  }

  /**
   * Get a protocol by ID
   */
  async getProtocol(protocolId: string): Promise<HouseProtocol> {
    return this.request(`/internal/travel/protocols/${protocolId}`);
  }

  /**
   * Assign protocol to user
   */
  async assignProtocol(protocolId: string, userId?: string): Promise<HouseProtocol> {
    return this.request(`/internal/travel/protocols/${protocolId}/assign`, {
      method: 'PATCH',
      body: JSON.stringify({ assignedToUserId: userId }),
    });
  }

  /**
   * Start protocol execution
   */
  async startProtocol(protocolId: string): Promise<HouseProtocol> {
    return this.request(`/internal/travel/protocols/${protocolId}/start`, {
      method: 'POST',
    });
  }

  /**
   * Complete a protocol item
   */
  async completeProtocolItem(
    protocolId: string,
    itemId: string,
    data: CompleteProtocolItemRequest
  ): Promise<HouseProtocolItem> {
    return this.request(`/internal/travel/protocols/${protocolId}/items/${itemId}/complete`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Skip a protocol item
   */
  async skipProtocolItem(protocolId: string, itemId: string, reason?: string): Promise<HouseProtocolItem> {
    return this.request(`/internal/travel/protocols/${protocolId}/items/${itemId}/skip`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  }

  /**
   * Add custom item to protocol
   */
  async addProtocolItem(protocolId: string, data: CreateProtocolItemRequest): Promise<HouseProtocolItem> {
    return this.request(`/internal/travel/protocols/${protocolId}/items`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  // ============================================================================
  // HOMEOWNER CONVERSATION ENDPOINTS
  // ============================================================================

  /**
   * Get conversations for the current household
   */
  async getConversations(params?: ConversationListQuery): Promise<Conversation[]> {
    const query = new URLSearchParams();
    if (params?.status) query.append('status', params.status);
    if (params?.updatedSince) query.append('updatedSince', params.updatedSince);
    const queryString = query.toString();
    return this.request(`/conversations${queryString ? `?${queryString}` : ''}`);
  }

  /**
   * Get a single conversation with messages
   */
  async getConversation(conversationId: string): Promise<ConversationDetail> {
    return this.request(`/conversations/${conversationId}`);
  }

  /**
   * Create a new support conversation
   */
  async createConversation(data: CreateConversationRequest): Promise<Conversation> {
    return this.request('/conversations', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Send a message in a conversation
   */
  async sendConversationMessage(conversationId: string, data: SendMessageRequest): Promise<SupportMessage> {
    return this.request(`/conversations/${conversationId}/messages`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  /**
   * Update conversation status
   */
  async updateConversationStatus(conversationId: string, status: ConversationStatus): Promise<Conversation> {
    return this.request(`/conversations/${conversationId}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    });
  }
}

export function createApiClient(config: ApiClientConfig): ApiClient {
  return new ApiClient(config);
}

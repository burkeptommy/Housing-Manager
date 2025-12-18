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
  ConversationStatus,
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
}

export function createApiClient(config: ApiClientConfig): ApiClient {
  return new ApiClient(config);
}

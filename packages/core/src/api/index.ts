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
      const error: ApiError = await response.json().catch(() => ({
        message: 'An error occurred',
        statusCode: response.status,
      }));
      throw error;
    }

    // Handle empty responses (204 No Content)
    if (response.status === 204) {
      return undefined as T;
    }

    return response.json();
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
      const error: ApiError = await response.json().catch(() => ({
        message: 'Upload failed',
        statusCode: response.status,
      }));
      throw error;
    }

    return response.json();
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
}

export function createApiClient(config: ApiClientConfig): ApiClient {
  return new ApiClient(config);
}

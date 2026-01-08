// Shared API client utilities for Haven

export interface ApiClientConfig {
  baseUrl: string;
  getToken: () => Promise<string | null>;
  onUnauthorized?: () => void;
}

export class ApiClient {
  constructor(private config: ApiClientConfig) {}

  private async getHeaders(): Promise<HeadersInit> {
    const token = await this.config.getToken();
    return {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    };
  }

  async fetch<T>(path: string, options?: RequestInit): Promise<T> {
    const headers = await this.getHeaders();
    const response = await fetch(`${this.config.baseUrl}${path}`, {
      ...options,
      headers: {
        ...headers,
        ...options?.headers,
      },
    });

    if (response.status === 401 && this.config.onUnauthorized) {
      this.config.onUnauthorized();
      throw new Error('Unauthorized');
    }

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'Request failed' }));
      throw new Error(error.message || `API Error: ${response.status}`);
    }

    // Handle empty responses
    const text = await response.text();
    if (!text) {
      return {} as T;
    }

    return JSON.parse(text);
  }

  async get<T>(path: string): Promise<T> {
    return this.fetch<T>(path, { method: 'GET' });
  }

  async post<T>(path: string, body?: unknown): Promise<T> {
    return this.fetch<T>(path, {
      method: 'POST',
      body: body ? JSON.stringify(body) : undefined,
    });
  }

  async put<T>(path: string, body: unknown): Promise<T> {
    return this.fetch<T>(path, {
      method: 'PUT',
      body: JSON.stringify(body),
    });
  }

  async patch<T>(path: string, body: unknown): Promise<T> {
    return this.fetch<T>(path, {
      method: 'PATCH',
      body: JSON.stringify(body),
    });
  }

  async delete<T>(path: string): Promise<T> {
    return this.fetch<T>(path, { method: 'DELETE' });
  }

  // ============================================================================
  // Household methods
  // ============================================================================

  async getHousehold(id: string): Promise<any> {
    return this.get(`/households/${id}`);
  }

  async getHouseholds(): Promise<any[]> {
    return this.get('/households');
  }

  async createHousehold(data: { name: string; description?: string }): Promise<any> {
    return this.post('/households', data);
  }

  async updateHousehold(id: string, data: { name?: string; description?: string }): Promise<any> {
    return this.patch(`/households/${id}`, data);
  }

  // ============================================================================
  // Home Profile methods
  // ============================================================================

  async getHomeProfile(householdId: string): Promise<any> {
    return this.get(`/households/${householdId}/home-profile`);
  }

  async upsertHomeProfile(householdId: string, data: any): Promise<any> {
    return this.put(`/households/${householdId}/home-profile`, data);
  }

  // ============================================================================
  // Bill Account methods
  // ============================================================================

  async getBillAccounts(householdId: string): Promise<any[]> {
    return this.get(`/bill-accounts?householdId=${householdId}`);
  }

  async createBillAccount(data: any): Promise<any> {
    return this.post('/bill-accounts', data);
  }

  async updateBillAccount(id: string, data: any): Promise<any> {
    return this.patch(`/bill-accounts/${id}`, data);
  }

  // ============================================================================
  // Maintenance Task methods
  // ============================================================================

  async getMaintenanceTasks(householdId: string): Promise<any[]> {
    return this.get(`/maintenance-tasks?householdId=${householdId}`);
  }

  async getMaintenanceTask(id: string): Promise<any> {
    return this.get(`/maintenance-tasks/${id}`);
  }

  async createMaintenanceTask(data: any): Promise<any> {
    return this.post('/maintenance-tasks', data);
  }

  async updateMaintenanceTask(id: string, data: any): Promise<any> {
    return this.patch(`/maintenance-tasks/${id}`, data);
  }

  // ============================================================================
  // Vendor methods
  // ============================================================================

  async getHouseholdVendors(householdId: string): Promise<any[]> {
    return this.get(`/household-vendors?householdId=${householdId}`);
  }

  async createHouseholdVendor(data: any): Promise<any> {
    return this.post('/household-vendors', data);
  }

  // ============================================================================
  // Dashboard methods
  // ============================================================================

  async getDashboard(householdId: string): Promise<any> {
    return this.get(`/dashboard?householdId=${householdId}`);
  }

  // ============================================================================
  // Work Order methods
  // ============================================================================

  async getWorkOrders(householdId: string): Promise<any[]> {
    return this.get(`/work-orders?householdId=${householdId}`);
  }

  async getWorkOrder(id: string): Promise<any> {
    return this.get(`/work-orders/${id}`);
  }

  async createWorkOrder(data: any): Promise<any> {
    return this.post('/work-orders', data);
  }

  // ============================================================================
  // Conversation methods
  // ============================================================================

  async getConversations(): Promise<any[]> {
    return this.get('/conversations');
  }

  async getConversation(id: string): Promise<any> {
    return this.get(`/conversations/${id}`);
  }

  async createConversation(data: any): Promise<any> {
    return this.post('/conversations', data);
  }

  async sendMessage(conversationId: string, data: any): Promise<any> {
    return this.post(`/conversations/${conversationId}/messages`, data);
  }
}

// Factory function for creating API client
export function createApiClient(config: ApiClientConfig): ApiClient {
  return new ApiClient(config);
}

import type { ApiError, ApiResponse, Home, PaginatedResponse, Task, User } from '../types';
import type { CreateHomeSchema, CreateTaskSchema, CreateUserSchema, LoginSchema, UpdateTaskSchema } from '../schemas';

export interface ApiClientConfig {
  baseUrl: string;
  getAccessToken?: () => string | null;
  onUnauthorized?: () => void;
}

export class ApiClient {
  private config: ApiClientConfig;

  constructor(config: ApiClientConfig) {
    this.config = config;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.config.baseUrl}${endpoint}`;
    const token = this.config.getAccessToken?.();

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
    });

    if (response.status === 401) {
      this.config.onUnauthorized?.();
    }

    if (!response.ok) {
      const error: ApiError = await response.json();
      throw error;
    }

    return response.json();
  }

  // Auth endpoints
  async register(data: CreateUserSchema): Promise<ApiResponse<{ user: User; token: string }>> {
    return this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async login(data: LoginSchema): Promise<ApiResponse<{ user: User; token: string }>> {
    return this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async getMe(): Promise<ApiResponse<User>> {
    return this.request('/auth/me');
  }

  // Home endpoints
  async getHomes(page = 1, pageSize = 20): Promise<ApiResponse<PaginatedResponse<Home>>> {
    return this.request(`/homes?page=${page}&pageSize=${pageSize}`);
  }

  async getHome(id: string): Promise<ApiResponse<Home>> {
    return this.request(`/homes/${id}`);
  }

  async createHome(data: CreateHomeSchema): Promise<ApiResponse<Home>> {
    return this.request('/homes', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateHome(id: string, data: Partial<CreateHomeSchema>): Promise<ApiResponse<Home>> {
    return this.request(`/homes/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async deleteHome(id: string): Promise<ApiResponse<void>> {
    return this.request(`/homes/${id}`, {
      method: 'DELETE',
    });
  }

  // Task endpoints
  async getTasks(homeId: string, page = 1, pageSize = 20): Promise<ApiResponse<PaginatedResponse<Task>>> {
    return this.request(`/homes/${homeId}/tasks?page=${page}&pageSize=${pageSize}`);
  }

  async getTask(homeId: string, taskId: string): Promise<ApiResponse<Task>> {
    return this.request(`/homes/${homeId}/tasks/${taskId}`);
  }

  async createTask(data: CreateTaskSchema): Promise<ApiResponse<Task>> {
    return this.request(`/homes/${data.homeId}/tasks`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateTask(homeId: string, taskId: string, data: UpdateTaskSchema): Promise<ApiResponse<Task>> {
    return this.request(`/homes/${homeId}/tasks/${taskId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async deleteTask(homeId: string, taskId: string): Promise<ApiResponse<void>> {
    return this.request(`/homes/${homeId}/tasks/${taskId}`, {
      method: 'DELETE',
    });
  }
}

export function createApiClient(config: ApiClientConfig): ApiClient {
  return new ApiClient(config);
}

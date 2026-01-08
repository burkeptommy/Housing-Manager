'use client';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

// Token storage keys
const ACCESS_TOKEN_KEY = 'haven_access_token';
const REFRESH_TOKEN_KEY = 'haven_refresh_token';
const FIREBASE_TOKEN_KEY = 'haven_firebase_token';

// Current Firebase token (managed by auth context)
let currentFirebaseToken: string | null = null;

// Initialize from sessionStorage on module load (handles Fast Refresh)
if (typeof window !== 'undefined') {
  currentFirebaseToken = sessionStorage.getItem(FIREBASE_TOKEN_KEY);
}

export function getAccessToken(): string | null {
  if (typeof window === 'undefined') return null;

  // Prefer Firebase token if available
  if (currentFirebaseToken) {
    return currentFirebaseToken;
  }

  // Fallback to stored Firebase token
  const firebaseToken = sessionStorage.getItem(FIREBASE_TOKEN_KEY);
  if (firebaseToken) {
    return firebaseToken;
  }

  // Legacy JWT token fallback
  return sessionStorage.getItem(ACCESS_TOKEN_KEY);
}

export function getRefreshToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(REFRESH_TOKEN_KEY);
}

export function setTokens(accessToken: string, refreshToken: string): void {
  if (typeof window === 'undefined') return;
  sessionStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
  localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
}

/**
 * Set the Firebase ID token for API requests
 */
export function setFirebaseToken(token: string | null): void {
  currentFirebaseToken = token;
  if (typeof window !== 'undefined') {
    if (token) {
      sessionStorage.setItem(FIREBASE_TOKEN_KEY, token);
    } else {
      sessionStorage.removeItem(FIREBASE_TOKEN_KEY);
    }
  }
}

export function clearTokens(): void {
  if (typeof window === 'undefined') return;
  currentFirebaseToken = null;
  sessionStorage.removeItem(ACCESS_TOKEN_KEY);
  sessionStorage.removeItem(FIREBASE_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
}

/**
 * API Client for making authenticated requests
 */
export class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const token = getAccessToken();

    const response = await fetch(`${this.baseUrl}${path}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers,
      },
    });

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
    return this.request<T>(path, { method: 'GET' });
  }

  async post<T>(path: string, data?: unknown): Promise<T> {
    return this.request<T>(path, {
      method: 'POST',
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async put<T>(path: string, data: unknown): Promise<T> {
    return this.request<T>(path, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async patch<T>(path: string, data: unknown): Promise<T> {
    return this.request<T>(path, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async delete<T>(path: string): Promise<T> {
    return this.request<T>(path, { method: 'DELETE' });
  }
}

// Singleton API client instance
let apiClient: ApiClient | null = null;

export function getApiClient(): ApiClient {
  if (!apiClient) {
    apiClient = new ApiClient(API_BASE_URL);
  }
  return apiClient;
}

/**
 * React hook to get the API client
 * Alias for getApiClient() for use in components
 */
export function useApi(): ApiClient {
  return getApiClient();
}

export { API_BASE_URL };

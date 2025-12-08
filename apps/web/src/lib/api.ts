'use client';

import { createApiClient, ApiClient } from '@haven/core';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

// Singleton API client instance
let apiClient: ApiClient | null = null;

// Token storage keys
const ACCESS_TOKEN_KEY = 'haven_access_token';
const REFRESH_TOKEN_KEY = 'haven_refresh_token';

export function getAccessToken(): string | null {
  if (typeof window === 'undefined') return null;
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

export function clearTokens(): void {
  if (typeof window === 'undefined') return;
  sessionStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
}

export function getApiClient(): ApiClient {
  if (!apiClient) {
    apiClient = createApiClient({
      baseUrl: API_BASE_URL,
      getAccessToken,
      getRefreshToken,
      onTokenRefresh: ({ accessToken, refreshToken }) => {
        setTokens(accessToken, refreshToken);
      },
      onUnauthorized: () => {
        clearTokens();
        // Redirect to login will be handled by auth context
      },
    });
  }
  return apiClient;
}

export { API_BASE_URL };

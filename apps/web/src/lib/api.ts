'use client';

import { createApiClient, ApiClient } from '@haven/core';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

// Singleton API client instance
let apiClient: ApiClient | null = null;

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

export function getApiClient(): ApiClient {
  if (!apiClient) {
    apiClient = createApiClient({
      baseUrl: API_BASE_URL,
      getAccessToken,
      getRefreshToken: () => {
        // Don't return refresh token when using Firebase auth
        // This prevents the API client from trying to refresh with legacy tokens
        if (currentFirebaseToken || sessionStorage.getItem(FIREBASE_TOKEN_KEY)) {
          return null;
        }
        return getRefreshToken();
      },
      onTokenRefresh: ({ accessToken, refreshToken }) => {
        // Only update legacy tokens - Firebase handles its own refresh
        if (!currentFirebaseToken) {
          setTokens(accessToken, refreshToken);
        }
      },
      onUnauthorized: () => {
        // Only clear tokens and trigger logout if we're not using Firebase
        // With Firebase, a 401 might just mean we need a fresh token
        if (!currentFirebaseToken && !sessionStorage.getItem(FIREBASE_TOKEN_KEY)) {
          clearTokens();
        }
        // Redirect to login will be handled by auth context
      },
    });
  }
  return apiClient;
}

export { API_BASE_URL };

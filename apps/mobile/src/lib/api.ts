import * as SecureStore from 'expo-secure-store';
import { ApiClient, type ApiClientConfig } from '@haven/core';

// Expo environment variable type declaration
declare const process: {
  env: {
    EXPO_PUBLIC_API_URL?: string;
  };
};

const ACCESS_TOKEN_KEY = 'haven_access_token';
const REFRESH_TOKEN_KEY = 'haven_refresh_token';
const FIREBASE_TOKEN_KEY = 'haven_firebase_token';

// API base URL - defaults to production, use EXPO_PUBLIC_API_URL for development
export const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.havenhome.dev/api';

// Current Firebase token (managed by auth context)
let currentFirebaseToken: string | null = null;

// Token management functions using SecureStore
export async function getAccessToken(): Promise<string | null> {
  // Prefer Firebase token if available
  if (currentFirebaseToken) {
    return currentFirebaseToken;
  }

  // Try to get stored Firebase token
  try {
    const firebaseToken = await SecureStore.getItemAsync(FIREBASE_TOKEN_KEY);
    if (firebaseToken) {
      return firebaseToken;
    }
  } catch {
    // Fall through to legacy token
  }

  // Legacy JWT token fallback
  try {
    return await SecureStore.getItemAsync(ACCESS_TOKEN_KEY);
  } catch {
    return null;
  }
}

export async function getRefreshToken(): Promise<string | null> {
  try {
    return await SecureStore.getItemAsync(REFRESH_TOKEN_KEY);
  } catch {
    return null;
  }
}

export async function setTokens(accessToken: string, refreshToken: string): Promise<void> {
  try {
    await SecureStore.setItemAsync(ACCESS_TOKEN_KEY, accessToken);
    await SecureStore.setItemAsync(REFRESH_TOKEN_KEY, refreshToken);
  } catch (error) {
    console.error('Failed to save tokens:', error);
  }
}

/**
 * Set the Firebase ID token for API requests
 */
export async function setFirebaseToken(token: string | null): Promise<void> {
  currentFirebaseToken = token;
  try {
    if (token) {
      await SecureStore.setItemAsync(FIREBASE_TOKEN_KEY, token);
    } else {
      await SecureStore.deleteItemAsync(FIREBASE_TOKEN_KEY);
    }
  } catch (error) {
    console.error('Failed to save Firebase token:', error);
  }
}

/**
 * Get the current Firebase token synchronously (for API client)
 */
export function getFirebaseTokenSync(): string | null {
  return currentFirebaseToken;
}

export async function clearTokens(): Promise<void> {
  currentFirebaseToken = null;
  try {
    await SecureStore.deleteItemAsync(ACCESS_TOKEN_KEY);
    await SecureStore.deleteItemAsync(REFRESH_TOKEN_KEY);
    await SecureStore.deleteItemAsync(FIREBASE_TOKEN_KEY);
  } catch (error) {
    console.error('Failed to clear tokens:', error);
  }
}

// Synchronous token cache for API client (updated by auth context)
let cachedAccessToken: string | null = null;
let cachedRefreshToken: string | null = null;

export function setCachedTokens(access: string | null, refresh: string | null) {
  cachedAccessToken = access;
  cachedRefreshToken = refresh;
}

export function getCachedAccessToken(): string | null {
  // Prefer Firebase token
  if (currentFirebaseToken) {
    return currentFirebaseToken;
  }
  return cachedAccessToken;
}

export function getCachedRefreshToken(): string | null {
  return cachedRefreshToken;
}

// Create API client instance
let apiClient: ApiClient | null = null;

export function getApiClient(): ApiClient {
  if (!apiClient) {
    const config: ApiClientConfig = {
      baseUrl: API_BASE_URL,
      getToken: async () => {
        // Prefer Firebase token
        if (currentFirebaseToken) {
          return currentFirebaseToken;
        }
        return cachedAccessToken;
      },
    };
    apiClient = new ApiClient(config);
  }
  return apiClient;
}

// Initialize tokens from SecureStore (call on app start)
export async function initializeTokens(): Promise<boolean> {
  // Try Firebase token first
  try {
    const firebaseToken = await SecureStore.getItemAsync(FIREBASE_TOKEN_KEY);
    if (firebaseToken) {
      currentFirebaseToken = firebaseToken;
      return true;
    }
  } catch {
    // Fall through to legacy tokens
  }

  // Legacy tokens fallback
  const accessToken = await getAccessToken();
  const refreshToken = await getRefreshToken();

  if (accessToken && refreshToken) {
    cachedAccessToken = accessToken;
    cachedRefreshToken = refreshToken;
    return true;
  }
  return false;
}

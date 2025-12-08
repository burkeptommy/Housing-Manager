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

// API base URL - use your local IP for development or production URL
const API_BASE_URL = process.env.EXPO_PUBLIC_API_URL || 'http://localhost:3001';

// Token management functions using SecureStore
export async function getAccessToken(): Promise<string | null> {
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

export async function clearTokens(): Promise<void> {
  try {
    await SecureStore.deleteItemAsync(ACCESS_TOKEN_KEY);
    await SecureStore.deleteItemAsync(REFRESH_TOKEN_KEY);
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
      getAccessToken: () => cachedAccessToken,
      getRefreshToken: () => cachedRefreshToken,
      onTokenRefresh: async (tokens) => {
        cachedAccessToken = tokens.accessToken;
        cachedRefreshToken = tokens.refreshToken;
        await setTokens(tokens.accessToken, tokens.refreshToken);
      },
      onUnauthorized: () => {
        // Will be handled by auth context
        cachedAccessToken = null;
        cachedRefreshToken = null;
      },
    };
    apiClient = new ApiClient(config);
  }
  return apiClient;
}

// Initialize tokens from SecureStore (call on app start)
export async function initializeTokens(): Promise<boolean> {
  const accessToken = await getAccessToken();
  const refreshToken = await getRefreshToken();

  if (accessToken && refreshToken) {
    cachedAccessToken = accessToken;
    cachedRefreshToken = refreshToken;
    return true;
  }
  return false;
}

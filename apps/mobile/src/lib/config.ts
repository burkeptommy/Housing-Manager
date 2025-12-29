/**
 * Haven Mobile Configuration
 *
 * Environment variables are loaded from app.config.js or .env
 */

// API URLs
export const API_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.havenhome.dev/api';
export const API_URL_DEV = 'http://localhost:4000/api';

// Firebase
export const FIREBASE_CONFIG = {
  apiKey: process.env.EXPO_PUBLIC_FIREBASE_API_KEY || '',
  authDomain: process.env.EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN || '',
  projectId: process.env.EXPO_PUBLIC_FIREBASE_PROJECT_ID || '',
  storageBucket: process.env.EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET || '',
  messagingSenderId: process.env.EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '',
  appId: process.env.EXPO_PUBLIC_FIREBASE_APP_ID || '',
};

// Google Places API (for address autocomplete)
export const GOOGLE_PLACES_API_KEY = process.env.EXPO_PUBLIC_GOOGLE_PLACES_API_KEY || '';

// Plaid
export const PLAID_ENV = process.env.EXPO_PUBLIC_PLAID_ENV || 'sandbox';

// App Config
export const APP_CONFIG = {
  name: 'Haven',
  version: '1.0.0',
  supportEmail: 'support@havenhome.dev',
  termsUrl: 'https://havenhome.dev/terms',
  privacyUrl: 'https://havenhome.dev/privacy',
};

// Feature Flags
export const FEATURES = {
  enablePlaid: true,
  enableApplePay: true,
  enableBiometrics: true,
  enablePushNotifications: true,
};

// Dev mode check
export const IS_DEV = __DEV__;

# Haven Mobile: M02 - Authentication & User Flow

**Created:** December 29, 2024  
**Priority:** P0 - Required for all features  
**Estimated Time:** 3-4 hours  
**Dependencies:** M01 complete

---

## CRITICAL RULES

1. **Apple Sign In is REQUIRED** - App Store rejects apps with social login that don't include Apple
2. **DO NOT store sensitive data in AsyncStorage** - Use SecureStore for tokens
3. **Handle all auth errors gracefully** - Show user-friendly messages
4. **Test on iOS Simulator** with Firebase test accounts

---

## Overview

This prompt implements complete authentication:
1. Apple Sign In (required for App Store)
2. Google Sign In (popular option)
3. Email/password login (existing, polished)
4. Firebase authentication integration
5. Biometric unlock (Face ID / Touch ID)
6. Proper session management

---

## PHASE 1: Install Auth Dependencies

### Task 1.1: Install Packages

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Apple Authentication
pnpm add expo-apple-authentication

# Google Authentication
pnpm add @react-native-google-signin/google-signin

# Crypto for nonce generation (Apple Sign In requirement)
pnpm add expo-crypto

# Local authentication (biometrics)
pnpm add expo-local-authentication
```

### Task 1.2: Add Google Web Client ID to Config

Update `apps/mobile/src/lib/config.ts` to add:

```typescript
// Google Sign In - Get from Firebase Console > Authentication > Sign-in method > Google
export const GOOGLE_WEB_CLIENT_ID = process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID || 'YOUR_GOOGLE_WEB_CLIENT_ID';
```

Note: Get the Web Client ID from Firebase Console:
1. Go to Firebase Console > Authentication > Sign-in method
2. Enable Google provider
3. Copy the Web Client ID (not the iOS Client ID)

### Task 1.3: Update app.json plugins

Add to `apps/mobile/app.json` plugins array:

```json
{
  "plugins": [
    "expo-router",
    "expo-secure-store",
    "expo-apple-authentication",
    [
      "expo-local-authentication",
      {
        "faceIDPermission": "Allow Haven to use Face ID for quick login."
      }
    ],
    [
      "expo-image-picker",
      {
        "photosPermission": "Haven needs photo access to upload documents."
      }
    ]
  ]
}
```

---

## PHASE 2: Create Auth Service

### Task 2.1: Create Google Auth Service

Create `apps/mobile/src/lib/google-auth.ts`:

```typescript
import { GoogleSignin, statusCodes } from '@react-native-google-signin/google-signin';
import { GoogleAuthProvider, signInWithCredential } from 'firebase/auth';
import { auth } from './firebase';
import { GOOGLE_WEB_CLIENT_ID } from './config';

export interface GoogleAuthResult {
  success: boolean;
  user?: {
    uid: string;
    email: string | null;
    displayName: string | null;
    photoURL: string | null;
  };
  error?: string;
}

let isConfigured = false;

/**
 * Configure Google Sign In
 * Call this once at app startup
 */
export function configureGoogleSignIn(): void {
  if (isConfigured) return;
  
  GoogleSignin.configure({
    webClientId: GOOGLE_WEB_CLIENT_ID, // From Firebase console
    offlineAccess: true,
    scopes: ['profile', 'email'],
  });
  
  isConfigured = true;
}

/**
 * Check if Google Sign In is available
 */
export async function isGoogleAuthAvailable(): Promise<boolean> {
  try {
    await GoogleSignin.hasPlayServices({ showPlayServicesUpdateDialog: true });
    return true;
  } catch {
    return false;
  }
}

/**
 * Sign in with Google
 */
export async function signInWithGoogle(): Promise<GoogleAuthResult> {
  try {
    // Ensure Google Sign In is configured
    configureGoogleSignIn();
    
    // Check for Play Services
    await GoogleSignin.hasPlayServices({ showPlayServicesUpdateDialog: true });
    
    // Sign in with Google
    const userInfo = await GoogleSignin.signIn();
    
    if (!userInfo.data?.idToken) {
      return {
        success: false,
        error: 'No ID token received from Google',
      };
    }
    
    // Create Firebase credential
    const googleCredential = GoogleAuthProvider.credential(userInfo.data.idToken);
    
    // Sign in to Firebase
    const userCredential = await signInWithCredential(auth, googleCredential);
    const user = userCredential.user;
    
    return {
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
      },
    };
  } catch (error: any) {
    // Handle specific Google Sign In errors
    if (error.code === statusCodes.SIGN_IN_CANCELLED) {
      return {
        success: false,
        error: 'Sign in was cancelled',
      };
    }
    
    if (error.code === statusCodes.IN_PROGRESS) {
      return {
        success: false,
        error: 'Sign in already in progress',
      };
    }
    
    if (error.code === statusCodes.PLAY_SERVICES_NOT_AVAILABLE) {
      return {
        success: false,
        error: 'Google Play Services not available',
      };
    }
    
    console.error('Google Sign In error:', error);
    return {
      success: false,
      error: error.message || 'Failed to sign in with Google',
    };
  }
}

/**
 * Sign out from Google
 */
export async function signOutGoogle(): Promise<void> {
  try {
    await GoogleSignin.signOut();
  } catch (error) {
    console.error('Google Sign Out error:', error);
  }
}
```

### Task 2.2: Create Apple Auth Service

Create `apps/mobile/src/lib/apple-auth.ts`:

```typescript
import * as AppleAuthentication from 'expo-apple-authentication';
import * as Crypto from 'expo-crypto';
import { OAuthProvider, signInWithCredential } from 'firebase/auth';
import { auth } from './firebase';

/**
 * Apple Sign In for Haven
 * 
 * Flow:
 * 1. Generate nonce for security
 * 2. Request Apple credentials
 * 3. Create Firebase credential
 * 4. Sign in to Firebase
 */

export interface AppleAuthResult {
  success: boolean;
  user?: {
    uid: string;
    email: string | null;
    displayName: string | null;
  };
  error?: string;
}

/**
 * Generate a random nonce for Apple Sign In
 */
async function generateNonce(length = 32): Promise<string> {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  let result = '';
  const randomValues = await Crypto.getRandomBytesAsync(length);
  for (let i = 0; i < length; i++) {
    result += charset[randomValues[i] % charset.length];
  }
  return result;
}

/**
 * Hash the nonce using SHA256
 */
async function sha256(input: string): Promise<string> {
  return await Crypto.digestStringAsync(Crypto.CryptoDigestAlgorithm.SHA256, input);
}

/**
 * Check if Apple Sign In is available on this device
 */
export async function isAppleAuthAvailable(): Promise<boolean> {
  return await AppleAuthentication.isAvailableAsync();
}

/**
 * Sign in with Apple
 */
export async function signInWithApple(): Promise<AppleAuthResult> {
  try {
    // Check availability
    const isAvailable = await isAppleAuthAvailable();
    if (!isAvailable) {
      return {
        success: false,
        error: 'Apple Sign In is not available on this device',
      };
    }

    // Generate nonce
    const rawNonce = await generateNonce();
    const hashedNonce = await sha256(rawNonce);

    // Request Apple credentials
    const credential = await AppleAuthentication.signInAsync({
      requestedScopes: [
        AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        AppleAuthentication.AppleAuthenticationScope.EMAIL,
      ],
      nonce: hashedNonce,
    });

    if (!credential.identityToken) {
      return {
        success: false,
        error: 'No identity token received from Apple',
      };
    }

    // Create Firebase credential
    const provider = new OAuthProvider('apple.com');
    const firebaseCredential = provider.credential({
      idToken: credential.identityToken,
      rawNonce,
    });

    // Sign in to Firebase
    const userCredential = await signInWithCredential(auth, firebaseCredential);
    const user = userCredential.user;

    // Apple only provides name on first sign in, so we need to handle that
    let displayName = user.displayName;
    if (!displayName && credential.fullName) {
      const { givenName, familyName } = credential.fullName;
      if (givenName || familyName) {
        displayName = [givenName, familyName].filter(Boolean).join(' ');
        // Note: You might want to update the user profile here
      }
    }

    return {
      success: true,
      user: {
        uid: user.uid,
        email: user.email,
        displayName,
      },
    };
  } catch (error: any) {
    // Handle specific Apple auth errors
    if (error.code === 'ERR_REQUEST_CANCELED') {
      return {
        success: false,
        error: 'Sign in was cancelled',
      };
    }
    
    console.error('Apple Sign In error:', error);
    return {
      success: false,
      error: error.message || 'Failed to sign in with Apple',
    };
  }
}
```

### Task 2.3: Create Biometric Auth Service

Create `apps/mobile/src/lib/biometric-auth.ts`:

```typescript
import * as LocalAuthentication from 'expo-local-authentication';
import * as SecureStore from 'expo-secure-store';

const BIOMETRIC_ENABLED_KEY = 'haven_biometric_enabled';
const BIOMETRIC_USER_KEY = 'haven_biometric_user_email';

export interface BiometricStatus {
  isAvailable: boolean;
  isEnabled: boolean;
  biometricType: 'fingerprint' | 'facial' | 'iris' | 'none';
}

/**
 * Get the type of biometric authentication available
 */
async function getBiometricType(): Promise<'fingerprint' | 'facial' | 'iris' | 'none'> {
  const types = await LocalAuthentication.supportedAuthenticationTypesAsync();
  
  if (types.includes(LocalAuthentication.AuthenticationType.FACIAL_RECOGNITION)) {
    return 'facial';
  }
  if (types.includes(LocalAuthentication.AuthenticationType.FINGERPRINT)) {
    return 'fingerprint';
  }
  if (types.includes(LocalAuthentication.AuthenticationType.IRIS)) {
    return 'iris';
  }
  return 'none';
}

/**
 * Check biometric authentication status
 */
export async function getBiometricStatus(): Promise<BiometricStatus> {
  const isAvailable = await LocalAuthentication.hasHardwareAsync();
  const isEnrolled = await LocalAuthentication.isEnrolledAsync();
  const biometricType = await getBiometricType();
  
  let isEnabled = false;
  try {
    const enabled = await SecureStore.getItemAsync(BIOMETRIC_ENABLED_KEY);
    isEnabled = enabled === 'true';
  } catch {
    // Ignore
  }

  return {
    isAvailable: isAvailable && isEnrolled,
    isEnabled,
    biometricType,
  };
}

/**
 * Enable biometric authentication for a user
 */
export async function enableBiometric(userEmail: string): Promise<boolean> {
  try {
    await SecureStore.setItemAsync(BIOMETRIC_ENABLED_KEY, 'true');
    await SecureStore.setItemAsync(BIOMETRIC_USER_KEY, userEmail);
    return true;
  } catch (error) {
    console.error('Failed to enable biometric:', error);
    return false;
  }
}

/**
 * Disable biometric authentication
 */
export async function disableBiometric(): Promise<boolean> {
  try {
    await SecureStore.deleteItemAsync(BIOMETRIC_ENABLED_KEY);
    await SecureStore.deleteItemAsync(BIOMETRIC_USER_KEY);
    return true;
  } catch (error) {
    console.error('Failed to disable biometric:', error);
    return false;
  }
}

/**
 * Get the email for biometric login
 */
export async function getBiometricUserEmail(): Promise<string | null> {
  try {
    return await SecureStore.getItemAsync(BIOMETRIC_USER_KEY);
  } catch {
    return null;
  }
}

/**
 * Authenticate with biometrics
 */
export async function authenticateWithBiometric(): Promise<{
  success: boolean;
  error?: string;
}> {
  try {
    const status = await getBiometricStatus();
    
    if (!status.isAvailable) {
      return {
        success: false,
        error: 'Biometric authentication is not available',
      };
    }

    if (!status.isEnabled) {
      return {
        success: false,
        error: 'Biometric authentication is not enabled',
      };
    }

    const promptMessage = status.biometricType === 'facial' 
      ? 'Use Face ID to sign in to Haven'
      : 'Use Touch ID to sign in to Haven';

    const result = await LocalAuthentication.authenticateAsync({
      promptMessage,
      cancelLabel: 'Cancel',
      disableDeviceFallback: false,
      fallbackLabel: 'Use Password',
    });

    if (result.success) {
      return { success: true };
    }

    return {
      success: false,
      error: result.error || 'Authentication failed',
    };
  } catch (error: any) {
    return {
      success: false,
      error: error.message || 'Biometric authentication failed',
    };
  }
}

/**
 * Get friendly name for biometric type
 */
export function getBiometricName(type: 'fingerprint' | 'facial' | 'iris' | 'none'): string {
  switch (type) {
    case 'facial':
      return 'Face ID';
    case 'fingerprint':
      return 'Touch ID';
    case 'iris':
      return 'Iris Scan';
    default:
      return 'Biometric';
  }
}
```

### Task 2.4: Update Auth Context

Update `apps/mobile/src/contexts/auth-context.tsx`:

```typescript
import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { onAuthStateChanged, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut, User, sendPasswordResetEmail } from 'firebase/auth';
import * as SecureStore from 'expo-secure-store';
import { auth } from '../lib/firebase';
import { setFirebaseToken, clearTokens, initializeTokens } from '../lib/api';
import { signInWithApple, isAppleAuthAvailable } from '../lib/apple-auth';
import { signInWithGoogle, configureGoogleSignIn } from '../lib/google-auth';
import { authenticateWithBiometric, getBiometricStatus, getBiometricUserEmail, BiometricStatus } from '../lib/biometric-auth';

interface AuthState {
  user: User | null;
  isLoading: boolean;
  isInitialized: boolean;
  biometricStatus: BiometricStatus | null;
}

interface AuthContextType extends AuthState {
  signIn: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  signUp: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  signInWithAppleAuth: () => Promise<{ success: boolean; error?: string }>;
  signInWithGoogleAuth: () => Promise<{ success: boolean; error?: string }>;
  signInWithBiometric: () => Promise<{ success: boolean; error?: string }>;
  resetPassword: (email: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
  refreshBiometricStatus: () => Promise<void>;
  isAppleSignInAvailable: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

const STORED_EMAIL_KEY = 'haven_stored_email';
const STORED_PASSWORD_KEY = 'haven_stored_password';

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    user: null,
    isLoading: true,
    isInitialized: false,
    biometricStatus: null,
  });
  const [isAppleSignInAvailable, setIsAppleSignInAvailable] = useState(false);

  // Configure Google Sign In and check Apple availability
  useEffect(() => {
    configureGoogleSignIn();
    isAppleAuthAvailable().then(setIsAppleSignInAvailable);
  }, []);

  // Check biometric status
  const refreshBiometricStatus = useCallback(async () => {
    const status = await getBiometricStatus();
    setState(prev => ({ ...prev, biometricStatus: status }));
  }, []);

  // Initialize auth state
  useEffect(() => {
    const initAuth = async () => {
      // Check for stored tokens
      await initializeTokens();
      await refreshBiometricStatus();
    };

    initAuth();

    // Listen for auth state changes
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        // Get and store the ID token
        const token = await user.getIdToken();
        await setFirebaseToken(token);
      } else {
        await clearTokens();
      }

      setState(prev => ({
        ...prev,
        user,
        isLoading: false,
        isInitialized: true,
      }));
    });

    return unsubscribe;
  }, [refreshBiometricStatus]);

  // Sign in with email/password
  const signIn = async (email: string, password: string): Promise<{ success: boolean; error?: string }> => {
    setState(prev => ({ ...prev, isLoading: true }));
    
    try {
      await signInWithEmailAndPassword(auth, email, password);
      
      // Store credentials for biometric login
      await SecureStore.setItemAsync(STORED_EMAIL_KEY, email);
      await SecureStore.setItemAsync(STORED_PASSWORD_KEY, password);
      
      return { success: true };
    } catch (error: any) {
      console.error('Sign in error:', error);
      
      let errorMessage = 'Failed to sign in';
      switch (error.code) {
        case 'auth/invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'auth/user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'auth/user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'auth/wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'auth/too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'auth/invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
      }
      
      return { success: false, error: errorMessage };
    } finally {
      setState(prev => ({ ...prev, isLoading: false }));
    }
  };

  // Sign up with email/password
  const signUp = async (email: string, password: string): Promise<{ success: boolean; error?: string }> => {
    setState(prev => ({ ...prev, isLoading: true }));
    
    try {
      await createUserWithEmailAndPassword(auth, email, password);
      
      // Store credentials for biometric login
      await SecureStore.setItemAsync(STORED_EMAIL_KEY, email);
      await SecureStore.setItemAsync(STORED_PASSWORD_KEY, password);
      
      return { success: true };
    } catch (error: any) {
      console.error('Sign up error:', error);
      
      let errorMessage = 'Failed to create account';
      switch (error.code) {
        case 'auth/email-already-in-use':
          errorMessage = 'An account with this email already exists';
          break;
        case 'auth/invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'auth/weak-password':
          errorMessage = 'Password must be at least 6 characters';
          break;
      }
      
      return { success: false, error: errorMessage };
    } finally {
      setState(prev => ({ ...prev, isLoading: false }));
    }
  };

  // Sign in with Apple
  const signInWithAppleAuth = async (): Promise<{ success: boolean; error?: string }> => {
    setState(prev => ({ ...prev, isLoading: true }));
    
    try {
      const result = await signInWithApple();
      
      if (!result.success) {
        return { success: false, error: result.error };
      }
      
      return { success: true };
    } catch (error: any) {
      return { success: false, error: error.message || 'Apple Sign In failed' };
    } finally {
      setState(prev => ({ ...prev, isLoading: false }));
    }
  };

  // Sign in with Google
  const signInWithGoogleAuth = async (): Promise<{ success: boolean; error?: string }> => {
    setState(prev => ({ ...prev, isLoading: true }));
    
    try {
      const result = await signInWithGoogle();
      
      if (!result.success) {
        return { success: false, error: result.error };
      }
      
      return { success: true };
    } catch (error: any) {
      return { success: false, error: error.message || 'Google Sign In failed' };
    } finally {
      setState(prev => ({ ...prev, isLoading: false }));
    }
  };

  // Sign in with biometrics
  const signInWithBiometric = async (): Promise<{ success: boolean; error?: string }> => {
    // First, authenticate with biometrics
    const authResult = await authenticateWithBiometric();
    
    if (!authResult.success) {
      return authResult;
    }

    // Get stored credentials
    try {
      const email = await SecureStore.getItemAsync(STORED_EMAIL_KEY);
      const password = await SecureStore.getItemAsync(STORED_PASSWORD_KEY);

      if (!email || !password) {
        return {
          success: false,
          error: 'No stored credentials. Please sign in with your password first.',
        };
      }

      // Sign in with stored credentials
      return await signIn(email, password);
    } catch (error) {
      return {
        success: false,
        error: 'Failed to retrieve stored credentials',
      };
    }
  };

  // Reset password
  const resetPassword = async (email: string): Promise<{ success: boolean; error?: string }> => {
    try {
      await sendPasswordResetEmail(auth, email);
      return { success: true };
    } catch (error: any) {
      let errorMessage = 'Failed to send reset email';
      if (error.code === 'auth/user-not-found') {
        errorMessage = 'No account found with this email';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = 'Invalid email address';
      }
      return { success: false, error: errorMessage };
    }
  };

  // Logout
  const logout = async () => {
    setState(prev => ({ ...prev, isLoading: true }));
    
    try {
      await signOut(auth);
      await clearTokens();
      // Don't clear stored credentials - keep them for biometric login
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      setState(prev => ({ ...prev, isLoading: false }));
    }
  };

  const value: AuthContextType = {
    ...state,
    signIn,
    signUp,
    signInWithAppleAuth,
    signInWithGoogleAuth,
    signInWithBiometric,
    resetPassword,
    logout,
    refreshBiometricStatus,
    isAppleSignInAvailable,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
```

---

## PHASE 3: Create Login Screen

### Task 3.1: Update Login Screen

Update `apps/mobile/app/(auth)/login.tsx`:

```typescript
import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
  Image,
} from 'react-native';
import { useRouter, Link } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import * as AppleAuthentication from 'expo-apple-authentication';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { Button, Input, LoadingSpinner } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';
import { getBiometricName } from '../../src/lib/biometric-auth';

export default function LoginScreen() {
  const router = useRouter();
  const { 
    signIn, 
    signInWithAppleAuth,
    signInWithGoogleAuth,
    signInWithBiometric,
    isLoading, 
    isAppleSignInAvailable,
    biometricStatus,
    user,
  } = useAuth();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  // Redirect if already authenticated
  useEffect(() => {
    if (user) {
      router.replace('/(tabs)');
    }
  }, [user]);

  // Auto-prompt biometric if available and enabled
  useEffect(() => {
    if (biometricStatus?.isEnabled && biometricStatus?.isAvailable) {
      handleBiometricLogin();
    }
  }, [biometricStatus]);

  const handleEmailLogin = async () => {
    if (!email.trim() || !password.trim()) {
      setError('Please enter your email and password');
      return;
    }

    setError('');
    const result = await signIn(email.trim(), password);
    
    if (!result.success) {
      setError(result.error || 'Failed to sign in');
    }
  };

  const handleAppleLogin = async () => {
    setError('');
    const result = await signInWithAppleAuth();
    
    if (!result.success && result.error !== 'Sign in was cancelled') {
      setError(result.error || 'Apple Sign In failed');
    }
  };

  const handleGoogleLogin = async () => {
    setError('');
    const result = await signInWithGoogleAuth();
    
    if (!result.success && result.error !== 'Sign in was cancelled') {
      setError(result.error || 'Google Sign In failed');
    }
  };

  const handleBiometricLogin = async () => {
    setError('');
    const result = await signInWithBiometric();
    
    if (!result.success && result.error !== 'Authentication failed') {
      // Only show error if it's not a user cancellation
      if (!result.error?.includes('cancel')) {
        setError(result.error || 'Biometric login failed');
      }
    }
  };

  const handleForgotPassword = () => {
    router.push('/(auth)/forgot-password');
  };

  if (isLoading && !email) {
    return <LoadingSpinner fullScreen message="Signing in..." />;
  }

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          {/* Logo & Header */}
          <View style={styles.header}>
            <View style={styles.logoContainer}>
              <Text style={styles.logoText}>Haven</Text>
            </View>
            <Text style={styles.title}>Welcome back</Text>
            <Text style={styles.subtitle}>
              Sign in to manage your home
            </Text>
          </View>

          {/* Error Message */}
          {error ? (
            <View style={styles.errorContainer}>
              <Ionicons name="alert-circle" size={20} color={colors.status.error} />
              <Text style={styles.errorText}>{error}</Text>
            </View>
          ) : null}

          {/* Social Login Buttons */}
          <View style={styles.socialButtons}>
            {isAppleSignInAvailable && (
              <AppleAuthentication.AppleAuthenticationButton
                buttonType={AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN}
                buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.BLACK}
                cornerRadius={borderRadius.lg}
                style={styles.appleButton}
                onPress={handleAppleLogin}
              />
            )}

            {/* Google Sign In Button */}
            <TouchableOpacity
              style={styles.googleButton}
              onPress={handleGoogleLogin}
            >
              <Image
                source={{ uri: 'https://developers.google.com/identity/images/g-logo.png' }}
                style={styles.googleLogo}
              />
              <Text style={styles.googleButtonText}>Sign in with Google</Text>
            </TouchableOpacity>

            {biometricStatus?.isAvailable && biometricStatus?.isEnabled && (
              <TouchableOpacity
                style={styles.biometricButton}
                onPress={handleBiometricLogin}
              >
                <Ionicons
                  name={biometricStatus.biometricType === 'facial' ? 'scan' : 'finger-print'}
                  size={24}
                  color={colors.haven.navy[900]}
                />
                <Text style={styles.biometricButtonText}>
                  Sign in with {getBiometricName(biometricStatus.biometricType)}
                </Text>
              </TouchableOpacity>
            )}
          </View>

          {/* Divider */}
          {(isAppleSignInAvailable || biometricStatus?.isEnabled) && (
            <View style={styles.divider}>
              <View style={styles.dividerLine} />
              <Text style={styles.dividerText}>or continue with email</Text>
              <View style={styles.dividerLine} />
            </View>
          )}

          {/* Email/Password Form */}
          <View style={styles.form}>
            <Input
              label="Email"
              placeholder="you@example.com"
              value={email}
              onChangeText={setEmail}
              keyboardType="email-address"
              autoCapitalize="none"
              autoComplete="email"
              leftIcon="mail-outline"
            />

            <Input
              label="Password"
              placeholder="Enter your password"
              value={password}
              onChangeText={setPassword}
              secureTextEntry
              autoCapitalize="none"
              autoComplete="password"
              leftIcon="lock-closed-outline"
            />

            <TouchableOpacity
              style={styles.forgotPassword}
              onPress={handleForgotPassword}
            >
              <Text style={styles.forgotPasswordText}>Forgot password?</Text>
            </TouchableOpacity>

            <Button
              title={isLoading ? 'Signing in...' : 'Sign In'}
              onPress={handleEmailLogin}
              loading={isLoading}
              fullWidth
              style={styles.signInButton}
            />
          </View>

          {/* Sign Up Link */}
          <View style={styles.signUpContainer}>
            <Text style={styles.signUpText}>Don't have an account? </Text>
            <Link href="/(auth)/register" asChild>
              <TouchableOpacity>
                <Text style={styles.signUpLink}>Sign up</Text>
              </TouchableOpacity>
            </Link>
          </View>

          {/* Demo Credentials (Dev only) */}
          {__DEV__ && (
            <View style={styles.devSection}>
              <Text style={styles.devTitle}>Demo Login:</Text>
              <TouchableOpacity
                style={styles.devButton}
                onPress={() => {
                  setEmail('bob@example.com');
                  setPassword('Bob123!');
                }}
              >
                <Text style={styles.devButtonText}>Use Bob Morrison (Homeowner)</Text>
              </TouchableOpacity>
            </View>
          )}
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    padding: spacing[5],
    justifyContent: 'center',
  },
  header: {
    alignItems: 'center',
    marginBottom: spacing[6],
  },
  logoContainer: {
    width: 80,
    height: 80,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.navy[900],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  logoText: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.haven.champagne[500],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[1],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
  },
  errorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.errorLight,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
  },
  errorText: {
    flex: 1,
    marginLeft: spacing[2],
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
  },
  socialButtons: {
    gap: spacing[3],
    marginBottom: spacing[4],
  },
  appleButton: {
    width: '100%',
    height: 50,
  },
  googleButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.white,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.border.default,
    gap: spacing[2],
    height: 50,
  },
  googleLogo: {
    width: 20,
    height: 20,
  },
  googleButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  biometricButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.gray[100],
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    gap: spacing[2],
  },
  biometricButtonText: {
    fontSize: typography.fontSizes.base,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.navy[900],
  },
  divider: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing[4],
  },
  dividerLine: {
    flex: 1,
    height: 1,
    backgroundColor: colors.border.default,
  },
  dividerText: {
    marginHorizontal: spacing[3],
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
  },
  form: {
    marginBottom: spacing[4],
  },
  forgotPassword: {
    alignSelf: 'flex-end',
    marginBottom: spacing[4],
    marginTop: -spacing[2],
  },
  forgotPasswordText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.medium,
  },
  signInButton: {
    marginTop: spacing[2],
  },
  signUpContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  signUpText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  signUpLink: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.champagne[600],
    fontWeight: typography.fontWeights.semibold,
  },
  devSection: {
    marginTop: spacing[8],
    padding: spacing[4],
    backgroundColor: colors.haven.champagne[50],
    borderRadius: borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.haven.champagne[200],
    borderStyle: 'dashed',
  },
  devTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.haven.champagne[600],
    marginBottom: spacing[2],
  },
  devButton: {
    backgroundColor: colors.haven.champagne[100],
    padding: spacing[2],
    borderRadius: borderRadius.md,
  },
  devButtonText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.navy[800],
    textAlign: 'center',
  },
});
```

### Task 3.2: Create Forgot Password Screen

Create `apps/mobile/app/(auth)/forgot-password.tsx`:

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
} from 'react-native';
import { useRouter } from 'expo-router';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../src/contexts/auth-context';
import { Button, Input } from '../../src/components';
import { colors, typography, spacing, borderRadius } from '../../src/lib/theme';

export default function ForgotPasswordScreen() {
  const router = useRouter();
  const { resetPassword } = useAuth();

  const [email, setEmail] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleResetPassword = async () => {
    if (!email.trim()) {
      setError('Please enter your email address');
      return;
    }

    setError('');
    setIsLoading(true);

    const result = await resetPassword(email.trim());

    setIsLoading(false);

    if (result.success) {
      setSuccess(true);
    } else {
      setError(result.error || 'Failed to send reset email');
    }
  };

  if (success) {
    return (
      <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
        <View style={styles.successContainer}>
          <View style={styles.successIcon}>
            <Ionicons name="mail" size={48} color={colors.haven.champagne[500]} />
          </View>
          <Text style={styles.successTitle}>Check your email</Text>
          <Text style={styles.successText}>
            We've sent password reset instructions to {email}
          </Text>
          <Button
            title="Back to Sign In"
            onPress={() => router.back()}
            fullWidth
            style={styles.backButton}
          />
        </View>
      </SafeAreaView>
    );
  }

  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView
          contentContainerStyle={styles.scrollContent}
          keyboardShouldPersistTaps="handled"
        >
          <View style={styles.header}>
            <Text style={styles.title}>Reset Password</Text>
            <Text style={styles.subtitle}>
              Enter your email and we'll send you instructions to reset your password
            </Text>
          </View>

          {error ? (
            <View style={styles.errorContainer}>
              <Ionicons name="alert-circle" size={20} color={colors.status.error} />
              <Text style={styles.errorText}>{error}</Text>
            </View>
          ) : null}

          <Input
            label="Email"
            placeholder="you@example.com"
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            autoComplete="email"
            leftIcon="mail-outline"
          />

          <Button
            title={isLoading ? 'Sending...' : 'Send Reset Link'}
            onPress={handleResetPassword}
            loading={isLoading}
            fullWidth
          />

          <Button
            title="Back to Sign In"
            onPress={() => router.back()}
            variant="ghost"
            fullWidth
            style={styles.backButton}
          />
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    padding: spacing[5],
    justifyContent: 'center',
  },
  header: {
    marginBottom: spacing[6],
  },
  title: {
    fontSize: typography.fontSizes['2xl'],
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  subtitle: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    lineHeight: 24,
  },
  errorContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.status.errorLight,
    padding: spacing[3],
    borderRadius: borderRadius.lg,
    marginBottom: spacing[4],
  },
  errorText: {
    flex: 1,
    marginLeft: spacing[2],
    fontSize: typography.fontSizes.sm,
    color: colors.status.error,
  },
  backButton: {
    marginTop: spacing[3],
  },
  successContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing[5],
  },
  successIcon: {
    width: 96,
    height: 96,
    borderRadius: 48,
    backgroundColor: colors.haven.champagne[100],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  successTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  successText: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    textAlign: 'center',
    marginBottom: spacing[6],
  },
});
```

---

## PHASE 4: Update Navigation

### Task 4.1: Update Auth Layout

Update `apps/mobile/app/(auth)/_layout.tsx`:

```typescript
import { Stack } from 'expo-router';
import { colors, typography } from '../../src/lib/theme';

export default function AuthLayout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: {
          backgroundColor: colors.white,
        },
        headerTintColor: colors.haven.navy[900],
        headerTitleStyle: {
          fontWeight: typography.fontWeights.semibold,
        },
        headerShadowVisible: false,
        headerBackTitleVisible: false,
      }}
    >
      <Stack.Screen
        name="login"
        options={{
          headerShown: false,
        }}
      />
      <Stack.Screen
        name="register"
        options={{
          title: 'Create Account',
        }}
      />
      <Stack.Screen
        name="forgot-password"
        options={{
          title: 'Reset Password',
        }}
      />
      <Stack.Screen
        name="onboarding"
        options={{
          headerShown: false,
        }}
      />
    </Stack>
  );
}
```

### Task 4.2: Update Root Layout

Update `apps/mobile/app/_layout.tsx`:

```typescript
import { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AuthProvider } from '../src/contexts/auth-context';
import { OnboardingProvider } from '../src/contexts/onboarding-context';
import { colors } from '../src/lib/theme';

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <AuthProvider>
          <OnboardingProvider>
            <StatusBar style="dark" />
            <Stack screenOptions={{ headerShown: false }}>
              <Stack.Screen name="index" />
              <Stack.Screen name="(auth)" />
              <Stack.Screen name="(tabs)" />
            </Stack>
          </OnboardingProvider>
        </AuthProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
```

---

## PHASE 5: Verification

### Task 5.1: Test Checklist

- [ ] App launches and shows login screen
- [ ] Apple Sign In button appears (on real device/configured simulator)
- [ ] Email/password login works with bob@example.com / Bob123!
- [ ] Error messages display correctly for invalid credentials
- [ ] Forgot password flow sends reset email
- [ ] Biometric prompt shows if enabled
- [ ] Navigation to register works
- [ ] Successful login redirects to tabs
- [ ] No TypeScript errors (`pnpm typecheck`)

### Task 5.2: Test Commands

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck
pnpm start --ios
```

---

## Summary

After completing this prompt:
1. ✅ Apple Sign In implemented (App Store requirement)
2. ✅ Google Sign In implemented (popular option)
3. ✅ Email/password authentication with Firebase
4. ✅ Biometric authentication (Face ID / Touch ID)
5. ✅ Password reset functionality
6. ✅ Secure credential storage
7. ✅ Polished login UI with Haven branding

**Next Prompt:** M03 - Magic Onboarding with ATTOM integration

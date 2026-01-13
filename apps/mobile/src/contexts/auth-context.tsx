import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  type ReactNode,
} from 'react';
import { useRouter, useSegments } from 'expo-router';
import type { User, Household, HouseholdDetail } from '@haven/core';
import {
  getApiClient,
  clearTokens,
  setFirebaseToken,
  API_BASE_URL,
} from '../lib/api';
import {
  signIn as firebaseSignIn,
  signUp as firebaseSignUp,
  signOut as firebaseSignOut,
  onAuthChange,
  getIdToken,
  resetPassword as firebaseResetPassword,
  type FirebaseUser,
} from '../lib/firebase';
import { signInWithApple, isAppleAuthAvailable } from '../lib/apple-auth';
import { signInWithGoogle, configureGoogleSignIn } from '../lib/google-auth';
import {
  authenticateWithBiometric,
  getBiometricStatus,
  BiometricStatus,
} from '../lib/biometric-auth';
import * as SecureStore from 'expo-secure-store';

const STORED_EMAIL_KEY = 'haven_stored_email';
const STORED_PASSWORD_KEY = 'haven_stored_password';

// Extended user info including household data from /api/me
interface UserInfo {
  id: string;
  email: string;
  displayName: string | null;
  firstName: string | null;
  lastName: string | null;
  avatarUrl: string | null;
  role: string;
  emailVerified: boolean;
  createdAt: Date;
}

interface HouseholdInfo {
  id: string;
  name: string;
  description: string | null;
  subscriptionPlan: string;
  subscriptionStatus: string;
  billingCycleDay: number;
  role: string;
  hasProperty: boolean;
  propertyAddress?: string;
}

interface MeResponse {
  user: UserInfo;
  household: HouseholdInfo | null;
  memberships: Array<{
    householdId: string;
    householdName: string;
    role: string;
    status: string;
  }>;
}

// New simplified registration input (Alfred-first flow)
interface RegisterSimpleInput {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  address: {
    addressLine1: string;
    addressLine2?: string;
    city: string;
    state: string;
    zipCode: string;
  };
}

// Property details from ATTOM (for onboarding)
interface PropertyDetails {
  bedrooms: number | null;
  bathrooms: number | null;
  squareFeet: number | null;
  yearBuilt: number | null;
  lotSizeAcres: number | null;
  stories: number | null;
  heatingType: string | null;
  heatingFuel: string | null;
  coolingType: string | null;
  waterType: string | null;
  sewerType: string | null;
  garageSpaces: number | null;
  pool: boolean | null;
  propertyType: string | null;
}

// Social registration input (Apple/Google)
interface RegisterSocialInput {
  email: string;
  firstName: string;
  lastName: string;
  address: {
    addressLine1: string;
    addressLine2?: string;
    city: string;
    state: string;
    zipCode: string;
  };
  propertyDetails?: PropertyDetails | null;
}

// Pending social auth data when user needs to complete registration
interface PendingSocialAuth {
  email: string;
  firstName: string;
  lastName: string;
  provider: 'apple' | 'google';
}

interface AuthContextValue {
  user: User | null;
  firebaseUser: FirebaseUser | null;
  households: Household[];
  currentHousehold: HouseholdDetail | null;
  householdInfo: HouseholdInfo | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  needsOnboarding: boolean;
  needsSocialRegistration: boolean;
  pendingSocialAuth: PendingSocialAuth | null;
  biometricStatus: BiometricStatus | null;
  isAppleSignInAvailable: boolean;
  login: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  register: (email: string, password: string, displayName?: string) => Promise<{ success: boolean; error?: string }>;
  registerSimple: (input: RegisterSimpleInput) => Promise<{ success: boolean; error?: string }>;
  registerWithApple: () => Promise<{ success: boolean; error?: string; needsAddress?: boolean }>;
  registerWithGoogle: () => Promise<{ success: boolean; error?: string; needsAddress?: boolean }>;
  completeSocialRegistration: (input: RegisterSocialInput) => Promise<{ success: boolean; error?: string }>;
  cancelSocialRegistration: () => Promise<void>;
  loginWithApple: () => Promise<{ success: boolean; error?: string }>;
  loginWithGoogle: () => Promise<{ success: boolean; error?: string }>;
  loginWithBiometric: () => Promise<{ success: boolean; error?: string }>;
  resetPassword: (email: string) => Promise<{ success: boolean; error?: string }>;
  logout: () => Promise<void>;
  selectHousehold: (household: Household) => void;
  refreshHouseholds: () => Promise<void>;
  refreshCurrentHousehold: () => Promise<void>;
  refreshMe: () => Promise<void>;
  refreshBiometricStatus: () => Promise<void>;
  completeOnboarding: (householdId: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const segments = useSegments();
  const [firebaseUser, setFirebaseUser] = useState<FirebaseUser | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [householdInfo, setHouseholdInfo] = useState<HouseholdInfo | null>(null);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [currentHousehold, setCurrentHousehold] = useState<HouseholdDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isInitialized, setIsInitialized] = useState(false);
  const [biometricStatus, setBiometricStatus] = useState<BiometricStatus | null>(null);
  const [isAppleSignInAvailable, setIsAppleSignInAvailable] = useState(false);
  const [pendingSocialAuth, setPendingSocialAuth] = useState<PendingSocialAuth | null>(null);

  const api = getApiClient();

  // Configure Google Sign In and check Apple availability on mount
  useEffect(() => {
    configureGoogleSignIn();
    isAppleAuthAvailable().then(setIsAppleSignInAvailable);
  }, []);

  // Refresh biometric status
  const refreshBiometricStatus = useCallback(async () => {
    const status = await getBiometricStatus();
    setBiometricStatus(status);
  }, []);

  // Check if user needs onboarding (no households)
  const needsOnboarding = !!user && !householdInfo;

  // Check if social auth user needs to complete registration
  const needsSocialRegistration = !!pendingSocialAuth;

  // Fetch user profile and household data from /api/me
  const fetchMe = useCallback(async (): Promise<MeResponse | null> => {
    try {
      // Get fresh Firebase token
      const token = await getIdToken(true);
      if (!token) return null;

      // Update API client with token
      await setFirebaseToken(token);

      // Call /api/me endpoint
      const response = await fetch(`${API_BASE_URL}/me`, {
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      });

      if (!response.ok) {
        console.error('Failed to fetch /api/me:', response.status);
        return null;
      }

      return response.json();
    } catch (error) {
      console.error('Error fetching /api/me:', error);
      return null;
    }
  }, []);

  // Load current household detail
  const loadCurrentHousehold = useCallback(
    async (householdList: Household[]) => {
      if (householdList.length === 0) {
        setCurrentHousehold(null);
        return;
      }

      const firstHousehold = householdList[0];
      if (!firstHousehold) return;
      const selectedId = firstHousehold.id;

      try {
        const detail = await api.getHousehold(selectedId);
        setCurrentHousehold(detail);
      } catch {
        setCurrentHousehold({ ...firstHousehold, members: [] });
      }
    },
    [api]
  );

  // Handle Firebase auth state changes
  useEffect(() => {
    const unsubscribe = onAuthChange(async (fbUser) => {
      setFirebaseUser(fbUser);

      if (fbUser) {
        // User is signed in - fetch profile from backend
        const meData = await fetchMe();

        if (meData) {
          // Map MeResponse to User type for backward compatibility
          setUser({
            id: meData.user.id,
            email: meData.user.email,
            firstName: meData.user.firstName || '',
            lastName: meData.user.lastName || '',
            phone: null,
            avatarUrl: meData.user.avatarUrl,
            role: meData.user.role as User['role'],
            isActive: true,
            createdAt: meData.user.createdAt,
            updatedAt: meData.user.createdAt,
          });

          setHouseholdInfo(meData.household);

          // Convert memberships to households for backward compatibility
          const householdList: Household[] = meData.memberships.map((m) => ({
            id: m.householdId,
            name: m.householdName,
            description: null,
            ownerId: '', // Not available from memberships
            createdAt: new Date(),
            updatedAt: new Date(),
          }));

          setHouseholds(householdList);
          await loadCurrentHousehold(householdList);
        } else {
          // API call failed - clear state
          setUser(null);
          setHouseholdInfo(null);
          setHouseholds([]);
          setCurrentHousehold(null);
        }
      } else {
        // User is signed out
        setUser(null);
        setHouseholdInfo(null);
        setHouseholds([]);
        setCurrentHousehold(null);
        await clearTokens();
      }

      setIsLoading(false);
      setIsInitialized(true);
    });

    return () => unsubscribe();
  }, [fetchMe, loadCurrentHousehold]);

  // Handle navigation based on auth state
  useEffect(() => {
    if (!isInitialized || isLoading) return;

    const inAuthGroup = segments[0] === '(auth)';
    const inOnboarding = segments[0] === '(onboarding)';

    // Case 1: No Firebase user at all - must go to login
    if (!firebaseUser && !inAuthGroup) {
      router.replace('/(auth)/login');
      return;
    }

    // Case 2: Firebase user exists but needs to complete registration (no household)
    // This covers both: user auto-created by API, or user record exists but no household
    if (firebaseUser && !householdInfo) {
      // Don't redirect if already in onboarding
      if (inOnboarding) return;

      // Check if this is a social auth user
      const providerData = firebaseUser.providerData || [];
      const socialProvider = providerData.find(
        (p: any) => p.providerId === 'apple.com' || p.providerId === 'google.com'
      );

      if (socialProvider) {
        // Social auth user needs to complete registration with address
        if (!pendingSocialAuth) {
          const displayName = firebaseUser.displayName || '';
          const nameParts = displayName.split(' ');
          setPendingSocialAuth({
            email: firebaseUser.email || '',
            firstName: nameParts[0] || '',
            lastName: nameParts.slice(1).join(' ') || '',
            provider: socialProvider.providerId === 'apple.com' ? 'apple' : 'google',
          });
        }
        router.replace('/(onboarding)/address');
        return;
      }

      // Email/password user without household - they need to register
      if (!inAuthGroup) {
        router.replace('/(auth)/register');
        return;
      }
    }

    // Case 3: User is fully set up (has Haven account + household) - go to main app
    // Don't redirect if user is on the completion page - let them see the success message
    const onCompletePage = inOnboarding && segments[1] === 'complete';
    if (user && householdInfo && (inAuthGroup || (inOnboarding && !onCompletePage))) {
      router.replace('/(tabs)');
    }
  }, [user, firebaseUser, householdInfo, pendingSocialAuth, segments, isLoading, isInitialized, router]);

  // Define refresh functions early so they can be used by registerSimple
  const refreshMe = useCallback(async () => {
    const meData = await fetchMe();
    if (meData) {
      setUser({
        id: meData.user.id,
        email: meData.user.email,
        firstName: meData.user.firstName || '',
        lastName: meData.user.lastName || '',
        phone: null,
        avatarUrl: meData.user.avatarUrl,
        role: meData.user.role as User['role'],
        isActive: true,
        createdAt: meData.user.createdAt,
        updatedAt: meData.user.createdAt,
      });
      setHouseholdInfo(meData.household);
    }
  }, [fetchMe]);

  const refreshHouseholds = useCallback(async () => {
    const meData = await fetchMe();
    if (meData) {
      setHouseholdInfo(meData.household);
      const householdList: Household[] = meData.memberships.map((m) => ({
        id: m.householdId,
        name: m.householdName,
        description: null,
        ownerId: '',
        createdAt: new Date(),
        updatedAt: new Date(),
      }));
      setHouseholds(householdList);
      await loadCurrentHousehold(householdList);
    }
  }, [fetchMe, loadCurrentHousehold]);

  const login = useCallback(async (email: string, password: string): Promise<{ success: boolean; error?: string }> => {
    try {
      await firebaseSignIn(email, password);

      // Store credentials for biometric login
      await SecureStore.setItemAsync(STORED_EMAIL_KEY, email);
      await SecureStore.setItemAsync(STORED_PASSWORD_KEY, password);

      return { success: true };
    } catch (error: any) {
      let errorMessage = 'Failed to sign in';

      // Handle Firebase not configured error
      if (error.message === 'Firebase is not configured') {
        errorMessage = 'App configuration error. Please restart the app.';
      } else {
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
      }

      return { success: false, error: errorMessage };
    }
  }, []);

  const register = useCallback(
    async (email: string, password: string, displayName?: string): Promise<{ success: boolean; error?: string }> => {
      try {
        await firebaseSignUp(email, password, displayName);

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
      }
    },
    []
  );

  // New Alfred-first simplified registration
  const registerSimple = useCallback(
    async (input: RegisterSimpleInput): Promise<{ success: boolean; error?: string }> => {
      try {
        // 1. Create Firebase auth user first
        const displayName = `${input.firstName} ${input.lastName}`;
        await firebaseSignUp(input.email, input.password, displayName);

        // 2. Get the Firebase token
        const token = await getIdToken(true);
        if (!token) {
          throw new Error('Failed to get authentication token');
        }

        // 3. Call our API to create user, household, and home profile
        const response = await fetch(`${API_BASE_URL}/auth/register-simple`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            email: input.email,
            password: input.password,
            firstName: input.firstName,
            lastName: input.lastName,
            address: input.address,
          }),
        });

        if (!response.ok) {
          const errorData = await response.json().catch(() => ({}));
          throw new Error(errorData.message || 'Failed to complete registration');
        }

        // 4. Store credentials for biometric login
        await SecureStore.setItemAsync(STORED_EMAIL_KEY, input.email);
        await SecureStore.setItemAsync(STORED_PASSWORD_KEY, input.password);

        // 5. Refresh user data to get household info
        await refreshMe();
        await refreshHouseholds();

        return { success: true };
      } catch (error: any) {
        console.error('Simple registration error:', error);

        let errorMessage = 'Failed to create account';

        if (error.code === 'auth/email-already-in-use') {
          errorMessage = 'An account with this email already exists';
        } else if (error.code === 'auth/weak-password') {
          errorMessage = 'Password must be at least 8 characters';
        } else if (error.message) {
          errorMessage = error.message;
        }

        return { success: false, error: errorMessage };
      }
    },
    [refreshMe, refreshHouseholds]
  );

  // Sign in with Apple
  const loginWithApple = useCallback(async (): Promise<{ success: boolean; error?: string }> => {
    try {
      const result = await signInWithApple();

      if (!result.success) {
        return { success: false, error: result.error };
      }

      return { success: true };
    } catch (error: any) {
      return { success: false, error: error.message || 'Apple Sign In failed' };
    }
  }, []);

  // Sign in with Google
  const loginWithGoogle = useCallback(async (): Promise<{ success: boolean; error?: string }> => {
    try {
      const result = await signInWithGoogle();

      if (!result.success) {
        return { success: false, error: result.error };
      }

      return { success: true };
    } catch (error: any) {
      return { success: false, error: error.message || 'Google Sign In failed' };
    }
  }, []);

  // Register with Apple (for new users)
  const registerWithApple = useCallback(async (): Promise<{ success: boolean; error?: string; needsAddress?: boolean }> => {
    try {
      const result = await signInWithApple();

      if (!result.success) {
        return { success: false, error: result.error };
      }

      // Check if user already exists in our database
      const meData = await fetchMe();

      if (meData && meData.household) {
        // User already has an account, they're logged in
        return { success: true };
      }

      // New user - need to collect address
      // Parse name from Apple (they may not provide it on subsequent sign-ins)
      let firstName = '';
      let lastName = '';
      if (result.user?.displayName) {
        const nameParts = result.user.displayName.split(' ');
        firstName = nameParts[0] || '';
        lastName = nameParts.slice(1).join(' ') || '';
      }

      setPendingSocialAuth({
        email: result.user?.email || '',
        firstName,
        lastName,
        provider: 'apple',
      });

      return { success: true, needsAddress: true };
    } catch (error: any) {
      return { success: false, error: error.message || 'Apple Sign In failed' };
    }
  }, [fetchMe]);

  // Register with Google (for new users)
  const registerWithGoogle = useCallback(async (): Promise<{ success: boolean; error?: string; needsAddress?: boolean }> => {
    try {
      const result = await signInWithGoogle();

      if (!result.success) {
        return { success: false, error: result.error };
      }

      // Check if user already exists in our database
      const meData = await fetchMe();

      if (meData && meData.household) {
        // User already has an account, they're logged in
        return { success: true };
      }

      // New user - need to collect address
      let firstName = '';
      let lastName = '';
      if (result.user?.displayName) {
        const nameParts = result.user.displayName.split(' ');
        firstName = nameParts[0] || '';
        lastName = nameParts.slice(1).join(' ') || '';
      }

      setPendingSocialAuth({
        email: result.user?.email || '',
        firstName,
        lastName,
        provider: 'google',
      });

      return { success: true, needsAddress: true };
    } catch (error: any) {
      return { success: false, error: error.message || 'Google Sign In failed' };
    }
  }, [fetchMe]);

  // Complete social registration by providing address
  const completeSocialRegistration = useCallback(async (input: RegisterSocialInput): Promise<{ success: boolean; error?: string }> => {
    if (!pendingSocialAuth) {
      return { success: false, error: 'No pending social authentication' };
    }

    try {
      // Get fresh Firebase token
      const token = await getIdToken(true);
      if (!token) {
        throw new Error('Failed to get authentication token');
      }

      // Call our API to create user, household, and home profile
      const response = await fetch(`${API_BASE_URL}/auth/register-social`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: input.email,
          firstName: input.firstName,
          lastName: input.lastName,
          address: input.address,
          propertyDetails: input.propertyDetails, // Include ATTOM data
        }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.message || 'Failed to complete registration');
      }

      // Clear pending state
      setPendingSocialAuth(null);

      // Refresh user data to get household info
      await refreshMe();
      await refreshHouseholds();

      return { success: true };
    } catch (error: any) {
      console.error('Social registration error:', error);
      return { success: false, error: error.message || 'Failed to create account' };
    }
  }, [pendingSocialAuth, refreshMe, refreshHouseholds]);

  // Cancel social registration
  const cancelSocialRegistration = useCallback(async () => {
    setPendingSocialAuth(null);
    await firebaseSignOut();
  }, []);

  // Sign in with biometrics
  const loginWithBiometric = useCallback(async (): Promise<{ success: boolean; error?: string }> => {
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
      return await login(email, password);
    } catch (error) {
      return {
        success: false,
        error: 'Failed to retrieve stored credentials',
      };
    }
  }, [login]);

  // Reset password
  const resetPassword = useCallback(async (email: string): Promise<{ success: boolean; error?: string }> => {
    try {
      await firebaseResetPassword(email);
      return { success: true };
    } catch (error: any) {
      let errorMessage = 'Failed to send reset email';
      if (error.code === 'auth/user-not-found') {
        errorMessage = 'No account found with this email';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = 'Invalid email address';
      } else if (error.message === 'Firebase is not configured') {
        errorMessage = 'Password reset is not available';
      }
      return { success: false, error: errorMessage };
    }
  }, []);

  const logout = useCallback(async () => {
    await firebaseSignOut();
    await clearTokens();
    setUser(null);
    setHouseholdInfo(null);
    setHouseholds([]);
    setCurrentHousehold(null);
    // Navigation is handled by the auth state navigation guard
    // Don't manually navigate here to avoid race conditions
  }, []);

  const selectHousehold = useCallback(
    async (household: Household) => {
      try {
        const detail = await api.getHousehold(household.id);
        setCurrentHousehold(detail);
      } catch {
        setCurrentHousehold({ ...household, members: [] });
      }
    },
    [api]
  );

  const refreshCurrentHousehold = useCallback(async () => {
    if (!currentHousehold) return;
    try {
      const detail = await api.getHousehold(currentHousehold.id);
      setCurrentHousehold(detail);
    } catch {
      // Ignore errors on refresh
    }
  }, [api, currentHousehold]);

  const completeOnboarding = useCallback(
    async (householdId: string) => {
      // Refresh data after onboarding - this updates householdInfo
      // The navigation guard will automatically redirect to /(tabs) when
      // needsOnboarding becomes false (i.e., when householdInfo is set)
      await refreshHouseholds();

      try {
        const detail = await api.getHousehold(householdId);
        setCurrentHousehold(detail);
      } catch {
        // Ignore errors
      }

      // Don't navigate explicitly - let the navigation guard handle it
      // This prevents race conditions with multiple navigation calls
    },
    [api, refreshHouseholds]
  );

  return (
    <AuthContext.Provider
      value={{
        user,
        firebaseUser,
        households,
        currentHousehold,
        householdInfo,
        isLoading,
        isAuthenticated: !!user,
        needsOnboarding,
        needsSocialRegistration,
        pendingSocialAuth,
        biometricStatus,
        isAppleSignInAvailable,
        login,
        register,
        registerSimple,
        registerWithApple,
        registerWithGoogle,
        completeSocialRegistration,
        cancelSocialRegistration,
        loginWithApple,
        loginWithGoogle,
        loginWithBiometric,
        resetPassword,
        logout,
        selectHousehold,
        refreshHouseholds,
        refreshCurrentHousehold,
        refreshMe,
        refreshBiometricStatus,
        completeOnboarding,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

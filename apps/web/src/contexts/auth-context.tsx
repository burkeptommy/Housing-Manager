'use client';

import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  type ReactNode,
} from 'react';
import { useRouter } from 'next/navigation';
import type { User, Household, HouseholdDetail } from '@haven/core';
import { getApiClient, setFirebaseToken, clearTokens } from '@/lib/api';
import {
  signIn as firebaseSignIn,
  signUp as firebaseSignUp,
  signOut as firebaseSignOut,
  signInWithGoogle as firebaseSignInWithGoogle,
  onAuthChange,
  getIdToken,
  type FirebaseUser,
} from '@/lib/firebase';

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

interface AuthContextValue {
  user: User | null;
  firebaseUser: FirebaseUser | null;
  households: Household[];
  currentHousehold: HouseholdDetail | null;
  householdInfo: HouseholdInfo | null;
  householdId: string | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  needsOnboarding: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, displayName?: string) => Promise<void>;
  signInWithGoogle: () => Promise<void>;
  logout: () => Promise<void>;
  selectHousehold: (household: Household) => void;
  refreshHouseholds: () => Promise<void>;
  refreshCurrentHousehold: () => Promise<void>;
  refreshMe: () => Promise<void>;
  completeOnboarding: (householdId: string) => Promise<void>;
  getIdToken: (forceRefresh?: boolean) => Promise<string | null>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const CURRENT_HOUSEHOLD_KEY = 'haven_current_household';

export function AuthProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [firebaseUser, setFirebaseUser] = useState<FirebaseUser | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [householdInfo, setHouseholdInfo] = useState<HouseholdInfo | null>(null);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [currentHousehold, setCurrentHousehold] = useState<HouseholdDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isInitialized, setIsInitialized] = useState(false);

  const api = getApiClient();

  // Check if user needs onboarding (only homeowners need households)
  // Staff, vendors, managers, and admins don't need household setup
  const needsOnboarding = !!user && user.role === 'HOMEOWNER' && !householdInfo;

  // Fetch user profile and household data from /api/me
  const fetchMe = useCallback(async (): Promise<MeResponse | null> => {
    try {
      // Get fresh Firebase token
      const token = await getIdToken(true);
      if (!token) return null;

      // Update API client with token
      setFirebaseToken(token);

      // Call /api/me endpoint
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'https://api.havenhome.dev/api'}/me`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

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

      const savedId = localStorage.getItem(CURRENT_HOUSEHOLD_KEY);
      const firstHousehold = householdList[0];
      if (!firstHousehold) return;
      let selectedId = firstHousehold.id;

      if (savedId) {
        const found = householdList.find((h) => h.id === savedId);
        if (found) {
          selectedId = found.id;
        }
      }

      localStorage.setItem(CURRENT_HOUSEHOLD_KEY, selectedId);

      try {
        const detail = await api.getHousehold(selectedId);
        setCurrentHousehold(detail);
      } catch {
        const basic = householdList.find((h) => h.id === selectedId);
        if (basic) {
          setCurrentHousehold({ ...basic, members: [] });
        }
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
          // API call failed - Firebase user exists but backend user doesn't
          // Sign out of Firebase to clear the stale session
          console.warn('Firebase user exists but backend user not found - signing out');
          await firebaseSignOut();
          setUser(null);
          setHouseholdInfo(null);
          setHouseholds([]);
          setCurrentHousehold(null);
          clearTokens();
        }
      } else {
        // User is signed out
        setUser(null);
        setHouseholdInfo(null);
        setHouseholds([]);
        setCurrentHousehold(null);
        clearTokens();
      }

      setIsLoading(false);
      setIsInitialized(true);
    });

    return () => unsubscribe();
  }, [fetchMe, loadCurrentHousehold]);

  const login = useCallback(
    async (email: string, password: string) => {
      // Set loading state before Firebase auth
      setIsLoading(true);

      const fbUser = await firebaseSignIn(email, password);

      // Get the token and set it immediately so API calls work
      if (fbUser) {
        const token = await fbUser.getIdToken();
        setFirebaseToken(token);
      }

      // Wait for the auth state callback to complete (sets user state, households, etc.)
      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => {
          reject(new Error('Login timeout - please try again'));
        }, 10000);

        // Poll until user state is set (onAuthChange sets this after fetchMe completes)
        const checkReady = setInterval(() => {
          // Check sessionStorage for the token as a signal that fetchMe completed
          const tokenSet = sessionStorage.getItem('haven_firebase_token');
          if (tokenSet) {
            clearInterval(checkReady);
            clearTimeout(timeout);
            resolve();
          }
        }, 50);
      });
    },
    []
  );

  const register = useCallback(
    async (email: string, password: string, displayName?: string) => {
      // Set loading state before Firebase auth
      setIsLoading(true);

      const fbUser = await firebaseSignUp(email, password, displayName);

      // Get the token and set it immediately so API calls work
      if (fbUser) {
        const token = await fbUser.getIdToken();
        setFirebaseToken(token);
      }

      // Wait for the auth state callback to complete
      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => {
          reject(new Error('Registration timeout - please try again'));
        }, 10000);

        const checkReady = setInterval(() => {
          const tokenSet = sessionStorage.getItem('haven_firebase_token');
          if (tokenSet) {
            clearInterval(checkReady);
            clearTimeout(timeout);
            resolve();
          }
        }, 50);
      });
    },
    []
  );

  const signInWithGoogle = useCallback(async () => {
    setIsLoading(true);

    try {
      const fbUser = await firebaseSignInWithGoogle();

      // Get the token and set it immediately so API calls work
      if (fbUser) {
        const token = await fbUser.getIdToken();
        setFirebaseToken(token);
      }

      // Wait for the auth state callback to complete
      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => {
          reject(new Error('Google sign-in timeout - please try again'));
        }, 10000);

        const checkReady = setInterval(() => {
          const tokenSet = sessionStorage.getItem('haven_firebase_token');
          if (tokenSet) {
            clearInterval(checkReady);
            clearTimeout(timeout);
            resolve();
          }
        }, 50);
      });
    } catch (error) {
      setIsLoading(false);
      throw error;
    }
  }, []);

  const logout = useCallback(async () => {
    await firebaseSignOut();
    clearTokens();
    setUser(null);
    setHouseholdInfo(null);
    setHouseholds([]);
    setCurrentHousehold(null);
    localStorage.removeItem(CURRENT_HOUSEHOLD_KEY);
    router.push('/login');
  }, [router]);

  const selectHousehold = useCallback(
    async (household: Household) => {
      localStorage.setItem(CURRENT_HOUSEHOLD_KEY, household.id);
      try {
        const detail = await api.getHousehold(household.id);
        setCurrentHousehold(detail);
      } catch {
        setCurrentHousehold({ ...household, members: [] });
      }
    },
    [api]
  );

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

  const refreshCurrentHousehold = useCallback(async () => {
    if (!currentHousehold) return;
    try {
      const detail = await api.getHousehold(currentHousehold.id);
      setCurrentHousehold(detail);
    } catch {
      // Ignore errors on refresh
    }
  }, [api, currentHousehold]);

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

  const completeOnboarding = useCallback(
    async (householdId: string) => {
      // Refresh data after onboarding
      await refreshHouseholds();
      localStorage.setItem(CURRENT_HOUSEHOLD_KEY, householdId);

      try {
        const detail = await api.getHousehold(householdId);
        setCurrentHousehold(detail);
      } catch {
        // Ignore errors
      }

      router.push('/app');
    },
    [api, router, refreshHouseholds]
  );

  // Handle routing based on auth state
  useEffect(() => {
    if (!isInitialized || isLoading) return;

    const path = window.location.pathname;

    // Allow public pages without any auth
    const publicPaths = ['/', '/login', '/register', '/forgot-password', '/terms', '/privacy'];
    const isPublicPath = publicPaths.some(p => path === p || path.startsWith('/pricing'));

    // Allow onboarding welcome page for unauthenticated users (registration)
    const isOnboardingWelcome = path.startsWith('/onboarding/welcome');

    if (!user) {
      // Not authenticated
      // Allow public paths and onboarding welcome (registration)
      if (!isPublicPath && !isOnboardingWelcome) {
        // Redirect protected pages to login
        if (path.startsWith('/app') || path.startsWith('/manager') || path.startsWith('/admin') || path.startsWith('/handyman') || path.startsWith('/vendor')) {
          router.push('/login');
        }
        // For other onboarding pages, redirect to welcome to register
        if (path.startsWith('/onboarding') && !isOnboardingWelcome) {
          router.push('/onboarding/welcome');
        }
      }
      return;
    }

    // User is authenticated from here on

    // Helper function to get the correct portal path for a user role
    const getPortalPath = (role: string): string => {
      switch (role) {
        case 'ADMIN':
          return '/admin';
        case 'MANAGER':
          return '/manager';
        case 'HANDYMAN':
          return '/handyman';
        case 'VENDOR':
          return '/vendor';
        case 'HOMEOWNER':
        default:
          return needsOnboarding ? '/onboarding/choose-path' : '/app';
      }
    };

    const userPortal = getPortalPath(user.role);

    // Redirect authenticated users away from login/register to their portal
    if (path === '/login' || path === '/register') {
      router.push(userPortal);
      return;
    }

    // If authenticated user is on welcome page, skip to choose-path
    if (isOnboardingWelcome) {
      router.push('/onboarding/choose-path');
      return;
    }

    // Allow users to stay in onboarding flow if they need it
    if (user.role === 'HOMEOWNER' && path.startsWith('/onboarding')) {
      // If user needs onboarding, let them continue
      if (needsOnboarding) {
        return; // Stay in onboarding
      }
      // If user doesn't need onboarding but is on complete page, let them finish
      if (path.startsWith('/onboarding/complete')) {
        return; // Stay on complete page
      }
      // Otherwise redirect to app
      router.push('/app');
      return;
    }

    // Handle role-based routing - ensure users are in their correct portal
    const isInWrongPortal = (
      (user.role === 'ADMIN' && !path.startsWith('/admin')) ||
      (user.role === 'MANAGER' && !path.startsWith('/manager')) ||
      (user.role === 'HANDYMAN' && !path.startsWith('/handyman')) ||
      (user.role === 'VENDOR' && !path.startsWith('/vendor')) ||
      (user.role === 'HOMEOWNER' && !path.startsWith('/app') && !path.startsWith('/onboarding'))
    );

    // Only redirect if user is trying to access a protected portal area that's not theirs
    if (isInWrongPortal && (
      path.startsWith('/app') ||
      path.startsWith('/admin') ||
      path.startsWith('/manager') ||
      path.startsWith('/handyman') ||
      path.startsWith('/vendor')
    )) {
      router.push(userPortal);
      return;
    }

    // Handle homeowners trying to access /app when they need onboarding
    if (user.role === 'HOMEOWNER' && needsOnboarding && path.startsWith('/app')) {
      router.push('/onboarding/choose-path');
    }
  }, [isInitialized, isLoading, user, needsOnboarding, router]);

  return (
    <AuthContext.Provider
      value={{
        user,
        firebaseUser,
        households,
        currentHousehold,
        householdInfo,
        householdId: currentHousehold?.id || householdInfo?.id || null,
        isLoading,
        isAuthenticated: !!user,
        needsOnboarding,
        login,
        register,
        signInWithGoogle,
        logout,
        selectHousehold,
        refreshHouseholds,
        refreshCurrentHousehold,
        refreshMe,
        completeOnboarding,
        getIdToken,
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

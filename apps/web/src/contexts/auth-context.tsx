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
  isLoading: boolean;
  isAuthenticated: boolean;
  needsOnboarding: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, displayName?: string) => Promise<void>;
  logout: () => Promise<void>;
  selectHousehold: (household: Household) => void;
  refreshHouseholds: () => Promise<void>;
  refreshCurrentHousehold: () => Promise<void>;
  refreshMe: () => Promise<void>;
  completeOnboarding: (householdId: string) => Promise<void>;
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

  // Check if user needs onboarding (no households)
  const needsOnboarding = !!user && !householdInfo;

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
        `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api'}/me`,
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
        clearTokens();
      }

      setIsLoading(false);
      setIsInitialized(true);
    });

    return () => unsubscribe();
  }, [fetchMe, loadCurrentHousehold]);

  const login = useCallback(
    async (email: string, password: string) => {
      await firebaseSignIn(email, password);
      // Auth state change listener will handle the rest
    },
    []
  );

  const register = useCallback(
    async (email: string, password: string, displayName?: string) => {
      await firebaseSignUp(email, password, displayName);
      // Auth state change listener will handle the rest
      // After registration, user will be redirected based on household status
    },
    []
  );

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

    if (!user) {
      // Not authenticated - only redirect if on protected pages
      if (path.startsWith('/app') || path.startsWith('/onboarding') || path.startsWith('/manager') || path.startsWith('/admin')) {
        router.push('/login');
      }
      return;
    }

    // User is authenticated - handle redirects
    if (path === '/login' || path === '/register') {
      // Redirect authenticated users away from login/register
      if (user.role === 'MANAGER' || user.role === 'ADMIN') {
        router.push('/manager');
      } else if (needsOnboarding) {
        router.push('/onboarding');
      } else {
        router.push('/app');
      }
      return;
    }

    // Handle role-based and onboarding routing for other pages
    if (path.startsWith('/app') || path.startsWith('/onboarding')) {
      if (user.role === 'MANAGER' || user.role === 'ADMIN') {
        router.push('/manager');
      } else if (needsOnboarding && !path.startsWith('/onboarding')) {
        router.push('/onboarding');
      } else if (!needsOnboarding && path.startsWith('/onboarding')) {
        router.push('/app');
      }
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
        isLoading,
        isAuthenticated: !!user,
        needsOnboarding,
        login,
        register,
        logout,
        selectHousehold,
        refreshHouseholds,
        refreshCurrentHousehold,
        refreshMe,
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

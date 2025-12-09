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
  type FirebaseUser,
} from '../lib/firebase';

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

    if (!user && !inAuthGroup) {
      router.replace('/(auth)/login');
    } else if (user && inAuthGroup) {
      if (needsOnboarding) {
        router.replace('/(auth)/onboarding');
      } else {
        router.replace('/(tabs)');
      }
    }
  }, [user, segments, isLoading, isInitialized, needsOnboarding, router]);

  const login = useCallback(async (email: string, password: string) => {
    await firebaseSignIn(email, password);
    // Auth state change listener will handle the rest
  }, []);

  const register = useCallback(
    async (email: string, password: string, displayName?: string) => {
      await firebaseSignUp(email, password, displayName);
      // Auth state change listener will handle the rest
    },
    []
  );

  const logout = useCallback(async () => {
    await firebaseSignOut();
    await clearTokens();
    setUser(null);
    setHouseholdInfo(null);
    setHouseholds([]);
    setCurrentHousehold(null);
    router.replace('/(auth)/login');
  }, [router]);

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

      try {
        const detail = await api.getHousehold(householdId);
        setCurrentHousehold(detail);
      } catch {
        // Ignore errors
      }

      // Navigate to main app
      router.replace('/(tabs)');
    },
    [api, router, refreshHouseholds]
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

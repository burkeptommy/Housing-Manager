import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  type ReactNode,
} from 'react';
import { useRouter, useSegments } from 'expo-router';
import type {
  User,
  Household,
  HouseholdDetail,
  RegisterRequest,
  LoginRequest,
} from '@haven/core';
import {
  getApiClient,
  setTokens,
  clearTokens,
  initializeTokens,
  setCachedTokens,
} from '../lib/api';

interface AuthContextValue {
  user: User | null;
  households: Household[];
  currentHousehold: HouseholdDetail | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  needsOnboarding: boolean;
  login: (data: LoginRequest) => Promise<void>;
  register: (data: RegisterRequest) => Promise<void>;
  logout: () => void;
  selectHousehold: (household: Household) => void;
  refreshHouseholds: () => Promise<void>;
  refreshCurrentHousehold: () => Promise<void>;
  completeOnboarding: (householdId: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const segments = useSegments();
  const [user, setUser] = useState<User | null>(null);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [currentHousehold, setCurrentHousehold] = useState<HouseholdDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const api = getApiClient();

  const needsOnboarding = !!user && households.length === 0;

  // Load household details
  const loadCurrentHousehold = useCallback(
    async (householdList: Household[]) => {
      if (householdList.length === 0) {
        setCurrentHousehold(null);
        return;
      }

      const selectedId = householdList[0].id;

      try {
        const detail = await api.getHousehold(selectedId);
        setCurrentHousehold(detail);
      } catch {
        const basic = householdList[0];
        setCurrentHousehold({ ...basic, members: [] });
      }
    },
    [api]
  );

  // Initialize auth state from stored tokens
  useEffect(() => {
    const initAuth = async () => {
      const hasTokens = await initializeTokens();
      if (!hasTokens) {
        setIsLoading(false);
        return;
      }

      try {
        const [userData, householdData] = await Promise.all([
          api.getMe(),
          api.getHouseholds(),
        ]);
        setUser(userData);
        setHouseholds(householdData);
        await loadCurrentHousehold(householdData);
      } catch {
        await clearTokens();
        setCachedTokens(null, null);
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, [api, loadCurrentHousehold]);

  // Handle navigation based on auth state
  useEffect(() => {
    if (isLoading) return;

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
  }, [user, segments, isLoading, needsOnboarding, router]);

  const login = useCallback(
    async (data: LoginRequest) => {
      const response = await api.login(data);
      await setTokens(response.accessToken, response.refreshToken);
      setCachedTokens(response.accessToken, response.refreshToken);
      setUser(response.user);

      const householdData = await api.getHouseholds();
      setHouseholds(householdData);

      if (householdData.length === 0) {
        router.replace('/(auth)/onboarding');
      } else {
        await loadCurrentHousehold(householdData);
        router.replace('/(tabs)');
      }
    },
    [api, router, loadCurrentHousehold]
  );

  const register = useCallback(
    async (data: RegisterRequest) => {
      const response = await api.register(data);
      await setTokens(response.accessToken, response.refreshToken);
      setCachedTokens(response.accessToken, response.refreshToken);
      setUser(response.user);
      setHouseholds([]);
      setCurrentHousehold(null);

      router.replace('/(auth)/onboarding');
    },
    [api, router]
  );

  const logout = useCallback(async () => {
    await clearTokens();
    setCachedTokens(null, null);
    setUser(null);
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
    const householdData = await api.getHouseholds();
    setHouseholds(householdData);
    await loadCurrentHousehold(householdData);
  }, [api, loadCurrentHousehold]);

  const refreshCurrentHousehold = useCallback(async () => {
    if (!currentHousehold) return;
    try {
      const detail = await api.getHousehold(currentHousehold.id);
      setCurrentHousehold(detail);
    } catch {
      // Ignore errors
    }
  }, [api, currentHousehold]);

  const completeOnboarding = useCallback(
    async (householdId: string) => {
      // Refresh households to include the newly created one
      const householdData = await api.getHouseholds();
      setHouseholds(householdData);

      // Load the household details
      const detail = await api.getHousehold(householdId);
      setCurrentHousehold(detail);

      // Navigate to main app
      router.replace('/(tabs)');
    },
    [api, router]
  );

  return (
    <AuthContext.Provider
      value={{
        user,
        households,
        currentHousehold,
        isLoading,
        isAuthenticated: !!user,
        needsOnboarding,
        login,
        register,
        logout,
        selectHousehold,
        refreshHouseholds,
        refreshCurrentHousehold,
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

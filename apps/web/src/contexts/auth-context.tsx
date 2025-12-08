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
import type {
  User,
  Household,
  HouseholdDetail,
  HomeProfile,
  RegisterRequest,
  LoginRequest,
} from '@haven/core';
import { getApiClient, setTokens, clearTokens, getAccessToken } from '@/lib/api';

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

const CURRENT_HOUSEHOLD_KEY = 'haven_current_household';

export function AuthProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [currentHousehold, setCurrentHousehold] = useState<HouseholdDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const api = getApiClient();

  // Check if user needs onboarding (no households)
  const needsOnboarding = !!user && households.length === 0;

  // Load current household from storage and fetch detail
  const loadCurrentHousehold = useCallback(
    async (householdList: Household[]) => {
      if (householdList.length === 0) {
        setCurrentHousehold(null);
        return;
      }

      const savedId = localStorage.getItem(CURRENT_HOUSEHOLD_KEY);
      let selectedId = householdList[0].id;

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
        // Fallback to basic household info
        const basic = householdList.find((h) => h.id === selectedId);
        if (basic) {
          setCurrentHousehold({ ...basic, members: [] });
        }
      }
    },
    [api]
  );

  // Initialize auth state
  useEffect(() => {
    const initAuth = async () => {
      const token = getAccessToken();
      if (!token) {
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
        clearTokens();
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, [api, loadCurrentHousehold]);

  const login = useCallback(
    async (data: LoginRequest) => {
      const response = await api.login(data);
      setTokens(response.accessToken, response.refreshToken);
      setUser(response.user);

      const householdData = await api.getHouseholds();
      setHouseholds(householdData);

      if (householdData.length === 0) {
        // New user or no households - go to onboarding
        router.push('/onboarding');
      } else {
        await loadCurrentHousehold(householdData);
        router.push('/app');
      }
    },
    [api, router, loadCurrentHousehold]
  );

  const register = useCallback(
    async (data: RegisterRequest) => {
      const response = await api.register(data);
      setTokens(response.accessToken, response.refreshToken);
      setUser(response.user);
      setHouseholds([]);
      setCurrentHousehold(null);

      // New registrations always go to onboarding
      router.push('/onboarding');
    },
    [api, router]
  );

  const logout = useCallback(() => {
    clearTokens();
    setUser(null);
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
      // Ignore errors on refresh
    }
  }, [api, currentHousehold]);

  const completeOnboarding = useCallback(
    async (householdId: string) => {
      const householdData = await api.getHouseholds();
      setHouseholds(householdData);
      localStorage.setItem(CURRENT_HOUSEHOLD_KEY, householdId);

      const detail = await api.getHousehold(householdId);
      setCurrentHousehold(detail);

      router.push('/app');
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

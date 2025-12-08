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
import type { User, Household, RegisterRequest, LoginRequest } from '@haven/core';
import { getApiClient, setTokens, clearTokens, getAccessToken } from '@/lib/api';

interface AuthContextValue {
  user: User | null;
  households: Household[];
  currentHousehold: Household | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (data: LoginRequest) => Promise<void>;
  register: (data: RegisterRequest) => Promise<void>;
  logout: () => void;
  selectHousehold: (household: Household) => void;
  refreshHouseholds: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const CURRENT_HOUSEHOLD_KEY = 'haven_current_household';

export function AuthProvider({ children }: { children: ReactNode }) {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [households, setHouseholds] = useState<Household[]>([]);
  const [currentHousehold, setCurrentHousehold] = useState<Household | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const api = getApiClient();

  // Load current household from storage
  const loadCurrentHousehold = useCallback((householdList: Household[]) => {
    const savedId = localStorage.getItem(CURRENT_HOUSEHOLD_KEY);
    if (savedId) {
      const found = householdList.find((h) => h.id === savedId);
      if (found) {
        setCurrentHousehold(found);
        return;
      }
    }
    // Default to first household
    if (householdList.length > 0) {
      setCurrentHousehold(householdList[0]);
      localStorage.setItem(CURRENT_HOUSEHOLD_KEY, householdList[0].id);
    }
  }, []);

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
        loadCurrentHousehold(householdData);
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
      loadCurrentHousehold(householdData);

      router.push('/app');
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

      router.push('/app');
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

  const selectHousehold = useCallback((household: Household) => {
    setCurrentHousehold(household);
    localStorage.setItem(CURRENT_HOUSEHOLD_KEY, household.id);
  }, []);

  const refreshHouseholds = useCallback(async () => {
    const householdData = await api.getHouseholds();
    setHouseholds(householdData);
    loadCurrentHousehold(householdData);
  }, [api, loadCurrentHousehold]);

  return (
    <AuthContext.Provider
      value={{
        user,
        households,
        currentHousehold,
        isLoading,
        isAuthenticated: !!user,
        login,
        register,
        logout,
        selectHousehold,
        refreshHouseholds,
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

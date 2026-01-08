# HAVEN COMPREHENSIVE FIX - MASTER PROMPT

**Run this entire prompt in Claude Code**

This prompt addresses ALL current issues:
1. iOS app crashes on launch (Version 19)
2. Onboarding infinite loop
3. Alfred AI not working
4. Demo data mismatch between mobile and web
5. iOS app doesn't match mobile web design
6. Redesign onboarding for Essentials-first ($39 tier)
7. Bill consolidation as major feature
8. Alfred butler (Batman's Alfred Pennyworth) branding

---

# PHASE 1: DIAGNOSTICS & CRASH FIXES

## Step 1.1: Full System Diagnostic

```bash
echo "=== HAVEN DIAGNOSTIC REPORT ==="
echo ""

# Check project structure
echo "--- Project Structure ---"
ls -la /Users/tomburke/Projects/Housing-Manager/

# Check mobile app structure
echo ""
echo "--- Mobile App Structure ---"
ls -la /Users/tomburke/Projects/Housing-Manager/apps/mobile/
ls -la /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/
ls -la /Users/tomburke/Projects/Housing-Manager/apps/mobile/app/\(tabs\)/ 2>/dev/null || echo "No (tabs) directory"
ls -la /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/contexts/ 2>/dev/null || echo "No contexts directory"

# Check web app onboarding
echo ""
echo "--- Web Onboarding Files ---"
find /Users/tomburke/Projects/Housing-Manager/apps/web -path "*onboarding*" -name "*.tsx" 2>/dev/null | head -20

# Check API structure
echo ""
echo "--- API Structure ---"
ls -la /Users/tomburke/Projects/Housing-Manager/apps/api/src/ 2>/dev/null | head -20
ls -la /Users/tomburke/Projects/Housing-Manager/apps/api/src/alfred/ 2>/dev/null || echo "No alfred directory"

# Check for TypeScript errors
echo ""
echo "--- TypeScript Errors (Mobile) ---"
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck 2>&1 | head -50

# Check for TypeScript errors (Web)
echo ""
echo "--- TypeScript Errors (Web) ---"
cd /Users/tomburke/Projects/Housing-Manager/apps/web
pnpm typecheck 2>&1 | head -50

# Check for TypeScript errors (API)
echo ""
echo "--- TypeScript Errors (API) ---"
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm typecheck 2>&1 | head -50

# Check mobile app.json for current build number
echo ""
echo "--- Current Build Number ---"
cat /Users/tomburke/Projects/Housing-Manager/apps/mobile/app.json | grep -A2 "buildNumber"

# Check if Alfred module exists and is registered
echo ""
echo "--- Alfred Module Status ---"
grep -rn "AlfredModule" /Users/tomburke/Projects/Housing-Manager/apps/api/src/app.module.ts 2>/dev/null || echo "AlfredModule not found in app.module.ts"

# Check Anthropic API key
echo ""
echo "--- Anthropic API Key Status ---"
grep -n "ANTHROPIC" /Users/tomburke/Projects/Housing-Manager/apps/api/.env 2>/dev/null || echo "No ANTHROPIC key found in .env"

# Check mobile API URL
echo ""
echo "--- Mobile API URL ---"
grep -rn "API_URL\|BASE_URL\|api.haven\|localhost:4000" /Users/tomburke/Projects/Housing-Manager/apps/mobile/src --include="*.ts" --include="*.tsx" 2>/dev/null | head -10

echo ""
echo "=== END DIAGNOSTIC ==="
```

## Step 1.2: Fix iOS App Crash - Clean and Rebuild

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Clear all caches
rm -rf node_modules/.cache
rm -rf .expo
rm -rf dist
watchman watch-del-all 2>/dev/null || true

# Reinstall dependencies
pnpm install

# Check expo doctor
npx expo-doctor 2>&1 || true
```

## Step 1.3: Create/Fix Missing Context Files

First, ensure the contexts directory exists:

```bash
mkdir -p /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/contexts
mkdir -p /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/lib
mkdir -p /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/theme
mkdir -p /Users/tomburke/Projects/Housing-Manager/apps/mobile/src/components
```

Create apps/mobile/src/contexts/subscription-context.tsx:

```typescript
import React, { createContext, useContext, useState, useEffect } from 'react';
import * as SecureStore from 'expo-secure-store';

type SubscriptionTier = 'essentials' | 'lite' | 'haven' | 'haven_plus' | 'estate';

interface SubscriptionContextType {
  tier: SubscriptionTier;
  isEssentials: boolean;
  hasHumanManager: boolean;
  managerName: string;
  loading: boolean;
  price: number;
}

const tierConfig: Record<SubscriptionTier, { price: number; hasHumanManager: boolean; managerName: string }> = {
  essentials: { price: 39, hasHumanManager: false, managerName: 'Alfred' },
  lite: { price: 349, hasHumanManager: true, managerName: 'Sarah Chen' },
  haven: { price: 749, hasHumanManager: true, managerName: 'Sarah Chen' },
  haven_plus: { price: 1499, hasHumanManager: true, managerName: 'Sarah Chen' },
  estate: { price: 3499, hasHumanManager: true, managerName: 'Sarah Chen' },
};

const SubscriptionContext = createContext<SubscriptionContextType>({
  tier: 'essentials',
  isEssentials: true,
  hasHumanManager: false,
  managerName: 'Alfred',
  loading: false,
  price: 39,
});

export function SubscriptionProvider({ children }: { children: React.ReactNode }) {
  const [tier, setTier] = useState<SubscriptionTier>('essentials');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadSubscription = async () => {
      try {
        // Try to get from secure storage first
        const savedTier = await SecureStore.getItemAsync('subscriptionTier');
        if (savedTier && tierConfig[savedTier as SubscriptionTier]) {
          setTier(savedTier as SubscriptionTier);
        }
        
        // TODO: Fetch from API to get actual subscription
        // const token = await SecureStore.getItemAsync('authToken');
        // if (token) {
        //   const response = await fetch(`${API_URL}/subscription/current`, {
        //     headers: { Authorization: `Bearer ${token}` },
        //   });
        //   const data = await response.json();
        //   setTier(data.tier);
        // }
      } catch (error) {
        console.log('Failed to load subscription, using default:', error);
      } finally {
        setLoading(false);
      }
    };

    loadSubscription();
  }, []);

  const config = tierConfig[tier];
  const value: SubscriptionContextType = {
    tier,
    isEssentials: tier === 'essentials',
    hasHumanManager: config.hasHumanManager,
    managerName: config.managerName,
    loading,
    price: config.price,
  };

  return (
    <SubscriptionContext.Provider value={value}>
      {children}
    </SubscriptionContext.Provider>
  );
}

export function useSubscription() {
  const context = useContext(SubscriptionContext);
  if (!context) {
    // Return safe defaults if used outside provider
    return {
      tier: 'essentials' as SubscriptionTier,
      isEssentials: true,
      hasHumanManager: false,
      managerName: 'Alfred',
      loading: false,
      price: 39,
    };
  }
  return context;
}
```

Create apps/mobile/src/contexts/auth-context.tsx (if missing or broken):

```typescript
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import * as SecureStore from 'expo-secure-store';
import { useRouter, useSegments } from 'expo-router';

interface User {
  id: string;
  email: string;
  firstName?: string;
  lastName?: string;
  householdId?: string;
  onboardingCompleted?: boolean;
}

interface AuthContextType {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  updateUser: (user: Partial<User>) => void;
}

const AuthContext = createContext<AuthContextType | null>(null);

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.havenhome.dev';

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();
  const segments = useSegments();

  // Load saved auth state on mount
  useEffect(() => {
    const loadAuthState = async () => {
      try {
        const savedToken = await SecureStore.getItemAsync('authToken');
        const savedUser = await SecureStore.getItemAsync('user');
        
        if (savedToken && savedUser) {
          setToken(savedToken);
          setUser(JSON.parse(savedUser));
        }
      } catch (error) {
        console.error('Failed to load auth state:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadAuthState();
  }, []);

  // Handle navigation based on auth state
  useEffect(() => {
    if (isLoading) return;

    const inAuthGroup = segments[0] === '(auth)';
    const inOnboarding = segments[0] === 'onboarding';

    if (!user && !inAuthGroup) {
      // Not signed in, redirect to sign in
      router.replace('/(auth)/login');
    } else if (user && inAuthGroup) {
      // Signed in but on auth screen
      if (user.onboardingCompleted === false || !user.householdId) {
        router.replace('/onboarding');
      } else {
        router.replace('/(tabs)');
      }
    }
  }, [user, isLoading, segments]);

  const signIn = async (email: string, password: string) => {
    try {
      const response = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message || 'Login failed');
      }

      const data = await response.json();
      
      await SecureStore.setItemAsync('authToken', data.accessToken);
      await SecureStore.setItemAsync('user', JSON.stringify(data.user));
      
      setToken(data.accessToken);
      setUser(data.user);
    } catch (error) {
      console.error('Sign in error:', error);
      throw error;
    }
  };

  const signOut = async () => {
    try {
      await SecureStore.deleteItemAsync('authToken');
      await SecureStore.deleteItemAsync('user');
      setToken(null);
      setUser(null);
      router.replace('/(auth)/login');
    } catch (error) {
      console.error('Sign out error:', error);
    }
  };

  const updateUser = (updates: Partial<User>) => {
    if (user) {
      const updatedUser = { ...user, ...updates };
      setUser(updatedUser);
      SecureStore.setItemAsync('user', JSON.stringify(updatedUser));
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isLoading,
        isAuthenticated: !!user,
        signIn,
        signOut,
        updateUser,
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
```

## Step 1.4: Create API Client

Create apps/mobile/src/lib/api.ts:

```typescript
import * as SecureStore from 'expo-secure-store';

const API_URL = process.env.EXPO_PUBLIC_API_URL || 'https://api.havenhome.dev';

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private async getToken(): Promise<string | null> {
    try {
      return await SecureStore.getItemAsync('authToken');
    } catch {
      return null;
    }
  }

  async get<T>(endpoint: string): Promise<T> {
    const token = await this.getToken();
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'Request failed' }));
      throw new Error(error.message || `API error: ${response.status}`);
    }

    return response.json();
  }

  async post<T>(endpoint: string, data?: any): Promise<T> {
    const token = await this.getToken();
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: data ? JSON.stringify(data) : undefined,
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'Request failed' }));
      throw new Error(error.message || `API error: ${response.status}`);
    }

    return response.json();
  }

  async put<T>(endpoint: string, data: any): Promise<T> {
    const token = await this.getToken();
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'Request failed' }));
      throw new Error(error.message || `API error: ${response.status}`);
    }

    return response.json();
  }

  async delete<T>(endpoint: string): Promise<T> {
    const token = await this.getToken();
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
    });

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'Request failed' }));
      throw new Error(error.message || `API error: ${response.status}`);
    }

    return response.json();
  }
}

export const api = new ApiClient(API_URL);
export { API_URL };
```

## Step 1.5: Create Theme Files (Matching Mobile Web)

Create apps/mobile/src/theme/colors.ts:

```typescript
export const colors = {
  // Primary - Navy
  navy: {
    950: '#0a1929',
    900: '#102a43',
    800: '#243b53',
    700: '#334e68',
    600: '#486581',
    500: '#627d98',
    400: '#829ab1',
    300: '#9fb3c8',
    200: '#bcccdc',
    100: '#d9e2ec',
    50: '#f0f4f8',
  },
  // Accent - Champagne
  champagne: {
    600: '#a68a5b',
    500: '#c4a574',
    400: '#d4c4a5',
    300: '#e9dcc4',
    200: '#f5efe6',
    100: '#faf6ed',
    50: '#fdfcfa',
  },
  // Neutrals - Gray
  gray: {
    950: '#0f172a',
    900: '#1e293b',
    800: '#334155',
    700: '#475569',
    600: '#64748b',
    500: '#94a3b8',
    400: '#cbd5e1',
    300: '#e2e8f0',
    200: '#f1f5f9',
    100: '#f8fafc',
    50: '#fafafa',
  },
  // Base
  white: '#ffffff',
  black: '#000000',
  // Status
  success: {
    500: '#10b981',
    100: '#d1fae5',
  },
  warning: {
    500: '#f59e0b',
    100: '#fef3c7',
  },
  error: {
    500: '#ef4444',
    100: '#fee2e2',
  },
  info: {
    500: '#3b82f6',
    100: '#dbeafe',
  },
};
```

Create apps/mobile/src/theme/spacing.ts:

```typescript
export const spacing = {
  0: 0,
  0.5: 2,
  1: 4,
  1.5: 6,
  2: 8,
  2.5: 10,
  3: 12,
  3.5: 14,
  4: 16,
  5: 20,
  6: 24,
  7: 28,
  8: 32,
  9: 36,
  10: 40,
  11: 44,
  12: 48,
  14: 56,
  16: 64,
  20: 80,
  24: 96,
  28: 112,
  32: 128,
};

export const borderRadius = {
  none: 0,
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  '2xl': 20,
  '3xl': 24,
  full: 9999,
};
```

Create apps/mobile/src/theme/typography.ts:

```typescript
import { Platform } from 'react-native';

const fontFamily = Platform.select({
  ios: 'System',
  android: 'Roboto',
  default: 'System',
});

export const typography = {
  // Display
  displayLarge: {
    fontFamily,
    fontSize: 32,
    fontWeight: '700' as const,
    lineHeight: 40,
    letterSpacing: -0.5,
  },
  displayMedium: {
    fontFamily,
    fontSize: 28,
    fontWeight: '700' as const,
    lineHeight: 36,
    letterSpacing: -0.25,
  },
  // Headings
  h1: {
    fontFamily,
    fontSize: 24,
    fontWeight: '700' as const,
    lineHeight: 32,
  },
  h2: {
    fontFamily,
    fontSize: 20,
    fontWeight: '600' as const,
    lineHeight: 28,
  },
  h3: {
    fontFamily,
    fontSize: 18,
    fontWeight: '600' as const,
    lineHeight: 24,
  },
  h4: {
    fontFamily,
    fontSize: 16,
    fontWeight: '600' as const,
    lineHeight: 22,
  },
  // Body
  bodyLarge: {
    fontFamily,
    fontSize: 16,
    fontWeight: '400' as const,
    lineHeight: 24,
  },
  body: {
    fontFamily,
    fontSize: 15,
    fontWeight: '400' as const,
    lineHeight: 22,
  },
  bodySmall: {
    fontFamily,
    fontSize: 14,
    fontWeight: '400' as const,
    lineHeight: 20,
  },
  // Caption
  caption: {
    fontFamily,
    fontSize: 12,
    fontWeight: '500' as const,
    lineHeight: 16,
  },
  captionSmall: {
    fontFamily,
    fontSize: 11,
    fontWeight: '500' as const,
    lineHeight: 14,
  },
  // Label
  label: {
    fontFamily,
    fontSize: 13,
    fontWeight: '600' as const,
    lineHeight: 18,
    letterSpacing: 0.5,
  },
  // Button
  button: {
    fontFamily,
    fontSize: 15,
    fontWeight: '600' as const,
    lineHeight: 20,
  },
  buttonSmall: {
    fontFamily,
    fontSize: 13,
    fontWeight: '600' as const,
    lineHeight: 18,
  },
};
```

Create apps/mobile/src/theme/shadows.ts:

```typescript
import { Platform } from 'react-native';

export const shadows = {
  none: {
    shadowColor: 'transparent',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0,
    shadowRadius: 0,
    elevation: 0,
  },
  xs: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 1,
    elevation: 1,
  },
  sm: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
    elevation: 2,
  },
  md: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 3,
  },
  lg: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    elevation: 4,
  },
  xl: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.12,
    shadowRadius: 16,
    elevation: 6,
  },
};

// Card shadow - commonly used
export const cardShadow = Platform.select({
  ios: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
  },
  android: {
    elevation: 3,
  },
  default: {},
});
```

Create apps/mobile/src/theme/index.ts:

```typescript
export * from './colors';
export * from './spacing';
export * from './typography';
export * from './shadows';
```

---

# PHASE 2: FIX ROOT LAYOUT AND TAB NAVIGATION

## Step 2.1: Fix Root Layout

Replace apps/mobile/app/_layout.tsx:

```typescript
import { useEffect, useState } from 'react';
import { Stack, SplashScreen } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { View, ActivityIndicator, StyleSheet, LogBox } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { AuthProvider } from '../src/contexts/auth-context';
import { SubscriptionProvider } from '../src/contexts/subscription-context';
import { colors } from '../src/theme';

// Prevent splash screen from auto-hiding
SplashScreen.preventAutoHideAsync();

// Ignore specific warnings in development
LogBox.ignoreLogs([
  'ViewPropTypes will be removed',
  'ColorPropType will be removed',
]);

export default function RootLayout() {
  const [appIsReady, setAppIsReady] = useState(false);

  useEffect(() => {
    async function prepare() {
      try {
        // Pre-load any resources here if needed
        // await Font.loadAsync({ ... });
        
        // Artificial delay to show splash screen (remove in production)
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (e) {
        console.warn('Error loading app:', e);
      } finally {
        setAppIsReady(true);
        SplashScreen.hideAsync();
      }
    }

    prepare();
  }, []);

  if (!appIsReady) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.navy[900]} />
      </View>
    );
  }

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <AuthProvider>
        <SubscriptionProvider>
          <StatusBar style="auto" />
          <Stack
            screenOptions={{
              headerShown: false,
              animation: 'slide_from_right',
            }}
          >
            <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
            <Stack.Screen name="(auth)" options={{ headerShown: false }} />
            <Stack.Screen 
              name="onboarding" 
              options={{ 
                headerShown: false,
                gestureEnabled: false,
              }} 
            />
          </Stack>
        </SubscriptionProvider>
      </AuthProvider>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.gray[50],
  },
});
```

## Step 2.2: Fix Tab Layout - EXACTLY 5 Tabs

Replace apps/mobile/app/(tabs)/_layout.tsx:

```typescript
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { Platform, View, StyleSheet } from 'react-native';
import { useSubscription } from '../../src/contexts/subscription-context';
import { colors } from '../../src/theme';

export default function TabLayout() {
  const { isEssentials, managerName } = useSubscription();

  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: colors.navy[900],
        tabBarInactiveTintColor: colors.gray[500],
        headerShown: true,
        headerStyle: {
          backgroundColor: colors.white,
          shadowColor: 'transparent',
          elevation: 0,
          borderBottomWidth: 1,
          borderBottomColor: colors.gray[200],
        },
        headerTitleStyle: {
          color: colors.navy[900],
          fontWeight: '600',
          fontSize: 17,
        },
        tabBarStyle: {
          backgroundColor: colors.white,
          borderTopWidth: 1,
          borderTopColor: colors.gray[200],
          paddingTop: 8,
          paddingBottom: Platform.OS === 'ios' ? 28 : 12,
          height: Platform.OS === 'ios' ? 88 : 68,
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '500',
          marginTop: 2,
        },
      }}
    >
      {/* Tab 1: Home/Dashboard */}
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          headerTitle: 'Dashboard',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon name={focused ? 'home' : 'home-outline'} color={color} />
          ),
        }}
      />

      {/* Tab 2: Manager (Alfred for Essentials, Sarah for Premium) */}
      <Tabs.Screen
        name="manager"
        options={{
          title: isEssentials ? 'Alfred' : 'Sarah',
          headerTitle: isEssentials ? 'Your AI Home Manager' : 'Your Home Manager',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon 
              name={isEssentials 
                ? (focused ? 'sparkles' : 'sparkles-outline')
                : (focused ? 'person-circle' : 'person-circle-outline')
              } 
              color={color} 
            />
          ),
        }}
      />

      {/* Tab 3: Messages */}
      <Tabs.Screen
        name="messages"
        options={{
          title: 'Messages',
          headerTitle: 'Messages',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon name={focused ? 'chatbubbles' : 'chatbubbles-outline'} color={color} />
          ),
        }}
      />

      {/* Tab 4: Money */}
      <Tabs.Screen
        name="wallet"
        options={{
          title: 'Money',
          headerTitle: 'Financial',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon name={focused ? 'wallet' : 'wallet-outline'} color={color} />
          ),
        }}
      />

      {/* Tab 5: More */}
      <Tabs.Screen
        name="more"
        options={{
          title: 'More',
          headerTitle: 'More',
          tabBarIcon: ({ color, focused }) => (
            <TabBarIcon name={focused ? 'menu' : 'menu-outline'} color={color} />
          ),
        }}
      />

      {/* Hidden Screens - accessed via navigation, NOT as tabs */}
      <Tabs.Screen name="maintenance" options={{ href: null }} />
      <Tabs.Screen name="vault" options={{ href: null }} />
      <Tabs.Screen name="family" options={{ href: null }} />
      <Tabs.Screen name="approvals" options={{ href: null }} />
      <Tabs.Screen name="profile" options={{ href: null }} />
      <Tabs.Screen name="settings" options={{ href: null }} />
      <Tabs.Screen name="billing" options={{ href: null }} />
      <Tabs.Screen name="home" options={{ href: null }} />
      <Tabs.Screen name="vendors" options={{ href: null }} />
      <Tabs.Screen name="tasks" options={{ href: null }} />
      <Tabs.Screen name="calendar" options={{ href: null }} />
    </Tabs>
  );
}

function TabBarIcon({ name, color }: { name: string; color: string }) {
  return <Ionicons name={name as any} size={24} color={color} />;
}
```

---

# PHASE 3: REPLICATE MOBILE WEB EXPERIENCE TO iOS

## Step 3.1: Analyze and Copy Mobile Web Design

The mobile web at havenhome.dev looks great. We need the iOS app to look IDENTICAL.

First, examine the mobile web dashboard:

```bash
# Find and examine the web dashboard
cat /Users/tomburke/Projects/Housing-Manager/apps/web/src/app/app/page.tsx | head -300
```

## Step 3.2: Create iOS Dashboard Matching Mobile Web EXACTLY

Replace apps/mobile/app/(tabs)/index.tsx with a design that matches mobile web:

```typescript
import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  RefreshControl,
  TouchableOpacity,
  ActivityIndicator,
  SafeAreaView,
  Platform,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useAuth } from '../../src/contexts/auth-context';
import { api } from '../../src/lib/api';
import { colors, spacing, typography, shadows } from '../../src/theme';

interface DashboardData {
  homeHealth: {
    score: number;
    grade: string;
  };
  billsSummary: {
    totalDue: number;
    billsPaid: number;
    nextDueDate: string;
  };
  upcomingMaintenance: Array<{
    id: string;
    title: string;
    dueDate: string;
    category: string;
  }>;
  todaysNotes: Array<{
    id: string;
    icon: string;
    text: string;
  }>;
  family: Array<{
    id: string;
    name: string;
    type: string;
  }>;
}

export default function DashboardScreen() {
  const router = useRouter();
  const { user } = useAuth();
  const [data, setData] = useState<DashboardData | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const firstName = user?.firstName || 'there';
  const currentHour = new Date().getHours();
  const greeting = currentHour < 12 ? 'Good morning' : currentHour < 18 ? 'Good afternoon' : 'Good evening';
  
  // Format current date
  const today = new Date();
  const dateString = today.toLocaleDateString('en-US', {
    weekday: 'long',
    month: 'long',
    day: 'numeric',
  });

  const fetchData = useCallback(async () => {
    try {
      // Fetch dashboard data from API
      const dashboardData = await api.get<DashboardData>('/dashboard').catch(() => null);
      
      if (dashboardData) {
        setData(dashboardData);
      } else {
        // Use demo data if API fails
        setData({
          homeHealth: { score: 94, grade: 'Excellent' },
          billsSummary: { totalDue: 22771, billsPaid: 13, nextDueDate: 'Jan 15' },
          upcomingMaintenance: [
            { id: '1', title: 'HVAC Filter Change', dueDate: 'Jan 15', category: 'HVAC' },
            { id: '2', title: 'Gutter Cleaning', dueDate: 'Feb 1', category: 'Exterior' },
          ],
          todaysNotes: [
            { id: '1', icon: 'trash', text: "Trash day tomorrow - bins out?" },
            { id: '2', icon: 'cube', text: "Amazon delivery expected 2-5pm" },
            { id: '3', icon: 'calendar', text: "Emma's soccer practice 4pm" },
          ],
          family: [
            { id: '1', name: 'Emma', type: 'Child' },
            { id: '2', name: 'Jack', type: 'Child' },
            { id: '3', name: 'Maria', type: 'Staff' },
            { id: '4', name: 'Max', type: 'Golden Retriever' },
          ],
        });
      }
    } catch (error) {
      console.error('Failed to fetch dashboard:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const onRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  };

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.navy[900]} />
      </View>
    );
  }

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={colors.navy[900]}
          />
        }
      >
        {/* Hero Header - Matching Mobile Web */}
        <LinearGradient
          colors={[colors.navy[900], colors.navy[800]]}
          style={styles.heroHeader}
        >
          <View style={styles.heroContent}>
            <View style={styles.dateWeatherRow}>
              <Text style={styles.dateText}>{dateString}</Text>
              <View style={styles.weatherBadge}>
                <Ionicons name="sunny" size={14} color={colors.champagne[400]} />
                <Text style={styles.weatherText}>68°</Text>
              </View>
            </View>
            
            <Text style={styles.greeting}>{greeting}, {firstName}</Text>
            <Text style={styles.subtitle}>Your home is in great shape.</Text>
            
            {/* Stats Row */}
            <View style={styles.statsRow}>
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Home Health</Text>
                <View style={styles.statValueRow}>
                  <Text style={styles.statValue}>{data?.homeHealth.score || 94}%</Text>
                  <View style={styles.gradeBadge}>
                    <Text style={styles.gradeText}>{data?.homeHealth.grade || 'Excellent'}</Text>
                  </View>
                </View>
              </View>
              <View style={styles.statDivider} />
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Bills Paid</Text>
                <Text style={styles.statValue}>{data?.billsSummary.billsPaid || 0}</Text>
              </View>
              <View style={styles.statDivider} />
              <View style={styles.statItem}>
                <Text style={styles.statLabel}>Next Service</Text>
                <Text style={styles.statValue}>—</Text>
              </View>
            </View>
          </View>
        </LinearGradient>

        {/* Today's Notes Card */}
        <View style={styles.section}>
          <View style={styles.card}>
            <View style={styles.cardHeader}>
              <Text style={styles.cardTitle}>Today's Notes</Text>
              <View style={styles.countBadge}>
                <Text style={styles.countText}>{data?.todaysNotes.length || 0}</Text>
              </View>
            </View>
            
            {data?.todaysNotes.map((note, index) => (
              <View 
                key={note.id} 
                style={[
                  styles.noteItem,
                  index < (data?.todaysNotes.length || 0) - 1 && styles.noteItemBorder
                ]}
              >
                <View style={styles.noteIconContainer}>
                  <Ionicons 
                    name={note.icon as any} 
                    size={18} 
                    color={colors.champagne[500]} 
                  />
                </View>
                <Text style={styles.noteText}>{note.text}</Text>
              </View>
            ))}
          </View>
        </View>

        {/* Family Section */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Family</Text>
            <TouchableOpacity onPress={() => router.push('/family')}>
              <Text style={styles.seeAllLink}>See all</Text>
            </TouchableOpacity>
          </View>
          
          <ScrollView 
            horizontal 
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.familyScroll}
          >
            {data?.family.map((member) => (
              <TouchableOpacity key={member.id} style={styles.familyItem}>
                <View style={styles.familyAvatar}>
                  <Ionicons 
                    name={member.type === 'Golden Retriever' ? 'paw' : 'person'} 
                    size={24} 
                    color={colors.gray[400]} 
                  />
                </View>
                <Text style={styles.familyName}>{member.name}</Text>
                <Text style={styles.familyType}>{member.type}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>

        {/* Quick Actions */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Quick Actions</Text>
          <View style={styles.quickActionsGrid}>
            <TouchableOpacity 
              style={styles.quickAction}
              onPress={() => router.push('/maintenance')}
            >
              <View style={[styles.quickActionIcon, { backgroundColor: colors.champagne[100] }]}>
                <Ionicons name="construct" size={22} color={colors.champagne[600]} />
              </View>
              <Text style={styles.quickActionText}>Maintenance</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.quickAction}
              onPress={() => router.push('/vault')}
            >
              <View style={[styles.quickActionIcon, { backgroundColor: colors.navy[100] }]}>
                <Ionicons name="document-text" size={22} color={colors.navy[700]} />
              </View>
              <Text style={styles.quickActionText}>Documents</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.quickAction}
              onPress={() => router.push('/vendors')}
            >
              <View style={[styles.quickActionIcon, { backgroundColor: colors.success[100] }]}>
                <Ionicons name="people" size={22} color={colors.success[500]} />
              </View>
              <Text style={styles.quickActionText}>Find Pros</Text>
            </TouchableOpacity>
            
            <TouchableOpacity 
              style={styles.quickAction}
              onPress={() => router.push('/manager')}
            >
              <View style={[styles.quickActionIcon, { backgroundColor: colors.champagne[100] }]}>
                <Ionicons name="chatbubble-ellipses" size={22} color={colors.champagne[600]} />
              </View>
              <Text style={styles.quickActionText}>Ask Alfred</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Upcoming Maintenance */}
        {data?.upcomingMaintenance && data.upcomingMaintenance.length > 0 && (
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <Text style={styles.sectionTitle}>Upcoming Maintenance</Text>
              <TouchableOpacity onPress={() => router.push('/maintenance')}>
                <Text style={styles.seeAllLink}>See all</Text>
              </TouchableOpacity>
            </View>
            
            <View style={styles.card}>
              {data.upcomingMaintenance.map((task, index) => (
                <TouchableOpacity 
                  key={task.id}
                  style={[
                    styles.maintenanceItem,
                    index < data.upcomingMaintenance.length - 1 && styles.maintenanceItemBorder
                  ]}
                >
                  <View style={styles.maintenanceIconContainer}>
                    <Ionicons name="construct-outline" size={18} color={colors.navy[600]} />
                  </View>
                  <View style={styles.maintenanceContent}>
                    <Text style={styles.maintenanceTitle}>{task.title}</Text>
                    <Text style={styles.maintenanceDate}>Due {task.dueDate}</Text>
                  </View>
                  <Ionicons name="chevron-forward" size={20} color={colors.gray[400]} />
                </TouchableOpacity>
              ))}
            </View>
          </View>
        )}

        <View style={styles.bottomSpacer} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.gray[100],
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.gray[100],
  },
  scrollView: {
    flex: 1,
  },
  scrollContent: {
    paddingBottom: spacing[6],
  },
  
  // Hero Header
  heroHeader: {
    paddingTop: spacing[4],
    paddingBottom: spacing[6],
    paddingHorizontal: spacing[4],
    borderBottomLeftRadius: 24,
    borderBottomRightRadius: 24,
  },
  heroContent: {
    gap: spacing[2],
  },
  dateWeatherRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  dateText: {
    ...typography.bodySmall,
    color: colors.gray[300],
  },
  weatherBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[1],
    backgroundColor: 'rgba(255,255,255,0.1)',
    paddingHorizontal: spacing[2],
    paddingVertical: spacing[1],
    borderRadius: 12,
  },
  weatherText: {
    ...typography.bodySmall,
    color: colors.white,
    fontWeight: '500',
  },
  greeting: {
    ...typography.displayMedium,
    color: colors.white,
    marginTop: spacing[1],
  },
  subtitle: {
    ...typography.body,
    color: colors.gray[300],
  },
  
  // Stats Row
  statsRow: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255,255,255,0.08)',
    borderRadius: 16,
    marginTop: spacing[4],
    padding: spacing[4],
  },
  statItem: {
    flex: 1,
    alignItems: 'flex-start',
  },
  statLabel: {
    ...typography.caption,
    color: colors.gray[400],
    marginBottom: spacing[1],
  },
  statValueRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
  },
  statValue: {
    ...typography.h2,
    color: colors.champagne[400],
  },
  gradeBadge: {
    backgroundColor: colors.success[500],
    paddingHorizontal: spacing[2],
    paddingVertical: spacing[0.5],
    borderRadius: 6,
  },
  gradeText: {
    ...typography.captionSmall,
    color: colors.white,
    fontWeight: '600',
  },
  statDivider: {
    width: 1,
    backgroundColor: 'rgba(255,255,255,0.15)',
    marginHorizontal: spacing[3],
  },
  
  // Sections
  section: {
    marginTop: spacing[5],
    paddingHorizontal: spacing[4],
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionTitle: {
    ...typography.h3,
    color: colors.navy[900],
  },
  seeAllLink: {
    ...typography.bodySmall,
    color: colors.champagne[500],
    fontWeight: '600',
  },
  
  // Cards
  card: {
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: spacing[4],
    ...shadows.md,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  cardTitle: {
    ...typography.h4,
    color: colors.navy[900],
  },
  countBadge: {
    backgroundColor: colors.navy[100],
    width: 24,
    height: 24,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
  },
  countText: {
    ...typography.caption,
    color: colors.navy[700],
    fontWeight: '600',
  },
  
  // Notes
  noteItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
  },
  noteItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.gray[100],
  },
  noteIconContainer: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: colors.champagne[100],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing[3],
  },
  noteText: {
    ...typography.body,
    color: colors.gray[700],
    flex: 1,
  },
  
  // Family
  familyScroll: {
    paddingRight: spacing[4],
  },
  familyItem: {
    alignItems: 'center',
    marginRight: spacing[4],
    width: 72,
  },
  familyAvatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: colors.gray[100],
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  familyName: {
    ...typography.bodySmall,
    color: colors.navy[900],
    fontWeight: '600',
    textAlign: 'center',
  },
  familyType: {
    ...typography.caption,
    color: colors.gray[500],
    textAlign: 'center',
  },
  
  // Quick Actions
  quickActionsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: spacing[3],
    gap: spacing[3],
  },
  quickAction: {
    width: '47%',
    backgroundColor: colors.white,
    borderRadius: 16,
    padding: spacing[4],
    alignItems: 'center',
    ...shadows.sm,
  },
  quickActionIcon: {
    width: 48,
    height: 48,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing[2],
  },
  quickActionText: {
    ...typography.bodySmall,
    color: colors.navy[900],
    fontWeight: '600',
  },
  
  // Maintenance Items
  maintenanceItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[3],
  },
  maintenanceItemBorder: {
    borderBottomWidth: 1,
    borderBottomColor: colors.gray[100],
  },
  maintenanceIconContainer: {
    width: 40,
    height: 40,
    borderRadius: 10,
    backgroundColor: colors.navy[50],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing[3],
  },
  maintenanceContent: {
    flex: 1,
  },
  maintenanceTitle: {
    ...typography.body,
    color: colors.navy[900],
    fontWeight: '500',
  },
  maintenanceDate: {
    ...typography.caption,
    color: colors.gray[500],
    marginTop: 2,
  },
  
  bottomSpacer: {
    height: spacing[8],
  },
});
```

---

# PHASE 4: CREATE ALFRED BUTLER EXPERIENCE

## Step 4.1: Create Alfred Avatar Component

Create apps/mobile/src/components/AlfredAvatar.tsx:

```typescript
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Svg, { Circle, Path, Ellipse, Line, G } from 'react-native-svg';
import { colors } from '../theme';

interface AlfredAvatarProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  showBadge?: boolean;
}

export function AlfredAvatar({ size = 'md', showBadge = true }: AlfredAvatarProps) {
  const sizes = {
    sm: 32,
    md: 48,
    lg: 64,
    xl: 96,
  };

  const dimension = sizes[size];
  const iconSize = dimension * 0.65;
  const badgeSize = Math.max(16, dimension * 0.25);

  return (
    <View style={[styles.container, { width: dimension, height: dimension }]}>
      <LinearGradient
        colors={[colors.navy[800], colors.navy[950]]}
        style={[
          styles.avatar,
          {
            width: dimension,
            height: dimension,
            borderRadius: dimension / 2,
            borderWidth: dimension * 0.04,
          },
        ]}
      >
        <Svg width={iconSize} height={iconSize} viewBox="0 0 48 48">
          {/* Distinguished Butler Alfred - with monocle and bow tie */}
          <G>
            {/* Head silhouette */}
            <Ellipse cx="24" cy="16" rx="10" ry="11" fill={colors.champagne[500]} opacity={0.95} />
            
            {/* Monocle */}
            <Circle cx="29" cy="15" r="5" stroke={colors.champagne[400]} strokeWidth="1.2" fill="none" />
            <Line x1="34" y1="15" x2="38" y2="20" stroke={colors.champagne[400]} strokeWidth="1.2" />
            
            {/* Suit/Body */}
            <Path
              d="M8 48 Q8 36 24 34 Q40 36 40 48"
              fill={colors.champagne[500]}
              opacity={0.95}
            />
            
            {/* Bow tie */}
            <Path
              d="M18 34 L24 37 L30 34 L30 38 L24 35 L18 38 Z"
              fill={colors.champagne[300]}
            />
            
            {/* Lapel lines */}
            <Path d="M20 36 L24 44 L22 48" stroke={colors.navy[900]} strokeWidth="0.8" fill="none" />
            <Path d="M28 36 L24 44 L26 48" stroke={colors.navy[900]} strokeWidth="0.8" fill="none" />
          </G>
        </Svg>
      </LinearGradient>

      {/* AI Badge */}
      {showBadge && (
        <View
          style={[
            styles.badge,
            {
              width: badgeSize + 8,
              height: badgeSize,
              borderRadius: badgeSize / 2,
            },
          ]}
        >
          <Text style={[styles.badgeText, { fontSize: badgeSize * 0.55 }]}>AI</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    position: 'relative',
  },
  avatar: {
    justifyContent: 'center',
    alignItems: 'center',
    borderColor: colors.champagne[400],
  },
  badge: {
    position: 'absolute',
    bottom: -2,
    right: -4,
    backgroundColor: colors.champagne[500],
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: colors.white,
  },
  badgeText: {
    color: colors.white,
    fontWeight: '700',
  },
});
```

## Step 4.2: Create Alfred Chat Screen (manager.tsx)

Create apps/mobile/app/(tabs)/manager.tsx - This should be a full Alfred chat experience matching the butler personality.

The file is long - see the full content in the original prompt above in PHASE 4, Step 4.2.

---

# PHASE 5: FIX WEB ONBOARDING

## Step 5.1: Find and Fix the Onboarding Loop

```bash
# Find the onboarding confirmation page that has the "Start entering info" button
grep -rn "Start entering info\|entering info now\|I'll wait for my call" /Users/tomburke/Projects/Housing-Manager/apps/web --include="*.tsx" | head -10

# Find the page and examine it
```

The fix: After scheduling the call, "Start entering info now" should go to `/app` (dashboard), NOT back to the challenge question.

## Step 5.2: Update the Confirmation Page Navigation

Find the confirmation page and update the handlers:

```typescript
// The button handler should be:
const handleStartEnteringInfo = async () => {
  // Mark onboarding as complete
  await fetch('/api/users/complete-onboarding', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      callScheduled: true,
      tier: localStorage.getItem('selectedPlan') || 'essentials'
    }),
  });
  
  // Go to dashboard - NOT back to onboarding
  router.replace('/app');
};

const handleWaitForCall = async () => {
  // Same - go to dashboard
  await fetch('/api/users/complete-onboarding', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      callScheduled: true,
      waitingForCall: true,
      tier: localStorage.getItem('selectedPlan') || 'essentials'
    }),
  });
  
  router.replace('/app');
};
```

## Step 5.3: Create New Plan Selection with 3 Tiers + Bill Consolidation

Create/Replace apps/web/src/app/onboarding/plan/page.tsx with the plan selection showing $39, $349, $749 and highlighting bill consolidation.

See PHASE 5 in the full prompt above for the complete file.

---

# PHASE 6: BUILD, TEST, AND DEPLOY

## Step 6.1: Final Build Check

```bash
echo "=== FINAL BUILD CHECK ==="

# Build API
echo "Building API..."
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm build 2>&1 | tail -20

# Build Web
echo ""
echo "Building Web..."
cd /Users/tomburke/Projects/Housing-Manager/apps/web
pnpm build 2>&1 | tail -20

# Build Mobile
echo ""
echo "Checking Mobile..."
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm typecheck 2>&1 | tail -30

# Export mobile
echo ""
echo "Exporting Mobile..."
npx expo export --platform ios 2>&1 | tail -20

echo ""
echo "=== BUILD CHECK COMPLETE ==="
```

## Step 6.2: Increment Build Number

```bash
# Get current build number and increment
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
CURRENT_BUILD=$(grep -o '"buildNumber": "[0-9]*"' app.json | grep -o '[0-9]*')
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "Current build: $CURRENT_BUILD"
echo "New build: $NEW_BUILD"

# Update build number
sed -i '' "s/\"buildNumber\": \"$CURRENT_BUILD\"/\"buildNumber\": \"$NEW_BUILD\"/" app.json

echo "Updated to build $NEW_BUILD"
```

## Step 6.3: Deploy to TestFlight

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
eas build --platform ios --profile production --auto-submit
```

---

# REQUIRED REPORT

After completing all phases, provide a report with:

1. **Diagnostic Results**:
   - What TypeScript errors were found?
   - What files were missing?
   - Was AlfredModule registered in app.module.ts?
   - Was ANTHROPIC_API_KEY present?

2. **Files Created/Modified**:
   - List all files created
   - List all files modified

3. **Tab Layout**:
   - Confirm exactly 5 tabs: Home, Alfred/Sarah, Messages, Money, More
   - Confirm hidden screens are set with `href: null`

4. **Design Matching**:
   - Confirm theme files created (colors, spacing, typography, shadows)
   - Confirm dashboard matches mobile web design

5. **Alfred Butler**:
   - Confirm AlfredAvatar component created
   - Confirm Alfred chat screen created with butler personality

6. **Onboarding**:
   - Confirm plan selection shows 3 tiers ($39, $349, $749)
   - Confirm bill consolidation is highlighted
   - Confirm Essentials tier navigation fixed

7. **Build Status**:
   - API build: success/fail
   - Web build: success/fail
   - Mobile typecheck: success/fail
   - Mobile export: success/fail

8. **New Build Number**: What is the new buildNumber?

9. **Remaining Issues**: List any issues that couldn't be resolved

---

# END OF PROMPT

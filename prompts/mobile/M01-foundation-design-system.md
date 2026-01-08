# Haven Mobile: M01 - Foundation & Design System

**Created:** December 29, 2024  
**Priority:** P0 - Must complete first  
**Estimated Time:** 2-3 hours  
**Dependencies:** None

---

## CRITICAL RULES

1. **DO NOT DELETE existing code** - Only add, refactor, and update
2. **Use Haven brand colors** - Navy (#0a1929) + Champagne (#c4a574), NO bright green
3. **Test on iOS Simulator** after each major change
4. **Keep package.json clean** - Install only what's needed

---

## Overview

This prompt establishes the foundation for the Haven mobile app:
1. Update color theme from old blue/green to navy/champagne
2. Install essential dependencies
3. Create reusable UI components
4. Configure app.json for production
5. Set up proper project structure

---

## PHASE 1: Install Dependencies

### Task 1.1: Install UI Dependencies

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Icon library
pnpm add @expo/vector-icons

# Animations and gestures (ensure latest)
pnpm add react-native-reanimated

# Bottom sheets
pnpm add @gorhom/bottom-sheet

# Haptic feedback
pnpm add expo-haptics

# Linear gradient for cards
pnpm add expo-linear-gradient

# Date handling
pnpm add date-fns
```

### Task 1.2: Update babel.config.js for Reanimated

```javascript
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      'react-native-reanimated/plugin', // Must be last
    ],
  };
};
```

---

## PHASE 2: Update Theme

### Task 2.1: Replace Theme File

Replace `apps/mobile/src/lib/theme.ts` with Haven brand colors:

```typescript
/**
 * Haven Mobile Design System
 * 
 * Primary: Navy (#0a1929) - Brand identity, headers, primary actions
 * Accent: Champagne (#c4a574) - CTAs, highlights, premium feel
 * 
 * CRITICAL: NO BRIGHT GREEN - Old brand is deprecated
 */

// Haven Brand Colors
export const colors = {
  // Haven Navy (Primary)
  haven: {
    navy: {
      950: '#0a1929',  // Darkest - headers, primary bg
      900: '#102a43',  // Primary text, buttons
      800: '#243b53',  // Secondary elements
      700: '#334e68',  // Hover states
      600: '#486581',  // Tertiary elements
      500: '#627d98',  // Muted text
      400: '#829ab1',  // Borders, disabled
      300: '#9fb3c8',  // Light borders
      200: '#bcccdc',  // Subtle backgrounds
      100: '#d9e2ec',  // Very light backgrounds
      50: '#f0f4f8',   // Near white
    },
    champagne: {
      600: '#a68a5b',  // Dark accent
      500: '#c4a574',  // Primary accent - CTAs
      400: '#d4c4a5',  // Hover state
      300: '#e9dcc4',  // Light accent
      200: '#f2ebe0',  // Very light
      100: '#faf6ed',  // Subtle backgrounds
      50: '#fdfbf7',   // Near white
    },
  },

  // Neutral grays (for UI elements)
  gray: {
    950: '#0f0f0f',
    900: '#171717',
    800: '#262626',
    700: '#404040',
    600: '#525252',
    500: '#737373',
    400: '#a3a3a3',
    300: '#d4d4d4',
    200: '#e5e5e5',
    100: '#f5f5f5',
    50: '#fafafa',
  },

  // Status colors (use sparingly)
  status: {
    success: '#059669',      // emerald-600 - Confirmations, success states
    successLight: '#d1fae5', // emerald-100 - Success backgrounds
    warning: '#d97706',      // amber-600 - Warnings
    warningLight: '#fef3c7', // amber-100 - Warning backgrounds
    error: '#dc2626',        // red-600 - Errors
    errorLight: '#fee2e2',   // red-100 - Error backgrounds
    info: '#0284c7',         // sky-600 - Information
    infoLight: '#e0f2fe',    // sky-100 - Info backgrounds
  },

  // Basic
  white: '#ffffff',
  black: '#000000',
  transparent: 'transparent',

  // Background colors
  background: {
    primary: '#ffffff',      // Main content
    secondary: '#f8fafc',    // Cards, sections
    tertiary: '#f1f5f9',     // Input backgrounds
  },

  // Text colors
  text: {
    primary: '#102a43',      // haven.navy.900
    secondary: '#627d98',    // haven.navy.500
    tertiary: '#829ab1',     // haven.navy.400
    inverse: '#ffffff',      // On dark backgrounds
    accent: '#c4a574',       // Champagne accent
  },

  // Border colors
  border: {
    default: '#e2e8f0',
    light: '#f1f5f9',
    dark: '#cbd5e1',
    focus: '#c4a574',        // Champagne for focus
  },
};

// Typography scale
export const typography = {
  fontSizes: {
    '2xs': 10,
    xs: 12,
    sm: 14,
    base: 16,
    lg: 18,
    xl: 20,
    '2xl': 24,
    '3xl': 30,
    '4xl': 36,
  },
  fontWeights: {
    normal: '400' as const,
    medium: '500' as const,
    semibold: '600' as const,
    bold: '700' as const,
  },
  lineHeights: {
    tight: 1.1,
    snug: 1.25,
    normal: 1.5,
    relaxed: 1.75,
  },
};

// Spacing scale (4px base)
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
};

// Border radius
export const borderRadius = {
  none: 0,
  xs: 2,
  sm: 4,
  md: 8,
  lg: 12,
  xl: 16,
  '2xl': 24,
  '3xl': 32,
  full: 9999,
};

// Shadows (iOS style)
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
    shadowOpacity: 0.05,
    shadowRadius: 1,
    elevation: 1,
  },
  sm: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 2,
    elevation: 2,
  },
  md: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  lg: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.12,
    shadowRadius: 6,
    elevation: 5,
  },
  xl: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.15,
    shadowRadius: 12,
    elevation: 8,
  },
};

// Animation durations
export const animation = {
  fast: 150,
  normal: 250,
  slow: 350,
};

// Hit slop for touch targets (accessibility)
export const hitSlop = {
  small: { top: 8, bottom: 8, left: 8, right: 8 },
  medium: { top: 12, bottom: 12, left: 12, right: 12 },
  large: { top: 16, bottom: 16, left: 16, right: 16 },
};

// Minimum touch target sizes (accessibility)
export const touchTarget = {
  minimum: 44, // iOS Human Interface Guidelines
  comfortable: 48,
};
```

---

## PHASE 3: Create UI Components

### Task 3.1: Create Components Directory Structure

```bash
mkdir -p apps/mobile/src/components/ui
mkdir -p apps/mobile/src/components/forms
mkdir -p apps/mobile/src/components/layout
```

### Task 3.2: Create Button Component

Create `apps/mobile/src/components/ui/Button.tsx`:

```typescript
import React from 'react';
import {
  TouchableOpacity,
  Text,
  StyleSheet,
  ActivityIndicator,
  ViewStyle,
  TextStyle,
  View,
} from 'react-native';
import * as Haptics from 'expo-haptics';
import { colors, typography, spacing, borderRadius, shadows, touchTarget } from '../../lib/theme';

type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: ButtonVariant;
  size?: ButtonSize;
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  icon?: React.ReactNode;
  iconPosition?: 'left' | 'right';
  style?: ViewStyle;
  textStyle?: TextStyle;
  haptic?: boolean;
}

export function Button({
  title,
  onPress,
  variant = 'primary',
  size = 'md',
  disabled = false,
  loading = false,
  fullWidth = false,
  icon,
  iconPosition = 'left',
  style,
  textStyle,
  haptic = true,
}: ButtonProps) {
  const handlePress = () => {
    if (haptic) {
      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    }
    onPress();
  };

  const isDisabled = disabled || loading;

  return (
    <TouchableOpacity
      style={[
        styles.base,
        styles[variant],
        styles[`size_${size}`],
        fullWidth && styles.fullWidth,
        isDisabled && styles.disabled,
        style,
      ]}
      onPress={handlePress}
      disabled={isDisabled}
      activeOpacity={0.8}
    >
      {loading ? (
        <ActivityIndicator
          color={variant === 'primary' ? colors.white : colors.haven.navy[900]}
          size="small"
        />
      ) : (
        <View style={styles.content}>
          {icon && iconPosition === 'left' && <View style={styles.iconLeft}>{icon}</View>}
          <Text
            style={[
              styles.text,
              styles[`text_${variant}`],
              styles[`text_${size}`],
              textStyle,
            ]}
          >
            {title}
          </Text>
          {icon && iconPosition === 'right' && <View style={styles.iconRight}>{icon}</View>}
        </View>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  base: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: borderRadius.lg,
    minHeight: touchTarget.minimum,
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconLeft: {
    marginRight: spacing[2],
  },
  iconRight: {
    marginLeft: spacing[2],
  },
  fullWidth: {
    width: '100%',
  },
  disabled: {
    opacity: 0.5,
  },

  // Variants
  primary: {
    backgroundColor: colors.haven.navy[900],
    ...shadows.sm,
  },
  secondary: {
    backgroundColor: colors.haven.champagne[500],
    ...shadows.sm,
  },
  outline: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: colors.haven.navy[900],
  },
  ghost: {
    backgroundColor: 'transparent',
  },
  destructive: {
    backgroundColor: colors.status.error,
    ...shadows.sm,
  },

  // Sizes
  size_sm: {
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    minHeight: 36,
  },
  size_md: {
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[4],
    minHeight: touchTarget.minimum,
  },
  size_lg: {
    paddingVertical: spacing[4],
    paddingHorizontal: spacing[6],
    minHeight: 52,
  },

  // Text base
  text: {
    fontWeight: typography.fontWeights.semibold,
  },

  // Text variants
  text_primary: {
    color: colors.white,
  },
  text_secondary: {
    color: colors.haven.navy[900],
  },
  text_outline: {
    color: colors.haven.navy[900],
  },
  text_ghost: {
    color: colors.haven.navy[900],
  },
  text_destructive: {
    color: colors.white,
  },

  // Text sizes
  text_sm: {
    fontSize: typography.fontSizes.sm,
  },
  text_md: {
    fontSize: typography.fontSizes.base,
  },
  text_lg: {
    fontSize: typography.fontSizes.lg,
  },
});
```

### Task 3.3: Create Card Component

Create `apps/mobile/src/components/ui/Card.tsx`:

```typescript
import React from 'react';
import { View, StyleSheet, ViewStyle, TouchableOpacity } from 'react-native';
import { colors, spacing, borderRadius, shadows } from '../../lib/theme';

interface CardProps {
  children: React.ReactNode;
  onPress?: () => void;
  variant?: 'default' | 'elevated' | 'outlined';
  padding?: keyof typeof spacing;
  style?: ViewStyle;
}

export function Card({
  children,
  onPress,
  variant = 'default',
  padding = 4,
  style,
}: CardProps) {
  const cardStyle = [
    styles.base,
    styles[variant],
    { padding: spacing[padding] },
    style,
  ];

  if (onPress) {
    return (
      <TouchableOpacity style={cardStyle} onPress={onPress} activeOpacity={0.95}>
        {children}
      </TouchableOpacity>
    );
  }

  return <View style={cardStyle}>{children}</View>;
}

const styles = StyleSheet.create({
  base: {
    borderRadius: borderRadius.xl,
    backgroundColor: colors.white,
  },
  default: {
    ...shadows.sm,
  },
  elevated: {
    ...shadows.lg,
  },
  outlined: {
    borderWidth: 1,
    borderColor: colors.border.default,
    ...shadows.none,
  },
});
```

### Task 3.4: Create Input Component

Create `apps/mobile/src/components/forms/Input.tsx`:

```typescript
import React, { useState } from 'react';
import {
  View,
  TextInput,
  Text,
  StyleSheet,
  TextInputProps,
  TouchableOpacity,
  ViewStyle,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

interface InputProps extends Omit<TextInputProps, 'style'> {
  label?: string;
  error?: string;
  hint?: string;
  leftIcon?: keyof typeof Ionicons.glyphMap;
  rightIcon?: keyof typeof Ionicons.glyphMap;
  onRightIconPress?: () => void;
  containerStyle?: ViewStyle;
}

export function Input({
  label,
  error,
  hint,
  leftIcon,
  rightIcon,
  onRightIconPress,
  containerStyle,
  secureTextEntry,
  ...props
}: InputProps) {
  const [isFocused, setIsFocused] = useState(false);
  const [isPasswordVisible, setIsPasswordVisible] = useState(false);

  const showPasswordToggle = secureTextEntry && !rightIcon;
  const actualSecureEntry = secureTextEntry && !isPasswordVisible;

  return (
    <View style={[styles.container, containerStyle]}>
      {label && <Text style={styles.label}>{label}</Text>}
      
      <View
        style={[
          styles.inputContainer,
          isFocused && styles.inputFocused,
          error && styles.inputError,
        ]}
      >
        {leftIcon && (
          <Ionicons
            name={leftIcon}
            size={20}
            color={colors.haven.navy[400]}
            style={styles.leftIcon}
          />
        )}
        
        <TextInput
          style={[
            styles.input,
            leftIcon && styles.inputWithLeftIcon,
            (rightIcon || showPasswordToggle) && styles.inputWithRightIcon,
          ]}
          placeholderTextColor={colors.haven.navy[400]}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          secureTextEntry={actualSecureEntry}
          {...props}
        />
        
        {showPasswordToggle && (
          <TouchableOpacity
            onPress={() => setIsPasswordVisible(!isPasswordVisible)}
            style={styles.rightIconContainer}
          >
            <Ionicons
              name={isPasswordVisible ? 'eye-off-outline' : 'eye-outline'}
              size={20}
              color={colors.haven.navy[400]}
            />
          </TouchableOpacity>
        )}
        
        {rightIcon && onRightIconPress && (
          <TouchableOpacity onPress={onRightIconPress} style={styles.rightIconContainer}>
            <Ionicons name={rightIcon} size={20} color={colors.haven.navy[400]} />
          </TouchableOpacity>
        )}
      </View>
      
      {hint && !error && <Text style={styles.hint}>{hint}</Text>}
      {error && <Text style={styles.error}>{error}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[1.5],
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.background.tertiary,
    borderWidth: 1,
    borderColor: colors.border.default,
    borderRadius: borderRadius.lg,
    minHeight: 48,
  },
  inputFocused: {
    borderColor: colors.haven.champagne[500],
    backgroundColor: colors.white,
  },
  inputError: {
    borderColor: colors.status.error,
  },
  input: {
    flex: 1,
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[3],
  },
  inputWithLeftIcon: {
    paddingLeft: 0,
  },
  inputWithRightIcon: {
    paddingRight: 0,
  },
  leftIcon: {
    marginLeft: spacing[3],
  },
  rightIconContainer: {
    padding: spacing[3],
  },
  hint: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: spacing[1],
  },
  error: {
    fontSize: typography.fontSizes.xs,
    color: colors.status.error,
    marginTop: spacing[1],
  },
});
```

### Task 3.5: Create Loading Spinner Component

Create `apps/mobile/src/components/ui/LoadingSpinner.tsx`:

```typescript
import React from 'react';
import { View, ActivityIndicator, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, typography, spacing } from '../../lib/theme';

interface LoadingSpinnerProps {
  size?: 'small' | 'large';
  color?: string;
  message?: string;
  fullScreen?: boolean;
  style?: ViewStyle;
}

export function LoadingSpinner({
  size = 'large',
  color = colors.haven.champagne[500],
  message,
  fullScreen = false,
  style,
}: LoadingSpinnerProps) {
  const content = (
    <View style={[styles.container, style]}>
      <ActivityIndicator size={size} color={color} />
      {message && <Text style={styles.message}>{message}</Text>}
    </View>
  );

  if (fullScreen) {
    return <View style={styles.fullScreen}>{content}</View>;
  }

  return content;
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[4],
  },
  fullScreen: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.white,
  },
  message: {
    marginTop: spacing[3],
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
  },
});
```

### Task 3.6: Create Badge Component

Create `apps/mobile/src/components/ui/Badge.tsx`:

```typescript
import React from 'react';
import { View, Text, StyleSheet, ViewStyle } from 'react-native';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';

type BadgeVariant = 'default' | 'success' | 'warning' | 'error' | 'info' | 'champagne';

interface BadgeProps {
  label: string;
  variant?: BadgeVariant;
  size?: 'sm' | 'md';
  style?: ViewStyle;
}

export function Badge({ label, variant = 'default', size = 'md', style }: BadgeProps) {
  return (
    <View style={[styles.base, styles[variant], styles[`size_${size}`], style]}>
      <Text style={[styles.text, styles[`text_${variant}`], styles[`text_${size}`]]}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    borderRadius: borderRadius.full,
    alignSelf: 'flex-start',
  },

  // Variants
  default: {
    backgroundColor: colors.gray[100],
  },
  success: {
    backgroundColor: colors.status.successLight,
  },
  warning: {
    backgroundColor: colors.status.warningLight,
  },
  error: {
    backgroundColor: colors.status.errorLight,
  },
  info: {
    backgroundColor: colors.status.infoLight,
  },
  champagne: {
    backgroundColor: colors.haven.champagne[100],
  },

  // Sizes
  size_sm: {
    paddingVertical: spacing[0.5],
    paddingHorizontal: spacing[2],
  },
  size_md: {
    paddingVertical: spacing[1],
    paddingHorizontal: spacing[2.5],
  },

  // Text base
  text: {
    fontWeight: typography.fontWeights.medium,
  },

  // Text variants
  text_default: {
    color: colors.gray[700],
  },
  text_success: {
    color: colors.status.success,
  },
  text_warning: {
    color: colors.status.warning,
  },
  text_error: {
    color: colors.status.error,
  },
  text_info: {
    color: colors.status.info,
  },
  text_champagne: {
    color: colors.haven.champagne[600],
  },

  // Text sizes
  text_sm: {
    fontSize: typography.fontSizes['2xs'],
  },
  text_md: {
    fontSize: typography.fontSizes.xs,
  },
});
```

### Task 3.7: Create Component Index

Create `apps/mobile/src/components/index.ts`:

```typescript
// UI Components
export * from './ui/Button';
export * from './ui/Card';
export * from './ui/Badge';
export * from './ui/LoadingSpinner';

// Form Components
export * from './forms/Input';
```

---

## PHASE 4: Update App Configuration

### Task 4.1: Update app.json

Replace `apps/mobile/app.json`:

```json
{
  "expo": {
    "name": "Haven",
    "slug": "haven-home-manager",
    "version": "1.0.0",
    "orientation": "portrait",
    "icon": "./assets/icon.png",
    "scheme": "haven",
    "userInterfaceStyle": "light",
    "newArchEnabled": true,
    "splash": {
      "image": "./assets/splash-icon.png",
      "resizeMode": "contain",
      "backgroundColor": "#0a1929"
    },
    "assetBundlePatterns": ["**/*"],
    "ios": {
      "supportsTablet": true,
      "bundleIdentifier": "com.havenhome.app",
      "buildNumber": "1",
      "infoPlist": {
        "NSCameraUsageDescription": "Haven needs camera access to scan documents and take photos of your home.",
        "NSPhotoLibraryUsageDescription": "Haven needs photo library access to upload documents and photos.",
        "NSLocationWhenInUseUsageDescription": "Haven uses your location to provide local service recommendations."
      }
    },
    "android": {
      "adaptiveIcon": {
        "foregroundImage": "./assets/adaptive-icon.png",
        "backgroundColor": "#0a1929"
      },
      "package": "com.havenhome.app",
      "versionCode": 1
    },
    "web": {
      "bundler": "metro",
      "output": "static",
      "favicon": "./assets/favicon.png"
    },
    "plugins": [
      "expo-router",
      "expo-secure-store",
      [
        "expo-image-picker",
        {
          "photosPermission": "Haven needs photo access to upload documents."
        }
      ]
    ],
    "experiments": {
      "typedRoutes": true
    },
    "extra": {
      "eas": {
        "projectId": "YOUR_EAS_PROJECT_ID"
      }
    }
  }
}
```

### Task 4.2: Create Environment Config

Create `apps/mobile/src/lib/config.ts`:

```typescript
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
```

### Task 4.3: Create .env.example

Create `apps/mobile/.env.example`:

```bash
# Haven Mobile Environment Variables

# API
EXPO_PUBLIC_API_URL=https://api.havenhome.dev/api

# Firebase
EXPO_PUBLIC_FIREBASE_API_KEY=
EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN=
EXPO_PUBLIC_FIREBASE_PROJECT_ID=
EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET=
EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=
EXPO_PUBLIC_FIREBASE_APP_ID=

# Google Places API
EXPO_PUBLIC_GOOGLE_PLACES_API_KEY=

# Plaid
EXPO_PUBLIC_PLAID_ENV=sandbox
```

---

## PHASE 5: Update Tab Navigation with New Theme

### Task 5.1: Update Tab Layout

Update `apps/mobile/app/(tabs)/_layout.tsx` to use new theme colors:

```typescript
import { Tabs } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors, typography, spacing } from '../../src/lib/theme';

type TabIconName = 'home' | 'add-circle' | 'chatbubble' | 'card' | 'settings';

function TabIcon({ name, focused }: { name: TabIconName; focused: boolean }) {
  const iconMap: Record<TabIconName, keyof typeof Ionicons.glyphMap> = {
    home: focused ? 'home' : 'home-outline',
    'add-circle': focused ? 'add-circle' : 'add-circle-outline',
    chatbubble: focused ? 'chatbubble' : 'chatbubble-outline',
    card: focused ? 'card' : 'card-outline',
    settings: focused ? 'settings' : 'settings-outline',
  };

  return (
    <Ionicons
      name={iconMap[name]}
      size={24}
      color={focused ? colors.haven.champagne[500] : colors.haven.navy[400]}
    />
  );
}

export default function TabsLayout() {
  return (
    <Tabs
      screenOptions={{
        tabBarActiveTintColor: colors.haven.champagne[500],
        tabBarInactiveTintColor: colors.haven.navy[400],
        tabBarStyle: {
          backgroundColor: colors.white,
          borderTopColor: colors.border.default,
          borderTopWidth: 1,
          paddingTop: spacing[2],
          paddingBottom: spacing[2],
          height: 80,
        },
        tabBarLabelStyle: {
          fontSize: typography.fontSizes.xs,
          fontWeight: typography.fontWeights.medium,
          marginTop: spacing[1],
        },
        headerStyle: {
          backgroundColor: colors.haven.navy[900],
        },
        headerTintColor: colors.white,
        headerTitleStyle: {
          fontWeight: typography.fontWeights.semibold,
          fontSize: typography.fontSizes.lg,
        },
        headerShadowVisible: false,
      }}
    >
      <Tabs.Screen
        name="index"
        options={{
          title: 'Home',
          headerTitle: 'Haven',
          tabBarIcon: ({ focused }) => <TabIcon name="home" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="new-request"
        options={{
          title: 'Request',
          tabBarIcon: ({ focused }) => <TabIcon name="add-circle" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="chat"
        options={{
          title: 'Sarah',
          tabBarIcon: ({ focused }) => <TabIcon name="chatbubble" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="billing"
        options={{
          title: 'Money',
          tabBarIcon: ({ focused }) => <TabIcon name="card" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="settings"
        options={{
          title: 'Settings',
          tabBarIcon: ({ focused }) => <TabIcon name="settings" focused={focused} />,
        }}
      />
    </Tabs>
  );
}
```

---

## PHASE 6: Verification

### Task 6.1: Run Development Server

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
pnpm start --ios
```

### Task 6.2: Verify Checklist

- [ ] App launches without errors
- [ ] Theme colors are navy/champagne (no bright blue/green)
- [ ] Tab bar shows correct icons and colors
- [ ] Button component works with all variants
- [ ] Card component renders correctly
- [ ] Input component shows focus states
- [ ] Badge component displays correctly
- [ ] No TypeScript errors (`pnpm typecheck`)

### Task 6.3: Take Screenshots

After verification, take screenshots of:
1. Tab bar with new theme
2. Sample screen with components

---

## Summary

After completing this prompt:
1. ✅ Haven brand theme (navy/champagne) applied
2. ✅ Essential dependencies installed
3. ✅ Reusable UI component library created
4. ✅ App configuration updated for production
5. ✅ Tab navigation styled with new theme

**Next Prompt:** M02 - Authentication & User Flow

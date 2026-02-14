/**
 * Haven Mobile Design System
 *
 * Primary: Deep Purple (#6200EA) - Brand identity, headers, primary actions
 * Accent: Coral (#FF6B6B) - Alerts, urgent badges, secondary CTAs (use sparingly)
 * Background: White/Purple-50 - Clean, bright, airy
 *
 * Font: Nunito
 */

// Haven Brand Colors
export const colors = {
  // Haven Purple (Primary Brand)
  haven: {
    purple: {
      950: '#1A0044',  // Darkest - dark mode bg
      900: '#2D006B',  // Deep emphasis
      800: '#3D008F',  // Dark buttons
      700: '#4A00B4',  // Hover states
      600: '#5500D4',  // Active states
      500: '#6200EA',  // PRIMARY BRAND COLOR
      400: '#7C4DFF',  // Lighter interactive
      300: '#B388FF',  // Light accent text, badges
      200: '#D1B3FF',  // Subtle highlights
      100: '#EDE7F6',  // Card backgrounds, input fills
      50:  '#F9F5FF',  // Page background, subtle tints
    },
    // Coral accent (USE SPARINGLY — alerts, urgent badges, secondary CTAs only)
    coral: {
      600: '#E85555',  // Dark coral for text on white (WCAG AA)
      500: '#FF6B6B',  // Primary coral
      400: '#FF8A8A',  // Hover state
      100: '#FFE0E0',  // Light coral bg
      50:  '#FFF0F0',  // Subtle coral tint
    },
  },

  // Neutral grays (for UI elements)
  gray: {
    950: '#0F0F1E',
    900: '#1A1A2E',
    800: '#2D2D44',
    700: '#444466',
    600: '#525252',
    500: '#6B7280',
    400: '#9CA3AF',
    300: '#D1D5DB',
    200: '#E5E7EB',
    100: '#F3F4F6',
    50:  '#F9FAFB',
  },

  // Status colors (semantic — DO NOT change)
  status: {
    success: '#059669',      // emerald-600
    successLight: '#d1fae5', // emerald-100
    warning: '#D97706',      // amber-600
    warningLight: '#fef3c7', // amber-100
    error: '#DC2626',        // red-600
    errorLight: '#fee2e2',   // red-100
    info: '#0284c7',         // sky-600
    infoLight: '#e0f2fe',    // sky-100
  },

  // Basic
  white: '#ffffff',
  black: '#000000',
  transparent: 'transparent',

  // Background colors
  background: {
    primary: '#FFFFFF',
    secondary: '#F9F5FF',    // Light purple tint
    tertiary: '#EDE7F6',     // Purple-100
  },

  // Text colors
  text: {
    primary: '#1A1A2E',      // gray-900 (dark with purple tint)
    secondary: '#6B7280',    // gray-500
    tertiary: '#9CA3AF',     // gray-400
    inverse: '#FFFFFF',
    accent: '#6200EA',       // Purple-500
  },

  // Border colors
  border: {
    default: '#E5E7EB',
    light: '#F3F4F6',
    dark: '#D1D5DB',
    focus: '#6200EA',        // Purple for focus
  },

  green: {
    50: '#ecfdf5',
    100: '#d1fae5',
    200: '#a7f3d0',
    300: '#6ee7b7',
    400: '#34d399',
    500: '#10b981',
    600: '#059669',
    700: '#047857',
    800: '#065f46',
    900: '#064e3b',
  },
  slate: {
    50: '#f8fafc',
    100: '#f1f5f9',
    200: '#e2e8f0',
    300: '#cbd5e1',
    400: '#94a3b8',
    500: '#64748b',
    600: '#475569',
    700: '#334155',
    800: '#1e293b',
    900: '#0f172a',
    950: '#020617',
  },
  error: '#dc2626',    // Alias for status.error
  warning: '#d97706',  // Alias for status.warning
  success: '#059669',  // Alias for status.success
  info: '#0284c7',     // Alias for status.info

  // Additional color aliases
  red: {
    50: '#fef2f2',
    100: '#fee2e2',
    200: '#fecaca',
    300: '#fca5a5',
    400: '#f87171',
    500: '#ef4444',
    600: '#dc2626',
    700: '#b91c1c',
    800: '#991b1b',
    900: '#7f1d1d',
  },
  blue: {
    50: '#eff6ff',
    100: '#dbeafe',
    200: '#bfdbfe',
    300: '#93c5fd',
    400: '#60a5fa',
    500: '#3b82f6',
    600: '#2563eb',
    700: '#1d4ed8',
    800: '#1e40af',
    900: '#1e3a8a',
  },
  indigo: {
    50: '#eef2ff',
    100: '#e0e7ff',
    200: '#c7d2fe',
    300: '#a5b4fc',
    400: '#818cf8',
    500: '#6366f1',
    600: '#4f46e5',
    700: '#4338ca',
    800: '#3730a3',
    900: '#312e81',
  },
  amber: {
    50: '#fffbeb',
    100: '#fef3c7',
    200: '#fde68a',
    300: '#fcd34d',
    400: '#fbbf24',
    500: '#f59e0b',
    600: '#d97706',
    700: '#b45309',
    800: '#92400e',
    900: '#78350f',
  },
  cyan: {
    50: '#ecfeff',
    100: '#cffafe',
    200: '#a5f3fc',
    300: '#67e8f9',
    400: '#22d3ee',
    500: '#06b6d4',
    600: '#0891b2',
    700: '#0e7490',
    800: '#155e75',
    900: '#164e63',
  },
  emerald: {
    50: '#ecfdf5',
    100: '#d1fae5',
    200: '#a7f3d0',
    300: '#6ee7b7',
    400: '#34d399',
    500: '#10b981',
    600: '#059669',
    700: '#047857',
    800: '#065f46',
    900: '#064e3b',
  },
  orange: {
    50: '#fff7ed',
    100: '#ffedd5',
    200: '#fed7aa',
    300: '#fdba74',
    400: '#fb923c',
    500: '#f97316',
    600: '#ea580c',
    700: '#c2410c',
    800: '#9a3412',
    900: '#7c2d12',
  },
  rose: {
    50: '#fff1f2',
    100: '#ffe4e6',
    200: '#fecdd3',
    300: '#fda4af',
    400: '#fb7185',
    500: '#f43f5e',
    600: '#e11d48',
    700: '#be123c',
    800: '#9f1239',
    900: '#881337',
  },
  lime: {
    50: '#f7fee7',
    100: '#ecfccb',
    200: '#d9f99d',
    300: '#bef264',
    400: '#a3e635',
    500: '#84cc16',
    600: '#65a30d',
    700: '#4d7c0f',
    800: '#3f6212',
    900: '#365314',
  },
  sky: {
    50: '#f0f9ff',
    100: '#e0f2fe',
    200: '#bae6fd',
    300: '#7dd3fc',
    400: '#38bdf8',
    500: '#0ea5e9',
    600: '#0284c7',
    700: '#0369a1',
    800: '#075985',
    900: '#0c4a6e',
  },
};

// Font family names (loaded via @expo-google-fonts/nunito)
export const fonts = {
  light: 'Nunito_300Light',
  regular: 'Nunito_400Regular',
  medium: 'Nunito_500Medium',
  semibold: 'Nunito_600SemiBold',
  bold: 'Nunito_700Bold',
  extrabold: 'Nunito_800ExtraBold',
} as const;

// Typography scale
export const typography = {
  // =========================================================================
  // FONT SIZES - Minimum 13px for accessibility and readability
  // =========================================================================
  fontSizes: {
    xs: 13,      // Was 12 - minimum readable size (captions, timestamps)
    sm: 14,      // Secondary text, button labels
    base: 16,    // Body text, inputs
    lg: 18,      // Subheadings, card titles
    xl: 20,      // Section titles
    '2xl': 24,   // Screen titles
    '3xl': 30,   // Large headings
    '4xl': 36,   // Hero text
    '5xl': 48,   // Extra large display
  },

  // =========================================================================
  // FONT WEIGHTS - Clear hierarchy
  // =========================================================================
  fontWeights: {
    light: '300' as const,     // Decorative use only
    regular: '400' as const,   // Body text
    normal: '400' as const,    // Alias for regular
    medium: '500' as const,    // Labels, secondary emphasis
    semibold: '600' as const,  // Subheadings, buttons, card titles
    bold: '700' as const,      // Section titles, emphasis
    extrabold: '800' as const, // Hero text, display headings, screen titles
  },

  // =========================================================================
  // LINE HEIGHTS - Comfortable reading
  // =========================================================================
  lineHeights: {
    none: 1,        // Single line items
    tight: 1.2,     // Headings
    snug: 1.375,    // Compact text
    normal: 1.5,    // Body text (default)
    relaxed: 1.625, // Long-form text
    loose: 2,       // Extra spacing
  },

  // =========================================================================
  // LETTER SPACING - Elegance and readability
  // =========================================================================
  letterSpacing: {
    tighter: -0.5,   // Large display text (36px+)
    tight: -0.25,    // Headings (24px+)
    normal: 0,       // Body text
    wide: 0.25,      // Buttons, labels
    wider: 0.5,      // Small caps
    widest: 1.5,     // UPPERCASE LABELS
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

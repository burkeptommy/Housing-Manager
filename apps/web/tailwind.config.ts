import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    '../../packages/ui/src/**/*.{js,ts,jsx,tsx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // PRIMARY: Deep Navy - established, trustworthy, premium
        haven: {
          50: '#F5F7FA',
          100: '#E8ECF2',
          200: '#CBD5E1',
          300: '#94A3B8',
          400: '#64748B',
          500: '#475569',
          600: '#334155',
          700: '#1E2A3B',
          800: '#172032',
          900: '#111827',
          950: '#0B1120',
        },
        // Alias for onboarding pages
        'haven-navy': {
          50: '#F5F7FA',
          100: '#E8ECF2',
          200: '#CBD5E1',
          300: '#94A3B8',
          400: '#64748B',
          500: '#475569',
          600: '#334155',
          700: '#1E2A3B',
          800: '#172032',
          900: '#102a43',
          950: '#0a1929',
        },
        // ACCENT: Champagne - warm elegance, subtle luxury
        champagne: {
          50: '#FAF8F5',
          100: '#F5F0E8',
          200: '#E8E0D0',
          300: '#D4C5A9',
          400: '#C4B393',
          500: '#A89968',
          600: '#8C7D4E',
          700: '#6B5D3A',
          800: '#4A4028',
          900: '#2E2819',
        },
        // Alias for onboarding pages
        'haven-champagne': {
          50: '#faf6ed',
          100: '#faf6ed',
          200: '#E8E0D0',
          300: '#D4C5A9',
          400: '#d4c4a5',
          500: '#c4a574',
          600: '#b08d5b',
          700: '#6B5D3A',
          800: '#4A4028',
          900: '#2E2819',
        },
        // NEUTRALS: Warm grays
        warm: {
          50: '#FAFAF9',
          100: '#F5F5F4',
          200: '#E7E5E4',
          300: '#D6D3D1',
          400: '#A8A29E',
          500: '#78716C',
          600: '#57534E',
          700: '#44403C',
          800: '#292524',
          900: '#1C1917',
          950: '#0C0A09',
        },
        // Keep gold for premium badges
        gold: {
          50: '#FDFBF3',
          100: '#FBF5E1',
          200: '#F6E9C3',
          300: '#EFD89C',
          400: '#E5C06D',
          500: '#DBA844',
          600: '#C48C33',
          700: '#A36D2B',
          800: '#855729',
          900: '#6D4825',
          950: '#3D2512',
        },
      },
      fontFamily: {
        serif: ['Playfair Display', 'Georgia', 'serif'],
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
      boxShadow: {
        'soft': '0 2px 8px rgba(0, 0, 0, 0.04), 0 4px 24px rgba(0, 0, 0, 0.04)',
        'soft-lg': '0 4px 12px rgba(0, 0, 0, 0.05), 0 8px 32px rgba(0, 0, 0, 0.05)',
        'soft-xl': '0 8px 24px rgba(0, 0, 0, 0.08), 0 16px 48px rgba(0, 0, 0, 0.06)',
        'glow': '0 0 24px rgba(30, 42, 59, 0.15)',
        'glow-champagne': '0 0 24px rgba(212, 197, 169, 0.25)',
        'inner-light': 'inset 0 1px 0 rgba(255, 255, 255, 0.1)',
      },
      animation: {
        'fade-in': 'fadeIn 0.4s ease-out',
        'fade-in-up': 'fadeInUp 0.5s ease-out',
        'slide-in-right': 'slideInRight 0.3s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
        'shimmer': 'shimmer 2s infinite linear',
        'pulse-soft': 'pulseSoft 2s infinite',
        'bounce-soft': 'bounceSoft 0.5s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        fadeInUp: {
          '0%': { opacity: '0', transform: 'translateY(16px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        slideInRight: {
          '0%': { opacity: '0', transform: 'translateX(-16px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        scaleIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.6' },
        },
        bounceSoft: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-4px)' },
        },
      },
      backgroundImage: {
        'gradient-radial': 'radial-gradient(var(--tw-gradient-stops))',
        'shimmer': 'linear-gradient(90deg, transparent 0%, rgba(255,255,255,0.4) 50%, transparent 100%)',
      },
    },
  },
  plugins: [],
};

export default config;

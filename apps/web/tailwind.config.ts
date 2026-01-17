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
        // ACCENT: Sage Green - natural, grounded, calm
        sage: {
          50: '#F4F6F2',
          100: '#E8EDE4',
          200: '#D1DBC9',
          300: '#A4B494',
          400: '#8FA37F',
          500: '#7D8E74',
          600: '#6B7A63',
          700: '#5A6853',
          800: '#4A5544',
          900: '#3B4536',
        },
        // Alias for onboarding/app pages
        'haven-sage': {
          50: '#F4F6F2',
          100: '#E8EDE4',
          200: '#D1DBC9',
          300: '#A4B494',
          400: '#8FA37F',
          500: '#7D8E74',
          600: '#6B7A63',
          700: '#5A6853',
          800: '#4A5544',
          900: '#3B4536',
        },
        // Card backgrounds
        cream: {
          50: '#FEFDFB',
          100: '#FAFAF7',
          200: '#F5F4F0',
        },
        // Legacy alias for compatibility (maps to sage)
        champagne: {
          50: '#F4F6F2',
          100: '#E8EDE4',
          200: '#D1DBC9',
          300: '#A4B494',
          400: '#8FA37F',
          500: '#7D8E74',
          600: '#6B7A63',
          700: '#5A6853',
          800: '#4A5544',
          900: '#3B4536',
        },
        // Legacy alias for onboarding pages (maps to sage)
        'haven-champagne': {
          50: '#F4F6F2',
          100: '#E8EDE4',
          200: '#D1DBC9',
          300: '#A4B494',
          400: '#8FA37F',
          500: '#7D8E74',
          600: '#6B7A63',
          700: '#5A6853',
          800: '#4A5544',
          900: '#3B4536',
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
        serif: ['var(--font-playfair)', 'Playfair Display', 'Georgia', 'serif'],
        sans: ['var(--font-inter)', 'Inter', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
      fontSize: {
        'display-2xl': ['4.5rem', { lineHeight: '1.1', letterSpacing: '-0.03em' }],
        'display-xl': ['3.75rem', { lineHeight: '1.1', letterSpacing: '-0.025em' }],
        'display-lg': ['3rem', { lineHeight: '1.15', letterSpacing: '-0.02em' }],
        'display-md': ['2.25rem', { lineHeight: '1.2', letterSpacing: '-0.015em' }],
        'display-sm': ['1.875rem', { lineHeight: '1.25', letterSpacing: '-0.01em' }],
      },
      boxShadow: {
        'soft': '0 2px 8px rgba(0, 0, 0, 0.04), 0 4px 24px rgba(0, 0, 0, 0.04)',
        'soft-lg': '0 4px 12px rgba(0, 0, 0, 0.05), 0 8px 32px rgba(0, 0, 0, 0.05)',
        'soft-xl': '0 8px 24px rgba(0, 0, 0, 0.08), 0 16px 48px rgba(0, 0, 0, 0.06)',
        'glow': '0 0 24px rgba(30, 42, 59, 0.15)',
        'glow-sage': '0 0 24px rgba(125, 142, 116, 0.25)',
        'inner-light': 'inset 0 1px 0 rgba(255, 255, 255, 0.1)',
        'elegant': '0 1px 2px rgba(11, 17, 32, 0.04), 0 4px 8px rgba(11, 17, 32, 0.04), 0 8px 16px rgba(11, 17, 32, 0.02)',
        'elegant-lg': '0 2px 4px rgba(11, 17, 32, 0.02), 0 8px 16px rgba(11, 17, 32, 0.06), 0 16px 32px rgba(11, 17, 32, 0.04)',
        'elegant-xl': '0 4px 8px rgba(11, 17, 32, 0.02), 0 16px 32px rgba(11, 17, 32, 0.08), 0 32px 64px rgba(11, 17, 32, 0.04)',
        'card-hover': '0 12px 32px rgba(11, 17, 32, 0.12)',
      },
      animation: {
        'fade-in': 'fadeIn 0.4s ease-out',
        'fade-in-up': 'fadeInUp 0.5s ease-out',
        'slide-in-right': 'slideInRight 0.3s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
        'shimmer': 'shimmer 2s infinite linear',
        'pulse-soft': 'pulseSoft 2s infinite',
        'bounce-soft': 'bounceSoft 0.5s ease-out',
        'float': 'float 6s ease-in-out infinite',
        'float-slow': 'float 8s ease-in-out infinite',
        'reveal-up': 'revealUp 0.7s cubic-bezier(0.16, 1, 0.3, 1) forwards',
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
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-12px)' },
        },
        revealUp: {
          '0%': { opacity: '0', transform: 'translateY(24px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
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

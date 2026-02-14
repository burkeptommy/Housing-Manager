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
        haven: {
          50: '#F9F5FF',
          100: '#EDE7F6',
          200: '#D1B3FF',
          300: '#B388FF',
          400: '#7C4DFF',
          500: '#6200EA',
          600: '#5500D4',
          700: '#4A00B4',
          800: '#3D008F',
          900: '#2D006B',
          950: '#1A0044',
        },
        coral: {
          50: '#FFF0F0',
          100: '#FFE0E0',
          400: '#FF8A8A',
          500: '#FF6B6B',
          600: '#E85555',
        },
        neutral: {
          50: '#F9FAFB',
          100: '#F3F4F6',
          200: '#E5E7EB',
          300: '#D1D5DB',
          400: '#9CA3AF',
          500: '#6B7280',
          600: '#4B5563',
          700: '#374151',
          800: '#1F2937',
          900: '#1A1A2E',
          950: '#0F0F1E',
        },
      },
      fontFamily: {
        sans: ['var(--font-nunito)', 'Nunito', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
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
        'glow': '0 0 24px rgba(98, 0, 234, 0.15)',
        'glow-purple': '0 0 24px rgba(98, 0, 234, 0.25)',
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

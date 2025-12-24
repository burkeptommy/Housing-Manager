# Haven Complete Rebrand: Navy + Champagne

## Brand Identity Update

**Old:** Bright green (#4a9a4a) - "Tech startup"
**New:** Deep navy (#1E2A3B) - "Private banking, established trust"

### Final Color Palette

```
Primary (Navy):
  haven-50:  #F5F7FA  (backgrounds)
  haven-100: #E8ECF2  (hover states, subtle bg)
  haven-200: #CBD5E1  (borders, disabled)
  haven-300: #94A3B8  (placeholder text)
  haven-400: #64748B  (secondary text)
  haven-500: #475569  (body text on light)
  haven-600: #334155  (headings, links)
  haven-700: #1E2A3B  (PRIMARY - buttons, headers)
  haven-800: #172032  (hover/active states)
  haven-900: #111827  (darkest, dark mode bg)
  
Accent (Champagne):
  champagne-50:  #FAF8F5  (very light backgrounds)
  champagne-100: #F5F0E8  (light tint, subtle)
  champagne-200: #E8E0D0  (badges, highlights)
  champagne-300: #D4C5A9  (PRIMARY ACCENT)
  champagne-400: #C4B393  (slightly darker)
  champagne-500: #A89968  (text on dark)
  champagne-600: #8C7D4E  (dark text)

Neutrals (Warm):
  warm-50:  #FAFAF9  (page background)
  warm-100: #F5F5F4  (section backgrounds)
  warm-200: #E7E5E4  (borders)
  warm-300: #D6D3D1  (disabled)
  warm-400: #A8A29E  (placeholder)
  warm-500: #78716C  (secondary text)
  warm-600: #57534E  (body text)
  warm-700: #44403C  (headings)
  warm-800: #292524  (dark headings)
  warm-900: #1C1917  (darkest)
```

---

## TASK 1: Update Tailwind Config

Replace the entire `apps/web/tailwind.config.ts` file with:

```typescript
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
```

---

## TASK 2: Update globals.css

Replace the entire `apps/web/src/app/globals.css` file with this updated version. Key changes:
- Remove forest color references
- Update gradients to use navy
- Update focus rings to use navy
- Update component classes

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Playfair+Display:wght@400;500;600;700&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    scroll-behavior: smooth;
  }

  body {
    @apply font-sans text-warm-800 bg-warm-50;
    font-feature-settings: 'cv02', 'cv03', 'cv04', 'cv11';
  }

  .dark body {
    @apply bg-warm-900 text-warm-100;
  }

  /* ONLY h1 gets serif font - main page titles only */
  h1 {
    @apply font-serif tracking-tight text-warm-900;
  }

  /* All other headings use sans-serif */
  h2, h3, h4, h5, h6 {
    @apply font-sans font-semibold tracking-tight text-warm-900;
  }

  .dark h1, .dark h2, .dark h3, .dark h4, .dark h5, .dark h6 {
    @apply text-warm-50;
  }

  ::selection {
    @apply bg-haven-200 text-haven-900;
  }

  ::-webkit-scrollbar {
    width: 8px;
    height: 8px;
  }

  ::-webkit-scrollbar-track {
    @apply bg-transparent;
  }

  ::-webkit-scrollbar-thumb {
    @apply bg-warm-300 rounded-full;
  }

  ::-webkit-scrollbar-thumb:hover {
    @apply bg-warm-400;
  }

  input, textarea, select {
    @apply font-sans;
  }

  *:focus {
    outline: none;
  }

  *:focus-visible {
    @apply ring-2 ring-haven-500/30 ring-offset-2;
  }
}

@layer components {
  /* Cards */
  .card {
    @apply bg-white rounded-2xl border border-warm-200 shadow-soft p-6 transition-all duration-300;
  }

  .dark .card {
    @apply bg-warm-800 border-warm-700;
  }

  .card-hover {
    @apply hover:shadow-soft-lg hover:border-warm-300 hover:-translate-y-0.5;
  }

  .card-interactive {
    @apply card card-hover cursor-pointer active:scale-[0.99];
  }

  /* Page title - serif only for main page headings */
  .page-title {
    @apply font-serif text-2xl sm:text-3xl font-bold text-warm-900;
  }

  /* Navy gradient cards - white text */
  .card-navy {
    @apply bg-gradient-to-br from-haven-700 to-haven-800 rounded-2xl border-0 text-white;
  }

  .card-navy h1,
  .card-navy h2,
  .card-navy h3,
  .card-navy h4,
  .card-navy .card-title,
  .card-navy .stat-value {
    @apply text-white;
  }

  .card-navy p,
  .card-navy .card-description,
  .card-navy .stat-label {
    @apply text-white/80;
  }

  /* Dark charcoal cards - white text */
  .card-dark {
    @apply bg-gradient-to-br from-warm-800 to-warm-900 rounded-2xl border-0 text-white;
  }

  .card-dark h1,
  .card-dark h2,
  .card-dark h3,
  .card-dark h4,
  .card-dark .card-title,
  .card-dark .stat-value {
    @apply text-white;
  }

  .card-dark p,
  .card-dark .card-description,
  .card-dark .stat-label {
    @apply text-white/70;
  }

  /* Champagne accent card */
  .card-champagne {
    @apply bg-gradient-to-br from-champagne-100 to-champagne-200 rounded-2xl border border-champagne-300;
  }

  /* Sidebar styles */
  .sidebar {
    @apply bg-gradient-to-b from-haven-800 to-haven-900;
  }

  .sidebar-nav-item {
    @apply flex items-center gap-3 px-4 py-3 rounded-xl font-medium
           text-white/70 transition-all duration-200
           hover:bg-white/10 hover:text-white;
  }

  .sidebar-nav-item-active {
    @apply bg-white/15 text-white;
  }

  /* Button variants */
  .btn {
    @apply inline-flex items-center justify-center gap-2 font-medium rounded-xl
           transition-all duration-200 active:scale-[0.98]
           disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100;
  }

  .btn-primary {
    @apply btn px-5 py-2.5 bg-haven-700 text-white
           shadow-[0_1px_2px_rgba(0,0,0,0.1),0_2px_4px_rgba(0,0,0,0.1)]
           hover:bg-haven-800 hover:shadow-[0_2px_4px_rgba(0,0,0,0.15),0_4px_8px_rgba(0,0,0,0.1)];
  }

  .btn-secondary {
    @apply btn px-5 py-2.5 bg-white text-warm-700 border border-warm-200
           shadow-sm hover:bg-warm-50 hover:border-warm-300 hover:text-warm-900;
  }

  .dark .btn-secondary {
    @apply bg-warm-800 text-warm-200 border-warm-600 hover:bg-warm-700 hover:text-warm-100;
  }

  .btn-ghost {
    @apply btn px-4 py-2 text-warm-600 hover:bg-warm-100 hover:text-warm-900;
  }

  .dark .btn-ghost {
    @apply text-warm-400 hover:bg-warm-800 hover:text-warm-100;
  }

  .btn-danger {
    @apply btn px-5 py-2.5 bg-red-600 text-white
           shadow-[0_1px_2px_rgba(0,0,0,0.1)]
           hover:bg-red-700;
  }

  .btn-white {
    @apply btn px-5 py-2.5 bg-white text-haven-700 shadow-lg hover:bg-champagne-50;
  }

  .btn-outline-light {
    @apply btn px-5 py-2.5 bg-transparent text-white border border-white/30 hover:bg-white/10;
  }

  .btn-ghost-light {
    @apply btn px-4 py-2 text-white/70 hover:bg-white/10 hover:text-white;
  }

  .btn-sm {
    @apply px-3 py-1.5 text-sm rounded-lg gap-1.5;
  }

  .btn-lg {
    @apply px-6 py-3 text-base rounded-xl gap-2.5;
  }

  /* Inputs */
  .input {
    @apply w-full px-4 py-3 bg-white border border-warm-200 rounded-xl
           text-warm-800 placeholder:text-warm-400
           transition-all duration-200
           hover:border-warm-300
           focus:border-haven-600 focus:ring-2 focus:ring-haven-600/20;
  }

  .dark .input {
    @apply bg-warm-800 border-warm-600 text-warm-100 placeholder:text-warm-500
           hover:border-warm-500 focus:border-haven-400;
  }

  .input-error {
    @apply border-red-300 focus:border-red-500 focus:ring-red-500/20;
  }

  /* Badges */
  .badge {
    @apply inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium;
  }

  .badge-success {
    @apply bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/20;
  }

  .badge-warning {
    @apply bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20;
  }

  .badge-error {
    @apply bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20;
  }

  .badge-info {
    @apply bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20;
  }

  .badge-neutral {
    @apply bg-warm-100 text-warm-700 ring-1 ring-inset ring-warm-600/10;
  }

  .badge-premium {
    @apply bg-gradient-to-r from-champagne-100 to-champagne-200 text-champagne-700
           ring-1 ring-inset ring-champagne-400/30;
  }

  .badge-navy {
    @apply bg-haven-100 text-haven-700 ring-1 ring-inset ring-haven-600/20;
  }

  .badge-light {
    @apply bg-white/20 text-white;
  }

  /* Avatars */
  .avatar {
    @apply relative inline-flex items-center justify-center rounded-full
           bg-gradient-to-br from-haven-600 to-haven-700 text-white font-semibold
           ring-2 ring-white shadow-sm;
  }

  .avatar-sm { @apply w-8 h-8 text-xs; }
  .avatar-md { @apply w-10 h-10 text-sm; }
  .avatar-lg { @apply w-12 h-12 text-base; }
  .avatar-xl { @apply w-16 h-16 text-lg; }
  .avatar-2xl { @apply w-24 h-24 text-2xl; }

  /* Status Dots */
  .status-dot {
    @apply absolute bottom-0 right-0 w-3 h-3 rounded-full ring-2 ring-white;
  }

  .status-online { @apply bg-emerald-500; }
  .status-offline { @apply bg-warm-400; }
  .status-busy { @apply bg-red-500; }
  .status-away { @apply bg-amber-500; }

  /* Skeleton Loaders */
  .skeleton {
    @apply bg-gradient-to-r from-warm-100 via-warm-50 to-warm-100
           bg-[length:200%_100%] animate-shimmer rounded-lg;
  }

  /* Page Layout */
  .page-container {
    @apply max-w-7xl mx-auto px-4 sm:px-6 lg:px-8;
  }

  /* Nav Items */
  .nav-item {
    @apply flex items-center gap-3 px-4 py-3 rounded-xl font-medium
           text-warm-600 transition-all duration-200
           hover:bg-warm-100 hover:text-warm-900;
  }

  .dark .nav-item {
    @apply text-warm-400 hover:bg-warm-800 hover:text-warm-100;
  }

  .nav-item-active {
    @apply bg-haven-50 text-haven-700 hover:bg-haven-100;
  }

  .dark .nav-item-active {
    @apply bg-haven-900/30 text-haven-400 hover:bg-haven-900/40;
  }

  /* Stat Cards */
  .stat-card {
    @apply card;
  }

  .stat-value {
    @apply text-3xl font-bold text-warm-900 font-serif tabular-nums;
  }

  .dark .stat-value {
    @apply text-warm-50;
  }

  .stat-label {
    @apply text-sm text-warm-500 mt-1;
  }

  /* Tables */
  .table-container {
    @apply overflow-x-auto rounded-xl border border-warm-200;
  }

  .dark .table-container {
    @apply border-warm-700;
  }

  .table {
    @apply w-full text-sm;
  }

  .table th {
    @apply px-4 py-3 text-left text-xs font-semibold text-warm-500 uppercase tracking-wider bg-warm-50 border-b border-warm-200;
  }

  .dark .table th {
    @apply bg-warm-800 text-warm-400 border-warm-700;
  }

  .table td {
    @apply px-4 py-4 border-b border-warm-100;
  }

  .dark .table td {
    @apply border-warm-700;
  }

  .table tr:last-child td {
    @apply border-b-0;
  }

  .table tr:hover td {
    @apply bg-warm-50/50;
  }

  .dark .table tr:hover td {
    @apply bg-warm-800/50;
  }

  /* Empty States */
  .empty-state {
    @apply text-center py-16 px-8;
  }

  .empty-state-icon {
    @apply w-16 h-16 rounded-2xl bg-warm-100 flex items-center justify-center mx-auto mb-4;
  }

  .dark .empty-state-icon {
    @apply bg-warm-800;
  }

  /* Modals */
  .modal-overlay {
    @apply fixed inset-0 bg-warm-900/40 backdrop-blur-sm z-50
           flex items-center justify-center p-4;
  }

  .modal {
    @apply bg-white rounded-2xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-hidden
           animate-scale-in;
  }

  .dark .modal {
    @apply bg-warm-800;
  }

  .modal-header {
    @apply px-6 py-4 border-b border-warm-200;
  }

  .dark .modal-header {
    @apply border-warm-700;
  }

  .modal-body {
    @apply px-6 py-4 overflow-y-auto;
  }

  .modal-footer {
    @apply px-6 py-4 border-t border-warm-200 flex items-center justify-end gap-3;
  }

  .dark .modal-footer {
    @apply border-warm-700;
  }

  /* Label */
  .label {
    @apply text-sm font-medium text-warm-700;
  }

  .dark .label {
    @apply text-warm-300;
  }
}

@layer utilities {
  .text-gradient {
    @apply bg-clip-text text-transparent bg-gradient-to-r from-haven-700 to-haven-600;
  }

  .text-gradient-champagne {
    @apply bg-clip-text text-transparent bg-gradient-to-r from-champagne-500 to-champagne-400;
  }

  /* Staggered animations */
  .stagger-1 { animation-delay: 50ms; }
  .stagger-2 { animation-delay: 100ms; }
  .stagger-3 { animation-delay: 150ms; }
  .stagger-4 { animation-delay: 200ms; }
  .stagger-5 { animation-delay: 250ms; }

  /* Hide scrollbar */
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }

  .no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .no-scrollbar::-webkit-scrollbar {
    display: none;
  }

  /* Glass effect */
  .glass {
    @apply bg-white/70 backdrop-blur-xl border border-white/20;
  }

  .dark .glass {
    @apply bg-warm-900/70;
  }
}

/* Typography */
.font-serif {
  font-family: 'Playfair Display', Georgia, serif;
}

h1.page-title,
.page-title {
  font-family: 'Playfair Display', Georgia, serif;
}

body, h2, h3, h4, h5, h6, p, span, div, a, button, input, textarea, select, label {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.font-serif {
  font-family: 'Playfair Display', Georgia, serif !important;
}

/* Mapbox Popup Styles */
.mapboxgl-popup-content {
  padding: 0 !important;
  border-radius: 12px !important;
  overflow: hidden !important;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15) !important;
}

.mapboxgl-popup-close-button {
  font-size: 20px !important;
  padding: 8px 10px !important;
  color: #666 !important;
  right: 0 !important;
  top: 0 !important;
  z-index: 10 !important;
  background: white !important;
  border-radius: 0 12px 0 8px !important;
}

.mapboxgl-popup-close-button:hover {
  background: #f5f5f4 !important;
  color: #333 !important;
}

.mapboxgl-popup-tip {
  display: none !important;
}
```

---

## TASK 3: Create Navbar Component

Create `apps/web/src/components/marketing/Navbar.tsx`:

```tsx
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Menu, X } from 'lucide-react';

export function Navbar() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { href: '#how-it-works', label: 'How It Works' },
    { href: '#services', label: 'Services' },
    { href: '#pricing', label: 'Pricing' },
    { href: '#faq', label: 'FAQ' },
  ];

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled
          ? 'bg-white/95 backdrop-blur-md shadow-sm border-b border-warm-100'
          : 'bg-transparent'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 lg:h-20">
          {/* Logo */}
          <Link href="/" className="flex items-center">
            <span className={`text-2xl font-bold tracking-tight transition-colors ${
              isScrolled ? 'text-haven-700' : 'text-white'
            }`}>
              Haven
            </span>
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden lg:flex items-center gap-8">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className={`text-sm font-medium transition-colors ${
                  isScrolled 
                    ? 'text-warm-600 hover:text-haven-700' 
                    : 'text-white/90 hover:text-white'
                }`}
              >
                {link.label}
              </a>
            ))}
          </div>

          {/* Desktop CTA */}
          <div className="hidden lg:flex items-center gap-4">
            <Link
              href="/login"
              className={`text-sm font-medium transition-colors ${
                isScrolled ? 'text-warm-600 hover:text-haven-700' : 'text-white/90 hover:text-white'
              }`}
            >
              Sign In
            </Link>
            <Link
              href="/register"
              className={`px-5 py-2.5 text-sm font-semibold rounded-xl transition-all ${
                isScrolled
                  ? 'bg-haven-700 text-white hover:bg-haven-800 shadow-sm hover:shadow-md'
                  : 'bg-white text-haven-700 hover:bg-champagne-50 shadow-lg shadow-black/10'
              }`}
            >
              Get Started
            </Link>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className={`lg:hidden p-2 rounded-lg transition-colors ${
              isScrolled ? 'text-warm-700 hover:bg-warm-100' : 'text-white hover:bg-white/10'
            }`}
            aria-label="Toggle menu"
          >
            {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isMobileMenuOpen && (
          <div className="lg:hidden bg-white border-t border-warm-100 py-4 shadow-lg">
            <div className="flex flex-col gap-1">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50 transition-colors"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  {link.label}
                </a>
              ))}
              <div className="border-t border-warm-100 mt-2 pt-2 px-2">
                <Link
                  href="/login"
                  className="block px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50 transition-colors"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Sign In
                </Link>
                <Link
                  href="/register"
                  className="block mt-2 px-4 py-3 bg-haven-700 text-white font-semibold rounded-xl text-center hover:bg-haven-800 transition-colors"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Get Started
                </Link>
              </div>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}
```

Also create the directory if it doesn't exist:
```bash
mkdir -p apps/web/src/components/marketing
```

---

## TASK 4: Update Homepage (page.tsx)

The homepage at `apps/web/src/app/page.tsx` needs comprehensive updates. Here are the key color mappings:

### Color Replacement Guide for Homepage

| Old (Green) | New (Navy) |
|-------------|------------|
| `haven-600` | `haven-700` |
| `haven-700` | `haven-800` |
| `haven-500` | `haven-600` |
| `haven-100` | `haven-100` |
| `haven-50` | `haven-50` |
| `from-haven-600 via-haven-700 to-haven-800` | `from-haven-700 via-haven-800 to-haven-900` |
| `text-haven-600` | `text-haven-700` |
| `bg-haven-600` | `bg-haven-700` |
| `hover:bg-haven-700` | `hover:bg-haven-800` |
| `border-haven-500` | `border-haven-600` |
| `text-amber-*` | `text-champagne-*` |
| `bg-amber-*` | `bg-champagne-*` |

### Specific Section Updates

**Hero Section:**
```tsx
<section className="relative overflow-hidden bg-gradient-to-br from-haven-700 via-haven-800 to-haven-900 pt-24 sm:pt-32 pb-16 sm:pb-24">
  {/* Background decoration */}
  <div className="absolute inset-0 overflow-hidden pointer-events-none">
    <div className="absolute -top-40 -right-40 w-96 h-96 bg-haven-600 rounded-full blur-3xl opacity-20" />
    <div className="absolute top-1/2 -left-20 w-72 h-72 bg-champagne-300/20 rounded-full blur-3xl opacity-30" />
    <div className="absolute bottom-0 right-1/4 w-64 h-64 bg-haven-500 rounded-full blur-3xl opacity-15" />
  </div>
```

**Accent text:** `text-champagne-300` (on dark backgrounds)

**Primary CTA on dark:** `bg-white text-haven-700 hover:bg-champagne-50`

**Secondary CTA on dark:** `border-2 border-white/30 text-white hover:bg-white/10`

**Checkmarks on dark:** `text-champagne-300`

**"With Haven" card:**
```tsx
<div className="bg-gradient-to-br from-haven-700 to-haven-800 rounded-2xl p-6 text-white">
```

**Stat highlight bar:**
```tsx
<div className="inline-flex items-center gap-3 px-6 py-3 bg-champagne-100 rounded-full">
  <Clock className="w-5 h-5 text-champagne-600" />
  <p className="text-lg font-semibold text-champagne-600">
```

**Step icon colors:**
- Step 1: `bg-haven-100 text-haven-700`
- Step 2: `bg-champagne-200 text-champagne-600`
- Step 3: `bg-blue-100 text-blue-600`

**Service card accent bars:**
- Bill Management: `bg-haven-600`
- Home Maintenance: `bg-blue-500`
- Vendor Coordination: `bg-purple-500`
- Life Management: `bg-champagne-400`

**Handyman section:**
```tsx
<section className="py-16 sm:py-24 bg-gradient-to-br from-warm-900 via-warm-800 to-warm-900 text-white relative overflow-hidden">
```
- Label: `text-champagne-300`
- Heading: `text-white`
- Checkmarks: `text-champagne-300`
- Avatar: `bg-gradient-to-br from-champagne-300 to-champagne-400 text-warm-800`

**Pricing cards accent bars:**
- Essentials: `bg-warm-300`
- Lite: `bg-gradient-to-r from-haven-600 to-haven-700`
- Haven: `bg-champagne-400`

**Most Popular badge:**
```tsx
<span className="px-4 py-1.5 bg-gradient-to-r from-haven-700 to-haven-800 text-white text-sm font-semibold rounded-full shadow-lg">
```

**Compare Plans section:**
```tsx
<section className="py-16 sm:py-24 bg-haven-900 text-white">
```
- Table: `bg-haven-800`
- Lite column: `bg-haven-700/30` with `text-champagne-300`

**Testimonials section:**
```tsx
<section className="py-16 sm:py-24 bg-gradient-to-b from-champagne-50 to-champagne-100/50">
```

**Final CTA:**
```tsx
<section className="py-16 sm:py-24 bg-gradient-to-br from-haven-700 via-haven-800 to-haven-900 relative overflow-hidden">
```
- Highlight text: `text-champagne-300`
- Primary CTA: `bg-white text-haven-700 hover:bg-champagne-50`

**Footer:**
```tsx
<footer className="bg-haven-900 text-white py-12">
```

---

## TASK 5: Update Remaining App Files

Search through all files in the app and update haven color references. Key directories:

- `apps/web/src/app/app/*` - Main application pages
- `apps/web/src/app/admin/*` - Admin pages
- `apps/web/src/app/manager/*` - Manager portal
- `apps/web/src/app/vendor/*` - Vendor portal
- `apps/web/src/app/handyman/*` - Handyman portal
- `apps/web/src/app/internal/*` - Internal tools
- `apps/web/src/components/*` - Shared components

### Global Search/Replace Commands

Run these search/replace operations across all .tsx files:

```
Find: haven-600
Replace: haven-700

Find: haven-700
Replace: haven-800

Find: hover:bg-haven-700
Replace: hover:bg-haven-800

Find: from-haven-500 to-haven-600
Replace: from-haven-600 to-haven-700

Find: from-haven-600 to-haven-700
Replace: from-haven-700 to-haven-800

Find: text-haven-600
Replace: text-haven-700

Find: bg-haven-600
Replace: bg-haven-700

Find: border-haven-500
Replace: border-haven-600

Find: ring-haven-500
Replace: ring-haven-600

Find: forest-
Replace: haven-
(for any remaining forest color references)
```

### Important Notes

1. **Don't replace haven-50, haven-100, haven-200** - these light tints work with navy
2. **Check gradients carefully** - ensure from/via/to progression makes sense
3. **Dark backgrounds** - use haven-800 or haven-900 instead of haven-600/700
4. **Text on dark** - use white or champagne-300
5. **Accents** - use champagne instead of amber/gold where appropriate

---

## TASK 6: Remove Em Dashes

Search entire codebase for `—` and `–` and replace appropriately:

```
Find: —
Replace: (context-dependent: comma, period, "to", or remove)

Find: –
Replace: (usually "to" for ranges)
```

---

## TASK 7: Verification Checklist

After all changes:

- [ ] Tailwind config has new navy haven palette
- [ ] globals.css updated with navy references
- [ ] Navbar component created and working
- [ ] Homepage uses navy + champagne palette
- [ ] No bright green (#4a9a4a or similar) visible anywhere
- [ ] No em dashes in any user-facing text
- [ ] Dark sections use haven-800/900 or warm-800/900
- [ ] Accent highlights use champagne-300
- [ ] CTAs on dark backgrounds are white with champagne hover
- [ ] All pages load without errors

---

## TASK 8: Build and Deploy

```bash
# Build to check for errors
pnpm build

# Test locally
pnpm dev

# Check for any remaining green references
grep -r "haven-500\|haven-600" apps/web/src --include="*.tsx" | head -20

# Commit
git add .
git commit -m "Complete rebrand: Navy + Champagne color palette, add navigation"

# Push
git push origin main
```

---

## Quick Reference: Button Styles

```tsx
// Primary on light background
className="bg-haven-700 text-white hover:bg-haven-800"

// Primary on dark background  
className="bg-white text-haven-700 hover:bg-champagne-50"

// Secondary
className="bg-white text-warm-700 border border-warm-200 hover:bg-warm-50"

// Ghost on dark
className="border-2 border-white/30 text-white hover:bg-white/10"
```

## Quick Reference: Background Sections

```tsx
// Light section
className="bg-white" or "bg-warm-50"

// Champagne tinted section
className="bg-gradient-to-b from-champagne-50 to-champagne-100/50"

// Navy section
className="bg-gradient-to-br from-haven-700 via-haven-800 to-haven-900"

// Dark charcoal section
className="bg-gradient-to-br from-warm-800 via-warm-900 to-warm-900"

// Navy for tables/compare
className="bg-haven-900" with table "bg-haven-800"
```

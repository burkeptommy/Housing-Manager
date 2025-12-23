# 🏠 HAVEN PLATFORM - ULTIMATE BUILD & DESIGN OVERHAUL

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this entire prompt or run:
```bash
cat HAVEN_ULTIMATE_BUILD.md | claude --dangerously-skip-permissions
```

---

## MISSION

Transform Haven into the most beautiful home management platform ever built. This is a luxury service democratized for everyone. The design must reflect premium quality while being warm and approachable.

**Design Philosophy:**
- **Elegant Simplicity** - Clean, uncluttered interfaces
- **Warm Sophistication** - Inviting, not cold corporate  
- **Deep Green Sidebar** - Rich forest green navigation, premium and luxurious
- **Attention to Detail** - Every pixel matters
- **Real Photography** - High-quality authentic imagery
- **Smooth Animations** - Subtle motion that delights

**Demo Credentials:**
| Role | Email | Password | Portal |
|------|-------|----------|--------|
| Manager | sarah@haven.app | Manager123! | /manager |
| Homeowner | bob@example.com | Bob123! | /app |
| Handyman | mike@haven.app | Handy123! | /handyman |
| Vendor | vendor@aceroofing.example.com | AceRoof123! | /vendor |

---

## PHASE 1: DESIGN SYSTEM FOUNDATION

### 1.1 Update Tailwind Config

**File:** `apps/web/tailwind.config.ts`

```typescript
import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Primary Brand - Sage Green
        haven: {
          50: '#f4f9f4',
          100: '#e6f2e6',
          200: '#cce5cc',
          300: '#a3d1a3',
          400: '#72b572',
          500: '#4a9a4a',
          600: '#3a7d3a',
          700: '#316331',
          800: '#2b502b',
          900: '#254225',
          950: '#102410',
        },
        // Deep Forest Green - For Sidebar (PREMIUM LOOK)
        forest: {
          50: '#f3f6f3',
          100: '#e4ebe4',
          200: '#c9d7c9',
          300: '#a3bba3',
          400: '#769676',
          500: '#587858',
          600: '#456145',
          700: '#394e39',
          800: '#2f402f',
          900: '#1e2d1e',  // Sidebar background
          950: '#0f180f',  // Darker accents
        },
        // Gold Accent - Premium touches
        gold: {
          50: '#fdfbf3',
          100: '#fbf5e1',
          200: '#f6e9c3',
          300: '#efd89c',
          400: '#e5c06d',
          500: '#dba844',
          600: '#c48c33',
          700: '#a36d2b',
          800: '#855729',
          900: '#6d4825',
          950: '#3d2512',
        },
        // Warm Neutrals - Content areas
        warm: {
          50: '#fafaf9',
          100: '#f5f5f4',
          200: '#e7e5e4',
          300: '#d6d3d1',
          400: '#a8a29e',
          500: '#78716c',
          600: '#57534e',
          700: '#44403c',
          800: '#292524',
          900: '#1c1917',
          950: '#0c0a09',
        },
      },
      fontFamily: {
        serif: ['Playfair Display', 'Georgia', 'serif'],
        sans: ['Inter', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'],
      },
      boxShadow: {
        'soft': '0 2px 8px rgba(0, 0, 0, 0.04), 0 4px 24px rgba(0, 0, 0, 0.04)',
        'soft-lg': '0 4px 12px rgba(0, 0, 0, 0.05), 0 8px 32px rgba(0, 0, 0, 0.05)',
        'glow': '0 0 24px rgba(74, 154, 74, 0.15)',
        'glow-gold': '0 0 24px rgba(219, 168, 68, 0.2)',
        'inner-light': 'inset 0 1px 0 rgba(255, 255, 255, 0.1)',
        'sidebar': '4px 0 24px rgba(0, 0, 0, 0.1)',
      },
      animation: {
        'fade-in': 'fadeIn 0.4s ease-out',
        'fade-in-up': 'fadeInUp 0.5s ease-out',
        'slide-in-right': 'slideInRight 0.3s ease-out',
        'scale-in': 'scaleIn 0.2s ease-out',
        'shimmer': 'shimmer 2s infinite linear',
        'pulse-soft': 'pulseSoft 2s infinite',
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
      },
    },
  },
  plugins: [],
};

export default config;
```

### 1.2 Global Styles

**File:** `apps/web/src/app/globals.css`

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
  
  h1, h2, h3, h4, h5, h6 {
    @apply font-serif text-warm-900 tracking-tight;
  }
  
  ::selection {
    @apply bg-haven-200 text-haven-900;
  }
  
  ::-webkit-scrollbar {
    width: 6px;
    height: 6px;
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
  
  /* Dark scrollbar for sidebar */
  .dark-scrollbar::-webkit-scrollbar-track {
    @apply bg-forest-950/50;
  }
  
  .dark-scrollbar::-webkit-scrollbar-thumb {
    @apply bg-forest-700 rounded-full;
  }
  
  *:focus {
    outline: none;
  }
  
  *:focus-visible {
    @apply ring-2 ring-haven-500/30 ring-offset-2;
  }
}

@layer components {
  /* ===== SIDEBAR STYLES (Deep Forest Green) ===== */
  .sidebar {
    @apply bg-forest-900 text-white;
  }
  
  .sidebar-header {
    @apply border-b border-white/10;
  }
  
  .sidebar-nav-item {
    @apply flex items-center gap-3 px-4 py-3 rounded-xl font-medium
           text-forest-200 transition-all duration-200
           hover:bg-white/10 hover:text-white;
  }
  
  .sidebar-nav-item-active {
    @apply bg-white/15 text-white;
  }
  
  .sidebar-nav-icon {
    @apply w-5 h-5 text-forest-400;
  }
  
  .sidebar-nav-item-active .sidebar-nav-icon {
    @apply text-haven-400;
  }
  
  .sidebar-section-title {
    @apply text-xs font-semibold text-forest-500 uppercase tracking-wider px-4 mb-2;
  }
  
  .sidebar-divider {
    @apply border-t border-white/10 my-4;
  }
  
  .sidebar-user {
    @apply flex items-center gap-3 p-4 border-t border-white/10;
  }
  
  .sidebar-badge {
    @apply ml-auto px-2 py-0.5 text-xs font-bold rounded-full bg-haven-500 text-white;
  }
  
  /* Property selector in sidebar */
  .sidebar-property-selector {
    @apply mx-4 p-3 rounded-xl bg-white/5 hover:bg-white/10 
           transition-colors cursor-pointer border border-white/10;
  }
  
  /* ===== CARDS ===== */
  .card {
    @apply bg-white rounded-2xl border border-warm-100 shadow-soft transition-all duration-300;
  }
  
  .card-hover {
    @apply hover:shadow-soft-lg hover:border-warm-200 hover:-translate-y-0.5;
  }
  
  .card-interactive {
    @apply card card-hover cursor-pointer active:scale-[0.99];
  }
  
  /* ===== BUTTONS ===== */
  .btn {
    @apply inline-flex items-center justify-center gap-2 font-medium rounded-xl
           transition-all duration-200 active:scale-[0.98]
           disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100;
  }
  
  .btn-primary {
    @apply btn px-5 py-2.5 bg-gradient-to-b from-haven-500 to-haven-600 text-white
           shadow-[0_1px_2px_rgba(0,0,0,0.1),0_2px_4px_rgba(0,0,0,0.1),inset_0_1px_0_rgba(255,255,255,0.15)]
           hover:from-haven-600 hover:to-haven-700 hover:shadow-[0_2px_4px_rgba(0,0,0,0.15),0_4px_8px_rgba(0,0,0,0.1)];
  }
  
  .btn-secondary {
    @apply btn px-5 py-2.5 bg-white text-warm-700 border border-warm-200
           shadow-sm hover:bg-warm-50 hover:border-warm-300 hover:text-warm-900;
  }
  
  .btn-ghost {
    @apply btn px-4 py-2 text-warm-600 hover:bg-warm-100 hover:text-warm-900;
  }
  
  .btn-ghost-light {
    @apply btn px-4 py-2 text-forest-300 hover:bg-white/10 hover:text-white;
  }
  
  .btn-danger {
    @apply btn px-5 py-2.5 bg-gradient-to-b from-red-500 to-red-600 text-white
           shadow-[0_1px_2px_rgba(0,0,0,0.1),inset_0_1px_0_rgba(255,255,255,0.15)]
           hover:from-red-600 hover:to-red-700;
  }
  
  .btn-sm { @apply px-3 py-1.5 text-sm rounded-lg gap-1.5; }
  .btn-lg { @apply px-6 py-3 text-base rounded-xl gap-2.5; }
  
  /* ===== INPUTS ===== */
  .input {
    @apply w-full px-4 py-3 bg-white border border-warm-200 rounded-xl
           text-warm-800 placeholder:text-warm-400
           transition-all duration-200
           hover:border-warm-300
           focus:border-haven-500 focus:ring-2 focus:ring-haven-500/20;
  }
  
  /* ===== BADGES ===== */
  .badge {
    @apply inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium;
  }
  
  .badge-success { @apply bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/20; }
  .badge-warning { @apply bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20; }
  .badge-error { @apply bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20; }
  .badge-info { @apply bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20; }
  .badge-neutral { @apply bg-warm-100 text-warm-700 ring-1 ring-inset ring-warm-600/10; }
  .badge-premium { @apply bg-gradient-to-r from-gold-100 to-gold-200 text-gold-800 ring-1 ring-inset ring-gold-400/30; }
  
  /* ===== AVATARS ===== */
  .avatar {
    @apply relative inline-flex items-center justify-center rounded-full 
           bg-gradient-to-br from-haven-400 to-haven-600 text-white font-semibold
           ring-2 ring-white shadow-sm;
  }
  
  .avatar-sm { @apply w-8 h-8 text-xs; }
  .avatar-md { @apply w-10 h-10 text-sm; }
  .avatar-lg { @apply w-12 h-12 text-base; }
  .avatar-xl { @apply w-16 h-16 text-lg; }
  .avatar-2xl { @apply w-24 h-24 text-2xl; }
  
  /* Avatar on dark sidebar */
  .avatar-dark {
    @apply ring-forest-800;
  }
  
  .status-dot {
    @apply absolute bottom-0 right-0 w-3 h-3 rounded-full ring-2 ring-white;
  }
  
  .status-online { @apply bg-emerald-500; }
  .status-offline { @apply bg-warm-400; }
  .status-busy { @apply bg-red-500; }
  
  /* ===== SKELETON LOADERS ===== */
  .skeleton {
    @apply bg-gradient-to-r from-warm-100 via-warm-50 to-warm-100 
           bg-[length:200%_100%] animate-shimmer rounded-lg;
  }
  
  .skeleton-dark {
    @apply bg-gradient-to-r from-forest-800 via-forest-700 to-forest-800
           bg-[length:200%_100%] animate-shimmer rounded-lg;
  }
  
  /* ===== STAT CARDS ===== */
  .stat-card {
    @apply card p-6;
  }
  
  .stat-value {
    @apply text-3xl font-bold text-warm-900 font-serif tabular-nums;
  }
  
  .stat-label {
    @apply text-sm text-warm-500 mt-1;
  }
  
  /* ===== TABLES ===== */
  .table-container {
    @apply overflow-x-auto rounded-xl border border-warm-100 bg-white;
  }
  
  .table {
    @apply w-full text-sm;
  }
  
  .table th {
    @apply px-4 py-3 text-left text-xs font-semibold text-warm-500 uppercase tracking-wider bg-warm-50 border-b border-warm-100;
  }
  
  .table td {
    @apply px-4 py-4 border-b border-warm-100;
  }
  
  .table tr:last-child td {
    @apply border-b-0;
  }
  
  .table tbody tr:hover td {
    @apply bg-warm-50/50;
  }
  
  /* ===== EMPTY STATES ===== */
  .empty-state {
    @apply text-center py-16 px-8;
  }
  
  .empty-state-icon {
    @apply w-16 h-16 rounded-2xl bg-warm-100 flex items-center justify-center mx-auto mb-4 text-warm-400;
  }
  
  /* ===== MODALS ===== */
  .modal-overlay {
    @apply fixed inset-0 bg-forest-950/60 backdrop-blur-sm z-50
           flex items-center justify-center p-4;
  }
  
  .modal {
    @apply bg-white rounded-2xl shadow-xl max-w-lg w-full max-h-[90vh] overflow-hidden
           animate-scale-in;
  }
  
  .modal-header {
    @apply px-6 py-4 border-b border-warm-100;
  }
  
  .modal-body {
    @apply px-6 py-4 overflow-y-auto;
  }
  
  .modal-footer {
    @apply px-6 py-4 border-t border-warm-100 flex items-center justify-end gap-3 bg-warm-50;
  }
  
  /* ===== PAGE LAYOUT ===== */
  .page-container {
    @apply max-w-7xl mx-auto px-4 sm:px-6 lg:px-8;
  }
}

@layer utilities {
  .text-gradient {
    @apply bg-clip-text text-transparent bg-gradient-to-r from-haven-600 to-haven-500;
  }
  
  .text-gradient-gold {
    @apply bg-clip-text text-transparent bg-gradient-to-r from-gold-600 to-gold-500;
  }
  
  /* Staggered animations */
  .stagger-1 { animation-delay: 50ms; }
  .stagger-2 { animation-delay: 100ms; }
  .stagger-3 { animation-delay: 150ms; }
  .stagger-4 { animation-delay: 200ms; }
  .stagger-5 { animation-delay: 250ms; }
  
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }
  
  .glass {
    @apply bg-white/80 backdrop-blur-xl border border-white/20;
  }
  
  .glass-dark {
    @apply bg-forest-900/80 backdrop-blur-xl border border-white/10;
  }
}
```

### 1.3 Image Assets Helper

**Create file:** `apps/web/src/lib/images.ts`

```typescript
// Premium Unsplash images for demo
export const images = {
  properties: {
    greenwich: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800&q=80',
    malibu: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',
    beverly: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800&q=80',
    scarsdale: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&q=80',
  },
  
  avatars: {
    sarah: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&q=80',
    mike: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&q=80',
    bob: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80',
    alice: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200&q=80',
    carlos: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&q=80',
  },
  
  travel: {
    aspen: 'https://images.unsplash.com/photo-1605540436563-5bca919ae766?w=800&q=80',
    turks: 'https://images.unsplash.com/photo-1548574505-5e239809ee19?w=800&q=80',
    sf: 'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800&q=80',
    napa: 'https://images.unsplash.com/photo-1474722883778-792e7990302f?w=800&q=80',
  },
  
  services: {
    plumbing: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80',
    electrical: 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80',
    landscaping: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400&q=80',
    roofing: 'https://images.unsplash.com/photo-1632759145351-1d592919f522?w=400&q=80',
  },
};

export function getAvatarUrl(name: string): string | undefined {
  const map: Record<string, string> = {
    'sarah harrison': images.avatars.sarah,
    'sarah': images.avatars.sarah,
    'mike rodriguez': images.avatars.mike,
    'mike': images.avatars.mike,
    'bob smith': images.avatars.bob,
    'bob': images.avatars.bob,
    'alice johnson': images.avatars.alice,
    'carlos reyes': images.avatars.carlos,
  };
  return map[name.toLowerCase()];
}

export function getInitials(name: string): string {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
}

export function getPropertyImage(name: string): string {
  if (name.toLowerCase().includes('malibu')) return images.properties.malibu;
  if (name.toLowerCase().includes('beverly')) return images.properties.beverly;
  if (name.toLowerCase().includes('scarsdale') || name.toLowerCase().includes('johnson')) return images.properties.scarsdale;
  return images.properties.greenwich;
}

export function getDestinationImage(dest: string): string {
  if (dest.toLowerCase().includes('aspen') || dest.toLowerCase().includes('colorado')) return images.travel.aspen;
  if (dest.toLowerCase().includes('turks') || dest.toLowerCase().includes('caicos')) return images.travel.turks;
  if (dest.toLowerCase().includes('francisco') || dest.toLowerCase().includes('sf')) return images.travel.sf;
  if (dest.toLowerCase().includes('napa')) return images.travel.napa;
  return images.travel.aspen;
}
```

---

## PHASE 2: CRITICAL BUG FIXES

### 2.1 Fix Manager Navigation

**File:** `apps/web/src/app/manager/layout.tsx`

Find and replace `/manager/schedule` with `/manager/calendar`

### 2.2 Update Seed - Sarah & Mike

**File:** `apps/api/prisma/seed.ts`

Global find and replace:
- `managerSteve` → `managerSarah`
- `handymanDave` → `handymanMike`  
- `steve@haven.app` → `sarah@haven.app`
- `dave@haven.app` → `mike@haven.app`
- `Steve Manager` → `Sarah Harrison`
- `Manager Steve` → `Sarah Harrison`
- `Mike Castellano` → `Mike Rodriguez`
- `Dave Wilson` → `Mike Rodriguez`

Update user creation blocks with correct names.

### 2.3 Update Frontend References

Search all files in `apps/web/src/app/` for "Steve" or "Dave" and update to Sarah/Mike.

---

## PHASE 3: HOMEOWNER PORTAL - BEAUTIFUL SIDEBAR

### 3.1 Homeowner Layout with Deep Green Sidebar

**File:** `apps/web/src/app/app/layout.tsx`

```typescript
'use client';

import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import Image from 'next/image';
import { useAuth } from '@/contexts/auth-context';
import { useHousehold } from '@/contexts/household-context';
import { images, getAvatarUrl, getInitials } from '@/lib/images';
import {
  Home,
  MessageSquare,
  Calendar,
  FileText,
  Search,
  LogOut,
  Menu,
  X,
  Plane,
  Bell,
  ChevronDown,
  Sparkles,
  Settings,
  CreditCard,
} from 'lucide-react';

const navigation = [
  { name: 'Home', href: '/app', icon: Home },
  { name: 'Messages', href: '/app/messages', icon: MessageSquare, badge: 2 },
  { name: 'Requests', href: '/app/requests', icon: FileText },
  { name: 'Calendar', href: '/app/calendar', icon: Calendar },
  { name: 'Travel', href: '/app/travel', icon: Plane },
  { name: 'Find Pros', href: '/app/community', icon: Search },
  { name: 'Bills & Payments', href: '/app/bills', icon: CreditCard },
];

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, user, logout } = useAuth();
  const { currentHousehold } = useHousehold();
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login');
    }
  }, [isLoading, isAuthenticated, router]);

  if (isLoading || !isAuthenticated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-warm-50">
        <div className="text-center">
          <div className="w-12 h-12 rounded-full border-2 border-haven-500 border-t-transparent animate-spin mx-auto" />
          <p className="mt-4 text-warm-500">Loading your home...</p>
        </div>
      </div>
    );
  }

  const userName = user?.displayName || user?.email?.split('@')[0] || 'User';
  const userAvatar = getAvatarUrl(userName);

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Mobile Header */}
      <header className="lg:hidden fixed top-0 left-0 right-0 z-40 glass border-b border-warm-200">
        <div className="flex items-center justify-between px-4 h-16">
          <button
            onClick={() => setSidebarOpen(true)}
            className="p-2 rounded-lg hover:bg-warm-100 transition-colors"
          >
            <Menu className="w-6 h-6 text-warm-700" />
          </button>
          
          <Link href="/app" className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-haven-500 to-forest-700 flex items-center justify-center">
              <Home className="w-4 h-4 text-white" />
            </div>
            <span className="font-serif font-bold text-warm-900">Haven</span>
          </Link>
          
          <button className="p-2 rounded-lg hover:bg-warm-100 transition-colors relative">
            <Bell className="w-6 h-6 text-warm-700" />
            <span className="absolute top-1 right-1 w-4 h-4 bg-haven-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center">
              2
            </span>
          </button>
        </div>
      </header>

      {/* Mobile Sidebar Overlay */}
      {sidebarOpen && (
        <div
          className="lg:hidden fixed inset-0 z-50 bg-forest-950/60 backdrop-blur-sm"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* BEAUTIFUL DEEP GREEN SIDEBAR */}
      <aside
        className={`
          fixed top-0 left-0 bottom-0 z-50 w-72 
          bg-gradient-to-b from-forest-900 to-forest-950
          shadow-sidebar
          transform transition-transform duration-300 ease-in-out
          lg:translate-x-0
          ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'}
        `}
      >
        <div className="flex flex-col h-full dark-scrollbar overflow-y-auto">
          {/* Logo */}
          <div className="h-16 flex items-center justify-between px-6 border-b border-white/10">
            <Link href="/app" className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-haven-400 to-haven-600 flex items-center justify-center shadow-lg shadow-haven-500/30">
                <Home className="w-5 h-5 text-white" />
              </div>
              <span className="font-serif text-xl font-bold text-white">Haven</span>
            </Link>
            <button
              onClick={() => setSidebarOpen(false)}
              className="lg:hidden p-2 rounded-lg hover:bg-white/10 text-forest-300"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Property Selector */}
          {currentHousehold && (
            <div className="p-4">
              <button className="sidebar-property-selector w-full flex items-center gap-3">
                <div 
                  className="w-10 h-10 rounded-lg bg-cover bg-center ring-2 ring-white/20"
                  style={{ backgroundImage: `url(${images.properties.greenwich})` }}
                />
                <div className="flex-1 text-left">
                  <div className="font-medium text-white text-sm">
                    {currentHousehold.name || "My Home"}
                  </div>
                  <div className="text-xs text-forest-400">Greenwich, CT</div>
                </div>
                <ChevronDown className="w-4 h-4 text-forest-400" />
              </button>
            </div>
          )}

          {/* Navigation */}
          <nav className="flex-1 px-3 py-2 space-y-1">
            {navigation.map((item) => {
              const isActive = pathname === item.href || 
                (item.href !== '/app' && pathname.startsWith(item.href));
              
              return (
                <Link
                  key={item.name}
                  href={item.href}
                  onClick={() => setSidebarOpen(false)}
                  className={`
                    sidebar-nav-item
                    ${isActive ? 'sidebar-nav-item-active' : ''}
                  `}
                >
                  <item.icon className={`sidebar-nav-icon ${isActive ? 'text-haven-400' : ''}`} />
                  <span>{item.name}</span>
                  {item.badge && (
                    <span className="sidebar-badge">{item.badge}</span>
                  )}
                </Link>
              );
            })}
          </nav>

          {/* Home Manager Quick Card */}
          <div className="px-4 pb-4">
            <div className="rounded-xl bg-gradient-to-br from-haven-600 to-haven-700 p-4 text-white">
              <div className="flex items-center gap-3 mb-3">
                <div className="relative">
                  <Image
                    src={images.avatars.sarah}
                    alt="Sarah"
                    width={40}
                    height={40}
                    className="rounded-full ring-2 ring-white/30"
                  />
                  <span className="absolute bottom-0 right-0 w-3 h-3 bg-emerald-400 rounded-full ring-2 ring-haven-600" />
                </div>
                <div>
                  <div className="font-medium text-sm">Sarah Harrison</div>
                  <div className="text-xs text-haven-200">Your Home Manager</div>
                </div>
              </div>
              <Link 
                href="/app/messages"
                className="block w-full py-2 bg-white/20 hover:bg-white/30 rounded-lg text-sm font-medium text-center transition-colors"
              >
                <MessageSquare className="w-4 h-4 inline mr-2" />
                Send Message
              </Link>
            </div>
          </div>

          <div className="sidebar-divider mx-4" />

          {/* User Menu */}
          <div className="p-4">
            <div className="flex items-center gap-3 p-3 rounded-xl hover:bg-white/5 transition-colors cursor-pointer">
              {userAvatar ? (
                <Image
                  src={userAvatar}
                  alt={userName}
                  width={40}
                  height={40}
                  className="rounded-full ring-2 ring-forest-700"
                />
              ) : (
                <div className="avatar avatar-md avatar-dark">
                  {getInitials(userName)}
                </div>
              )}
              <div className="flex-1 min-w-0">
                <div className="font-medium text-white text-sm truncate">{userName}</div>
                <div className="text-xs text-forest-400">Concierge Plan</div>
              </div>
            </div>
            
            <div className="mt-2 flex gap-2">
              <Link 
                href="/app/settings"
                className="flex-1 btn-ghost-light text-sm justify-center"
              >
                <Settings className="w-4 h-4" />
                Settings
              </Link>
              <button
                onClick={() => logout()}
                className="flex-1 btn-ghost-light text-sm justify-center text-red-300 hover:text-red-200 hover:bg-red-500/10"
              >
                <LogOut className="w-4 h-4" />
                Sign Out
              </button>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="lg:pl-72 pt-16 lg:pt-0 min-h-screen">
        <div className="p-4 lg:p-8 max-w-7xl mx-auto">
          {children}
        </div>
      </main>
    </div>
  );
}
```

### 3.2 Homeowner Dashboard

**File:** `apps/web/src/app/app/page.tsx`

Build a beautiful dashboard with:
- Personalized greeting with weather
- Quick stats grid
- Home Manager card with avatar and message button
- Upcoming trip card with destination image
- Active requests list
- Recent messages preview
- Quick action buttons

Use the card, badge, button, and avatar CSS classes defined in globals.css.

---

## PHASE 4: MANAGER PORTAL - DEEP GREEN SIDEBAR

### 4.1 Manager Layout

**File:** `apps/web/src/app/manager/layout.tsx`

Same beautiful deep green sidebar pattern but with manager navigation:
- Dashboard
- Households
- Calendar (not Schedule!)
- Conversations
- Travel Desk
- Payables
- Verification
- Reports

Add "Haven Pro" branding and household multi-selector.

### 4.2 Manager Dashboard

Connect to real APIs and show:
- Quick stats
- Needs Attention queue
- Today's schedule
- Household health

### 4.3 Manager Calendar, Payables, Conversations, Travel, Verification

Build all these pages with the premium design system.

---

## PHASE 5: HANDYMAN PORTAL

### 5.1 Handyman Layout

Mobile-first with deep green header/navigation.

### 5.2 Handyman Dashboard, Job Detail, Schedule

Build with check-in/out, geolocation, photo upload.

---

## PHASE 6: VENDOR PORTAL

### 6.1 Vendor Layout

Professional design with deep green accents.

### 6.2 Vendor Dashboard, Jobs, Job Detail

Build with job claiming and completion workflow.

---

## PHASE 7: SEED DATA

Add to seed.ts:
- Travel profiles, trips, itineraries, proposals
- Conversations with messages
- Work orders for all user types
- Update all Steve→Sarah, Dave→Mike

---

## PHASE 8: FINAL POLISH

- Loading skeletons on every page
- Empty states with icons
- Error states with retry
- Smooth animations
- Mobile responsive
- No TypeScript errors

---

## RUN AFTER BUILD

```bash
cd apps/api
pnpm prisma db push --force-reset
pnpm prisma db seed
pnpm dev

# Second terminal
cd apps/web
pnpm dev
```

Test: http://localhost:3000

---

## COLOR SUMMARY

| Element | Color | Tailwind Class |
|---------|-------|----------------|
| Sidebar Background | Deep Forest Green | `bg-forest-900` / `bg-gradient-to-b from-forest-900 to-forest-950` |
| Sidebar Text | White/Light | `text-white`, `text-forest-200`, `text-forest-400` |
| Sidebar Active Item | White with green icon | `bg-white/15 text-white`, icon: `text-haven-400` |
| Sidebar Borders | Subtle white | `border-white/10` |
| Primary Buttons | Sage Green gradient | `from-haven-500 to-haven-600` |
| Content Background | Warm Off-white | `bg-warm-50` |
| Cards | White | `bg-white` |
| Text | Warm Dark | `text-warm-800`, `text-warm-900` |
| Accents | Gold | `text-gold-500`, `bg-gold-100` |

This creates a sophisticated, premium feel - like a private banking app or luxury concierge service.

🏠✨

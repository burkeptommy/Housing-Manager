# Haven Avatar System - Special Role Avatars Fix

## PROBLEMS IDENTIFIED

1. **Sarah's avatar cut off** - Avatar doesn't fit its container on dashboard
2. **Messages tab inconsistency** - Sarah shows "SC", Marcus shows "MJ", Concierge shows "HC"
3. **No special avatar for Concierge** - Needs unique illustration
4. **No special avatar for Handyman** - Marcus should have HandymanAvatar
5. **Vendors show initials** - Should use colored VendorAvatar

---

## SPECIAL ROLE AVATARS

### Three Special Roles with Unique Illustrations:

| Role | Icon | Background | Badge/Indicator |
|------|------|------------|-----------------|
| **Home Manager** (Sarah) | Sparkles ✨ | Champagne | Star badge |
| **Handyman** (Marcus) | Wrench 🔧 | Orange | Tool badge |
| **Concierge** (AI) | Bot/Wand 🤖 | Navy | Pulse dot |

---

## UPDATED AVATAR COMPONENT

### File: `apps/web/src/components/ui/Avatar.tsx`

```tsx
'use client';

import React from 'react';
import { Sparkles, Wrench, Bot, Star, User, Dog, Cat, Baby } from 'lucide-react';

// Color palette for dynamic avatars
const colors = [
  { bg: '#E8ECF2', text: '#1E2A3B' },  // Navy
  { bg: '#CCFBF1', text: '#0F766E' },  // Teal
  { bg: '#EDE9FE', text: '#6D28D9' },  // Violet
  { bg: '#FFE4E6', text: '#BE123C' },  // Rose
  { bg: '#FEF3C7', text: '#B45309' },  // Amber
  { bg: '#D1FAE5', text: '#047857' },  // Emerald
  { bg: '#E0F2FE', text: '#0369A1' },  // Sky
  { bg: '#FFEDD5', text: '#C2410C' },  // Orange
  { bg: '#FCE7F3', text: '#BE185D' },  // Pink
  { bg: '#E0E7FF', text: '#4338CA' },  // Indigo
  { bg: '#ECFCCB', text: '#4D7C0F' },  // Lime
  { bg: '#CFFAFE', text: '#0E7490' },  // Cyan
];

function getColorIndex(name: string): number {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return Math.abs(hash) % colors.length;
}

// Size configurations
const sizes = {
  xs: { container: 24, icon: 12, badge: 8, text: 10 },
  sm: { container: 32, icon: 16, badge: 10, text: 12 },
  md: { container: 40, icon: 20, badge: 12, text: 14 },
  lg: { container: 48, icon: 24, badge: 14, text: 16 },
  xl: { container: 64, icon: 32, badge: 16, text: 20 },
  '2xl': { container: 80, icon: 40, badge: 20, text: 24 },
};

type AvatarSize = keyof typeof sizes;

// ===========================================
// HOME MANAGER AVATAR (Sarah Chen)
// ===========================================
interface ManagerAvatarProps {
  size?: AvatarSize;
  className?: string;
  showBadge?: boolean;
}

export function ManagerAvatar({ size = 'md', className = '', showBadge = true }: ManagerAvatarProps) {
  const s = sizes[size];
  
  return (
    <div 
      className={`relative flex-shrink-0 ${className}`}
      style={{ width: s.container, height: s.container }}
    >
      {/* Main circle */}
      <div 
        className="w-full h-full rounded-full bg-gradient-to-br from-champagne-200 to-champagne-300 flex items-center justify-center"
      >
        <Sparkles 
          style={{ width: s.icon, height: s.icon }} 
          className="text-champagne-700"
        />
      </div>
      
      {/* Star badge */}
      {showBadge && (
        <div 
          className="absolute -top-0.5 -right-0.5 bg-amber-400 rounded-full flex items-center justify-center ring-2 ring-white"
          style={{ width: s.badge, height: s.badge }}
        >
          <Star 
            style={{ width: s.badge * 0.6, height: s.badge * 0.6 }} 
            className="text-amber-700 fill-current"
          />
        </div>
      )}
    </div>
  );
}

// ===========================================
// HANDYMAN AVATAR (Marcus Johnson)
// ===========================================
interface HandymanAvatarProps {
  size?: AvatarSize;
  className?: string;
  showBadge?: boolean;
}

export function HandymanAvatar({ size = 'md', className = '', showBadge = true }: HandymanAvatarProps) {
  const s = sizes[size];
  
  return (
    <div 
      className={`relative flex-shrink-0 ${className}`}
      style={{ width: s.container, height: s.container }}
    >
      {/* Main circle */}
      <div 
        className="w-full h-full rounded-full bg-gradient-to-br from-orange-200 to-orange-300 flex items-center justify-center"
      >
        <Wrench 
          style={{ width: s.icon, height: s.icon }} 
          className="text-orange-700"
        />
      </div>
      
      {/* Tool badge */}
      {showBadge && (
        <div 
          className="absolute -top-0.5 -right-0.5 bg-orange-500 rounded-full flex items-center justify-center ring-2 ring-white"
          style={{ width: s.badge, height: s.badge }}
        >
          <Wrench 
            style={{ width: s.badge * 0.6, height: s.badge * 0.6 }} 
            className="text-white"
          />
        </div>
      )}
    </div>
  );
}

// ===========================================
// CONCIERGE AVATAR (AI Assistant)
// ===========================================
interface ConciergeAvatarProps {
  size?: AvatarSize;
  className?: string;
  showPulse?: boolean;
}

export function ConciergeAvatar({ size = 'md', className = '', showPulse = true }: ConciergeAvatarProps) {
  const s = sizes[size];
  
  return (
    <div 
      className={`relative flex-shrink-0 ${className}`}
      style={{ width: s.container, height: s.container }}
    >
      {/* Main circle */}
      <div 
        className="w-full h-full rounded-full bg-gradient-to-br from-haven-600 to-haven-700 flex items-center justify-center"
      >
        <Bot 
          style={{ width: s.icon, height: s.icon }} 
          className="text-white"
        />
      </div>
      
      {/* Online pulse indicator */}
      {showPulse && (
        <div 
          className="absolute bottom-0 right-0 bg-emerald-500 rounded-full ring-2 ring-white animate-pulse"
          style={{ width: s.badge * 0.7, height: s.badge * 0.7 }}
        />
      )}
    </div>
  );
}

// ===========================================
// PERSON AVATAR (Family Members)
// ===========================================
interface PersonAvatarProps {
  name: string;
  type: 'male' | 'female' | 'boy' | 'girl';
  size?: AvatarSize;
  className?: string;
}

export function PersonAvatar({ name, type, size = 'md', className = '' }: PersonAvatarProps) {
  const s = sizes[size];
  const color = colors[getColorIndex(name)];
  
  // Simple silhouette icons based on type
  const getIcon = () => {
    switch (type) {
      case 'male':
        return (
          <svg viewBox="0 0 40 40" style={{ width: s.icon, height: s.icon }}>
            <circle cx="20" cy="12" r="8" fill={color.text} />
            <path d="M8 40 L12 26 Q16 20 20 20 Q24 20 28 26 L32 40 Z" fill={color.text} />
          </svg>
        );
      case 'female':
        return (
          <svg viewBox="0 0 40 40" style={{ width: s.icon, height: s.icon }}>
            <ellipse cx="20" cy="10" rx="9" ry="7" fill={color.text} />
            <circle cx="20" cy="13" r="7" fill={color.text} />
            <path d="M10 40 L14 26 Q17 20 20 20 Q23 20 26 26 L30 40 Z" fill={color.text} />
          </svg>
        );
      case 'boy':
        return (
          <svg viewBox="0 0 40 40" style={{ width: s.icon, height: s.icon }}>
            <circle cx="20" cy="14" r="9" fill={color.text} />
            <path d="M12 40 L15 28 Q18 23 20 23 Q22 23 25 28 L28 40 Z" fill={color.text} />
          </svg>
        );
      case 'girl':
        return (
          <svg viewBox="0 0 40 40" style={{ width: s.icon, height: s.icon }}>
            <circle cx="20" cy="14" r="9" fill={color.text} />
            <circle cx="10" cy="12" r="4" fill={color.text} />
            <circle cx="30" cy="12" r="4" fill={color.text} />
            <path d="M12 40 L15 28 Q18 23 20 23 Q22 23 25 28 L28 40 Z" fill={color.text} />
          </svg>
        );
    }
  };
  
  return (
    <div 
      className={`rounded-full flex items-center justify-center flex-shrink-0 ${className}`}
      style={{ 
        width: s.container, 
        height: s.container, 
        backgroundColor: color.bg 
      }}
    >
      {getIcon()}
    </div>
  );
}

// ===========================================
// PET AVATAR
// ===========================================
interface PetAvatarProps {
  name: string;
  type: 'dog' | 'cat';
  size?: AvatarSize;
  className?: string;
}

export function PetAvatar({ name, type, size = 'md', className = '' }: PetAvatarProps) {
  const s = sizes[size];
  const color = colors[getColorIndex(name)];
  const Icon = type === 'dog' ? Dog : Cat;
  
  return (
    <div 
      className={`rounded-full flex items-center justify-center flex-shrink-0 ${className}`}
      style={{ 
        width: s.container, 
        height: s.container, 
        backgroundColor: color.bg 
      }}
    >
      <Icon style={{ width: s.icon, height: s.icon, color: color.text }} />
    </div>
  );
}

// ===========================================
// VENDOR AVATAR (Initials with color)
// ===========================================
interface VendorAvatarProps {
  name: string;
  size?: AvatarSize;
  className?: string;
}

export function VendorAvatar({ name, size = 'md', className = '' }: VendorAvatarProps) {
  const s = sizes[size];
  const color = colors[getColorIndex(name)];
  
  // Get initials (first letter of first two words)
  const initials = name
    .split(' ')
    .slice(0, 2)
    .map(word => word[0])
    .join('')
    .toUpperCase();
  
  return (
    <div 
      className={`rounded-xl flex items-center justify-center font-semibold flex-shrink-0 ${className}`}
      style={{ 
        width: s.container, 
        height: s.container, 
        backgroundColor: color.bg,
        color: color.text,
        fontSize: s.text,
      }}
    >
      {initials}
    </div>
  );
}

// ===========================================
// GENERIC AVATAR (Fallback)
// ===========================================
interface AvatarProps {
  name: string;
  size?: AvatarSize;
  className?: string;
}

export function Avatar({ name, size = 'md', className = '' }: AvatarProps) {
  const s = sizes[size];
  const color = colors[getColorIndex(name)];
  
  const initials = name
    .split(' ')
    .slice(0, 2)
    .map(word => word[0])
    .join('')
    .toUpperCase();
  
  return (
    <div 
      className={`rounded-full flex items-center justify-center font-semibold flex-shrink-0 ${className}`}
      style={{ 
        width: s.container, 
        height: s.container, 
        backgroundColor: color.bg,
        color: color.text,
        fontSize: s.text,
      }}
    >
      {initials}
    </div>
  );
}

export default Avatar;
```

---

## USAGE GUIDE

### Special Roles (Always use these specific components)

```tsx
import { ManagerAvatar, HandymanAvatar, ConciergeAvatar } from '@/components/ui/Avatar';

// Sarah Chen - Home Manager
<ManagerAvatar size="lg" />

// Marcus Johnson - Handyman  
<HandymanAvatar size="lg" />

// Haven Concierge - AI Assistant
<ConciergeAvatar size="lg" />
```

### Family Members

```tsx
import { PersonAvatar, PetAvatar } from '@/components/ui/Avatar';

<PersonAvatar name="Bob Thompson" type="male" size="md" />
<PersonAvatar name="Alice Thompson" type="female" size="md" />
<PersonAvatar name="Emma Thompson" type="girl" size="md" />
<PersonAvatar name="Jake Thompson" type="boy" size="md" />
<PetAvatar name="Max" type="dog" size="md" />
```

### Vendors

```tsx
import { VendorAvatar } from '@/components/ui/Avatar';

<VendorAvatar name="Mike's Plumbing Pro" size="md" />
<VendorAvatar name="Country Landscape Design" size="md" />
<VendorAvatar name="Comfort Zone HVAC" size="md" />
```

---

## FILES TO UPDATE

### 1. Dashboard Page

**File:** `apps/web/src/app/app/dashboard/page.tsx`

```tsx
import { ManagerAvatar, PersonAvatar, PetAvatar } from '@/components/ui/Avatar';

// Sarah Chen card - MUST use ManagerAvatar
<div className="flex items-center gap-3">
  <ManagerAvatar size="lg" />  {/* NOT an image, NOT initials */}
  <div>
    <p className="font-semibold">Sarah Chen</p>
    <p className="text-sm text-warm-500">Your Home Manager</p>
  </div>
</div>

// Today's Logistics
<PersonAvatar name="Bob Thompson" type="male" size="sm" />
<PersonAvatar name="Alice Thompson" type="female" size="sm" />
<PersonAvatar name="Emma Thompson" type="girl" size="sm" />
<PersonAvatar name="Jake Thompson" type="boy" size="sm" />
<PetAvatar name="Max" type="dog" size="sm" />

// Bottom bar Sarah
<div className="flex items-center gap-3">
  <ManagerAvatar size="md" />
  <div>
    <p className="font-semibold text-white">Sarah Chen</p>
    <p className="text-sm text-haven-200">Your Home Manager</p>
  </div>
</div>
```

### 2. Sarah Tab

**File:** `apps/web/src/app/app/sarah/page.tsx`

```tsx
import { ManagerAvatar } from '@/components/ui/Avatar';

// Header
<div className="flex items-center gap-4">
  <ManagerAvatar size="xl" />  {/* Large size, NOT "SC" initials */}
  <div>
    <h1 className="text-2xl font-bold">Sarah Chen</h1>
    <p className="text-warm-500">Your Home Manager</p>
    <p className="text-sm text-warm-400">Managing your home since June 2023</p>
  </div>
</div>
```

### 3. Messages Tab

**File:** `apps/web/src/app/app/messages/page.tsx`

```tsx
import { 
  ManagerAvatar, 
  HandymanAvatar, 
  ConciergeAvatar, 
  VendorAvatar,
  Avatar 
} from '@/components/ui/Avatar';

// Conversation list - determine avatar by type
function getConversationAvatar(conversation) {
  switch (conversation.type) {
    case 'manager':
      return <ManagerAvatar size="md" />;
    case 'handyman':
      return <HandymanAvatar size="md" />;
    case 'concierge':
      return <ConciergeAvatar size="md" />;
    case 'vendor':
      return <VendorAvatar name={conversation.name} size="md" />;
    default:
      return <Avatar name={conversation.name} size="md" />;
  }
}

// Pinned section
<div className="flex items-center gap-3">
  <ManagerAvatar size="md" />
  <div>
    <p className="font-semibold">Sarah Chen</p>
    <p className="text-sm text-warm-500">Your Home Manager</p>
  </div>
</div>

<div className="flex items-center gap-3">
  <HandymanAvatar size="md" />
  <div>
    <p className="font-semibold">Marcus Johnson</p>
    <p className="text-sm text-warm-500">Your Handyman</p>
  </div>
</div>

<div className="flex items-center gap-3">
  <ConciergeAvatar size="md" />
  <div>
    <p className="font-semibold">Haven Concierge</p>
    <p className="text-sm text-warm-500">AI Assistant</p>
  </div>
</div>

// Vendors section
<div className="flex items-center gap-3">
  <VendorAvatar name="Mike's Plumbing Pro" size="md" />
  <div>
    <p className="font-semibold">Mike's Plumbing Pro</p>
    <p className="text-sm text-warm-500">Plumber • Haven Trusted</p>
  </div>
</div>
```

### 4. Chat Widget / Concierge

**File:** `apps/web/src/components/chat/ConciergeChat.tsx`

```tsx
import { ConciergeAvatar } from '@/components/ui/Avatar';

// Header
<div className="flex items-center gap-3">
  <ConciergeAvatar size="md" />
  <div>
    <p className="font-semibold text-white">Haven Concierge</p>
    <p className="text-xs text-haven-200">Here to help 24/7</p>
  </div>
</div>

// In messages from concierge
<ConciergeAvatar size="sm" />
```

---

## VISUAL REFERENCE

```
SPECIAL ROLES:

┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   ✨  ⭐    │   │   🔧  🔧    │   │   🤖  •    │
│ champagne   │   │   orange    │   │   navy     │
│   gradient  │   │   gradient  │   │  gradient  │
│             │   │             │   │  (pulse)   │
│  MANAGER    │   │  HANDYMAN   │   │ CONCIERGE  │
│ Sarah Chen  │   │   Marcus    │   │    AI      │
└─────────────┘   └─────────────┘   └─────────────┘


FAMILY:

┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│     👤      │   │     👤      │   │     🐕      │
│  silhouette │   │  silhouette │   │    icon     │
│   (varied   │   │   (varied   │   │   (varied   │
│   colors)   │   │   colors)   │   │   colors)   │
│    MALE     │   │   FEMALE    │   │     DOG     │
└─────────────┘   └─────────────┘   └─────────────┘


VENDORS:

┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│             │   │             │   │             │
│     MP      │   │     CL      │   │     CZ      │
│   (navy)    │   │   (teal)    │   │  (violet)   │
│  rounded    │   │  rounded    │   │  rounded    │
│   square    │   │   square    │   │   square    │
└─────────────┘   └─────────────┘   └─────────────┘
```

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Fix avatar consistency across the app - read HAVEN_AVATAR_ROLES.md:

1. Update apps/web/src/components/ui/Avatar.tsx with:
   - ManagerAvatar: Champagne gradient + Sparkles icon + Star badge (for Sarah)
   - HandymanAvatar: Orange gradient + Wrench icon + Tool badge (for Marcus)
   - ConciergeAvatar: Navy gradient + Bot icon + Pulse indicator (for AI)
   - PersonAvatar: Silhouettes for male/female/boy/girl
   - PetAvatar: Dog/Cat icons
   - VendorAvatar: Colored rounded squares with initials

2. Update Dashboard (apps/web/src/app/app/dashboard/page.tsx):
   - Sarah's card: Use ManagerAvatar (NOT image that gets cut off)
   - Today's Logistics: Use PersonAvatar for Bob/Alice/Emma/Jake, PetAvatar for Max
   - Bottom bar: Use ManagerAvatar

3. Update Sarah tab (apps/web/src/app/app/sarah/page.tsx):
   - Replace "SC" initials with ManagerAvatar size="xl"

4. Update Messages tab (apps/web/src/app/app/messages/page.tsx):
   - Sarah Chen: ManagerAvatar (NOT "SC")
   - Marcus Johnson: HandymanAvatar (NOT "MJ")
   - Haven Concierge: ConciergeAvatar (NOT "HC")
   - Vendors: VendorAvatar with their names

5. Update Chat widget to use ConciergeAvatar

Every special role must use their specific avatar component everywhere they appear.

Run pnpm build to verify.
```

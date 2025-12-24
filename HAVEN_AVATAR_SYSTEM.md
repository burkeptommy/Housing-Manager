# Haven Avatar System - Simple & Clear

## CONCEPT

Simple illustrated silhouette avatars that clearly distinguish:
- 👨 Male adult
- 👩 Female adult  
- 👦 Male child
- 👧 Female child
- ✨ Home Manager (Sarah) - special treatment
- 🔧 Handyman (Mike) - special treatment
- 🏢 Vendors - icon based on category + varied colors

## APPROACH

Use simple SVG silhouettes with:
1. **Shape differences** - Male (angular), Female (rounded), Kids (smaller)
2. **Color variety** - Each person/vendor gets a unique background color
3. **Special badges** - Manager gets a star badge, Handyman gets a tool badge

---

## AVATAR COMPONENT

### File: `apps/web/src/components/ui/Avatar.tsx`

```tsx
'use client';

import React from 'react';

// Color palette - 12 distinct colors
const colors = [
  { bg: '#E8ECF2', fill: '#1E2A3B' },  // Navy
  { bg: '#CCFBF1', fill: '#0F766E' },  // Teal
  { bg: '#EDE9FE', fill: '#6D28D9' },  // Violet
  { bg: '#FFE4E6', fill: '#BE123C' },  // Rose
  { bg: '#FEF3C7', fill: '#B45309' },  // Amber
  { bg: '#D1FAE5', fill: '#047857' },  // Emerald
  { bg: '#E0F2FE', fill: '#0369A1' },  // Sky
  { bg: '#FFEDD5', fill: '#C2410C' },  // Orange
  { bg: '#FCE7F3', fill: '#BE185D' },  // Pink
  { bg: '#E0E7FF', fill: '#4338CA' },  // Indigo
  { bg: '#ECFCCB', fill: '#4D7C0F' },  // Lime
  { bg: '#CFFAFE', fill: '#0E7490' },  // Cyan
];

// Get consistent color from name
function getColorIndex(name: string): number {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return Math.abs(hash) % colors.length;
}

// Size presets
const sizes = {
  xs: 24,
  sm: 32,
  md: 40,
  lg: 48,
  xl: 64,
  '2xl': 80,
};

type AvatarSize = keyof typeof sizes;

interface AvatarProps {
  name: string;
  type: 'male' | 'female' | 'boy' | 'girl' | 'manager' | 'handyman' | 'pet-dog' | 'pet-cat';
  size?: AvatarSize;
  colorIndex?: number; // Override color
  className?: string;
}

// Male Adult Silhouette
function MaleSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Head */}
      <circle cx="20" cy="12" r="7" />
      {/* Shoulders/Body - broader, more angular */}
      <path d="M8 40 L12 28 C14 24 17 22 20 22 C23 22 26 24 28 28 L32 40 Z" />
    </g>
  );
}

// Female Adult Silhouette  
function FemaleSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Head */}
      <circle cx="20" cy="12" r="7" />
      {/* Hair hint - slightly longer */}
      <ellipse cx="20" cy="10" rx="8" ry="6" />
      {/* Shoulders/Body - narrower, softer */}
      <path d="M10 40 L13 28 C15 24 17 22 20 22 C23 22 25 24 27 28 L30 40 Z" />
    </g>
  );
}

// Boy Silhouette (smaller, childlike proportions)
function BoySilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Bigger head relative to body (child proportions) */}
      <circle cx="20" cy="13" r="8" />
      {/* Smaller body */}
      <path d="M12 40 L14 30 C16 26 18 24 20 24 C22 24 24 26 26 30 L28 40 Z" />
    </g>
  );
}

// Girl Silhouette (smaller, childlike proportions with hair)
function GirlSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Bigger head relative to body */}
      <circle cx="20" cy="13" r="8" />
      {/* Pigtails/hair puffs */}
      <circle cx="11" cy="11" r="3" />
      <circle cx="29" cy="11" r="3" />
      {/* Smaller body */}
      <path d="M12 40 L14 30 C16 26 18 24 20 24 C22 24 24 26 26 30 L28 40 Z" />
    </g>
  );
}

// Manager silhouette with sparkle badge
function ManagerSilhouette() {
  return (
    <g>
      {/* Female silhouette base */}
      <g fill="#8C7D4E">
        <circle cx="20" cy="12" r="7" />
        <ellipse cx="20" cy="10" rx="8" ry="6" />
        <path d="M10 40 L13 28 C15 24 17 22 20 22 C23 22 25 24 27 28 L30 40 Z" />
      </g>
      {/* Star badge */}
      <g transform="translate(28, 2)">
        <circle cx="6" cy="6" r="6" fill="#FCD34D" />
        <path d="M6 2 L7 5 L10 5 L8 7 L9 10 L6 8 L3 10 L4 7 L2 5 L5 5 Z" fill="#B45309" />
      </g>
    </g>
  );
}

// Handyman silhouette with tool badge
function HandymanSilhouette() {
  return (
    <g>
      {/* Male silhouette base */}
      <g fill="#C2410C">
        <circle cx="20" cy="12" r="7" />
        <path d="M8 40 L12 28 C14 24 17 22 20 22 C23 22 26 24 28 28 L32 40 Z" />
      </g>
      {/* Wrench badge */}
      <g transform="translate(28, 2)">
        <circle cx="6" cy="6" r="6" fill="#FED7AA" />
        <path d="M4 4 L8 8 M8 4 L4 8" stroke="#C2410C" strokeWidth="2" strokeLinecap="round" />
      </g>
    </g>
  );
}

// Dog silhouette
function DogSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Body */}
      <ellipse cx="20" cy="24" rx="12" ry="8" />
      {/* Head */}
      <circle cx="20" cy="14" r="7" />
      {/* Ears */}
      <ellipse cx="13" cy="10" rx="3" ry="5" />
      <ellipse cx="27" cy="10" rx="3" ry="5" />
      {/* Snout */}
      <ellipse cx="20" cy="17" rx="3" ry="2" />
    </g>
  );
}

// Cat silhouette
function CatSilhouette({ color }: { color: string }) {
  return (
    <g fill={color}>
      {/* Body */}
      <ellipse cx="20" cy="26" rx="10" ry="7" />
      {/* Head */}
      <circle cx="20" cy="15" r="7" />
      {/* Pointed ears */}
      <polygon points="12,12 14,6 17,12" />
      <polygon points="28,12 26,6 23,12" />
      {/* Whiskers area */}
      <ellipse cx="20" cy="17" rx="2" ry="1.5" />
    </g>
  );
}

export function Avatar({ name, type, size = 'md', colorIndex, className = '' }: AvatarProps) {
  const pixelSize = sizes[size];
  const color = colors[colorIndex ?? getColorIndex(name)];
  
  // Manager and Handyman have fixed colors
  const bgColor = type === 'manager' ? '#F5F0E8' : 
                  type === 'handyman' ? '#FFEDD5' : 
                  color.bg;
  
  return (
    <svg 
      width={pixelSize} 
      height={pixelSize} 
      viewBox="0 0 40 40" 
      className={`rounded-full flex-shrink-0 ${className}`}
      style={{ backgroundColor: bgColor }}
    >
      {type === 'male' && <MaleSilhouette color={color.fill} />}
      {type === 'female' && <FemaleSilhouette color={color.fill} />}
      {type === 'boy' && <BoySilhouette color={color.fill} />}
      {type === 'girl' && <GirlSilhouette color={color.fill} />}
      {type === 'manager' && <ManagerSilhouette />}
      {type === 'handyman' && <HandymanSilhouette />}
      {type === 'pet-dog' && <DogSilhouette color={color.fill} />}
      {type === 'pet-cat' && <CatSilhouette color={color.fill} />}
    </svg>
  );
}

// Vendor Avatar - Uses initials with category icon
interface VendorAvatarProps {
  name: string;
  category?: string;
  size?: AvatarSize;
  colorIndex?: number;
  className?: string;
}

export function VendorAvatar({ name, category, size = 'md', colorIndex, className = '' }: VendorAvatarProps) {
  const pixelSize = sizes[size];
  const color = colors[colorIndex ?? getColorIndex(name)];
  
  // Get initials (first letter of first two words)
  const initials = name
    .split(' ')
    .slice(0, 2)
    .map(word => word[0])
    .join('')
    .toUpperCase();
  
  const fontSize = pixelSize * 0.35;
  
  return (
    <div 
      className={`rounded-xl flex items-center justify-center font-semibold flex-shrink-0 ${className}`}
      style={{ 
        width: pixelSize, 
        height: pixelSize, 
        backgroundColor: color.bg,
        color: color.fill,
        fontSize: fontSize,
      }}
    >
      {initials}
    </div>
  );
}

// Convenience exports
export function ManagerAvatar({ size = 'md', className = '' }: { size?: AvatarSize; className?: string }) {
  return <Avatar name="Sarah Chen" type="manager" size={size} className={className} />;
}

export function HandymanAvatar({ size = 'md', className = '' }: { size?: AvatarSize; className?: string }) {
  return <Avatar name="Mike Rodriguez" type="handyman" size={size} className={className} />;
}

export default Avatar;
```

---

## USAGE

### Family Members

```tsx
import { Avatar } from '@/components/ui/Avatar';

// Adults
<Avatar name="Bob Thompson" type="male" size="lg" />
<Avatar name="Alice Thompson" type="female" size="lg" />

// Kids
<Avatar name="Jack Thompson" type="boy" size="lg" />
<Avatar name="Emma Thompson" type="girl" size="lg" />

// Pets
<Avatar name="Max" type="pet-dog" size="lg" />
<Avatar name="Whiskers" type="pet-cat" size="lg" />
```

### Manager & Handyman

```tsx
import { ManagerAvatar, HandymanAvatar } from '@/components/ui/Avatar';

<ManagerAvatar size="lg" />  // Sarah Chen - champagne bg, star badge
<HandymanAvatar size="lg" /> // Mike Rodriguez - orange bg, tool badge
```

### Vendors (Find Pros Page)

```tsx
import { VendorAvatar } from '@/components/ui/Avatar';

// Each vendor gets unique color based on name
<VendorAvatar name="Elite Plumbing Co" size="md" />        // Color 1
<VendorAvatar name="AirFlow HVAC" size="md" />              // Color 2
<VendorAvatar name="Green Thumb Landscaping" size="md" />   // Color 3
<VendorAvatar name="Wilson Electric" size="md" />           // Color 4

// Or force specific colors for visual variety
<VendorAvatar name="Elite Plumbing" colorIndex={0} />  // Navy
<VendorAvatar name="AirFlow HVAC" colorIndex={1} />    // Teal
<VendorAvatar name="Green Thumb" colorIndex={2} />     // Violet
```

---

## FIND PROS PAGE - VENDOR CARDS

### File: `apps/web/src/app/app/find-pros/page.tsx`

Each vendor card should use VendorAvatar with automatic color assignment:

```tsx
import { VendorAvatar } from '@/components/ui/Avatar';

{vendors.map((vendor, index) => (
  <div key={vendor.id} className="bg-white rounded-xl border border-warm-200 p-4 flex items-start gap-4">
    <VendorAvatar 
      name={vendor.name} 
      category={vendor.category}
      size="lg"
      // Colors automatically vary based on name
      // Or use index for guaranteed variety: colorIndex={index % 12}
    />
    <div className="flex-1">
      <h3 className="font-semibold text-warm-900">{vendor.name}</h3>
      <p className="text-sm text-warm-500">{vendor.category}</p>
      <div className="flex items-center gap-1 mt-1">
        <Star className="w-4 h-4 text-amber-400 fill-current" />
        <span className="text-sm font-medium">{vendor.rating}</span>
        <span className="text-sm text-warm-400">({vendor.reviewCount})</span>
      </div>
    </div>
  </div>
))}
```

---

## FILES TO UPDATE

| Page | What to Update |
|------|----------------|
| **Dashboard** | Sarah → `<ManagerAvatar />`, Bob/Alice → `<Avatar type="male/female" />` |
| **Sarah page** | Sarah Chen → `<ManagerAvatar />` |
| **Family page** | All members with appropriate `type` (male/female/boy/girl/pet-dog/pet-cat) |
| **Maintenance** | Mike → `<HandymanAvatar />` |
| **Find Pros** | All vendors → `<VendorAvatar />` with varied colors |
| **Vendors list** | All vendors → `<VendorAvatar />` |
| **Homepage** | Chat mockup Sarah, Handyman section Mike |

---

## NAME FIX

Search and replace:
- "Sarah Harrison" → "Sarah Chen"
- Ensure consistency everywhere

---

## VISUAL SUMMARY

```
PEOPLE:
┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│  ○      │  │  ○○     │  │  ○      │  │ ○ ○ ○   │
│ /│\     │  │ /│\     │  │ /│\     │  │  /│\    │
│ MALE    │  │ FEMALE  │  │  BOY    │  │  GIRL   │
└─────────┘  └─────────┘  └─────────┘  └─────────┘

SPECIAL:
┌─────────┐  ┌─────────┐
│  ○  ⭐  │  │  ○  🔧  │
│ /│\     │  │ /│\     │
│ MANAGER │  │HANDYMAN │
│champagne│  │ orange  │
└─────────┘  └─────────┘

VENDORS:
┌─────────┐  ┌─────────┐  ┌─────────┐
│         │  │         │  │         │
│   EP    │  │   AH    │  │   GT    │
│  navy   │  │  teal   │  │ violet  │
└─────────┘  └─────────┘  └─────────┘
(rounded squares with initials, varied colors)
```

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Read HAVEN_AVATAR_SYSTEM.md and implement the simple avatar system:

1. Create apps/web/src/components/ui/Avatar.tsx with:
   - SVG silhouette avatars for: male, female, boy, girl, pet-dog, pet-cat
   - ManagerAvatar (female silhouette + star badge, champagne background)
   - HandymanAvatar (male silhouette + tool badge, orange background)
   - VendorAvatar (rounded square with initials, varied colors from 12-color palette)
   - Color auto-assigned from name for consistency

2. Update all pages to use new avatars:
   - Dashboard: ManagerAvatar for Sarah, Avatar type="male/female" for Bob/Alice
   - Sarah page: ManagerAvatar, name "Sarah Chen"
   - Family page: Appropriate types for each member
   - Maintenance: HandymanAvatar for Mike
   - Find Pros: VendorAvatar for all vendors with varied colors
   - Homepage: Update chat mockup and handyman section

3. Fix "Sarah Harrison" → "Sarah Chen" everywhere

4. On Find Pros page, ensure each vendor card has a different colored VendorAvatar

Run pnpm build to verify.
```

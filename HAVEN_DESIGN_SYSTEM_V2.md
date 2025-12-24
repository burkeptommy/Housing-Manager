# HAVEN DESIGN SYSTEM
## Visual Identity & Component Standards

**Last Updated:** December 24, 2025
**Version:** 2.0

---

## BRAND IDENTITY

### Brand Essence
Haven represents **calm**, **trust**, and **competence**. Our visual language should feel like coming home—warm, sophisticated, and reassuring. We're not a flashy tech startup; we're a trusted partner in homeownership.

### Brand Values
- **Trustworthy** — We handle what matters most
- **Sophisticated** — Premium without pretension
- **Calm** — Reducing chaos, not adding to it
- **Human** — Technology with a personal touch

---

## COLOR PALETTE

### Primary Colors

#### Navy (Primary Brand Color)
The foundation of Haven's identity. Used for primary UI elements, text, and branding.

```css
/* Navy Palette */
--haven-navy-50: #f0f4f8;
--haven-navy-100: #d9e2ec;
--haven-navy-200: #bcccdc;
--haven-navy-300: #9fb3c8;
--haven-navy-400: #829ab1;
--haven-navy-500: #627d98;
--haven-navy-600: #486581;
--haven-navy-700: #334e68;
--haven-navy-800: #243b53;  /* Primary Dark */
--haven-navy-900: #102a43;  /* Deepest Navy */
--haven-navy-950: #0a1929;  /* Sidebar Background */
```

**Usage:**
- `navy-950` — Sidebar background
- `navy-900` — Primary headings, important text
- `navy-800` — Secondary headings, body text
- `navy-700` — Hover states on dark backgrounds
- `navy-100-300` — Light backgrounds, borders

#### Champagne (Accent Color)
Warm, sophisticated accent that complements navy. Used for highlights, CTAs, and success states.

```css
/* Champagne/Gold Palette */
--haven-champagne-50: #fdfcf9;
--haven-champagne-100: #faf6ed;
--haven-champagne-200: #f4ebda;
--haven-champagne-300: #e9dcc4;
--haven-champagne-400: #d4c4a5;
--haven-champagne-500: #c4a574;  /* Primary Champagne */
--haven-champagne-600: #b08d54;
--haven-champagne-700: #937542;
--haven-champagne-800: #7a6038;
--haven-champagne-900: #654f30;
```

**Usage:**
- `champagne-500` — Primary accent, highlighted text
- `champagne-400` — Hover states
- `champagne-100-200` — Subtle backgrounds, cards

### Neutral Colors

#### White & Gray
Clean, professional backgrounds and surfaces.

```css
/* Neutral Palette */
--haven-white: #ffffff;
--haven-gray-50: #f9fafb;
--haven-gray-100: #f3f4f6;
--haven-gray-200: #e5e7eb;
--haven-gray-300: #d1d5db;
--haven-gray-400: #9ca3af;
--haven-gray-500: #6b7280;
--haven-gray-600: #4b5563;
--haven-gray-700: #374151;
--haven-gray-800: #1f2937;
--haven-gray-900: #111827;
```

**Usage:**
- `white` — Main content background
- `gray-50` — Page backgrounds
- `gray-100` — Card backgrounds, alternating rows
- `gray-200` — Borders, dividers
- `gray-500` — Secondary text, placeholders

### Semantic Colors

#### Status Colors
Used sparingly for system feedback. NOT brand colors.

```css
/* Success - Muted Green (sparingly) */
--haven-success-light: #ecfdf5;
--haven-success: #059669;
--haven-success-dark: #047857;

/* Warning - Amber */
--haven-warning-light: #fffbeb;
--haven-warning: #d97706;
--haven-warning-dark: #b45309;

/* Error - Red */
--haven-error-light: #fef2f2;
--haven-error: #dc2626;
--haven-error-dark: #b91c1c;

/* Info - Blue */
--haven-info-light: #eff6ff;
--haven-info: #2563eb;
--haven-info-dark: #1d4ed8;
```

**⚠️ CRITICAL: No Bright Green**
The previous brand used bright/lime green (`#10b981`, `#22c55e`). This has been **deprecated**. Use champagne for positive accents and muted success green only for explicit success states (checkmarks, confirmations).

---

## COLOR APPLICATION

### Sidebar
```css
.sidebar {
  background: var(--haven-navy-950);  /* #0a1929 */
  color: var(--haven-gray-300);
}

.sidebar-item:hover {
  background: var(--haven-navy-800);
}

.sidebar-item.active {
  background: var(--haven-navy-800);
  color: var(--haven-white);
}

.sidebar-badge {
  background: var(--haven-champagne-500);
  color: var(--haven-navy-900);
}
```

### Main Content Area
```css
.main-content {
  background: var(--haven-gray-50);
}

.card {
  background: var(--haven-white);
  border: 1px solid var(--haven-gray-200);
}

.card-header {
  color: var(--haven-navy-900);
}

.card-text {
  color: var(--haven-gray-600);
}
```

### Buttons

```css
/* Primary Button */
.btn-primary {
  background: var(--haven-navy-900);
  color: var(--haven-white);
}

.btn-primary:hover {
  background: var(--haven-navy-800);
}

/* Secondary Button */
.btn-secondary {
  background: var(--haven-white);
  border: 1px solid var(--haven-gray-300);
  color: var(--haven-navy-800);
}

/* Accent Button (CTAs) */
.btn-accent {
  background: var(--haven-champagne-500);
  color: var(--haven-navy-900);
}

.btn-accent:hover {
  background: var(--haven-champagne-400);
}
```

### Status Indicators
```css
/* Use sparingly - not for decoration */
.status-excellent { color: var(--haven-success); }
.status-good { color: var(--haven-info); }
.status-due-soon { color: var(--haven-warning); }
.status-needs-attention { color: var(--haven-error); }
```

---

## TYPOGRAPHY

### Font Stack
```css
--font-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
--font-display: 'Inter', var(--font-sans);
```

### Type Scale
```css
/* Headings */
.text-4xl { font-size: 2.25rem; line-height: 2.5rem; }   /* Page titles */
.text-3xl { font-size: 1.875rem; line-height: 2.25rem; } /* Section headers */
.text-2xl { font-size: 1.5rem; line-height: 2rem; }      /* Card titles */
.text-xl { font-size: 1.25rem; line-height: 1.75rem; }   /* Subsection */
.text-lg { font-size: 1.125rem; line-height: 1.75rem; }  /* Emphasis */

/* Body */
.text-base { font-size: 1rem; line-height: 1.5rem; }     /* Default body */
.text-sm { font-size: 0.875rem; line-height: 1.25rem; }  /* Secondary */
.text-xs { font-size: 0.75rem; line-height: 1rem; }      /* Captions */
```

### Font Weights
```css
.font-normal { font-weight: 400; }  /* Body text */
.font-medium { font-weight: 500; }  /* Emphasis, labels */
.font-semibold { font-weight: 600; } /* Headings, buttons */
.font-bold { font-weight: 700; }     /* Strong emphasis */
```

---

## SPACING

### Spacing Scale (Tailwind)
```
space-1: 0.25rem (4px)
space-2: 0.5rem (8px)
space-3: 0.75rem (12px)
space-4: 1rem (16px)
space-5: 1.25rem (20px)
space-6: 1.5rem (24px)
space-8: 2rem (32px)
space-10: 2.5rem (40px)
space-12: 3rem (48px)
space-16: 4rem (64px)
```

### Common Patterns
```css
/* Card padding */
.card { padding: var(--space-6); }

/* Section spacing */
.section { margin-bottom: var(--space-8); }

/* Form field spacing */
.form-group { margin-bottom: var(--space-4); }

/* List item spacing */
.list-item { padding: var(--space-4) var(--space-6); }
```

---

## COMPONENTS

### Cards
```jsx
<Card>
  <CardHeader>
    <CardTitle>Card Title</CardTitle>
    <CardDescription>Supporting text</CardDescription>
  </CardHeader>
  <CardContent>
    {/* Content */}
  </CardContent>
</Card>
```

**Styles:**
```css
.card {
  background: white;
  border-radius: 0.75rem;
  border: 1px solid var(--haven-gray-200);
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.05);
}
```

### Buttons
```jsx
{/* Primary - Main actions */}
<Button variant="primary">Get Started</Button>

{/* Secondary - Alternative actions */}
<Button variant="secondary">Learn More</Button>

{/* Accent - CTAs, highlights */}
<Button variant="accent">Approve</Button>

{/* Ghost - Subtle actions */}
<Button variant="ghost">Cancel</Button>

{/* Destructive - Dangerous actions */}
<Button variant="destructive">Delete</Button>
```

### Status Badges
```jsx
{/* System status */}
<Badge variant="excellent">Excellent</Badge>
<Badge variant="good">Good</Badge>
<Badge variant="due-soon">Due Soon</Badge>
<Badge variant="attention">Needs Attention</Badge>

{/* Location badges */}
<Badge variant="location">At Home</Badge>
<Badge variant="location">At Work</Badge>
<Badge variant="location">At School</Badge>
```

### Avatar/Initials
```jsx
{/* Person avatar with initials */}
<Avatar>
  <AvatarFallback style={{ 
    background: 'var(--haven-navy-700)',
    color: 'white' 
  }}>
    BM
  </AvatarFallback>
</Avatar>

{/* Colored variants for family members */}
<Avatar variant="primary">BM</Avatar>   {/* Navy */}
<Avatar variant="secondary">AM</Avatar> {/* Champagne */}
<Avatar variant="child">EM</Avatar>     {/* Lighter variants */}
```

### Navigation (Sidebar)
```jsx
<Sidebar>
  <SidebarHeader>
    <Logo />
  </SidebarHeader>
  
  <SidebarSection label="OVERVIEW">
    <SidebarItem icon={Dashboard} active>Dashboard</SidebarItem>
    <SidebarItem icon={User} badge={5}>Sarah</SidebarItem>
    <SidebarItem icon={Message}>Messages</SidebarItem>
    <SidebarItem icon={Calendar}>Calendar</SidebarItem>
  </SidebarSection>
  
  <SidebarSection label="YOUR HOME">
    <SidebarItem icon={Home}>Your Home</SidebarItem>
    <SidebarItem icon={Users}>Family</SidebarItem>
    {/* ... */}
  </SidebarSection>
</Sidebar>
```

---

## ICONS

### Icon System: Lucide React

```jsx
import { 
  Home, 
  Users, 
  Calendar,
  DollarSign,
  Settings,
  MessageSquare,
  Wrench,
  Search,
  Bell,
  ChevronRight
} from 'lucide-react';
```

### Icon Sizes
```css
.icon-sm { width: 16px; height: 16px; }
.icon-md { width: 20px; height: 20px; }
.icon-lg { width: 24px; height: 24px; }
.icon-xl { width: 32px; height: 32px; }
```

---

## LAYOUT PATTERNS

### App Shell
```
┌─────────────────────────────────────────────────────────┐
│ ┌─────────┐ ┌─────────────────────────────────────────┐ │
│ │         │ │ Header                                  │ │
│ │         │ └─────────────────────────────────────────┘ │
│ │ Sidebar │ ┌─────────────────────────────────────────┐ │
│ │         │ │                                         │ │
│ │ (240px) │ │ Main Content (scrollable)               │ │
│ │         │ │                                         │ │
│ │         │ │                                         │ │
│ └─────────┘ └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Page Layout
```jsx
<div className="p-8">
  {/* Page Header */}
  <div className="mb-8">
    <h1 className="text-3xl font-semibold text-navy-900">Page Title</h1>
    <p className="text-gray-500 mt-1">Page description</p>
  </div>
  
  {/* Page Content */}
  <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <div className="lg:col-span-2">
      {/* Main content */}
    </div>
    <div>
      {/* Sidebar content */}
    </div>
  </div>
</div>
```

### Dashboard Cards Grid
```jsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  <StatCard title="Home Health" value="94%" status="excellent" />
  <StatCard title="Items Handled" value="4" />
  <StatCard title="Next Service" value="Jan 7" />
  <StatCard title="Weather" value="68°" />
</div>
```

---

## TAILWIND CONFIGURATION

### tailwind.config.js
```js
module.exports = {
  theme: {
    extend: {
      colors: {
        haven: {
          navy: {
            50: '#f0f4f8',
            100: '#d9e2ec',
            200: '#bcccdc',
            300: '#9fb3c8',
            400: '#829ab1',
            500: '#627d98',
            600: '#486581',
            700: '#334e68',
            800: '#243b53',
            900: '#102a43',
            950: '#0a1929',
          },
          champagne: {
            50: '#fdfcf9',
            100: '#faf6ed',
            200: '#f4ebda',
            300: '#e9dcc4',
            400: '#d4c4a5',
            500: '#c4a574',
            600: '#b08d54',
            700: '#937542',
            800: '#7a6038',
            900: '#654f30',
          },
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
}
```

---

## MIGRATION NOTES

### Removing Old Green Accents

Search and replace these patterns:

```
OLD                          NEW
---------------------------  ---------------------------
bg-green-500                 bg-haven-champagne-500
bg-green-600                 bg-haven-navy-800
bg-emerald-500               bg-haven-champagne-500
text-green-600               text-haven-champagne-600
text-emerald-600             text-haven-champagne-600
border-green-500             border-haven-champagne-500
#10b981                      #c4a574 (champagne-500)
#22c55e                      #c4a574 (champagne-500)
#059669                      #b08d54 (champagne-600)
```

### Files to Update
1. `apps/web/src/app/globals.css` — CSS variables
2. `apps/web/tailwind.config.js` — Theme extension
3. `apps/web/src/components/**` — Component classes
4. `packages/ui/**` — Shared component library

---

## ACCESSIBILITY

### Color Contrast
All text combinations must meet WCAG 2.1 AA standards:
- Navy-900 on white: ✅ 14.5:1
- Navy-800 on white: ✅ 10.9:1
- Champagne-600 on navy-950: ✅ 6.2:1
- Gray-500 on white: ✅ 4.6:1

### Focus States
```css
:focus-visible {
  outline: 2px solid var(--haven-navy-600);
  outline-offset: 2px;
}
```

---

## SUMMARY

### The Haven Visual Formula

1. **Navy sidebar** (950) with white/gray text
2. **White/light gray** main content areas
3. **Champagne accents** for CTAs and highlights
4. **Muted semantic colors** only for status (success/warning/error)
5. **No bright green** — it's been retired

### Quick Reference
| Element | Color |
|---------|-------|
| Sidebar background | navy-950 |
| Sidebar text | gray-300 |
| Page background | gray-50 |
| Card background | white |
| Primary text | navy-900 |
| Secondary text | gray-500 |
| Primary button | navy-900 |
| Accent/CTA | champagne-500 |
| Success indicator | success (muted green) |
| Warning indicator | warning (amber) |
| Error indicator | error (red) |

---

*Navy + Champagne + White = Haven*
*Sophisticated. Trustworthy. Calm.*

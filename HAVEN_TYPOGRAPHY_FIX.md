# 🎨 HAVEN - TYPOGRAPHY & CONTRAST FIX

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this entire prompt.

---

## ISSUE 1: FONT INCONSISTENCY

### The Problem
Fonts are applied inconsistently - some headings are serif, some are sans, card content varies randomly.

### The Solution: Clear Typography Hierarchy

**Playfair Display (serif)** - Use ONLY for:
- Main page titles (h1) like "Good morning, Bob", "Dashboard", "Messages"
- That's it. Nothing else.

**Inter (sans-serif)** - Use for EVERYTHING else:
- Card titles
- Stat values
- Labels
- Body text
- Buttons
- Navigation items
- Form fields
- Badges
- Everything else

---

## ISSUE 2: CONTRAST PROBLEMS

### The Problem
Black text on dark backgrounds (green cards, slate sections) is unreadable.

### The Solution
- Dark backgrounds → White/light text
- Light backgrounds → Dark text
- Always ensure WCAG AA contrast ratio (4.5:1 minimum)

---

## IMPLEMENTATION

### Step 1: Update Global CSS

**File:** `apps/web/src/app/globals.css`

Replace the entire file with:

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Playfair+Display:wght@500;600;700&display=swap');

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
  }
  
  /* ONLY h1 gets serif font - main page titles only */
  h1 {
    @apply font-serif tracking-tight;
  }
  
  /* All other headings use sans-serif */
  h2, h3, h4, h5, h6 {
    @apply font-sans font-semibold tracking-tight;
  }
  
  ::selection {
    @apply bg-haven-200 text-haven-900;
  }
  
  /* Scrollbars */
  ::-webkit-scrollbar {
    width: 6px;
    height: 6px;
  }
  
  ::-webkit-scrollbar-track {
    @apply bg-transparent;
  }
  
  ::-webkit-scrollbar-thumb {
    @apply bg-warm-300 rounded-full hover:bg-warm-400;
  }
  
  .dark-scrollbar::-webkit-scrollbar-thumb {
    @apply bg-white/20 hover:bg-white/30;
  }
  
  *:focus {
    outline: none;
  }
  
  *:focus-visible {
    @apply ring-2 ring-haven-500/30 ring-offset-2;
  }
}

@layer components {
  /* ===================================================================
     PAGE TITLES - The only place we use serif font
     =================================================================== */
  .page-title {
    @apply font-serif text-2xl sm:text-3xl font-bold text-warm-900;
  }
  
  /* ===================================================================
     SIDEBAR STYLES (Deep Forest Green)
     =================================================================== */
  .sidebar {
    @apply bg-gradient-to-b from-forest-900 to-forest-950 text-white;
  }
  
  .sidebar-nav-item {
    @apply flex items-center gap-3 px-4 py-3 rounded-xl font-medium
           text-white/70 transition-all duration-200
           hover:bg-white/10 hover:text-white;
  }
  
  .sidebar-nav-item-active {
    @apply bg-white/15 text-white;
  }
  
  .sidebar-nav-icon {
    @apply w-5 h-5 opacity-60;
  }
  
  .sidebar-nav-item-active .sidebar-nav-icon {
    @apply text-haven-400 opacity-100;
  }
  
  .sidebar-section-title {
    @apply text-xs font-semibold text-white/40 uppercase tracking-wider px-4 mb-2;
  }
  
  .sidebar-badge {
    @apply ml-auto px-2 py-0.5 text-xs font-bold rounded-full bg-haven-500 text-white;
  }
  
  .sidebar-property-selector {
    @apply w-full p-3 rounded-xl bg-white/5 hover:bg-white/10 
           transition-colors cursor-pointer border border-white/10;
  }
  
  .sidebar-user-name {
    @apply font-medium text-white text-sm truncate;
  }
  
  .sidebar-user-role {
    @apply text-xs text-white/50;
  }

  /* ===================================================================
     CARDS - All text is sans-serif
     =================================================================== */
  .card {
    @apply bg-white rounded-2xl border border-warm-100 shadow-soft;
  }
  
  .card-hover {
    @apply transition-all duration-200 hover:shadow-soft-lg hover:border-warm-200 hover:-translate-y-0.5;
  }
  
  .card-title {
    @apply font-semibold text-warm-900;
  }
  
  .card-description {
    @apply text-sm text-warm-500;
  }

  /* ===================================================================
     DARK CARDS (Green, Slate, etc.) - WHITE TEXT ALWAYS
     =================================================================== */
  .card-dark {
    @apply text-white;
  }
  
  .card-dark .card-title,
  .card-dark h2,
  .card-dark h3,
  .card-dark h4 {
    @apply text-white;
  }
  
  .card-dark .card-description,
  .card-dark p {
    @apply text-white/70;
  }
  
  /* Green gradient cards */
  .card-green {
    @apply bg-gradient-to-br from-haven-500 to-haven-600 text-white border-0;
  }
  
  .card-green h2,
  .card-green h3,
  .card-green h4,
  .card-green .card-title {
    @apply text-white;
  }
  
  .card-green p,
  .card-green .card-description {
    @apply text-white/80;
  }
  
  .card-green .text-muted {
    @apply text-haven-100;
  }
  
  /* Forest/dark green cards */
  .card-forest {
    @apply bg-gradient-to-br from-forest-800 to-forest-900 text-white border-0;
  }
  
  .card-forest h2,
  .card-forest h3,
  .card-forest h4,
  .card-forest .card-title {
    @apply text-white;
  }
  
  .card-forest p,
  .card-forest .card-description {
    @apply text-white/70;
  }
  
  /* Slate/dark gray cards */
  .card-slate {
    @apply bg-gradient-to-br from-warm-800 to-warm-900 text-white border-0;
  }
  
  .card-slate h2,
  .card-slate h3,
  .card-slate h4,
  .card-slate .card-title {
    @apply text-white;
  }
  
  .card-slate p,
  .card-slate .card-description {
    @apply text-white/70;
  }
  
  .card-slate .stat-value {
    @apply text-white;
  }

  /* ===================================================================
     STAT CARDS
     =================================================================== */
  .stat-card {
    @apply card p-6;
  }
  
  .stat-value {
    @apply text-3xl font-bold text-warm-900 tabular-nums;
  }
  
  .stat-label {
    @apply text-sm text-warm-500 mt-1;
  }
  
  /* Dark stat cards need white text */
  .stat-card-dark .stat-value {
    @apply text-white;
  }
  
  .stat-card-dark .stat-label {
    @apply text-white/70;
  }

  /* ===================================================================
     HERO/BANNER SECTIONS (Dark backgrounds)
     =================================================================== */
  .hero-dark {
    @apply text-white;
  }
  
  .hero-dark h1 {
    @apply text-white;
  }
  
  .hero-dark p {
    @apply text-white/80;
  }
  
  .hero-dark .text-muted {
    @apply text-white/60;
  }

  /* ===================================================================
     BUTTONS
     =================================================================== */
  .btn {
    @apply inline-flex items-center justify-center gap-2 font-medium rounded-xl
           transition-all duration-200 active:scale-[0.98]
           disabled:opacity-50 disabled:cursor-not-allowed;
  }
  
  .btn-primary {
    @apply btn px-5 py-2.5 
           bg-gradient-to-b from-haven-500 to-haven-600 
           text-white font-medium
           shadow-[0_1px_2px_rgba(0,0,0,0.1),0_2px_4px_rgba(0,0,0,0.1),inset_0_1px_0_rgba(255,255,255,0.1)]
           hover:from-haven-600 hover:to-haven-700;
  }
  
  .btn-secondary {
    @apply btn px-5 py-2.5 
           bg-white text-warm-700 
           border border-warm-200 shadow-sm
           hover:bg-warm-50 hover:border-warm-300 hover:text-warm-900;
  }
  
  .btn-ghost {
    @apply btn px-4 py-2 
           text-warm-600 
           hover:bg-warm-100 hover:text-warm-900;
  }
  
  /* Ghost button on dark backgrounds */
  .btn-ghost-light {
    @apply btn px-4 py-2 
           text-white/70 
           hover:bg-white/10 hover:text-white;
  }
  
  /* White button for dark backgrounds */
  .btn-white {
    @apply btn px-5 py-2.5
           bg-white text-warm-800
           shadow-lg
           hover:bg-warm-50;
  }
  
  /* Outline button on dark backgrounds */
  .btn-outline-light {
    @apply btn px-5 py-2.5
           bg-transparent text-white
           border border-white/30
           hover:bg-white/10 hover:border-white/50;
  }

  .btn-sm { @apply px-3 py-1.5 text-sm rounded-lg; }
  .btn-lg { @apply px-6 py-3 text-base; }

  /* ===================================================================
     INPUTS
     =================================================================== */
  .input {
    @apply w-full px-4 py-3 
           bg-white border border-warm-200 rounded-xl
           text-warm-800 placeholder:text-warm-400
           transition-all duration-200
           hover:border-warm-300
           focus:border-haven-500 focus:ring-2 focus:ring-haven-500/20;
  }

  /* ===================================================================
     BADGES
     =================================================================== */
  .badge {
    @apply inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium;
  }
  
  .badge-success { @apply bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/20; }
  .badge-warning { @apply bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-600/20; }
  .badge-error { @apply bg-red-50 text-red-700 ring-1 ring-inset ring-red-600/20; }
  .badge-info { @apply bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-600/20; }
  .badge-neutral { @apply bg-warm-100 text-warm-700; }
  .badge-premium { @apply bg-gradient-to-r from-gold-100 to-gold-200 text-gold-800; }
  
  /* Badges on dark backgrounds */
  .badge-light {
    @apply bg-white/20 text-white;
  }

  /* ===================================================================
     AVATARS
     =================================================================== */
  .avatar {
    @apply relative inline-flex items-center justify-center rounded-full 
           bg-gradient-to-br from-haven-400 to-haven-600 
           text-white font-semibold
           ring-2 ring-white shadow-sm;
  }
  
  .avatar-sm { @apply w-8 h-8 text-xs; }
  .avatar-md { @apply w-10 h-10 text-sm; }
  .avatar-lg { @apply w-12 h-12 text-base; }
  .avatar-xl { @apply w-16 h-16 text-lg; }
  .avatar-2xl { @apply w-24 h-24 text-2xl; }

  /* ===================================================================
     TABLES
     =================================================================== */
  .table-container {
    @apply overflow-x-auto rounded-xl border border-warm-100 bg-white;
  }
  
  .table {
    @apply w-full text-sm;
  }
  
  .table th {
    @apply px-4 py-3 text-left text-xs font-semibold text-warm-500 
           uppercase tracking-wider bg-warm-50 border-b border-warm-100;
  }
  
  .table td {
    @apply px-4 py-4 text-warm-700 border-b border-warm-100;
  }
  
  .table tr:last-child td {
    @apply border-b-0;
  }
  
  .table tbody tr:hover td {
    @apply bg-warm-50/50;
  }

  /* ===================================================================
     SKELETONS
     =================================================================== */
  .skeleton {
    @apply bg-gradient-to-r from-warm-200 via-warm-100 to-warm-200 
           bg-[length:200%_100%] animate-shimmer rounded-lg;
  }
  
  .skeleton-dark {
    @apply bg-gradient-to-r from-white/10 via-white/5 to-white/10
           bg-[length:200%_100%] animate-shimmer rounded-lg;
  }

  /* ===================================================================
     EMPTY STATES
     =================================================================== */
  .empty-state {
    @apply text-center py-16 px-8;
  }
  
  .empty-state-icon {
    @apply w-16 h-16 rounded-2xl bg-warm-100 
           flex items-center justify-center mx-auto mb-4 text-warm-400;
  }
  
  .empty-state-title {
    @apply font-semibold text-warm-900 mb-2;
  }
  
  .empty-state-description {
    @apply text-warm-500 max-w-sm mx-auto;
  }

  /* ===================================================================
     MODALS
     =================================================================== */
  .modal-overlay {
    @apply fixed inset-0 bg-forest-950/60 backdrop-blur-sm z-50
           flex items-center justify-center p-4;
  }
  
  .modal {
    @apply bg-white rounded-2xl shadow-xl max-w-lg w-full 
           max-h-[90vh] overflow-hidden animate-scale-in;
  }
  
  .modal-header {
    @apply px-6 py-4 border-b border-warm-100;
  }
  
  .modal-title {
    @apply font-semibold text-warm-900;
  }
  
  .modal-body {
    @apply px-6 py-4 overflow-y-auto;
  }
  
  .modal-footer {
    @apply px-6 py-4 border-t border-warm-100 
           flex items-center justify-end gap-3 bg-warm-50;
  }
}

@layer utilities {
  /* Text on dark backgrounds - use these explicitly when needed */
  .text-on-dark {
    @apply text-white;
  }
  
  .text-on-dark-muted {
    @apply text-white/70;
  }
  
  .text-on-dark-subtle {
    @apply text-white/50;
  }
  
  /* Text on light backgrounds */
  .text-on-light {
    @apply text-warm-900;
  }
  
  .text-on-light-muted {
    @apply text-warm-500;
  }
  
  /* Animation delays for staggered effects */
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
}
```

### Step 2: Fix All Page Files

Search through ALL files in `apps/web/src/app/` and fix these patterns:

#### Pattern 1: Page Titles
```tsx
// BEFORE (inconsistent)
<h1 className="text-2xl font-bold text-warm-900">Dashboard</h1>
<h1 className="font-serif text-3xl ...">Good morning</h1>
<div className="text-2xl font-semibold">Welcome</div>

// AFTER (consistent - only h1 page titles get serif via CSS)
<h1 className="page-title">Dashboard</h1>
<h1 className="page-title">Good morning, Bob</h1>
```

#### Pattern 2: Card Titles
```tsx
// BEFORE (some serif, some sans)
<h3 className="font-serif text-lg font-semibold">Card Title</h3>
<div className="font-semibold text-warm-900">Another Title</div>

// AFTER (always sans via .card-title class)
<h3 className="card-title text-lg">Card Title</h3>
<h3 className="card-title">Another Title</h3>
```

#### Pattern 3: Dark Background Cards - CRITICAL CONTRAST FIX
```tsx
// BEFORE (BLACK TEXT ON GREEN - UNREADABLE!)
<div className="bg-gradient-to-br from-haven-500 to-haven-600 p-6 rounded-2xl">
  <h2 className="text-xl font-bold text-warm-900">Good morning, Bob</h2>
  <p className="text-warm-600">Here's your daily summary</p>
</div>

// AFTER (WHITE TEXT ON GREEN - READABLE!)
<div className="card-green p-6 rounded-2xl">
  <h2 className="text-xl font-bold text-white">Good morning, Bob</h2>
  <p className="text-white/80">Here's your daily summary</p>
</div>

// OR use the card-dark class
<div className="bg-gradient-to-br from-haven-500 to-haven-600 p-6 rounded-2xl card-dark">
  <h2 className="text-xl font-bold">Good morning, Bob</h2>
  <p>Here's your daily summary</p>
</div>
```

#### Pattern 4: Slate/Dark Stat Cards - CRITICAL CONTRAST FIX
```tsx
// BEFORE (BLACK TEXT ON SLATE - INVISIBLE!)
<div className="bg-warm-800 p-6 rounded-2xl">
  <div className="text-3xl font-bold text-warm-900">$8,247.23</div>
  <div className="text-warm-600">Total Balance</div>
</div>

// AFTER (WHITE TEXT ON SLATE - VISIBLE!)
<div className="card-slate p-6 rounded-2xl">
  <div className="text-3xl font-bold text-white">$8,247.23</div>
  <div className="text-white/70">Total Balance</div>
</div>

// OR explicitly
<div className="bg-warm-800 p-6 rounded-2xl">
  <div className="text-3xl font-bold text-white">$8,247.23</div>
  <div className="text-white/70">Total Balance</div>
</div>
```

#### Pattern 5: Hero Sections
```tsx
// BEFORE
<div className="bg-forest-900 p-8">
  <h1 className="text-3xl font-bold text-warm-900">Welcome</h1>
</div>

// AFTER
<div className="bg-forest-900 p-8 hero-dark">
  <h1 className="text-3xl font-bold">Welcome</h1>
</div>
```

#### Pattern 6: Buttons on Dark Backgrounds
```tsx
// BEFORE (regular buttons don't show well on dark)
<div className="bg-haven-600 p-4">
  <button className="btn-secondary">Click me</button>
</div>

// AFTER (use white or outline-light buttons)
<div className="bg-haven-600 p-4">
  <button className="btn-white">Click me</button>
  <button className="btn-outline-light">Or me</button>
  <button className="btn-ghost-light">Ghost</button>
</div>
```

### Step 3: Specific Files to Update

Search and update these specific files for contrast issues:

**File:** `apps/web/src/app/app/page.tsx` (Homeowner Dashboard)
- Fix "Good morning, Bob" greeting card
- Fix any stat cards with dark backgrounds
- Ensure all card titles use `card-title` class

**File:** `apps/web/src/app/app/bills/page.tsx` or similar money page
- Fix the "$8,247.23" stat that's on slate background
- All money values on dark backgrounds need `text-white`

**File:** `apps/web/src/app/manager/page.tsx` (Manager Dashboard)
- Same fixes as homeowner

**File:** `apps/web/src/app/app/layout.tsx` (Sidebar)
- Already should be white text, but verify

**File:** `apps/web/src/app/manager/layout.tsx` (Manager Sidebar)
- Already should be white text, but verify

### Step 4: Component Updates

If there are reusable components, update them:

**File:** `apps/web/src/components/ui/stat-card.tsx` (if exists)
```tsx
interface StatCardProps {
  label: string;
  value: string | number;
  variant?: 'light' | 'dark' | 'green' | 'slate';
  // ...
}

export function StatCard({ label, value, variant = 'light', ...props }: StatCardProps) {
  const variantClasses = {
    light: 'card',
    dark: 'card-dark bg-warm-800',
    green: 'card-green',
    slate: 'card-slate',
  };
  
  return (
    <div className={`p-6 rounded-2xl ${variantClasses[variant]}`}>
      <div className={`text-3xl font-bold tabular-nums ${variant === 'light' ? 'text-warm-900' : 'text-white'}`}>
        {value}
      </div>
      <div className={`text-sm mt-1 ${variant === 'light' ? 'text-warm-500' : 'text-white/70'}`}>
        {label}
      </div>
    </div>
  );
}
```

### Step 5: Global Search and Replace

Run these searches across the entire `apps/web/src/` directory:

1. **Find dark backgrounds with dark text:**
   - Search: `bg-haven-` or `bg-forest-` or `bg-warm-800` or `bg-warm-900`
   - Check: Any `text-warm-` classes nearby? Change to `text-white`

2. **Find inconsistent heading fonts:**
   - Search: `font-serif`
   - Check: Is it on an h1 page title? If not, remove it.

3. **Find card titles without proper class:**
   - Search: `font-semibold text-warm-900` or `font-bold text-warm-900` inside cards
   - Check: Should use `card-title` class for consistency

---

## TYPOGRAPHY RULES SUMMARY

| Element | Font | Class |
|---------|------|-------|
| Page titles (h1) | Playfair Display (serif) | `page-title` |
| Card titles | Inter (sans) | `card-title` |
| Stat values | Inter (sans) | `stat-value` or `text-3xl font-bold` |
| Body text | Inter (sans) | Default |
| Labels | Inter (sans) | `text-sm text-warm-500` |
| Buttons | Inter (sans) | `btn-*` classes |
| Navigation | Inter (sans) | `sidebar-nav-item` |

## CONTRAST RULES SUMMARY

| Background | Text Color | Class Helper |
|------------|------------|--------------|
| White/Light (`bg-white`, `bg-warm-50`) | Dark (`text-warm-900`) | Default |
| Green (`bg-haven-*`) | White (`text-white`) | `card-green` |
| Forest (`bg-forest-*`) | White (`text-white`) | `card-forest` |
| Slate (`bg-warm-800/900`) | White (`text-white`) | `card-slate` |
| Any dark gradient | White | `card-dark` or `hero-dark` |

---

## RUN AFTER COMPLETION

```bash
cd apps/web
pnpm dev
```

Then visually check:
1. ✅ All page titles use elegant serif font
2. ✅ All other text uses clean sans-serif font  
3. ✅ All text on dark backgrounds is WHITE and readable
4. ✅ No more black-on-green or black-on-slate issues

🎨✨

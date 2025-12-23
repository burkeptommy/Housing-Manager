# 🏠 HAVEN - MASTER FIX PROMPT (ALL ISSUES)

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this entire prompt.

---

## ISSUES BEING FIXED

1. **Typography Consistency** - Serif only for h1 page titles, sans-serif everywhere else
2. **Contrast Issues** - White text on ALL dark backgrounds (green cards, slate, etc.)
3. **Vendor Map Card Bug** - Buttons/badges overflowing outside card
4. **Vendor Photos** - All showing same image, need unique per vendor
5. **User Avatars** - Switch to DiceBear illustrated avatars
6. **More Vendors** - Add 25+ vendors for better demo
7. **Project Planning** - Complete overhaul with phases, quotes, timeline
8. **Family Page** - Add Alice (wife), Emma, Jack, and Max (dog)

---

## PART 1: TYPOGRAPHY & CONTRAST (CRITICAL)

### 1.1 Update Global CSS

**File:** `apps/web/src/app/globals.css`

Replace the entire file:

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
  
  /* All other headings use sans-serif for consistency */
  h2, h3, h4, h5, h6 {
    @apply font-sans font-semibold tracking-tight;
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
  /* ===== PAGE TITLE - Only serif usage ===== */
  .page-title {
    @apply font-serif text-2xl sm:text-3xl font-bold text-warm-900;
  }
  
  /* ===== SIDEBAR (Deep Forest Green with WHITE text) ===== */
  .sidebar {
    @apply bg-gradient-to-b from-forest-900 to-forest-950;
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
  
  .sidebar-badge {
    @apply ml-auto px-2 py-0.5 text-xs font-bold rounded-full bg-haven-500 text-white;
  }
  
  .sidebar-property-selector {
    @apply w-full p-3 rounded-xl bg-white/5 hover:bg-white/10 
           transition-colors cursor-pointer border border-white/10;
  }

  /* ===== CARDS ===== */
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

  /* ===== DARK CARDS - WHITE TEXT ALWAYS ===== */
  
  /* Green gradient cards */
  .card-green {
    @apply bg-gradient-to-br from-haven-500 to-haven-600 rounded-2xl border-0;
  }
  
  .card-green,
  .card-green h1,
  .card-green h2,
  .card-green h3,
  .card-green h4,
  .card-green .card-title,
  .card-green .stat-value {
    @apply text-white;
  }
  
  .card-green p,
  .card-green .card-description,
  .card-green .stat-label {
    @apply text-white/80;
  }
  
  /* Forest dark green cards */
  .card-forest {
    @apply bg-gradient-to-br from-forest-800 to-forest-900 rounded-2xl border-0;
  }
  
  .card-forest,
  .card-forest h1,
  .card-forest h2,
  .card-forest h3,
  .card-forest h4,
  .card-forest .card-title,
  .card-forest .stat-value {
    @apply text-white;
  }
  
  .card-forest p,
  .card-forest .card-description,
  .card-forest .stat-label {
    @apply text-white/70;
  }
  
  /* Slate/dark gray cards */
  .card-slate {
    @apply bg-gradient-to-br from-warm-800 to-warm-900 rounded-2xl border-0;
  }
  
  .card-slate,
  .card-slate h1,
  .card-slate h2,
  .card-slate h3,
  .card-slate h4,
  .card-slate .card-title,
  .card-slate .stat-value {
    @apply text-white;
  }
  
  .card-slate p,
  .card-slate .card-description,
  .card-slate .stat-label {
    @apply text-white/70;
  }

  /* ===== STAT CARDS ===== */
  .stat-card {
    @apply card p-6;
  }
  
  .stat-value {
    @apply text-3xl font-bold tabular-nums;
  }
  
  .stat-label {
    @apply text-sm mt-1;
  }

  /* ===== BUTTONS ===== */
  .btn {
    @apply inline-flex items-center justify-center gap-2 font-medium rounded-xl
           transition-all duration-200 active:scale-[0.98]
           disabled:opacity-50 disabled:cursor-not-allowed;
  }
  
  .btn-primary {
    @apply btn px-5 py-2.5 
           bg-gradient-to-b from-haven-500 to-haven-600 
           text-white
           shadow-[0_1px_2px_rgba(0,0,0,0.1),0_2px_4px_rgba(0,0,0,0.1),inset_0_1px_0_rgba(255,255,255,0.1)]
           hover:from-haven-600 hover:to-haven-700;
  }
  
  .btn-secondary {
    @apply btn px-5 py-2.5 
           bg-white text-warm-700 
           border border-warm-200 shadow-sm
           hover:bg-warm-50 hover:border-warm-300;
  }
  
  .btn-ghost {
    @apply btn px-4 py-2 text-warm-600 hover:bg-warm-100 hover:text-warm-900;
  }
  
  .btn-ghost-light {
    @apply btn px-4 py-2 text-white/70 hover:bg-white/10 hover:text-white;
  }
  
  .btn-white {
    @apply btn px-5 py-2.5 bg-white text-warm-800 shadow-lg hover:bg-warm-50;
  }
  
  .btn-outline-light {
    @apply btn px-5 py-2.5 bg-transparent text-white border border-white/30 hover:bg-white/10;
  }
  
  .btn-sm { @apply px-3 py-1.5 text-sm rounded-lg; }
  .btn-lg { @apply px-6 py-3 text-base; }

  /* ===== INPUTS ===== */
  .input {
    @apply w-full px-4 py-3 bg-white border border-warm-200 rounded-xl
           text-warm-800 placeholder:text-warm-400
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
  .badge-neutral { @apply bg-warm-100 text-warm-700; }
  .badge-light { @apply bg-white/20 text-white; }

  /* ===== AVATARS ===== */
  .avatar {
    @apply relative inline-flex items-center justify-center rounded-full 
           bg-gradient-to-br from-haven-400 to-haven-600 
           text-white font-semibold ring-2 ring-white shadow-sm;
  }
  
  .avatar-sm { @apply w-8 h-8 text-xs; }
  .avatar-md { @apply w-10 h-10 text-sm; }
  .avatar-lg { @apply w-12 h-12 text-base; }
  .avatar-xl { @apply w-16 h-16 text-lg; }

  /* ===== TABLES ===== */
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

  /* ===== SKELETONS ===== */
  .skeleton {
    @apply bg-gradient-to-r from-warm-200 via-warm-100 to-warm-200 
           bg-[length:200%_100%] animate-shimmer rounded-lg;
  }

  /* ===== MODALS ===== */
  .modal-overlay {
    @apply fixed inset-0 bg-forest-950/60 backdrop-blur-sm z-50
           flex items-center justify-center p-4;
  }
  
  .modal {
    @apply bg-white rounded-2xl shadow-xl max-w-lg w-full 
           max-h-[90vh] overflow-hidden animate-scale-in;
  }
}

@layer utilities {
  .text-on-dark { @apply text-white; }
  .text-on-dark-muted { @apply text-white/70; }
  
  .stagger-1 { animation-delay: 50ms; }
  .stagger-2 { animation-delay: 100ms; }
  .stagger-3 { animation-delay: 150ms; }
  
  .scrollbar-hide {
    -ms-overflow-style: none;
    scrollbar-width: none;
  }
  .scrollbar-hide::-webkit-scrollbar {
    display: none;
  }
}
```

### 1.2 Fix All Dark Background Text

Search through ALL files in `apps/web/src/app/` and fix these critical contrast issues:

**Pattern to find and fix:**

```tsx
// ❌ WRONG - Black text on green (unreadable)
<div className="bg-gradient-to-br from-haven-500 to-haven-600 p-6 rounded-2xl">
  <h2 className="text-xl font-bold text-warm-900">Good morning, Bob</h2>
  <p className="text-warm-600">Daily summary</p>
</div>

// ✅ CORRECT - White text on green
<div className="card-green p-6">
  <h2 className="text-xl font-bold">Good morning, Bob</h2>
  <p>Daily summary</p>
</div>
// OR explicitly:
<div className="bg-gradient-to-br from-haven-500 to-haven-600 p-6 rounded-2xl">
  <h2 className="text-xl font-bold text-white">Good morning, Bob</h2>
  <p className="text-white/80">Daily summary</p>
</div>
```

```tsx
// ❌ WRONG - Black text on slate (invisible)
<div className="bg-warm-800 p-6 rounded-2xl">
  <div className="text-3xl font-bold text-warm-900">$8,247.23</div>
</div>

// ✅ CORRECT - White text on slate
<div className="card-slate p-6">
  <div className="text-3xl font-bold">$8,247.23</div>
</div>
// OR:
<div className="bg-warm-800 p-6 rounded-2xl">
  <div className="text-3xl font-bold text-white">$8,247.23</div>
</div>
```

**Files to check and fix:**
- `apps/web/src/app/app/page.tsx` - Homeowner dashboard greeting
- `apps/web/src/app/app/bills/page.tsx` - Money amounts on dark cards
- `apps/web/src/app/manager/page.tsx` - Manager dashboard
- `apps/web/src/app/manager/payables/page.tsx` - Payment amounts
- Any file with `bg-haven-`, `bg-forest-`, `bg-warm-800`, `bg-warm-900`

### 1.3 Fix Font Consistency

**Rule: Only h1 page titles use serif font. Everything else is sans-serif.**

Search for `font-serif` and remove it from anything that's NOT an h1 page title.

```tsx
// ❌ WRONG - serif on card title
<h3 className="font-serif text-lg font-semibold">Card Title</h3>

// ✅ CORRECT - sans (default) on card title
<h3 className="card-title text-lg">Card Title</h3>
// OR just:
<h3 className="text-lg font-semibold text-warm-900">Card Title</h3>
```

---

## PART 2: AVATAR SYSTEM (DiceBear)

### 2.1 Create Avatar Helper

**Create file:** `apps/web/src/lib/avatars.ts`

```typescript
// DiceBear illustrated avatars - unique per user, consistent style

type AvatarStyle = 'lorelei' | 'avataaars' | 'notionists' | 'bottts';

export function getAvatarUrl(
  seed: string, 
  style: AvatarStyle = 'lorelei',
  size: number = 128
): string {
  const encodedSeed = encodeURIComponent(seed.toLowerCase().trim());
  return `https://api.dicebear.com/7.x/${style}/svg?seed=${encodedSeed}&size=${size}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf`;
}

// Demo user avatars - consistent across app
export function getUserAvatar(name: string): string {
  const avatarMap: Record<string, string> = {
    'bob': getAvatarUrl('bob-smith-homeowner'),
    'bob smith': getAvatarUrl('bob-smith-homeowner'),
    'alice': getAvatarUrl('alice-smith-wife'),
    'alice smith': getAvatarUrl('alice-smith-wife'),
    'emma': getAvatarUrl('emma-smith-daughter'),
    'emma smith': getAvatarUrl('emma-smith-daughter'),
    'jack': getAvatarUrl('jack-smith-son'),
    'jack smith': getAvatarUrl('jack-smith-son'),
    'sarah': getAvatarUrl('sarah-harrison-manager'),
    'sarah harrison': getAvatarUrl('sarah-harrison-manager'),
    'mike': getAvatarUrl('mike-rodriguez-handyman'),
    'mike rodriguez': getAvatarUrl('mike-rodriguez-handyman'),
    'carlos': getAvatarUrl('carlos-reyes-handyman'),
    'carlos reyes': getAvatarUrl('carlos-reyes-handyman'),
  };
  
  const key = name.toLowerCase().trim();
  return avatarMap[key] || getAvatarUrl(name);
}

export function getInitials(name: string): string {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
}
```

### 2.2 Update All Avatar Usages

Search for Unsplash avatar URLs and replace with DiceBear:

```tsx
// ❌ OLD - Unsplash real photo
<Image src="https://images.unsplash.com/photo-149..." alt="Sarah" />

// ✅ NEW - DiceBear illustrated
import { getUserAvatar } from '@/lib/avatars';
<img src={getUserAvatar('Sarah Harrison')} alt="Sarah" className="w-10 h-10 rounded-full" />
```

**Files to update:**
- All layout files
- All dashboard files
- Message/conversation components
- Family page
- Any component showing user avatars

---

## PART 3: VENDOR IMPROVEMENTS

### 3.1 Create Vendor Images Helper

**Update file:** `apps/web/src/lib/images.ts`

Add vendor-specific images:

```typescript
export const vendorImages: Record<string, string[]> = {
  plumbing: [
    'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80',
    'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=400&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80',
  ],
  electrical: [
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80',
    'https://images.unsplash.com/photo-1555963966-b7ae5404b6ed?w=400&q=80',
  ],
  hvac: [
    'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&q=80',
    'https://images.unsplash.com/photo-1631545308978-5f0d5f7c0e6a?w=400&q=80',
  ],
  landscaping: [
    'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400&q=80',
    'https://images.unsplash.com/photo-1592420315809-54c6e9c07b07?w=400&q=80',
  ],
  roofing: [
    'https://images.unsplash.com/photo-1632759145351-1d592919f522?w=400&q=80',
    'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=400&q=80',
  ],
  cleaning: [
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80',
    'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=400&q=80',
  ],
  painting: [
    'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80',
    'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400&q=80',
  ],
  pool: [
    'https://images.unsplash.com/photo-1575429198097-0414ec08e8cd?w=400&q=80',
    'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?w=400&q=80',
  ],
  flooring: [
    'https://images.unsplash.com/photo-1581858726788-75bc0f6a952d?w=400&q=80',
  ],
  security: [
    'https://images.unsplash.com/photo-1558002038-1055907df827?w=400&q=80',
  ],
  general: [
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&q=80',
    'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=400&q=80',
  ],
};

export function getVendorImage(category: string, index: number = 0): string {
  const cat = category.toLowerCase().replace(/[^a-z]/g, '');
  const images = vendorImages[cat] || vendorImages.general;
  return images[index % images.length];
}
```

### 3.2 Fix Vendor Map Card

**File:** `apps/web/src/app/app/community/page.tsx`

Fix the vendor popup card so all elements are inside:

```tsx
// The map popup for a vendor
function VendorMapPopup({ vendor, onClose }: { vendor: Vendor; onClose: () => void }) {
  return (
    <div className="bg-white rounded-2xl shadow-xl overflow-hidden w-80">
      {/* Image header with close button INSIDE */}
      <div className="relative h-32">
        <img 
          src={getVendorImage(vendor.category, vendor.index)} 
          alt={vendor.name}
          className="w-full h-full object-cover"
        />
        
        {/* Close button - positioned inside the image area */}
        <button 
          onClick={onClose}
          className="absolute top-3 right-3 w-8 h-8 bg-white/90 backdrop-blur-sm rounded-full 
                     flex items-center justify-center shadow-lg hover:bg-white transition-colors"
        >
          <X className="w-4 h-4 text-warm-600" />
        </button>
        
        {/* Verified badge - overlapping at bottom of image */}
        {vendor.isVerified && (
          <div className="absolute -bottom-3 left-4">
            <span className="inline-flex items-center gap-1 px-2.5 py-1 bg-haven-500 text-white text-xs font-medium rounded-full shadow-lg">
              <BadgeCheck className="w-3.5 h-3.5" />
              Verified Pro
            </span>
          </div>
        )}
      </div>
      
      {/* Content */}
      <div className="p-4 pt-5">
        <h3 className="font-semibold text-warm-900 text-lg">{vendor.name}</h3>
        <p className="text-warm-500 text-sm">{vendor.category}</p>
        
        {/* Rating */}
        <div className="flex items-center gap-2 mt-2">
          <div className="flex items-center">
            {[...Array(5)].map((_, i) => (
              <Star 
                key={i} 
                className={`w-4 h-4 ${i < Math.floor(vendor.rating) ? 'text-amber-400 fill-amber-400' : 'text-warm-200'}`} 
              />
            ))}
          </div>
          <span className="text-sm text-warm-600">
            {vendor.rating} ({vendor.reviewCount} reviews)
          </span>
        </div>
        
        {/* Neighbors used */}
        <p className="text-sm text-haven-600 mt-2">
          {vendor.neighborsUsed} neighbors have used this pro
        </p>
        
        {/* Action buttons - INSIDE the card */}
        <div className="flex gap-2 mt-4">
          <button className="flex-1 btn-primary text-sm py-2.5">
            Request Quote
          </button>
          <a 
            href={`tel:${vendor.phone}`}
            className="btn-secondary px-4 py-2.5"
          >
            <Phone className="w-4 h-4" />
          </a>
        </div>
      </div>
    </div>
  );
}
```

### 3.3 Add More Vendors to Seed

**File:** `apps/api/prisma/seed.ts`

Add 25+ vendors across all categories. Here's the data to add:

```typescript
const vendorData = [
  // PLUMBING (3)
  { name: 'Greenwich Plumbing Co.', category: 'PLUMBING', rating: 4.9, reviews: 127, neighbors: 23, verified: true, lat: 41.0534, lng: -73.6287 },
  { name: 'Drain Masters CT', category: 'PLUMBING', rating: 4.7, reviews: 89, neighbors: 15, verified: true, lat: 41.0612, lng: -73.6512 },
  { name: 'Precision Pipe Works', category: 'PLUMBING', rating: 4.8, reviews: 64, neighbors: 8, verified: false, lat: 41.0445, lng: -73.5998 },
  
  // ELECTRICAL (3)
  { name: 'Fairfield Electric', category: 'ELECTRICAL', rating: 4.9, reviews: 156, neighbors: 31, verified: true, lat: 41.0587, lng: -73.6123 },
  { name: 'PowerPro Electrical', category: 'ELECTRICAL', rating: 4.6, reviews: 78, neighbors: 12, verified: true, lat: 41.0498, lng: -73.6345 },
  { name: 'Smart Home Wiring', category: 'ELECTRICAL', rating: 5.0, reviews: 42, neighbors: 7, verified: true, lat: 41.0623, lng: -73.5876 },
  
  // HVAC (2)
  { name: 'Climate Control CT', category: 'HVAC', rating: 4.8, reviews: 203, neighbors: 45, verified: true, lat: 41.0556, lng: -73.6234 },
  { name: 'AirFlow HVAC', category: 'HVAC', rating: 4.7, reviews: 91, neighbors: 18, verified: true, lat: 41.0478, lng: -73.6098 },
  
  // LANDSCAPING (3)
  { name: 'Country Landscape Design', category: 'LANDSCAPING', rating: 4.9, reviews: 178, neighbors: 52, verified: true, lat: 41.0512, lng: -73.6178 },
  { name: 'Green Thumb Gardens', category: 'LANDSCAPING', rating: 4.6, reviews: 134, neighbors: 28, verified: true, lat: 41.0589, lng: -73.6312 },
  { name: 'Elite Grounds', category: 'LANDSCAPING', rating: 4.8, reviews: 67, neighbors: 14, verified: false, lat: 41.0423, lng: -73.5945 },
  
  // ROOFING (2)
  { name: 'Ace Roofing & Repair', category: 'ROOFING', rating: 4.8, reviews: 112, neighbors: 19, verified: true, lat: 41.0534, lng: -73.6287 },
  { name: 'Connecticut Roofing Co.', category: 'ROOFING', rating: 4.5, reviews: 87, neighbors: 11, verified: true, lat: 41.0612, lng: -73.6456 },
  
  // CLEANING (2)
  { name: 'Pristine Home Cleaning', category: 'CLEANING', rating: 4.9, reviews: 234, neighbors: 67, verified: true, lat: 41.0498, lng: -73.6123 },
  { name: 'Molly Maid of Greenwich', category: 'CLEANING', rating: 4.7, reviews: 189, neighbors: 43, verified: true, lat: 41.0567, lng: -73.6234 },
  
  // PAINTING (2)
  { name: 'Artistic Painters CT', category: 'PAINTING', rating: 4.9, reviews: 98, neighbors: 21, verified: true, lat: 41.0523, lng: -73.6178 },
  { name: 'Color Theory Painting', category: 'PAINTING', rating: 4.8, reviews: 56, neighbors: 9, verified: false, lat: 41.0589, lng: -73.6345 },
  
  // POOL (2)
  { name: 'Crystal Clear Pools', category: 'POOL', rating: 4.8, reviews: 145, neighbors: 38, verified: true, lat: 41.0512, lng: -73.6098 },
  { name: 'Pools Unlimited CT', category: 'POOL', rating: 4.6, reviews: 78, neighbors: 16, verified: true, lat: 41.0478, lng: -73.6234 },
  
  // PEST CONTROL (2)
  { name: 'Terminix Northeast', category: 'PEST_CONTROL', rating: 4.5, reviews: 167, neighbors: 29, verified: true, lat: 41.0556, lng: -73.6312 },
  { name: 'EcoShield Pest Solutions', category: 'PEST_CONTROL', rating: 4.7, reviews: 54, neighbors: 8, verified: false, lat: 41.0498, lng: -73.6178 },
  
  // FLOORING (2)
  { name: 'Hardwood Flooring Pros', category: 'FLOORING', rating: 4.9, reviews: 89, neighbors: 17, verified: true, lat: 41.0534, lng: -73.6123 },
  { name: 'Stone & Tile Masters', category: 'FLOORING', rating: 4.8, reviews: 67, neighbors: 12, verified: true, lat: 41.0589, lng: -73.6287 },
  
  // WINDOWS (1)
  { name: 'Window World CT', category: 'WINDOWS', rating: 4.6, reviews: 134, neighbors: 24, verified: true, lat: 41.0512, lng: -73.6345 },
  
  // SECURITY (1)
  { name: 'SafeHome Security', category: 'SECURITY', rating: 4.8, reviews: 78, neighbors: 19, verified: true, lat: 41.0478, lng: -73.6098 },
  
  // GENERAL HANDYMAN (2)
  { name: 'Mr. Fix It Greenwich', category: 'GENERAL', rating: 4.7, reviews: 203, neighbors: 56, verified: true, lat: 41.0556, lng: -73.6178 },
  { name: 'Handy Helpers CT', category: 'GENERAL', rating: 4.5, reviews: 145, neighbors: 32, verified: false, lat: 41.0523, lng: -73.6234 },
];

// Insert all vendors
for (let i = 0; i < vendorData.length; i++) {
  const v = vendorData[i];
  await prisma.socialVendor.upsert({
    where: { id: `vendor-${i + 1}` },
    update: {},
    create: {
      id: `vendor-${i + 1}`,
      displayName: v.name,
      category: v.category,
      rating: v.rating,
      reviewCount: v.reviews,
      neighborsUsed: v.neighbors,
      isVerified: v.verified,
      latitude: v.lat,
      longitude: v.lng,
    },
  });
}
console.log(`✓ Created ${vendorData.length} vendors`);
```

---

## PART 4: FAMILY PAGE FIX

### 4.1 Add Family Members to Seed

**File:** `apps/api/prisma/seed.ts`

Add after household creation:

```typescript
// ============================================================================
// FAMILY MEMBERS
// ============================================================================
console.log('👨‍👩‍👧‍👦 Creating family members...');

// Bob (head of household)
await prisma.householdMember.upsert({
  where: { id: 'member-bob' },
  update: {},
  create: {
    id: 'member-bob',
    householdId: demoHousehold.id,
    userId: homeownerBob.id,
    firstName: 'Bob',
    lastName: 'Smith',
    relationship: 'HEAD_OF_HOUSEHOLD',
    email: 'bob@example.com',
    phone: '+1 (203) 555-0001',
    dateOfBirth: new Date('1978-03-15'),
    isEmergencyContact: true,
    isPrimaryContact: true,
  },
});

// Alice (wife)
await prisma.householdMember.upsert({
  where: { id: 'member-alice' },
  update: {},
  create: {
    id: 'member-alice',
    householdId: demoHousehold.id,
    firstName: 'Alice',
    lastName: 'Smith',
    relationship: 'SPOUSE',
    email: 'alice.smith@example.com',
    phone: '+1 (203) 555-0002',
    dateOfBirth: new Date('1980-07-22'),
    isEmergencyContact: true,
    isPrimaryContact: false,
  },
});

// Emma (daughter, 14)
await prisma.householdMember.upsert({
  where: { id: 'member-emma' },
  update: {},
  create: {
    id: 'member-emma',
    householdId: demoHousehold.id,
    firstName: 'Emma',
    lastName: 'Smith',
    relationship: 'CHILD',
    dateOfBirth: new Date('2010-09-10'),
    notes: 'PADI Open Water certified diver. Allergic to shellfish.',
  },
});

// Jack (son, 10)
await prisma.householdMember.upsert({
  where: { id: 'member-jack' },
  update: {},
  create: {
    id: 'member-jack',
    householdId: demoHousehold.id,
    firstName: 'Jack',
    lastName: 'Smith',
    relationship: 'CHILD',
    dateOfBirth: new Date('2014-04-05'),
    notes: 'Plays soccer. Nut allergy (carries EpiPen).',
  },
});

// Max (dog)
await prisma.householdMember.upsert({
  where: { id: 'member-max' },
  update: {},
  create: {
    id: 'member-max',
    householdId: demoHousehold.id,
    firstName: 'Max',
    relationship: 'PET',
    notes: 'Golden Retriever, 5 years old. Vet: Greenwich Animal Hospital (203-555-8888)',
  },
});

console.log('  ✓ Created family: Bob, Alice, Emma, Jack, Max');
```

### 4.2 Update Family Page

**File:** `apps/web/src/app/app/family/page.tsx`

Update to fetch and display all family members with their DiceBear avatars.

---

## PART 5: PROJECT PLANNING OVERHAUL

### 5.1 Create Project List Page

**File:** `apps/web/src/app/app/projects/page.tsx`

Create a page listing all home projects with status tabs.

### 5.2 Create Project Detail Page

**File:** `apps/web/src/app/app/projects/[id]/page.tsx`

Create a detailed project view with:
- Progress timeline with phases
- Checklist items per phase
- Vendor quotes comparison
- Inspiration board
- Message thread/updates
- Budget tracking

Include demo data for "Kitchen Backsplash Upgrade" project.

---

## SUMMARY OF ALL FIXES

| Issue | Solution |
|-------|----------|
| Font inconsistency | Serif for h1 only, sans everywhere else |
| Contrast on green cards | `card-green` class with white text |
| Contrast on slate cards | `card-slate` class with white text |
| Vendor card overflow | Restructured with `overflow-hidden` |
| Same vendor photos | Unique images per category |
| Real photo avatars | DiceBear illustrated avatars |
| Not enough vendors | 26 vendors across 12 categories |
| Project planning broken | Full workflow with phases & quotes |
| Family missing Alice | Added Alice, Emma, Jack, Max |

---

## AFTER BUILD COMPLETE

```bash
# Reset database
cd apps/api
pnpm prisma db push --force-reset
pnpm prisma db seed
pnpm dev

# Start frontend
cd apps/web
pnpm dev
```

Test at http://localhost:3000

**Visual Verification:**
1. ✅ Page titles are elegant serif font
2. ✅ All other text is clean sans-serif
3. ✅ Green cards have WHITE text
4. ✅ Slate cards have WHITE text  
5. ✅ No black-on-dark anywhere
6. ✅ Vendor map card is contained
7. ✅ Each vendor has unique image
8. ✅ Avatars are illustrated, not photos
9. ✅ Family shows Bob, Alice, Emma, Jack, Max
10. ✅ Projects have full workflow

🏠✨

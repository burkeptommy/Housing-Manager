# 🎨 HAVEN UI FIX - Sidebar & Find Pros Page

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this entire prompt.

---

## ISSUE SUMMARY

The previous build missed these critical UI fixes:
1. **Sidebar is SLATE instead of FOREST GREEN** - Should be deep green to match brand
2. **Layout backgrounds are slate** - Should use warm color palette
3. **Find Pros page uses all slate colors** - Needs brand consistency
4. **Vendor cards not updated** - Still using old color scheme
5. **Vendor logos use random placeholder images** - Should use DiceBear 'bottts' style like user avatars

---

## FIX 1: DESKTOP SIDEBAR - Deep Forest Green

**File:** `apps/web/src/components/app-shell/desktop-sidebar.tsx`

Replace the entire file with:

```tsx
'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Leaf } from 'lucide-react';
import { sidebarNavigation, sidebarBottomNav } from './navigation-config';

export function DesktopSidebar() {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (href === '/app') return pathname === '/app';
    return pathname === href || pathname.startsWith(href + '/');
  };

  return (
    <aside className="hidden lg:flex lg:flex-col lg:w-[260px] lg:fixed lg:inset-y-0 bg-gradient-to-b from-forest-900 to-forest-950">
      {/* Logo */}
      <div className="flex items-center h-16 px-6 border-b border-white/10">
        <Link href="/app" className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-haven-400 to-haven-600 flex items-center justify-center shadow-lg shadow-haven-500/20">
            <Leaf className="w-5 h-5 text-white" />
          </div>
          <span className="text-xl font-bold tracking-tight text-white">Haven</span>
        </Link>
      </div>

      {/* Navigation - Scrollable */}
      <nav className="flex-1 px-3 py-4 space-y-6 overflow-y-auto">
        {sidebarNavigation.map((section) => (
          <div key={section.title}>
            {/* Section Title */}
            <h3 className="px-3 mb-2 text-xs font-semibold uppercase tracking-wider text-white/40">
              {section.title}
            </h3>
            {/* Section Items */}
            <div className="space-y-1">
              {section.items.map((item) => {
                const active = isActive(item.href);
                const Icon = item.icon;

                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                      active
                        ? 'bg-white/15 text-white'
                        : 'text-white/70 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    <Icon
                      className={`w-5 h-5 ${active ? 'text-haven-400' : 'text-white/50'}`}
                      strokeWidth={active ? 2.5 : 2}
                    />
                    {item.name}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Bottom Section */}
      <div className="px-3 py-4 border-t border-white/10 space-y-1">
        {sidebarBottomNav.map((item) => {
          const active = isActive(item.href);
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                active
                  ? 'bg-white/15 text-white'
                  : 'text-white/70 hover:bg-white/10 hover:text-white'
              }`}
            >
              <Icon
                className={`w-5 h-5 ${active ? 'text-haven-400' : 'text-white/50'}`}
                strokeWidth={active ? 2.5 : 2}
              />
              {item.name}
            </Link>
          );
        })}
      </div>
    </aside>
  );
}
```

---

## FIX 2: APP LAYOUT - Warm Background

**File:** `apps/web/src/app/app/layout.tsx`

Replace `bg-slate-50` with `bg-warm-50` and update spinner:

```tsx
'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import { DesktopSidebar, MobileHeader, MobileBottomNav, ConciergeFab } from '@/components/app-shell';

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isLoading, needsOnboarding } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login');
    } else if (!isLoading && isAuthenticated && needsOnboarding) {
      router.push('/onboarding');
    }
  }, [isLoading, isAuthenticated, needsOnboarding, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-warm-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-haven-600 mx-auto"></div>
          <p className="mt-4 text-warm-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated || needsOnboarding) {
    return null;
  }

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Desktop Sidebar */}
      <DesktopSidebar />

      {/* Mobile Header */}
      <MobileHeader />

      {/* Main Content */}
      <div className="lg:pl-[260px]">
        <main className="p-4 lg:p-6 pb-20 lg:pb-6">{children}</main>
      </div>

      {/* Mobile Bottom Navigation */}
      <MobileBottomNav />

      {/* Persistent Concierge Chat */}
      <ConciergeFab />
    </div>
  );
}
```

---

## FIX 3: MOBILE HEADER - Forest Green

**File:** `apps/web/src/components/app-shell/mobile-header.tsx`

Search for any `slate-` colors and replace:
- `bg-slate-900` → `bg-forest-900`
- `border-slate-800` → `border-white/10`
- `text-slate-*` → `text-white` or `text-white/70`

If file exists, update it. If not, the mobile header might be inline in another file.

---

## FIX 4: MOBILE BOTTOM NAV - Haven Green Accents

**File:** `apps/web/src/components/app-shell/mobile-bottom-nav.tsx`

Replace slate colors with haven/warm:
- `text-slate-400` → `text-warm-400`
- `text-slate-600` → `text-warm-600`
- Active state: `text-emerald-600` → `text-haven-600`
- `bg-slate-*` → `bg-warm-*`

---

## FIX 5: FIND PROS PAGE - Complete Color Overhaul

**File:** `apps/web/src/app/app/community/page.tsx`

Do a global find-and-replace for these color changes:

### Background colors:
- `bg-slate-50` → `bg-warm-50`
- `bg-slate-100` → `bg-warm-100`
- `bg-slate-200` → `bg-warm-200`
- `bg-slate-800` → `bg-warm-800`
- `bg-slate-900` → `bg-forest-900`

### Text colors:
- `text-slate-900` → `text-warm-900`
- `text-slate-800` → `text-warm-800`
- `text-slate-700` → `text-warm-700`
- `text-slate-600` → `text-warm-600`
- `text-slate-500` → `text-warm-500`
- `text-slate-400` → `text-warm-400`
- `text-slate-300` → `text-white/70` (on dark backgrounds)

### Border colors:
- `border-slate-200` → `border-warm-200`
- `border-slate-300` → `border-warm-300`
- `border-slate-100` → `border-warm-100`

### Accent colors (keep emerald OR change to haven):
- `bg-emerald-600` → `bg-haven-600`
- `bg-emerald-100` → `bg-haven-100`
- `text-emerald-600` → `text-haven-600`
- `text-emerald-700` → `text-haven-700`
- `text-emerald-400` → `text-haven-400`
- `hover:bg-emerald-700` → `hover:bg-haven-700`
- `ring-emerald-500` → `ring-haven-500`
- `focus:ring-emerald-500` → `focus:ring-haven-500`

### Hover states:
- `hover:bg-slate-50` → `hover:bg-warm-50`
- `hover:bg-slate-100` → `hover:bg-warm-100`
- `hover:bg-slate-200` → `hover:bg-warm-200`

---

## FIX 6: VENDOR POPUP CARD - Better Contained Layout

In the same file (`apps/web/src/app/app/community/page.tsx`), update the `VendorPopup` component:

```tsx
function VendorPopup({ vendor }: { vendor: Vendor }) {
  return (
    <div className="w-[280px] max-w-[280px]">
      <div className="flex items-start gap-3">
        <img
          src={vendor.logoUrl}
          alt={vendor.name}
          className="w-12 h-12 rounded-lg object-cover flex-shrink-0"
        />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1.5 flex-wrap">
            <h3 className="font-semibold text-warm-900 truncate max-w-[140px]">{vendor.name}</h3>
            {vendor.havenTrusted && (
              <span className="px-1.5 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded flex-shrink-0">
                Haven Trusted
              </span>
            )}
          </div>
          <div className="flex items-center gap-1.5 text-sm text-warm-500 mt-0.5">
            <Star className="w-3.5 h-3.5 text-amber-500 fill-current flex-shrink-0" />
            <span>{vendor.rating}</span>
            <span className="text-warm-300">•</span>
            <span className="truncate">{vendor.reviewCount} reviews</span>
          </div>
        </div>
      </div>
      <div className="mt-2.5 flex items-center gap-3 text-xs text-warm-600">
        <div className="flex items-center gap-1">
          <Users className="w-3.5 h-3.5 flex-shrink-0" />
          <span>{vendor.neighborsUsed} neighbors</span>
        </div>
        <div className="flex items-center gap-1">
          <MapPin className="w-3.5 h-3.5 flex-shrink-0" />
          <span>{vendor.distance} mi</span>
        </div>
      </div>
      <div className="mt-2.5 flex gap-2">
        <button className="flex-1 px-3 py-1.5 bg-haven-600 text-white text-sm font-medium rounded-lg hover:bg-haven-700 transition-colors">
          Request Quote
        </button>
        <a
          href={`tel:${vendor.phone}`}
          className="px-2.5 py-1.5 border border-warm-300 rounded-lg hover:bg-warm-50 transition-colors flex items-center justify-center"
        >
          <Phone className="w-4 h-4 text-warm-600" />
        </a>
      </div>
    </div>
  );
}
```

---

## FIX 7: VENDOR LIST ITEM - Consistent Colors

Update `VendorListItem` component:

```tsx
function VendorListItem({
  vendor,
  isSelected,
  onClick
}: {
  vendor: Vendor;
  isSelected: boolean;
  onClick: () => void;
}) {
  return (
    <div
      onClick={onClick}
      className={`p-4 cursor-pointer transition-colors ${
        isSelected ? 'bg-haven-50' : 'hover:bg-warm-50'
      }`}
    >
      <div className="flex gap-3">
        <img
          src={vendor.logoUrl}
          alt={vendor.name}
          className="w-14 h-14 rounded-lg object-cover"
        />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-medium text-warm-900 truncate">{vendor.name}</h3>
            {vendor.havenTrusted && (
              <Shield className="w-4 h-4 text-haven-600 flex-shrink-0" />
            )}
          </div>
          <div className="flex items-center gap-2 text-sm text-warm-500">
            <Star className="w-3.5 h-3.5 text-amber-500 fill-current" />
            <span>{vendor.rating}</span>
            <span>•</span>
            <span>{vendor.priceTier}</span>
            <span>•</span>
            <span>{vendor.distance} mi</span>
          </div>
          <div className="mt-1 flex items-center gap-1 text-xs text-haven-600">
            <Users className="w-3.5 h-3.5" />
            <span>{vendor.neighborsUsed} neighbors used this pro</span>
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

## FIX 8: VENDOR CARD - Brand Colors

Update `VendorCard` component:

```tsx
function VendorCard({ vendor }: { vendor: Vendor }) {
  const recentProject = vendor.recentProjects[0];

  return (
    <div className="bg-white rounded-xl border border-warm-200 overflow-hidden hover:shadow-lg transition-shadow">
      {/* Cover/Project Image */}
      <div className="relative h-40">
        <img
          src={recentProject?.afterImage || vendor.coverUrl}
          alt={vendor.name}
          className="w-full h-full object-cover"
        />
        {vendor.havenTrusted && (
          <div className="absolute top-2 left-2 px-2 py-1 bg-haven-600 text-white text-xs font-medium rounded-full flex items-center gap-1">
            <Shield className="w-3 h-3" />
            Haven Trusted
          </div>
        )}
        <div className="absolute bottom-2 right-2 px-2 py-1 bg-black/60 text-white text-xs rounded-full">
          {vendor.priceTier}
        </div>
      </div>

      {/* Content */}
      <div className="p-4">
        <div className="flex items-start gap-3">
          <img
            src={vendor.logoUrl}
            alt={vendor.name}
            className="w-12 h-12 rounded-lg object-cover"
          />
          <div className="flex-1">
            <h3 className="font-semibold text-warm-900">{vendor.name}</h3>
            <div className="flex items-center gap-2 text-sm text-warm-500">
              <Star className="w-4 h-4 text-amber-500 fill-current" />
              <span>{vendor.rating}</span>
              <span>({vendor.reviewCount})</span>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="mt-3 grid grid-cols-3 gap-2 text-center">
          <div className="py-2 bg-warm-50 rounded-lg">
            <div className="text-lg font-semibold text-warm-900">{vendor.neighborsUsed}</div>
            <div className="text-xs text-warm-500">Neighbors</div>
          </div>
          <div className="py-2 bg-warm-50 rounded-lg">
            <div className="text-lg font-semibold text-warm-900">{vendor.totalProjects}</div>
            <div className="text-xs text-warm-500">Projects</div>
          </div>
          <div className="py-2 bg-warm-50 rounded-lg">
            <div className="text-lg font-semibold text-warm-900">{vendor.onTimeRate}%</div>
            <div className="text-xs text-warm-500">On Time</div>
          </div>
        </div>

        {/* Specialties */}
        <div className="mt-3 flex flex-wrap gap-1">
          {vendor.specialties.slice(0, 3).map(specialty => (
            <span key={specialty} className="px-2 py-1 bg-warm-100 text-warm-600 text-xs rounded-full">
              {specialty}
            </span>
          ))}
        </div>

        {/* Actions */}
        <div className="mt-4 flex gap-2">
          <button className="flex-1 px-3 py-2 bg-haven-600 text-white text-sm font-medium rounded-lg hover:bg-haven-700">
            Request Quote
          </button>
          <button className="px-3 py-2 border border-warm-300 rounded-lg hover:bg-warm-50">
            <Heart className="w-4 h-4 text-warm-600" />
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## FIX 9: FIND PROS PAGE HEADER

Update the page header section in the main component:

```tsx
{/* Header */}
<div className="bg-white border-b border-warm-200 sticky top-0 z-20">
  <div className="max-w-7xl mx-auto px-4 py-4">
    <div className="flex items-center justify-between mb-4">
      <div>
        <h1 className="text-2xl font-bold text-warm-900">Find Contractors</h1>
        <p className="text-sm text-warm-500">Trusted pros used by your neighbors</p>
      </div>
      <div className="flex items-center gap-2">
        <button
          onClick={() => setViewMode('map')}
          className={`p-2 rounded-lg ${viewMode === 'map' ? 'bg-haven-100 text-haven-700' : 'text-warm-400 hover:bg-warm-100'}`}
        >
          <MapIcon className="w-5 h-5" />
        </button>
        <button
          onClick={() => setViewMode('grid')}
          className={`p-2 rounded-lg ${viewMode === 'grid' ? 'bg-haven-100 text-haven-700' : 'text-warm-400 hover:bg-warm-100'}`}
        >
          <Grid3X3 className="w-5 h-5" />
        </button>
      </div>
    </div>

    {/* Search */}
    <div className="relative mb-4">
      <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-warm-400" />
      <input
        type="text"
        placeholder="Search by name or specialty..."
        value={searchQuery}
        onChange={(e) => setSearchQuery(e.target.value)}
        className="w-full pl-10 pr-4 py-2.5 border border-warm-300 rounded-xl focus:ring-2 focus:ring-haven-500 focus:border-transparent"
      />
    </div>

    {/* Trade Filters */}
    <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
      {tradeFilters.map(trade => (
        <button
          key={trade.id}
          onClick={() => setSelectedTrade(trade.id)}
          className={`flex items-center gap-2 px-4 py-2 rounded-full whitespace-nowrap transition-all ${
            selectedTrade === trade.id
              ? 'bg-haven-600 text-white'
              : 'bg-warm-100 text-warm-600 hover:bg-warm-200'
          }`}
        >
          <trade.icon className="w-4 h-4" />
          <span className="text-sm font-medium">{trade.label}</span>
        </button>
      ))}
    </div>
  </div>
</div>
```

---

## FIX 10: MAP MARKERS - Haven Green

Update the marker colors in the Map section:

```tsx
{/* Vendor markers */}
{sortedVendors.map(vendor => (
  <Marker
    key={vendor.id}
    latitude={vendor.location.lat}
    longitude={vendor.location.lng}
    onClick={() => setSelectedVendor(vendor)}
  >
    <div className={`
      w-10 h-10 rounded-full flex items-center justify-center cursor-pointer
      transition-transform hover:scale-110
      ${vendor.havenTrusted ? 'bg-haven-600' : 'bg-warm-600'}
      ${selectedVendor?.id === vendor.id ? 'ring-4 ring-haven-300 scale-110' : ''}
    `}>
      {vendor.havenTrusted && (
        <Shield className="w-5 h-5 text-white" />
      )}
      {!vendor.havenTrusted && (
        <Wrench className="w-5 h-5 text-white" />
      )}
    </div>
  </Marker>
))}
```

---

## FIX 11: VENDOR LIST SIDEBAR

Update the sidebar container and sort selector:

```tsx
{/* Vendor List Sidebar */}
<div className="w-full lg:w-96 bg-white border-l border-warm-200 overflow-y-auto">
  <div className="p-4 border-b border-warm-200">
    <div className="flex items-center justify-between">
      <span className="text-sm font-medium text-warm-600">
        {sortedVendors.length} contractors found
      </span>
      <select
        value={sortBy}
        onChange={(e) => setSortBy(e.target.value as SortOption)}
        className="text-sm border-none bg-transparent text-haven-600 font-medium focus:ring-0"
      >
        <option value="neighbors">Most Used by Neighbors</option>
        <option value="rating">Highest Rated</option>
        <option value="nearest">Nearest</option>
        <option value="projects">Most Projects</option>
      </select>
    </div>
  </div>
  <div className="divide-y divide-warm-100">
    {sortedVendors.map(vendor => (
      <VendorListItem
        key={vendor.id}
        vendor={vendor}
        isSelected={selectedVendor?.id === vendor.id}
        onClick={() => flyToVendor(vendor)}
      />
    ))}
  </div>
</div>
```

---

## FIX 12: GLOBAL SEARCH & REPLACE

After making the component updates above, do a final sweep through the entire `apps/web/src/` directory:

**Search for these patterns and replace:**

| Find | Replace |
|------|---------|
| `bg-slate-50` | `bg-warm-50` |
| `bg-slate-100` | `bg-warm-100` |
| `bg-slate-200` | `bg-warm-200` |
| `bg-slate-900` | `bg-forest-900` |
| `text-slate-900` | `text-warm-900` |
| `text-slate-700` | `text-warm-700` |
| `text-slate-600` | `text-warm-600` |
| `text-slate-500` | `text-warm-500` |
| `text-slate-400` | `text-warm-400` |
| `border-slate-200` | `border-warm-200` |
| `border-slate-300` | `border-warm-300` |
| `border-slate-100` | `border-warm-100` |
| `bg-emerald-600` | `bg-haven-600` |
| `bg-emerald-100` | `bg-haven-100` |
| `text-emerald-600` | `text-haven-600` |
| `text-emerald-700` | `text-haven-700` |
| `hover:bg-emerald-700` | `hover:bg-haven-700` |

**Exception:** Keep `text-yellow-500` for star ratings and `text-amber-500` for gold accents.

---

## FIX 13: VENDOR LOGOS - Use DiceBear Avatars

The app already has an `avatars.ts` file with a `getVendorAvatar()` function that uses the DiceBear 'bottts' style for vendors. But the Find Pros page isn't using it.

**File:** `apps/web/src/app/app/community/page.tsx`

### Step 1: Add import at top of file

```tsx
import { getVendorAvatar } from '@/lib/avatars';
```

### Step 2: Update mockVendors data

Replace all `logoUrl: getDemoImage(...)` with `logoUrl: getVendorAvatar(vendorName)`:

```tsx
const mockVendors: Vendor[] = [
  {
    id: 'v1',
    name: "Mike's Plumbing Pro",
    trade: 'plumber',
    rating: 4.9,
    reviewCount: 127,
    priceTier: '$',
    verified: true,
    havenTrusted: true,
    logoUrl: getVendorAvatar("Mike's Plumbing Pro"), // DiceBear bottts style
    // ... rest of vendor data
  },
  // Update ALL vendors similarly
];
```

### Step 3: Or dynamically generate in component

Alternatively, compute the logoUrl dynamically in the render instead of storing it:

```tsx
// In VendorCard, VendorListItem, VendorPopup components:
<img
  src={getVendorAvatar(vendor.name)}
  alt={vendor.name}
  className="w-12 h-12 rounded-lg object-cover"
/>
```

### Step 4: Remove getDemoImage import if no longer needed

If `getDemoImage` is only used for vendor logos, remove the import:

```tsx
// REMOVE this line if not needed elsewhere:
import { getDemoImage, getVendorWorkImage } from '@/lib/imageUtils';

// KEEP getVendorWorkImage for cover images if still used
import { getVendorWorkImage } from '@/lib/imageUtils';
```

### Step 5: Keep cover images as real photos

The `coverUrl` (project/work photos) should remain real Unsplash images - only the `logoUrl` (vendor avatar) should use DiceBear:

```tsx
{
  logoUrl: getVendorAvatar(vendor.name),        // DiceBear bottts avatar
  coverUrl: getVendorWorkImage('plumber', ...),  // Real work photo
}
```

---

## FIX 14: MAP VIEW - Westchester & Fairfield Counties with Premium 3D Style

**File:** `apps/web/src/app/app/community/page.tsx`

### Problem:
- Map is too zoomed in (zoom 13)
- Only shows immediate Greenwich area
- Vendors are clustered too tightly
- Map style doesn't match premium aesthetic

### CIO Decision: Map Style

After evaluating Mapbox options, I recommend using **Mapbox Standard** with 3D buildings enabled. This creates a premium, sophisticated look that matches Haven's luxury positioning:

- 3D buildings give depth and visual interest
- Clean, modern aesthetic
- Warm color tones that complement our palette
- Professional feel like high-end real estate apps

Alternative: If 3D feels too heavy, fall back to `light-v11` which is clean and minimal.

### Solution:

**Step 1: Update map style and initial view**

```tsx
// Update the Map component
<Map
  ref={mapRef}
  mapboxAccessToken={MAPBOX_TOKEN}
  initialViewState={{
    latitude: 41.1,      // Centered between Westchester & Fairfield
    longitude: -73.55,   // Right on the NY/CT border
    zoom: 9,             // Zoomed out to show both counties
    pitch: 45,           // Tilt for 3D effect
    bearing: -10,        // Slight rotation for visual interest
  }}
  style={{ width: '100%', height: '100%' }}
  mapStyle="mapbox://styles/mapbox/standard"  // 3D style
  terrain={{ source: 'mapbox-dem', exaggeration: 1.2 }}  // Optional: 3D terrain
>
```

**Step 2: Add terrain source for 3D effect (optional but looks great)**

```tsx
// Inside the Map component, add a Source for terrain
import { Source } from 'react-map-gl/mapbox';

<Map ...>
  {/* 3D Terrain */}
  <Source
    id="mapbox-dem"
    type="raster-dem"
    url="mapbox://mapbox.mapbox-terrain-dem-v1"
    tileSize={512}
    maxzoom={14}
  />
  
  {/* Rest of map content */}
</Map>
```

**Step 3: Spread vendors across BOTH Westchester (NY) and Fairfield (CT) Counties**

```tsx
// Comprehensive vendor locations across both counties
const vendorLocations = {
  // =========================================
  // FAIRFIELD COUNTY, CT (Eastern side)
  // =========================================
  
  // Greenwich area
  greenwich: { lat: 41.0534, lng: -73.6287 },
  oldGreenwich: { lat: 41.0312, lng: -73.5656 },
  cosCob: { lat: 41.0612, lng: -73.6012 },
  riverside: { lat: 41.0345, lng: -73.5789 },
  
  // Stamford
  stamford: { lat: 41.0534, lng: -73.5387 },
  stamfordDowntown: { lat: 41.0466, lng: -73.5394 },
  
  // Darien & Norwalk
  darien: { lat: 41.0787, lng: -73.4698 },
  norwalk: { lat: 41.1177, lng: -73.4082 },
  southNorwalk: { lat: 41.0954, lng: -73.4190 },
  
  // Westport & Fairfield
  westport: { lat: 41.1415, lng: -73.3579 },
  fairfield: { lat: 41.1412, lng: -73.2637 },
  southport: { lat: 41.1365, lng: -73.2834 },
  
  // Northern Fairfield
  newCanaan: { lat: 41.1468, lng: -73.4948 },
  wilton: { lat: 41.1954, lng: -73.4379 },
  ridgefield: { lat: 41.2815, lng: -73.4984 },
  danbury: { lat: 41.3948, lng: -73.4540 },
  
  // =========================================
  // WESTCHESTER COUNTY, NY (Western side)
  // =========================================
  
  // Southern Westchester
  portChester: { lat: 41.0018, lng: -73.6657 },
  rye: { lat: 40.9807, lng: -73.6835 },
  ryeBrook: { lat: 41.0290, lng: -73.6835 },
  mamaroneck: { lat: 40.9487, lng: -73.7324 },
  larchmont: { lat: 40.9276, lng: -73.7518 },
  newRochelle: { lat: 40.9115, lng: -73.7824 },
  
  // Central Westchester
  whitePlains: { lat: 41.0340, lng: -73.7629 },
  scarsdale: { lat: 40.9887, lng: -73.7846 },
  eastchester: { lat: 40.9526, lng: -73.8085 },
  bronxville: { lat: 40.9401, lng: -73.8321 },
  tuckahoe: { lat: 40.9504, lng: -73.8276 },
  hartsdale: { lat: 41.0190, lng: -73.7982 },
  
  // Northern Westchester
  armonk: { lat: 41.1265, lng: -73.7140 },
  bedford: { lat: 41.2045, lng: -73.6437 },
  chappaqua: { lat: 41.1595, lng: -73.7651 },
  mountKisco: { lat: 41.2048, lng: -73.7271 },
  katonah: { lat: 41.2587, lng: -73.6857 },
  poundRidge: { lat: 41.2070, lng: -73.5743 },
  
  // Hudson River towns
  tarrytown: { lat: 41.0762, lng: -73.8587 },
  irvington: { lat: 41.0393, lng: -73.8654 },
  dobbsFerry: { lat: 41.0154, lng: -73.8726 },
  hastings: { lat: 41.0001, lng: -73.8790 },
  yonkers: { lat: 40.9312, lng: -73.8987 },
  
  // Sound Shore
  pelham: { lat: 40.9101, lng: -73.8079 },
  pelhamManor: { lat: 40.8954, lng: -73.8079 },
  mtVernon: { lat: 40.9126, lng: -73.8371 },
};

// Assign locations to vendors - spread them evenly across both counties
// Example assignments (update all 26 vendors):
const vendorLocationAssignments = [
  'greenwich',      // v1 - Mike's Plumbing Pro
  'westport',       // v2 - Country Landscape Design
  'whitePlains',    // v3 - Elite Electric Services
  'scarsdale',      // v4 - Comfort Zone HVAC
  'darien',         // v5 - Perfect Painters LLC
  'rye',            // v6 - Handy Dan Services
  'stamford',       // v7 - Ace Roofing Co.
  'newCanaan',      // v8 - Top Notch Roofing
  'armonk',         // v9 - Sparkle Clean CT
  'fairfield',      // v10 - Molly Maid Greenwich
  'tarrytown',      // v11 - Quick Fix Plumbing
  'norwalk',        // v12 - Premium Plumbing Solutions
  'bedford',        // v13 - Bright Spark Electric
  'ridgefield',     // v14 - Tesla Certified Electricians
  'bronxville',     // v15 - Green Thumb Gardens
  'chappaqua',      // v16 - Estate Grounds Maintenance
  'mamaroneck',     // v17 - Arctic Air HVAC
  'wilton',         // v18 - Brush Masters Painting
  'larchmont',      // v19 - Fine Finish Painters
  'portChester',    // v20 - Mr. Fix-It Greenwich
  'newRochelle',    // v21 - Home Pro Services
  'dobbsFerry',     // v22 - Pool Paradise CT
  'danbury',        // v23 - Security Systems Plus
  'mountKisco',     // v24 - Window World CT
  'southport',      // v25 - Floor Masters LLC
  'hartsdale',      // v26 - Garage Door Experts
];
```

**Step 4: Update user location marker**

```tsx
// User is in Greenwich, CT (our demo property at 38 Bedford Rd)
const currentUserLocation = { lat: 41.0534, lng: -73.6287 };
```

**Step 5: Update vendor distances dynamically**

Since vendors are now spread across two counties, calculate real distances:

```tsx
// Helper function to calculate distance between two points
function calculateDistance(
  lat1: number, lng1: number, 
  lat2: number, lng2: number
): number {
  const R = 3959; // Earth's radius in miles
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return Math.round(R * c * 10) / 10; // Round to 1 decimal
}

// Then in each vendor:
vendor.distance = calculateDistance(
  currentUserLocation.lat, 
  currentUserLocation.lng,
  vendor.location.lat,
  vendor.location.lng
);
```

**Step 6: Add map controls for better UX**

```tsx
import { NavigationControl, GeolocateControl, ScaleControl } from 'react-map-gl/mapbox';

<Map ...>
  <NavigationControl position="top-right" visualizePitch={true} />
  <GeolocateControl position="top-right" />
  <ScaleControl position="bottom-left" />
  
  {/* Rest of markers and popups */}
</Map>
```

**Step 7: Style the markers to stand out on 3D map**

```tsx
{/* Vendor markers with shadows for 3D depth */}
{sortedVendors.map(vendor => (
  <Marker
    key={vendor.id}
    latitude={vendor.location.lat}
    longitude={vendor.location.lng}
    onClick={() => setSelectedVendor(vendor)}
  >
    <div className={`
      w-10 h-10 rounded-full flex items-center justify-center cursor-pointer
      transition-all duration-200 hover:scale-110
      shadow-lg shadow-black/20
      ${vendor.havenTrusted 
        ? 'bg-gradient-to-br from-haven-500 to-haven-700' 
        : 'bg-gradient-to-br from-warm-500 to-warm-700'
      }
      ${selectedVendor?.id === vendor.id 
        ? 'ring-4 ring-white scale-110 shadow-xl' 
        : ''
      }
    `}>
      {vendor.havenTrusted ? (
        <Shield className="w-5 h-5 text-white drop-shadow" />
      ) : (
        <Wrench className="w-5 h-5 text-white drop-shadow" />
      )}
    </div>
  </Marker>
))}

---

## FIX 15: MAP POPUP CARD - Fix Overflow Issues

**File:** `apps/web/src/app/app/community/page.tsx`

### Problem:
- The "X" close button appears outside the card
- The "Haven Verified" badge overflows
- Card doesn't properly contain all its content

### Solution:

Replace the Popup usage with a CUSTOM popup that properly contains all elements:

**Step 1: Create a proper contained popup component**

```tsx
function VendorMapCard({ vendor, onClose }: { vendor: Vendor; onClose: () => void }) {
  return (
    <div className="bg-white rounded-xl shadow-2xl overflow-hidden w-[300px] border border-warm-200">
      {/* Image Header with Close Button INSIDE */}
      <div className="relative h-28">
        <img
          src={vendor.coverUrl}
          alt={vendor.name}
          className="w-full h-full object-cover"
        />
        
        {/* Close button - INSIDE the card, top right */}
        <button
          onClick={(e) => {
            e.stopPropagation();
            onClose();
          }}
          className="absolute top-2 right-2 w-7 h-7 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center shadow-md hover:bg-white transition-colors z-10"
        >
          <X className="w-4 h-4 text-warm-600" />
        </button>
        
        {/* Haven Trusted badge - INSIDE the card, bottom left overlapping */}
        {vendor.havenTrusted && (
          <div className="absolute bottom-0 left-3 transform translate-y-1/2 z-10">
            <span className="inline-flex items-center gap-1 px-2 py-1 bg-haven-600 text-white text-xs font-medium rounded-full shadow-lg">
              <Shield className="w-3 h-3" />
              Haven Trusted
            </span>
          </div>
        )}
      </div>
      
      {/* Content - with padding to account for overlapping badge */}
      <div className="p-4 pt-5">
        <div className="flex items-start gap-3">
          <img
            src={getVendorAvatar(vendor.name)}
            alt={vendor.name}
            className="w-11 h-11 rounded-lg flex-shrink-0"
          />
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-warm-900 truncate">{vendor.name}</h3>
            <div className="flex items-center gap-1.5 text-sm text-warm-500">
              <Star className="w-3.5 h-3.5 text-amber-500 fill-current" />
              <span>{vendor.rating}</span>
              <span className="text-warm-300">•</span>
              <span>{vendor.reviewCount} reviews</span>
            </div>
          </div>
        </div>
        
        {/* Stats row */}
        <div className="mt-3 flex items-center gap-4 text-xs text-warm-600">
          <div className="flex items-center gap-1">
            <Users className="w-3.5 h-3.5" />
            <span>{vendor.neighborsUsed} neighbors</span>
          </div>
          <div className="flex items-center gap-1">
            <MapPin className="w-3.5 h-3.5" />
            <span>{vendor.distance} mi</span>
          </div>
          <div className="flex items-center gap-1">
            <Clock className="w-3.5 h-3.5" />
            <span>{vendor.priceTier}</span>
          </div>
        </div>
        
        {/* Action buttons - INSIDE the card */}
        <div className="mt-4 flex gap-2">
          <button className="flex-1 px-3 py-2 bg-haven-600 text-white text-sm font-medium rounded-lg hover:bg-haven-700 transition-colors">
            Request Quote
          </button>
          <a
            href={`tel:${vendor.phone}`}
            className="px-3 py-2 border border-warm-300 rounded-lg hover:bg-warm-50 transition-colors flex items-center justify-center"
          >
            <Phone className="w-4 h-4 text-warm-600" />
          </a>
        </div>
      </div>
    </div>
  );
}
```

**Step 2: Update the Popup in the Map component**

```tsx
{/* Replace the existing Popup with this */}
{selectedVendor && (
  <Popup
    latitude={selectedVendor.location.lat}
    longitude={selectedVendor.location.lng}
    onClose={() => setSelectedVendor(null)}
    closeButton={false}  // IMPORTANT: Disable default close button
    closeOnClick={false}
    offset={[0, -10]}
    anchor="bottom"
    className="vendor-popup"
  >
    <VendorMapCard 
      vendor={selectedVendor} 
      onClose={() => setSelectedVendor(null)} 
    />
  </Popup>
)}
```

**Step 3: Add CSS to remove default Mapbox popup styling**

Add to `globals.css`:

```css
/* Custom vendor popup - remove default Mapbox styling */
.vendor-popup .mapboxgl-popup-content {
  padding: 0;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.15);
}

.vendor-popup .mapboxgl-popup-close-button {
  display: none; /* Hide default close button */
}

.vendor-popup .mapboxgl-popup-tip {
  border-top-color: white;
}
```

---

## FIX 16: ADD "RECENT PROJECTS" TAB

**File:** `apps/web/src/app/app/community/page.tsx`

### Add a tab interface with two views:
1. **Find Pros** - Current vendor discovery (map/grid)
2. **Recent Projects** - Gallery of completed work from the community

**Step 1: Add tab state**

```tsx
type PageTab = 'vendors' | 'projects';

export default function VendorDiscoveryPage() {
  const [activeTab, setActiveTab] = useState<PageTab>('vendors');
  const [viewMode, setViewMode] = useState<ViewMode>('map');
  // ... rest of existing state
```

**Step 2: Add tab navigation in header**

```tsx
{/* Header */}
<div className="bg-white border-b border-warm-200 sticky top-0 z-20">
  <div className="max-w-7xl mx-auto px-4 py-4">
    <div className="flex items-center justify-between mb-4">
      <div>
        <h1 className="text-2xl font-bold text-warm-900">Find Pros</h1>
        <p className="text-sm text-warm-500">Trusted contractors from your neighborhood</p>
      </div>
      
      {/* Only show view toggle on vendors tab */}
      {activeTab === 'vendors' && (
        <div className="flex items-center gap-2">
          <button
            onClick={() => setViewMode('map')}
            className={`p-2 rounded-lg ${viewMode === 'map' ? 'bg-haven-100 text-haven-700' : 'text-warm-400 hover:bg-warm-100'}`}
          >
            <MapIcon className="w-5 h-5" />
          </button>
          <button
            onClick={() => setViewMode('grid')}
            className={`p-2 rounded-lg ${viewMode === 'grid' ? 'bg-haven-100 text-haven-700' : 'text-warm-400 hover:bg-warm-100'}`}
          >
            <Grid3X3 className="w-5 h-5" />
          </button>
        </div>
      )}
    </div>
    
    {/* TAB NAVIGATION */}
    <div className="flex gap-1 mb-4 p-1 bg-warm-100 rounded-lg w-fit">
      <button
        onClick={() => setActiveTab('vendors')}
        className={`px-4 py-2 rounded-md text-sm font-medium transition-all ${
          activeTab === 'vendors'
            ? 'bg-white text-warm-900 shadow-sm'
            : 'text-warm-600 hover:text-warm-900'
        }`}
      >
        <div className="flex items-center gap-2">
          <Search className="w-4 h-4" />
          Find Contractors
        </div>
      </button>
      <button
        onClick={() => setActiveTab('projects')}
        className={`px-4 py-2 rounded-md text-sm font-medium transition-all ${
          activeTab === 'projects'
            ? 'bg-white text-warm-900 shadow-sm'
            : 'text-warm-600 hover:text-warm-900'
        }`}
      >
        <div className="flex items-center gap-2">
          <Camera className="w-4 h-4" />
          Recent Projects
        </div>
      </button>
    </div>
    
    {/* Only show search and filters on vendors tab */}
    {activeTab === 'vendors' && (
      <>
        {/* Search */}
        <div className="relative mb-4">
          {/* ... existing search input ... */}
        </div>
        
        {/* Trade Filters */}
        <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 scrollbar-hide">
          {/* ... existing trade filter buttons ... */}
        </div>
      </>
    )}
  </div>
</div>
```

**Step 3: Create mock projects data**

```tsx
interface Project {
  id: string;
  vendorId: string;
  vendorName: string;
  title: string;
  category: string;
  beforeImage?: string;
  afterImage: string;
  description: string;
  cost: string;
  duration: string;
  completedAt: string;
  neighborhood: string;
  rating: number;
  review?: string;
}

const mockProjects: Project[] = [
  {
    id: 'proj-1',
    vendorId: 'v1',
    vendorName: "Mike's Plumbing Pro",
    title: 'Master Bathroom Renovation',
    category: 'Plumbing',
    beforeImage: 'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=400&q=80',
    afterImage: 'https://images.unsplash.com/photo-1620626011761-996317b8d101?w=400&q=80',
    description: 'Complete master bath remodel with new fixtures, rain shower, and heated floors.',
    cost: '$12,500',
    duration: '2 weeks',
    completedAt: '2024-12-01',
    neighborhood: 'Round Hill, Greenwich',
    rating: 5,
    review: 'Exceptional craftsmanship. Mike and his team were professional and finished on time.',
  },
  {
    id: 'proj-2',
    vendorId: 'v2',
    vendorName: 'Country Landscape Design',
    title: 'Backyard Transformation',
    category: 'Landscaping',
    beforeImage: 'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400&q=80',
    afterImage: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=400&q=80',
    description: 'New patio, fire pit, and native garden installation.',
    cost: '$28,000',
    duration: '3 weeks',
    completedAt: '2024-11-15',
    neighborhood: 'Belle Haven, Greenwich',
    rating: 5,
    review: 'Our backyard is now our favorite room. Absolutely stunning work.',
  },
  {
    id: 'proj-3',
    vendorId: 'v4',
    vendorName: 'Comfort Zone HVAC',
    title: 'Whole House HVAC Upgrade',
    category: 'HVAC',
    afterImage: 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&q=80',
    description: 'Replaced 20-year-old system with high-efficiency heat pump and smart thermostat.',
    cost: '$18,500',
    duration: '3 days',
    completedAt: '2024-11-28',
    neighborhood: 'Riverside, Greenwich',
    rating: 5,
  },
  {
    id: 'proj-4',
    vendorId: 'v7',
    vendorName: 'Ace Roofing Co.',
    title: 'Cedar Shake Roof Replacement',
    category: 'Roofing',
    beforeImage: 'https://images.unsplash.com/photo-1632759145351-1d592919f522?w=400&q=80',
    afterImage: 'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=400&q=80',
    description: 'Full roof replacement with premium cedar shakes and copper flashing.',
    cost: '$45,000',
    duration: '1 week',
    completedAt: '2024-10-20',
    neighborhood: 'North Street, Greenwich',
    rating: 5,
    review: 'Beautiful work. The new roof completely transformed the look of our home.',
  },
  {
    id: 'proj-5',
    vendorId: 'v18',
    vendorName: 'Brush Masters Painting',
    title: 'Exterior Home Painting',
    category: 'Painting',
    beforeImage: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=400&q=80',
    afterImage: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=400&q=80',
    description: 'Complete exterior repaint with Benjamin Moore Aura.',
    cost: '$8,500',
    duration: '5 days',
    completedAt: '2024-11-05',
    neighborhood: 'Old Greenwich',
    rating: 4,
  },
  // Add more projects...
];
```

**Step 4: Create the Projects Gallery component**

```tsx
function ProjectsGallery() {
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);
  
  return (
    <div className="max-w-7xl mx-auto p-4">
      <div className="flex items-center justify-between mb-6">
        <span className="text-sm font-medium text-warm-600">
          {mockProjects.length} projects from your neighbors
        </span>
        <select className="text-sm border border-warm-300 rounded-lg px-3 py-1.5">
          <option>Most Recent</option>
          <option>Highest Rated</option>
          <option>By Category</option>
        </select>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {mockProjects.map(project => (
          <ProjectCard 
            key={project.id} 
            project={project} 
            onClick={() => setSelectedProject(project)}
          />
        ))}
      </div>
      
      {/* Project Detail Modal */}
      {selectedProject && (
        <ProjectDetailModal 
          project={selectedProject} 
          onClose={() => setSelectedProject(null)} 
        />
      )}
    </div>
  );
}

function ProjectCard({ project, onClick }: { project: Project; onClick: () => void }) {
  return (
    <div 
      onClick={onClick}
      className="bg-white rounded-xl border border-warm-200 overflow-hidden hover:shadow-lg transition-all cursor-pointer group"
    >
      {/* Before/After Images */}
      <div className="relative h-48">
        <img
          src={project.afterImage}
          alt={project.title}
          className="w-full h-full object-cover"
        />
        {project.beforeImage && (
          <div className="absolute bottom-2 left-2 w-16 h-16 rounded-lg overflow-hidden border-2 border-white shadow-lg">
            <img
              src={project.beforeImage}
              alt="Before"
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
              <span className="text-white text-xs font-medium">Before</span>
            </div>
          </div>
        )}
        <div className="absolute top-2 right-2 px-2 py-1 bg-black/60 text-white text-xs rounded-full">
          {project.category}
        </div>
      </div>
      
      {/* Content */}
      <div className="p-4">
        <h3 className="font-semibold text-warm-900 group-hover:text-haven-700 transition-colors">
          {project.title}
        </h3>
        <p className="text-sm text-warm-500 mt-1">
          by {project.vendorName}
        </p>
        
        <div className="mt-3 flex items-center justify-between text-sm">
          <div className="flex items-center gap-1 text-warm-600">
            <MapPin className="w-3.5 h-3.5" />
            <span>{project.neighborhood}</span>
          </div>
          <div className="flex items-center gap-1">
            <Star className="w-3.5 h-3.5 text-amber-500 fill-current" />
            <span className="text-warm-600">{project.rating}</span>
          </div>
        </div>
        
        <div className="mt-3 flex items-center gap-4 text-xs text-warm-500">
          <span className="font-medium text-haven-700">{project.cost}</span>
          <span>•</span>
          <span>{project.duration}</span>
        </div>
      </div>
    </div>
  );
}

function ProjectDetailModal({ project, onClose }: { project: Project; onClose: () => void }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-forest-950/60 backdrop-blur-sm">
      <div className="bg-white rounded-2xl shadow-xl max-w-2xl w-full max-h-[90vh] overflow-hidden">
        {/* Header with images */}
        <div className="relative">
          <div className="grid grid-cols-2 gap-1">
            {project.beforeImage && (
              <div className="relative">
                <img src={project.beforeImage} alt="Before" className="w-full h-64 object-cover" />
                <div className="absolute bottom-2 left-2 px-2 py-1 bg-black/60 text-white text-xs rounded">
                  Before
                </div>
              </div>
            )}
            <div className="relative">
              <img src={project.afterImage} alt="After" className={`w-full h-64 object-cover ${!project.beforeImage ? 'col-span-2' : ''}`} />
              <div className="absolute bottom-2 left-2 px-2 py-1 bg-haven-600 text-white text-xs rounded">
                After
              </div>
            </div>
          </div>
          <button
            onClick={onClose}
            className="absolute top-3 right-3 w-8 h-8 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center shadow-lg hover:bg-white"
          >
            <X className="w-4 h-4 text-warm-600" />
          </button>
        </div>
        
        {/* Content */}
        <div className="p-6">
          <div className="flex items-start justify-between">
            <div>
              <h2 className="text-xl font-bold text-warm-900">{project.title}</h2>
              <p className="text-haven-600 mt-1">by {project.vendorName}</p>
            </div>
            <div className="text-right">
              <div className="text-xl font-bold text-warm-900">{project.cost}</div>
              <div className="text-sm text-warm-500">{project.duration}</div>
            </div>
          </div>
          
          <p className="mt-4 text-warm-600">{project.description}</p>
          
          <div className="mt-4 flex items-center gap-4 text-sm text-warm-500">
            <div className="flex items-center gap-1">
              <MapPin className="w-4 h-4" />
              {project.neighborhood}
            </div>
            <div className="flex items-center gap-1">
              <Calendar className="w-4 h-4" />
              {new Date(project.completedAt).toLocaleDateString()}
            </div>
          </div>
          
          {project.review && (
            <div className="mt-4 p-4 bg-warm-50 rounded-xl">
              <div className="flex items-center gap-1 mb-2">
                {[...Array(5)].map((_, i) => (
                  <Star 
                    key={i} 
                    className={`w-4 h-4 ${i < project.rating ? 'text-amber-500 fill-current' : 'text-warm-300'}`} 
                  />
                ))}
              </div>
              <p className="text-warm-700 italic">"{project.review}"</p>
              <p className="text-sm text-warm-500 mt-2">— A neighbor in {project.neighborhood}</p>
            </div>
          )}
          
          <div className="mt-6 flex gap-3">
            <button className="flex-1 btn-primary">
              Contact {project.vendorName.split(' ')[0]}
            </button>
            <button className="btn-secondary">
              View All Work
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
```

**Step 5: Update main content to show correct tab**

```tsx
{/* Content */}
<div className="max-w-7xl mx-auto">
  {activeTab === 'vendors' ? (
    // Existing vendor discovery content (map or grid view)
    viewMode === 'map' ? (
      <div className="flex flex-col lg:flex-row h-[calc(100vh-200px)]">
        {/* Map */}
        {/* Vendor sidebar */}
      </div>
    ) : (
      /* Grid View */
      <div className="p-4">
        {/* Vendor grid */}
      </div>
    )
  ) : (
    // Projects gallery
    <ProjectsGallery />
  )}
</div>
```

**Step 6: Add Calendar icon import if not already present**

```tsx
import { Calendar } from 'lucide-react';
```

---

## VERIFICATION CHECKLIST

After applying all fixes, verify:

1. ✅ Sidebar is deep forest green (`bg-forest-900`), not slate
2. ✅ Sidebar text is white/light (`text-white`, `text-white/70`)
3. ✅ Active nav items have haven-green icon (`text-haven-400`)
4. ✅ App background is warm off-white (`bg-warm-50`)
5. ✅ Find Pros page uses warm colors, not slate
6. ✅ Vendor cards have white background, warm borders
7. ✅ Buttons are haven-green (`bg-haven-600`)
8. ✅ Map markers are haven-green for trusted vendors
9. ✅ No more random slate colors anywhere
10. ✅ Vendor logos use DiceBear 'bottts' style (robot-like professional icons)
11. ✅ All user avatars use DiceBear 'lorelei' style (friendly illustrated)
12. ✅ Map is zoomed out to show Westchester region (zoom level 10)
13. ✅ Vendors are spread across different neighborhoods
14. ✅ Map popup card properly contains all elements (X button, verified badge inside)
15. ✅ "Recent Projects" tab shows completed work gallery
16. ✅ Project cards have before/after images

---

## RUN AFTER COMPLETION

```bash
cd apps/web
pnpm dev
```

Test:
- Navigate to http://localhost:3000/app (logged in)
- Check sidebar is deep green
- Go to Find Pros page
- Verify all colors are warm/haven palette
- No slate colors visible

🏠✨

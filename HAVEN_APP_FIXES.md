# Haven App-Wide Color Fix & Your Home Page Enhancement

## OVERVIEW

This document addresses all remaining green color usage throughout the application, fixes text contrast issues on dark backgrounds, and enhances the "Your Home" page to be more informative.

---

## PART 1: GLOBAL COLOR SEARCH & REPLACE

### Files to Search
Search ALL files in these directories:
- `apps/web/src/app/**/*.tsx`
- `apps/web/src/components/**/*.tsx`
- `packages/ui/src/**/*.tsx`

### Color Mappings (Old → New)

**Green to Navy:**
```
bg-haven-500 → bg-haven-700
bg-haven-600 → bg-haven-700
bg-haven-700 → bg-haven-800
hover:bg-haven-600 → hover:bg-haven-800
hover:bg-haven-700 → hover:bg-haven-800

text-haven-500 → text-haven-700
text-haven-600 → text-haven-700
text-haven-700 → text-haven-800

border-haven-500 → border-haven-600
border-haven-600 → border-haven-700

ring-haven-500 → ring-haven-600
focus:ring-haven-500 → focus:ring-haven-600
focus:border-haven-500 → focus:border-haven-700

from-haven-500 → from-haven-700
from-haven-600 → from-haven-700
to-haven-600 → to-haven-800
to-haven-700 → to-haven-800
via-haven-600 → via-haven-800
```

**Green backgrounds to Navy (specific patterns):**
```
bg-green-500 → bg-haven-700
bg-green-600 → bg-haven-700
bg-emerald-500 → bg-haven-700
bg-emerald-600 → bg-haven-700
```

**Status colors (keep semantic but check context):**
- Keep `bg-green-100 text-green-700` for SUCCESS states (checkmarks, completed)
- Keep `bg-red-100 text-red-700` for ERROR states
- Keep `bg-amber-100 text-amber-700` for WARNING states
- Keep `bg-blue-100 text-blue-700` for INFO states

---

## PART 2: SPECIFIC COMPONENT FIXES

### 2.1 Sidebar (ALL portals: app, manager, vendor, handyman, admin)

The sidebar is currently green. Change to navy.

**Find files:**
- `apps/web/src/components/app/Sidebar.tsx` (or similar)
- `apps/web/src/app/app/layout.tsx`
- `apps/web/src/app/manager/layout.tsx`
- `apps/web/src/app/vendor/layout.tsx`
- `apps/web/src/app/handyman/layout.tsx`
- `apps/web/src/app/admin/layout.tsx`

**Change:**
```tsx
// OLD (green sidebar)
className="bg-gradient-to-b from-haven-600 to-haven-700"
// or
className="bg-haven-600"
// or
className="bg-gradient-to-b from-forest-900 to-forest-950"
// or
className="bg-gradient-to-b from-emerald-800 to-emerald-900"

// NEW (navy sidebar)
className="bg-gradient-to-b from-haven-800 to-haven-900"
```

**Sidebar nav items:**
```tsx
// Active state - OLD
className="bg-haven-500/20 text-white"
// or
className="bg-white/15 text-white"

// Active state - NEW
className="bg-white/15 text-white"

// Hover state
className="hover:bg-white/10 text-white/70 hover:text-white"
```

**Sidebar logo/brand:**
```tsx
// Ensure "Haven" text is white
<span className="text-white font-bold text-xl">Haven</span>
```

### 2.2 Chat/Support Bubble (bottom right)

**Find:** The floating chat bubble component (likely Intercom or custom)

**Change:**
```tsx
// OLD
className="bg-haven-600" or "bg-green-600" or "bg-emerald-600"

// NEW  
className="bg-haven-700"
```

### 2.3 Sign-In Page

**File:** `apps/web/src/app/login/page.tsx`

**Icon:** Change green home icon to navy
```tsx
// OLD
<div className="w-16 h-16 rounded-2xl bg-haven-600 ...">
// or
<div className="w-16 h-16 rounded-2xl bg-green-600 ...">

// NEW
<div className="w-16 h-16 rounded-2xl bg-haven-700 ...">
```

**Input focus states:**
```tsx
// OLD
className="... focus:ring-haven-500 focus:border-haven-500"
// or yellow background shown in screenshot - remove that

// NEW
className="... focus:ring-haven-600 focus:border-haven-700 bg-white"
```

**"Create one" link:**
```tsx
// OLD
className="text-haven-600 hover:text-haven-700"

// NEW
className="text-haven-700 hover:text-haven-800"
```

**Submit button:**
```tsx
// NEW
className="bg-haven-700 text-white hover:bg-haven-800"
```

### 2.4 Status Banners (Shopping, Maintenance pages)

**Change the green status bars to navy:**
```tsx
// OLD (Sarah is handling X items)
<div className="bg-haven-600 text-white ...">
// or
<div className="bg-gradient-to-r from-haven-500 to-haven-600 text-white ...">

// NEW
<div className="bg-haven-700 text-white ...">
// or
<div className="bg-gradient-to-br from-haven-700 to-haven-800 text-white ...">
```

### 2.5 Home Health Circle (Maintenance Page)

**File:** `apps/web/src/app/app/maintenance/page.tsx` or component

**Change the circular progress indicator:**
```tsx
// OLD - green circle
stroke="rgb(34, 197, 94)" // green-500
// or
className="text-haven-500"
// or  
className="text-green-500"

// NEW - navy circle (or keep it a semantic color based on score)
// Option A: Always navy
stroke="rgb(30, 42, 59)" // haven-700

// Option B: Semantic (recommended)
// 0-40: red, 41-70: amber, 71-100: green (keep green for "good health")
// If score-based, keep as is but update the surrounding UI
```

**The number inside:**
```tsx
// Should be navy or match the circle
className="text-haven-700 text-4xl font-bold"
```

### 2.6 Progress Bars / Lifespan Indicators

On system cards, the progress bars showing lifespan:

```tsx
// OLD
<div className="bg-haven-500 h-2 rounded-full" style={{width: '40%'}} />

// NEW - use semantic colors based on health:
// Good (60%+ remaining): green-500
// Warning (30-60% remaining): amber-500
// Critical (<30% remaining): red-500
// Or use navy for neutral:
<div className="bg-haven-600 h-2 rounded-full" style={{width: '40%'}} />
```

### 2.7 Notification Badges

The red badge with number (e.g., "5" next to Sarah):
```tsx
// Keep red for notifications - this is correct
className="bg-red-500 text-white"
```

### 2.8 Active Tab Indicators

On the Your Home page tabs (Overview, Maintenance, Systems, etc.):
```tsx
// OLD
className="border-b-2 border-haven-600 text-haven-600"

// NEW
className="border-b-2 border-haven-700 text-haven-700"
```

---

## PART 3: HOMEPAGE TEXT CONTRAST FIXES

### Problem
Black text on dark navy backgrounds is unreadable.

### Files to Check
`apps/web/src/app/page.tsx`

### Sections with Dark Backgrounds

**Hero Section** (`bg-gradient-to-br from-haven-700 via-haven-800 to-haven-900`):
- ALL text must be `text-white` or `text-haven-100` or `text-champagne-300`
- NO `text-warm-900`, `text-black`, or `text-haven-700` on this background

**Handyman Section** (`bg-gradient-to-br from-warm-900 via-warm-800 to-warm-900`):
- Heading: `text-white` (NOT black)
- Body: `text-warm-300`
- Checkmarks: `text-champagne-300`
- Label: `text-champagne-300`

**Compare Plans Section** (`bg-haven-900`):
- All text: `text-white`, `text-warm-300`, `text-warm-400`, or `text-champagne-300`
- Table headers: `text-warm-400`
- Table cells: `text-warm-300`

**Final CTA Section** (`bg-gradient-to-br from-haven-700 via-haven-800 to-haven-900`):
- Heading: `text-white`
- Body: `text-haven-100` or `text-haven-200`
- Accent: `text-champagne-300`

**Footer** (`bg-haven-900`):
- All text: `text-white`, `text-warm-400`, `text-warm-300`

### Quick Fix Pattern
Search for any of these on dark backgrounds and fix:
```tsx
// WRONG on dark backgrounds:
text-warm-900
text-warm-800
text-warm-700
text-black
text-haven-700
text-haven-800

// CORRECT on dark backgrounds:
text-white
text-warm-100
text-warm-200
text-warm-300
text-warm-400
text-haven-100
text-haven-200
text-champagne-300
```

---

## PART 4: YOUR HOME PAGE ENHANCEMENT

### File
`apps/web/src/app/app/your-home/page.tsx` (or similar path)

### Current State (from screenshot)
- Just shows property details and basic maintenance summary
- Very minimal, not informative
- No Home Health score
- No system status overview
- No quick actions
- Property image not displaying

### New Design: Information-Rich Overview

```tsx
// Your Home Overview Page Structure

export default function YourHomePage() {
  return (
    <div className="space-y-6">
      {/* Property Header with Image */}
      <div className="relative h-64 rounded-2xl overflow-hidden bg-warm-900">
        {property.imageUrl ? (
          <img 
            src={property.imageUrl} 
            alt={property.address}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-haven-800 to-haven-900 flex items-center justify-center">
            <Home className="w-16 h-16 text-haven-600" />
          </div>
        )}
        {/* Overlay with property info */}
        <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-6">
          <h1 className="text-2xl font-bold text-white">{property.address}</h1>
          <p className="text-white/80">{property.city}, {property.state} {property.zip}</p>
          <div className="flex gap-4 mt-2 text-white/70 text-sm">
            <span>{property.beds} beds</span>
            <span>{property.baths} baths</span>
            <span>{property.sqft.toLocaleString()} sqft</span>
            <span>{property.acres} acres</span>
          </div>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="border-b border-warm-200">
        <nav className="flex gap-6">
          {['Overview', 'Maintenance', 'Systems', 'Vendors', 'Vehicles', 'Financial', 'Documents'].map(tab => (
            <button 
              key={tab}
              className={`pb-3 text-sm font-medium border-b-2 transition-colors ${
                activeTab === tab 
                  ? 'border-haven-700 text-haven-700' 
                  : 'border-transparent text-warm-500 hover:text-warm-700'
              }`}
            >
              {tab}
              {tab === 'Maintenance' && maintenanceCount > 0 && (
                <span className="ml-2 px-2 py-0.5 bg-amber-100 text-amber-700 text-xs rounded-full">
                  {maintenanceCount}
                </span>
              )}
            </button>
          ))}
        </nav>
      </div>

      {/* Main Grid - Overview Tab */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Column - Home Health + Quick Stats */}
        <div className="space-y-6">
          
          {/* Home Health Score Card */}
          <div className="bg-white rounded-2xl border border-warm-200 p-6 shadow-soft">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-semibold text-warm-900">Home Health</h2>
              <button className="text-sm text-haven-700 hover:text-haven-800">View Details</button>
            </div>
            
            {/* Circular Progress */}
            <div className="flex justify-center mb-6">
              <div className="relative w-32 h-32">
                <svg className="w-full h-full transform -rotate-90">
                  <circle
                    cx="64"
                    cy="64"
                    r="56"
                    stroke="#E7E5E4"
                    strokeWidth="12"
                    fill="none"
                  />
                  <circle
                    cx="64"
                    cy="64"
                    r="56"
                    stroke={healthScore >= 70 ? '#22C55E' : healthScore >= 40 ? '#F59E0B' : '#EF4444'}
                    strokeWidth="12"
                    fill="none"
                    strokeLinecap="round"
                    strokeDasharray={`${(healthScore / 100) * 352} 352`}
                  />
                </svg>
                <div className="absolute inset-0 flex flex-col items-center justify-center">
                  <span className="text-4xl font-bold text-warm-900">{healthScore}</span>
                  <span className="text-sm text-warm-500">/ 100</span>
                </div>
              </div>
            </div>

            {/* Health Breakdown */}
            <div className="space-y-3">
              <div className="flex items-center justify-between text-sm">
                <span className="text-warm-600">Systems needing attention</span>
                <span className="font-medium text-amber-600">{needsAttention}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-warm-600">Overdue maintenance</span>
                <span className="font-medium text-red-600">{overdue}</span>
              </div>
              <div className="flex items-center justify-between text-sm">
                <span className="text-warm-600">On track</span>
                <span className="font-medium text-green-600">{onTrack}</span>
              </div>
            </div>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-2 gap-4">
            <div className="bg-white rounded-xl border border-warm-200 p-4">
              <p className="text-2xl font-bold text-warm-900">{totalSystems}</p>
              <p className="text-sm text-warm-500">Systems Tracked</p>
            </div>
            <div className="bg-white rounded-xl border border-warm-200 p-4">
              <p className="text-2xl font-bold text-warm-900">{totalVendors}</p>
              <p className="text-sm text-warm-500">Vendors</p>
            </div>
            <div className="bg-white rounded-xl border border-warm-200 p-4">
              <p className="text-2xl font-bold text-green-600">${moneySaved}</p>
              <p className="text-sm text-warm-500">Saved This Year</p>
            </div>
            <div className="bg-white rounded-xl border border-warm-200 p-4">
              <p className="text-2xl font-bold text-warm-900">{documents}</p>
              <p className="text-sm text-warm-500">Documents</p>
            </div>
          </div>
        </div>

        {/* Middle Column - Systems Overview */}
        <div className="space-y-6">
          <div className="bg-white rounded-2xl border border-warm-200 p-6 shadow-soft">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-semibold text-warm-900">Systems Status</h2>
              <button className="text-sm text-haven-700 hover:text-haven-800">View All</button>
            </div>

            <div className="space-y-4">
              {systems.slice(0, 5).map(system => (
                <div 
                  key={system.id}
                  className="flex items-center gap-4 p-3 rounded-xl hover:bg-warm-50 cursor-pointer transition-colors"
                  onClick={() => navigateToSystem(system.id)}
                >
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${
                    system.status === 'excellent' ? 'bg-green-100' :
                    system.status === 'good' ? 'bg-blue-100' :
                    system.status === 'attention' ? 'bg-amber-100' :
                    'bg-red-100'
                  }`}>
                    <system.icon className={`w-5 h-5 ${
                      system.status === 'excellent' ? 'text-green-600' :
                      system.status === 'good' ? 'text-blue-600' :
                      system.status === 'attention' ? 'text-amber-600' :
                      'text-red-600'
                    }`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-warm-900 truncate">{system.name}</p>
                    <p className="text-sm text-warm-500">{system.brand} • Year {system.age} of {system.lifespan}</p>
                  </div>
                  <div className="text-right">
                    <span className={`inline-flex px-2 py-0.5 rounded-full text-xs font-medium ${
                      system.status === 'excellent' ? 'bg-green-100 text-green-700' :
                      system.status === 'good' ? 'bg-blue-100 text-blue-700' :
                      system.status === 'attention' ? 'bg-amber-100 text-amber-700' :
                      'bg-red-100 text-red-700'
                    }`}>
                      {system.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right Column - Activity & Upcoming */}
        <div className="space-y-6">
          
          {/* Upcoming Maintenance */}
          <div className="bg-white rounded-2xl border border-warm-200 p-6 shadow-soft">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-semibold text-warm-900">Upcoming</h2>
              <button className="text-sm text-haven-700 hover:text-haven-800">View All</button>
            </div>

            <div className="space-y-3">
              {upcomingMaintenance.slice(0, 4).map(item => (
                <div key={item.id} className="flex items-center gap-3 p-3 bg-warm-50 rounded-xl">
                  <div className="w-12 text-center">
                    <p className="text-lg font-bold text-warm-900">{item.day}</p>
                    <p className="text-xs text-warm-500 uppercase">{item.month}</p>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-warm-900 truncate">{item.title}</p>
                    <p className="text-sm text-warm-500">{item.vendor}</p>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded-full ${
                    item.confirmed ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'
                  }`}>
                    {item.confirmed ? 'Confirmed' : 'Pending'}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Recent Activity */}
          <div className="bg-white rounded-2xl border border-warm-200 p-6 shadow-soft">
            <div className="flex items-center justify-between mb-4">
              <h2 className="font-semibold text-warm-900">Recent Activity</h2>
            </div>

            <div className="space-y-4">
              {recentActivity.slice(0, 4).map((activity, idx) => (
                <div key={idx} className="flex items-start gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center flex-shrink-0 ${
                    activity.type === 'service' ? 'bg-blue-100' :
                    activity.type === 'payment' ? 'bg-green-100' :
                    'bg-warm-100'
                  }`}>
                    <activity.icon className={`w-4 h-4 ${
                      activity.type === 'service' ? 'text-blue-600' :
                      activity.type === 'payment' ? 'text-green-600' :
                      'text-warm-600'
                    }`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm text-warm-900">{activity.title}</p>
                    <p className="text-xs text-warm-500">{activity.date}</p>
                  </div>
                  {activity.amount && (
                    <span className="text-sm font-medium text-warm-900">${activity.amount}</span>
                  )}
                </div>
              ))}
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
```

### Property Image Fix

Check how property images are stored and displayed:

```tsx
// If using Next.js Image component
import Image from 'next/image';

// Make sure the image URL is correct
// If stored locally, ensure path is correct
// If stored in cloud (S3, Cloudinary), ensure URL is accessible

<div className="relative h-64 rounded-2xl overflow-hidden">
  {property.imageUrl ? (
    <Image
      src={property.imageUrl}
      alt={property.address}
      fill
      className="object-cover"
      // If external URL, add to next.config.js domains
    />
  ) : (
    // Fallback gradient
    <div className="w-full h-full bg-gradient-to-br from-haven-800 to-haven-900" />
  )}
</div>
```

**Check next.config.js for image domains if using external images.**

---

## PART 5: VERIFICATION CHECKLIST

After all changes, verify:

### Colors
- [ ] Sidebar is navy (haven-800/900 gradient), not green
- [ ] All primary buttons are `bg-haven-700 hover:bg-haven-800`
- [ ] Chat bubble is navy, not green
- [ ] Sign-in page icon is navy, not green
- [ ] Input focus states use navy ring
- [ ] Status banners are navy (or champagne for highlights)
- [ ] Tab active states are navy
- [ ] Links are `text-haven-700 hover:text-haven-800`

### Contrast
- [ ] Hero section: ALL text is white/light
- [ ] Handyman section: Heading is WHITE, not black
- [ ] Compare Plans table: All text is visible on dark bg
- [ ] Final CTA: All text is white/light
- [ ] Footer: All text is visible

### Your Home Page
- [ ] Shows Home Health score with circular gauge
- [ ] Shows systems summary with status indicators
- [ ] Shows upcoming maintenance
- [ ] Shows recent activity
- [ ] Property image displays (or elegant fallback)
- [ ] Can click through to each section

### Green Removal
- [ ] No bright green (#4a9a4a, #22c55e) used for branding
- [ ] Green ONLY used for semantic success states (checkmarks, completed)
- [ ] No green in sidebar, buttons, links, or primary UI elements

---

## PART 6: EXECUTION

Run in Claude Code:

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste:

```
Read HAVEN_APP_FIXES.md and implement all fixes:

1. GLOBAL COLOR CHANGES:
   - Search all .tsx files for green color classes (haven-500, haven-600, emerald-*, green-* used for branding)
   - Replace with navy equivalents (haven-700, haven-800)
   - Update sidebar in ALL portals (app, manager, vendor, handyman, admin) from green to navy gradient
   - Update chat/support bubble from green to navy
   - Update sign-in page icon and focus states

2. HOMEPAGE CONTRAST FIXES:
   - In apps/web/src/app/page.tsx
   - Find any black or dark text on dark sections (hero, handyman, compare plans, final CTA, footer)
   - Change to white or light colors (text-white, text-warm-300, text-champagne-300)
   - CRITICAL: Handyman section heading must be text-white, NOT text-warm-900

3. YOUR HOME PAGE ENHANCEMENT:
   - Redesign apps/web/src/app/app/your-home/page.tsx (or similar path)
   - Add Home Health circular score gauge
   - Add Systems Status preview with clickable items
   - Add Upcoming Maintenance preview
   - Add Recent Activity feed
   - Add Quick Stats grid
   - Fix property image display

4. Verify no em dashes remain

After implementing, run pnpm build to verify no errors, then commit and push.
```

---

## QUICK REFERENCE: Final Color Usage

| Element | Class |
|---------|-------|
| Primary button | `bg-haven-700 text-white hover:bg-haven-800` |
| Secondary button | `bg-white text-warm-700 border-warm-200 hover:bg-warm-50` |
| Ghost button on dark | `border-white/30 text-white hover:bg-white/10` |
| Link | `text-haven-700 hover:text-haven-800` |
| Sidebar | `bg-gradient-to-b from-haven-800 to-haven-900` |
| Input focus | `focus:ring-haven-600 focus:border-haven-700` |
| Active tab | `border-haven-700 text-haven-700` |
| Status banner | `bg-haven-700 text-white` |
| Success state | `bg-green-100 text-green-700` |
| Warning state | `bg-amber-100 text-amber-700` |
| Error state | `bg-red-100 text-red-700` |
| Accent on dark | `text-champagne-300` |

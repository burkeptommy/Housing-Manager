# Haven Mobile Responsiveness Fix

## PROBLEM

On mobile devices:
- Dashboard stat cards (Home Health, Items Handled, Next Service) are cut off
- Cards don't fit within viewport
- Content overflows horizontally

## SOLUTION

Make all pages responsive with proper mobile layouts.

---

## FIX 1: DASHBOARD STAT CARDS

The three stat cards in the hero section need to stack or scroll on mobile.

### Option A: Stack Vertically on Mobile (Recommended)

```tsx
{/* Stat cards - stack on mobile, row on desktop */}
<div className="flex flex-col sm:flex-row gap-3 mt-6">
  {/* Home Health */}
  <div className="flex-1 bg-emerald-50 border border-emerald-200 rounded-xl px-4 py-3">
    <p className="text-xs text-emerald-600 uppercase tracking-wide">Home Health</p>
    <div className="flex items-baseline gap-2">
      <span className="text-2xl font-bold text-emerald-700">94%</span>
      <span className="text-xs text-emerald-600 bg-emerald-100 px-2 py-0.5 rounded-full">Excellent</span>
    </div>
  </div>
  
  {/* Items Handled */}
  <div className="flex-1 bg-champagne-100 border border-champagne-200 rounded-xl px-4 py-3">
    <p className="text-xs text-champagne-600 uppercase tracking-wide">Items Handled</p>
    <span className="text-2xl font-bold text-haven-700">4</span>
  </div>
  
  {/* Next Service */}
  <div className="flex-1 bg-champagne-100 border border-champagne-200 rounded-xl px-4 py-3">
    <p className="text-xs text-champagne-600 uppercase tracking-wide">Next Service</p>
    <span className="text-2xl font-bold text-haven-700">Jan 7</span>
  </div>
</div>
```

### Option B: Horizontal Scroll on Mobile

```tsx
{/* Stat cards - horizontal scroll on mobile */}
<div className="flex gap-3 mt-6 overflow-x-auto pb-2 -mx-4 px-4 sm:mx-0 sm:px-0 sm:overflow-visible scrollbar-hide">
  {/* Home Health */}
  <div className="flex-shrink-0 w-[140px] sm:w-auto sm:flex-1 bg-emerald-50 border border-emerald-200 rounded-xl px-4 py-3">
    <p className="text-xs text-emerald-600 uppercase tracking-wide">Home Health</p>
    <div className="flex items-baseline gap-2">
      <span className="text-2xl font-bold text-emerald-700">94%</span>
      <span className="text-xs text-emerald-600 bg-emerald-100 px-2 py-0.5 rounded-full">Excellent</span>
    </div>
  </div>
  
  {/* Items Handled */}
  <div className="flex-shrink-0 w-[120px] sm:w-auto sm:flex-1 bg-champagne-100 border border-champagne-200 rounded-xl px-4 py-3">
    <p className="text-xs text-champagne-600 uppercase tracking-wide">Items Handled</p>
    <span className="text-2xl font-bold text-haven-700">4</span>
  </div>
  
  {/* Next Service */}
  <div className="flex-shrink-0 w-[120px] sm:w-auto sm:flex-1 bg-champagne-100 border border-champagne-200 rounded-xl px-4 py-3">
    <p className="text-xs text-champagne-600 uppercase tracking-wide">Next Service</p>
    <span className="text-2xl font-bold text-haven-700">Jan 7</span>
  </div>
</div>
```

### Option C: 2x2 Grid on Mobile

```tsx
{/* Stat cards - 2 column grid on mobile, row on desktop */}
<div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mt-6">
  {/* Home Health - spans full width on mobile or takes first spot */}
  <div className="col-span-2 sm:col-span-1 bg-emerald-50 border border-emerald-200 rounded-xl px-4 py-3">
    <p className="text-xs text-emerald-600 uppercase tracking-wide">Home Health</p>
    <div className="flex items-baseline gap-2">
      <span className="text-2xl font-bold text-emerald-700">94%</span>
      <span className="text-xs text-emerald-600 bg-emerald-100 px-2 py-0.5 rounded-full">Excellent</span>
    </div>
  </div>
  
  {/* Items Handled */}
  <div className="bg-champagne-100 border border-champagne-200 rounded-xl px-4 py-3">
    <p className="text-xs text-champagne-600 uppercase tracking-wide">Items Handled</p>
    <span className="text-2xl font-bold text-haven-700">4</span>
  </div>
  
  {/* Next Service */}
  <div className="bg-champagne-100 border border-champagne-200 rounded-xl px-4 py-3">
    <p className="text-xs text-champagne-600 uppercase tracking-wide">Next Service</p>
    <span className="text-2xl font-bold text-haven-700">Jan 7</span>
  </div>
</div>
```

---

## FIX 2: GENERAL MOBILE PATTERNS

### Container Padding

```tsx
{/* Proper container with mobile padding */}
<div className="px-4 sm:px-6 lg:px-8">
  {/* Content */}
</div>
```

### Card Grids

```tsx
{/* Cards that stack on mobile, grid on desktop */}
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
  {/* Cards */}
</div>
```

### Side-by-Side Content

```tsx
{/* Stack on mobile, side-by-side on desktop */}
<div className="flex flex-col lg:flex-row gap-6">
  <div className="flex-1">{/* Left content */}</div>
  <div className="w-full lg:w-80">{/* Right sidebar */}</div>
</div>
```

### Tables on Mobile

```tsx
{/* Scrollable table on mobile */}
<div className="overflow-x-auto -mx-4 sm:mx-0">
  <div className="inline-block min-w-full align-middle px-4 sm:px-0">
    <table className="min-w-full">
      {/* Table content */}
    </table>
  </div>
</div>
```

### Long Text

```tsx
{/* Truncate long text on mobile */}
<p className="truncate sm:whitespace-normal">{longText}</p>
```

---

## FIX 3: DASHBOARD SPECIFIC FIXES

### File: `apps/web/src/app/app/dashboard/page.tsx`

```tsx
export default function DashboardPage() {
  return (
    <div className="min-h-screen bg-warm-50">
      {/* Hero Section */}
      <div className="bg-gradient-to-br from-haven-700 via-haven-800 to-haven-900 text-white">
        <div className="px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
          {/* Greeting */}
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-haven-200 text-sm">Wednesday, December 24</p>
              <h1 className="text-2xl sm:text-3xl font-bold mt-1">Good afternoon, Bob</h1>
            </div>
            <div className="flex items-center gap-2 bg-white/10 rounded-full px-3 py-1.5">
              <Sun className="w-4 h-4 text-amber-300" />
              <span className="text-sm font-medium">68°</span>
            </div>
          </div>
          
          {/* Stat Cards - RESPONSIVE */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 mt-6">
            {/* Home Health - full width on mobile */}
            <div className="col-span-2 sm:col-span-1 bg-emerald-50/90 backdrop-blur border border-emerald-200/50 rounded-xl px-4 py-3">
              <p className="text-xs text-emerald-600 uppercase tracking-wide font-medium">Home Health</p>
              <div className="flex items-baseline gap-2 mt-1">
                <span className="text-2xl font-bold text-emerald-700">94%</span>
                <span className="text-xs text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full font-medium">
                  Excellent
                </span>
              </div>
            </div>
            
            {/* Items Handled */}
            <div className="bg-champagne-100/90 backdrop-blur border border-champagne-200/50 rounded-xl px-4 py-3">
              <p className="text-xs text-champagne-600 uppercase tracking-wide font-medium">Items Handled</p>
              <span className="text-2xl font-bold text-haven-700 mt-1 block">4</span>
            </div>
            
            {/* Next Service */}
            <div className="bg-champagne-100/90 backdrop-blur border border-champagne-200/50 rounded-xl px-4 py-3">
              <p className="text-xs text-champagne-600 uppercase tracking-wide font-medium">Next Service</p>
              <span className="text-2xl font-bold text-haven-700 mt-1 block">Jan 7</span>
            </div>
          </div>
        </div>
      </div>
      
      {/* Main Content */}
      <div className="px-4 sm:px-6 lg:px-8 py-6">
        {/* Today's Notes */}
        <div className="bg-white rounded-2xl border border-warm-200 shadow-soft p-4 sm:p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-warm-900">Today's Notes</h2>
            <span className="text-xs bg-warm-100 text-warm-600 px-2 py-0.5 rounded-full">3</span>
          </div>
          {/* Notes list */}
        </div>
        
        {/* Two column layout - stack on mobile */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Left column */}
          <div className="space-y-6">
            {/* Needs Your Decision */}
            {/* Sarah Card */}
          </div>
          
          {/* Right column */}
          <div className="space-y-6">
            {/* Today's Logistics */}
            {/* House Health */}
          </div>
        </div>
      </div>
    </div>
  );
}
```

---

## FIX 4: OTHER PAGES TO CHECK

### Pages that need mobile review:

1. **Sarah Tab** - Stats row may overflow
2. **Messages Tab** - Conversation list should be full width
3. **Your Home** - Tab navigation may overflow
4. **Maintenance** - System cards grid
5. **Find Pros** - Vendor cards
6. **Money** - Financial tables/charts
7. **Family** - Member cards

### Common fixes needed:

```tsx
// Stats row
<div className="grid grid-cols-2 sm:grid-cols-4 gap-3">

// Tab navigation - horizontal scroll
<div className="overflow-x-auto -mx-4 px-4 sm:mx-0 sm:px-0">
  <div className="flex gap-2 min-w-max sm:min-w-0">
    {tabs.map(tab => (...))}
  </div>
</div>

// Cards grid
<div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">

// Two column with sidebar
<div className="flex flex-col lg:flex-row gap-6">
  <div className="flex-1 order-2 lg:order-1">{/* Main */}</div>
  <div className="w-full lg:w-80 order-1 lg:order-2">{/* Sidebar */}</div>
</div>
```

---

## FIX 5: MOBILE NAVIGATION

The bottom navigation bar should be properly spaced:

```tsx
{/* Mobile bottom nav */}
<nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-warm-200 px-2 py-2 sm:hidden z-40">
  <div className="flex items-center justify-around">
    {navItems.map(item => (
      <a 
        key={item.href}
        href={item.href}
        className="flex flex-col items-center gap-1 px-3 py-2"
      >
        <item.icon className="w-5 h-5" />
        <span className="text-xs">{item.label}</span>
      </a>
    ))}
  </div>
</nav>

{/* Add padding to main content to account for bottom nav */}
<main className="pb-20 sm:pb-0">
  {/* Content */}
</main>
```

---

## BREAKPOINT REFERENCE

| Breakpoint | Width | Use For |
|------------|-------|---------|
| (default) | < 640px | Mobile phones |
| `sm:` | ≥ 640px | Large phones, small tablets |
| `md:` | ≥ 768px | Tablets |
| `lg:` | ≥ 1024px | Small laptops, tablets landscape |
| `xl:` | ≥ 1280px | Laptops, desktops |
| `2xl:` | ≥ 1536px | Large desktops |

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Fix mobile responsiveness across the app - read HAVEN_MOBILE_FIX.md:

1. Dashboard stat cards (apps/web/src/app/app/dashboard/page.tsx):
   - Use grid-cols-2 sm:grid-cols-3 layout
   - Home Health card spans col-span-2 sm:col-span-1 on mobile
   - Items Handled and Next Service each take one column
   - Cards must not overflow viewport

2. Check and fix these pages for mobile:
   - Sarah tab - stats should wrap/stack
   - Messages - full width conversation list
   - Your Home - scrollable tab navigation
   - Maintenance - responsive card grid
   - Find Pros - responsive vendor cards
   - Money - scrollable tables

3. Common patterns to apply:
   - grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 for card grids
   - flex-col sm:flex-row for side-by-side content
   - overflow-x-auto for horizontal scrolling where needed
   - px-4 sm:px-6 lg:px-8 for container padding

4. Ensure no horizontal overflow on any page at 375px width (iPhone)

Run pnpm build, then test on mobile viewport.
```

# Haven Dashboard Cards - Consistency & Color Fix

## PROBLEM 1: Data Inconsistency

Home Health shows different values:
- **Dashboard:** 94%
- **Your Home page:** 84/100

These MUST be the same value pulled from the same data source.

## PROBLEM 2: Visual Design

The dashboard stat cards are bland. Need:
- **Home Health:** Semantic colors (red/yellow/green based on score)
- **Items Handled:** Champagne background, navy text
- **Next Service:** Champagne background, navy text

---

## FIX 1: Data Consistency

Both pages should pull from the same source:

```tsx
// Shared data source - could be API, context, or store
// Example: apps/web/src/lib/hooks/useHomeHealth.ts

export function useHomeHealth() {
  // This should be fetched from your API
  const homeHealth = {
    score: 94, // Single source of truth
    status: 'healthy', // 'critical' | 'warning' | 'healthy' | 'excellent'
    lastUpdated: new Date(),
  };
  
  return homeHealth;
}
```

Both Dashboard and Your Home page should use this same hook/data source.

---

## FIX 2: Home Health Semantic Colors

### Color Scale

| Score | Status | Background | Text | Border | Icon |
|-------|--------|------------|------|--------|------|
| 0-39 | Critical | `bg-red-50` | `text-red-700` | `border-red-200` | `text-red-500` |
| 40-59 | Warning | `bg-amber-50` | `text-amber-700` | `border-amber-200` | `text-amber-500` |
| 60-79 | Good | `bg-emerald-50` | `text-emerald-700` | `border-emerald-200` | `text-emerald-500` |
| 80-100 | Excellent | `bg-emerald-50` | `text-emerald-700` | `border-emerald-200` | `text-emerald-500` |

### Helper Function

```tsx
// apps/web/src/lib/utils/healthColors.ts

export function getHealthColors(score: number) {
  if (score >= 80) {
    return {
      bg: 'bg-emerald-50',
      text: 'text-emerald-700',
      border: 'border-emerald-200',
      icon: 'text-emerald-500',
      badge: 'bg-emerald-100 text-emerald-700',
      progress: 'bg-emerald-500',
      label: 'Excellent',
    };
  } else if (score >= 60) {
    return {
      bg: 'bg-emerald-50',
      text: 'text-emerald-700',
      border: 'border-emerald-200',
      icon: 'text-emerald-500',
      badge: 'bg-emerald-100 text-emerald-700',
      progress: 'bg-emerald-500',
      label: 'Good',
    };
  } else if (score >= 40) {
    return {
      bg: 'bg-amber-50',
      text: 'text-amber-700',
      border: 'border-amber-200',
      icon: 'text-amber-500',
      badge: 'bg-amber-100 text-amber-700',
      progress: 'bg-amber-500',
      label: 'Needs Attention',
    };
  } else {
    return {
      bg: 'bg-red-50',
      text: 'text-red-700',
      border: 'border-red-200',
      icon: 'text-red-500',
      badge: 'bg-red-100 text-red-700',
      progress: 'bg-red-500',
      label: 'Critical',
    };
  }
}
```

---

## FIX 3: Dashboard Stat Cards

### Dashboard Header Cards Layout

```tsx
import { getHealthColors } from '@/lib/utils/healthColors';
import { Heart, CheckCircle, Calendar } from 'lucide-react';

// Get health data (should be from shared source)
const homeHealth = 94; // Same value used everywhere
const healthColors = getHealthColors(homeHealth);

// Dashboard header stats
<div className="flex gap-4">
  
  {/* Home Health Card - Semantic Colors */}
  <div className={`flex items-center gap-3 px-4 py-3 rounded-xl border ${healthColors.bg} ${healthColors.border}`}>
    <div className={`w-10 h-10 rounded-full ${healthColors.bg} flex items-center justify-center`}>
      <Heart className={`w-5 h-5 ${healthColors.icon}`} />
    </div>
    <div>
      <p className="text-xs text-warm-500 uppercase tracking-wide">Home Health</p>
      <p className={`text-xl font-bold ${healthColors.text}`}>{homeHealth}%</p>
    </div>
    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${healthColors.badge}`}>
      {healthColors.label}
    </span>
  </div>

  {/* Items Handled Card - Champagne */}
  <div className="flex items-center gap-3 px-4 py-3 rounded-xl bg-champagne-100 border border-champagne-200">
    <div className="w-10 h-10 rounded-full bg-champagne-200 flex items-center justify-center">
      <CheckCircle className="w-5 h-5 text-champagne-600" />
    </div>
    <div>
      <p className="text-xs text-champagne-600 uppercase tracking-wide">Items Handled</p>
      <p className="text-xl font-bold text-haven-700">4</p>
    </div>
  </div>

  {/* Next Service Card - Champagne */}
  <div className="flex items-center gap-3 px-4 py-3 rounded-xl bg-champagne-100 border border-champagne-200">
    <div className="w-10 h-10 rounded-full bg-champagne-200 flex items-center justify-center">
      <Calendar className="w-5 h-5 text-champagne-600" />
    </div>
    <div>
      <p className="text-xs text-champagne-600 uppercase tracking-wide">Next Service</p>
      <p className="text-xl font-bold text-haven-700">Jan 7</p>
    </div>
  </div>

</div>
```

---

## FIX 4: Your Home Page Health Card

Use the same helper function for consistency:

```tsx
import { getHealthColors } from '@/lib/utils/healthColors';

const homeHealth = 94; // Same source as dashboard!
const healthColors = getHealthColors(homeHealth);

<div className={`rounded-2xl p-6 border ${healthColors.bg} ${healthColors.border}`}>
  <div className="flex items-center justify-between mb-4">
    <h2 className="font-semibold text-warm-900">Home Health</h2>
    <button className="text-sm text-haven-700 hover:text-haven-800">View Details</button>
  </div>
  
  {/* Circular Progress */}
  <div className="flex justify-center mb-6">
    <div className="relative w-32 h-32">
      <svg className="w-full h-full transform -rotate-90">
        {/* Background circle */}
        <circle
          cx="64"
          cy="64"
          r="56"
          stroke="#E7E5E4"
          strokeWidth="12"
          fill="none"
        />
        {/* Progress circle - color based on score */}
        <circle
          cx="64"
          cy="64"
          r="56"
          stroke={
            homeHealth >= 60 ? '#10B981' : // emerald-500
            homeHealth >= 40 ? '#F59E0B' : // amber-500
            '#EF4444' // red-500
          }
          strokeWidth="12"
          fill="none"
          strokeLinecap="round"
          strokeDasharray={`${(homeHealth / 100) * 352} 352`}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <span className={`text-4xl font-bold ${healthColors.text}`}>{homeHealth}</span>
        <span className="text-sm text-warm-500">/ 100</span>
      </div>
    </div>
  </div>

  {/* Status badge */}
  <div className="text-center">
    <span className={`inline-flex px-3 py-1 rounded-full text-sm font-medium ${healthColors.badge}`}>
      {healthColors.label}
    </span>
  </div>
</div>
```

---

## VISUAL SUMMARY

### Dashboard Header (Dark Background)

```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │ 💚 Home Health   │  │ ✨ Items Handled │  │ ✨ Next Svc  │ │
│  │    94%           │  │    4             │  │    Jan 7     │ │
│  │    [Excellent]   │  │                  │  │              │ │
│  │  emerald bg      │  │  champagne bg    │  │ champagne bg │ │
│  └──────────────────┘  └──────────────────┘  └──────────────┘ │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### Health Score Visual States

```
EXCELLENT (80-100):     GOOD (60-79):          WARNING (40-59):       CRITICAL (0-39):
┌────────────────┐      ┌────────────────┐      ┌────────────────┐     ┌────────────────┐
│  bg-emerald-50 │      │  bg-emerald-50 │      │  bg-amber-50   │     │  bg-red-50     │
│                │      │                │      │                │     │                │
│     94%        │      │     72%        │      │     51%        │     │     28%        │
│   Excellent    │      │     Good       │      │ Needs Attention│     │   Critical     │
│   💚 green     │      │   💚 green     │      │   🟡 amber     │     │   🔴 red       │
└────────────────┘      └────────────────┘      └────────────────┘     └────────────────┘
```

---

## FILES TO UPDATE

1. **Create helper:** `apps/web/src/lib/utils/healthColors.ts`
2. **Dashboard:** `apps/web/src/app/app/dashboard/page.tsx`
3. **Your Home:** `apps/web/src/app/app/your-home/page.tsx`
4. **Maintenance:** `apps/web/src/app/app/maintenance/page.tsx` (if it shows health)

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Fix Home Health consistency and dashboard card colors:

1. Create apps/web/src/lib/utils/healthColors.ts with getHealthColors(score) helper:
   - 80-100: emerald (Excellent)
   - 60-79: emerald (Good)
   - 40-59: amber (Needs Attention)
   - 0-39: red (Critical)

2. Fix data inconsistency - Home Health must show SAME value on:
   - Dashboard (currently shows 94%)
   - Your Home page (currently shows 84)
   Use the same data source for both.

3. Update Dashboard stat cards:
   - Home Health: Use getHealthColors() for semantic colors (green when good, red when bad)
   - Items Handled: bg-champagne-100, border-champagne-200, text-haven-700
   - Next Service: bg-champagne-100, border-champagne-200, text-haven-700

4. Update Your Home page health circle:
   - Use getHealthColors() for the progress ring color
   - Show status label badge below

5. Ensure the circular progress ring color matches:
   - emerald-500 for 60+
   - amber-500 for 40-59
   - red-500 for below 40

Run pnpm build to verify.
```

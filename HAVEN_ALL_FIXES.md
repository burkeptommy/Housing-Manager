# 🏠 HAVEN - COMPLETE FIX PROMPT (ALL ISSUES)

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this prompt OR run:
```bash
cat HAVEN_ALL_FIXES.md | claude --dangerously-skip-permissions
```

---

## ALL ISSUES TO FIX

### Critical Bugs
1. **Handyman portal crash** - `TypeError: undefined is not an object (evaluating 't.hoursLoggedToday.toFixed')`
2. **Contrast issues** - Black text on green/slate backgrounds is unreadable

### Design Issues
3. **Font inconsistency** - Serif/sans used randomly, need consistent hierarchy
4. **Vendor map card overflow** - Buttons/badges outside card container
5. **Same vendor photos** - All vendors show identical image
6. **Real photo avatars** - Switch to illustrated DiceBear avatars

### Missing Features
7. **Not enough vendors** - Add 25+ for better demo
8. **Family page incomplete** - Missing Alice, Emma, Jack, Max
9. **Project planning broken** - Kitchen backsplash just shows photo
10. **Handyman portal incomplete** - Need households, systems, after-action reports

---

## PHASE 1: FIX CRITICAL BUGS

### 1.1 Fix Handyman Dashboard (Null Safety + Demo Data)

**File:** `apps/web/src/app/handyman/page.tsx`

The dashboard crashes because it tries to call `.toFixed()` on undefined. Add null safety with demo data fallback:

```typescript
'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import {
  Clock, MapPin, CheckCircle2, Calendar, ChevronRight, Wrench, Home,
  Timer, ClipboardList, Settings
} from 'lucide-react';

interface WorkOrder {
  id: string;
  title: string;
  status: string;
  scheduledTime?: string;
  estimatedDuration?: number;
  household?: { id: string; name: string; };
}

interface Stats {
  tasksToday: number;
  tasksCompleted: number;
  hoursLoggedToday: number;
  tasksThisWeek: number;
  avgCompletionTime: number;
}

// Demo data fallback
const demoStats: Stats = {
  tasksToday: 4,
  tasksCompleted: 2,
  hoursLoggedToday: 3.5,
  tasksThisWeek: 18,
  avgCompletionTime: 45,
};

const demoTasks: WorkOrder[] = [
  { id: 'wo-1', title: 'Replace Smoke Detector Batteries', status: 'SCHEDULED', scheduledTime: '9:00 AM', estimatedDuration: 30, household: { id: 'h1', name: 'Smith Residence' } },
  { id: 'wo-2', title: 'Fix Squeaky Door Hinge', status: 'SCHEDULED', scheduledTime: '10:30 AM', estimatedDuration: 20, household: { id: 'h1', name: 'Smith Residence' } },
  { id: 'wo-3', title: 'Install Smart Thermostat', status: 'SCHEDULED', scheduledTime: '2:00 PM', estimatedDuration: 60, household: { id: 'h2', name: 'Johnson Home' } },
  { id: 'wo-4', title: 'Repair Cabinet Handles', status: 'IN_PROGRESS', scheduledTime: '11:30 AM', estimatedDuration: 45, household: { id: 'h1', name: 'Smith Residence' } },
];

function getGreeting(): string {
  const hour = new Date().getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

function getUserAvatar(name: string): string {
  const seed = encodeURIComponent(name.toLowerCase());
  return `https://api.dicebear.com/7.x/lorelei/svg?seed=${seed}&backgroundColor=b6e3f4,c0aede,d1d4f9`;
}

export default function HandymanDashboard() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [tasks, setTasks] = useState<WorkOrder[]>([]);
  const [stats, setStats] = useState<Stats>(demoStats);
  const [activeTask, setActiveTask] = useState<WorkOrder | null>(null);

  useEffect(() => {
    loadDashboard();
  }, []);

  async function loadDashboard() {
    try {
      setLoading(true);
      // Try API, fallback to demo data
      try {
        const res = await fetch('/api/handyman/dashboard');
        if (res.ok) {
          const data = await res.json();
          setTasks(data.todaysTasks || demoTasks);
          setStats({
            tasksToday: data.stats?.tasksToday ?? demoStats.tasksToday,
            tasksCompleted: data.stats?.tasksCompleted ?? demoStats.tasksCompleted,
            hoursLoggedToday: data.stats?.hoursLoggedToday ?? demoStats.hoursLoggedToday,
            tasksThisWeek: data.stats?.tasksThisWeek ?? demoStats.tasksThisWeek,
            avgCompletionTime: data.stats?.avgCompletionTime ?? demoStats.avgCompletionTime,
          });
          setActiveTask(data.activeTask || null);
          return;
        }
      } catch (e) {
        console.log('API unavailable, using demo data');
      }
      // Use demo data
      setTasks(demoTasks);
      setStats(demoStats);
      setActiveTask(demoTasks.find(t => t.status === 'IN_PROGRESS') || null);
    } finally {
      setLoading(false);
    }
  }

  const userName = user?.displayName || 'Mike';

  if (loading) {
    return (
      <div className="min-h-screen bg-warm-50 flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-haven-500 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-warm-50">
      {/* Header - WHITE text on dark background */}
      <header className="bg-gradient-to-br from-forest-900 to-forest-950 px-4 pt-6 pb-20">
        <div className="flex items-center justify-between mb-6">
          <div>
            <p className="text-white/60 text-sm">{getGreeting()}</p>
            <h1 className="text-2xl font-bold text-white">{userName}</h1>
          </div>
          <img src={getUserAvatar(userName)} alt="" className="w-12 h-12 rounded-full ring-2 ring-white/20" />
        </div>
        
        {/* Stats - WHITE text */}
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
            <div className="text-2xl font-bold text-white">{stats.tasksToday}</div>
            <div className="text-xs text-white/60">Today's Tasks</div>
          </div>
          <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
            <div className="text-2xl font-bold text-white">{stats.tasksCompleted}</div>
            <div className="text-xs text-white/60">Completed</div>
          </div>
          <div className="bg-white/10 backdrop-blur rounded-xl p-3 text-center">
            <div className="text-2xl font-bold text-white">{(stats.hoursLoggedToday ?? 0).toFixed(1)}h</div>
            <div className="text-xs text-white/60">Hours</div>
          </div>
        </div>
      </header>

      {/* Content */}
      <main className="px-4 -mt-12 pb-24 space-y-4">
        {/* Active Task */}
        {activeTask && (
          <div className="bg-gradient-to-r from-haven-500 to-haven-600 p-4 rounded-2xl">
            <div className="flex items-center gap-2 mb-2">
              <Timer className="w-4 h-4 text-white" />
              <span className="text-sm font-medium text-white">In Progress</span>
            </div>
            <h3 className="font-semibold text-lg text-white">{activeTask.title}</h3>
            <p className="text-white/80 text-sm mt-1">{activeTask.household?.name}</p>
            <div className="flex items-center justify-between mt-4">
              <span className="text-sm text-white/80">Started 45 min ago</span>
              <Link href={`/handyman/jobs/${activeTask.id}`} className="px-4 py-2 bg-white text-haven-700 rounded-lg text-sm font-medium">
                Continue
              </Link>
            </div>
          </div>
        )}

        {/* Today's Tasks */}
        <div className="bg-white p-4 rounded-2xl border border-warm-100">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-warm-900">Today's Schedule</h2>
            <Link href="/handyman/schedule" className="text-sm text-haven-600">View All</Link>
          </div>
          
          {tasks.length === 0 ? (
            <div className="text-center py-8">
              <CheckCircle2 className="w-12 h-12 text-haven-500 mx-auto mb-2" />
              <p className="text-warm-600">All caught up!</p>
            </div>
          ) : (
            <div className="space-y-3">
              {tasks.filter(t => t.status !== 'IN_PROGRESS').slice(0, 4).map(task => (
                <Link key={task.id} href={`/handyman/jobs/${task.id}`} className="flex items-center gap-4 p-3 rounded-xl hover:bg-warm-50">
                  <div className="w-12 h-12 rounded-xl bg-warm-100 flex items-center justify-center">
                    <Wrench className="w-6 h-6 text-warm-600" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="font-medium text-warm-900 truncate">{task.title}</h3>
                    <div className="flex items-center gap-2 text-sm text-warm-500">
                      <MapPin className="w-3 h-3" />
                      <span>{task.household?.name}</span>
                    </div>
                    {task.scheduledTime && (
                      <div className="flex items-center gap-1 text-sm text-warm-500 mt-1">
                        <Clock className="w-3 h-3" />
                        <span>{task.scheduledTime}</span>
                      </div>
                    )}
                  </div>
                  <ChevronRight className="w-5 h-5 text-warm-400" />
                </Link>
              ))}
            </div>
          )}
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-2 gap-3">
          <Link href="/handyman/schedule" className="bg-white p-4 rounded-xl border border-warm-100 text-center hover:shadow-md transition-shadow">
            <Calendar className="w-8 h-8 text-haven-600 mx-auto mb-2" />
            <span className="text-sm font-medium text-warm-900">Schedule</span>
          </Link>
          <Link href="/handyman/households" className="bg-white p-4 rounded-xl border border-warm-100 text-center hover:shadow-md transition-shadow">
            <Home className="w-8 h-8 text-blue-600 mx-auto mb-2" />
            <span className="text-sm font-medium text-warm-900">Households</span>
          </Link>
          <Link href="/handyman/reports" className="bg-white p-4 rounded-xl border border-warm-100 text-center hover:shadow-md transition-shadow">
            <ClipboardList className="w-8 h-8 text-purple-600 mx-auto mb-2" />
            <span className="text-sm font-medium text-warm-900">Reports</span>
          </Link>
          <Link href="/handyman/settings" className="bg-white p-4 rounded-xl border border-warm-100 text-center hover:shadow-md transition-shadow">
            <Settings className="w-8 h-8 text-warm-600 mx-auto mb-2" />
            <span className="text-sm font-medium text-warm-900">Settings</span>
          </Link>
        </div>
      </main>

      {/* Bottom Nav */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-warm-200 px-6 py-3">
        <div className="flex items-center justify-around">
          <Link href="/handyman" className="flex flex-col items-center text-haven-600">
            <Home className="w-6 h-6" />
            <span className="text-xs mt-1">Home</span>
          </Link>
          <Link href="/handyman/schedule" className="flex flex-col items-center text-warm-400">
            <Calendar className="w-6 h-6" />
            <span className="text-xs mt-1">Schedule</span>
          </Link>
          <Link href="/handyman/households" className="flex flex-col items-center text-warm-400">
            <Home className="w-6 h-6" />
            <span className="text-xs mt-1">Homes</span>
          </Link>
        </div>
      </nav>
    </div>
  );
}
```

### 1.2 Fix All Contrast Issues

Search ALL files in `apps/web/src/app/` for dark backgrounds with dark text. 

**Rule: Dark background = White text. Always.**

Find and replace these patterns:

```typescript
// ❌ WRONG - unreadable
<div className="bg-haven-500 ...">
  <h2 className="text-warm-900">...</h2>  // Dark text on green = BAD
</div>

// ✅ CORRECT - readable  
<div className="bg-haven-500 ...">
  <h2 className="text-white">...</h2>  // White text on green = GOOD
</div>
```

**Files to check:**
- `apps/web/src/app/app/page.tsx` - "Good morning, Bob" greeting
- `apps/web/src/app/app/bills/page.tsx` - Money amounts
- `apps/web/src/app/manager/page.tsx` - Dashboard
- `apps/web/src/app/manager/payables/page.tsx` - Amounts
- Any file with `bg-haven-`, `bg-forest-`, `bg-warm-800`, `bg-warm-900`

---

## PHASE 2: FIX TYPOGRAPHY

### 2.1 Update Global CSS

**File:** `apps/web/src/app/globals.css`

Establish clear font hierarchy:
- **Playfair Display (serif)**: ONLY h1 page titles
- **Inter (sans-serif)**: Everything else

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Playfair+Display:wght@500;600;700&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  body {
    @apply font-sans text-warm-800 bg-warm-50;
  }
  
  /* ONLY h1 gets serif */
  h1 {
    @apply font-serif;
  }
  
  /* All other headings use sans */
  h2, h3, h4, h5, h6 {
    @apply font-sans font-semibold;
  }
}

@layer components {
  /* Page title class */
  .page-title {
    @apply font-serif text-2xl sm:text-3xl font-bold text-warm-900;
  }
  
  /* Card title - always sans */
  .card-title {
    @apply font-sans font-semibold text-warm-900;
  }
  
  /* Dark card styles - WHITE TEXT */
  .card-green {
    @apply bg-gradient-to-br from-haven-500 to-haven-600 rounded-2xl;
  }
  .card-green, .card-green h1, .card-green h2, .card-green h3, .card-green p {
    @apply text-white;
  }
  
  .card-slate {
    @apply bg-gradient-to-br from-warm-800 to-warm-900 rounded-2xl;
  }
  .card-slate, .card-slate h1, .card-slate h2, .card-slate h3, .card-slate p {
    @apply text-white;
  }
  
  .card-forest {
    @apply bg-gradient-to-br from-forest-800 to-forest-900 rounded-2xl;
  }
  .card-forest, .card-forest h1, .card-forest h2, .card-forest h3, .card-forest p {
    @apply text-white;
  }
}
```

### 2.2 Remove Random `font-serif` Usage

Search for `font-serif` in all files. Remove it from anything that's NOT an h1 page title.

---

## PHASE 3: FIX AVATARS

### 3.1 Create Avatar Helper

**Create file:** `apps/web/src/lib/avatars.ts`

```typescript
// DiceBear illustrated avatars
export function getUserAvatar(name: string, size: number = 128): string {
  const seed = encodeURIComponent(name.toLowerCase().trim());
  return `https://api.dicebear.com/7.x/lorelei/svg?seed=${seed}&size=${size}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf`;
}

export function getInitials(name: string): string {
  return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
}
```

### 3.2 Replace Unsplash Avatars

Search for `images.unsplash.com/photo-149` (avatar photos) and replace with `getUserAvatar(name)`.

---

## PHASE 4: FIX VENDORS

### 4.1 Add Vendor Images

**Update file:** `apps/web/src/lib/images.ts`

```typescript
export const vendorImages: Record<string, string[]> = {
  plumbing: ['https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400', 'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=400'],
  electrical: ['https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400', 'https://images.unsplash.com/photo-1555963966-b7ae5404b6ed?w=400'],
  hvac: ['https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400'],
  landscaping: ['https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400', 'https://images.unsplash.com/photo-1592420315809-54c6e9c07b07?w=400'],
  roofing: ['https://images.unsplash.com/photo-1632759145351-1d592919f522?w=400'],
  cleaning: ['https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400'],
  painting: ['https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400'],
  pool: ['https://images.unsplash.com/photo-1575429198097-0414ec08e8cd?w=400'],
  general: ['https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400'],
};

export function getVendorImage(category: string, index: number = 0): string {
  const cat = category.toLowerCase().replace(/[^a-z]/g, '');
  const imgs = vendorImages[cat] || vendorImages.general;
  return imgs[index % imgs.length];
}
```

### 4.2 Fix Vendor Map Card

**File:** `apps/web/src/app/app/community/page.tsx`

Ensure popup card has `overflow-hidden` and all elements (close button, verified badge, call button) are INSIDE the card container.

### 4.3 Add More Vendors to Seed

**File:** `apps/api/prisma/seed.ts`

Add 25+ vendors with varied categories, ratings, and locations.

---

## PHASE 5: FIX FAMILY PAGE

### 5.1 Add Family Members to Seed

**File:** `apps/api/prisma/seed.ts`

```typescript
// Add after household creation
const familyMembers = [
  { id: 'bob', firstName: 'Bob', lastName: 'Smith', relationship: 'HEAD_OF_HOUSEHOLD', email: 'bob@example.com', phone: '(203) 555-0001' },
  { id: 'alice', firstName: 'Alice', lastName: 'Smith', relationship: 'SPOUSE', email: 'alice.smith@example.com', phone: '(203) 555-0002' },
  { id: 'emma', firstName: 'Emma', lastName: 'Smith', relationship: 'CHILD', notes: 'Age 14. PADI certified. Shellfish allergy.' },
  { id: 'jack', firstName: 'Jack', lastName: 'Smith', relationship: 'CHILD', notes: 'Age 10. Soccer. Nut allergy (EpiPen).' },
  { id: 'max', firstName: 'Max', relationship: 'PET', notes: 'Golden Retriever. Vet: Greenwich Animal Hospital.' },
];

for (const m of familyMembers) {
  await prisma.householdMember.upsert({
    where: { id: `member-${m.id}` },
    update: {},
    create: { id: `member-${m.id}`, householdId: demoHousehold.id, ...m },
  });
}
```

---

## PHASE 6: BUILD HANDYMAN PORTAL

### 6.1 Households Page

**Create:** `apps/web/src/app/handyman/households/page.tsx`

List all assigned households with system status overview.

### 6.2 Household Detail Page

**Create:** `apps/web/src/app/handyman/households/[id]/page.tsx`

Full household info with:
- Property image and address
- Contact info (homeowner, manager)
- Access notes
- Systems list with status
- Service history
- Quick actions (call, navigate, report)

### 6.3 System Detail Page

**Create:** `apps/web/src/app/handyman/systems/[id]/page.tsx`

Equipment tracking:
- Specs (brand, model, serial, installed date, warranty)
- Service history
- Photos
- Documents (manuals, warranties)
- Maintenance notes
- Next service schedule

### 6.4 After Action Report Page

**Create:** `apps/web/src/app/handyman/households/[id]/report/page.tsx`

Send visit reports to homeowners:
- Visit summary
- Time on site
- Work completed items
- Observations (things noticed)
- Recommendations (suggested work)
- Photo attachments
- Urgent flag option

---

## PHASE 7: BUILD PROJECT PLANNING

### 7.1 Projects List Page

**Create:** `apps/web/src/app/app/projects/page.tsx`

### 7.2 Project Detail Page

**Create:** `apps/web/src/app/app/projects/[id]/page.tsx`

Full project workflow:
- Progress bar and phase timeline
- Checklist items per phase
- Vendor quotes comparison
- Inspiration board
- Message thread
- Budget tracking

---

## VERIFICATION CHECKLIST

After running this prompt:

- [ ] Handyman portal loads without crash
- [ ] All dark backgrounds have white text
- [ ] Only h1 page titles use serif font
- [ ] Avatars are illustrated (DiceBear), not photos
- [ ] Each vendor has unique image
- [ ] Vendor map card is properly contained
- [ ] 25+ vendors in demo data
- [ ] Family shows Bob, Alice, Emma, Jack, Max
- [ ] Handyman can view households and systems
- [ ] Handyman can send after-action reports
- [ ] Projects have full workflow view

---

## AFTER BUILD

```bash
# Reset database with new seed data
cd apps/api
pnpm prisma db push --force-reset
pnpm prisma db seed
pnpm dev

# Start frontend
cd apps/web
pnpm dev
```

Test all portals:
- http://localhost:3000/app (bob@example.com / Bob123!)
- http://localhost:3000/manager (sarah@haven.app / Manager123!)
- http://localhost:3000/handyman (mike@haven.app / Handy123!)
- http://localhost:3000/vendor (vendor@aceroofing.example.com / AceRoof123!)

🏠✨

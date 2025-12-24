# Haven Vehicles & Financial Tab Fixes

## PROBLEMS

1. **Vehicles tab** - Only Tesla has an image, other vehicles show nothing
2. **Data inconsistency** - 3 vehicles on Vehicles tab, but only 2 on Family tab
3. **Financial tab** - "Property Value" text is black on dark background (unreadable)

---

## FIX 1: VEHICLE ILLUSTRATIONS

Create simple, elegant vehicle illustrations using icons/SVGs. No photos needed.

### Vehicle Types & Icons

| Vehicle Type | Icon | Color |
|--------------|------|-------|
| Tesla / Electric | Zap + Car | Emerald |
| SUV / Crossover | Car | Sky |
| Sedan | Car | Navy |
| Truck | Truck | Orange |
| Sports Car | Car | Rose |
| Minivan | Car | Violet |
| Motorcycle | Bike | Amber |

### Vehicle Avatar Component

**File:** `apps/web/src/components/ui/VehicleAvatar.tsx`

```tsx
'use client';

import { Car, Zap, Truck, Bike } from 'lucide-react';

const vehicleStyles = {
  tesla: { bg: 'bg-emerald-100', icon: 'text-emerald-600', accent: 'bg-emerald-500' },
  electric: { bg: 'bg-emerald-100', icon: 'text-emerald-600', accent: 'bg-emerald-500' },
  suv: { bg: 'bg-sky-100', icon: 'text-sky-600', accent: 'bg-sky-500' },
  sedan: { bg: 'bg-haven-100', icon: 'text-haven-600', accent: 'bg-haven-500' },
  truck: { bg: 'bg-orange-100', icon: 'text-orange-600', accent: 'bg-orange-500' },
  sports: { bg: 'bg-rose-100', icon: 'text-rose-600', accent: 'bg-rose-500' },
  minivan: { bg: 'bg-violet-100', icon: 'text-violet-600', accent: 'bg-violet-500' },
  motorcycle: { bg: 'bg-amber-100', icon: 'text-amber-600', accent: 'bg-amber-500' },
  default: { bg: 'bg-warm-100', icon: 'text-warm-600', accent: 'bg-warm-500' },
};

type VehicleType = keyof typeof vehicleStyles;

interface VehicleAvatarProps {
  type?: VehicleType;
  make?: string; // e.g., "Tesla", "BMW", "Toyota"
  isElectric?: boolean;
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

const sizes = {
  sm: { container: 'w-12 h-12', icon: 'w-6 h-6', badge: 'w-4 h-4' },
  md: { container: 'w-16 h-16', icon: 'w-8 h-8', badge: 'w-5 h-5' },
  lg: { container: 'w-24 h-24', icon: 'w-12 h-12', badge: 'w-6 h-6' },
  xl: { container: 'w-32 h-32', icon: 'w-16 h-16', badge: 'w-8 h-8' },
};

function getVehicleType(make?: string, type?: VehicleType, isElectric?: boolean): VehicleType {
  if (type) return type;
  
  const makeLower = make?.toLowerCase() || '';
  
  if (makeLower.includes('tesla') || isElectric) return 'electric';
  if (makeLower.includes('model s') || makeLower.includes('model 3') || makeLower.includes('model x') || makeLower.includes('model y')) return 'electric';
  if (makeLower.includes('x5') || makeLower.includes('suv') || makeLower.includes('highlander') || makeLower.includes('pilot') || makeLower.includes('explorer')) return 'suv';
  if (makeLower.includes('truck') || makeLower.includes('f-150') || makeLower.includes('silverado')) return 'truck';
  if (makeLower.includes('porsche') || makeLower.includes('corvette') || makeLower.includes('mustang')) return 'sports';
  if (makeLower.includes('odyssey') || makeLower.includes('sienna') || makeLower.includes('pacifica')) return 'minivan';
  
  return 'sedan';
}

export function VehicleAvatar({ type, make, isElectric, size = 'md', className = '' }: VehicleAvatarProps) {
  const vehicleType = getVehicleType(make, type, isElectric);
  const style = vehicleStyles[vehicleType] || vehicleStyles.default;
  const s = sizes[size];
  
  const Icon = vehicleType === 'truck' ? Truck : 
               vehicleType === 'motorcycle' ? Bike : 
               Car;
  
  const showElectricBadge = vehicleType === 'electric' || isElectric;
  
  return (
    <div className={`relative ${className}`}>
      {/* Main container */}
      <div className={`${s.container} ${style.bg} rounded-2xl flex items-center justify-center`}>
        <Icon className={`${s.icon} ${style.icon}`} />
      </div>
      
      {/* Electric badge */}
      {showElectricBadge && (
        <div className={`absolute -top-1 -right-1 ${s.badge} bg-emerald-500 rounded-full flex items-center justify-center ring-2 ring-white`}>
          <Zap className="w-3 h-3 text-white fill-current" />
        </div>
      )}
    </div>
  );
}

export default VehicleAvatar;
```

### Usage in Vehicles Tab

```tsx
import { VehicleAvatar } from '@/components/ui/VehicleAvatar';

// Vehicles list
{vehicles.map(vehicle => (
  <div key={vehicle.id} className="bg-white rounded-xl border border-warm-200 p-4 flex items-center gap-4">
    <VehicleAvatar 
      make={vehicle.make} 
      isElectric={vehicle.isElectric}
      size="lg" 
    />
    <div className="flex-1">
      <h3 className="font-semibold text-warm-900">{vehicle.year} {vehicle.make} {vehicle.model}</h3>
      <p className="text-sm text-warm-500">{vehicle.type}</p>
    </div>
    <div className="text-right">
      <p className="text-sm text-warm-500">Next Service</p>
      <p className="font-medium">{vehicle.nextService}</p>
    </div>
  </div>
))}
```

---

## FIX 2: VEHICLE DATA CONSISTENCY

The same vehicle data should appear on both the Vehicles tab and Family tab.

### Single Source of Truth

Create a shared data file or hook:

**File:** `apps/web/src/lib/data/vehicles.ts`

```tsx
export interface Vehicle {
  id: string;
  year: number;
  make: string;
  model: string;
  type: 'sedan' | 'suv' | 'truck' | 'sports' | 'minivan' | 'motorcycle';
  isElectric: boolean;
  licensePlate?: string;
  vin?: string;
  color?: string;
  assignedTo?: string; // Family member name
  nextService?: string;
  lastService?: string;
  mileage?: number;
}

// This should come from your API/database
export const vehicles: Vehicle[] = [
  {
    id: '1',
    year: 2023,
    make: 'Tesla',
    model: 'Model S Long Range',
    type: 'sedan',
    isElectric: true,
    assignedTo: 'Bob Thompson',
    nextService: 'June 2025',
    mileage: 12500,
  },
  {
    id: '2',
    year: 2022,
    make: 'BMW',
    model: 'X5 xDrive40i',
    type: 'suv',
    isElectric: false,
    assignedTo: 'Alice Thompson',
    nextService: 'March 2025',
    mileage: 28000,
  },
  // If there's a third vehicle, add it here
  // OR remove it from the Vehicles tab if it shouldn't exist
];
```

### Update Both Pages

**Vehicles Tab:** `apps/web/src/app/app/your-home/vehicles/page.tsx`
**Family Tab:** `apps/web/src/app/app/family/page.tsx`

Both should import from the same source:

```tsx
import { vehicles } from '@/lib/data/vehicles';
// OR use a hook
import { useVehicles } from '@/lib/hooks/useVehicles';
```

### Verify Count

Check current data:
- If Vehicles tab shows 3 but Family shows 2, either:
  - Add the missing vehicle to Family tab
  - OR remove the extra vehicle from Vehicles tab
  - The data should be IDENTICAL

---

## FIX 3: FINANCIAL TAB TEXT CONTRAST

"Property Value" text is black on dark background - needs to be white.

### File: `apps/web/src/app/app/your-home/financial/page.tsx` (or similar)

Search for the Property Value section and fix text colors:

```tsx
// WRONG - Black text on dark background
<div className="bg-haven-900 ...">
  <p className="text-warm-900">Property Value</p>  {/* UNREADABLE */}
</div>

// CORRECT - White text on dark background
<div className="bg-haven-900 ...">
  <p className="text-white">Property Value</p>
  <p className="text-2xl font-bold text-white">$1,250,000</p>
  <p className="text-warm-300">Last updated: Dec 2024</p>
</div>
```

### Full Section Fix

```tsx
{/* Property Value Card - Dark Background */}
<div className="bg-gradient-to-br from-haven-800 to-haven-900 rounded-2xl p-6 text-white">
  <div className="flex items-center justify-between mb-4">
    <div className="flex items-center gap-3">
      <div className="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center">
        <Home className="w-5 h-5 text-white" />
      </div>
      <div>
        <p className="text-sm text-haven-200">Property Value</p>
        <p className="text-2xl font-bold text-white">$1,250,000</p>
      </div>
    </div>
    <div className="text-right">
      <p className="text-sm text-haven-300">Zestimate</p>
      <p className="text-xs text-haven-400">Updated Dec 2024</p>
    </div>
  </div>
  
  {/* Optional: Value trend */}
  <div className="flex items-center gap-2 pt-4 border-t border-white/10">
    <TrendingUp className="w-4 h-4 text-emerald-400" />
    <span className="text-sm text-emerald-400">+5.2%</span>
    <span className="text-sm text-haven-300">vs last year</span>
  </div>
</div>
```

### Text Color Rules for Dark Backgrounds

| Element | Class |
|---------|-------|
| Primary text | `text-white` |
| Secondary text | `text-haven-200` or `text-warm-300` |
| Tertiary/muted | `text-haven-300` or `text-warm-400` |
| Labels | `text-haven-200` |
| Values | `text-white font-bold` |
| Positive trend | `text-emerald-400` |
| Negative trend | `text-red-400` |

---

## VERIFICATION CHECKLIST

After fixes:

- [ ] **Vehicles Tab**
  - [ ] All vehicles show illustrated avatars (not just Tesla)
  - [ ] Tesla shows car icon with ⚡ electric badge
  - [ ] BMW/SUV shows car icon in sky blue
  - [ ] All vehicle types have appropriate icons

- [ ] **Data Consistency**
  - [ ] Same number of vehicles on Vehicles tab and Family tab
  - [ ] Same vehicle details (make, model, year) on both pages
  - [ ] Vehicles use same data source

- [ ] **Financial Tab**
  - [ ] "Property Value" text is WHITE, not black
  - [ ] All text on dark sections is readable
  - [ ] Values are clearly visible

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Fix vehicles and financial tab issues - read HAVEN_VEHICLES_FIX.md:

1. Create VehicleAvatar component (apps/web/src/components/ui/VehicleAvatar.tsx):
   - Car icon with colored backgrounds based on vehicle type
   - Tesla/Electric: Emerald green with ⚡ badge
   - SUV: Sky blue
   - Sedan: Navy
   - Truck: Orange
   - Support detecting type from make name

2. Update Vehicles tab to use VehicleAvatar for ALL vehicles (not just Tesla)

3. Fix vehicle data consistency:
   - Count vehicles on Vehicles tab vs Family tab
   - Make them use the same data source
   - Should show same vehicles on both pages

4. Fix Financial tab text contrast:
   - Find "Property Value" section
   - Change black text to white on dark backgrounds
   - All text on dark sections must be text-white or text-haven-200

Run pnpm build to verify.
```

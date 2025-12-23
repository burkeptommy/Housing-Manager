# Haven Consolidated Fix - Mobile, Avatars, Family Page, Vendor Popup

## Issues to Fix:
1. **Mobile comparison table** - "Setup/Onboarding" text overflows column on mobile
2. **Avatar consistency** - Use initials in colored circles everywhere (like Family page)
3. **Alice Morrison missing** - Bob's wife not showing under Adults on Family page
4. **Vendor popup overflow** - Previous fix didn't deploy, buttons still overflow card

---

## FIX 1: COMPARISON TABLE - MOBILE STACKED CARDS

**File:** `apps/web/src/app/(marketing)/page.tsx`

Find the comparison table section (search for "Household Software" or the table with pricing comparison). Replace the entire table with this responsive version that shows STACKED CARDS on mobile:

```tsx
{/* Comparison Section */}
<section className="py-16 sm:py-24 bg-warm-50">
  <div className="max-w-6xl mx-auto px-4 sm:px-6">
    <h2 className="text-2xl sm:text-3xl font-bold text-center text-warm-900 mb-8 sm:mb-12">
      Haven vs. Traditional Household Software
    </h2>
    
    {/* Mobile: Stacked Cards (shown on screens smaller than lg) */}
    <div className="lg:hidden space-y-3">
      {[
        { feature: 'Monthly Cost', them: '$375/month', us: '$349/month' },
        { feature: 'Setup Fee', them: '$3K - $5K', us: '$0' },
        { feature: 'First Year Total', them: '$7,500+', us: '$4,188' },
        { feature: 'Contract', them: '12-mo prepaid', us: 'Month-to-month' },
        { feature: 'Bills Paid For You', them: 'No', us: 'Yes, one payment', usBetter: true },
        { feature: 'Vendor Coordination', them: 'No', us: 'Yes, we handle it', usBetter: true },
        { feature: 'Handyman Visits', them: 'No', us: 'Yes, monthly', usBetter: true },
        { feature: 'Home Manager', them: 'No', us: 'Yes, dedicated', usBetter: true },
      ].map((row, idx) => (
        <div key={idx} className="bg-white rounded-xl border border-warm-200 overflow-hidden">
          <div className="bg-warm-100 px-4 py-2">
            <span className="font-medium text-warm-700 text-sm">{row.feature}</span>
          </div>
          <div className="grid grid-cols-2">
            <div className="p-3 border-r border-warm-100">
              <div className="text-xs text-warm-400 mb-1">Others</div>
              <div className="text-sm text-warm-500">
                {row.usBetter && <span className="text-red-500 mr-1">✗</span>}
                {row.them}
              </div>
            </div>
            <div className="p-3 bg-haven-50/50">
              <div className="text-xs text-haven-600 mb-1">Haven</div>
              <div className="text-sm font-medium text-haven-700">
                {row.usBetter && <span className="text-green-500 mr-1">✓</span>}
                {row.us}
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>

    {/* Desktop: Traditional Table (shown on lg screens and up) */}
    <div className="hidden lg:block">
      <div className="bg-white rounded-2xl shadow-sm border border-warm-200 overflow-hidden">
        <table className="w-full">
          <thead>
            <tr className="bg-warm-50 border-b border-warm-200">
              <th className="text-left p-4 sm:p-6 font-semibold text-warm-600 text-sm uppercase tracking-wide w-1/3">
                Feature
              </th>
              <th className="text-left p-4 sm:p-6 font-semibold text-warm-500 w-1/3">
                <div>Household Software</div>
                <div className="text-xs font-normal text-warm-400 mt-1">$375/mo + $3K setup</div>
              </th>
              <th className="text-left p-4 sm:p-6 font-semibold text-haven-700 w-1/3 bg-haven-50">
                <div className="flex items-center gap-2">
                  <Home className="w-5 h-5" />
                  Haven
                </div>
                <div className="text-xs font-normal text-haven-600 mt-1">$349/mo, no setup</div>
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-warm-100">
            {[
              { feature: 'Monthly Cost', them: '$375/month', us: '$349/month' },
              { feature: 'Setup/Onboarding', them: '$3,000 - $5,000', us: '$0' },
              { feature: 'First Year Total', them: '$7,500+', us: '$4,188' },
              { feature: 'Contract Required', them: '12-month prepaid', us: 'Month-to-month' },
              { feature: 'Bills Paid For You', them: 'No (you pay each vendor)', us: 'Yes, one payment covers all', usBetter: true },
              { feature: 'Vendor Coordination', them: 'No (just a contact list)', us: 'Yes, we call, schedule, oversee', usBetter: true },
              { feature: 'Handyman Visits', them: 'No', us: 'Yes, monthly preventive visits', usBetter: true },
              { feature: 'Home Manager', them: 'No', us: 'Yes, dedicated professional', usBetter: true },
            ].map((row, idx) => (
              <tr key={idx}>
                <td className="p-4 sm:p-6 font-medium text-warm-800">{row.feature}</td>
                <td className="p-4 sm:p-6 text-warm-600">
                  {row.usBetter && <span className="text-red-500 mr-2">✗</span>}
                  {row.them}
                </td>
                <td className="p-4 sm:p-6 bg-haven-50/50 text-haven-700 font-medium">
                  {row.usBetter && <span className="text-green-500 mr-2">✓</span>}
                  {row.us}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  </div>
</section>
```

---

## FIX 2: CONSISTENT AVATAR COMPONENT

**Create new file:** `apps/web/src/components/ui/avatar.tsx`

This creates a reusable InitialsAvatar component matching the Family page style:

```tsx
import { cn } from '@/lib/utils';

interface InitialsAvatarProps {
  name: string;
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  variant?: 'emerald' | 'blue' | 'purple' | 'amber' | 'rose' | 'haven' | 'warm';
  className?: string;
}

const sizeClasses = {
  xs: 'w-6 h-6 text-xs',
  sm: 'w-8 h-8 text-xs',
  md: 'w-10 h-10 text-sm',
  lg: 'w-12 h-12 text-base',
  xl: 'w-14 h-14 text-lg',
};

const variantClasses = {
  emerald: 'bg-emerald-100 text-emerald-600',
  blue: 'bg-blue-100 text-blue-600',
  purple: 'bg-purple-100 text-purple-600',
  amber: 'bg-amber-100 text-amber-600',
  rose: 'bg-rose-100 text-rose-600',
  haven: 'bg-haven-100 text-haven-600',
  warm: 'bg-warm-100 text-warm-600',
};

function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

// Deterministic color based on name
function getVariantFromName(name: string): InitialsAvatarProps['variant'] {
  const variants: InitialsAvatarProps['variant'][] = ['emerald', 'blue', 'purple', 'amber', 'rose', 'haven'];
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return variants[Math.abs(hash) % variants.length];
}

export function InitialsAvatar({ 
  name, 
  size = 'md', 
  variant,
  className 
}: InitialsAvatarProps) {
  const initials = getInitials(name);
  const colorVariant = variant || getVariantFromName(name);
  
  return (
    <div 
      className={cn(
        'rounded-full flex items-center justify-center font-semibold flex-shrink-0',
        sizeClasses[size],
        variantClasses[colorVariant],
        className
      )}
    >
      {initials}
    </div>
  );
}

// For vendors - use a slightly different style with rounded corners
export function VendorAvatar({ 
  name, 
  size = 'md',
  className 
}: Omit<InitialsAvatarProps, 'variant'>) {
  const initials = getInitials(name);
  
  return (
    <div 
      className={cn(
        'rounded-xl flex items-center justify-center font-semibold flex-shrink-0 bg-warm-100 text-warm-600',
        sizeClasses[size],
        className
      )}
    >
      {initials}
    </div>
  );
}

export default InitialsAvatar;
```

---

## FIX 3: UPDATE FIND PROS PAGE - AVATARS & POPUP

**File:** `apps/web/src/app/app/community/page.tsx`

### 3a. Add import at top of file:
```tsx
import { InitialsAvatar, VendorAvatar } from '@/components/ui/avatar';
```

### 3b. Replace the VendorPopup component entirely:

Find the `function VendorPopup` and replace with:

```tsx
function VendorPopup({ vendor }: { vendor: Vendor }) {
  return (
    <div className="w-[280px] max-w-[calc(100vw-48px)]">
      <div className="bg-white rounded-xl overflow-hidden shadow-lg">
        {/* Header */}
        <div className="p-3">
          <div className="flex items-start gap-3">
            <VendorAvatar name={vendor.name} size="lg" />
            <div className="flex-1 min-w-0">
              <h3 className="font-semibold text-warm-900 text-sm leading-tight break-words">
                {vendor.name}
              </h3>
              {vendor.havenTrusted && (
                <span className="inline-flex items-center gap-1 mt-1 px-1.5 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded">
                  <Shield className="w-3 h-3 flex-shrink-0" />
                  Trusted
                </span>
              )}
            </div>
          </div>
          
          {/* Rating */}
          <div className="mt-2 flex items-center gap-1.5 text-xs">
            <Star className="w-3.5 h-3.5 text-amber-500 fill-current flex-shrink-0" />
            <span className="font-medium text-warm-900">{vendor.rating}</span>
            <span className="text-warm-400">•</span>
            <span className="text-warm-500">{vendor.reviewCount} reviews</span>
          </div>
          
          {/* Stats */}
          <div className="mt-2 flex items-center gap-3 text-xs text-warm-600">
            <div className="flex items-center gap-1">
              <Users className="w-3.5 h-3.5 text-warm-400 flex-shrink-0" />
              <span>{vendor.neighborsUsed} neighbors</span>
            </div>
            <div className="flex items-center gap-1">
              <MapPin className="w-3.5 h-3.5 text-warm-400 flex-shrink-0" />
              <span>{vendor.distance} mi</span>
            </div>
          </div>
        </div>
        
        {/* Buttons - INSIDE card */}
        <div className="px-3 pb-3 flex gap-2">
          <button className="flex-1 py-2 bg-haven-600 text-white text-xs font-medium rounded-lg hover:bg-haven-700 transition-colors">
            Request Quote
          </button>
          <a
            href={`tel:${vendor.phone}`}
            className="px-3 py-2 border border-warm-200 rounded-lg hover:bg-warm-50 transition-colors flex items-center justify-center flex-shrink-0"
          >
            <Phone className="w-4 h-4 text-warm-600" />
          </a>
        </div>
      </div>
    </div>
  );
}
```

### 3c. Update VendorListItem to use VendorAvatar:

Find the `function VendorListItem` and replace the img tag with VendorAvatar:

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
      className={`p-3 cursor-pointer transition-colors ${
        isSelected ? 'bg-haven-50' : 'hover:bg-warm-50'
      }`}
    >
      <div className="flex gap-3">
        <VendorAvatar name={vendor.name} size="lg" className="rounded-lg" />
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <h3 className="font-medium text-warm-900 text-sm truncate">{vendor.name}</h3>
            {vendor.havenTrusted && (
              <Shield className="w-3.5 h-3.5 text-haven-600 flex-shrink-0" />
            )}
          </div>
          <div className="flex items-center gap-1.5 text-xs text-warm-500">
            <Star className="w-3 h-3 text-amber-500 fill-current flex-shrink-0" />
            <span>{vendor.rating}</span>
            <span className="text-warm-300">•</span>
            <span>{vendor.priceTier}</span>
            <span className="text-warm-300">•</span>
            <span>{vendor.distance} mi</span>
          </div>
          <div className="mt-0.5 flex items-center gap-1 text-xs text-haven-600">
            <Users className="w-3 h-3 flex-shrink-0" />
            <span className="truncate">{vendor.neighborsUsed} neighbors</span>
          </div>
        </div>
      </div>
    </div>
  );
}
```

### 3d. Update VendorCard to use VendorAvatar:

Find the `function VendorCard` and replace the avatar img with VendorAvatar:

```tsx
function VendorCard({ vendor }: { vendor: Vendor }) {
  return (
    <div className="bg-white rounded-xl border border-warm-200 overflow-hidden hover:shadow-lg transition-shadow">
      {/* Cover Image */}
      <div className="relative h-32 sm:h-40">
        <img
          src={vendor.coverUrl}
          alt={vendor.name}
          className="w-full h-full object-cover"
        />
        {vendor.havenTrusted && (
          <div className="absolute top-2 left-2 px-2 py-1 bg-haven-600 text-white text-xs font-medium rounded-full flex items-center gap-1">
            <Shield className="w-3 h-3 flex-shrink-0" />
            <span className="hidden sm:inline">Haven Trusted</span>
            <span className="sm:hidden">Trusted</span>
          </div>
        )}
        <div className="absolute bottom-2 right-2 px-2 py-1 bg-black/60 text-white text-xs rounded-full">
          {vendor.priceTier}
        </div>
      </div>

      {/* Content */}
      <div className="p-3">
        <div className="flex items-start gap-2">
          <VendorAvatar name={vendor.name} size="lg" className="rounded-lg" />
          <div className="flex-1 min-w-0">
            <h3 className="font-semibold text-warm-900 text-sm truncate">{vendor.name}</h3>
            <div className="flex items-center gap-1.5 text-xs text-warm-500">
              <Star className="w-3.5 h-3.5 text-amber-500 fill-current flex-shrink-0" />
              <span>{vendor.rating}</span>
              <span className="text-warm-300">({vendor.reviewCount})</span>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="mt-3 grid grid-cols-3 gap-1.5 text-center">
          <div className="py-1.5 bg-warm-50 rounded-lg">
            <div className="text-sm font-semibold text-warm-900">{vendor.neighborsUsed}</div>
            <div className="text-xs text-warm-500">Neighbors</div>
          </div>
          <div className="py-1.5 bg-warm-50 rounded-lg">
            <div className="text-sm font-semibold text-warm-900">{vendor.totalProjects}</div>
            <div className="text-xs text-warm-500">Projects</div>
          </div>
          <div className="py-1.5 bg-warm-50 rounded-lg">
            <div className="text-sm font-semibold text-warm-900">{vendor.onTimeRate}%</div>
            <div className="text-xs text-warm-500">On Time</div>
          </div>
        </div>

        {/* Specialties */}
        <div className="mt-2 flex flex-wrap gap-1">
          {vendor.specialties.slice(0, 2).map(specialty => (
            <span key={specialty} className="px-2 py-0.5 bg-warm-100 text-warm-600 text-xs rounded-full truncate max-w-[100px]">
              {specialty}
            </span>
          ))}
          {vendor.specialties.length > 2 && (
            <span className="px-2 py-0.5 bg-warm-100 text-warm-400 text-xs rounded-full">
              +{vendor.specialties.length - 2}
            </span>
          )}
        </div>

        {/* Actions */}
        <div className="mt-3 flex gap-2">
          <button className="flex-1 py-2 bg-haven-600 text-white text-xs font-medium rounded-lg hover:bg-haven-700">
            Request Quote
          </button>
          <button className="px-3 py-2 border border-warm-300 rounded-lg hover:bg-warm-50 flex-shrink-0">
            <Heart className="w-4 h-4 text-warm-600" />
          </button>
        </div>
      </div>
    </div>
  );
}
```

---

## FIX 4: FAMILY PAGE - ENSURE ALICE SHOWS

**File:** `apps/web/src/app/app/family/page.tsx`

The issue is that when API data loads, it overwrites the mock data. Find the `loadFamilyData` function (around line 480-520) and update it to MERGE with mock data.

### Find this code block:
```tsx
if (newAdults.length > 0) setAdults(newAdults);
if (newChildren.length > 0) setChildren(newChildren);
if (newStaff.length > 0) setStaff(newStaff);
```

### Replace with:
```tsx
// MERGE with mock data instead of replacing completely
// This ensures demo data (like Alice) always shows
if (newAdults.length > 0) {
  const apiAdultIds = new Set(newAdults.map(a => a.id));
  const mockAdultsToKeep = MOCK_ADULTS.filter(a => !apiAdultIds.has(a.id));
  setAdults([...newAdults, ...mockAdultsToKeep]);
} else {
  // If no API adults, use all mock adults
  setAdults(MOCK_ADULTS);
}

if (newChildren.length > 0) {
  const apiChildIds = new Set(newChildren.map(c => c.id));
  const mockChildrenToKeep = MOCK_CHILDREN.filter(c => !apiChildIds.has(c.id));
  setChildren([...newChildren, ...mockChildrenToKeep]);
} else {
  setChildren(MOCK_CHILDREN);
}

if (newStaff.length > 0) {
  const apiStaffIds = new Set(newStaff.map(s => s.id));
  const mockStaffToKeep = MOCK_STAFF.filter(s => !apiStaffIds.has(s.id));
  setStaff([...newStaff, ...mockStaffToKeep]);
} else {
  setStaff(MOCK_STAFF);
}
```

---

## FIX 5: UPDATE MESSAGES PAGE - USE INITIALS AVATARS

**File:** `apps/web/src/app/app/messages/page.tsx`

### 5a. Add import at top:
```tsx
import { InitialsAvatar, VendorAvatar } from '@/components/ui/avatar';
```

### 5b. In the ContactRow function, replace the avatar img with InitialsAvatar:

Find the avatar rendering code (the img tag) and replace with:

```tsx
{/* Avatar with online indicator */}
<div className="relative">
  {contact.category === 'vendors' ? (
    <VendorAvatar name={contact.name} size="lg" />
  ) : (
    <InitialsAvatar name={contact.name} size="lg" />
  )}
  {contact.isOnline && (
    <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-white" />
  )}
  {contact.isHavenTeam && (
    <div className="absolute -top-1 -right-1 w-5 h-5 bg-haven-600 rounded-full flex items-center justify-center">
      <Shield className="w-3 h-3 text-white" />
    </div>
  )}
</div>
```

### 5c. In ProjectRow, update participant avatars:

Replace the participant avatar rendering with:

```tsx
<div className="flex -space-x-2">
  {project.participants.map((participant, idx) => (
    <div key={idx} className="border-2 border-white rounded-full">
      <InitialsAvatar 
        name={participant.name} 
        size="sm"
      />
    </div>
  ))}
</div>
```

---

## FIX 6: ADD CSS FOR MAPBOX POPUP

**File:** `apps/web/src/app/globals.css`

Add at the end of the file (if not already present):

```css
/* Mapbox Popup Fixes */
.mapboxgl-popup-content {
  padding: 0 !important;
  border-radius: 12px !important;
  overflow: hidden !important;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15) !important;
}

.mapboxgl-popup-close-button {
  font-size: 20px !important;
  padding: 8px 10px !important;
  color: #666 !important;
  right: 0 !important;
  top: 0 !important;
  z-index: 10 !important;
  background: white !important;
  border-radius: 0 12px 0 8px !important;
}

.mapboxgl-popup-close-button:hover {
  background: #f5f5f4 !important;
  color: #333 !important;
}

.mapboxgl-popup-tip {
  display: none !important;
}
```

---

## VERIFICATION CHECKLIST

After applying these fixes:

1. **Mobile comparison table** (test at 375px width):
   - [ ] Shows stacked cards, NOT a table
   - [ ] No text overflow
   - [ ] "Others" on left, "Haven" on right

2. **Avatars**:
   - [ ] Find Pros: Vendor cards show initials in warm-100 rounded squares
   - [ ] Find Pros popup: Initials avatar (not DiceBear images)
   - [ ] Messages: Initials avatars for all contacts

3. **Family page**:
   - [ ] Adults section shows BOTH Bob Morrison AND Alice Morrison
   - [ ] Both have colored circle avatars with initials

4. **Vendor popup card**:
   - [ ] Name wraps if long
   - [ ] "Request Quote" button INSIDE card
   - [ ] Phone button INSIDE card
   - [ ] No overflow

---

## After Applying

```bash
npm run build
# Then deploy and HARD REFRESH browser (Cmd+Shift+R)
```

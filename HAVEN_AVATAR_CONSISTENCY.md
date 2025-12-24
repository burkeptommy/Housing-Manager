# Haven Avatar Consistency Fix

## PROBLEM

Avatars are inconsistent across the app:
- **Dashboard**: Sarah Chen shows empty/blank circle (should be ManagerAvatar)
- **Dashboard**: Today's Logistics shows mixed styles (Bob has photo, Alice blank, Emma/Jake have initials)
- **Sarah page**: Shows "SC" initials (should be ManagerAvatar)
- **Family page**: Has correct illustrated avatars

## GOAL

Every person should use the SAME Avatar component with their assigned type, everywhere they appear.

---

## AVATAR ASSIGNMENTS (FIXED)

| Person | Type | Color | Used On |
|--------|------|-------|---------|
| Sarah Chen | `manager` | champagne (fixed) | Dashboard, Sarah page, Messages, Homepage |
| Mike Rodriguez | `handyman` | orange (fixed) | Maintenance, Homepage |
| Bob Thompson | `male` | auto from name | Family, Dashboard logistics |
| Alice Thompson | `female` | auto from name | Family, Dashboard logistics |
| Emma Thompson | `girl` | auto from name | Family, Dashboard logistics |
| Jake Thompson | `boy` | auto from name | Family, Dashboard logistics |
| Max | `pet-dog` | auto from name | Family, Dashboard logistics |

---

## FILES TO FIX

### 1. Dashboard Page

**File:** `apps/web/src/app/app/dashboard/page.tsx` (or similar)

**Fix Sarah Chen's Avatar:**
```tsx
// WRONG - blank or initials
<div className="w-10 h-10 rounded-full bg-warm-200" />
// or
<div className="...">SC</div>

// CORRECT
import { ManagerAvatar } from '@/components/ui/Avatar';
<ManagerAvatar size="lg" />
```

**Fix Today's Logistics Avatars:**
```tsx
// WRONG - mixed styles, photos, initials
<img src="/bob.jpg" className="w-8 h-8 rounded-full" />
<div className="w-8 h-8 rounded-full bg-gray-200">A</div>
<div className="w-8 h-8 rounded-full bg-gray-200 text-xs">E</div>

// CORRECT
import { Avatar } from '@/components/ui/Avatar';

// Bob
<Avatar name="Bob Thompson" type="male" size="sm" />

// Alice  
<Avatar name="Alice Thompson" type="female" size="sm" />

// Emma
<Avatar name="Emma Thompson" type="girl" size="sm" />

// Jake
<Avatar name="Jake Thompson" type="boy" size="sm" />

// Max (dog)
<Avatar name="Max" type="pet-dog" size="sm" />
```

**Fix "Message Sarah" button area:**
```tsx
// At bottom of dashboard where it shows Sarah Chen
<div className="flex items-center gap-3">
  <ManagerAvatar size="md" />
  <div>
    <p className="font-semibold text-white">Sarah Chen</p>
    <p className="text-sm text-haven-200">Your Home Manager</p>
  </div>
</div>
```

### 2. Sarah Page

**File:** `apps/web/src/app/app/sarah/page.tsx` (or messages page)

**Fix Header Avatar:**
```tsx
// WRONG
<div className="w-16 h-16 rounded-full bg-warm-200 flex items-center justify-center text-xl font-semibold">
  SC
</div>

// CORRECT
import { ManagerAvatar } from '@/components/ui/Avatar';

<div className="flex items-center gap-4">
  <ManagerAvatar size="xl" />
  <div>
    <div className="flex items-center gap-2">
      <h1 className="text-2xl font-bold">Sarah Chen</h1>
      <span className="px-2 py-0.5 bg-champagne-200 text-champagne-700 text-xs font-medium rounded-full">
        Your Home Manager
      </span>
    </div>
    <p className="text-warm-500">Managing your home since June 2023</p>
  </div>
</div>
```

### 3. Family Page (Verify Consistency)

**File:** `apps/web/src/app/app/family/page.tsx`

Ensure it uses the same Avatar component:

```tsx
import { Avatar } from '@/components/ui/Avatar';

// Family member data should include type
const familyMembers = [
  { id: 1, name: 'Bob Thompson', type: 'male', role: 'Owner' },
  { id: 2, name: 'Alice Thompson', type: 'female', role: 'Owner' },
  { id: 3, name: 'Emma Thompson', type: 'girl', role: 'Child', age: 12 },
  { id: 4, name: 'Jake Thompson', type: 'boy', role: 'Child', age: 9 },
  { id: 5, name: 'Max', type: 'pet-dog', role: 'Pet' },
];

// Render
{familyMembers.map(member => (
  <div key={member.id} className="flex items-center gap-4">
    <Avatar 
      name={member.name} 
      type={member.type as 'male' | 'female' | 'boy' | 'girl' | 'pet-dog'} 
      size="lg" 
    />
    <div>
      <p className="font-semibold">{member.name}</p>
      <p className="text-sm text-warm-500">{member.role}</p>
    </div>
  </div>
))}
```

### 4. Messages/Chat Components

Any chat interface showing Sarah or family members:

```tsx
// Sarah's messages
<div className="flex items-start gap-3">
  <ManagerAvatar size="sm" />
  <div className="bg-warm-100 rounded-2xl px-4 py-2">
    <p>{message.text}</p>
  </div>
</div>

// User's messages (Bob)
<div className="flex items-start gap-3 flex-row-reverse">
  <Avatar name="Bob Thompson" type="male" size="sm" />
  <div className="bg-haven-700 text-white rounded-2xl px-4 py-2">
    <p>{message.text}</p>
  </div>
</div>
```

### 5. Homepage Chat Mockup

**File:** `apps/web/src/app/page.tsx`

```tsx
// Sarah in chat mockup
<div className="flex items-center gap-3">
  <div className="w-10 h-10 rounded-full bg-champagne-200 flex items-center justify-center">
    <Sparkles className="w-5 h-5 text-champagne-600" />
  </div>
  <div>
    <p className="font-semibold text-white">Sarah Chen</p>
    <p className="text-xs text-haven-200">Your Home Manager</p>
  </div>
</div>
```

---

## SEARCH & REPLACE PATTERNS

Search the codebase for these patterns and replace with Avatar component:

```bash
# Find hardcoded initials
grep -r "SC</\|>SC<" apps/web/src --include="*.tsx"
grep -r "MT</\|>MT<" apps/web/src --include="*.tsx"
grep -r "MR</\|>MR<" apps/web/src --include="*.tsx"

# Find photo references
grep -r "src.*\.jpg\|src.*\.png" apps/web/src --include="*.tsx" | grep -i "avatar\|profile\|photo"

# Find inline avatar styling
grep -r "rounded-full.*bg-.*flex.*items-center.*justify-center" apps/web/src --include="*.tsx"
```

---

## VERIFICATION CHECKLIST

After fixes, verify EVERY page shows consistent avatars:

- [ ] **Dashboard**
  - [ ] Sarah Chen card shows ManagerAvatar (champagne + sparkles + star)
  - [ ] Bottom bar Sarah shows ManagerAvatar
  - [ ] Bob shows male silhouette avatar
  - [ ] Alice shows female silhouette avatar  
  - [ ] Emma shows girl silhouette avatar
  - [ ] Jake shows boy silhouette avatar
  - [ ] Max shows dog avatar

- [ ] **Sarah Page**
  - [ ] Header shows ManagerAvatar (large)
  - [ ] Chat messages from Sarah show ManagerAvatar (small)

- [ ] **Family Page**
  - [ ] All members show correct avatar types
  - [ ] Colors are consistent with dashboard

- [ ] **Maintenance Page**
  - [ ] Mike Rodriguez shows HandymanAvatar

- [ ] **Homepage**
  - [ ] Chat mockup Sarah shows champagne avatar style
  - [ ] Handyman section shows orange avatar style

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Fix avatar consistency across the Haven app:

1. Dashboard page (apps/web/src/app/app/dashboard/page.tsx or similar):
   - Fix Sarah Chen's avatar: Replace blank/gray circle with ManagerAvatar component
   - Fix Today's Logistics avatars: Replace photos/initials with Avatar component
     - Bob Thompson → Avatar type="male"
     - Alice Thompson → Avatar type="female"  
     - Emma Thompson → Avatar type="girl"
     - Jake Thompson → Avatar type="boy"
     - Max → Avatar type="pet-dog"
   - Fix bottom Sarah bar: Use ManagerAvatar

2. Sarah page (apps/web/src/app/app/sarah/page.tsx):
   - Replace "SC" initials with ManagerAvatar size="xl"

3. Ensure Family page uses same Avatar component with same types

4. Search for any remaining:
   - Hardcoded initials (SC, MT, MR)
   - Photo src references for avatars
   - Inline avatar styling that should use the component

5. Every avatar should use the Avatar component from @/components/ui/Avatar

The goal: Bob on Dashboard should look identical to Bob on Family page.

Run pnpm build to verify.
```

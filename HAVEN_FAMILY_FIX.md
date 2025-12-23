# Haven Family Page - Remove Duplicate Adults

## Quick Fix

**File:** `apps/web/src/app/app/family/page.tsx`

Find the `loadFamilyData` function and simplify it to just use mock data for the demo. 

### Option 1: Always use mock data (simplest for demo)

Find the `loadFamilyData` useCallback function and replace the entire function with:

```tsx
const loadFamilyData = useCallback(async () => {
  if (!currentHousehold?.id) {
    setIsLoading(false);
    return;
  }

  try {
    const api = getApiClient();
    
    // Load pets from API (these are real user data we want to keep)
    const petsResult = await api.getFamilyPets().catch(() => []);
    if (petsResult && petsResult.length > 0) {
      const mappedPets = petsResult.map(mapToPet);
      setPets(mappedPets);
    }
    
    // For demo purposes, always use mock data for family members
    // This ensures consistent demo experience with Bob, Alice, kids, staff
    setAdults(MOCK_ADULTS);
    setChildren(MOCK_CHILDREN);
    setStaff(MOCK_STAFF);
    
  } catch (error) {
    console.error('Failed to load family data:', error);
  } finally {
    setIsLoading(false);
  }
}, [currentHousehold?.id]);
```

This will:
- Always show Bob Morrison, Alice Morrison (the demo family)
- Still load real pets from the API if you've added any
- Remove the duplicate "Bob Smith" from showing up

### Option 2: If you want to keep API integration but fix names

If you want to keep API data but have it show proper demo names, find where `MOCK_ADULTS` is defined and update Bob's info to match your actual account:

```tsx
const MOCK_ADULTS: AdultMember[] = [
  {
    id: 'a1',
    type: 'adult',
    name: 'Bob Burke',  // Your actual name
    initials: 'BB',
    role: 'Head of Household',
    isAdmin: true,
    email: 'bob@example.com',
    phone: '(203) 555-0101',
    // ... rest stays the same
  },
  {
    id: 'a2', 
    type: 'adult',
    name: 'Alice Burke',  // Spouse name
    initials: 'AB',
    role: 'Spouse',
    // ... rest stays the same
  },
];
```

---

## Recommended: Use Option 1

For a demo/prototype, Option 1 is cleaner - just use mock data so everything is consistent and you don't have to worry about API data conflicting with the demo story.

Run this in Claude Code:

```
In apps/web/src/app/app/family/page.tsx, update the loadFamilyData function to always use MOCK_ADULTS, MOCK_CHILDREN, and MOCK_STAFF instead of loading from the API. Only load pets from the API. This ensures the demo shows the Morrison family consistently without duplicates.
```

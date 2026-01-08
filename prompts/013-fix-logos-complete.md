# Haven Logo Complete Fix & Validation

## Problem Summary
Logos showing as broken placeholder icons (?) across the site due to Next.js `<Image>` component not handling SVGs with `<text>` elements.

---

## PHASE 1: Find All Logo/Image References

```bash
cd /Users/tomburke/Projects/Housing-Manager

echo "=== Finding all Image imports from next/image ==="
grep -rn --include="*.tsx" --include="*.ts" "import Image from 'next/image'" apps/web/src/

echo ""
echo "=== Finding all <Image usage ==="
grep -rn --include="*.tsx" "<Image" apps/web/src/

echo ""
echo "=== Finding all logo/icon file references ==="
grep -rn --include="*.tsx" --include="*.ts" -E "src=.*logo|src=.*icon|src=.*favicon" apps/web/src/

echo ""
echo "=== Finding all SVG imports ==="
grep -rn --include="*.tsx" --include="*.ts" "\.svg" apps/web/src/
```

---

## PHASE 2: Fix All Known Issues

### 2a. Fix Navbar.tsx (Landing Page Header)
**File:** `apps/web/src/components/marketing/Navbar.tsx`

```tsx
// REMOVE this import:
// import Image from 'next/image';

// REPLACE all <Image> tags with <img> tags:
// Before:
<Image
  src={isScrolled ? '/logo-wordmark.svg' : '/logo-wordmark-white.svg'}
  alt="Haven"
  width={140}
  height={36}
  priority
  className="h-9 w-auto"
/>

// After:
<img
  src={isScrolled ? '/logo-wordmark.svg' : '/logo-wordmark-white.svg'}
  alt="Haven"
  className="h-9 w-auto"
/>
```

### 2b. Fix desktop-sidebar.tsx (Dashboard Sidebar)
**File:** `apps/web/src/components/app-shell/desktop-sidebar.tsx`

```tsx
// REMOVE this import:
// import Image from 'next/image';

// REPLACE:
<Image
  src="/logo-wordmark-white.svg"
  alt="Haven"
  width={140}
  height={36}
  priority
  className="h-8 w-auto"
/>

// WITH:
<img
  src="/logo-wordmark-white.svg"
  alt="Haven"
  className="h-8 w-auto"
/>
```

### 2c. Check and Fix mobile-header.tsx
**File:** `apps/web/src/components/app-shell/mobile-header.tsx`

Check if it uses `<Image>` for logo and apply same fix.

### 2d. Check and Fix Any Other Components

Run the grep commands from Phase 1 and fix ANY component that:
1. Imports `Image from 'next/image'`
2. Uses `<Image>` with a `.svg` src that contains our logo

---

## PHASE 3: Validate All SVG Files Exist and Are Valid

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/web/public

echo "=== Checking all logo files exist ==="
ls -la logo.svg favicon.svg logo-wordmark.svg logo-wordmark-white.svg icon-white.svg icon-navy.svg

echo ""
echo "=== Validating SVG syntax (first 3 lines) ==="
for f in *.svg; do
  echo "--- $f ---"
  head -3 "$f"
done

echo ""
echo "=== Checking file sizes (should be > 500 bytes) ==="
wc -c *.svg
```

---

## PHASE 4: Verify Favicon Configuration

**File:** `apps/web/src/app/layout.tsx`

Ensure the metadata includes:
```tsx
icons: {
  icon: '/favicon.svg',
  shortcut: '/favicon.svg',
  apple: '/logo.svg',
},
```

---

## PHASE 5: Clear Cache and Rebuild

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Clear Next.js cache completely
rm -rf apps/web/.next
rm -rf apps/web/node_modules/.cache

# Rebuild
cd apps/web
pnpm build

# Or restart dev server
pnpm dev
```

---

## PHASE 6: Comprehensive Site Validation

After fixes are applied, manually verify each of these locations:

### Landing Page (/)
- [ ] Header logo (top left) - Should show Haven wordmark with champagne roof
- [ ] Mobile menu logo (if applicable)
- [ ] Footer logo (if applicable)
- [ ] Favicon in browser tab - Should show H with champagne roof

### Login Page (/login)
- [ ] Logo on login form/header

### Register Page (/register)  
- [ ] Logo on registration form/header

### Onboarding (/onboarding)
- [ ] Logo during onboarding flow

### Dashboard (/app)
- [ ] Sidebar logo (top of left sidebar) - White wordmark on navy
- [ ] Mobile header logo
- [ ] Favicon still correct

### All Dashboard Sub-pages
- [ ] /app/sarah
- [ ] /app/messages
- [ ] /app/calendar
- [ ] /app/home
- [ ] /app/family
- [ ] /app/projects
- [ ] /app/maintenance
- [ ] /app/find-pros
- [ ] /app/money
- [ ] /app/profile
- [ ] /app/settings

(Sidebar logo should persist on all these pages)

### Manager Portal (/manager)
- [ ] Logo in manager dashboard

### Other Portals (if applicable)
- [ ] /handyman
- [ ] /vendor
- [ ] /admin

---

## PHASE 7: Browser/URL Direct Tests

Open these URLs directly in browser to confirm SVGs render:

```
http://localhost:3000/logo.svg
http://localhost:3000/favicon.svg
http://localhost:3000/logo-wordmark.svg
http://localhost:3000/logo-wordmark-white.svg
http://localhost:3000/icon-white.svg
http://localhost:3000/icon-navy.svg
```

Each should display the Haven logo correctly. If any show XML or errors, the file is malformed.

---

## PHASE 8: Check for ESLint/TypeScript Errors

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/web

# Check for any errors after changes
pnpm lint
pnpm type-check
```

Fix any errors related to:
- Unused `Image` imports that weren't removed
- Missing alt tags on `<img>` elements
- Any TypeScript errors

---

## PHASE 9: Final Grep to Confirm No Remaining Issues

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Should return NO results for SVG files with Image component
echo "=== Checking for remaining Image+SVG combinations ==="
grep -rn --include="*.tsx" -B2 -A2 "<Image" apps/web/src/ | grep -i "\.svg"

# Confirm all logo references use <img> not <Image>
echo ""
echo "=== All current logo implementations ==="
grep -rn --include="*.tsx" -E "src=.*(logo|Logo|icon|Icon|favicon).*\.svg" apps/web/src/
```

The first command should return nothing. The second should show only `<img` tags (lowercase), not `<Image`.

---

## PHASE 10: Commit and Deploy

```bash
cd /Users/tomburke/Projects/Housing-Manager

git add .
git commit -m "fix(branding): Replace Next.js Image with img tags for all SVG logos

- Fix Navbar.tsx logo (landing page header)
- Fix desktop-sidebar.tsx logo (dashboard sidebar)
- Fix mobile-header.tsx logo (if applicable)
- Fix any other components using Image with SVG
- Resolves broken placeholder icons across site

Tested on:
- Landing page header ✓
- Dashboard sidebar ✓
- All sub-pages ✓
- Favicon ✓"

git push origin main
```

---

## Quick Reference: Files Most Likely Needing Fixes

| File | Location | Logo Type |
|------|----------|-----------|
| `Navbar.tsx` | `src/components/marketing/` | Wordmark (switches white/navy on scroll) |
| `desktop-sidebar.tsx` | `src/components/app-shell/` | Wordmark white |
| `mobile-header.tsx` | `src/components/app-shell/` | Icon or wordmark |
| `layout.tsx` | `src/app/` | Favicon metadata |
| `Footer.tsx` | `src/components/marketing/` | Wordmark (if exists) |
| `login/page.tsx` | `src/app/login/` | Logo on form |
| `register/page.tsx` | `src/app/register/` | Logo on form |

---

## Troubleshooting

### Logo still broken after fix?
1. Hard refresh: `Cmd + Shift + R`
2. Clear browser cache completely
3. Try incognito window
4. Check console for 404 errors

### SVG renders as code/XML?
The SVG file has incorrect MIME type or syntax error. Recreate the file.

### Favicon not updating?
1. Favicons are heavily cached - try incognito
2. Check `/favicon.svg` loads directly in browser
3. Verify metadata in `layout.tsx` is correct
4. May need to clear browser favicon cache completely

### ESLint error about `<img>`?
Next.js ESLint may warn about using `<img>` instead of `<Image>`. For SVGs with text elements, `<img>` is correct. Add this to `.eslintrc.js` if needed:
```js
rules: {
  '@next/next/no-img-element': 'off', // SVGs with text need <img>
}
```

Or use inline disable comment:
```tsx
{/* eslint-disable-next-line @next/next/no-img-element */}
<img src="/logo.svg" alt="Haven" />
```

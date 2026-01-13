# Haven Logo Complete Replacement - Roof Peak Logo

## CRITICAL FIRST STEP: Generate favicon.ico

**This must be done FIRST before anything else:**

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/web/public

# Generate favicon.ico from the SVG (requires ImageMagick)
# Install if needed: brew install imagemagick
convert -background none favicon.svg -define icon:auto-resize=256,128,64,48,32,16 favicon.ico

# Verify it was created and has content
ls -la favicon.ico
file favicon.ico
```

If ImageMagick is not installed:
```bash
brew install imagemagick
```

Then run the convert command again.

---

## PHASE 1: Generate PNG Assets for Mobile

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile/assets

# Generate all PNGs from SVGs
convert -background none icon.svg -resize 1024x1024 icon.png
convert -background none adaptive-icon.svg -resize 1024x1024 adaptive-icon.png  
convert -background none splash.svg splash.png
convert -background none favicon.svg -resize 48x48 favicon.png
convert -background none notification-icon.svg -resize 96x96 notification-icon.png

# Verify all PNGs exist
ls -la *.png
```

---

## PHASE 2: Fix Code - Replace <Image> with <img>

### 2a. Fix Navbar.tsx
**File:** `apps/web/src/components/marketing/Navbar.tsx`

**DELETE this line:**
```tsx
import Image from 'next/image';
```

**FIND and REPLACE:**
```tsx
// FIND:
<Image
  src={isScrolled ? '/logo-wordmark.svg' : '/logo-wordmark-white.svg'}
  alt="Haven"
  width={140}
  height={36}
  priority
  className="h-9 w-auto"
/>

// REPLACE WITH:
<img
  src={isScrolled ? '/logo-wordmark.svg' : '/logo-wordmark-white.svg'}
  alt="Haven"
  className="h-9 w-auto"
/>
```

### 2b. Fix desktop-sidebar.tsx  
**File:** `apps/web/src/components/app-shell/desktop-sidebar.tsx`

**DELETE this line:**
```tsx
import Image from 'next/image';
```

**FIND and REPLACE:**
```tsx
// FIND:
<Image
  src="/logo-wordmark-white.svg"
  alt="Haven"
  width={140}
  height={36}
  priority
  className="h-8 w-auto"
/>

// REPLACE WITH:
<img
  src="/logo-wordmark-white.svg"
  alt="Haven"
  className="h-8 w-auto"
/>
```

### 2c. Search for ANY other Image+SVG logo combinations
```bash
grep -rn --include="*.tsx" -B2 -A2 "<Image" apps/web/src/ | grep -i "\.svg"
```
Fix any found with the same pattern.

---

## PHASE 3: Verify layout.tsx has correct favicon config

**File:** `apps/web/src/app/layout.tsx`

The icons section should include favicon.ico:
```tsx
icons: {
  icon: [
    { url: '/favicon.ico', sizes: 'any' },
    { url: '/favicon.svg', type: 'image/svg+xml' },
  ],
  apple: '/logo.svg',
},
```

---

## PHASE 4: Update manifest.json

**File:** `apps/web/public/manifest.json`

Ensure it has:
```json
{
  "name": "Haven",
  "short_name": "Haven", 
  "description": "Stop managing your home. Start living in it.",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0a1929",
  "theme_color": "#0a1929",
  "icons": [
    {
      "src": "/favicon.ico",
      "sizes": "48x48",
      "type": "image/x-icon"
    },
    {
      "src": "/logo.svg",
      "sizes": "any",
      "type": "image/svg+xml"
    }
  ]
}
```

---

## PHASE 5: Search & Destroy ALL Old Logo References

Run each of these searches and fix/delete anything found:

```bash
cd /Users/tomburke/Projects/Housing-Manager

# 1. Find old champagne color in ANY logo/icon files
grep -rn "#c4a574" apps/web/public/
grep -rn "#c4a574" apps/mobile/assets/
# ACTION: If found in logo files, those are OLD logos - delete or replace them

# 2. Find serif font references in SVGs (old logo used serif H)
grep -rn "serif\|Times\|Georgia" apps/web/public/*.svg
grep -rn "serif\|Times\|Georgia" apps/mobile/assets/*.svg
# ACTION: Delete any SVGs with serif fonts - they're old logos

# 3. Find old H letterform path patterns
grep -rn "M -76 -52" apps/
grep -rn "M -38 -26" apps/
grep -rn "M -19 -13" apps/
# ACTION: These are old serif H logos - replace with roof peak

# 4. Check for remaining Image imports that might be for logos
grep -rn "import Image from 'next/image'" apps/web/src/components/marketing/
grep -rn "import Image from 'next/image'" apps/web/src/components/app-shell/
# ACTION: Remove if only used for logo SVGs

# 5. Find any <text> elements in logo SVGs (old wordmark had text)
grep -rn "<text" apps/web/public/*.svg
# ACTION: Verify these are the NEW wordmarks with system font, not old serif
```

---

## PHASE 6: Verify All Correct Files Exist

```bash
# Web public folder
ls -la apps/web/public/favicon.ico    # MUST exist and be > 0 bytes
ls -la apps/web/public/favicon.svg
ls -la apps/web/public/logo.svg
ls -la apps/web/public/logo-wordmark.svg
ls -la apps/web/public/logo-wordmark-white.svg
ls -la apps/web/public/icon-white.svg
ls -la apps/web/public/icon-navy.svg

# Mobile assets
ls -la apps/mobile/assets/icon.png        # MUST exist
ls -la apps/mobile/assets/adaptive-icon.png
ls -la apps/mobile/assets/splash.png
ls -la apps/mobile/assets/notification-icon.png
```

---

## PHASE 7: Clean Build

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Clear ALL caches
rm -rf apps/web/.next
rm -rf apps/web/node_modules/.cache
rm -rf apps/mobile/.expo

# Rebuild web
cd apps/web
pnpm build
```

---

## PHASE 8: Validation

### Test URLs directly in browser:
```
http://localhost:3000/favicon.ico
http://localhost:3000/favicon.svg
http://localhost:3000/logo.svg
http://localhost:3000/logo-wordmark.svg
http://localhost:3000/logo-wordmark-white.svg
```

### Test pages:
- Landing page (/) - roof peak wordmark in header
- Dashboard (/app) - white roof peak wordmark in sidebar
- Browser tab - roof peak favicon

### Force favicon refresh:
```bash
# Open in incognito or clear cache
# Cmd + Shift + R to hard refresh
```

---

## PHASE 9: Final Verification - Confirm No Old Logos

**ALL of these commands should return EMPTY/no matches:**

```bash
cd /Users/tomburke/Projects/Housing-Manager

# No champagne color in logo files
grep -l "#c4a574" apps/web/public/*.svg apps/mobile/assets/*.svg 2>/dev/null

# No serif fonts in logo files  
grep -l "Times\|Georgia" apps/web/public/*.svg apps/mobile/assets/*.svg 2>/dev/null

# No old H path patterns
grep -l "M -76 -52\|M -38 -26\|M -19 -13" apps/web/public/*.svg 2>/dev/null

# No Image component in logo-related components (should be <img>)
grep "import Image from" apps/web/src/components/marketing/Navbar.tsx
grep "import Image from" apps/web/src/components/app-shell/desktop-sidebar.tsx
```

If any return results, go back and fix them.

---

## PHASE 10: Commit

```bash
git add .
git commit -m "feat(branding): Replace all logos with simple roof peak design

NEW LOGO: Simple white roof peak chevron on navy (#0a1929) background

Changes:
- Generated favicon.ico (proper ICO format with multiple sizes)
- Updated all web SVG assets with roof peak design  
- Updated all mobile PNG assets
- Fixed Navbar.tsx: <Image> -> <img> for SVG compatibility
- Fixed desktop-sidebar.tsx: <Image> -> <img> for SVG compatibility
- Updated manifest.json with favicon.ico reference
- Removed all traces of old serif H logo with champagne roof

The new logo is minimal and scales perfectly from 16px to 1024px."

git push origin main
```

---

## Logo Reference

**New Design:**
```
     /\
    /  \
   /    \
```

**Colors:**
- Background: Navy #0a1929
- Icon: White #ffffff

**Files:**
| File | Purpose |
|------|---------|
| favicon.ico | Browser tab (ICO format) |
| favicon.svg | SVG fallback |
| logo.svg | Main app icon |
| logo-wordmark.svg | Logo + "HAVEN" (navy) |
| logo-wordmark-white.svg | Logo + "HAVEN" (white) |
| icon.png | iOS App Store |
| adaptive-icon.png | Android |

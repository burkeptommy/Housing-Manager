# Haven Logo Validation & Fix Prompt

## Problem
The Haven logos are not rendering correctly:
- Landing page header: Shows broken image placeholder (? icon)
- Dashboard sidebar: Shows broken image placeholder
- Favicon: Not updated to new Haven logo

## Step 1: Validate Logo Files Exist and Are Valid

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Check web public folder
echo "=== Web Public Folder ===" 
ls -la apps/web/public/*.svg

# Validate SVG files are not empty and have valid content
echo ""
echo "=== Validating SVG Content ===" 
for f in apps/web/public/*.svg; do
  echo "$f: $(head -c 100 $f)"
  echo "---"
done

# Check file sizes (should be > 0)
echo ""
echo "=== File Sizes ===" 
wc -c apps/web/public/*.svg
```

## Step 2: Find All Logo References in Codebase

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Find all image/logo references in web app
echo "=== Finding logo/image references ===" 
grep -rn --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" -E "(logo|Logo|favicon|icon)" apps/web/src/ | head -50

# Find img tags
echo ""
echo "=== Finding img tags ===" 
grep -rn --include="*.tsx" "<img" apps/web/src/ | head -30

# Find Image components (Next.js)
echo ""
echo "=== Finding Next.js Image components ===" 
grep -rn --include="*.tsx" "from 'next/image'" apps/web/src/
grep -rn --include="*.tsx" "<Image" apps/web/src/ | head -30

# Check layout files specifically
echo ""
echo "=== Layout files ===" 
cat apps/web/src/app/layout.tsx | head -50
echo "---"
cat apps/web/src/app/app/layout.tsx | head -100
```

## Step 3: Check Current Logo Implementation

Look at these specific files and identify how logos are currently referenced:

1. **Landing page header**: `apps/web/src/app/page.tsx` or a header component
2. **Dashboard sidebar**: `apps/web/src/app/app/layout.tsx` 
3. **Favicon**: `apps/web/src/app/layout.tsx` (metadata)

```bash
# Find the header/navbar component
grep -rn --include="*.tsx" -l "navbar\|header\|Header\|Navbar" apps/web/src/

# Find where the current broken logo is
grep -rn --include="*.tsx" "src=.*logo\|src=.*Logo\|src=.*icon" apps/web/src/
```

## Step 4: Fix the Logo References

### 4a. Fix Root Layout (Favicon)

**File: `apps/web/src/app/layout.tsx`**

Add or update the metadata to include the favicon:

```tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Haven - Full-Service Home Management',
  description: 'Stop managing your home. Start living in it.',
  icons: {
    icon: '/favicon.svg',
    shortcut: '/favicon.svg',
    apple: '/logo.svg',
  },
}
```

### 4b. Fix Landing Page Header Logo

Find the header/navbar component (likely in `apps/web/src/components/` or inline in `page.tsx`) and update the logo:

```tsx
// Replace broken logo with:
<img 
  src="/logo.svg" 
  alt="Haven" 
  className="h-10 w-10"
/>

// Or for the wordmark version:
<img 
  src="/logo-wordmark.svg" 
  alt="Haven" 
  className="h-8"
/>
```

### 4c. Fix Dashboard Sidebar Logo

**File: `apps/web/src/app/app/layout.tsx`**

Find the sidebar section and update the logo:

```tsx
// For white logo on dark sidebar:
<img 
  src="/logo.svg" 
  alt="Haven" 
  className="h-10 w-10"
/>

// Or icon only on dark background:
<img 
  src="/icon-white.svg" 
  alt="Haven" 
  className="h-8 w-8"
/>
```

## Step 5: Verify the SVG Files Are Web-Compatible

Sometimes SVGs have issues. Validate they work:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/web/public

# Check if SVGs have proper XML declaration and viewBox
head -5 logo.svg
head -5 favicon.svg
head -5 icon-white.svg

# Ensure no BOM or weird characters
file logo.svg
file favicon.svg
```

If there are encoding issues, recreate the files:

```bash
# Test by opening in browser directly
open logo.svg
```

## Step 6: Clear Cache and Rebuild

```bash
cd /Users/tomburke/Projects/Housing-Manager

# Clear Next.js cache
rm -rf apps/web/.next

# Rebuild
cd apps/web
pnpm build

# Or just restart dev server
pnpm dev
```

## Step 7: Browser Cache

After fixing, hard refresh the browser:
- Mac: `Cmd + Shift + R`
- Or open in incognito window to bypass cache

## Step 8: Verify All Logos Render

Check these URLs manually:
- `http://localhost:3000/logo.svg` - Should show the Haven logo
- `http://localhost:3000/favicon.svg` - Should show the favicon
- `http://localhost:3000/icon-white.svg` - Should show white icon
- `http://localhost:3000/logo-wordmark.svg` - Should show logo + text

If any return 404 or don't render, the file is missing or corrupted.

## Common Issues & Fixes

### Issue: SVG shows as broken image
**Cause**: Path is wrong or file doesn't exist
**Fix**: Verify file exists in `apps/web/public/` and path starts with `/`

### Issue: SVG exists but doesn't render
**Cause**: SVG has invalid syntax or encoding issues
**Fix**: Recreate the SVG file or validate with an SVG validator

### Issue: Favicon not updating
**Cause**: Browser cache or metadata not configured
**Fix**: 
1. Add icons to metadata in layout.tsx
2. Hard refresh browser
3. Check that `/favicon.svg` is accessible directly

### Issue: Next.js Image component errors
**Cause**: Using `<Image>` component with SVG
**Fix**: Use regular `<img>` tag for SVGs, or configure next.config.ts for SVG

## Final Validation Checklist

After fixes, verify:
- [ ] Landing page header shows Haven logo (navy background, white H, champagne roof)
- [ ] Dashboard sidebar shows Haven logo
- [ ] Browser tab shows Haven favicon
- [ ] `/logo.svg` renders correctly in browser
- [ ] `/favicon.svg` renders correctly in browser
- [ ] No console errors related to images

## Commit After Fixing

```bash
git add .
git commit -m "fix(branding): Fix logo references and favicon configuration

- Update metadata in layout.tsx with correct favicon path
- Fix logo src paths in header and sidebar components  
- Ensure SVG files are properly served from public folder"

git push origin main
```

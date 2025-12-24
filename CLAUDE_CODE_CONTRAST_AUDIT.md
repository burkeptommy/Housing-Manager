# HAVEN ACCESSIBILITY AUDIT
## Dark Text on Dark Background Detection

**Priority:** HIGH
**Estimated Time:** 20-40 minutes

---

## OBJECTIVE

Find and fix all instances where dark text appears on dark backgrounds, ensuring proper contrast ratios throughout the application.

---

## STEP 1: IDENTIFY PROBLEM PATTERNS

### Pattern A: Dark Background + Default/Dark Text

```tsx
// BAD: Dark background with no text color override
<div className="bg-gray-800">
  <p>This text will be hard to read</p>  // Inherits dark text
</div>

// BAD: Dark background with dark text explicitly set
<div className="bg-navy-900 text-gray-800">
  <span>Invisible text</span>
</div>

// BAD: Navy sidebar with navy text
<div className="bg-haven-navy-950 text-haven-navy-900">
  Unreadable
</div>
```

### Pattern B: Conditional Dark Backgrounds

```tsx
// BAD: Dark mode or state changes background but not text
<div className={isActive ? "bg-gray-900" : "bg-white"}>
  <span className="text-gray-700">May be invisible when active</span>
</div>
```

---

## STEP 2: SEARCH COMMANDS

Run these to find potential issues:

```bash
# Find dark backgrounds (navy, gray-700+, slate-700+)
grep -rn --include="*.tsx" \
  -E "bg-(gray|slate|zinc|neutral)-(7|8|9)[0-9]{2}|bg-haven-navy-(7|8|9)[0-9]{2}|bg-\[#[0-3]" \
  apps/web/src/

# Find dark backgrounds followed by text without light text class
grep -rn --include="*.tsx" -A5 \
  -E "bg-(gray|slate)-(800|900|950)|bg-haven-navy-(800|900|950)|bg-\[#0|bg-\[#1|bg-\[#2" \
  apps/web/src/ | grep -v "text-white\|text-gray-[1-4]\|text-haven-navy-[1-3]\|text-haven-champagne"

# Find potential sidebar issues
grep -rn --include="*.tsx" \
  -E "bg-haven-navy-950|bg-\[#0a1929\]" \
  apps/web/src/ -A10 | grep -E "text-gray-[5-9]|text-haven-navy-[5-9]|text-black"

# Find black backgrounds
grep -rn --include="*.tsx" \
  -E "bg-black|bg-\[#000" \
  apps/web/src/
```

---

## STEP 3: COMMON PROBLEM AREAS

### 1. Sidebar Navigation
**File:** `apps/web/src/app/app/layout.tsx` or `components/layout/Sidebar.tsx`

```tsx
// CHECK: Sidebar items on dark background
// Background is navy-950 (#0a1929)
// Text MUST be: white, gray-100, gray-200, gray-300

// CORRECT:
<nav className="bg-haven-navy-950">
  <a className="text-gray-300 hover:text-white">Dashboard</a>
</nav>

// WRONG:
<nav className="bg-haven-navy-950">
  <a className="text-gray-600">Dashboard</a>  // Too dark!
</nav>
```

### 2. Cards with Dark Headers
**Common in:** Dashboard, Money page, Sarah page

```tsx
// CHECK: Card headers with dark backgrounds
// CORRECT:
<div className="bg-haven-navy-900 rounded-t-lg p-4">
  <h3 className="text-white font-semibold">Card Title</h3>
  <p className="text-gray-300">Subtitle</p>
</div>

// WRONG:
<div className="bg-haven-navy-900 rounded-t-lg p-4">
  <h3 className="text-gray-700 font-semibold">Card Title</h3>  // Invisible!
</div>
```

### 3. Status Badges on Dark Backgrounds
```tsx
// CHECK: Badges that might appear on dark cards
// CORRECT:
<Badge className="bg-haven-champagne-500 text-haven-navy-900">Active</Badge>

// WRONG:
<Badge className="bg-haven-navy-700 text-haven-navy-800">Active</Badge>
```

### 4. Modal/Dialog Overlays
```tsx
// CHECK: Modal content on dark overlays
// Overlay might be dark, content should have light background
```

### 5. Footer Sections
```tsx
// CHECK: Footer on dark background
// CORRECT:
<footer className="bg-haven-navy-950 text-gray-300">
  <p className="text-gray-400">© 2025 Haven</p>
</footer>
```

---

## STEP 4: CONTRAST REQUIREMENTS (WCAG 2.1 AA)

### Minimum Contrast Ratios
- **Normal text:** 4.5:1
- **Large text (18px+ or 14px bold):** 3:1
- **UI components:** 3:1

### Safe Combinations

| Background | Safe Text Colors |
|------------|------------------|
| `navy-950` (#0a1929) | white, gray-100, gray-200, gray-300, champagne-300+ |
| `navy-900` (#102a43) | white, gray-100, gray-200, gray-300, champagne-300+ |
| `navy-800` (#243b53) | white, gray-100, gray-200, champagne-200+ |
| `gray-900` (#111827) | white, gray-100, gray-200, gray-300 |
| `gray-800` (#1f2937) | white, gray-100, gray-200, gray-300 |
| `black` | white, gray-100, gray-200 |

### Dangerous Combinations (AVOID)

| Background | Avoid These Text Colors |
|------------|------------------------|
| `navy-950` | navy-600+, gray-500+, black |
| `navy-900` | navy-500+, gray-500+, black |
| `gray-900` | gray-500+, navy-600+, black |
| `gray-800` | gray-600+, navy-700+ |

---

## STEP 5: FILE-BY-FILE AUDIT

Check these files specifically:

```bash
# Sidebar/Layout
apps/web/src/app/app/layout.tsx
apps/web/src/components/layout/Sidebar.tsx
apps/web/src/components/layout/Header.tsx

# Dashboard (has dark stat cards)
apps/web/src/app/app/page.tsx

# Sarah page (manager hub with dark elements)
apps/web/src/app/app/sarah/page.tsx

# Money page (dark statement header)
apps/web/src/app/app/money/page.tsx

# Homepage (marketing - dark hero sections)
apps/web/src/app/page.tsx

# Find Pros (map with dark elements)
apps/web/src/app/app/find-pros/page.tsx

# Your Home (property card with dark header)
apps/web/src/app/app/home/page.tsx
```

---

## STEP 6: AUTOMATED CHECK SCRIPT

Create and run this script:

```bash
#!/bin/bash
# save as: scripts/check-contrast.sh

echo "=== DARK BACKGROUND AUDIT ==="
echo ""

echo "1. Files with dark backgrounds:"
grep -l --include="*.tsx" -rE \
  "bg-(gray|slate)-(800|900|950)|bg-haven-navy-(800|900|950)|bg-black|bg-\[#0|bg-\[#1|bg-\[#2" \
  apps/web/src/

echo ""
echo "2. Potential contrast issues (dark bg near dark text):"
grep -rn --include="*.tsx" -B2 -A2 \
  "bg-haven-navy-950\|bg-haven-navy-900\|bg-gray-900\|bg-gray-800" \
  apps/web/src/ | grep -E "text-(gray|haven-navy)-(5|6|7|8|9)[0-9]{2}|text-black"

echo ""
echo "3. Sidebar-specific check:"
grep -rn --include="*.tsx" "Sidebar\|sidebar\|side-bar" apps/web/src/ | head -20

echo ""
echo "=== Review each file above manually ==="
```

---

## STEP 7: FIXING PATTERNS

### Fix 1: Add explicit light text to dark containers

```tsx
// BEFORE
<div className="bg-haven-navy-950 p-6">
  <h2>Title</h2>
  <p>Description</p>
</div>

// AFTER
<div className="bg-haven-navy-950 p-6 text-white">
  <h2>Title</h2>
  <p className="text-gray-300">Description</p>
</div>
```

### Fix 2: Use CSS variables for theme consistency

```css
/* In globals.css */
.dark-section {
  background-color: var(--haven-navy-950);
  color: var(--gray-100);
}

.dark-section p,
.dark-section span {
  color: var(--gray-300);
}
```

### Fix 3: Component-level defaults

```tsx
// Create a DarkCard component with correct defaults
function DarkCard({ children, className }: Props) {
  return (
    <div className={cn(
      "bg-haven-navy-900 text-white rounded-lg",
      className
    )}>
      {children}
    </div>
  )
}
```

---

## STEP 8: VERIFICATION CHECKLIST

After fixes, verify each page:

- [ ] **Sidebar:** All nav items readable on navy-950
- [ ] **Dashboard:** Stat cards readable, header text visible
- [ ] **Sarah page:** Manager card text visible
- [ ] **Money page:** Statement header text visible
- [ ] **Homepage:** Hero section text visible, footer readable
- [ ] **Your Home:** Property card header text visible
- [ ] **All modals:** Text visible on any overlay

### Quick Visual Test
1. Run `pnpm dev:web`
2. Navigate to each page
3. Squint at the screen - if anything disappears, it's a contrast issue
4. Use browser DevTools > Rendering > Emulate vision deficiencies

---

## STEP 9: BROWSER CONTRAST CHECK

Use Chrome DevTools:
1. Right-click element → Inspect
2. In Styles panel, click the color swatch
3. Look for contrast ratio (should show ✓ for AA compliance)

Or use the Lighthouse accessibility audit:
1. DevTools → Lighthouse tab
2. Check "Accessibility"
3. Run audit
4. Look for "Background and foreground colors do not have a sufficient contrast ratio"

---

## SUMMARY: THE RULES

1. **Dark backgrounds (navy-800+, gray-800+)** → Text must be white, gray-100, gray-200, or gray-300
2. **Sidebar (navy-950)** → Text must be gray-300 or lighter, active items white
3. **Cards with dark headers** → Explicitly set text-white on the header
4. **Never assume** → Always explicitly set text color when background is dark
5. **When in doubt** → Use white text on dark backgrounds

---

*Accessibility isn't optional. Every user should be able to read Haven.*

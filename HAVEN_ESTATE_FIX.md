# Haven Estate Pricing Card Fix

## The Problem

The current Haven Estate tier lists specific features that make other tiers seem less personal:
- "Dedicated home manager (2:1 or 1:1)"
- "Dedicated handyman access"

This implies other tiers DON'T have dedicated service, which undermines them.

## The Fix

**File:** `apps/web/src/app/(marketing)/page.tsx`

Find the Haven Estate pricing card and replace with:

```tsx
{/* Haven Estate */}
<div className="relative bg-gradient-to-br from-forest-900 to-forest-950 rounded-2xl p-8 text-white">
  <div className="absolute top-4 right-4">
    <span className="px-3 py-1 bg-gold-500/20 text-gold-400 text-xs font-medium rounded-full border border-gold-500/30">
      White Glove
    </span>
  </div>
  
  <h3 className="text-xl font-semibold">Haven Estate</h3>
  <p className="text-white/60 mt-1">For estates & multiple properties</p>
  
  <div className="mt-6">
    <span className="text-4xl font-bold">$3,499+</span>
    <span className="text-white/60">/month</span>
  </div>
  
  {/* Elegant tagline instead of feature bullets */}
  <p className="mt-6 text-white/80 text-lg leading-relaxed">
    Your personal estate manager—anticipating needs, coordinating staff, and ensuring every detail of your properties is handled with discretion and excellence.
  </p>
  
  <ul className="mt-6 space-y-3 text-white/70">
    <li className="flex items-center gap-2">
      <Check className="w-4 h-4 text-gold-400" />
      Multiple properties supported
    </li>
    <li className="flex items-center gap-2">
      <Check className="w-4 h-4 text-gold-400" />
      Priority 24/7 concierge access
    </li>
    <li className="flex items-center gap-2">
      <Check className="w-4 h-4 text-gold-400" />
      Custom service agreements
    </li>
  </ul>
  
  <button className="mt-8 w-full py-3 bg-gold-500 hover:bg-gold-400 text-forest-950 font-semibold rounded-xl transition-colors">
    Contact Us
  </button>
</div>
```

## Key Changes

| Before | After |
|--------|-------|
| "Dedicated home manager (2:1 or 1:1)" | Elegant tagline about personal estate management |
| "Dedicated handyman access" | Removed (implied in white glove) |
| "Full concierge & multiple properties" | Split into cleaner bullet points |
| "Contact Us" as text | Proper gold CTA button |

## Alternative Taglines

Pick one that resonates:

1. **Current recommendation:**
   > "Your personal estate manager—anticipating needs, coordinating staff, and ensuring every detail of your properties is handled with discretion and excellence."

2. **Shorter:**
   > "The full estate management experience. Every property, every detail, handled."

3. **Luxury-focused:**
   > "Like having a world-class estate manager on retainer—without the $200K salary."

4. **Service-focused:**
   > "We manage your properties the way you'd manage them yourself—if you had unlimited time."

---

## Run

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then:
```
Read and apply the fix in /Users/tomburke/Projects/Housing-Manager/HAVEN_ESTATE_FIX.md

Update the Haven Estate pricing card on the homepage to:
1. Replace specific feature bullets with an elegant tagline about full estate management
2. Make "Contact Us" a proper gold button
3. Keep it feeling exclusive without making other tiers seem less personal
```

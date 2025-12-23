# 🔧 HAVEN - COMPREHENSIVE FIX & ENHANCEMENT PROMPT

## HOW TO RUN

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this entire prompt.

---

## ISSUES TO FIX

1. **Vendor Map Card Bug** - Close button, call button, verified badge outside card container
2. **Vendor Photos** - All vendors have same photo, need unique per vendor
3. **User Avatars** - Replace real photos with nice illustrated avatars (DiceBear or similar)
4. **More Vendors** - Add 20+ vendors across different categories for better demo
5. **Project Planning Overhaul** - Kitchen backsplash just shows photo, needs full project workflow
6. **Font Inconsistency** - Elegant font only on some headings, card content uses old font
7. **Family Page** - Only shows Bob, missing wife Alice and kids

---

## FIX 1: VENDOR MAP CARD LAYOUT

**File:** `apps/web/src/app/app/community/page.tsx`

Find the vendor detail card/popup component that appears when clicking a marker. The issue is that elements are positioned outside the card container. Fix by ensuring:

```tsx
// The vendor popup card should look like this:
<div className="bg-white rounded-2xl shadow-xl overflow-hidden w-80">
  {/* Header with close button INSIDE the card */}
  <div className="relative">
    {/* Vendor image */}
    <div className="h-32 bg-cover bg-center" style={{ backgroundImage: `url(${vendor.image})` }}>
      {/* Close button absolutely positioned but INSIDE this container */}
      <button 
        onClick={onClose}
        className="absolute top-3 right-3 w-8 h-8 bg-white/90 backdrop-blur rounded-full flex items-center justify-center shadow-lg hover:bg-white transition-colors"
      >
        <X className="w-4 h-4 text-warm-600" />
      </button>
    </div>
    
    {/* Verified badge positioned at bottom of image, overlapping */}
    {vendor.verified && (
      <div className="absolute -bottom-3 left-4">
        <span className="inline-flex items-center gap-1 px-2.5 py-1 bg-haven-500 text-white text-xs font-medium rounded-full shadow-lg">
          <BadgeCheck className="w-3.5 h-3.5" />
          Verified Pro
        </span>
      </div>
    )}
  </div>
  
  {/* Content */}
  <div className="p-4 pt-5">
    <h3 className="font-semibold text-warm-900 text-lg">{vendor.name}</h3>
    <p className="text-warm-500 text-sm">{vendor.category}</p>
    
    {/* Rating */}
    <div className="flex items-center gap-2 mt-2">
      <div className="flex items-center">
        {[...Array(5)].map((_, i) => (
          <Star 
            key={i} 
            className={`w-4 h-4 ${i < Math.floor(vendor.rating) ? 'text-amber-400 fill-amber-400' : 'text-warm-200'}`} 
          />
        ))}
      </div>
      <span className="text-sm text-warm-600">{vendor.rating} ({vendor.reviewCount} reviews)</span>
    </div>
    
    {/* Neighbors */}
    <p className="text-sm text-haven-600 mt-2">
      {vendor.neighborsUsed} neighbors have used this pro
    </p>
    
    {/* Action buttons INSIDE the card */}
    <div className="flex gap-2 mt-4">
      <button className="flex-1 btn-primary text-sm py-2">
        Request Quote
      </button>
      <a 
        href={`tel:${vendor.phone}`}
        className="btn-secondary px-4 py-2"
      >
        <Phone className="w-4 h-4" />
      </a>
    </div>
  </div>
</div>
```

Make sure the popup container has `overflow-hidden` and all child elements are properly nested inside.

---

## FIX 2: UNIQUE VENDOR IMAGES

**File:** `apps/web/src/lib/images.ts`

Add unique images for each vendor category:

```typescript
export const vendorImages = {
  plumbing: [
    'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=400&q=80',
    'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?w=400&q=80',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&q=80',
  ],
  electrical: [
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=400&q=80',
    'https://images.unsplash.com/photo-1555963966-b7ae5404b6ed?w=400&q=80',
    'https://images.unsplash.com/photo-1544724569-5f546fd6f2b5?w=400&q=80',
  ],
  hvac: [
    'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=400&q=80',
    'https://images.unsplash.com/photo-1631545308978-5f0d5f7c0e6a?w=400&q=80',
  ],
  roofing: [
    'https://images.unsplash.com/photo-1632759145351-1d592919f522?w=400&q=80',
    'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=400&q=80',
  ],
  landscaping: [
    'https://images.unsplash.com/photo-1558904541-efa843a96f01?w=400&q=80',
    'https://images.unsplash.com/photo-1592420315809-54c6e9c07b07?w=400&q=80',
    'https://images.unsplash.com/photo-1600585152220-90363fe7e115?w=400&q=80',
  ],
  cleaning: [
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&q=80',
    'https://images.unsplash.com/photo-1628177142898-93e36e4e3a50?w=400&q=80',
  ],
  painting: [
    'https://images.unsplash.com/photo-1562259949-e8e7689d7828?w=400&q=80',
    'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=400&q=80',
  ],
  pool: [
    'https://images.unsplash.com/photo-1575429198097-0414ec08e8cd?w=400&q=80',
    'https://images.unsplash.com/photo-1576013551627-0cc20b96c2a7?w=400&q=80',
  ],
  pest: [
    'https://images.unsplash.com/photo-1609840114035-3c981b782dfe?w=400&q=80',
  ],
  flooring: [
    'https://images.unsplash.com/photo-1581858726788-75bc0f6a952d?w=400&q=80',
    'https://images.unsplash.com/photo-1562663474-6cbb3eaa4d14?w=400&q=80',
  ],
  windows: [
    'https://images.unsplash.com/photo-1604079628040-94301bb21b91?w=400&q=80',
  ],
  security: [
    'https://images.unsplash.com/photo-1558002038-1055907df827?w=400&q=80',
  ],
  general: [
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=400&q=80',
    'https://images.unsplash.com/photo-1581092160562-40aa08e78837?w=400&q=80',
  ],
};

// Get vendor image by category and index for uniqueness
export function getVendorImage(category: string, index: number = 0): string {
  const categoryKey = category.toLowerCase().replace(/[^a-z]/g, '');
  const images = vendorImages[categoryKey as keyof typeof vendorImages] || vendorImages.general;
  return images[index % images.length];
}
```

Then update the vendor list/map to use `getVendorImage(vendor.category, vendorIndex)` for each vendor.

---

## FIX 3: ILLUSTRATED AVATARS (DiceBear)

**File:** `apps/web/src/lib/avatars.ts`

Create a new file for avatar generation:

```typescript
// Use DiceBear for consistent, friendly illustrated avatars
// These generate unique avatars based on a seed (the user's name or ID)

type AvatarStyle = 'avataaars' | 'bottts' | 'initials' | 'lorelei' | 'notionists';

export function getAvatarUrl(
  seed: string, 
  style: AvatarStyle = 'lorelei',
  size: number = 128
): string {
  // DiceBear API - generates consistent avatar for same seed
  // lorelei style is friendly and professional
  // notionists is also good - more illustrated/artistic
  // avataaars is cartoon-like
  
  const encodedSeed = encodeURIComponent(seed.toLowerCase().trim());
  return `https://api.dicebear.com/7.x/${style}/svg?seed=${encodedSeed}&size=${size}&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf`;
}

// Specific avatars for demo users with consistent look
export const demoAvatars = {
  // Homeowners
  'bob': getAvatarUrl('bob-smith-haven', 'lorelei'),
  'bob smith': getAvatarUrl('bob-smith-haven', 'lorelei'),
  'alice': getAvatarUrl('alice-smith-haven', 'lorelei'),
  'alice smith': getAvatarUrl('alice-smith-haven', 'lorelei'),
  'alice johnson': getAvatarUrl('alice-johnson-haven', 'lorelei'),
  
  // Family members
  'emma smith': getAvatarUrl('emma-smith-teen', 'lorelei'),
  'jack smith': getAvatarUrl('jack-smith-kid', 'lorelei'),
  
  // Staff
  'sarah': getAvatarUrl('sarah-harrison-manager', 'lorelei'),
  'sarah harrison': getAvatarUrl('sarah-harrison-manager', 'lorelei'),
  'mike': getAvatarUrl('mike-rodriguez-handy', 'lorelei'),
  'mike rodriguez': getAvatarUrl('mike-rodriguez-handy', 'lorelei'),
  'carlos': getAvatarUrl('carlos-reyes-handy', 'lorelei'),
  'carlos reyes': getAvatarUrl('carlos-reyes-handy', 'lorelei'),
  'maria': getAvatarUrl('maria-santos-handy', 'lorelei'),
  'maria santos': getAvatarUrl('maria-santos-handy', 'lorelei'),
};

export function getUserAvatar(name: string): string {
  const key = name.toLowerCase().trim();
  return demoAvatars[key as keyof typeof demoAvatars] || getAvatarUrl(name, 'lorelei');
}

// For initials fallback (if DiceBear fails)
export function getInitials(name: string): string {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}
```

**Update all avatar usages** across the app to use `getUserAvatar(name)` instead of the Unsplash photos.

**Files to update:**
- `apps/web/src/app/app/layout.tsx`
- `apps/web/src/app/app/page.tsx`
- `apps/web/src/app/app/messages/page.tsx`
- `apps/web/src/app/manager/layout.tsx`
- `apps/web/src/app/manager/page.tsx`
- `apps/web/src/app/manager/conversations/page.tsx`
- `apps/web/src/app/handyman/layout.tsx`
- `apps/web/src/app/handyman/page.tsx`
- Any other file using avatars

Replace patterns like:
```tsx
// OLD
<Image src={images.avatars.sarah} ... />

// NEW
<img src={getUserAvatar('Sarah Harrison')} alt="Sarah Harrison" className="w-10 h-10 rounded-full" />
```

---

## FIX 4: ADD MORE VENDORS TO SEED

**File:** `apps/api/prisma/seed.ts`

Add these vendors to the seed data (in addition to existing ones):

```typescript
// ============================================================================
// COMPREHENSIVE VENDOR SEED DATA
// ============================================================================

const socialVendors = [
  // PLUMBING
  {
    displayName: 'Greenwich Plumbing Co.',
    category: 'PLUMBING',
    phone: '(203) 555-0201',
    email: 'service@greenwichplumbing.example.com',
    rating: 4.9,
    reviewCount: 127,
    neighborsUsed: 23,
    isVerified: true,
    description: 'Family-owned since 1985. Specializing in luxury home plumbing.',
    serviceAreas: ['Greenwich', 'Stamford', 'Darien', 'New Canaan'],
    latitude: 41.0534,
    longitude: -73.6287,
  },
  {
    displayName: 'Drain Masters CT',
    category: 'PLUMBING',
    phone: '(203) 555-0202',
    email: 'help@drainmastersct.example.com',
    rating: 4.7,
    reviewCount: 89,
    neighborsUsed: 15,
    isVerified: true,
    description: '24/7 emergency drain and sewer services.',
    serviceAreas: ['Greenwich', 'Stamford', 'Norwalk'],
    latitude: 41.0612,
    longitude: -73.6512,
  },
  {
    displayName: 'Precision Pipe Works',
    category: 'PLUMBING',
    phone: '(203) 555-0203',
    email: 'info@precisionpipe.example.com',
    rating: 4.8,
    reviewCount: 64,
    neighborsUsed: 8,
    isVerified: false,
    description: 'Specializing in repiping and water heater installation.',
    serviceAreas: ['Greenwich', 'Cos Cob', 'Riverside'],
    latitude: 41.0445,
    longitude: -73.5998,
  },
  
  // ELECTRICAL
  {
    displayName: 'Fairfield Electric',
    category: 'ELECTRICAL',
    phone: '(203) 555-0301',
    email: 'service@fairfieldelectric.example.com',
    rating: 4.9,
    reviewCount: 156,
    neighborsUsed: 31,
    isVerified: true,
    description: 'Licensed master electricians. Smart home specialists.',
    serviceAreas: ['Greenwich', 'Fairfield', 'Westport', 'Darien'],
    latitude: 41.0587,
    longitude: -73.6123,
  },
  {
    displayName: 'PowerPro Electrical',
    category: 'ELECTRICAL',
    phone: '(203) 555-0302',
    email: 'info@powerproelectric.example.com',
    rating: 4.6,
    reviewCount: 78,
    neighborsUsed: 12,
    isVerified: true,
    description: 'Residential and commercial electrical services.',
    serviceAreas: ['Greenwich', 'Stamford', 'New Canaan'],
    latitude: 41.0498,
    longitude: -73.6345,
  },
  {
    displayName: 'Smart Home Wiring',
    category: 'ELECTRICAL',
    phone: '(203) 555-0303',
    email: 'hello@smarthomewiring.example.com',
    rating: 5.0,
    reviewCount: 42,
    neighborsUsed: 7,
    isVerified: true,
    description: 'Lutron, Control4, and Savant certified installers.',
    serviceAreas: ['Greenwich', 'Darien', 'New Canaan'],
    latitude: 41.0623,
    longitude: -73.5876,
  },
  
  // HVAC
  {
    displayName: 'Climate Control CT',
    category: 'HVAC',
    phone: '(203) 555-0401',
    email: 'service@climatect.example.com',
    rating: 4.8,
    reviewCount: 203,
    neighborsUsed: 45,
    isVerified: true,
    description: 'Heating, cooling, and indoor air quality experts.',
    serviceAreas: ['Greenwich', 'Stamford', 'Norwalk', 'Westport'],
    latitude: 41.0556,
    longitude: -73.6234,
  },
  {
    displayName: 'AirFlow HVAC',
    category: 'HVAC',
    phone: '(203) 555-0402',
    email: 'info@airflowhvac.example.com',
    rating: 4.7,
    reviewCount: 91,
    neighborsUsed: 18,
    isVerified: true,
    description: '24/7 emergency HVAC repairs. Carrier & Lennox dealer.',
    serviceAreas: ['Greenwich', 'Stamford', 'Darien'],
    latitude: 41.0478,
    longitude: -73.6098,
  },
  
  // LANDSCAPING
  {
    displayName: 'Country Landscape Design',
    category: 'LANDSCAPING',
    phone: '(203) 555-0501',
    email: 'design@countrylandscape.example.com',
    rating: 4.9,
    reviewCount: 178,
    neighborsUsed: 52,
    isVerified: true,
    description: 'Award-winning landscape architecture and maintenance.',
    serviceAreas: ['Greenwich', 'New Canaan', 'Darien', 'Westport'],
    latitude: 41.0512,
    longitude: -73.6178,
  },
  {
    displayName: 'Green Thumb Gardens',
    category: 'LANDSCAPING',
    phone: '(203) 555-0502',
    email: 'info@greenthumbct.example.com',
    rating: 4.6,
    reviewCount: 134,
    neighborsUsed: 28,
    isVerified: true,
    description: 'Organic lawn care and sustainable landscaping.',
    serviceAreas: ['Greenwich', 'Stamford', 'Riverside'],
    latitude: 41.0589,
    longitude: -73.6312,
  },
  {
    displayName: 'Elite Grounds',
    category: 'LANDSCAPING',
    phone: '(203) 555-0503',
    email: 'service@elitegrounds.example.com',
    rating: 4.8,
    reviewCount: 67,
    neighborsUsed: 14,
    isVerified: false,
    description: 'Luxury estate grounds management.',
    serviceAreas: ['Greenwich', 'Belle Haven', 'Round Hill'],
    latitude: 41.0423,
    longitude: -73.5945,
  },
  
  // ROOFING
  {
    displayName: 'Ace Roofing & Repair',
    category: 'ROOFING',
    phone: '(203) 555-0601',
    email: 'info@aceroofing.example.com',
    rating: 4.8,
    reviewCount: 112,
    neighborsUsed: 19,
    isVerified: true,
    description: 'Slate, tile, and premium roofing specialists.',
    serviceAreas: ['Greenwich', 'Stamford', 'Darien', 'New Canaan'],
    latitude: 41.0534,
    longitude: -73.6287,
  },
  {
    displayName: 'Connecticut Roofing Co.',
    category: 'ROOFING',
    phone: '(203) 555-0602',
    email: 'estimates@ctroofing.example.com',
    rating: 4.5,
    reviewCount: 87,
    neighborsUsed: 11,
    isVerified: true,
    description: 'Full-service roofing, gutters, and siding.',
    serviceAreas: ['Greenwich', 'Norwalk', 'Westport'],
    latitude: 41.0612,
    longitude: -73.6456,
  },
  
  // CLEANING
  {
    displayName: 'Pristine Home Cleaning',
    category: 'CLEANING',
    phone: '(203) 555-0701',
    email: 'book@pristinehome.example.com',
    rating: 4.9,
    reviewCount: 234,
    neighborsUsed: 67,
    isVerified: true,
    description: 'Eco-friendly deep cleaning for luxury homes.',
    serviceAreas: ['Greenwich', 'Stamford', 'Darien', 'New Canaan', 'Westport'],
    latitude: 41.0498,
    longitude: -73.6123,
  },
  {
    displayName: 'Molly Maid of Greenwich',
    category: 'CLEANING',
    phone: '(203) 555-0702',
    email: 'greenwich@mollymaid.example.com',
    rating: 4.7,
    reviewCount: 189,
    neighborsUsed: 43,
    isVerified: true,
    description: 'Trusted nationwide brand. Insured and bonded.',
    serviceAreas: ['Greenwich', 'Stamford', 'Cos Cob'],
    latitude: 41.0567,
    longitude: -73.6234,
  },
  
  // PAINTING
  {
    displayName: 'Artistic Painters CT',
    category: 'PAINTING',
    phone: '(203) 555-0801',
    email: 'quotes@artisticpainters.example.com',
    rating: 4.9,
    reviewCount: 98,
    neighborsUsed: 21,
    isVerified: true,
    description: 'Interior, exterior, and decorative finishes.',
    serviceAreas: ['Greenwich', 'Darien', 'New Canaan'],
    latitude: 41.0523,
    longitude: -73.6178,
  },
  {
    displayName: 'Color Theory Painting',
    category: 'PAINTING',
    phone: '(203) 555-0802',
    email: 'hello@colortheory.example.com',
    rating: 4.8,
    reviewCount: 56,
    neighborsUsed: 9,
    isVerified: false,
    description: 'Color consultation and premium paint application.',
    serviceAreas: ['Greenwich', 'Stamford', 'Westport'],
    latitude: 41.0589,
    longitude: -73.6345,
  },
  
  // POOL SERVICE
  {
    displayName: 'Crystal Clear Pools',
    category: 'POOL',
    phone: '(203) 555-0901',
    email: 'service@crystalclearpools.example.com',
    rating: 4.8,
    reviewCount: 145,
    neighborsUsed: 38,
    isVerified: true,
    description: 'Weekly service, repairs, and renovations.',
    serviceAreas: ['Greenwich', 'Darien', 'New Canaan', 'Westport'],
    latitude: 41.0512,
    longitude: -73.6098,
  },
  {
    displayName: 'Pools Unlimited CT',
    category: 'POOL',
    phone: '(203) 555-0902',
    email: 'info@poolsunlimitedct.example.com',
    rating: 4.6,
    reviewCount: 78,
    neighborsUsed: 16,
    isVerified: true,
    description: 'Pool opening, closing, and maintenance.',
    serviceAreas: ['Greenwich', 'Stamford', 'Norwalk'],
    latitude: 41.0478,
    longitude: -73.6234,
  },
  
  // PEST CONTROL
  {
    displayName: 'Terminix Northeast',
    category: 'PEST_CONTROL',
    phone: '(203) 555-1001',
    email: 'schedule@terminix.example.com',
    rating: 4.5,
    reviewCount: 167,
    neighborsUsed: 29,
    isVerified: true,
    description: 'Pest control and termite protection.',
    serviceAreas: ['Greenwich', 'Stamford', 'Norwalk', 'Westport', 'Darien'],
    latitude: 41.0556,
    longitude: -73.6312,
  },
  {
    displayName: 'EcoShield Pest Solutions',
    category: 'PEST_CONTROL',
    phone: '(203) 555-1002',
    email: 'help@ecoshieldpest.example.com',
    rating: 4.7,
    reviewCount: 54,
    neighborsUsed: 8,
    isVerified: false,
    description: 'Organic and pet-friendly pest control.',
    serviceAreas: ['Greenwich', 'Stamford', 'Darien'],
    latitude: 41.0498,
    longitude: -73.6178,
  },
  
  // FLOORING
  {
    displayName: 'Hardwood Flooring Pros',
    category: 'FLOORING',
    phone: '(203) 555-1101',
    email: 'info@hardwoodpros.example.com',
    rating: 4.9,
    reviewCount: 89,
    neighborsUsed: 17,
    isVerified: true,
    description: 'Installation, refinishing, and restoration.',
    serviceAreas: ['Greenwich', 'Darien', 'New Canaan', 'Westport'],
    latitude: 41.0534,
    longitude: -73.6123,
  },
  {
    displayName: 'Stone & Tile Masters',
    category: 'FLOORING',
    phone: '(203) 555-1102',
    email: 'quotes@stonetile.example.com',
    rating: 4.8,
    reviewCount: 67,
    neighborsUsed: 12,
    isVerified: true,
    description: 'Marble, granite, and custom tile work.',
    serviceAreas: ['Greenwich', 'Stamford', 'Darien'],
    latitude: 41.0589,
    longitude: -73.6287,
  },
  
  // WINDOWS & DOORS
  {
    displayName: 'Window World CT',
    category: 'WINDOWS',
    phone: '(203) 555-1201',
    email: 'sales@windowworldct.example.com',
    rating: 4.6,
    reviewCount: 134,
    neighborsUsed: 24,
    isVerified: true,
    description: 'Energy-efficient window replacement.',
    serviceAreas: ['Greenwich', 'Stamford', 'Norwalk', 'Westport'],
    latitude: 41.0512,
    longitude: -73.6345,
  },
  
  // SECURITY
  {
    displayName: 'SafeHome Security',
    category: 'SECURITY',
    phone: '(203) 555-1301',
    email: 'install@safehome.example.com',
    rating: 4.8,
    reviewCount: 78,
    neighborsUsed: 19,
    isVerified: true,
    description: 'Smart home security and monitoring.',
    serviceAreas: ['Greenwich', 'Darien', 'New Canaan', 'Stamford'],
    latitude: 41.0478,
    longitude: -73.6098,
  },
  
  // GENERAL HANDYMAN
  {
    displayName: 'Mr. Fix It Greenwich',
    category: 'GENERAL',
    phone: '(203) 555-1401',
    email: 'help@mrfixitgreenwich.example.com',
    rating: 4.7,
    reviewCount: 203,
    neighborsUsed: 56,
    isVerified: true,
    description: 'No job too small. Honey-do list specialists.',
    serviceAreas: ['Greenwich', 'Stamford', 'Cos Cob', 'Riverside'],
    latitude: 41.0556,
    longitude: -73.6178,
  },
  {
    displayName: 'Handy Helpers CT',
    category: 'GENERAL',
    phone: '(203) 555-1402',
    email: 'book@handyhelpersct.example.com',
    rating: 4.5,
    reviewCount: 145,
    neighborsUsed: 32,
    isVerified: false,
    description: 'Assembly, mounting, and minor repairs.',
    serviceAreas: ['Greenwich', 'Stamford', 'Norwalk'],
    latitude: 41.0523,
    longitude: -73.6234,
  },
];

// Create all vendors in the database
for (let i = 0; i < socialVendors.length; i++) {
  const v = socialVendors[i];
  await prisma.socialVendor.upsert({
    where: { id: `social-vendor-${i + 1}` },
    update: {},
    create: {
      id: `social-vendor-${i + 1}`,
      displayName: v.displayName,
      category: v.category,
      phone: v.phone,
      email: v.email,
      rating: v.rating,
      reviewCount: v.reviewCount,
      neighborsUsed: v.neighborsUsed,
      isVerified: v.isVerified,
      description: v.description,
      serviceAreas: v.serviceAreas,
      latitude: v.latitude,
      longitude: v.longitude,
      imageIndex: i, // Use this to get unique image
    },
  });
}
console.log(`  ✓ Created ${socialVendors.length} social vendors`);
```

If the SocialVendor model doesn't exist, create it or adapt to existing vendor schema.

---

## FIX 5: PROJECT PLANNING OVERHAUL

The project planning feature needs a complete redesign. Currently clicking "Kitchen Backsplash" just shows a photo - it needs a full project workflow.

**File:** `apps/web/src/app/app/projects/page.tsx` (create if doesn't exist)

Create a project list page:

```tsx
// Projects List Page
export default function ProjectsPage() {
  return (
    <div className="space-y-6 animate-fade-in">
      <PageHeader 
        title="Home Projects"
        description="Plan and track improvements to your home"
      >
        <Button>
          <Plus className="w-4 h-4" />
          New Project
        </Button>
      </PageHeader>
      
      {/* Project Status Tabs */}
      <div className="flex gap-2 border-b border-warm-200 pb-2">
        <button className="px-4 py-2 text-sm font-medium text-haven-600 border-b-2 border-haven-600">
          Active (2)
        </button>
        <button className="px-4 py-2 text-sm font-medium text-warm-500 hover:text-warm-700">
          Planning (1)
        </button>
        <button className="px-4 py-2 text-sm font-medium text-warm-500 hover:text-warm-700">
          Completed (3)
        </button>
      </div>
      
      {/* Project Cards */}
      <div className="grid md:grid-cols-2 gap-6">
        {projects.map(project => (
          <ProjectCard key={project.id} project={project} />
        ))}
      </div>
    </div>
  );
}
```

**File:** `apps/web/src/app/app/projects/[id]/page.tsx`

Create detailed project page:

```tsx
// Project Detail Page
export default function ProjectDetailPage({ params }: { params: { id: string } }) {
  // Demo: Kitchen Backsplash project
  const project = {
    id: params.id,
    title: 'Kitchen Backsplash Upgrade',
    status: 'IN_PROGRESS',
    description: 'Replace dated backsplash with classic white subway tile and gray grout.',
    createdAt: '2024-12-15',
    budget: { min: 2000, max: 3500 },
    manager: 'Sarah Harrison',
    
    // Project phases
    phases: [
      {
        name: 'Discovery & Planning',
        status: 'COMPLETED',
        items: [
          { title: 'Initial consultation with Sarah', status: 'DONE', date: 'Dec 15' },
          { title: 'Style selection (subway tile, gray grout)', status: 'DONE', date: 'Dec 16' },
          { title: 'Mood board created', status: 'DONE', date: 'Dec 17' },
        ],
      },
      {
        name: 'Vendor Selection',
        status: 'IN_PROGRESS',
        items: [
          { title: 'Get quotes from tile contractors', status: 'DONE', date: 'Dec 18' },
          { title: 'Review quotes with homeowner', status: 'IN_PROGRESS', date: 'Dec 20' },
          { title: 'Select contractor', status: 'PENDING' },
          { title: 'Schedule installation', status: 'PENDING' },
        ],
      },
      {
        name: 'Execution',
        status: 'PENDING',
        items: [
          { title: 'Materials delivery', status: 'PENDING' },
          { title: 'Demo existing backsplash', status: 'PENDING' },
          { title: 'Install new tile', status: 'PENDING' },
          { title: 'Grouting and sealing', status: 'PENDING' },
          { title: 'Final cleanup', status: 'PENDING' },
        ],
      },
      {
        name: 'Completion',
        status: 'PENDING',
        items: [
          { title: 'Final walkthrough', status: 'PENDING' },
          { title: 'Homeowner approval', status: 'PENDING' },
          { title: 'Process payment', status: 'PENDING' },
        ],
      },
    ],
    
    // Quotes received
    quotes: [
      { vendor: 'Stone & Tile Masters', amount: 2800, status: 'RECEIVED', recommended: true },
      { vendor: 'Greenwich Tile Co.', amount: 3200, status: 'RECEIVED' },
      { vendor: 'Custom Tile Works', amount: 2650, status: 'PENDING' },
    ],
    
    // Messages/updates
    updates: [
      { date: 'Dec 20', from: 'Sarah Harrison', message: 'Stone & Tile Masters came highly recommended by the Hendersons. Their quote is competitive and includes premium materials.' },
      { date: 'Dec 18', from: 'Sarah Harrison', message: 'Sent quote requests to 3 tile contractors. Expecting responses within 48 hours.' },
      { date: 'Dec 17', from: 'Sarah Harrison', message: 'Created mood board based on your preferences. Classic and timeless!' },
    ],
    
    // Inspiration images
    inspirationImages: [
      'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&q=80',
      'https://images.unsplash.com/photo-1556909172-54557c7e4fb7?w=400&q=80',
      'https://images.unsplash.com/photo-1556909190-6a308e16d62e?w=400&q=80',
    ],
  };

  return (
    <div className="space-y-8 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between">
        <div>
          <Link href="/app/projects" className="text-sm text-haven-600 hover:underline mb-2 inline-block">
            ← Back to Projects
          </Link>
          <h1 className="text-3xl font-bold text-warm-900 font-serif">{project.title}</h1>
          <p className="text-warm-500 mt-1">{project.description}</p>
        </div>
        <Badge variant="warning" size="lg">In Progress</Badge>
      </div>
      
      {/* Progress Overview */}
      <Card>
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-semibold text-warm-900">Project Progress</h2>
          <span className="text-sm text-warm-500">50% Complete</span>
        </div>
        <div className="w-full h-2 bg-warm-100 rounded-full overflow-hidden">
          <div className="h-full bg-haven-500 rounded-full" style={{ width: '50%' }} />
        </div>
        
        {/* Phase Timeline */}
        <div className="mt-6 space-y-6">
          {project.phases.map((phase, i) => (
            <div key={i} className="relative pl-8">
              {/* Timeline line */}
              {i < project.phases.length - 1 && (
                <div className="absolute left-3 top-8 bottom-0 w-0.5 bg-warm-200" />
              )}
              
              {/* Phase dot */}
              <div className={`absolute left-0 top-1 w-6 h-6 rounded-full flex items-center justify-center ${
                phase.status === 'COMPLETED' ? 'bg-haven-500 text-white' :
                phase.status === 'IN_PROGRESS' ? 'bg-amber-500 text-white' :
                'bg-warm-200 text-warm-500'
              }`}>
                {phase.status === 'COMPLETED' ? <Check className="w-4 h-4" /> : 
                 phase.status === 'IN_PROGRESS' ? <Clock className="w-4 h-4" /> :
                 <span className="text-xs">{i + 1}</span>}
              </div>
              
              {/* Phase content */}
              <div>
                <h3 className="font-medium text-warm-900">{phase.name}</h3>
                <ul className="mt-2 space-y-2">
                  {phase.items.map((item, j) => (
                    <li key={j} className="flex items-center gap-2 text-sm">
                      <span className={`w-4 h-4 rounded-full flex items-center justify-center ${
                        item.status === 'DONE' ? 'bg-haven-100 text-haven-600' :
                        item.status === 'IN_PROGRESS' ? 'bg-amber-100 text-amber-600' :
                        'bg-warm-100 text-warm-400'
                      }`}>
                        {item.status === 'DONE' ? <Check className="w-3 h-3" /> : null}
                      </span>
                      <span className={item.status === 'DONE' ? 'text-warm-500 line-through' : 'text-warm-700'}>
                        {item.title}
                      </span>
                      {item.date && (
                        <span className="text-xs text-warm-400 ml-auto">{item.date}</span>
                      )}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          ))}
        </div>
      </Card>
      
      {/* Two Column Layout */}
      <div className="grid lg:grid-cols-3 gap-6">
        {/* Quotes */}
        <Card className="lg:col-span-2">
          <h2 className="font-semibold text-warm-900 mb-4">Quotes Received</h2>
          <div className="space-y-3">
            {project.quotes.map((quote, i) => (
              <div key={i} className={`p-4 rounded-xl border ${quote.recommended ? 'border-haven-200 bg-haven-50' : 'border-warm-200'}`}>
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-medium text-warm-900">{quote.vendor}</div>
                    {quote.recommended && (
                      <span className="text-xs text-haven-600 font-medium">★ Recommended by Sarah</span>
                    )}
                  </div>
                  <div className="text-right">
                    <div className="text-lg font-bold text-warm-900">${quote.amount.toLocaleString()}</div>
                    <Badge variant={quote.status === 'RECEIVED' ? 'success' : 'neutral'} size="sm">
                      {quote.status}
                    </Badge>
                  </div>
                </div>
              </div>
            ))}
          </div>
          
          <div className="mt-4 flex gap-3">
            <Button variant="primary">Select Stone & Tile Masters</Button>
            <Button variant="secondary">Request More Quotes</Button>
          </div>
        </Card>
        
        {/* Inspiration */}
        <Card>
          <h2 className="font-semibold text-warm-900 mb-4">Inspiration Board</h2>
          <div className="grid grid-cols-2 gap-2">
            {project.inspirationImages.map((img, i) => (
              <div key={i} className="aspect-square rounded-lg overflow-hidden bg-warm-100">
                <img src={img} alt="" className="w-full h-full object-cover" />
              </div>
            ))}
            <button className="aspect-square rounded-lg border-2 border-dashed border-warm-300 flex items-center justify-center text-warm-400 hover:border-haven-400 hover:text-haven-600 transition-colors">
              <Plus className="w-6 h-6" />
            </button>
          </div>
        </Card>
      </div>
      
      {/* Updates */}
      <Card>
        <h2 className="font-semibold text-warm-900 mb-4">Project Updates</h2>
        <div className="space-y-4">
          {project.updates.map((update, i) => (
            <div key={i} className="flex gap-4 pb-4 border-b border-warm-100 last:border-0">
              <img 
                src={getUserAvatar(update.from)} 
                alt={update.from}
                className="w-10 h-10 rounded-full"
              />
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-medium text-warm-900">{update.from}</span>
                  <span className="text-xs text-warm-400">{update.date}</span>
                </div>
                <p className="text-warm-600 mt-1">{update.message}</p>
              </div>
            </div>
          ))}
        </div>
        
        {/* Reply box */}
        <div className="mt-4 pt-4 border-t border-warm-100">
          <textarea 
            placeholder="Add a comment or ask Sarah a question..."
            className="input min-h-[80px] resize-none"
          />
          <div className="flex justify-end mt-2">
            <Button>Send Message</Button>
          </div>
        </div>
      </Card>
    </div>
  );
}
```

Add projects to navigation and seed data.

---

## FIX 6: FONT CONSISTENCY

The issue is that `font-serif` (Playfair Display) is only applied to h1-h6 tags. Text inside cards using `<span>` or `<p>` uses the default sans-serif.

**File:** `apps/web/src/app/globals.css`

The fonts ARE intentional - headings use serif (elegant), body uses sans (readable). But if you want specific elements to use serif, add the class explicitly.

For consistent heading style inside cards, ensure you use proper heading tags or add `font-serif`:

```tsx
// In card components, use actual heading tags:
<h3 className="font-serif text-lg font-semibold text-warm-900">Sarah is handling 10 items</h3>
<p className="text-warm-500">3 orders in progress</p>

// Or explicitly add font-serif class:
<span className="font-serif font-semibold text-warm-900">Sarah is handling 10 items</span>
```

**Update these files** to ensure headings inside cards use `font-serif`:
- Dashboard stat card titles
- Card headers
- Any prominent text that should look elegant

Look for patterns like:
```tsx
// BEFORE (inconsistent)
<div className="font-semibold text-warm-900">Title</div>

// AFTER (consistent serif heading)
<h3 className="text-lg font-semibold text-warm-900">Title</h3>
// OR
<div className="font-serif font-semibold text-warm-900">Title</div>
```

---

## FIX 7: FAMILY PAGE - ADD ALICE AND KIDS

**File:** `apps/api/prisma/seed.ts`

Add family members to Bob's household:

```typescript
// ============================================================================
// HOUSEHOLD MEMBERS (FAMILY)
// ============================================================================

console.log('');
console.log('👨‍👩‍👧‍👦 Setting up family members...');

// Bob (already exists as homeowner)
await prisma.householdMember.upsert({
  where: { id: 'member-bob' },
  update: {},
  create: {
    id: 'member-bob',
    householdId: demoHousehold.id,
    userId: homeownerBob.id,
    firstName: 'Bob',
    lastName: 'Smith',
    relationship: 'HEAD_OF_HOUSEHOLD',
    email: 'bob@example.com',
    phone: '+1 (203) 555-0001',
    dateOfBirth: new Date('1978-03-15'),
    isEmergencyContact: true,
    isPrimaryContact: true,
  },
});

// Alice - Wife
await prisma.householdMember.upsert({
  where: { id: 'member-alice' },
  update: {},
  create: {
    id: 'member-alice',
    householdId: demoHousehold.id,
    firstName: 'Alice',
    lastName: 'Smith',
    relationship: 'SPOUSE',
    email: 'alice.smith@example.com',
    phone: '+1 (203) 555-0002',
    dateOfBirth: new Date('1980-07-22'),
    isEmergencyContact: true,
    isPrimaryContact: false,
  },
});

// Emma - Daughter (14)
await prisma.householdMember.upsert({
  where: { id: 'member-emma' },
  update: {},
  create: {
    id: 'member-emma',
    householdId: demoHousehold.id,
    firstName: 'Emma',
    lastName: 'Smith',
    relationship: 'CHILD',
    dateOfBirth: new Date('2010-09-10'),
    notes: 'PADI Open Water certified diver. Allergic to shellfish.',
  },
});

// Jack - Son (10)
await prisma.householdMember.upsert({
  where: { id: 'member-jack' },
  update: {},
  create: {
    id: 'member-jack',
    householdId: demoHousehold.id,
    firstName: 'Jack',
    lastName: 'Smith',
    relationship: 'CHILD',
    dateOfBirth: new Date('2014-04-05'),
    notes: 'Plays soccer. Nut allergy (carries EpiPen).',
  },
});

// Max - Family dog
await prisma.householdMember.upsert({
  where: { id: 'member-max' },
  update: {},
  create: {
    id: 'member-max',
    householdId: demoHousehold.id,
    firstName: 'Max',
    relationship: 'PET',
    notes: 'Golden Retriever, 5 years old. Vet: Greenwich Animal Hospital (203-555-8888). Microchip #: 985112345678901',
  },
});

console.log('  ✓ Created 5 household members (Bob, Alice, Emma, Jack, Max)');
```

**File:** `apps/web/src/app/app/family/page.tsx`

Update the family page to show all members:

```tsx
// Family Page
export default function FamilyPage() {
  const familyMembers = [
    {
      id: 'bob',
      name: 'Bob Smith',
      relationship: 'Head of Household',
      avatar: getUserAvatar('Bob Smith'),
      email: 'bob@example.com',
      phone: '+1 (203) 555-0001',
      birthday: 'March 15',
      isPrimary: true,
      isEmergency: true,
    },
    {
      id: 'alice',
      name: 'Alice Smith',
      relationship: 'Spouse',
      avatar: getUserAvatar('Alice Smith'),
      email: 'alice.smith@example.com',
      phone: '+1 (203) 555-0002',
      birthday: 'July 22',
      isPrimary: false,
      isEmergency: true,
    },
    {
      id: 'emma',
      name: 'Emma Smith',
      relationship: 'Daughter',
      avatar: getUserAvatar('Emma Smith'),
      birthday: 'September 10 (14 years old)',
      notes: 'PADI Open Water certified. Allergic to shellfish.',
    },
    {
      id: 'jack',
      name: 'Jack Smith',
      relationship: 'Son',
      avatar: getUserAvatar('Jack Smith'),
      birthday: 'April 5 (10 years old)',
      notes: 'Plays soccer. Nut allergy (carries EpiPen).',
    },
    {
      id: 'max',
      name: 'Max',
      relationship: 'Family Pet',
      avatar: getUserAvatar('Max the dog'),
      notes: 'Golden Retriever, 5 years old',
      vet: 'Greenwich Animal Hospital • (203) 555-8888',
    },
  ];

  return (
    <div className="space-y-6 animate-fade-in">
      <PageHeader 
        title="Family"
        description="Manage your household members and their information"
      >
        <Button>
          <Plus className="w-4 h-4" />
          Add Family Member
        </Button>
      </PageHeader>
      
      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {familyMembers.map(member => (
          <Card key={member.id} className="card-hover">
            <div className="flex items-start gap-4">
              <img 
                src={member.avatar} 
                alt={member.name}
                className="w-16 h-16 rounded-full"
              />
              <div className="flex-1">
                <h3 className="font-serif font-semibold text-warm-900">{member.name}</h3>
                <p className="text-sm text-haven-600">{member.relationship}</p>
                
                {member.birthday && (
                  <p className="text-sm text-warm-500 mt-2">
                    🎂 {member.birthday}
                  </p>
                )}
                
                {member.email && (
                  <p className="text-sm text-warm-500 mt-1">
                    ✉️ {member.email}
                  </p>
                )}
                
                {member.phone && (
                  <p className="text-sm text-warm-500">
                    📱 {member.phone}
                  </p>
                )}
                
                {member.notes && (
                  <p className="text-sm text-warm-600 mt-2 p-2 bg-warm-50 rounded-lg">
                    {member.notes}
                  </p>
                )}
                
                {member.vet && (
                  <p className="text-sm text-warm-500 mt-1">
                    🏥 {member.vet}
                  </p>
                )}
              </div>
            </div>
            
            <div className="flex gap-2 mt-4 pt-4 border-t border-warm-100">
              {member.isPrimary && (
                <Badge variant="info">Primary Contact</Badge>
              )}
              {member.isEmergency && (
                <Badge variant="warning">Emergency Contact</Badge>
              )}
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
```

---

## SUMMARY OF CHANGES

| Issue | Fix |
|-------|-----|
| Vendor map card overflow | Restructure card with proper nesting, `overflow-hidden` |
| Same vendor photos | Add unique images per category in `images.ts` |
| Real photo avatars | Switch to DiceBear illustrated avatars |
| Not enough vendors | Add 25+ vendors across all categories |
| Project planning broken | Build full project workflow with phases, quotes, updates |
| Font inconsistency | Use `font-serif` class on card headings |
| Family missing Alice | Add Alice, Emma, Jack, Max to seed + update family page |

---

## RUN ORDER

1. Paste this prompt into Claude Code
2. After completion, run:

```bash
cd apps/api
pnpm prisma db push --force-reset
pnpm prisma db seed
pnpm dev

# In second terminal
cd apps/web
pnpm dev
```

3. Test at http://localhost:3000

🏠✨

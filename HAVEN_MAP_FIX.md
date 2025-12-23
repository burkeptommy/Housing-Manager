# Find Pros Map - DIRECT FIX

## Run in Claude Code:
```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Then paste this entire prompt.

---

## ISSUE 1: Map zoom, center, and style

**File:** `apps/web/src/app/app/community/page.tsx`

Find this code (around line 580):
```tsx
<Map
  ref={mapRef}
  mapboxAccessToken={MAPBOX_TOKEN}
  initialViewState={{
    latitude: currentUserLocation.lat,
    longitude: currentUserLocation.lng,
    zoom: 13,
  }}
  style={{ width: '100%', height: '100%' }}
  mapStyle="mapbox://styles/mapbox/light-v11"
>
```

**Replace with:**
```tsx
<Map
  ref={mapRef}
  mapboxAccessToken={MAPBOX_TOKEN}
  initialViewState={{
    latitude: 41.08,
    longitude: -73.60,
    zoom: 9.5,
    pitch: 45,
    bearing: -15,
  }}
  style={{ width: '100%', height: '100%' }}
  mapStyle="mapbox://styles/mapbox/standard"
>
```

---

## ISSUE 2: Vendor locations are too clustered

Find `currentUserLocation` (around line 96):
```tsx
const currentUserLocation = { lat: 41.0534, lng: -73.5387 };
```

**Replace with:**
```tsx
const currentUserLocation = { lat: 41.0534, lng: -73.6287 }; // Greenwich, CT
```

Now find the `mockVendors` array and **replace ALL vendor locations** with these spread-out coordinates:

```tsx
const mockVendors: Vendor[] = [
  {
    id: 'v1',
    name: "Mike's Plumbing Pro",
    // ... keep all other fields ...
    location: { lat: 41.0534, lng: -73.6287 }, // Greenwich
    address: 'Greenwich, CT',
    distance: 0.0,
  },
  {
    id: 'v2',
    name: 'Country Landscape Design',
    // ... keep all other fields ...
    location: { lat: 41.1415, lng: -73.3579 }, // Westport, CT
    address: 'Westport, CT',
    distance: 15.2,
  },
  {
    id: 'v3',
    name: 'Elite Electric Services',
    // ... keep all other fields ...
    location: { lat: 41.0340, lng: -73.7629 }, // White Plains, NY
    address: 'White Plains, NY',
    distance: 8.5,
  },
  {
    id: 'v4',
    name: 'Comfort Zone HVAC',
    // ... keep all other fields ...
    location: { lat: 40.9887, lng: -73.7846 }, // Scarsdale, NY
    address: 'Scarsdale, NY',
    distance: 10.2,
  },
  {
    id: 'v5',
    name: 'Perfect Painters LLC',
    // ... keep all other fields ...
    location: { lat: 41.0787, lng: -73.4698 }, // Darien, CT
    address: 'Darien, CT',
    distance: 9.8,
  },
  {
    id: 'v6',
    name: 'Handy Dan Services',
    // ... keep all other fields ...
    location: { lat: 40.9807, lng: -73.6835 }, // Rye, NY
    address: 'Rye, NY',
    distance: 5.1,
  },
  {
    id: 'v7',
    name: 'Ace Roofing Co.',
    // ... keep all other fields ...
    location: { lat: 41.0534, lng: -73.5387 }, // Stamford, CT
    address: 'Stamford, CT',
    distance: 5.5,
  },
  {
    id: 'v8',
    name: 'Top Notch Roofing',
    // ... keep all other fields ...
    location: { lat: 41.1468, lng: -73.4948 }, // New Canaan, CT
    address: 'New Canaan, CT',
    distance: 11.3,
  },
  {
    id: 'v9',
    name: 'Sparkle Clean CT',
    // ... keep all other fields ...
    location: { lat: 41.1265, lng: -73.7140 }, // Armonk, NY
    address: 'Armonk, NY',
    distance: 9.8,
  },
  {
    id: 'v10',
    name: 'Molly Maid Greenwich',
    // ... keep all other fields ...
    location: { lat: 41.1412, lng: -73.2637 }, // Fairfield, CT
    address: 'Fairfield, CT',
    distance: 20.5,
  },
  {
    id: 'v11',
    name: 'Quick Fix Plumbing',
    // ... keep all other fields ...
    location: { lat: 41.0762, lng: -73.8587 }, // Tarrytown, NY
    address: 'Tarrytown, NY',
    distance: 15.2,
  },
  {
    id: 'v12',
    name: 'Premium Plumbing Solutions',
    // ... keep all other fields ...
    location: { lat: 41.1177, lng: -73.4082 }, // Norwalk, CT
    address: 'Norwalk, CT',
    distance: 12.8,
  },
  {
    id: 'v13',
    name: 'Bright Spark Electric',
    // ... keep all other fields ...
    location: { lat: 41.2045, lng: -73.6437 }, // Bedford, NY
    address: 'Bedford, NY',
    distance: 11.5,
  },
  {
    id: 'v14',
    name: 'Tesla Certified Electricians',
    // ... keep all other fields ...
    location: { lat: 41.2815, lng: -73.4984 }, // Ridgefield, CT
    address: 'Ridgefield, CT',
    distance: 18.2,
  },
  {
    id: 'v15',
    name: 'Green Thumb Gardens',
    // ... keep all other fields ...
    location: { lat: 40.9401, lng: -73.8321 }, // Bronxville, NY
    address: 'Bronxville, NY',
    distance: 14.5,
  },
  {
    id: 'v16',
    name: 'Estate Grounds Maintenance',
    // ... keep all other fields ...
    location: { lat: 41.1595, lng: -73.7651 }, // Chappaqua, NY
    address: 'Chappaqua, NY',
    distance: 13.8,
  },
  {
    id: 'v17',
    name: 'Arctic Air HVAC',
    // ... keep all other fields ...
    location: { lat: 40.9487, lng: -73.7324 }, // Mamaroneck, NY
    address: 'Mamaroneck, NY',
    distance: 9.2,
  },
  {
    id: 'v18',
    name: 'Brush Masters Painting',
    // ... keep all other fields ...
    location: { lat: 41.1954, lng: -73.4379 }, // Wilton, CT
    address: 'Wilton, CT',
    distance: 14.5,
  },
  {
    id: 'v19',
    name: 'Fine Finish Painters',
    // ... keep all other fields ...
    location: { lat: 40.9276, lng: -73.7518 }, // Larchmont, NY
    address: 'Larchmont, NY',
    distance: 11.8,
  },
  {
    id: 'v20',
    name: 'Mr. Fix-It Greenwich',
    // ... keep all other fields ...
    location: { lat: 41.0018, lng: -73.6657 }, // Port Chester, NY
    address: 'Port Chester, NY',
    distance: 3.5,
  },
  {
    id: 'v21',
    name: 'Home Pro Services',
    // ... keep all other fields ...
    location: { lat: 40.9115, lng: -73.7824 }, // New Rochelle, NY
    address: 'New Rochelle, NY',
    distance: 12.5,
  },
  {
    id: 'v22',
    name: 'Pool Paradise CT',
    // ... keep all other fields ...
    location: { lat: 41.0154, lng: -73.8726 }, // Dobbs Ferry, NY
    address: 'Dobbs Ferry, NY',
    distance: 16.8,
  },
  {
    id: 'v23',
    name: 'Security Systems Plus',
    // ... keep all other fields ...
    location: { lat: 41.3948, lng: -73.4540 }, // Danbury, CT
    address: 'Danbury, CT',
    distance: 25.5,
  },
  {
    id: 'v24',
    name: 'Window World CT',
    // ... keep all other fields ...
    location: { lat: 41.2048, lng: -73.7271 }, // Mount Kisco, NY
    address: 'Mount Kisco, NY',
    distance: 14.2,
  },
  {
    id: 'v25',
    name: 'Floor Masters LLC',
    // ... keep all other fields ...
    location: { lat: 41.1365, lng: -73.2834 }, // Southport, CT
    address: 'Southport, CT',
    distance: 19.8,
  },
  {
    id: 'v26',
    name: 'Garage Door Experts',
    // ... keep all other fields ...
    location: { lat: 41.0190, lng: -73.7982 }, // Hartsdale, NY
    address: 'Hartsdale, NY',
    distance: 11.5,
  },
];
```

---

## ISSUE 3: Popup card buttons overflow

Find the `VendorPopup` component (around line 650) and **replace the entire function** with:

```tsx
function VendorPopup({ vendor }: { vendor: Vendor }) {
  return (
    <div className="w-72 p-0">
      {/* Card container with proper overflow handling */}
      <div className="bg-white rounded-lg overflow-hidden">
        {/* Vendor info */}
        <div className="p-3">
          <div className="flex items-start gap-3">
            <img
              src={getVendorAvatar(vendor.name)}
              alt={vendor.name}
              className="w-11 h-11 rounded-lg flex-shrink-0"
            />
            <div className="flex-1 min-w-0">
              <h3 className="font-semibold text-warm-900 text-sm leading-tight">{vendor.name}</h3>
              {vendor.havenTrusted && (
                <span className="inline-flex items-center gap-1 mt-1 px-1.5 py-0.5 bg-haven-100 text-haven-700 text-xs font-medium rounded">
                  <Shield className="w-3 h-3" />
                  Haven Trusted
                </span>
              )}
              <div className="flex items-center gap-1.5 text-xs text-warm-500 mt-1">
                <Star className="w-3 h-3 text-amber-500 fill-current" />
                <span>{vendor.rating}</span>
                <span>•</span>
                <span>{vendor.reviewCount} reviews</span>
              </div>
            </div>
          </div>
          
          {/* Stats */}
          <div className="mt-3 flex items-center gap-4 text-xs text-warm-600">
            <div className="flex items-center gap-1">
              <Users className="w-3 h-3" />
              <span>{vendor.neighborsUsed} neighbors</span>
            </div>
            <div className="flex items-center gap-1">
              <MapPin className="w-3 h-3" />
              <span>{vendor.distance} mi</span>
            </div>
          </div>
        </div>
        
        {/* Buttons - inside the card with proper containment */}
        <div className="px-3 pb-3 flex gap-2">
          <button className="flex-1 px-3 py-2 bg-haven-600 text-white text-sm font-medium rounded-lg hover:bg-haven-700 transition-colors">
            Request Quote
          </button>
          <a
            href={`tel:${vendor.phone}`}
            className="px-3 py-2 border border-warm-300 rounded-lg hover:bg-warm-50 transition-colors flex items-center justify-center"
          >
            <Phone className="w-4 h-4 text-warm-600" />
          </a>
        </div>
      </div>
    </div>
  );
}
```

---

## ISSUE 4: Add CSS fix for Mapbox popup

**File:** `apps/web/src/app/globals.css`

Add this at the end of the file:

```css
/* Fix Mapbox popup styling */
.mapboxgl-popup-content {
  padding: 0 !important;
  border-radius: 12px !important;
  overflow: hidden !important;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15) !important;
}

.mapboxgl-popup-close-button {
  font-size: 18px !important;
  padding: 4px 8px !important;
  color: #666 !important;
  right: 4px !important;
  top: 4px !important;
}

.mapboxgl-popup-close-button:hover {
  background: rgba(0, 0, 0, 0.05) !important;
  border-radius: 4px !important;
}

.mapboxgl-popup-tip {
  display: none !important;
}
```

---

## SUMMARY OF CHANGES

1. **Map View**: Zoom 9.5, centered at (41.08, -73.60) to show both Westchester NY and Fairfield CT, 3D pitch at 45°, Mapbox Standard style

2. **Vendor Locations**: All 26 vendors spread across:
   - **Fairfield County CT**: Greenwich, Stamford, Darien, Norwalk, Westport, Fairfield, Southport, New Canaan, Wilton, Ridgefield, Danbury
   - **Westchester County NY**: Rye, Port Chester, Mamaroneck, Larchmont, New Rochelle, Scarsdale, White Plains, Bronxville, Hartsdale, Tarrytown, Dobbs Ferry, Armonk, Chappaqua, Bedford, Mount Kisco

3. **Popup Card**: Restructured with proper containment - buttons now inside the card, no overflow

4. **CSS**: Global fix for Mapbox popup padding and close button styling

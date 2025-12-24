# Haven Link Preview (Open Graph Image)

## GOAL

Create a beautiful, elegant link preview for when Haven is shared on iMessage, Slack, Twitter, LinkedIn, etc. Should match the new navy + champagne brand and instantly communicate value.

---

## CURRENT STATE

File exists at: `apps/web/src/app/opengraph-image.tsx`
Currently uses old green branding.

---

## NEW DESIGN

### Visual Concept

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│  ░░░░░░░░░░░░░░░░░░ NAVY GRADIENT ░░░░░░░░░░░░░░░░░░░░░░░  │
│  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │
│                                                            │
│         ┌──────┐                                           │
│         │ LOGO │  Haven                                    │
│         └──────┘                                           │
│                                                            │
│         Stop satisfying your home.                          │
│         Start living in it.          ← Champagne accent    │
│                                                            │
│         ─────────────────────────                          │
│                                                            │
│         One payment. One text. Everything handled.         │
│                                                            │
│         ┌─────────┐ ┌─────────┐ ┌─────────┐               │
│         │ 8+ hrs  │ │  500+   │ │  4.9★   │               │
│         │ saved   │ │families │ │ rating  │               │
│         └─────────┘ └─────────┘ └─────────┘               │
│                                                            │
│  ░░░░░░░░░░░░░░░░ Subtle champagne glow ░░░░░░░░░░░░░░░░  │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### Specifications

- **Size:** 1200 x 630 pixels (standard OG size)
- **Background:** Navy gradient (`#1E2A3B` → `#111827`)
- **Accent:** Champagne (`#D4C5A9`) for highlight text
- **Text:** White primary, champagne accent
- **Logo:** Haven wordmark or icon in white/champagne

---

## IMPLEMENTATION

### File: `apps/web/src/app/opengraph-image.tsx`

```tsx
import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const alt = 'Haven - Full-service home management';
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = 'image/png';

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          height: '100%',
          width: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #1E2A3B 0%, #111827 100%)',
          fontFamily: 'system-ui, sans-serif',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Subtle champagne glow in corner */}
        <div
          style={{
            position: 'absolute',
            top: '-100px',
            right: '-100px',
            width: '400px',
            height: '400px',
            background: 'radial-gradient(circle, rgba(212, 197, 169, 0.15) 0%, transparent 70%)',
            borderRadius: '50%',
          }}
        />
        <div
          style={{
            position: 'absolute',
            bottom: '-150px',
            left: '-150px',
            width: '500px',
            height: '500px',
            background: 'radial-gradient(circle, rgba(212, 197, 169, 0.1) 0%, transparent 70%)',
            borderRadius: '50%',
          }}
        />

        {/* Content container */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            padding: '60px',
            position: 'relative',
            zIndex: 1,
          }}
        >
          {/* Logo */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              marginBottom: '40px',
            }}
          >
            {/* Logo icon - house shape */}
            <div
              style={{
                width: '56px',
                height: '56px',
                background: 'linear-gradient(135deg, #D4C5A9 0%, #C4B393 100%)',
                borderRadius: '14px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <svg
                width="32"
                height="32"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#1E2A3B"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
                <polyline points="9 22 9 12 15 12 15 22" />
              </svg>
            </div>
            {/* Haven wordmark */}
            <span
              style={{
                fontSize: '48px',
                fontWeight: 700,
                color: 'white',
                letterSpacing: '-0.02em',
              }}
            >
              Haven
            </span>
          </div>

          {/* Headline */}
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              marginBottom: '24px',
            }}
          >
            <span
              style={{
                fontSize: '52px',
                fontWeight: 700,
                color: 'white',
                letterSpacing: '-0.02em',
                lineHeight: 1.1,
              }}
            >
              Stop managing your home.
            </span>
            <span
              style={{
                fontSize: '52px',
                fontWeight: 700,
                color: '#D4C5A9',
                letterSpacing: '-0.02em',
                lineHeight: 1.1,
              }}
            >
              Start living in it.
            </span>
          </div>

          {/* Divider */}
          <div
            style={{
              width: '80px',
              height: '3px',
              background: 'linear-gradient(90deg, transparent, #D4C5A9, transparent)',
              marginBottom: '24px',
              borderRadius: '2px',
            }}
          />

          {/* Subheadline */}
          <span
            style={{
              fontSize: '24px',
              color: 'rgba(255, 255, 255, 0.8)',
              marginBottom: '40px',
              letterSpacing: '0.01em',
            }}
          >
            One payment. One text. Everything handled.
          </span>

          {/* Stats row */}
          <div
            style={{
              display: 'flex',
              gap: '48px',
            }}
          >
            {[
              { value: '8+', label: 'hours saved monthly' },
              { value: '500+', label: 'families served' },
              { value: '4.9★', label: 'average rating' },
            ].map((stat, i) => (
              <div
                key={i}
                style={{
                  display: 'flex',
                  flexDirection: 'column',
                  alignItems: 'center',
                  padding: '16px 24px',
                  background: 'rgba(255, 255, 255, 0.05)',
                  borderRadius: '12px',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                }}
              >
                <span
                  style={{
                    fontSize: '32px',
                    fontWeight: 700,
                    color: '#D4C5A9',
                  }}
                >
                  {stat.value}
                </span>
                <span
                  style={{
                    fontSize: '14px',
                    color: 'rgba(255, 255, 255, 0.6)',
                    textTransform: 'uppercase',
                    letterSpacing: '0.05em',
                  }}
                >
                  {stat.label}
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}
```

---

## ALSO UPDATE: Twitter Image

### File: `apps/web/src/app/twitter-image.tsx`

Create this file with same content (or slightly adjusted for Twitter's 2:1 ratio):

```tsx
import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const alt = 'Haven - Full-service home management';
export const size = {
  width: 1200,
  height: 600, // Twitter uses 2:1 ratio
};
export const contentType = 'image/png';

// Same content as opengraph-image.tsx
export default async function Image() {
  // ... same implementation
}
```

---

## ALSO UPDATE: Metadata in layout.tsx

### File: `apps/web/src/app/layout.tsx`

Ensure metadata is set correctly:

```tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Haven - Full-Service Home Management',
  description: 'Stop managing your home. Start living in it. One payment covers everything. One text handles anything.',
  keywords: ['home management', 'bill pay', 'home maintenance', 'handyman', 'home manager'],
  authors: [{ name: 'Haven' }],
  creator: 'Haven',
  publisher: 'Haven',
  
  // Open Graph
  openGraph: {
    title: 'Haven - Full-Service Home Management',
    description: 'Stop managing your home. Start living in it. One payment covers everything. One text handles anything.',
    url: 'https://havenhome.com', // Update with actual URL
    siteName: 'Haven',
    locale: 'en_US',
    type: 'website',
  },
  
  // Twitter
  twitter: {
    card: 'summary_large_image',
    title: 'Haven - Full-Service Home Management',
    description: 'Stop managing your home. Start living in it. One payment. One text. Everything handled.',
    creator: '@havenhome', // Update with actual handle
  },
  
  // Additional
  robots: {
    index: true,
    follow: true,
  },
};
```

---

## PREVIEW RESULT

When shared on iMessage/Slack/Twitter, it will show:

```
┌─────────────────────────────────────┐
│                                     │
│  🏠 Haven                           │
│                                     │
│  Stop managing your home.           │
│  Start living in it.                │
│                                     │
│  One payment. One text. Everything  │
│  handled.                           │
│                                     │
│  8+ hrs | 500+ families | 4.9★      │
│                                     │
└─────────────────────────────────────┘
  Haven - Full-Service Home Management
  havenhome.com
```

---

## EXECUTION

```bash
cd /Users/tomburke/Projects/Housing-Manager
claude --dangerously-skip-permissions
```

Paste:

```
Read HAVEN_LINK_PREVIEW.md and update the Open Graph image:

1. Update apps/web/src/app/opengraph-image.tsx with:
   - Navy gradient background (#1E2A3B → #111827)
   - Champagne accent color (#D4C5A9)
   - Haven logo (house icon in champagne square + white wordmark)
   - Headline: "Stop managing your home." (white) + "Start living in it." (champagne)
   - Subheadline: "One payment. One text. Everything handled."
   - Stats row: 8+ hours, 500+ families, 4.9★ rating
   - Subtle champagne glow effects in corners

2. Create apps/web/src/app/twitter-image.tsx with same design (2:1 ratio)

3. Update metadata in apps/web/src/app/layout.tsx with proper OG and Twitter tags

4. Remove any old green colors from these files

Run pnpm build to verify the images generate correctly.
```

---

## TESTING

After deployment, test the preview at:
- https://developers.facebook.com/tools/debug/ (Facebook/iMessage)
- https://cards-dev.twitter.com/validator (Twitter)
- https://www.opengraph.xyz/ (General OG preview)

You may need to clear cached previews by re-scraping the URL.

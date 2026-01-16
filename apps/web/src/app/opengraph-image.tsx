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
          background: 'linear-gradient(135deg, #0F172A 0%, #1E293B 100%)',
          fontFamily: 'system-ui, sans-serif',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Subtle sage glow */}
        <div
          style={{
            position: 'absolute',
            top: '50%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            width: '800px',
            height: '800px',
            background: 'radial-gradient(circle, rgba(125, 142, 116, 0.12) 0%, transparent 60%)',
            borderRadius: '50%',
          }}
        />

        {/* Content */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            position: 'relative',
            zIndex: 1,
          }}
        >
          {/* Alfred House Logo */}
          <svg
            width="140"
            height="140"
            viewBox="0 0 120 120"
            fill="none"
            style={{ marginBottom: '32px' }}
          >
            {/* A-frame house - White */}
            <path d="M60 12L99 96H84L60 45L36 96H21L60 12Z" fill="#ffffff" />
            {/* Inner warmth - Sage */}
            <path d="M60 51L77 89H43L60 51Z" fill="#7D8E74" />
            {/* Window cutout */}
            <rect x="54" y="63" width="12" height="9" rx="1.5" fill="#0F172A" />
            {/* Door cutout */}
            <rect x="56" y="75" width="8" height="14" rx="1.5" fill="#0F172A" />
            {/* Sparkle */}
            <path
              d="M93 27L95.5 33.5L102 36L95.5 38.5L93 45L90.5 38.5L84 36L90.5 33.5L93 27Z"
              fill="#7D8E74"
            />
          </svg>

          {/* Brand name */}
          <span
            style={{
              fontSize: '72px',
              fontWeight: 700,
              color: 'white',
              letterSpacing: '-0.02em',
              marginBottom: '16px',
            }}
          >
            Haven
          </span>

          {/* Tagline */}
          <span
            style={{
              fontSize: '28px',
              color: '#A4B494',
              fontWeight: 500,
              marginBottom: '32px',
            }}
          >
            Your home, finally under control.
          </span>

          {/* Subtext */}
          <span
            style={{
              fontSize: '20px',
              color: 'rgba(255, 255, 255, 0.6)',
            }}
          >
            One bill. One app. Everything handled.
          </span>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}

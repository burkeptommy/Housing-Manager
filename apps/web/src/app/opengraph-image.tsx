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
          background: 'linear-gradient(135deg, #2D006B 0%, #1A0044 100%)',
          fontFamily: 'system-ui, sans-serif',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Subtle purple glow */}
        <div
          style={{
            position: 'absolute',
            top: '40%',
            left: '50%',
            transform: 'translate(-50%, -50%)',
            width: '900px',
            height: '600px',
            background: 'radial-gradient(ellipse, rgba(98, 0, 234, 0.12) 0%, transparent 60%)',
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
          {/* Haven Logo - Simple roof peak */}
          <svg
            width="100"
            height="80"
            viewBox="0 0 100 80"
            fill="none"
            style={{ marginBottom: '40px' }}
          >
            {/* Simple roof/house peak - clean Haven branding */}
            <path
              d="M50 0L100 70H75L50 30L25 70H0L50 0Z"
              fill="#ffffff"
            />
          </svg>

          {/* Brand name */}
          <span
            style={{
              fontSize: '80px',
              fontWeight: 700,
              color: 'white',
              letterSpacing: '-0.03em',
              marginBottom: '20px',
            }}
          >
            Haven
          </span>

          {/* Tagline */}
          <span
            style={{
              fontSize: '32px',
              color: '#B388FF',
              fontWeight: 500,
              marginBottom: '16px',
            }}
          >
            Your home, finally under control.
          </span>

          {/* Value prop */}
          <span
            style={{
              fontSize: '22px',
              color: 'rgba(255, 255, 255, 0.5)',
            }}
          >
            One bill. One contact. Zero hassle.
          </span>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}

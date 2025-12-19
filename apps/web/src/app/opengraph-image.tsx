import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const alt = 'Haven - Welcome Home';
export const size = {
  width: 1200,
  height: 630,
};
export const contentType = 'image/png';

export default async function OGImage() {
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
          backgroundColor: '#0f172a',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Abstract architectural lines in background */}
        <svg
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
            opacity: 0.08,
          }}
          viewBox="0 0 1200 630"
          fill="none"
        >
          {/* Architectural grid lines */}
          <path
            d="M0 315 L1200 315"
            stroke="#10b981"
            strokeWidth="1"
          />
          <path
            d="M600 0 L600 630"
            stroke="#10b981"
            strokeWidth="1"
          />
          {/* Abstract home outline */}
          <path
            d="M400 450 L600 280 L800 450 L800 550 L400 550 Z"
            stroke="#10b981"
            strokeWidth="2"
            fill="none"
          />
          {/* Horizontal accent lines */}
          <path
            d="M100 200 L500 200"
            stroke="#10b981"
            strokeWidth="1"
          />
          <path
            d="M700 200 L1100 200"
            stroke="#10b981"
            strokeWidth="1"
          />
          <path
            d="M100 430 L350 430"
            stroke="#10b981"
            strokeWidth="1"
          />
          <path
            d="M850 430 L1100 430"
            stroke="#10b981"
            strokeWidth="1"
          />
          {/* Diagonal accent */}
          <path
            d="M0 630 L400 230"
            stroke="#10b981"
            strokeWidth="1"
          />
          <path
            d="M1200 630 L800 230"
            stroke="#10b981"
            strokeWidth="1"
          />
          {/* Corner accents */}
          <path
            d="M50 50 L150 50 L150 150"
            stroke="#10b981"
            strokeWidth="2"
            fill="none"
          />
          <path
            d="M1150 50 L1050 50 L1050 150"
            stroke="#10b981"
            strokeWidth="2"
            fill="none"
          />
          <path
            d="M50 580 L150 580 L150 480"
            stroke="#10b981"
            strokeWidth="2"
            fill="none"
          />
          <path
            d="M1150 580 L1050 580 L1050 480"
            stroke="#10b981"
            strokeWidth="2"
            fill="none"
          />
        </svg>

        {/* Main content */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 10,
          }}
        >
          {/* Haven wordmark */}
          <div
            style={{
              fontSize: 120,
              fontWeight: 700,
              color: '#10b981',
              letterSpacing: '-0.02em',
              marginBottom: 24,
              fontFamily: 'system-ui, -apple-system, sans-serif',
            }}
          >
            Haven
          </div>

          {/* Subtext */}
          <div
            style={{
              fontSize: 36,
              color: '#94a3b8',
              fontWeight: 400,
              letterSpacing: '0.05em',
              fontFamily: 'system-ui, -apple-system, sans-serif',
            }}
          >
            Welcome Home.
          </div>
        </div>

        {/* Subtle gradient overlay at bottom */}
        <div
          style={{
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            background: 'linear-gradient(to top, rgba(16, 185, 129, 0.1), transparent)',
          }}
        />
      </div>
    ),
    {
      ...size,
    }
  );
}

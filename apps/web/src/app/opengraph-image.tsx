import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const alt = 'Haven - The Operating System for Your Home';
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
          backgroundColor: '#059669', // emerald-600
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* Subtle geometric pattern overlay for depth */}
        <svg
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: '100%',
            height: '100%',
          }}
          viewBox="0 0 1200 630"
          fill="none"
        >
          {/* Grid pattern - subtle darker emerald */}
          {/* Vertical lines */}
          {[0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200].map((x) => (
            <line
              key={`v-${x}`}
              x1={x}
              y1="0"
              x2={x}
              y2="630"
              stroke="#047857"
              strokeWidth="1"
              opacity="0.15"
            />
          ))}
          {/* Horizontal lines */}
          {[0, 100, 200, 300, 400, 500, 600].map((y) => (
            <line
              key={`h-${y}`}
              x1="0"
              y1={y}
              x2="1200"
              y2={y}
              stroke="#047857"
              strokeWidth="1"
              opacity="0.15"
            />
          ))}
          {/* Diagonal accent lines for premium feel */}
          <line
            x1="0"
            y1="630"
            x2="300"
            y2="330"
            stroke="#047857"
            strokeWidth="2"
            opacity="0.1"
          />
          <line
            x1="1200"
            y1="630"
            x2="900"
            y2="330"
            stroke="#047857"
            strokeWidth="2"
            opacity="0.1"
          />
          {/* Corner accents - premium badge feel */}
          <path
            d="M40 40 L120 40 L120 50 L50 50 L50 120 L40 120 Z"
            fill="#047857"
            opacity="0.2"
          />
          <path
            d="M1160 40 L1080 40 L1080 50 L1150 50 L1150 120 L1160 120 Z"
            fill="#047857"
            opacity="0.2"
          />
          <path
            d="M40 590 L120 590 L120 580 L50 580 L50 510 L40 510 Z"
            fill="#047857"
            opacity="0.2"
          />
          <path
            d="M1160 590 L1080 590 L1080 580 L1150 580 L1150 510 L1160 510 Z"
            fill="#047857"
            opacity="0.2"
          />
        </svg>

        {/* Subtle radial gradient for depth */}
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            background: 'radial-gradient(ellipse at center, transparent 0%, rgba(4, 120, 87, 0.3) 100%)',
          }}
        />

        {/* Main content */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            justifyContent: 'center',
            zIndex: 10,
            padding: '40px',
          }}
        >
          {/* Haven wordmark - large and bold */}
          <div
            style={{
              fontSize: 140,
              fontWeight: 700,
              color: '#ffffff',
              letterSpacing: '-0.02em',
              marginBottom: 16,
              fontFamily: 'system-ui, -apple-system, sans-serif',
              textShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
            }}
          >
            Haven
          </div>

          {/* Tagline */}
          <div
            style={{
              fontSize: 32,
              fontWeight: 500,
              color: '#ffffff',
              letterSpacing: '0.02em',
              marginBottom: 20,
              fontFamily: 'system-ui, -apple-system, sans-serif',
            }}
          >
            The Operating System for Your Home
          </div>

          {/* Decorative line separator */}
          <div
            style={{
              width: 80,
              height: 3,
              backgroundColor: 'rgba(255, 255, 255, 0.5)',
              borderRadius: 2,
              marginBottom: 20,
            }}
          />

          {/* Subtext with reduced opacity */}
          <div
            style={{
              fontSize: 24,
              fontWeight: 400,
              color: 'rgba(255, 255, 255, 0.8)',
              letterSpacing: '0.1em',
              fontFamily: 'system-ui, -apple-system, sans-serif',
            }}
          >
            Welcome Home.
          </div>
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
}

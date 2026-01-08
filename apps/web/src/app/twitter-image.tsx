import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const alt = 'Haven - Full-service home management';
export const size = {
  width: 1200,
  height: 600, // Twitter uses 2:1 ratio
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
            padding: '50px',
            position: 'relative',
            zIndex: 1,
          }}
        >
          {/* Logo - H with roof + "aven" */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              marginBottom: '32px',
            }}
          >
            {/* Haven H icon with champagne roof */}
            <svg
              width="64"
              height="64"
              viewBox="-30 -25 60 50"
              fill="none"
            >
              {/* H letter in white */}
              <path
                d="M -19 -13 L -7.5 -13 L -7.5 -11 L -12 -11 L -12 -2 L 12 -2 L 12 -11 L 7.5 -11 L 7.5 -13 L 19 -13 L 19 -11 L 15.5 -11 L 15.5 11 L 19 11 L 19 13 L 7.5 13 L 7.5 11 L 12 11 L 12 2 L -12 2 L -12 11 L -7.5 11 L -7.5 13 L -19 13 L -19 11 L -15.5 11 L -15.5 -11 L -19 -11 Z"
                fill="white"
              />
              {/* Champagne roof */}
              <path
                d="M 0 -20 L -27.5 -13 L -23.5 -13 L 0 -16.5 L 23.5 -13 L 27.5 -13 Z"
                fill="#c4a574"
              />
            </svg>
            {/* "aven" text to spell Haven */}
            <span
              style={{
                fontSize: '50px',
                fontWeight: 300,
                color: 'white',
                letterSpacing: '0.04em',
                marginLeft: '4px',
              }}
            >
              aven
            </span>
          </div>

          {/* Headline */}
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              marginBottom: '20px',
            }}
          >
            <span
              style={{
                fontSize: '46px',
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
                fontSize: '46px',
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
              marginBottom: '20px',
              borderRadius: '2px',
            }}
          />

          {/* Subheadline */}
          <span
            style={{
              fontSize: '22px',
              color: 'rgba(255, 255, 255, 0.8)',
              marginBottom: '32px',
              letterSpacing: '0.01em',
            }}
          >
            One payment. One text. Everything handled.
          </span>

          {/* Stats row */}
          <div
            style={{
              display: 'flex',
              gap: '40px',
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
                  padding: '14px 20px',
                  background: 'rgba(255, 255, 255, 0.05)',
                  borderRadius: '12px',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                }}
              >
                <span
                  style={{
                    fontSize: '28px',
                    fontWeight: 700,
                    color: '#D4C5A9',
                  }}
                >
                  {stat.value}
                </span>
                <span
                  style={{
                    fontSize: '12px',
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

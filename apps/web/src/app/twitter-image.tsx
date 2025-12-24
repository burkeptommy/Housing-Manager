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
          {/* Logo */}
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '16px',
              marginBottom: '32px',
            }}
          >
            {/* Logo icon - leaf shape */}
            <div
              style={{
                width: '48px',
                height: '48px',
                background: 'linear-gradient(135deg, #D4C5A9 0%, #C4B393 100%)',
                borderRadius: '12px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <svg
                width="28"
                height="28"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#1E2A3B"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <path d="M11 20A7 7 0 0 1 9.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10Z" />
                <path d="M2 21c0-3 1.85-5.36 5.08-6C9.5 14.52 12 13 13 12" />
              </svg>
            </div>
            {/* Haven wordmark */}
            <span
              style={{
                fontSize: '42px',
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

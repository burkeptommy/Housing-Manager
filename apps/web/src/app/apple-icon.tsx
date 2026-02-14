import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const size = {
  width: 180,
  height: 180,
};

export const contentType = 'image/png';

export default function AppleIcon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: 'linear-gradient(135deg, #6200EA 0%, #4A00B4 100%)',
          borderRadius: '40px',
        }}
      >
        {/* Haven H icon with purple roof */}
        <svg
          width="120"
          height="120"
          viewBox="-30 -25 60 50"
          fill="none"
        >
          {/* H letter in white */}
          <path
            d="M -19 -13 L -7.5 -13 L -7.5 -11 L -12 -11 L -12 -2 L 12 -2 L 12 -11 L 7.5 -11 L 7.5 -13 L 19 -13 L 19 -11 L 15.5 -11 L 15.5 11 L 19 11 L 19 13 L 7.5 13 L 7.5 11 L 12 11 L 12 2 L -12 2 L -12 11 L -7.5 11 L -7.5 13 L -19 13 L -19 11 L -15.5 11 L -15.5 -11 L -19 -11 Z"
            fill="white"
          />
          {/* White roof */}
          <path
            d="M 0 -20 L -27.5 -13 L -23.5 -13 L 0 -16.5 L 23.5 -13 L 27.5 -13 Z"
            fill="white"
          />
        </svg>
      </div>
    ),
    {
      ...size,
    }
  );
}

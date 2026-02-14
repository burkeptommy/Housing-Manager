import { ImageResponse } from 'next/og';

export const runtime = 'edge';

export const size = {
  width: 32,
  height: 32,
};

export const contentType = 'image/png';

export default function Icon() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          background: '#6200EA',
          borderRadius: '6px',
        }}
      >
        {/* Haven H icon with purple roof */}
        <svg
          width="24"
          height="24"
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

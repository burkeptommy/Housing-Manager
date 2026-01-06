'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body>
        <div style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#faf9f7'
        }}>
          <div style={{ textAlign: 'center' }}>
            <h1 style={{ fontSize: '2rem', fontWeight: 'bold', color: '#1e3a5f', marginBottom: '1rem' }}>
              Something went wrong
            </h1>
            <p style={{ color: '#666', marginBottom: '2rem' }}>
              We apologize for the inconvenience.
            </p>
            <button
              onClick={() => reset()}
              style={{
                padding: '0.75rem 1.5rem',
                backgroundColor: '#1e3a5f',
                color: 'white',
                border: 'none',
                borderRadius: '0.5rem',
                cursor: 'pointer',
                fontWeight: '500'
              }}
            >
              Try again
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}

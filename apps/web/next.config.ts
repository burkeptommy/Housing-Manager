import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  transpilePackages: ['@haven/ui', '@haven/core'],

  // Enable standalone output for Docker deployment
  output: 'standalone',

  // Disable x-powered-by header for security
  poweredByHeader: false,

  // Ignore ESLint errors during build (linting runs separately in CI)
  eslint: {
    ignoreDuringBuilds: true,
  },

  // Ignore TypeScript errors during build (type checking runs separately)
  typescript: {
    ignoreBuildErrors: true,
  },

  // Configure allowed image domains
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'storage.googleapis.com',
      },
    ],
  },
};

export default nextConfig;

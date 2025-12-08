import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  transpilePackages: ['@haven/ui', '@haven/core'],
};

export default nextConfig;

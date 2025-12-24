import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';

import { AuthProvider } from '@/contexts/auth-context';
import { QueryProvider } from '@/lib/query-client';

import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: {
    default: 'Haven - Full-Service Home Management',
    template: '%s | Haven',
  },
  description:
    'Stop managing your home. Start living in it. One payment covers everything. One text handles anything.',
  keywords: [
    'home management',
    'bill pay',
    'home maintenance',
    'handyman',
    'home manager',
    'home concierge',
    'household management',
  ],
  authors: [{ name: 'Haven' }],
  creator: 'Haven',
  publisher: 'Haven',
  metadataBase: new URL('https://havenhome.dev'),
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://havenhome.dev',
    siteName: 'Haven',
    title: 'Haven - Full-Service Home Management',
    description:
      'Stop managing your home. Start living in it. One payment covers everything. One text handles anything.',
    images: [
      {
        url: '/opengraph-image',
        width: 1200,
        height: 630,
        alt: 'Haven - Full-service home management',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Haven - Full-Service Home Management',
    description:
      'Stop managing your home. Start living in it. One payment. One text. Everything handled.',
    images: ['/twitter-image'],
  },
  robots: {
    index: true,
    follow: true,
  },
  icons: {
    icon: '/favicon.ico',
    apple: '/apple-touch-icon.png',
  },
  manifest: '/manifest.json',
  appleWebApp: {
    capable: true,
    statusBarStyle: 'black-translucent',
    title: 'Haven',
  },
  formatDetection: {
    telephone: true,
    email: true,
    address: true,
  },
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0f172a' },
  ],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="mobile-web-app-capable" content="yes" />
      </head>
      <body className={inter.className}>
        <QueryProvider>
          <AuthProvider>{children}</AuthProvider>
        </QueryProvider>
      </body>
    </html>
  );
}

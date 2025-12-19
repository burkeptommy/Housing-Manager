import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';

import { AuthProvider } from '@/contexts/auth-context';
import { QueryProvider } from '@/lib/query-client';

import './globals.css';

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: {
    default: 'Haven | The Operating System for Your Home',
    template: '%s | Haven',
  },
  description:
    'A dedicated Chief of Staff, a secure wallet for your bills, and a proactive maintenance team. Your home, fully managed.',
  keywords: [
    'home management',
    'home concierge',
    'property management',
    'home maintenance',
    'household management',
    'home services',
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
    title: 'Haven | The Operating System for Your Home',
    description:
      'A dedicated Chief of Staff, a secure wallet for your bills, and a proactive maintenance team. Your home, fully managed.',
    images: [
      {
        url: '/opengraph-image',
        width: 1200,
        height: 630,
        alt: 'Haven - Welcome Home',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Haven | The Operating System for Your Home',
    description:
      'A dedicated Chief of Staff, a secure wallet for your bills, and a proactive maintenance team. Your home, fully managed.',
    images: ['/opengraph-image'],
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

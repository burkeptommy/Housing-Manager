'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Menu, X } from 'lucide-react';

export function Navbar() {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { href: '#how-it-works', label: 'How It Works' },
    { href: '#services', label: 'Services' },
    { href: '#pricing', label: 'Pricing' },
    { href: '#faq', label: 'FAQ' },
  ];

  return (
    <nav
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled
          ? 'bg-white/95 backdrop-blur-md shadow-sm border-b border-warm-100'
          : 'bg-transparent'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16 lg:h-20">
          {/* Logo */}
          <Link href="/" className="flex items-center">
            <Image
              src={isScrolled ? '/logo-wordmark.svg' : '/logo-wordmark-white.svg'}
              alt="Haven"
              width={140}
              height={36}
              priority
              className="h-9 w-auto"
            />
          </Link>

          {/* Desktop Navigation */}
          <div className="hidden lg:flex items-center gap-8">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className={`text-sm font-medium transition-colors ${
                  isScrolled
                    ? 'text-warm-600 hover:text-haven-700'
                    : 'text-white/90 hover:text-white'
                }`}
              >
                {link.label}
              </a>
            ))}
          </div>

          {/* Desktop CTA */}
          <div className="hidden lg:flex items-center gap-4">
            <Link
              href="/login"
              className={`text-sm font-medium transition-colors ${
                isScrolled ? 'text-warm-600 hover:text-haven-700' : 'text-white/90 hover:text-white'
              }`}
            >
              Sign In
            </Link>
            <Link
              href="/register"
              className={`px-5 py-2.5 text-sm font-semibold rounded-xl transition-all ${
                isScrolled
                  ? 'bg-haven-700 text-white hover:bg-haven-800 shadow-sm hover:shadow-md'
                  : 'bg-white text-haven-700 hover:bg-champagne-50 shadow-lg shadow-black/10'
              }`}
            >
              Get Started
            </Link>
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
            className={`lg:hidden p-2 rounded-lg transition-colors ${
              isScrolled ? 'text-warm-700 hover:bg-warm-100' : 'text-white hover:bg-white/10'
            }`}
            aria-label="Toggle menu"
          >
            {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Menu */}
        {isMobileMenuOpen && (
          <div className="lg:hidden bg-white border-t border-warm-100 py-4 shadow-lg">
            <div className="flex flex-col gap-1">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50 transition-colors"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  {link.label}
                </a>
              ))}
              <div className="border-t border-warm-100 mt-2 pt-2 px-2">
                <Link
                  href="/login"
                  className="block px-4 py-3 text-warm-700 font-medium rounded-lg hover:bg-warm-50 transition-colors"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Sign In
                </Link>
                <Link
                  href="/register"
                  className="block mt-2 px-4 py-3 bg-haven-700 text-white font-semibold rounded-xl text-center hover:bg-haven-800 transition-colors"
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  Get Started
                </Link>
              </div>
            </div>
          </div>
        )}
      </div>
    </nav>
  );
}

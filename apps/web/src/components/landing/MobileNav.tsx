'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Home, Menu, X } from 'lucide-react';

export function MobileNav() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-slate-50/90 backdrop-blur-md border-b border-slate-200/50">
      <div className="flex items-center justify-between px-6 lg:px-12 py-4 max-w-7xl mx-auto">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-950 flex items-center justify-center">
            <Home className="w-5 h-5 text-white" />
          </div>
          <span className="text-xl font-semibold tracking-tight text-emerald-950">Haven</span>
        </div>

        {/* Desktop Nav */}
        <div className="hidden md:flex items-center gap-8">
          <a href="#services" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">Services</a>
          <a href="#pricing" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">Membership</a>
          <a href="#about" className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors">About</a>
        </div>

        {/* Desktop CTA */}
        <div className="hidden md:flex items-center gap-4">
          <Link
            href="/login"
            className="text-slate-600 hover:text-emerald-950 text-sm font-medium transition-colors"
          >
            Sign In
          </Link>
          <Link
            href="/login"
            className="bg-emerald-950 text-white hover:bg-emerald-900 px-5 py-2.5 rounded-lg text-sm font-medium transition-colors"
          >
            Request Access
          </Link>
        </div>

        {/* Mobile Menu Button */}
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="md:hidden p-2 text-emerald-950 hover:bg-slate-100 rounded-lg transition-colors"
          aria-label="Toggle menu"
        >
          {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
        </button>
      </div>

      {/* Mobile Menu Panel */}
      {isOpen && (
        <div className="md:hidden bg-white border-t border-slate-200 shadow-lg">
          <div className="px-6 py-4 space-y-4">
            <a
              href="#services"
              onClick={() => setIsOpen(false)}
              className="block text-slate-600 hover:text-emerald-950 font-medium py-2 transition-colors"
            >
              Services
            </a>
            <a
              href="#pricing"
              onClick={() => setIsOpen(false)}
              className="block text-slate-600 hover:text-emerald-950 font-medium py-2 transition-colors"
            >
              Membership
            </a>
            <a
              href="#about"
              onClick={() => setIsOpen(false)}
              className="block text-slate-600 hover:text-emerald-950 font-medium py-2 transition-colors"
            >
              About
            </a>
            <div className="border-t border-slate-200 pt-4 space-y-3">
              <Link
                href="/login"
                onClick={() => setIsOpen(false)}
                className="block text-center text-slate-600 hover:text-emerald-950 font-medium py-2 transition-colors"
              >
                Sign In
              </Link>
              <Link
                href="/login"
                onClick={() => setIsOpen(false)}
                className="block text-center bg-emerald-950 text-white hover:bg-emerald-900 px-5 py-3 rounded-lg font-medium transition-colors"
              >
                Request Access
              </Link>
            </div>
          </div>
        </div>
      )}
    </nav>
  );
}

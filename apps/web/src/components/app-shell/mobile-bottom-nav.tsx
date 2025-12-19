'use client';

import { useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { X, Leaf } from 'lucide-react';
import { mobileNavigation, sidebarNavigation, sidebarBottomNav } from './navigation-config';

export function MobileBottomNav() {
  const pathname = usePathname();
  const [drawerOpen, setDrawerOpen] = useState(false);

  const isActive = (href: string) => {
    if (href === '/app') return pathname === '/app';
    return pathname === href || pathname.startsWith(href + '/');
  };

  // Filter out the Menu item for regular nav items
  const navItems = mobileNavigation.filter((item) => item.href !== '#menu');

  return (
    <>
      {/* Bottom Navigation Bar */}
      <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-white border-t border-slate-200 safe-area-pb">
        <div className="flex items-center justify-around h-16 px-2">
          {navItems.map((item) => {
            const active = isActive(item.href);
            const Icon = item.icon;

            return (
              <Link
                key={item.name}
                href={item.href}
                className={`flex flex-col items-center justify-center flex-1 h-full py-1 transition-colors ${
                  active ? 'text-emerald-600' : 'text-slate-400'
                }`}
              >
                <Icon className="w-6 h-6" strokeWidth={active ? 2.5 : 2} />
                <span className={`text-xs mt-1 ${active ? 'font-medium' : 'font-normal'}`}>
                  {item.name}
                </span>
              </Link>
            );
          })}
          {/* Menu Button */}
          <button
            onClick={() => setDrawerOpen(true)}
            className="flex flex-col items-center justify-center flex-1 h-full py-1 text-slate-400 transition-colors"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M4 6h16M4 12h16M4 18h16"
              />
            </svg>
            <span className="text-xs mt-1 font-normal">Menu</span>
          </button>
        </div>
      </nav>

      {/* Drawer Overlay */}
      {drawerOpen && (
        <div
          className="lg:hidden fixed inset-0 z-50 bg-black/50"
          onClick={() => setDrawerOpen(false)}
        />
      )}

      {/* Drawer */}
      <div
        className={`lg:hidden fixed inset-y-0 right-0 z-50 w-80 bg-slate-900 transform transition-transform duration-300 ease-in-out ${
          drawerOpen ? 'translate-x-0' : 'translate-x-full'
        }`}
      >
        {/* Drawer Header */}
        <div className="flex items-center justify-between h-16 px-6 border-b border-slate-800">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-emerald-600 flex items-center justify-center">
              <Leaf className="w-4 h-4 text-white" />
            </div>
            <span className="text-lg font-bold text-white">Haven</span>
          </div>
          <button
            onClick={() => setDrawerOpen(false)}
            className="p-2 text-slate-400 hover:text-white transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Drawer Navigation */}
        <nav className="flex-1 px-3 py-4 space-y-6 overflow-y-auto max-h-[calc(100vh-8rem)]">
          {sidebarNavigation.map((section) => (
            <div key={section.title}>
              <h3 className="px-3 mb-2 text-xs font-semibold uppercase tracking-wider text-slate-500">
                {section.title}
              </h3>
              <div className="space-y-1">
                {section.items.map((item) => {
                  const active = isActive(item.href);
                  const Icon = item.icon;

                  return (
                    <Link
                      key={item.name}
                      href={item.href}
                      onClick={() => setDrawerOpen(false)}
                      className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                        active
                          ? 'bg-emerald-600/10 text-emerald-400'
                          : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                      }`}
                    >
                      <Icon
                        className={`w-5 h-5 ${active ? 'text-emerald-400' : 'text-slate-400'}`}
                        strokeWidth={active ? 2.5 : 2}
                      />
                      {item.name}
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </nav>

        {/* Drawer Bottom Section */}
        <div className="absolute bottom-0 left-0 right-0 px-3 py-4 border-t border-slate-800 bg-slate-900 space-y-1">
          {sidebarBottomNav.map((item) => {
            const active = isActive(item.href);
            const Icon = item.icon;

            return (
              <Link
                key={item.name}
                href={item.href}
                onClick={() => setDrawerOpen(false)}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                  active
                    ? 'bg-emerald-600/10 text-emerald-400'
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <Icon
                  className={`w-5 h-5 ${active ? 'text-emerald-400' : 'text-slate-400'}`}
                  strokeWidth={active ? 2.5 : 2}
                />
                {item.name}
              </Link>
            );
          })}
        </div>
      </div>
    </>
  );
}

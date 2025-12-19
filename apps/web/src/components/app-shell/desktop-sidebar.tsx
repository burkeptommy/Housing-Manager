'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Leaf } from 'lucide-react';
import { sidebarNavigation, sidebarBottomNav } from './navigation-config';

export function DesktopSidebar() {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (href === '/app') return pathname === '/app';
    return pathname === href || pathname.startsWith(href + '/');
  };

  return (
    <aside className="hidden lg:flex lg:flex-col lg:w-[260px] lg:fixed lg:inset-y-0 bg-slate-900">
      {/* Logo */}
      <div className="flex items-center h-16 px-6 border-b border-slate-800">
        <Link href="/app" className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-emerald-600 flex items-center justify-center">
            <Leaf className="w-5 h-5 text-white" />
          </div>
          <span className="text-xl font-bold tracking-tight text-white">Haven</span>
        </Link>
      </div>

      {/* Navigation - Scrollable */}
      <nav className="flex-1 px-3 py-4 space-y-6 overflow-y-auto">
        {sidebarNavigation.map((section) => (
          <div key={section.title}>
            {/* Section Title */}
            <h3 className="px-3 mb-2 text-xs font-semibold uppercase tracking-wider text-slate-500">
              {section.title}
            </h3>
            {/* Section Items */}
            <div className="space-y-1">
              {section.items.map((item) => {
                const active = isActive(item.href);
                const Icon = item.icon;

                return (
                  <Link
                    key={item.name}
                    href={item.href}
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

      {/* Bottom Section */}
      <div className="px-3 py-4 border-t border-slate-800 space-y-1">
        {sidebarBottomNav.map((item) => {
          const active = isActive(item.href);
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
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
    </aside>
  );
}

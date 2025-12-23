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
    <aside className="hidden lg:flex lg:flex-col lg:w-[260px] lg:fixed lg:inset-y-0 bg-gradient-to-b from-forest-900 to-forest-950">
      {/* Logo */}
      <div className="flex items-center h-16 px-6 border-b border-white/10">
        <Link href="/app" className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-haven-400 to-haven-600 flex items-center justify-center shadow-lg shadow-haven-500/20">
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
            <h3 className="px-3 mb-2 text-xs font-semibold uppercase tracking-wider text-white/40">
              {section.title}
            </h3>
            {/* Section Items */}
            <div className="space-y-1">
              {section.items.map((item) => {
                const active = isActive(item.href);
                const Icon = item.icon;

                // Special highlight styling for Sarah
                if (item.highlight) {
                  return (
                    <Link
                      key={item.name}
                      href={item.href}
                      className={`flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all ${
                        active
                          ? 'bg-haven-500/30 text-white'
                          : 'bg-haven-500/20 text-haven-200 hover:bg-haven-500/30 hover:text-white'
                      }`}
                    >
                      <div className="w-8 h-8 rounded-lg bg-haven-500/40 flex items-center justify-center">
                        <Icon className="w-4 h-4 text-haven-200" strokeWidth={2} />
                      </div>
                      <span className="font-medium">{item.name}</span>
                      {item.badge && item.badge > 0 && (
                        <span className="ml-auto px-2 py-0.5 bg-red-500 text-white text-xs font-bold rounded-full">
                          {item.badge}
                        </span>
                      )}
                    </Link>
                  );
                }

                return (
                  <Link
                    key={item.name}
                    href={item.href}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                      active
                        ? 'bg-white/15 text-white'
                        : 'text-white/70 hover:bg-white/10 hover:text-white'
                    }`}
                  >
                    <Icon
                      className={`w-5 h-5 ${active ? 'text-haven-400' : 'text-white/50'}`}
                      strokeWidth={active ? 2.5 : 2}
                    />
                    {item.name}
                    {item.badge && item.badge > 0 && (
                      <span className="ml-auto px-2 py-0.5 bg-red-500 text-white text-xs font-bold rounded-full">
                        {item.badge}
                      </span>
                    )}
                  </Link>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Bottom Section */}
      <div className="px-3 py-4 border-t border-white/10 space-y-1">
        {sidebarBottomNav.map((item) => {
          const active = isActive(item.href);
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all ${
                active
                  ? 'bg-white/15 text-white'
                  : 'text-white/70 hover:bg-white/10 hover:text-white'
              }`}
            >
              <Icon
                className={`w-5 h-5 ${active ? 'text-haven-400' : 'text-white/50'}`}
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

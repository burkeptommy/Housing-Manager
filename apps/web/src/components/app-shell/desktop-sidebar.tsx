'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Home, HelpCircle } from 'lucide-react';
import { useAuth } from '@/contexts/auth-context';
import { mainNavigation } from './navigation-config';

export function DesktopSidebar() {
  const pathname = usePathname();
  const { user } = useAuth();

  // Filter navigation items based on user role
  const filteredNavigation = mainNavigation.filter((item) => {
    if (!item.roles) return true;
    return user?.role && item.roles.includes(user.role);
  });

  const isActive = (href: string) => {
    if (href === '/app') return pathname === '/app';
    return pathname === href || pathname.startsWith(href + '/');
  };

  return (
    <aside className="hidden lg:flex lg:flex-col lg:w-64 lg:fixed lg:inset-y-0 bg-white border-r border-slate-200">
      {/* Logo */}
      <div className="flex items-center h-16 px-6 border-b border-slate-200">
        <Link href="/app" className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-lg bg-slate-900 flex items-center justify-center">
            <Home className="w-5 h-5 text-white" />
          </div>
          <span className="text-xl font-bold tracking-tight text-slate-900">Haven</span>
        </Link>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {filteredNavigation.map((item) => {
          const active = isActive(item.href);
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                active
                  ? 'bg-slate-900 text-white'
                  : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
              }`}
            >
              <Icon
                className={`w-5 h-5 ${active ? 'text-white' : 'text-slate-400'}`}
                strokeWidth={active ? 2.5 : 2}
              />
              {item.name}
            </Link>
          );
        })}
      </nav>

      {/* Bottom section */}
      <div className="px-3 py-4 border-t border-slate-200">
        <Link
          href="/app/support"
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-500 hover:bg-slate-100 hover:text-slate-700 transition-colors"
        >
          <HelpCircle className="w-5 h-5 text-slate-400" />
          Help & Support
        </Link>
      </div>
    </aside>
  );
}

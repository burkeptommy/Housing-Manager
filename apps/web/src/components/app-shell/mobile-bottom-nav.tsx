'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { mobileNavigation } from './navigation-config';

export function MobileBottomNav() {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (href === '/app') return pathname === '/app';
    return pathname === href || pathname.startsWith(href + '/');
  };

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-white border-t border-slate-200 safe-area-pb">
      <div className="flex items-center justify-around h-16 px-2">
        {mobileNavigation.map((item) => {
          const active = isActive(item.href);
          const Icon = item.icon;

          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex flex-col items-center justify-center flex-1 h-full py-1 transition-colors ${
                active ? 'text-slate-900' : 'text-slate-400'
              }`}
            >
              <Icon
                className="w-6 h-6"
                strokeWidth={active ? 2.5 : 2}
                fill={active ? 'currentColor' : 'none'}
              />
              <span className={`text-xs mt-1 ${active ? 'font-medium' : 'font-normal'}`}>
                {item.name}
              </span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}

'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import {
  Home,
  LayoutDashboard,
  Wrench,
  Users,
  User,
  ClipboardList,
  ClipboardCheck,
  MessageSquare,
  Calendar,
  CreditCard,
  Settings,
  HelpCircle,
  X,
  Menu
} from 'lucide-react';

type NavItem = {
  name: string;
  href: string;
  icon: React.ReactNode;
  roles?: string[];
};

const navigation: NavItem[] = [
  { name: 'Dashboard', href: '/app', icon: <LayoutDashboard className="w-5 h-5" /> },
  { name: 'Home Profile', href: '/app/home', icon: <Home className="w-5 h-5" /> },
  { name: 'Projects', href: '/app/projects', icon: <Wrench className="w-5 h-5" /> },
  { name: 'Find Pros', href: '/app/community', icon: <Users className="w-5 h-5" /> },
  { name: 'My Profile', href: '/app/profile', icon: <User className="w-5 h-5" /> },
  { name: 'Requests', href: '/app/requests', icon: <ClipboardList className="w-5 h-5" /> },
  { name: 'Work Orders', href: '/app/work-orders', icon: <ClipboardCheck className="w-5 h-5" /> },
  { name: 'Messages', href: '/app/messages', icon: <MessageSquare className="w-5 h-5" /> },
  { name: 'My Jobs', href: '/app/handyman', icon: <Settings className="w-5 h-5" />, roles: ['HANDYMAN'] },
  { name: 'Calendar', href: '/app/calendar', icon: <Calendar className="w-5 h-5" /> },
  { name: 'Billing', href: '/app/billing', icon: <CreditCard className="w-5 h-5" /> },
  { name: 'Settings', href: '/app/settings', icon: <Settings className="w-5 h-5" /> },
];

export function MobileSidebar() {
  const [isOpen, setIsOpen] = useState(false);
  const pathname = usePathname();
  const { user } = useAuth();

  // Close sidebar when route changes
  useEffect(() => {
    setIsOpen(false);
  }, [pathname]);

  // Prevent body scroll when sidebar is open
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => {
      document.body.style.overflow = '';
    };
  }, [isOpen]);

  const filteredNavigation = navigation.filter((item) => {
    if (!item.roles) return true;
    return user?.role && item.roles.includes(user.role);
  });

  return (
    <>
      {/* Mobile menu button */}
      <button
        onClick={() => setIsOpen(true)}
        className="lg:hidden p-2 -ml-2 text-slate-600 hover:text-emerald-700 hover:bg-slate-100 rounded-lg transition-colors"
        aria-label="Open menu"
      >
        <Menu className="w-6 h-6" />
      </button>

      {/* Overlay */}
      {isOpen && (
        <div
          className="fixed inset-0 z-50 bg-slate-900/50 lg:hidden"
          onClick={() => setIsOpen(false)}
        />
      )}

      {/* Sidebar panel */}
      <div
        className={`fixed inset-y-0 left-0 z-50 w-72 bg-white dark:bg-slate-800 transform transition-transform duration-300 ease-in-out lg:hidden ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Header */}
        <div className="flex items-center justify-between h-16 px-6 border-b border-slate-200 dark:border-slate-700">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-emerald-950 flex items-center justify-center">
              <Home className="w-5 h-5 text-white" />
            </div>
            <span className="text-lg font-semibold text-emerald-950 dark:text-white">Haven</span>
          </div>
          <button
            onClick={() => setIsOpen(false)}
            className="p-2 text-slate-500 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
            aria-label="Close menu"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-4 py-4 space-y-1 overflow-y-auto">
          {filteredNavigation.map((item) => {
            const isActive = pathname === item.href || (item.href !== '/app' && pathname.startsWith(item.href));
            return (
              <Link
                key={item.name}
                href={item.href}
                onClick={() => setIsOpen(false)}
                className={`flex items-center gap-3 px-3 py-3 rounded-lg text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-400'
                    : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-700/50'
                }`}
              >
                {item.icon}
                {item.name}
              </Link>
            );
          })}
        </nav>

        {/* Bottom section */}
        <div className="px-4 py-4 border-t border-slate-200 dark:border-slate-700">
          <div className="flex items-center gap-3 px-3 py-2 text-sm text-slate-500 dark:text-slate-400">
            <HelpCircle className="w-5 h-5" />
            <span>Help & Support</span>
          </div>
        </div>
      </div>
    </>
  );
}

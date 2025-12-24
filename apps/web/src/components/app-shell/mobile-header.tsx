'use client';

import { useState, useRef, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Bell, ChevronDown, LogOut, User, Settings } from 'lucide-react';
import { useAuth } from '@/contexts/auth-context';
import { getPageTitle } from './navigation-config';

export function MobileHeader() {
  const pathname = usePathname();
  const { user, households, currentHousehold, selectHousehold, logout } = useAuth();
  const [userMenuOpen, setUserMenuOpen] = useState(false);
  const [householdMenuOpen, setHouseholdMenuOpen] = useState(false);
  const userMenuRef = useRef<HTMLDivElement>(null);
  const householdMenuRef = useRef<HTMLDivElement>(null);

  const pageTitle = getPageTitle(pathname);

  // Close menus when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (userMenuRef.current && !userMenuRef.current.contains(event.target as Node)) {
        setUserMenuOpen(false);
      }
      if (householdMenuRef.current && !householdMenuRef.current.contains(event.target as Node)) {
        setHouseholdMenuOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Get user initials
  const initials = user?.firstName && user?.lastName
    ? `${user.firstName[0]}${user.lastName[0]}`
    : user?.email?.[0]?.toUpperCase() || 'U';

  return (
    <header className="lg:hidden sticky top-0 z-40 bg-white border-b border-warm-200">
      <div className="flex items-center justify-between h-14 px-4">
        {/* Household Selector */}
        <div ref={householdMenuRef} className="relative">
          <button
            onClick={() => setHouseholdMenuOpen(!householdMenuOpen)}
            className="flex items-center gap-1.5 text-sm font-medium text-warm-600 hover:text-warm-900 transition-colors"
          >
            <span className="max-w-[120px] truncate">
              {currentHousehold?.name || 'Select Home'}
            </span>
            <ChevronDown className="w-4 h-4 text-warm-400" />
          </button>

          {householdMenuOpen && (
            <div className="absolute left-0 mt-2 w-56 bg-white rounded-xl shadow-lg border border-warm-200 py-1 z-50">
              {households.length > 0 ? (
                households.map((household) => (
                  <button
                    key={household.id}
                    onClick={() => {
                      selectHousehold(household);
                      setHouseholdMenuOpen(false);
                    }}
                    className={`w-full flex items-center justify-between px-4 py-2.5 text-sm text-left hover:bg-warm-50 ${
                      currentHousehold?.id === household.id
                        ? 'text-warm-900 font-medium bg-warm-50'
                        : 'text-warm-600'
                    }`}
                  >
                    <span className="truncate">{household.name}</span>
                    {currentHousehold?.id === household.id && (
                      <div className="w-2 h-2 rounded-full bg-haven-700" />
                    )}
                  </button>
                ))
              ) : (
                <div className="px-4 py-3 text-sm text-warm-500">No homes yet</div>
              )}
            </div>
          )}
        </div>

        {/* Page Title */}
        <h1 className="absolute left-1/2 -translate-x-1/2 text-base font-bold tracking-tight text-warm-900">
          {pageTitle}
        </h1>

        {/* Right side actions */}
        <div className="flex items-center gap-2">
          {/* Notifications */}
          <button className="relative p-2 text-warm-500 hover:text-warm-700 hover:bg-warm-100 rounded-lg transition-colors">
            <Bell className="w-5 h-5" />
            <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full" />
          </button>

          {/* User Avatar */}
          <div ref={userMenuRef} className="relative">
            <button
              onClick={() => setUserMenuOpen(!userMenuOpen)}
              className="w-8 h-8 rounded-full bg-haven-700 flex items-center justify-center text-white text-sm font-medium hover:bg-haven-800 transition-colors"
            >
              {initials}
            </button>

            {userMenuOpen && (
              <div className="absolute right-0 mt-2 w-56 bg-white rounded-xl shadow-lg border border-warm-200 py-1 z-50">
                <div className="px-4 py-3 border-b border-warm-200">
                  <p className="text-sm font-medium text-warm-900">
                    {user?.firstName} {user?.lastName}
                  </p>
                  <p className="text-xs text-warm-500 truncate">{user?.email}</p>
                </div>
                <Link
                  href="/app/profile"
                  onClick={() => setUserMenuOpen(false)}
                  className="flex items-center gap-3 px-4 py-2.5 text-sm text-warm-700 hover:bg-warm-50"
                >
                  <User className="w-4 h-4 text-warm-400" />
                  Profile
                </Link>
                <Link
                  href="/app/settings"
                  onClick={() => setUserMenuOpen(false)}
                  className="flex items-center gap-3 px-4 py-2.5 text-sm text-warm-700 hover:bg-warm-50"
                >
                  <Settings className="w-4 h-4 text-warm-400" />
                  Settings
                </Link>
                <div className="border-t border-warm-200 my-1" />
                <button
                  onClick={() => {
                    setUserMenuOpen(false);
                    logout();
                  }}
                  className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-red-600 hover:bg-warm-50"
                >
                  <LogOut className="w-4 h-4" />
                  Sign out
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
}

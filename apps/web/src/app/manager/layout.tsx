'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/contexts/auth-context';
import {
  Home,
  LayoutDashboard,
  Users,
  ClipboardList,
  Inbox,
  Calendar,
  Wallet,
  MessageCircle,
  Wrench,
  Settings,
  ChevronLeft,
  ChevronRight,
  Bell,
  Search,
  LogOut,
  HelpCircle,
  Menu,
  X,
  CheckCircle2,
  DollarSign,
  Plane,
} from 'lucide-react';

// ============================================================================
// MANAGER PORTAL LAYOUT
// Primary Color: Indigo (vs Emerald for homeowners)
// Target: Information-dense, power-user focused
// ============================================================================

interface NavItem {
  label: string;
  href: string;
  icon: React.ElementType;
  badge?: number;
  urgent?: boolean;
}

const mainNavItems: NavItem[] = [
  { label: 'Dashboard', href: '/manager', icon: LayoutDashboard },
  { label: 'Households', href: '/manager/households', icon: Users },
  { label: 'Requests', href: '/manager/requests', icon: Inbox },
  { label: 'Conversations', href: '/manager/conversations', icon: MessageCircle },
  { label: 'Schedule', href: '/manager/schedule', icon: Calendar },
  { label: 'Vendors', href: '/manager/vendors', icon: Wrench },
  { label: 'Verification', href: '/manager/verification', icon: CheckCircle2 },
];

const financeNavItems: NavItem[] = [
  { label: 'Pay Bills', href: '/manager/payables', icon: Wallet },
  { label: 'Revenue', href: '/manager/revenue', icon: DollarSign },
];

const extraNavItems: NavItem[] = [
  { label: 'Travel', href: '/manager/travel', icon: Plane },
];

const bottomNavItems: NavItem[] = [
  { label: 'Help', href: '/manager/help', icon: HelpCircle },
  { label: 'Settings', href: '/manager/settings', icon: Settings },
];

// ============================================================================
// SIDEBAR COMPONENT
// ============================================================================

function Sidebar({
  collapsed,
  onToggle,
  user,
  logout
}: {
  collapsed: boolean;
  onToggle: () => void;
  user: { firstName?: string; lastName?: string; email?: string } | null;
  logout: () => void;
}) {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (href === '/manager') {
      return pathname === '/manager';
    }
    return pathname.startsWith(href);
  };

  const renderNavItem = (item: NavItem) => {
    const active = isActive(item.href);
    return (
      <Link
        key={item.href}
        href={item.href}
        className={`flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors relative ${
          active
            ? 'bg-indigo-600 text-white'
            : 'text-slate-300 hover:bg-slate-800 hover:text-white'
        }`}
        title={collapsed ? item.label : undefined}
      >
        <item.icon className="w-5 h-5 flex-shrink-0" />
        {!collapsed && (
          <>
            <span className="text-sm font-medium flex-1">{item.label}</span>
            {item.badge !== undefined && (
              <span
                className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                  item.urgent
                    ? 'bg-red-500 text-white'
                    : active
                      ? 'bg-indigo-500 text-white'
                      : 'bg-slate-700 text-slate-300'
                }`}
              >
                {item.badge}
              </span>
            )}
          </>
        )}
        {collapsed && item.badge !== undefined && (
          <span
            className={`absolute top-1 right-1 w-2 h-2 rounded-full ${
              item.urgent ? 'bg-red-500' : 'bg-indigo-400'
            }`}
          />
        )}
      </Link>
    );
  };

  return (
    <aside
      className={`fixed left-0 top-0 h-screen bg-slate-900 text-white z-40 transition-all duration-300 ${
        collapsed ? 'w-16' : 'w-64'
      } hidden lg:flex flex-col`}
    >
      {/* Logo */}
      <div className="flex items-center justify-between h-16 px-4 border-b border-slate-800">
        <Link href="/manager" className="flex items-center gap-3">
          <div className="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center flex-shrink-0">
            <Home className="w-5 h-5 text-white" />
          </div>
          {!collapsed && (
            <div>
              <span className="font-semibold text-white">Haven</span>
              <span className="text-xs text-indigo-400 block -mt-0.5">Manager Portal</span>
            </div>
          )}
        </Link>
        <button
          onClick={onToggle}
          className="p-1.5 hover:bg-slate-800 rounded-lg transition-colors"
        >
          {collapsed ? (
            <ChevronRight className="w-4 h-4 text-slate-400" />
          ) : (
            <ChevronLeft className="w-4 h-4 text-slate-400" />
          )}
        </button>
      </div>

      {/* Manager Info */}
      {!collapsed && (
        <div className="p-4 border-b border-slate-800">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-600 rounded-full flex items-center justify-center">
              <span className="text-sm font-bold text-white">
                {user?.firstName?.[0]}{user?.lastName?.[0]}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-white truncate">
                {user?.firstName} {user?.lastName}
              </p>
              <p className="text-xs text-slate-400">Home Manager</p>
            </div>
          </div>
        </div>
      )}

      {/* Main Navigation */}
      <nav className="flex-1 py-4 overflow-y-auto">
        {/* Main Items */}
        <div className="space-y-1 px-3">
          {mainNavItems.map(renderNavItem)}
        </div>

        {/* Finance Section */}
        <div className="mt-6 px-3">
          {!collapsed && (
            <p className="px-3 mb-2 text-xs font-medium text-slate-500 uppercase tracking-wider">Finance</p>
          )}
          <div className="space-y-1">
            {financeNavItems.map(renderNavItem)}
          </div>
        </div>

        {/* Extra Section */}
        <div className="mt-6 px-3">
          {!collapsed && (
            <p className="px-3 mb-2 text-xs font-medium text-slate-500 uppercase tracking-wider">Services</p>
          )}
          <div className="space-y-1">
            {extraNavItems.map(renderNavItem)}
          </div>
        </div>
      </nav>

      {/* Bottom Navigation */}
      <div className="border-t border-slate-800 py-4 px-3 space-y-1">
        {bottomNavItems.map(item => {
          const active = isActive(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors ${
                active
                  ? 'bg-indigo-600 text-white'
                  : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`}
              title={collapsed ? item.label : undefined}
            >
              <item.icon className="w-5 h-5 flex-shrink-0" />
              {!collapsed && <span className="text-sm font-medium">{item.label}</span>}
            </Link>
          );
        })}
        <button
          onClick={logout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors text-slate-300 hover:bg-slate-800 hover:text-white w-full"
          title={collapsed ? 'Sign Out' : undefined}
        >
          <LogOut className="w-5 h-5 flex-shrink-0" />
          {!collapsed && <span className="text-sm font-medium">Sign Out</span>}
        </button>
      </div>
    </aside>
  );
}

// ============================================================================
// MOBILE NAV COMPONENT
// ============================================================================

function MobileNav({
  open,
  onClose,
  user,
  logout
}: {
  open: boolean;
  onClose: () => void;
  user: { firstName?: string; lastName?: string; email?: string } | null;
  logout: () => void;
}) {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (href === '/manager') {
      return pathname === '/manager';
    }
    return pathname.startsWith(href);
  };

  if (!open) return null;

  const allNavItems = [...mainNavItems, ...financeNavItems, ...extraNavItems];

  return (
    <div className="fixed inset-0 z-50 lg:hidden">
      <div className="fixed inset-0 bg-black/50" onClick={onClose} />
      <aside className="fixed left-0 top-0 h-screen w-64 bg-slate-900 text-white overflow-y-auto">
        {/* Logo */}
        <div className="flex items-center justify-between h-16 px-4 border-b border-slate-800">
          <Link href="/manager" className="flex items-center gap-3" onClick={onClose}>
            <div className="w-8 h-8 bg-indigo-600 rounded-lg flex items-center justify-center">
              <Home className="w-5 h-5 text-white" />
            </div>
            <div>
              <span className="font-semibold text-white">Haven</span>
              <span className="text-xs text-indigo-400 block -mt-0.5">Manager Portal</span>
            </div>
          </Link>
          <button onClick={onClose} className="p-1.5 hover:bg-slate-800 rounded-lg">
            <X className="w-5 h-5 text-slate-400" />
          </button>
        </div>

        {/* Manager Info */}
        <div className="p-4 border-b border-slate-800">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-indigo-600 rounded-full flex items-center justify-center">
              <span className="text-sm font-bold text-white">
                {user?.firstName?.[0]}{user?.lastName?.[0]}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-white truncate">
                {user?.firstName} {user?.lastName}
              </p>
              <p className="text-xs text-slate-400">Home Manager</p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="py-4 px-3 space-y-1">
          {allNavItems.map((item) => {
            const active = isActive(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={onClose}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors ${
                  active
                    ? 'bg-indigo-600 text-white'
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <item.icon className="w-5 h-5 flex-shrink-0" />
                <span className="text-sm font-medium flex-1">{item.label}</span>
                {item.badge !== undefined && (
                  <span
                    className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                      item.urgent
                        ? 'bg-red-500 text-white'
                        : active
                          ? 'bg-indigo-500 text-white'
                          : 'bg-slate-700 text-slate-300'
                    }`}
                  >
                    {item.badge}
                  </span>
                )}
              </Link>
            );
          })}
        </nav>

        {/* Bottom */}
        <div className="border-t border-slate-800 py-4 px-3 space-y-1">
          {bottomNavItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              onClick={onClose}
              className="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors text-slate-300 hover:bg-slate-800 hover:text-white"
            >
              <item.icon className="w-5 h-5 flex-shrink-0" />
              <span className="text-sm font-medium">{item.label}</span>
            </Link>
          ))}
          <button
            onClick={logout}
            className="flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors text-slate-300 hover:bg-slate-800 hover:text-white w-full"
          >
            <LogOut className="w-5 h-5 flex-shrink-0" />
            <span className="text-sm font-medium">Sign Out</span>
          </button>
        </div>
      </aside>
    </div>
  );
}

// ============================================================================
// TOP HEADER COMPONENT
// ============================================================================

function TopHeader({ onMenuClick }: { onMenuClick: () => void }) {
  return (
    <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-4 lg:px-6">
      {/* Mobile menu button */}
      <button
        onClick={onMenuClick}
        className="lg:hidden p-2 -ml-2 hover:bg-slate-100 rounded-lg transition-colors"
      >
        <Menu className="w-5 h-5 text-slate-600" />
      </button>

      {/* Search */}
      <div className="flex-1 max-w-xl mx-4 hidden sm:block">
        <div className="relative">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Search households, tasks, vendors..."
            className="w-full pl-10 pr-4 py-2 text-sm border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-600 focus:border-transparent placeholder:text-slate-400"
          />
          <kbd className="absolute right-3 top-1/2 -translate-y-1/2 hidden md:inline-flex px-1.5 py-0.5 text-xs font-mono bg-slate-100 text-slate-500 rounded border border-slate-200">
            ⌘K
          </kbd>
        </div>
      </div>

      {/* Right side */}
      <div className="flex items-center gap-2">
        {/* Mobile search button */}
        <button className="sm:hidden p-2 hover:bg-slate-100 rounded-lg transition-colors">
          <Search className="w-5 h-5 text-slate-600" />
        </button>

        {/* Notifications */}
        <button className="relative p-2 hover:bg-slate-100 rounded-lg transition-colors">
          <Bell className="w-5 h-5 text-slate-600" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full" />
        </button>

        {/* Quick actions */}
        <button className="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors">
          Quick Actions
          <kbd className="px-1 py-0.5 text-xs font-mono bg-indigo-500 rounded">⌘J</kbd>
        </button>
      </div>
    </header>
  );
}

// ============================================================================
// MAIN LAYOUT COMPONENT
// ============================================================================

export default function ManagerLayout({ children }: { children: React.ReactNode }) {
  const { user, isAuthenticated, isLoading, logout } = useAuth();
  const router = useRouter();
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [mobileNavOpen, setMobileNavOpen] = useState(false);

  useEffect(() => {
    if (!isLoading && !isAuthenticated) {
      router.push('/login');
    } else if (!isLoading && user && user.role !== 'MANAGER' && user.role !== 'ADMIN') {
      // Non-managers redirect to regular app
      router.push('/app');
    }
  }, [isLoading, isAuthenticated, user, router]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-slate-600">Loading...</p>
        </div>
      </div>
    );
  }

  if (!isAuthenticated || (user?.role !== 'MANAGER' && user?.role !== 'ADMIN')) {
    return null;
  }

  return (
    <div className="min-h-screen bg-slate-50">
      {/* Desktop Sidebar */}
      <Sidebar
        collapsed={sidebarCollapsed}
        onToggle={() => setSidebarCollapsed(!sidebarCollapsed)}
        user={user}
        logout={logout}
      />

      {/* Mobile Nav */}
      <MobileNav
        open={mobileNavOpen}
        onClose={() => setMobileNavOpen(false)}
        user={user}
        logout={logout}
      />

      {/* Main Content */}
      <div
        className={`transition-all duration-300 ${
          sidebarCollapsed ? 'lg:ml-16' : 'lg:ml-64'
        }`}
      >
        <TopHeader onMenuClick={() => setMobileNavOpen(true)} />
        <main className="p-6">{children}</main>
      </div>
    </div>
  );
}

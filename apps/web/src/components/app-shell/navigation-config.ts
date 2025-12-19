import {
  LayoutDashboard,
  Calendar,
  CheckSquare,
  DollarSign,
  Package,
  Wrench,
  MessageSquare,
  Users,
  Settings,
  type LucideIcon,
} from 'lucide-react';

export interface NavItem {
  name: string;
  href: string;
  icon: LucideIcon;
  roles?: string[];
}

// Main navigation items
export const mainNavigation: NavItem[] = [
  { name: 'Dashboard', href: '/app', icon: LayoutDashboard },
  { name: 'Calendar', href: '/app/calendar', icon: Calendar },
  { name: 'Tasks', href: '/app/requests', icon: CheckSquare },
  { name: 'Money', href: '/app/billing', icon: DollarSign },
  { name: 'Inventory', href: '/app/home', icon: Package },
  { name: 'Maintenance', href: '/app/projects', icon: Wrench },
  { name: 'Messages', href: '/app/concierge', icon: MessageSquare },
  { name: 'Family', href: '/app/community', icon: Users },
  { name: 'Settings', href: '/app/settings', icon: Settings },
];

// Mobile bottom nav - subset of main navigation (max 5 items)
export const mobileNavigation: NavItem[] = [
  { name: 'Home', href: '/app', icon: LayoutDashboard },
  { name: 'Tasks', href: '/app/requests', icon: CheckSquare },
  { name: 'Messages', href: '/app/concierge', icon: MessageSquare },
  { name: 'Family', href: '/app/community', icon: Users },
  { name: 'Settings', href: '/app/settings', icon: Settings },
];

// Get page title from pathname
export function getPageTitle(pathname: string): string {
  // Check exact matches first
  const exactMatch = mainNavigation.find((item) => item.href === pathname);
  if (exactMatch) return exactMatch.name;

  // Check prefix matches for nested routes
  const prefixMatch = mainNavigation.find(
    (item) => item.href !== '/app' && pathname.startsWith(item.href)
  );
  if (prefixMatch) return prefixMatch.name;

  // Default to Dashboard for /app
  if (pathname === '/app') return 'Dashboard';

  // Extract page name from path for unknown routes
  const segments = pathname.split('/').filter(Boolean);
  const lastSegment = segments[segments.length - 1];
  return lastSegment ? lastSegment.charAt(0).toUpperCase() + lastSegment.slice(1) : 'Haven';
}

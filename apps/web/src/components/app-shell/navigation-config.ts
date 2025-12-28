import {
  LayoutDashboard,
  Calendar,
  MessageSquare,
  Users,
  Home,
  Wrench,
  ClipboardList,
  Package,
  FileText,
  UserCircle,
  ListTodo,
  DollarSign,
  Settings,
  User,
  Menu,
  Search,
  type LucideIcon,
} from 'lucide-react';

export interface NavItem {
  name: string;
  href: string;
  icon: LucideIcon;
  roles?: string[];
  badge?: number;
  highlight?: boolean;
}

export interface NavSection {
  title: string;
  items: NavItem[];
}

// Grouped navigation for desktop sidebar
export const sidebarNavigation: NavSection[] = [
  {
    title: 'Overview',
    items: [
      { name: 'Dashboard', href: '/app', icon: LayoutDashboard },
      { name: 'Sarah', href: '/app/manager', icon: User, badge: 5 },
      { name: 'Messages', href: '/app/messages', icon: MessageSquare },
      { name: 'Calendar', href: '/app/calendar', icon: Calendar },
    ],
  },
  {
    title: 'Your Home',
    items: [
      { name: 'Your Home', href: '/app/home', icon: Home },
      { name: 'Family', href: '/app/family', icon: UserCircle },
      { name: 'Projects', href: '/app/projects', icon: Wrench },
      { name: 'Maintenance', href: '/app/maintenance', icon: ClipboardList },
      { name: 'Documents', href: '/app/vault', icon: FileText },
      { name: 'Find Pros', href: '/app/community', icon: Search },
    ],
  },
  {
    title: 'Financial',
    items: [
      { name: 'Money', href: '/app/billing', icon: DollarSign },
      { name: 'Tasks', href: '/app/tasks', icon: ListTodo },
      { name: 'Inventory', href: '/app/inventory', icon: Package },
    ],
  },
];

// Bottom navigation items for sidebar
export const sidebarBottomNav: NavItem[] = [
  { name: 'My Profile', href: '/app/profile', icon: User },
  { name: 'Settings', href: '/app/settings', icon: Settings },
];

// Mobile bottom nav - 5 items: Home | Sarah | Messages | Money | Menu
export const mobileNavigation: NavItem[] = [
  { name: 'Home', href: '/app', icon: LayoutDashboard },
  { name: 'Sarah', href: '/app/manager', icon: User, badge: 5 },
  { name: 'Messages', href: '/app/messages', icon: MessageSquare },
  { name: 'Money', href: '/app/billing', icon: DollarSign },
  { name: 'Menu', href: '#menu', icon: Menu },
];

// All navigation items flattened (for mobile drawer)
export const allNavItems: NavItem[] = [
  ...sidebarNavigation.flatMap((section) => section.items),
  ...sidebarBottomNav,
];

// Get page title from pathname
export function getPageTitle(pathname: string): string {
  const allItems = [...allNavItems];

  // Check exact matches first
  const exactMatch = allItems.find((item) => item.href === pathname);
  if (exactMatch) return exactMatch.name;

  // Check prefix matches for nested routes
  const prefixMatch = allItems.find(
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

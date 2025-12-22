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
      { name: 'Calendar', href: '/app/calendar', icon: Calendar },
      { name: 'Messages', href: '/app/concierge', icon: MessageSquare },
      { name: 'Find Pros', href: '/app/community', icon: Search },
    ],
  },
  {
    title: 'Property',
    items: [
      { name: 'Home Profile', href: '/app/home', icon: Home },
      { name: 'Project Planning', href: '/app/projects', icon: Wrench },
      { name: 'Maintenance', href: '/app/maintenance', icon: ClipboardList },
      { name: 'Inventory', href: '/app/inventory', icon: Package },
      { name: 'Requests', href: '/app/requests', icon: FileText },
    ],
  },
  {
    title: 'Family',
    items: [
      { name: 'Family', href: '/app/family', icon: UserCircle },
      { name: 'Tasks', href: '/app/tasks', icon: ListTodo },
      { name: 'Money', href: '/app/billing', icon: DollarSign },
    ],
  },
];

// Bottom navigation items for sidebar
export const sidebarBottomNav: NavItem[] = [
  { name: 'My Profile', href: '/app/profile', icon: User },
  { name: 'Settings', href: '/app/settings', icon: Settings },
];

// Mobile bottom nav - 5 items max (last one opens drawer)
export const mobileNavigation: NavItem[] = [
  { name: 'Home', href: '/app', icon: LayoutDashboard },
  { name: 'Calendar', href: '/app/calendar', icon: Calendar },
  { name: 'Tasks', href: '/app/tasks', icon: ListTodo },
  { name: 'Messages', href: '/app/concierge', icon: MessageSquare },
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

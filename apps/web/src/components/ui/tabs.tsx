'use client';

import { ReactNode, createContext, useContext, useState } from 'react';

interface TabsContextType {
  activeTab: string;
  setActiveTab: (id: string) => void;
}

const TabsContext = createContext<TabsContextType | null>(null);

interface TabsProps {
  defaultTab: string;
  children: ReactNode;
  className?: string;
}

export function Tabs({ defaultTab, children, className = '' }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultTab);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className={className}>{children}</div>
    </TabsContext.Provider>
  );
}

export function TabList({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`flex gap-1 p-1 bg-warm-100 rounded-xl ${className}`}>
      {children}
    </div>
  );
}

export function Tab({
  id,
  children,
  icon,
}: {
  id: string;
  children: ReactNode;
  icon?: ReactNode;
}) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('Tab must be used within Tabs');

  const { activeTab, setActiveTab } = context;
  const isActive = activeTab === id;

  return (
    <button
      onClick={() => setActiveTab(id)}
      className={`flex items-center gap-2 px-4 py-2 text-sm font-medium rounded-lg transition-all duration-200
                  ${isActive
                    ? 'bg-white text-warm-900 shadow-sm'
                    : 'text-warm-600 hover:text-warm-900'}`}
    >
      {icon}
      {children}
    </button>
  );
}

export function TabPanel({
  id,
  children,
  className = '',
}: {
  id: string;
  children: ReactNode;
  className?: string;
}) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('TabPanel must be used within Tabs');

  if (context.activeTab !== id) return null;

  return <div className={className}>{children}</div>;
}

// Underline variant for navigation-style tabs
export function TabListUnderline({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`flex gap-6 border-b border-warm-200 ${className}`}>
      {children}
    </div>
  );
}

export function TabUnderline({
  id,
  children,
  count,
}: {
  id: string;
  children: ReactNode;
  count?: number;
}) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('TabUnderline must be used within Tabs');

  const { activeTab, setActiveTab } = context;
  const isActive = activeTab === id;

  return (
    <button
      onClick={() => setActiveTab(id)}
      className={`relative pb-3 text-sm font-medium transition-colors
                  ${isActive ? 'text-haven-600' : 'text-warm-500 hover:text-warm-700'}`}
    >
      <span className="flex items-center gap-2">
        {children}
        {count !== undefined && (
          <span
            className={`px-2 py-0.5 text-xs rounded-full
                       ${isActive ? 'bg-haven-100 text-haven-700' : 'bg-warm-100 text-warm-600'}`}
          >
            {count}
          </span>
        )}
      </span>
      {isActive && (
        <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-haven-500 rounded-full" />
      )}
    </button>
  );
}

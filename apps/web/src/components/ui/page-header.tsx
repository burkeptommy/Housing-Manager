'use client';

import { ReactNode } from 'react';

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  action?: ReactNode;
  breadcrumbs?: Array<{ label: string; href?: string }>;
  className?: string;
}

export function PageHeader({ title, subtitle, action, breadcrumbs, className = '' }: PageHeaderProps) {
  return (
    <div className={`mb-8 ${className}`}>
      {breadcrumbs && breadcrumbs.length > 0 && (
        <nav className="flex items-center gap-2 text-sm text-neutral-500 mb-3">
          {breadcrumbs.map((crumb, i) => (
            <span key={i} className="flex items-center gap-2">
              {i > 0 && <span>/</span>}
              {crumb.href ? (
                <a href={crumb.href} className="hover:text-neutral-700 transition-colors">
                  {crumb.label}
                </a>
              ) : (
                <span className="text-neutral-700">{crumb.label}</span>
              )}
            </span>
          ))}
        </nav>
      )}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-neutral-900 tracking-tight">{title}</h1>
          {subtitle && <p className="mt-1 text-neutral-500">{subtitle}</p>}
        </div>
        {action && <div className="flex-shrink-0">{action}</div>}
      </div>
    </div>
  );
}

// Section header for dividing content within a page
export function SectionHeader({
  title,
  subtitle,
  action,
  className = '',
}: {
  title: string;
  subtitle?: string;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div className={`flex items-center justify-between mb-4 ${className}`}>
      <div>
        <h2 className="text-lg font-semibold text-neutral-900">{title}</h2>
        {subtitle && <p className="text-sm text-neutral-500">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

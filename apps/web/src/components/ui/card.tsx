'use client';

import { ReactNode } from 'react';

interface CardProps {
  children: ReactNode;
  className?: string;
  hover?: boolean;
  padding?: 'none' | 'sm' | 'md' | 'lg';
}

const paddingClasses = {
  none: '',
  sm: 'p-4',
  md: 'p-6',
  lg: 'p-8',
};

export function Card({ children, className = '', hover = false, padding = 'md' }: CardProps) {
  return (
    <div
      className={`bg-white rounded-2xl border border-warm-100
                  shadow-[0_1px_3px_rgba(0,0,0,0.05),0_1px_2px_rgba(0,0,0,0.03)]
                  ${hover ? 'transition-all duration-200 hover:shadow-lg hover:border-warm-200 hover:-translate-y-0.5' : ''}
                  ${paddingClasses[padding]} ${className}`}
    >
      {children}
    </div>
  );
}

export function CardHeader({
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
    <div className={`flex items-start justify-between ${className}`}>
      <div>
        <h3 className="text-lg font-semibold text-warm-900">{title}</h3>
        {subtitle && <p className="text-sm text-warm-500 mt-0.5">{subtitle}</p>}
      </div>
      {action && <div>{action}</div>}
    </div>
  );
}

export function CardContent({ children, className = '' }: { children: ReactNode; className?: string }) {
  return <div className={className}>{children}</div>;
}

export function CardFooter({
  children,
  className = '',
  border = true,
}: {
  children: ReactNode;
  className?: string;
  border?: boolean;
}) {
  return (
    <div
      className={`mt-6 pt-4 ${border ? 'border-t border-warm-100' : ''} ${className}`}
    >
      {children}
    </div>
  );
}

// Premium feature card with gradient border
export function PremiumCard({ children, className = '' }: { children: ReactNode; className?: string }) {
  return (
    <div className={`relative rounded-2xl p-[1px] bg-gradient-to-br from-gold-300 via-gold-400 to-gold-500 ${className}`}>
      <div className="bg-white rounded-2xl p-6">
        {children}
      </div>
    </div>
  );
}

// Stat card for dashboard metrics
export function StatCard({
  label,
  value,
  change,
  changeType = 'neutral',
  icon,
}: {
  label: string;
  value: string | number;
  change?: string;
  changeType?: 'positive' | 'negative' | 'neutral';
  icon?: ReactNode;
}) {
  const changeColors = {
    positive: 'text-emerald-600 bg-emerald-50',
    negative: 'text-red-600 bg-red-50',
    neutral: 'text-warm-600 bg-warm-100',
  };

  return (
    <Card>
      <div className="flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-warm-500">{label}</p>
          <p className="mt-2 text-3xl font-bold text-warm-900">{value}</p>
          {change && (
            <span className={`inline-flex items-center mt-2 px-2 py-0.5 rounded-full text-xs font-medium ${changeColors[changeType]}`}>
              {change}
            </span>
          )}
        </div>
        {icon && (
          <div className="p-3 bg-haven-50 rounded-xl text-haven-600">
            {icon}
          </div>
        )}
      </div>
    </Card>
  );
}
